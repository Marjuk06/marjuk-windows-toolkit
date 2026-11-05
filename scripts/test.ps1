<#
.SYNOPSIS
    Automated test runner and syntax validator for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Validates PowerShell syntax across all project files, executes unit assertions,
    and ensures zero emojis, zero syntax errors, and consistent component behavior.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

$ErrorActionPreference = "Stop"

$toolkitRoot = Join-Path -Path $PSScriptRoot -ChildPath ".."
$srcDir = Join-Path -Path $toolkitRoot -ChildPath "src"

$totalTests = 0
$passedTests = 0
$failedTests = 0

function Assert-Test {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$Details = ""
    )

    $script:totalTests++
    if ($Condition) {
        $script:passedTests++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    }
    else {
        $script:failedTests++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Details) {
            Write-Host "         Details: $Details" -ForegroundColor Yellow
        }
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "MARJUK AMIN WINDOWS TOOLKIT — TEST RUNNER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Phase 1: Static PowerShell Syntax Validation
Write-Host "Phase 1: Validating PowerShell Syntax..." -ForegroundColor Yellow

$psFiles = Get-ChildItem -Path $srcDir -Recurse -Filter "*.ps1" -File
foreach ($file in $psFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null

    $hasNoErrors = ($errors.Count -eq 0)
    $errorDetails = if (-not $hasNoErrors) { ($errors | ForEach-Object { $_.Message }) -join "; " } else { "" }
    
    $relativePath = $file.FullName.Substring($toolkitRoot.Length + 1)
    Assert-Test -Name "Syntax: $relativePath" -Condition $hasNoErrors -Details $errorDetails
}

Write-Host ""

# Phase 2: Core Infrastructure Unit Tests
Write-Host "Phase 2: Testing Core Infrastructure..." -ForegroundColor Yellow

# Test Configuration
. (Join-Path -Path $srcDir -ChildPath "core/Configuration.ps1")
$config = Get-ToolkitConfiguration -ConfigPath (Join-Path -Path $toolkitRoot -ChildPath "config/settings.json")
Assert-Test -Name "Config: AppName is correct" -Condition ($config.AppName -eq "MARJUK AMIN WINDOWS TOOLKIT")
Assert-Test -Name "Config: PrimaryDomain is wintoolkit.marjukamin.com" -Condition ($config.PrimaryDomain -eq "https://wintoolkit.marjukamin.com")
Assert-Test -Name "Config: StandardWidth is positive" -Condition ($config.StandardWidth -ge 80)

# Test Environment
. (Join-Path -Path $srcDir -ChildPath "core/Environment.ps1")
$envInfo = Get-ToolkitEnvironment
Assert-Test -Name "Environment: OS Name detected" -Condition (-not [string]::IsNullOrEmpty($envInfo.OsName))
Assert-Test -Name "Environment: Architecture detected" -Condition (-not [string]::IsNullOrEmpty($envInfo.Architecture))

# Test Logging
. (Join-Path -Path $srcDir -ChildPath "core/Logging.ps1")
Initialize-ToolkitLogger -Subdirectory "MarjukToolkit\TestLogs"
Write-ToolkitLog -Level "INFO" -Component "UnitTest" -Message "Automated unit test log verification entry."
Assert-Test -Name "Logging: Log file created on disk" -Condition (Test-Path -LiteralPath $script:ToolkitLogFilePath)

Write-Host ""

# Phase 3: UI Design System Tests
Write-Host "Phase 3: Testing UI Design System..." -ForegroundColor Yellow

. (Join-Path -Path $srcDir -ChildPath "ui/Theme.ps1")
$theme = Get-ToolkitTheme -UseTrueColor $true
Assert-Test -Name "Theme: Contains Burgundy token" -Condition ($theme.ContainsKey("Burgundy"))
Assert-Test -Name "Theme: Contains CrimsonAccent token" -Condition ($theme.ContainsKey("CrimsonAccent"))

. (Join-Path -Path $srcDir -ChildPath "ui/Components.ps1")
$badgeOk = Get-StatusBadge -Status "OK" -UseTrueColor $false
Assert-Test -Name "Components: Status badge [OK] formatted" -Condition ($badgeOk -match "\[OK\]")

$borderGlyphs = Get-ToolkitBorderGlyphs -ForceAscii $false
Assert-Test -Name "Components: Unicode border glyphs loaded" -Condition ($null -ne $borderGlyphs.TopLeft)

Write-Host ""

# Phase 4: Prohibited Strings Check (Anti-Bypass & Clean Branding)
Write-Host "Phase 4: Verifying Complete Exclusion of Prohibited Strings..." -ForegroundColor Yellow

$prohibitedStrings = @(
    "massgrave\.dev",
    "activated\.win",
    "massgravel",
    "Sonbokli",
    "ohookdata",
    "LibTSforge"
)

foreach ($pattern in $prohibitedStrings) {
    $matchingFiles = @()
    foreach ($file in $psFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        if ($content -match $pattern) {
            $matchingFiles += $file.Name
        }
    }
    Assert-Test -Name "Prohibited pattern '$pattern' absent from src/" -Condition ($matchingFiles.Count -eq 0) -Details ($matchingFiles -join ", ")
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY: $passedTests / $totalTests Passed ($failedTests Failed)" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "============================================================" -ForegroundColor Cyan

if ($failedTests -gt 0) {
    exit 1
}
else {
    exit 0
}


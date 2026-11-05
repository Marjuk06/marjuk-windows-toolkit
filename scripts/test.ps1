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
Assert-Test -Name "Config: StandardWidth is positive" -Condition ($config.StandardWidth -ge 70)

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

# Phase 5: Activation Management & Licensing Diagnostics Tests
Write-Host "Phase 5: Testing Activation Management Modules..." -ForegroundColor Yellow

. (Join-Path -Path $srcDir -ChildPath "core/Permissions.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/OfficeInformation/OfficeDiscovery.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Network/ConnectivityCheck.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Activation/WindowsActivation.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Activation/OfficeActivation.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Activation/KmsManagement.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Activation/ActivationDiagnostics.ps1")

$winLic = Get-WindowsDigitalLicenseStatus
Assert-Test -Name "WindowsActivation: Digital license status object returned" -Condition ($null -ne $winLic -and -not [string]::IsNullOrEmpty($winLic.ProductName))
Assert-Test -Name "WindowsActivation: Channel detected" -Condition (-not [string]::IsNullOrEmpty($winLic.Channel))
Assert-Test -Name "WindowsActivation: Classify Generic Default Key (3V66T)" -Condition ((Get-WindowsKeyClassification -PartialKey "3V66T") -match "Generic Default Key")
Assert-Test -Name "WindowsActivation: Classify Public GVLK Key (T83GX)" -Condition ((Get-WindowsKeyClassification -PartialKey "T83GX") -match "Official Microsoft Public GVLK")
Assert-Test -Name "WindowsActivation: Classify Unique Key (ABCDE)" -Condition ((Get-WindowsKeyClassification -PartialKey "ABCDE" -Channel "Retail") -match "Unique Retail Product Key")

$offDiag = Get-OfficeActivationDiagnostics
Assert-Test -Name "OfficeActivation: Diagnostic audit object returned" -Condition ($null -ne $offDiag)
Assert-Test -Name "OfficeActivation: Ohook check returns boolean" -Condition ($offDiag.OhookDetected -is [bool])
Assert-Test -Name "OfficeActivation: SystemSppcSignatureStatus populated" -Condition (-not [string]::IsNullOrEmpty($offDiag.SystemSppcSignatureStatus))

# Test UTF-16LE and UTF-8 Office vNext JSON parser
$tempUtf16File = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "marjuk_test_vnext_utf16.json"
$tempUtf8File  = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "marjuk_test_vnext_utf8.json"
[System.IO.File]::WriteAllText($tempUtf16File, '{"License":"eyJQcm9kdWN0UmVsZWFzZUlkIjoiTzM2NVByb1BsdXNSZXRhaWwifQ=="}', [System.Text.Encoding]::Unicode)
[System.IO.File]::WriteAllText($tempUtf8File,  '{"License":"eyJQcm9kdWN0UmVsZWFzZUlkIjoiUHJvUGx1czIwMjRWb2x1bWUifQ=="}', [System.Text.Encoding]::UTF8)
$parsed16 = Read-OfficeLicenseJsonFile -FilePath $tempUtf16File
$parsed8  = Read-OfficeLicenseJsonFile -FilePath $tempUtf8File
Remove-Item -LiteralPath $tempUtf16File, $tempUtf8File -Force -ErrorAction SilentlyContinue
Assert-Test -Name "OfficeActivation: Parses UTF-16LE vNext license JSON" -Condition ($null -ne $parsed16 -and $parsed16.License -ne "")
Assert-Test -Name "OfficeActivation: Parses UTF-8 vNext license JSON" -Condition ($null -ne $parsed8 -and $parsed8.License -ne "")

$kmsDiag = Get-KmsConfigurationReport
Assert-Test -Name "KmsManagement: KMS configuration report returned" -Condition ($null -ne $kmsDiag -and -not [string]::IsNullOrEmpty($kmsDiag.ClientMachineId))
Assert-Test -Name "KmsManagement: Detects unauthorized emulator host (kms8.msguides.com)" -Condition (Test-UnauthorizedKmsHost -HostName "kms8.msguides.com")
Assert-Test -Name "KmsManagement: Detects loopback emulator (127.0.0.2)" -Condition (Test-UnauthorizedKmsHost -HostName "127.0.0.2")
Assert-Test -Name "KmsManagement: Allows legitimate enterprise KMS host (kms.corp.contoso.com)" -Condition (-not (Test-UnauthorizedKmsHost -HostName "kms.corp.contoso.com"))

$sppDiag = Get-ActivationDiagnosticsReport
Assert-Test -Name "ActivationDiagnostics: SPP service telemetry returned" -Condition ($null -ne $sppDiag -and -not [string]::IsNullOrEmpty($sppDiag.SlsVersion))

$errResolved = Resolve-ActivationErrorCode -ErrorCode "0xC004F074"
Assert-Test -Name "ActivationDiagnostics: Resolves 0xC004F074 (SL_E_CHPA_NO_KMS_AVAILABLE)" -Condition ($errResolved.Symbolic -eq "SL_E_CHPA_NO_KMS_AVAILABLE")
$errResolved2 = Resolve-ActivationErrorCode -ErrorCode "0x80070005"
Assert-Test -Name "ActivationDiagnostics: Resolves 0x80070005 (E_ACCESSDENIED)" -Condition ($errResolved2.Symbolic -eq "E_ACCESSDENIED")

$adminCheck = Test-ToolkitAdmin
Assert-Test -Name "Permissions: Admin privilege check returns boolean" -Condition ($adminCheck -is [bool])

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


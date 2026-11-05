<#
.SYNOPSIS
    MARJUK AMIN WINDOWS TOOLKIT — Official Remote Web Bootstrap.
.DESCRIPTION
    Executed via: irm https://wintoolkit.marjukamin.com | iex
    Downloads, validates, and launches the latest official release of MARJUK AMIN WINDOWS TOOLKIT.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# 1. Silently bypass ExecutionPolicy for the current process on Windows
if ($env:OS -eq "Windows_NT" -or (Get-Variable -Name IsWindows -ValueOnly -ErrorAction SilentlyContinue)) {
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
    }
    catch {}
}

# 2. Suppress bright blue progress bars that corrupt console buffers
$ProgressPreference = "SilentlyContinue"

# 3. Enable TLS 1.2 for secure GitHub communication
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}
catch {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}

# 4. Set UTF-8 encoding so characters render cleanly
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {}

$appName = "MARJUK AMIN WINDOWS TOOLKIT"
$tagline = "A better way to manage Windows."
$portalUrl = "https://wintoolkit.marjukamin.com"
$repoZipUrl = "https://github.com/marjuk06/marjuk-windows-toolkit/archive/refs/heads/main.zip"

# Sleek, bulletproof banner guaranteed to fit any terminal width without wrapping
$bannerWidth = 66
$border = "=" * $bannerWidth

Write-Host ""
Write-Host "  $border" -ForegroundColor DarkRed
Write-Host "    $appName" -ForegroundColor White
Write-Host "    $tagline" -ForegroundColor DarkGray
Write-Host "    $portalUrl" -ForegroundColor DarkRed
Write-Host "  $border" -ForegroundColor DarkRed
Write-Host ""

$tempRoot = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$tempDir = Join-Path -Path $tempRoot -ChildPath "MarjukToolkit"
$appDir = Join-Path -Path $tempDir -ChildPath "App"
$zipFile = Join-Path -Path $tempDir -ChildPath "toolkit.zip"

if (-not (Test-Path -LiteralPath $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
}

try {
    Write-Host "  -> Fetching toolkit package from GitHub..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $repoZipUrl -OutFile $zipFile -UseBasicParsing -TimeoutSec 30

    Write-Host "  -> Extracting and preparing environment..." -ForegroundColor Gray
    if (Test-Path -LiteralPath $appDir) {
        Remove-Item -Path $appDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $appDir -ItemType Directory -Force | Out-Null
    Expand-Archive -Path $zipFile -DestinationPath $appDir -Force

    # Locate extracted repository folder inside $appDir
    $extractedFolder = (Get-ChildItem -Path $appDir -Directory | Select-Object -First 1).FullName
    if (-not $extractedFolder) {
        $extractedFolder = $appDir
    }

    $mainScript = Join-Path -Path $extractedFolder -ChildPath "src\launcher\main.ps1"

    if (Test-Path -LiteralPath $mainScript) {
        Write-Host "  -> Launching toolkit..." -ForegroundColor Green
        Write-Host ""
        
        # Launch with explicit execution policy bypass to guarantee execution on all systems
        $psExe = if ($PSVersionTable.PSEdition -eq "Core") { "pwsh" } else { "powershell.exe" }
        & $psExe -NoProfile -ExecutionPolicy Bypass -File "$mainScript"
    }
    else {
        throw "Could not locate main launcher entry point at: $mainScript"
    }
}
catch {
    Write-Host ""
    Write-Host "  [ERROR] Toolkit launch failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  You can download the offline release directly from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/marjuk06/marjuk-windows-toolkit/releases" -ForegroundColor Cyan
    Write-Host ""
}
finally {
    if (Test-Path -LiteralPath $zipFile) {
        Remove-Item -LiteralPath $zipFile -Force -ErrorAction SilentlyContinue
    }
}

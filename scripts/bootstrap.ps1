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

# Ensure TLS 1.2 is enabled for Windows PowerShell 5.1
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}
catch {
    # Fallback integer code for TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}

$appName = "MARJUK AMIN WINDOWS TOOLKIT"
$tagline = "A better way to manage Windows."
$portalUrl = "https://wintoolkit.marjukamin.com"
$repoZipUrl = "https://github.com/marjuk06/marjuk-windows-toolkit/archive/refs/heads/main.zip"

Write-Host ""
Write-Host "  ╭────────────────────────────────────────────────────────────╮" -ForegroundColor DarkRed
Write-Host "  │  $appName                │" -ForegroundColor White
Write-Host "  │  $tagline                             │" -ForegroundColor DarkGray
Write-Host "  │  $portalUrl                               │" -ForegroundColor DarkRed
Write-Host "  ╰────────────────────────────────────────────────────────────╯" -ForegroundColor DarkRed
Write-Host ""
Write-Host "  [INFO] Initializing official toolkit bootstrap..." -ForegroundColor Gray

$tempRoot = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$tempDir = Join-Path -Path $tempRoot -ChildPath "MarjukToolkit"
$appDir = Join-Path -Path $tempDir -ChildPath "App"
$zipFile = Join-Path -Path $tempDir -ChildPath "toolkit.zip"

if (-not (Test-Path -LiteralPath $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
}

try {
    Write-Host "  [INFO] Fetching latest toolkit source from GitHub..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $repoZipUrl -OutFile $zipFile -UseBasicParsing -TimeoutSec 15

    Write-Host "  [INFO] Extracting toolkit archive..." -ForegroundColor Gray
    if (Test-Path -LiteralPath $appDir) {
        Remove-Item -Path $appDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $appDir -ItemType Directory -Force | Out-Null
    Expand-Archive -Path $zipFile -DestinationPath $appDir -Force

    # Locate extracted folder inside $appDir
    $extractedFolder = (Get-ChildItem -Path $appDir -Directory | Select-Object -First 1).FullName
    if (-not $extractedFolder) {
        $extractedFolder = $appDir
    }

    $mainScript = Join-Path -Path $extractedFolder -ChildPath "src\launcher\main.ps1"

    if (Test-Path -LiteralPath $mainScript) {
        Write-Host "  [OK] Toolkit verified. Launching..." -ForegroundColor Green
        Write-Host ""
        & $mainScript
    }
    else {
        throw "Could not locate main launcher entry point at: $mainScript"
    }
}
catch {
    Write-Host ""
    Write-Host "  [ERROR] Bootstrap execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  You can download the offline release directly from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/marjuk06/marjuk-windows-toolkit/releases" -ForegroundColor Cyan
    Write-Host ""
}
finally {
    # Clean up archive file
    if (Test-Path -LiteralPath $zipFile) {
        Remove-Item -LiteralPath $zipFile -Force -ErrorAction SilentlyContinue
    }
}


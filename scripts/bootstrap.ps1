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

# Set TLS 1.2 / TLS 1.3
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

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

$tempDir = Join-Path -Path [System.IO.Path]::GetTempPath() -ChildPath "MarjukToolkit"
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
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

    # Locate extracted folder (marjuk-windows-toolkit-main)
    $extractedFolder = Join-Path -Path $tempDir -ChildPath "marjuk-windows-toolkit-main"
    if (-not (Test-Path -LiteralPath $extractedFolder)) {
        $extractedFolder = (Get-ChildItem -Path $tempDir -Directory | Where-Object { $_.Name -like "*toolkit*" } | Select-Object -First 1).FullName
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


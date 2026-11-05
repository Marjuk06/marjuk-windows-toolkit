<#
.SYNOPSIS
    Release build and distribution packager for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Validates source tree, bundles release archive into dist/, and computes SHA-256 checksums.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

$ErrorActionPreference = "Stop"

$toolkitRoot = Join-Path -Path $PSScriptRoot -ChildPath ".."
$distDir = Join-Path -Path $toolkitRoot -ChildPath "dist"
$version = "1.0.0"
$releaseZip = Join-Path -Path $distDir -ChildPath "marjuk-windows-toolkit-v$version.zip"
$checksumFile = Join-Path -Path $distDir -ChildPath "SHA256SUMS.txt"

Write-Host "Building MARJUK AMIN WINDOWS TOOLKIT v$version..." -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $distDir)) {
    New-Item -Path $distDir -ItemType Directory -Force | Out-Null
}

if (Test-Path -LiteralPath $releaseZip) {
    Remove-Item -LiteralPath $releaseZip -Force
}

# Directories and files to include in release archive
$itemsToInclude = @(
    "LICENSE",
    "NOTICE.md",
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "config",
    "src"
)

$tempStaging = Join-Path -Path $distDir -ChildPath "staging"
if (Test-Path -LiteralPath $tempStaging) {
    Remove-Item -Path $tempStaging -Recurse -Force
}
New-Item -Path $tempStaging -ItemType Directory -Force | Out-Null

foreach ($item in $itemsToInclude) {
    $sourcePath = Join-Path -Path $toolkitRoot -ChildPath $item
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $tempStaging -Recurse -Force
    }
}

Write-Host "Compressing release archive..." -ForegroundColor Gray
Compress-Archive -Path "$tempStaging\*" -DestinationPath $releaseZip -Force
Remove-Item -Path $tempStaging -Recurse -Force

Write-Host "Computing SHA-256 checksum..." -ForegroundColor Gray
$hasher = [System.Security.Cryptography.SHA256]::Create()
$stream = [System.IO.File]::OpenRead($releaseZip)
$hashBytes = $hasher.ComputeHash($stream)
$stream.Close()
$stream.Dispose()

$sb = [System.Text.StringBuilder]::new()
foreach ($b in $hashBytes) {
    $sb.Append($b.ToString("x2")) | Out-Null
}
$sha256 = $sb.ToString()
$zipFileName = [System.IO.Path]::GetFileName($releaseZip)

$checksumContent = "$sha256  $zipFileName"
[System.IO.File]::WriteAllText($checksumFile, $checksumContent + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Release build complete!" -ForegroundColor Green
Write-Host "Archive:  $releaseZip" -ForegroundColor White
Write-Host "SHA-256:  $sha256" -ForegroundColor Yellow
Write-Host "Checksum: $checksumFile" -ForegroundColor White


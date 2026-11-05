<#
.SYNOPSIS
    Cryptographic SHA-256 integrity and file validation service.
.DESCRIPTION
    Computes and verifies SHA-256 hashes of toolkit files and downloaded payloads
    to detect transmission errors, file corruption, or tampering before execution.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Get-ToolkitFileHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "File not found: $FilePath"
    }

    try {
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $hasher.ComputeHash($stream)
        $stream.Close()
        $stream.Dispose()

        $sb = [System.Text.StringBuilder]::new()
        foreach ($b in $hashBytes) {
            $sb.Append($b.ToString("x2")) | Out-Null
        }
        return $sb.ToString().ToUpperInvariant()
    }
    catch {
        Write-ToolkitLog -Level "ERROR" -Component "IntegrityService" -Message "Hash computation failed: $($_.Exception.Message)"
        throw $_
    }
}

function Test-ToolkitFileIntegrity {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash
    )

    try {
        $actualHash = Get-ToolkitFileHash -FilePath $FilePath
        return ($actualHash.Equals($ExpectedHash.Trim().ToUpperInvariant(), [System.StringComparison]::OrdinalIgnoreCase))
    }
    catch {
        return $false
    }
}


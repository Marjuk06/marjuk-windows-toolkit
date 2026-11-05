<#
.SYNOPSIS
    Automated version check service for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Checks for available toolkit releases against the official API endpoint
    (https://wintoolkit.marjukamin.com/version.json or GitHub API) over HTTPS.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

class ToolkitReleaseInfo {
    [string]$CurrentVersion = "1.0.0"
    [string]$LatestVersion = "1.0.0"
    [bool]$UpdateAvailable = $false
    [string]$ReleaseNotesUrl = "https://wintoolkit.marjukamin.com"
    [string]$DownloadUrl = "https://wintoolkit.marjukamin.com"
}

function Get-ToolkitUpdateInfo {
    [CmdletBinding()]
    [OutputType([ToolkitReleaseInfo])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CurrentVersion = "1.0.0",

        [Parameter(Mandatory = $false)]
        [string]$ApiUrl = "https://api.github.com/repos/marjuk06/marjuk-windows-toolkit/releases/latest"
    )

    $info = [ToolkitReleaseInfo]::new()
    $info.CurrentVersion = $CurrentVersion

    try {
        $headers = @{ "User-Agent" = "MarjukAmin-WindowsToolkit/$CurrentVersion" }
        $response = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -TimeoutSec 5 -ErrorAction Stop

        if ($response.tag_name) {
            $latestTag = $response.tag_name.TrimStart('v')
            $info.LatestVersion = $latestTag

            if ([System.Version]$latestTag -gt [System.Version]$CurrentVersion) {
                $info.UpdateAvailable = $true
            }

            if ($response.html_url) {
                $info.ReleaseNotesUrl = [string]$response.html_url
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "UpdateService" -Message "Update check failed: $($_.Exception.Message)"
    }

    return $info
}


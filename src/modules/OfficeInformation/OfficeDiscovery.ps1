<#
.SYNOPSIS
    Microsoft Office Click-to-Run installation and channel discovery module.
.DESCRIPTION
    Scans registry and configuration paths for installed Microsoft Office C2R releases,
    architecture, update channels, and application suites. Read-only diagnostic utility.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from research by @abbodi1406.
    Copyright (c) 2026 Marjuk Amin.
#>

class OfficeInstallationSummary {
    [bool]$IsInstalled = $false
    [string]$Version = "None"
    [string]$Platform = "None"
    [string]$UpdateChannel = "None"
    [string]$InstalledProducts = "None"
    [string]$ClientFolder = "None"
}

function Get-OfficeInstallationReport {
    [CmdletBinding()]
    [OutputType([OfficeInstallationSummary])]
    param()

    $summary = [OfficeInstallationSummary]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Safe mock for non-Windows testing
        $summary.IsInstalled = $true
        $summary.Version = "16.0.17830.20166"
        $summary.Platform = "x64"
        $summary.UpdateChannel = "Current Channel"
        $summary.InstalledProducts = "Microsoft 365 Apps for enterprise"
        $summary.ClientFolder = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun"
        return $summary
    }

    try {
        $c2rKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        if (Test-Path -LiteralPath $c2rKey) {
            $props = Get-ItemProperty -Path $c2rKey -ErrorAction Stop

            $summary.IsInstalled = $true
            if ($props.VersionToReport) { $summary.Version = [string]$props.VersionToReport }
            if ($props.Platform) { $summary.Platform = [string]$props.Platform }
            if ($props.ProductReleaseIds) { $summary.InstalledProducts = [string]$props.ProductReleaseIds }
            if ($props.ClientFolder) { $summary.ClientFolder = [string]$props.ClientFolder }

            if ($props.UpdateChannel) {
                $channelUrl = [string]$props.UpdateChannel
                if ($channelUrl -match "492350f6-3a01-4f97-b9c0-c7c6ddf67d60") { $summary.UpdateChannel = "Current Channel" }
                elseif ($channelUrl -match "55336b82-a18d-4dd6-b5f6-9e5095c314a6") { $summary.UpdateChannel = "Monthly Enterprise" }
                elseif ($channelUrl -match "7ffbc656-404a-47c1-4145-49f16066d2c2") { $summary.UpdateChannel = "Semi-Annual Enterprise" }
                elseif ($channelUrl -match "5440fd1f-730b-4819-8132-15cde46ad65e") { $summary.UpdateChannel = "Beta Channel" }
                else { $summary.UpdateChannel = $channelUrl }
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "OfficeDiscovery" -Message "Office scan failed: $($_.Exception.Message)"
    }

    return $summary
}

function Show-OfficeInformationScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "Microsoft Office Discovery" `
                             -Subtitle "Installed Click-to-Run Suites and Servicing Channels" `
                             -UseTrueColor $UseTrueColor

    $report = Get-OfficeInstallationReport

    if (-not $report.IsInstalled) {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "No Microsoft Office Click-to-Run installation detected on this machine." -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor))
    }
    else {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "OFFICE INSTALLATION DETAILS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        Write-ToolkitKeyValue -Key "Installed Status" -Value "Installed" -ValueColor "Success" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Version / Build" -Value $report.Version -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Architecture" -Value $report.Platform -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Update Channel" -Value $report.UpdateChannel -ValueColor "PrimaryText" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Release IDs" -Value $report.InstalledProducts -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Client Directory" -Value $report.ClientFolder -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor
    }

    [System.Console]::WriteLine()
    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


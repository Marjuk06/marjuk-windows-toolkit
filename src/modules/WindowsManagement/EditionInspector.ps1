<#
.SYNOPSIS
    Windows edition inspection and official SKU servicing manager.
.DESCRIPTION
    Analyzes current Windows edition, servicing branch, and queries available target
    upgrade paths via official DISM APIs. Strictly adheres to official Microsoft
    edition-switching mechanisms without license circumvention.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Derived in part from research by @abbodi1406, asdcorp, and ave9858.
    Copyright (c) 2026 Marjuk Amin.
#>

class WindowsEditionReport {
    [string]$CurrentEdition = "Professional"
    [string]$CompositionEdition = "Professional"
    [string]$CurrentBuild = "26100"
    [string]$InstallationType = "Client"
    [string[]]$TargetEditions = @()
}

function Get-WindowsEditionReport {
    [CmdletBinding()]
    [OutputType([WindowsEditionReport])]
    param()

    $report = [WindowsEditionReport]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Safe mock for test environment
        $report.CurrentEdition = "Professional"
        $report.CompositionEdition = "Enterprise"
        $report.CurrentBuild = "26100.2033"
        $report.InstallationType = "Client"
        $report.TargetEditions = @("Enterprise", "Education", "ProfessionalEducation", "ProfessionalWorkstation")
        return $report
    }

    try {
        $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $props = Get-ItemProperty -Path $regKey -ErrorAction Stop

        if ($props.EditionID) { $report.CurrentEdition = [string]$props.EditionID }
        if ($props.CompositionEditionID) { $report.CompositionEdition = [string]$props.CompositionEditionID }
        if ($props.CurrentBuildNumber) { $report.CurrentBuild = [string]$props.CurrentBuildNumber }
        if ($props.InstallationType) { $report.InstallationType = [string]$props.InstallationType }

        # If elevated, query official DISM target editions
        if (Test-ToolkitAdmin) {
            $dismOutput = & "$env:SystemRoot\System32\Dism.exe" /Online /Get-TargetEditions /English 2>$null
            $targets = @()
            foreach ($line in $dismOutput) {
                if ($line -match "Target Edition\s*:\s*(.+)$") {
                    $targets += $matches[1].Trim()
                }
            }
            if ($targets.Count -gt 0) {
                $report.TargetEditions = $targets
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "EditionInspector" -Message "Edition discovery failed: $($_.Exception.Message)"
    }

    return $report
}

function Show-WindowsEditionScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "Windows Edition & Target Inspector" `
                             -Subtitle "Official Windows SKU Information and DISM Servicing Targets" `
                             -UseTrueColor $UseTrueColor

    $report = Get-WindowsEditionReport

    [System.Console]::WriteLine("  " + (Format-Colored -Text "CURRENT EDITION CONFIGURATION" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitKeyValue -Key "Installed Edition" -Value $report.CurrentEdition -ValueColor "Success" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Composition Edition" -Value $report.CompositionEdition -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Windows Build" -Value $report.CurrentBuild -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Installation Type" -Value $report.InstallationType -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "AVAILABLE TARGET UPGRADE EDITIONS (DISM)" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    if ($report.TargetEditions.Count -gt 0) {
        foreach ($target in $report.TargetEditions) {
            $badge = Get-StatusBadge -Status "READY" -UseTrueColor $UseTrueColor
            [System.Console]::WriteLine("  $badge  " + (Format-Colored -Text $target -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        }
    }
    else {
        if (-not (Test-ToolkitAdmin)) {
            [System.Console]::WriteLine("  " + (Format-Colored -Text "Run toolkit as Administrator to query available DISM target editions." -Color "SecondaryText" -UseTrueColor $UseTrueColor))
        }
        else {
            [System.Console]::WriteLine("  No target upgrade editions reported for this installation image.")
        }
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "Note: Edition switching requires an official product key or qualifying digital entitlement." -Color "SecondaryText" -UseTrueColor $UseTrueColor))

    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


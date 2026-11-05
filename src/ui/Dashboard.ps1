<#
.SYNOPSIS
    System overview telemetry dashboard and About/License views.
.DESCRIPTION
    Renders hardware and environmental telemetry summaries, as well as the official
    About, Credits, and GNU GPL-3.0 open-source licensing view for the toolkit.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Show-ToolkitSystemOverviewScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SystemEnvironmentInfo]$Environment,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "System & Hardware Overview" `
                             -Subtitle "Comprehensive Environmental and Platform Telemetry" `
                             -UseTrueColor $UseTrueColor

    $summary = Get-ToolkitSystemSummary

    [System.Console]::WriteLine("  " + (Format-Colored -Text "HARDWARE & FIRMWARE SUMMARY" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitKeyValue -Key "Computer Name" -Value $summary.ComputerName -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Manufacturer" -Value $summary.Manufacturer -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "System Model" -Value $summary.Model -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Processor" -Value "$($summary.ProcessorName) ($($summary.CpuCores) Cores / $($summary.CpuLogicalProcessors) Threads)" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Installed Memory" -Value "$($summary.TotalMemoryGb) GB RAM ($($summary.FreeMemoryGb) GB free)" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "System Drive Free" -Value $summary.SystemDiskFreeGb -UseTrueColor $UseTrueColor

    $secColor = if ($summary.SecureBootState -eq "Enabled") { "Success" } else { "SecondaryText" }
    Write-ToolkitKeyValue -Key "Secure Boot" -Value $summary.SecureBootState -ValueColor $secColor -UseTrueColor $UseTrueColor

    $tpmColor = if ($summary.TpmStatus -match "Ready") { "Success" } else { "SecondaryText" }
    Write-ToolkitKeyValue -Key "TPM Readiness" -Value $summary.TpmStatus -ValueColor $tpmColor -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "SOFTWARE & RUNTIME HOST" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitKeyValue -Key "Operating System" -Value "$($Environment.OsName) ($($Environment.BuildNumber))" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Architecture" -Value $Environment.Architecture -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "PowerShell Version" -Value "$($Environment.PowerShellVersion) ($($Environment.PowerShellEdition))" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Terminal Host" -Value $(if ($Environment.IsWindowsTerminal) { "Windows Terminal (wt.exe)" } else { "Standard Console (conhost.exe)" }) -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Color Engine" -Value $(if ($Environment.SupportsTrueColor) { "24-bit TrueColor ANSI ($#800020 Burgundy)" } else { "16-color ANSI Fallback" }) -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    Show-ToolkitPause -UseTrueColor $UseTrueColor
}

function Show-ToolkitAboutScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "About, Credits and License" `
                             -Subtitle "Open Source Heritage, Compliance and Project Information" `
                             -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine("  " + (Format-Colored -Text "MARJUK AMIN WINDOWS TOOLKIT" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine("  " + (Format-Colored -Text "A better way to manage Windows." -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitKeyValue -Key "Product Version" -Value "1.0.0 (Release)" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Author & Maintainer" -Value "Marjuk Amin (2026)" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Official Portal" -Value "https://wintoolkit.marjukamin.com" -ValueColor "PrimaryText" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Technical Alias" -Value "https://activation.marjukamin.com" -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Source Repository" -Value "https://github.com/marjuk06/marjuk-windows-toolkit" -ValueColor "PrimaryText" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "License" -Value "GNU General Public License v3.0 (GPL-3.0)" -ValueColor "Success" -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "OPEN-SOURCE HERITAGE & THIRD-PARTY CREDITS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine("  This toolkit is an independently architected, legitimate system administration")
    [System.Console]::WriteLine("  and maintenance utility derived in part from technical research and diagnostic")
    [System.Console]::WriteLine("  routines in the open-source Windows ecosystem:")
    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  - Microsoft-Activation-Scripts (MAS) v3.12: Upstream technical research (GPL-3.0)")
    [System.Console]::WriteLine("  - @abbodi1406: Licensing status inspection research and Office C2R discovery")
    [System.Console]::WriteLine("  - asdcorp: clic (Client Licensing Check) P/Invoke routines (MIT License)")
    [System.Console]::WriteLine("  - Alex (aka may, ave9858): DISM API research")
    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "WARRANTY & DISCLAIMER" -Color "SecondaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine("  This program is distributed in the hope that it will be useful, but WITHOUT ANY")
    [System.Console]::WriteLine("  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR")
    [System.Console]::WriteLine("  A PARTICULAR PURPOSE. See the GNU General Public License v3.0 for more details.")

    [System.Console]::WriteLine()
    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


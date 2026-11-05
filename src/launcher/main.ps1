<#
.SYNOPSIS
    MARJUK AMIN WINDOWS TOOLKIT — Main Application Entry Point.
.DESCRIPTION
    A better way to manage Windows.
    Provides terminal dashboard, system diagnostics, read-only licensing inspection,
    and guided system servicing routines using a Burgundy and Charcoal design system.
.PARAMETER CLI Switches
    -Info, -Licensing, -Office, -Network: Run non-interactive diagnostic reports.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

[CmdletBinding()]
param(
    [switch]$Info,
    [switch]$Licensing,
    [switch]$Office,
    [switch]$Network,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

# Set UTF-8 encoding for clean Unicode border rendering
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {
    # Ignore if redirected
}

$launcherDir = $PSScriptRoot
if (-not $launcherDir -and $MyInvocation.MyCommand.Path) {
    $launcherDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $launcherDir) {
    $launcherDir = (Get-Location).Path
}
$srcDir = Join-Path -Path $launcherDir -ChildPath ".."

# Source Core Infrastructure
. (Join-Path -Path $srcDir -ChildPath "core/Configuration.ps1")
. (Join-Path -Path $srcDir -ChildPath "core/Environment.ps1")
. (Join-Path -Path $srcDir -ChildPath "core/Permissions.ps1")
. (Join-Path -Path $srcDir -ChildPath "core/Logging.ps1")
. (Join-Path -Path $srcDir -ChildPath "core/ErrorHandling.ps1")
. (Join-Path -Path $srcDir -ChildPath "core/SystemInfo.ps1")

# Source UI Presentation Engine
. (Join-Path -Path $srcDir -ChildPath "ui/Theme.ps1")
. (Join-Path -Path $srcDir -ChildPath "ui/Components.ps1")
. (Join-Path -Path $srcDir -ChildPath "ui/Layout.ps1")
. (Join-Path -Path $srcDir -ChildPath "ui/Prompts.ps1")
. (Join-Path -Path $srcDir -ChildPath "ui/Navigation.ps1")
. (Join-Path -Path $srcDir -ChildPath "ui/Dashboard.ps1")

# Source Functional Modules
. (Join-Path -Path $srcDir -ChildPath "modules/LicensingStatus/LicensingInspector.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/OfficeInformation/OfficeDiscovery.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Maintenance/SystemFileChecker.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Maintenance/DismServicing.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Maintenance/LicensingServiceRepair.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/WindowsManagement/EditionInspector.ps1")
. (Join-Path -Path $srcDir -ChildPath "modules/Network/ConnectivityCheck.ps1")

# Initialize Runtime State
$config = Get-ToolkitConfiguration
Initialize-ToolkitLogger -Subdirectory $config.LogDirectory -RetentionDays $config.LogRetentionDays
$envInfo = Get-ToolkitEnvironment
$isAdmin = Test-ToolkitAdmin
$useTrueColor = $config.EnableTrueColor -and $envInfo.SupportsTrueColor

# Quick Office Discovery for Telemetry Header
$officeSummary = Get-OfficeInstallationReport
$officeTag = if ($officeSummary.IsInstalled) {
    "Office C2R ($($officeSummary.Platform))"
}
else {
    "Not Installed"
}

# Process Unattended CLI Flags
if ($Info) {
    Show-ToolkitSystemOverviewScreen -Environment $envInfo -UseTrueColor $useTrueColor
    return
}
if ($Licensing) {
    Show-WindowsLicensingScreen -UseTrueColor $useTrueColor
    return
}
if ($Office) {
    Show-OfficeInformationScreen -UseTrueColor $useTrueColor
    return
}
if ($Network) {
    Show-NetworkDiagnosticsScreen -UseTrueColor $useTrueColor
    return
}

# Construct Main Menu Items
$menuItems = @(
    [MenuItem]::new(
        "1",
        "System Overview",
        "Hardware, processor, memory, Secure Boot and TPM readiness",
        "System & Licensing Inspection",
        "",
        { Show-ToolkitSystemOverviewScreen -Environment $envInfo -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "2",
        "Licensing Inspector",
        "Official WMI, CIM, and Software Protection licensing state",
        "System & Licensing Inspection",
        "",
        { Show-WindowsLicensingScreen -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "3",
        "Office Installation",
        "Click-to-Run suites, build numbers, and update channels",
        "System & Licensing Inspection",
        "",
        { Show-OfficeInformationScreen -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "4",
        "System File Integrity",
        "Run managed sfc /scannow and inspect component logs",
        "System Maintenance & Servicing",
        "",
        { Invoke-SystemFileChecker -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "5",
        "Component Servicing",
        "DISM CheckHealth, ScanHealth, and RestoreHealth routines",
        "System Maintenance & Servicing",
        "",
        { Invoke-DismServicing -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "6",
        "Licensing Store Repair",
        "Reset service descriptors, restart sppsvc, and refresh slmgr",
        "System Maintenance & Servicing",
        "",
        { Invoke-LicensingServiceRepair -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "7",
        "Windows Edition Info",
        "Current SKU, composition edition, and DISM target upgrades",
        "Windows Management & Network",
        "",
        { Show-WindowsEditionScreen -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "8",
        "Network Diagnostics",
        "Active adapters, latency, and official Microsoft endpoints",
        "Windows Management & Network",
        "",
        { Show-NetworkDiagnosticsScreen -UseTrueColor $useTrueColor }
    ),
    [MenuItem]::new(
        "A",
        "About, Credits & License",
        "GNU GPL-3.0 license, upstream research credits, and URLs",
        "Application Information",
        "",
        { Show-ToolkitAboutScreen -UseTrueColor $useTrueColor }
    )
)

$renderHeaderAction = {
    Write-ToolkitHeader -Environment $envInfo `
                        -OfficeStatus $officeTag `
                        -IsAdmin $isAdmin `
                        -Width $config.StandardWidth `
                        -UseTrueColor $useTrueColor `
                        -ForceAscii $config.ForceAsciiBorders
}

Write-ToolkitLog -Level "INFO" -Component "Main" -Message "Entering interactive menu loop."

# Launch Interactive Loop
Invoke-ToolkitMenuLoop -Items $menuItems `
                       -RenderHeader $renderHeaderAction `
                       -Width $config.StandardWidth `
                       -UseTrueColor $useTrueColor `
                       -ForceAscii $config.ForceAsciiBorders

Write-ToolkitLog -Level "INFO" -Component "Main" -Message "Application exited cleanly."
Clear-ToolkitScreen


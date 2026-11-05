<#
.SYNOPSIS
    System environment and terminal capability detection engine.
.DESCRIPTION
    Discovers Windows build numbers, architecture, PowerShell host capabilities,
    and determines whether TrueColor 24-bit ANSI, 16-color ANSI, or legacy console APIs should be used.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

class SystemEnvironmentInfo {
    [string]$OsName = "Windows"
    [int]$BuildNumber = 0
    [string]$DisplayVersion = "Unknown"
    [string]$Architecture = "x64"
    [string]$PowerShellVersion = "5.1"
    [string]$PowerShellEdition = "Desktop"
    [bool]$IsWindowsTerminal = $false
    [bool]$SupportsTrueColor = $false
    [bool]$SupportsAnsi = $false
    [bool]$IsConsoleOutputRedirected = $false
    [int]$WindowWidth = 94
    [int]$WindowHeight = 32
}

function Get-ToolkitEnvironment {
    [CmdletBinding()]
    [OutputType([SystemEnvironmentInfo])]
    param()

    $envInfo = [SystemEnvironmentInfo]::new()

    # Determine PowerShell runtime
    $envInfo.PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    if ($PSVersionTable.PSEdition) {
        $envInfo.PowerShellEdition = $PSVersionTable.PSEdition
    }

    # Detect Windows Architecture
    if ($env:PROCESSOR_ARCHITEW6432) {
        $envInfo.Architecture = $env:PROCESSOR_ARCHITEW6432
    }
    elseif ($env:PROCESSOR_ARCHITECTURE) {
        $envInfo.Architecture = $env:PROCESSOR_ARCHITECTURE
    }

    # Query OS Version & Build from Registry when on Windows
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        try {
            $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
            $regProps = Get-ItemProperty -Path $regKey -ErrorAction Stop

            if ($regProps.ProductName) {
                $envInfo.OsName = [string]$regProps.ProductName
            }

            if ($regProps.CurrentBuildNumber) {
                $envInfo.BuildNumber = [int]$regProps.CurrentBuildNumber
            }
            elseif ($regProps.CurrentBuild) {
                $envInfo.BuildNumber = [int]$regProps.CurrentBuild
            }

            if ($regProps.DisplayVersion) {
                $envInfo.DisplayVersion = [string]$regProps.DisplayVersion
            }
            elseif ($regProps.ReleaseId) {
                $envInfo.DisplayVersion = [string]$regProps.ReleaseId
            }
        }
        catch {
            $envInfo.BuildNumber = [System.Environment]::OSVersion.Version.Build
        }
    }
    else {
        # Fallback for cross-platform/Linux mock environments
        $envInfo.OsName = "Linux / Test Environment"
        $envInfo.BuildNumber = 26100
        $envInfo.DisplayVersion = "24H2"
    }

    # Check if running inside Windows Terminal
    if ($env:WT_SESSION) {
        $envInfo.IsWindowsTerminal = $true
    }

    # Check console redirection
    try {
        if ([System.Console]::IsOutputRedirected) {
            $envInfo.IsConsoleOutputRedirected = $true
        }
    }
    catch {
        $envInfo.IsConsoleOutputRedirected = $false
    }

    # Determine ANSI and TrueColor support
    # Windows 10 Build >= 14393 natively supports ANSI; Build >= 16299 or Windows Terminal supports 24-bit TrueColor
    if ($envInfo.IsWindowsTerminal) {
        $envInfo.SupportsAnsi = $true
        $envInfo.SupportsTrueColor = $true
    }
    elseif ($envInfo.BuildNumber -ge 16299) {
        $envInfo.SupportsAnsi = $true
        $envInfo.SupportsTrueColor = $true
    }
    elseif ($envInfo.BuildNumber -ge 10586) {
        $envInfo.SupportsAnsi = $true
        $envInfo.SupportsTrueColor = $false
    }
    else {
        $envInfo.SupportsAnsi = $false
        $envInfo.SupportsTrueColor = $false
    }

    # Determine Console dimensions safely
    try {
        if (-not $envInfo.IsConsoleOutputRedirected) {
            $width = [System.Console]::WindowWidth
            $height = [System.Console]::WindowHeight
            if ($width -ge 60) { $envInfo.WindowWidth = $width }
            if ($height -ge 20) { $envInfo.WindowHeight = $height }
        }
    }
    catch {
        # Keep defaults if window geometry cannot be queried
    }

    return $envInfo
}


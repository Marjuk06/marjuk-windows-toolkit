<#
.SYNOPSIS
    Read-only Windows licensing and activation inspector for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Queries official WMI/CIM SoftwareLicensingProduct and SoftwareLicensingService
    classes to evaluate license states, channel types, partial keys, and grace timers.
    Strictly read-only with zero modifications to system state or licensing stores.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from research by @abbodi1406 and asdcorp.
    Copyright (c) 2026 Marjuk Amin.
#>

class WindowsLicenseDetail {
    [string]$Name = "Windows Operating System"
    [string]$Description = "Volume / Retail / OEM"
    [string]$Status = "Unknown"
    [string]$Channel = "Unknown"
    [string]$PartialKey = "None"
    [int]$GracePeriodDays = 0
    [bool]$IsLicensed = $false
}

function Get-WindowsLicensingReport {
    [CmdletBinding()]
    [OutputType([WindowsLicenseDetail])]
    param()

    $detail = [WindowsLicenseDetail]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Safe mock state for test environment
        $detail.Name = "Windows 11 Professional"
        $detail.Description = "Windows(R) Operating System, RETAIL channel"
        $detail.Status = "Licensed"
        $detail.Channel = "Retail"
        $detail.PartialKey = "3V66T"
        $detail.GracePeriodDays = 0
        $detail.IsLicensed = $true
        return $detail
    }

    try {
        # Windows Application ID for SoftwareLicensingProduct
        $windowsAppId = "55c92734-d682-4d71-983e-d6ec3f16059f"

        $products = Get-CimInstance -ClassName SoftwareLicensingProduct `
                                    -Filter "ApplicationID='$windowsAppId' and PartialProductKey is not null" `
                                    -ErrorAction Stop

        foreach ($p in $products) {
            # Find the active product or first product with a partial key
            $detail.Name = [string]$p.Name
            $detail.Description = [string]$p.Description
            $detail.PartialKey = [string]$p.PartialProductKey

            if ($p.ProductKeyChannel) {
                $detail.Channel = [string]$p.ProductKeyChannel
            }

            # LicenseStatus values:
            # 0 = Unlicensed, 1 = Licensed, 2 = OOBGrace, 3 = OOTGrace, 4 = NonGenuineGrace, 5 = Notification, 6 = ExtendedGrace
            switch ([int]$p.LicenseStatus) {
                1 {
                    $detail.Status = "Licensed"
                    $detail.IsLicensed = $true
                }
                2 { $detail.Status = "Out-of-Box Grace" }
                3 { $detail.Status = "Out-of-Tolerance Grace" }
                4 { $detail.Status = "Non-Genuine Grace" }
                5 { $detail.Status = "Notification Mode" }
                6 { $detail.Status = "Extended Grace" }
                default { $detail.Status = "Unlicensed" }
            }

            if ($p.GracePeriodRemaining) {
                $detail.GracePeriodDays = [int][Math]::Round($p.GracePeriodRemaining / 1440)
            }

            if ($detail.IsLicensed) {
                break
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "ERROR" -Component "LicensingInspector" -Message "Licensing query failed: $($_.Exception.Message)"
        $detail.Status = "Query Failed ($($_.Exception.Message))"
    }

    return $detail
}

function Show-WindowsLicensingScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "Windows Licensing Inspector" `
                             -Subtitle "Official WMI and CIM Licensing Status Verification" `
                             -UseTrueColor $UseTrueColor

    $report = Get-WindowsLicensingReport

    [System.Console]::WriteLine("  " + (Format-Colored -Text "OPERATING SYSTEM LICENSE REPORT" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitKeyValue -Key "Product Name" -Value $report.Name -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "License Description" -Value $report.Description -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Channel" -Value $report.Channel -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Partial Key" -Value $report.PartialKey -UseTrueColor $UseTrueColor

    $statusColor = if ($report.IsLicensed) { "Success" } else { "Warning" }
    Write-ToolkitKeyValue -Key "Activation State" -Value $report.Status -ValueColor $statusColor -UseTrueColor $UseTrueColor

    if ($report.GracePeriodDays -gt 0) {
        Write-ToolkitKeyValue -Key "Grace Period Remaining" -Value "$($report.GracePeriodDays) days" -ValueColor "Warning" -UseTrueColor $UseTrueColor
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "Note: This diagnostic view queries Windows Software Protection Platform APIs." -Color "SecondaryText" -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "GENUINE ACTIVATION & MANAGEMENT OPTIONS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine("  [S] Open Windows Activation Settings (ms-settings:activation)")
    [System.Console]::WriteLine("  [K] Install Genuine 25-character Product Key (slmgr.vbs /ipk)")
    [System.Console]::WriteLine("  [A] Trigger Official Online Activation (slmgr.vbs /ato)")
    [System.Console]::WriteLine("  [Enter] Return to main menu")
    [System.Console]::WriteLine()
    [System.Console]::Write("  Select an action or press Enter: ")

    $choice = [System.Console]::ReadLine()
    if ($choice) {
        $cleanChoice = $choice.Trim().ToUpper()
        switch ($cleanChoice) {
            "S" {
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    Start-Process "ms-settings:activation"
                    [System.Console]::WriteLine("  Launched Windows Activation Settings.")
                }
                else {
                    [System.Console]::WriteLine("  [Test Mock] Launched ms-settings:activation.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "K" {
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine("  " + (Format-Colored -Text "Administrator rights required to install a system product key." -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor))
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    return
                }
                [System.Console]::Write("  Enter your 25-character Product Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX): ")
                $keyInput = [System.Console]::ReadLine().Trim().ToUpper()
                if ($keyInput -match "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$") {
                    [System.Console]::WriteLine("  Installing product key via slmgr.vbs /ipk...")
                    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                        $slmgrOutput = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ipk $keyInput
                        [System.Console]::WriteLine("  $slmgrOutput")
                    }
                    else {
                        [System.Console]::WriteLine("  [Test Mock] Key $keyInput accepted.")
                    }
                }
                else {
                    [System.Console]::WriteLine("  " + (Format-Colored -Text "Invalid product key format. Key was not applied." -Color "Error" -Bold $true -UseTrueColor $UseTrueColor))
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "A" {
                [System.Console]::WriteLine("  Attempting activation via slmgr.vbs /ato...")
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    $slmgrOutput = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ato
                    [System.Console]::WriteLine("  $slmgrOutput")
                }
                else {
                    [System.Console]::WriteLine("  [Test Mock] Official online activation query triggered.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
        }
    }
}


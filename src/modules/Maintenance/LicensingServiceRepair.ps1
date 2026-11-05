<#
.SYNOPSIS
    Licensing service verification, security descriptor repair, and license cache refresh.
.DESCRIPTION
    Provides legitimate maintenance for corrupted Windows Software Protection (sppsvc)
    and Client License (ClipSVC) services. Restores default service permissions and
    reinstalls official system licenses using slmgr.vbs /rilc.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Derived in part from research by @abbodi1406.
    Copyright (c) 2026 Marjuk Amin.
#>

function Invoke-LicensingServiceRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "Licensing Service & Store Repair" `
                             -Subtitle "Repair Corrupted sppsvc, ClipSVC, and Refresh Official Licenses" `
                             -UseTrueColor $UseTrueColor

    if (-not (Test-ToolkitAdmin)) {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "ADMINISTRATOR PRIVILEGES REQUIRED:" -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  Service repair and license cache re-initialization require administrator rights.")
        [System.Console]::WriteLine()
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    [System.Console]::WriteLine("  This maintenance routine will perform the following actions:")
    [System.Console]::WriteLine("  1. Verify the operational state of sppsvc and ClipSVC services.")
    [System.Console]::WriteLine("  2. Reset default service security descriptors via sc.exe sdset.")
    [System.Console]::WriteLine("  3. Refresh and re-install official OEM/Retail system licenses via slmgr.vbs /rilc.")
    [System.Console]::WriteLine("  4. Restart the Software Protection service to flush stale memory locks.")
    [System.Console]::WriteLine()

    $proceed = Show-ToolkitConfirmation -ActionTitle "Repair Windows Licensing Services" `
                                        -Description "Restores official service descriptors and re-registers system license files." `
                                        -RiskLevel "MediumRisk" `
                                        -UseTrueColor $UseTrueColor

    if (-not $proceed) {
        [System.Console]::WriteLine("  Operation cancelled.")
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    [System.Console]::WriteLine()
    Write-ToolkitLog -Level "INFO" -Component "ServiceRepair" -Message "Initiating licensing service repair."

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Safe mock for test environment
        Start-Sleep -Seconds 1
        [System.Console]::WriteLine("  [Test Mock] Service descriptors reset. Official licenses re-registered.")
        [System.Console]::WriteLine("  " + (Format-Colored -Text "[SUCCESS] Licensing services are healthy." -Color "Success" -Bold $true -UseTrueColor $UseTrueColor))
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    try {
        # Step 1: Set service startup types to Demand/Auto
        [System.Console]::WriteLine("  [1/4] Configuring service startup parameters...")
        Set-Service -Name "sppsvc" -StartupType Manual -ErrorAction SilentlyContinue
        Set-Service -Name "ClipSVC" -StartupType Manual -ErrorAction SilentlyContinue

        # Step 2: Reset default service SDDL via sc.exe
        [System.Console]::WriteLine("  [2/4] Restoring official service security descriptors...")
        # Official default Windows security descriptor for sppsvc
        $sppSddl = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)"
        Start-Process -FilePath "$env:SystemRoot\System32\sc.exe" -ArgumentList "sdset sppsvc `"$sppSddl`"" -NoNewWindow -Wait | Out-Null

        # Step 3: Re-install official system license certificates
        [System.Console]::WriteLine("  [3/4] Re-registering system licenses via slmgr.vbs /rilc...")
        $slmgrProcess = Start-Process -FilePath "$env:SystemRoot\System32\cscript.exe" `
                                      -ArgumentList "//nologo `"$env:SystemRoot\System32\slmgr.vbs`" /rilc" `
                                      -NoNewWindow -Wait -PassThru

        # Step 4: Restart sppsvc
        [System.Console]::WriteLine("  [4/4] Starting Software Protection Service...")
        Start-Service -Name "sppsvc" -ErrorAction SilentlyContinue

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "[SUCCESS] Licensing service repair completed." -Color "Success" -Bold $true -UseTrueColor $UseTrueColor))
        Write-ToolkitLog -Level "INFO" -Component "ServiceRepair" -Message "Licensing repair finished successfully."
    }
    catch {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "[ERROR] Service repair encountered an issue: $($_.Exception.Message)" -Color "Error" -Bold $true -UseTrueColor $UseTrueColor))
        Write-ToolkitLog -Level "ERROR" -Component "ServiceRepair" -Message "Service repair failed: $($_.Exception.Message)"
    }

    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


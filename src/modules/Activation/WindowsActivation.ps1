<#
.SYNOPSIS
    Windows Digital License (HWID), Product Key, and Genuine Activation Module.
.DESCRIPTION
    Detects Windows HWID digital license entitlements via EditionUpgradeManager COM
    and Software Licensing Service (SLS), identifies generic default vs unique keys,
    inspects UEFI/BIOS OA3x embedded product keys, verifies edition and channel states,
    and integrates official Microsoft activation workflows.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from diagnostic research by @abbodi1406 and asdcorp (MIT).
    Copyright (c) 2026 Marjuk Amin.
#>

class WindowsDigitalLicenseReport {
    [string]$OsEdition = "Unknown"
    [string]$ProductName = "Windows Operating System"
    [string]$Description = "Unknown"
    [string]$SkuId = "None"
    [string]$Channel = "Unknown"
    [string]$PartialProductKey = "None"
    [string]$KeyClassification = "Unknown"
    [int]$LicenseStatusCode = 0
    [string]$LicenseStatusText = "Unlicensed"
    [int]$LicenseReasonHr = 0
    [string]$LicenseReasonHex = "0x00000000"
    [bool]$IsLicensed = $false
    [bool]$IsPermanent = $false
    [bool]$HasDigitalLicense = $false
    [string]$DigitalLicenseSummary = "Undetected"
    [bool]$BiosOemKeyPresent = $false
    [string]$BiosOemKeyMasked = "Not Present in UEFI/BIOS"
    [string]$BiosOemKeyRaw = ""
    [string]$BiosOemKeyDescription = "None"
    [int]$GracePeriodDays = 0
    [int]$GracePeriodMinutes = 0
}

$script:MarjukEumComType = $null

function Get-WindowsKeyClassification {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PartialKey = "",

        [Parameter(Mandatory = $false)]
        [string]$Channel = ""
    )

    if ([string]::IsNullOrWhiteSpace($PartialKey) -or $PartialKey -eq "None") {
        return "No Key Installed"
    }

    # Well-known Microsoft Generic Default Keys (HWID Digital License Carriers)
    $genericRetailKeys = @{
        "3V66T" = "Generic Default Key (Win 10/11 Pro Digital Entitlement Carrier)"
        "H8Q99" = "Generic Default Key (Win 10/11 Home Digital Entitlement Carrier)"
        "8HVX7" = "Generic Default Key (Win 10/11 Pro N Digital Entitlement Carrier)"
        "27V28" = "Generic Default Key (Win 10/11 Education Digital Entitlement Carrier)"
        "6F4BT" = "Generic Default Key (Win 10/11 Home Single Language Carrier)"
        "X3WVW" = "Generic Default Key (Win 10/11 Enterprise Digital Carrier)"
        "DXG7C" = "Generic Default Key (Win 10/11 Pro for Workstations Carrier)"
    }

    # Well-known Microsoft Public KMS Client Setup Keys (GVLK)
    $publicGvlkKeys = @{
        "T83GX" = "Official Microsoft Public GVLK (Win 10/11 Pro KMS Client)"
        "MH37W" = "Official Microsoft Public GVLK (Win 10/11 Pro N KMS Client)"
        "NW6C2" = "Official Microsoft Public GVLK (Win 10/11 Education KMS Client)"
        "2BX7T" = "Official Microsoft Public GVLK (Win 10/11 Enterprise KMS Client)"
        "DPH2V" = "Official Microsoft Public GVLK (Win 10/11 Enterprise N KMS Client)"
        "NRG8B" = "Official Microsoft Public GVLK (Win 10/11 Pro Workstations KMS Client)"
        "M7XTQ" = "Official Microsoft Public GVLK (Win 10/11 Enterprise LTSC KMS Client)"
    }

    $upper = $PartialKey.Trim().ToUpper()
    if ($genericRetailKeys.ContainsKey($upper)) {
        return $genericRetailKeys[$upper]
    }
    if ($publicGvlkKeys.ContainsKey($upper)) {
        return $publicGvlkKeys[$upper]
    }

    if ($Channel -match "OEM") {
        return "Unique OEM License Key ($Channel)"
    }
    elseif ($Channel -match "Retail") {
        return "Unique Retail Product Key"
    }
    elseif ($Channel -match "MAK") {
        return "Volume Multiple Activation Key (MAK)"
    }

    return "Installed Product Key ($Channel)"
}

function Test-WindowsDigitalEntitlementCom {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return 0
    }

    try {
        $sysPath = "$env:SystemRoot\System32"
        if (-not (Test-Path -LiteralPath "$sysPath\EditionUpgradeManagerObj.dll")) {
            return -1
        }

        if ($null -eq $script:MarjukEumComType) {
            $cab = [System.Reflection.Emit.CustomAttributeBuilder]
            $asmName = New-Object System.Reflection.AssemblyName("MarjukEumInteropAssembly")
            if ([System.Reflection.Emit.AssemblyBuilder].GetMethod("DefineDynamicAssembly", @([System.Reflection.AssemblyName], [System.Reflection.Emit.AssemblyBuilderAccess]))) {
                $dynAsm = [System.Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly($asmName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            }
            else {
                $dynAsm = [AppDomain]::CurrentDomain.DefineDynamicAssembly($asmName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            }
            $dynMod = $dynAsm.DefineDynamicModule("MarjukEumInteropModule")
            $iCom = $dynMod.DefineType("MarjukEumInterface", 'Public, Interface, Abstract, Import')
            $iCom.SetCustomAttribute($cab::new([System.Runtime.InteropServices.ComImportAttribute].GetConstructor(@()), @()))
            $iCom.SetCustomAttribute($cab::new([System.Runtime.InteropServices.GuidAttribute].GetConstructor(@([String])), @('F2DCB80D-0670-44BC-9002-CD18688730AF')))
            $iCom.SetCustomAttribute($cab::new([System.Runtime.InteropServices.InterfaceTypeAttribute].GetConstructor(@([Int16])), @([Int16]1)))
            1..4 | ForEach-Object {
                [void]$iCom.DefineMethod("VF$_", 'Public, Virtual, HideBySig, NewSlot, Abstract', 'Standard, HasThis', [Void], @())
            }
            [void]$iCom.DefineMethod('AcquireModernLicenseForWindows', 1478, 33, [Int32], @([Int32], [Int32].MakeByRefType()))
            $script:MarjukEumComType = $iCom.CreateType()
        }

        $comObj = New-Object -ComObject EditionUpgradeManagerObj.EditionUpgradeManager
        $params = @(1, 0)
        $hr = $script:MarjukEumComType.GetMethod("AcquireModernLicenseForWindows").Invoke($comObj, $params)
        if ($hr -ne 0) {
            return -1
        }
        return [int]$params[1]
    }
    catch {
        return -1
    }
}

function Get-WindowsDigitalLicenseStatus {
    [CmdletBinding()]
    [OutputType([WindowsDigitalLicenseReport])]
    param()

    $report = [WindowsDigitalLicenseReport]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        $report.OsEdition = "Professional"
        $report.ProductName = "Windows 11 Pro"
        $report.Description = "Windows(R) Operating System, RETAIL channel"
        $report.SkuId = "4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c"
        $report.Channel = "Retail"
        $report.PartialProductKey = "3V66T"
        $report.KeyClassification = Get-WindowsKeyClassification -PartialKey "3V66T" -Channel "Retail"
        $report.LicenseStatusCode = 1
        $report.LicenseStatusText = "Licensed"
        $report.IsLicensed = $true
        $report.IsPermanent = $true
        $report.HasDigitalLicense = $true
        $report.DigitalLicenseSummary = "Active (Verified HWID Digital Entitlement)"
        $report.BiosOemKeyPresent = $false
        $report.BiosOemKeyMasked = "Not Present in UEFI/BIOS"
        return $report
    }

    try {
        $ntKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if (Test-Path -LiteralPath $ntKey) {
            $ntProps = Get-ItemProperty -Path $ntKey -ErrorAction SilentlyContinue
            if ($ntProps.EditionID) {
                $report.OsEdition = [string]$ntProps.EditionID
            }
        }

        # Check BIOS OA3x Original Product Key via SoftwareLicensingService
        $sls = Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue
        if ($sls) {
            if (-not [string]::IsNullOrWhiteSpace($sls.OA3xOriginalProductKey)) {
                $rawKey = [string]$sls.OA3xOriginalProductKey
                $report.BiosOemKeyPresent = $true
                $report.BiosOemKeyRaw = $rawKey
                if ($rawKey.Length -ge 5) {
                    $last5 = $rawKey.Substring($rawKey.Length - 5)
                    $report.BiosOemKeyMasked = "XXXXX-XXXXX-XXXXX-XXXXX-$last5"
                }
                if ($sls.OA3xOriginalProductKeyDescription) {
                    $report.BiosOemKeyDescription = [string]$sls.OA3xOriginalProductKeyDescription
                }
            }
        }

        # Query SoftwareLicensingProduct for Windows AppID
        $winAppId = "55c92734-d682-4d71-983e-d6ec3f16059f"
        $products = Get-CimInstance -ClassName SoftwareLicensingProduct `
                                    -Filter "ApplicationID='$winAppId' and PartialProductKey is not null" `
                                    -ErrorAction Stop

        # Prioritize licensed SKU or primary OS SKU
        $selectedProduct = $products | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
        if (-not $selectedProduct) {
            $selectedProduct = $products | Select-Object -First 1
        }

        if ($selectedProduct) {
            $p = $selectedProduct
            $report.ProductName = [string]$p.Name
            $report.Description = [string]$p.Description
            $report.SkuId = [string]$p.ID
            $report.PartialProductKey = [string]$p.PartialProductKey
            $report.LicenseStatusCode = [int]$p.LicenseStatus

            if ($null -ne $p.LicenseStatusReason) {
                $report.LicenseReasonHr = [int]$p.LicenseStatusReason
                $report.LicenseReasonHex = "0x{0:X8}" -f $p.LicenseStatusReason
            }

            if ($p.ProductKeyChannel) {
                $report.Channel = [string]$p.ProductKeyChannel
            }
            elseif ($p.Description -match "RETAIL") {
                $report.Channel = "Retail"
            }
            elseif ($p.Description -match "OEM") {
                $report.Channel = "OEM"
            }
            elseif ($p.Description -match "VOLUME_KMSCLIENT") {
                $report.Channel = "Volume:GVLK"
            }
            elseif ($p.Description -match "VOLUME_MAK") {
                $report.Channel = "Volume:MAK"
            }

            $report.KeyClassification = Get-WindowsKeyClassification -PartialKey $report.PartialProductKey -Channel $report.Channel

            if ($null -ne $p.GracePeriodRemaining) {
                $report.GracePeriodMinutes = [int]$p.GracePeriodRemaining
                $report.GracePeriodDays = [int][Math]::Round($p.GracePeriodRemaining / 1440)
            }

            switch ($report.LicenseStatusCode) {
                1 {
                    $report.LicenseStatusText = "Licensed"
                    $report.IsLicensed = $true
                    if ($report.GracePeriodMinutes -eq 0) {
                        $report.IsPermanent = $true
                    }
                }
                2 { $report.LicenseStatusText = "Initial Out-of-Box Grace Period" }
                3 { $report.LicenseStatusText = "Additional Out-of-Tolerance Grace Period" }
                4 { $report.LicenseStatusText = "Non-Genuine Grace Period" }
                5 { $report.LicenseStatusText = "Notification Mode ($($report.LicenseReasonHex))" }
                6 { $report.LicenseStatusText = "Extended Grace Period" }
                default { $report.LicenseStatusText = "Unlicensed ($($report.LicenseReasonHex))" }
            }
        }

        # Evaluate Digital License (HWID) state
        $eumCode = Test-WindowsDigitalEntitlementCom
        if ($eumCode -ge 0 -and $eumCode -ne 1) {
            $report.HasDigitalLicense = $true
            $report.DigitalLicenseSummary = "Active (Verified via EditionUpgradeManager COM)"
        }
        elseif ($report.IsLicensed -and $report.IsPermanent -and ($report.Channel -match "Retail|OEM")) {
            $report.HasDigitalLicense = $true
            $report.DigitalLicenseSummary = "Permanent Entitlement ($($report.Channel) Channel)"
        }
        elseif ($report.IsLicensed -and -not $report.IsPermanent) {
            $report.HasDigitalLicense = $false
            $report.DigitalLicenseSummary = "Time-Based Volume Activation ($($report.GracePeriodDays) days remaining)"
        }
        else {
            $report.HasDigitalLicense = $false
            $report.DigitalLicenseSummary = "No Active Digital License Detected"
        }
    }
    catch {
        Write-ToolkitLog -Level "ERROR" -Component "WindowsActivation" -Message "Failed to query Windows digital license status: $($_.Exception.Message)"
        $report.LicenseStatusText = "Query Error ($($_.Exception.Message))"
    }

    return $report
}

function Show-WindowsDigitalLicenseScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    while ($true) {
        Clear-ToolkitScreen
        Write-ToolkitScreenTitle -Title "Windows HWID & Digital License Inspector" `
                                 -Subtitle "Digital Entitlement Detection, Key Classification & Genuine Workflows" `
                                 -UseTrueColor $UseTrueColor

        $status = Get-WindowsDigitalLicenseStatus

        [System.Console]::WriteLine("  " + (Format-Colored -Text "WINDOWS LICENSING & DIGITAL ENTITLEMENT" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        Write-ToolkitKeyValue -Key "Windows Edition" -Value "$($status.ProductName) [$($status.OsEdition)]" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "License Description" -Value $status.Description -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "SKU Activation ID" -Value $status.SkuId -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Product Key Channel" -Value $status.Channel -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Partial Product Key" -Value $status.PartialProductKey -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Key Classification" -Value $status.KeyClassification -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor

        $actColor = if ($status.IsLicensed) { "Success" } else { "Warning" }
        $actLabel = if ($status.IsLicensed -and $status.IsPermanent) {
            "Licensed (Permanent Activation)"
        }
        elseif ($status.IsLicensed) {
            "Licensed (Volume Renewal in $($status.GracePeriodDays) days)"
        }
        else {
            $status.LicenseStatusText
        }
        Write-ToolkitKeyValue -Key "Activation State" -Value $actLabel -ValueColor $actColor -UseTrueColor $UseTrueColor

        $dlColor = if ($status.HasDigitalLicense) { "Success" } else { "SecondaryText" }
        Write-ToolkitKeyValue -Key "HWID Digital License" -Value $status.DigitalLicenseSummary -ValueColor $dlColor -UseTrueColor $UseTrueColor

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "UEFI / BIOS EMBEDDED FIRMWARE KEY (OA3x MSDM)" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        $oemColor = if ($status.BiosOemKeyPresent) { "Success" } else { "SecondaryText" }
        Write-ToolkitKeyValue -Key "Firmware Key Status" -Value $status.BiosOemKeyMasked -ValueColor $oemColor -UseTrueColor $UseTrueColor
        if ($status.BiosOemKeyPresent) {
            Write-ToolkitKeyValue -Key "Firmware Edition Info" -Value $status.BiosOemKeyDescription -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "GENUINE DIGITAL LICENSE & KEY WORKFLOWS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  [1] Re-Verify Digital License & Genuine Entitlement State")
        [System.Console]::WriteLine("  [2] Install Genuine 25-Character Product Key (slmgr.vbs /ipk)")
        [System.Console]::WriteLine("  [3] Apply Embedded UEFI/BIOS Firmware Key to System")
        [System.Console]::WriteLine("  [4] Trigger Official Microsoft Online Activation (slmgr.vbs /ato)")
        [System.Console]::WriteLine("  [5] Open Windows Activation Settings GUI (ms-settings:activation)")
        [System.Console]::WriteLine("  [0] Return to Activation Hub")
        [System.Console]::WriteLine()
        [System.Console]::Write("  Select an option [0-5]: ")

        $choice = [System.Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($choice) -or $choice.Trim() -eq "0") {
            break
        }

        switch ($choice.Trim()) {
            "1" {
                [System.Console]::WriteLine()
                Write-ToolkitProgressBar -Percent 50 -StatusMessage "Querying ClipSVC and EditionUpgradeManager COM..." -UseTrueColor $UseTrueColor
                $recheck = Get-WindowsDigitalLicenseStatus
                Write-ToolkitProgressBar -Percent 100 -StatusMessage "Verification complete." -UseTrueColor $UseTrueColor
                [System.Console]::WriteLine()
                if ($recheck.IsLicensed) {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " Windows licensing state verified: $($recheck.LicenseStatusText)")
                }
                else {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " System is not currently licensed: $($recheck.LicenseStatusText)")
                }
                Write-ToolkitLog -Level "INFO" -Component "WindowsActivation" -Message "Manual verification completed. State: $($recheck.LicenseStatusText)"
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "2" {
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to install a product key.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }
                [System.Console]::WriteLine()
                [System.Console]::Write("  Enter 25-character Product Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX): ")
                $enteredKey = [System.Console]::ReadLine()
                if (-not $enteredKey) { continue }
                $cleanKey = $enteredKey.Trim().ToUpper()

                if ($cleanKey -notmatch "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$") {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "FAIL" -UseTrueColor $UseTrueColor) + " Invalid key format. Expected 5 groups of 5 alphanumeric characters.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                $proceed = Show-ToolkitConfirmation -ActionTitle "Install Product Key ($($cleanKey.Substring(0,5))-...)" `
                                                    -Description "Applies the specified product key to Windows Software Protection Platform via slmgr.vbs /ipk." `
                                                    -RiskLevel "MediumRisk" `
                                                    -UseTrueColor $UseTrueColor
                if ($proceed) {
                    Write-ToolkitProgressBar -Percent 50 -StatusMessage "Installing product key via slmgr.vbs..." -UseTrueColor $UseTrueColor
                    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                        $out = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ipk $cleanKey 2>&1
                        Write-ToolkitProgressBar -Percent 100 -StatusMessage "Command completed." -UseTrueColor $UseTrueColor
                        [System.Console]::WriteLine("  Output: $($out -join ' ')")
                    }
                    else {
                        Write-ToolkitProgressBar -Percent 100 -StatusMessage "Mock key installation complete." -UseTrueColor $UseTrueColor
                    }
                    Write-ToolkitLog -Level "INFO" -Component "WindowsActivation" -Message "Executed slmgr /ipk for user-provided product key."
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "3" {
                if (-not $status.BiosOemKeyPresent -or [string]::IsNullOrWhiteSpace($status.BiosOemKeyRaw)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " No embedded OA3x OEM product key was found in UEFI/BIOS firmware on this machine.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to apply the firmware product key.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }
                $proceed = Show-ToolkitConfirmation -ActionTitle "Apply Embedded UEFI/BIOS Key ($($status.BiosOemKeyMasked))" `
                                                    -Description "Installs the hardware manufacturer's OA3x key embedded in your motherboard firmware." `
                                                    -RiskLevel "MediumRisk" `
                                                    -UseTrueColor $UseTrueColor
                if ($proceed) {
                    Write-ToolkitProgressBar -Percent 50 -StatusMessage "Applying UEFI OA3x product key..." -UseTrueColor $UseTrueColor
                    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                        $out = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ipk $status.BiosOemKeyRaw 2>&1
                        Write-ToolkitProgressBar -Percent 100 -StatusMessage "Firmware key applied." -UseTrueColor $UseTrueColor
                        [System.Console]::WriteLine("  Output: $($out -join ' ')")
                    }
                    Write-ToolkitLog -Level "INFO" -Component "WindowsActivation" -Message "Applied OA3x firmware key."
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "4" {
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to trigger system activation.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }
                [System.Console]::WriteLine()
                Write-ToolkitProgressBar -Percent 30 -StatusMessage "Contacting Microsoft licensing services (slmgr.vbs /ato)..." -UseTrueColor $UseTrueColor
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    $out = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ato 2>&1
                    [System.Console]::WriteLine("  Service Response: $($out -join ' ')")
                }
                Write-ToolkitProgressBar -Percent 80 -StatusMessage "Verifying post-activation licensing state..." -UseTrueColor $UseTrueColor
                $verified = Get-WindowsDigitalLicenseStatus
                Write-ToolkitProgressBar -Percent 100 -StatusMessage "Verification finished." -UseTrueColor $UseTrueColor
                [System.Console]::WriteLine()
                if ($verified.IsLicensed) {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " Activation verified: Windows reports Licensed state ($($verified.Channel)).")
                }
                else {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Windows is still unlicensed ($($verified.LicenseStatusText)). Ensure a valid product key or digital entitlement is present.")
                }
                Write-ToolkitLog -Level "INFO" -Component "WindowsActivation" -Message "Online activation triggered. Verified IsLicensed=$($verified.IsLicensed)"
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "5" {
                [System.Console]::WriteLine()
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    Start-Process "ms-settings:activation"
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " Launched Windows Activation Settings.")
                }
                else {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " [Linux Preview] Would launch ms-settings:activation.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
        }
    }
}

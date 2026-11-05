<#
.SYNOPSIS
    Activation Diagnostics, Error Code Analyzer, Troubleshooter, and Unified Hub Module.
.DESCRIPTION
    Provides deep Software Protection Platform (SPP) telemetry, service state verification
    (sppsvc, ClipSVC, wlidsvc), token store inspection, HRESULT activation error translation,
    consolidated license reporting, automated troubleshooting, and the interactive
    Activation Management Hub.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from diagnostic research by @abbodi1406 and asdcorp (MIT).
    Copyright (c) 2026 Marjuk Amin.
#>

class ActivationServiceDiag {
    [string]$SlsVersion = "Unknown"
    [int]$RemainingRearmCount = 0
    [string]$SppsvcState = "Unknown"
    [string]$ClipSvcState = "Unknown"
    [string]$WlidSvcState = "Unknown"
    [bool]$TokensDatPresent = $false
    [string]$TokensDatPath = "None"
}

function Resolve-ActivationErrorCode {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorCode
    )

    $normalized = $ErrorCode.Trim().ToUpper()
    if (-not $normalized.StartsWith("0X") -and $normalized.Length -eq 8) {
        $normalized = "0X$normalized"
    }

    $knownCodes = @{
        "0XC004F074" = @{
            Symbolic = "SL_E_CHPA_NO_KMS_AVAILABLE"
            Cause    = "The Software Licensing Service reported that no Key Management Service (KMS) could be contacted."
            Action   = "Verify corporate VPN/network connection, check TCP port 1688 firewall rules, or switch to a Retail/MAK key if this is a personal device."
        }
        "0XC004C003" = @{
            Symbolic = "SL_E_CHPA_BLOCKED_PRODUCT_KEY"
            Cause    = "The activation server determined the specified product key is blocked or invalid for this edition."
            Action   = "Verify that your Windows edition matches your genuine entitlement or apply your embedded UEFI OA3x key."
        }
        "0XC004F200" = @{
            Symbolic = "SL_E_NON_GENUINE"
            Cause    = "The Software Protection Service reported that the current license is non-genuine."
            Action   = "Open Windows Activation Settings (ms-settings:activation) and run the official Activation Troubleshooter."
        }
        "0XC004F00F" = @{
            Symbolic = "SL_E_OUT_OF_TOLERANCE"
            Cause    = "The hardware ID (HWID) has changed significantly since activation, or the KMS grace period expired."
            Action   = "Sign in with your Microsoft Account linked to your digital license and select 'I changed hardware on this device recently'."
        }
        "0XC004F050" = @{
            Symbolic = "SL_E_INVALID_PRODUCT_KEY"
            Cause    = "The Software Licensing Service reported that the product key is invalid or contains a typo."
            Action   = "Double-check the 25-character product key and ensure it corresponds to the installed Windows SKU."
        }
        "0XC004F034" = @{
            Symbolic = "SL_E_PKEY_NOT_FOUND"
            Cause    = "No valid license or product key was found for the current SKU."
            Action   = "Install a genuine product key via Option [1] Windows Digital License or run slmgr.vbs /rilc to refresh system licenses."
        }
        "0X8007232B" = @{
            Symbolic = "DNS_ERROR_RCODE_NAME_ERROR"
            Cause    = "DNS name does not exist. Windows is using a Volume GVLK key and could not find a corporate KMS SRV record (_vlmcs._tcp)."
            Action   = "If this is a personal PC, install a Retail/OEM product key. If organizational, configure the corporate KMS server via Option [3]."
        }
        "0X8007007B" = @{
            Symbolic = "ERROR_INVALID_NAME"
            Cause    = "The filename, directory name, or volume label syntax is incorrect during KMS lookup."
            Action   = "Clear invalid KMS host configurations using Option [3] -> Clear KMS Configuration (slmgr.vbs /ckms)."
        }
        "0X803FA067" = @{
            Symbolic = "CLIP_E_EDITION_UPGRADE_FAILED"
            Cause    = "Edition upgrade or digital entitlement transition failed while background services were busy or offline."
            Action   = "Ensure sppsvc and ClipSVC are running and retry with an active internet connection."
        }
        "0X80072EE7" = @{
            Symbolic = "ERROR_INTERNET_NAME_NOT_RESOLVED"
            Cause    = "Cannot resolve Microsoft activation server hostname (activation-v2.sls.microsoft.com)."
            Action   = "Check DNS settings and run Network Diagnostics to verify internet reachability."
        }
    }

    if ($knownCodes.ContainsKey($normalized)) {
        return $knownCodes[$normalized]
    }

    return @{
        Symbolic = "UNKNOWN_ACTIVATION_HRESULT ($normalized)"
        Cause    = "Unrecognized or generic Windows/SPP error code."
        Action   = "Run the Automated Activation Troubleshooter (Option 6) to inspect sppsvc, ClipSVC, and licensing tokens."
    }
}

function Get-ActivationDiagnosticsReport {
    [CmdletBinding()]
    [OutputType([ActivationServiceDiag])]
    param()

    $diag = [ActivationServiceDiag]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        $diag.SlsVersion = "10.0.26100.1"
        $diag.RemainingRearmCount = 1000
        $diag.SppsvcState = "Stopped (Trigger-Start Ready)"
        $diag.ClipSvcState = "Running (Manual)"
        $diag.WlidSvcState = "Stopped (Manual)"
        $diag.TokensDatPresent = $true
        $diag.TokensDatPath = "C:\Windows\System32\spp\store\2.0\tokens.dat"
        return $diag
    }

    try {
        $sls = Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue
        if ($sls) {
            if ($sls.Version) { $diag.SlsVersion = [string]$sls.Version }
            if ($null -ne $sls.RemainingWindowsReArmCount) {
                $diag.RemainingRearmCount = [int]$sls.RemainingWindowsReArmCount
            }
        }

        foreach ($svcName in @("sppsvc", "ClipSVC", "wlidsvc")) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            $stateStr = if ($svc) { "$($svc.Status) ($($svc.StartType))" } else { "Not Found" }
            switch ($svcName) {
                "sppsvc"  { $diag.SppsvcState = $stateStr }
                "ClipSVC" { $diag.ClipSvcState = $stateStr }
                "wlidsvc" { $diag.WlidSvcState = $stateStr }
            }
        }

        $tokenCandidates = @(
            "$env:SystemRoot\System32\spp\store\2.0\tokens.dat",
            "$env:SystemRoot\System32\spp\store\tokens.dat"
        )
        foreach ($cand in $tokenCandidates) {
            if (Test-Path -LiteralPath $cand) {
                $diag.TokensDatPresent = $true
                $diag.TokensDatPath = $cand
                break
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "ActivationDiagnostics" -Message "SPP diagnostic query warning: $($_.Exception.Message)"
    }

    return $diag
}

function Show-ActivationDiagnosticsScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    while ($true) {
        Clear-ToolkitScreen
        Write-ToolkitScreenTitle -Title "Deep Activation & SPP Diagnostics" `
                                 -Subtitle "Software Protection Services, Token Store & HRESULT Error Analyzer" `
                                 -UseTrueColor $UseTrueColor

        $diag = Get-ActivationDiagnosticsReport

        [System.Console]::WriteLine("  " + (Format-Colored -Text "SOFTWARE PROTECTION PLATFORM (SPP) TELEMETRY" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        Write-ToolkitKeyValue -Key "SLS Engine Version" -Value $diag.SlsVersion -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Remaining Rearm Count" -Value "$($diag.RemainingRearmCount)" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Software Protection (sppsvc)" -Value $diag.SppsvcState -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Client License (ClipSVC)" -Value $diag.ClipSvcState -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "MS Account Sign-In (wlidsvc)" -Value $diag.WlidSvcState -UseTrueColor $UseTrueColor

        $tokColor = if ($diag.TokensDatPresent) { "Success" } else { "Warning" }
        $tokText = if ($diag.TokensDatPresent) { "Present ($($diag.TokensDatPath))" } else { "Not Found" }
        Write-ToolkitKeyValue -Key "SPP Licensing Store" -Value $tokText -ValueColor $tokColor -UseTrueColor $UseTrueColor

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "DIAGNOSTIC UTILITIES" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  [1] Lookup / Analyze Activation Error Code (e.g. 0xC004F074, 0x8007232B)")
        [System.Console]::WriteLine("  [2] Run Detailed slmgr.vbs /dlv Licensing Output")
        [System.Console]::WriteLine("  [0] Return to Activation Hub")
        [System.Console]::WriteLine()
        [System.Console]::Write("  Select an option [0-2]: ")

        $choice = [System.Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($choice) -or $choice.Trim() -eq "0") {
            break
        }

        switch ($choice.Trim()) {
            "1" {
                [System.Console]::WriteLine()
                [System.Console]::Write("  Enter Activation Error Code (e.g. 0xC004F074): ")
                $codeInput = [System.Console]::ReadLine()
                if (-not [string]::IsNullOrWhiteSpace($codeInput)) {
                    $resolved = Resolve-ActivationErrorCode -ErrorCode $codeInput
                    [System.Console]::WriteLine()
                    Write-ToolkitKeyValue -Key "Symbolic Name" -Value $resolved.Symbolic -ValueColor "Warning" -UseTrueColor $UseTrueColor
                    Write-ToolkitKeyValue -Key "Root Cause" -Value $resolved.Cause -UseTrueColor $UseTrueColor
                    Write-ToolkitKeyValue -Key "Recommended Fix" -Value $resolved.Action -ValueColor "Success" -UseTrueColor $UseTrueColor
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "2" {
                [System.Console]::WriteLine()
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    Write-ToolkitProgressBar -Percent 50 -StatusMessage "Querying slmgr.vbs /dlv..." -UseTrueColor $UseTrueColor
                    $dlvOut = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /dlv 2>&1
                    Write-ToolkitProgressBar -Percent 100 -StatusMessage "Done." -UseTrueColor $UseTrueColor
                    [System.Console]::WriteLine()
                    foreach ($line in $dlvOut) {
                        [System.Console]::WriteLine("  $line")
                    }
                }
                else {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " [Linux Preview] slmgr.vbs /dlv is supported on Windows hosts.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
        }
    }
}

function Show-LicenseInformationScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Clear-ToolkitScreen
    Write-ToolkitScreenTitle -Title "Consolidated License Information Report" `
                             -Subtitle "Complete Windows, UEFI Firmware, Office & KMS Licensing Summary" `
                             -UseTrueColor $UseTrueColor

    $win = Get-WindowsDigitalLicenseStatus
    $off = Get-OfficeActivationDiagnostics
    $kms = Get-KmsConfigurationReport
    $spp = Get-ActivationDiagnosticsReport

    [System.Console]::WriteLine("  " + (Format-Colored -Text "1. WINDOWS OPERATING SYSTEM LICENSING" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    Write-ToolkitKeyValue -Key "Product & Edition" -Value "$($win.ProductName) [$($win.OsEdition)]" -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Channel / Partial Key" -Value "$($win.Channel) | Key: $($win.PartialProductKey)" -UseTrueColor $UseTrueColor
    $wColor = if ($win.IsLicensed) { "Success" } else { "Warning" }
    Write-ToolkitKeyValue -Key "Activation Status" -Value $win.LicenseStatusText -ValueColor $wColor -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Digital Entitlement" -Value $win.DigitalLicenseSummary -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "UEFI/BIOS OA3x Key" -Value $win.BiosOemKeyMasked -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "2. MICROSOFT OFFICE LICENSING" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    $oText = if ($off.IsInstalled) { "Installed ($($off.Version) [$($off.Architecture)])" } else { "Not Installed" }
    Write-ToolkitKeyValue -Key "Office Suite State" -Value $oText -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Release IDs" -Value $off.ProductReleaseIds -UseTrueColor $UseTrueColor
    $ohColor = if ($off.OhookDetected) { "Warning" } else { "Success" }
    $ohText = if ($off.OhookDetected) { "Modified (Ohook DLL Proxy Present)" } else { "Clean (Genuine System32 sppc.dll)" }
    Write-ToolkitKeyValue -Key "DLL Integrity" -Value $ohText -ValueColor $ohColor -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "Installed WMI SKUs" -Value "$($off.WmiLicenses.Count) SKU(s) | vNext Tokens: $($off.VNextTokens.Count)" -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "3. KMS & SPP INFRASTRUCTURE" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    Write-ToolkitKeyValue -Key "Registered KMS Host" -Value "$($kms.RegisteredKmsHost):$($kms.RegisteredKmsPort)" -UseTrueColor $UseTrueColor
    $kAuditColor = if ($kms.UnauthorizedConfigDetected) { "Warning" } else { "Success" }
    $kAuditText = if ($kms.UnauthorizedConfigDetected) { "Warnings Present ($($kms.SecurityWarnings.Count))" } else { "Verified Clean" }
    Write-ToolkitKeyValue -Key "KMS Security Audit" -Value $kAuditText -ValueColor $kAuditColor -UseTrueColor $UseTrueColor
    Write-ToolkitKeyValue -Key "SPP Service / Store" -Value "SLS v$($spp.SlsVersion) | Store Present: $($spp.TokensDatPresent)" -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine()
    Show-ToolkitPause -UseTrueColor $UseTrueColor
}

function Show-ActivationTroubleshooterScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Clear-ToolkitScreen
    Write-ToolkitScreenTitle -Title "Automated Activation Troubleshooter" `
                             -Subtitle "6-Point Diagnostic Health Check & Genuine Recovery Guidance" `
                             -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine("  " + (Format-Colored -Text "EXECUTING AUTOMATED LICENSING DIAGNOSTICS..." -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    $win = Get-WindowsDigitalLicenseStatus
    $off = Get-OfficeActivationDiagnostics
    $kms = Get-KmsConfigurationReport
    $spp = Get-ActivationDiagnosticsReport
    $slsNet = Test-EndpointReachability -HostName "Microsoft Licensing SLS" -Url "https://activation-v2.sls.microsoft.com"

    $recommendations = @()

    # Check 1: SPP & ClipSVC Services
    if ($spp.TokensDatPresent) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [1/6] SPP Licensing Store (tokens.dat) is present and accessible.")
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " [1/6] SPP Licensing Store (tokens.dat) was not found in standard paths.")
        $recommendations += "Run Licensing Service & Store Repair (Main Menu Option 6) to rebuild system licenses."
    }

    # Check 2: Windows Activation Status
    if ($win.IsLicensed) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [2/6] Windows is currently Licensed ($($win.Channel) Channel).")
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " [2/6] Windows is Unlicensed ($($win.LicenseStatusText)).")
        if ($win.BiosOemKeyPresent) {
            $recommendations += "An embedded UEFI/BIOS OEM key ($($win.BiosOemKeyMasked)) was found! Apply it in 'Windows Digital License' -> Option [3]."
        }
        else {
            $recommendations += "Open Windows Activation Settings (ms-settings:activation) to run the Microsoft Activation Troubleshooter."
        }
    }

    # Check 3: Digital Entitlement / Channel Consistency
    if ($win.Channel -eq "Volume:GVLK" -and -not $kms.IsKmsClientChannel) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " [3/6] Volume GVLK key is installed without an active organizational KMS server.")
        $recommendations += "If this is a personal PC, switch from Volume GVLK to a Retail/OEM product key."
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [3/6] Product key channel ($($win.Channel)) is consistent.")
    }

    # Check 4: KMS Integrity
    if ($kms.UnauthorizedConfigDetected) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " [4/6] Non-standard KMS server or IFEO hook detected ($($kms.RegisteredKmsHost)).")
        $recommendations += "Use 'KMS Management' -> Option [1] to clear unauthorized KMS servers and IFEO hooks."
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [4/6] KMS client configuration is clean.")
    }

    # Check 5: Office DLL Integrity
    if ($off.OhookDetected) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " [5/6] Office Ohook sppc.dll proxy modification detected.")
        $recommendations += "Use 'Office Activation' -> Option [3] to remove unauthorized sppc.dll proxy files."
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [5/6] Office system library integrity is clean.")
    }

    # Check 6: Microsoft SLS Endpoint Connectivity
    if ($slsNet.Reachable) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " [6/6] Microsoft Activation Server (activation-v2.sls.microsoft.com) is reachable.")
    }
    else {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "FAIL" -UseTrueColor $UseTrueColor) + " [6/6] Cannot reach Microsoft Activation Server ($($slsNet.Details)).")
        $recommendations += "Check firewall and DNS settings; online activation requires HTTPS access to *.sls.microsoft.com."
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "TROUBLESHOOTER RECOMMENDATIONS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    if ($recommendations.Count -eq 0) {
        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " All licensing services, endpoints, and configurations passed inspection.")
    }
    else {
        foreach ($rec in $recommendations) {
            [System.Console]::WriteLine("  -> $rec")
        }
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  [1] Launch Official Windows Activation Troubleshooter (ms-settings:activation)")
    [System.Console]::WriteLine("  [2] Run Licensing Service & Store Repair Now")
    [System.Console]::WriteLine("  [0] Return to Activation Hub")
    [System.Console]::WriteLine()
    [System.Console]::Write("  Select an action [0-2]: ")

    $act = [System.Console]::ReadLine()
    if ($act) {
        switch ($act.Trim()) {
            "1" {
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    Start-Process "ms-settings:activation"
                }
            }
            "2" {
                Invoke-LicensingServiceRepair -UseTrueColor $UseTrueColor
            }
        }
    }
}

function Show-ActivationHubScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [SystemEnvironmentInfo]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$OfficeStatus = "Detected",

        [Parameter(Mandatory = $false)]
        [bool]$IsAdmin = $false,

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    if (-not $Environment) {
        $Environment = Get-ToolkitEnvironment
    }

    $hubItems = @(
        [MenuItem]::new(
            "1",
            "Windows Digital License",
            "HWID entitlement status, BIOS key & genuine activation",
            "Windows & Office Licensing",
            "",
            { Show-WindowsDigitalLicenseScreen -UseTrueColor $UseTrueColor }
        ),
        [MenuItem]::new(
            "2",
            "Office Activation",
            "Office C2R licensing, M365 vNext tokens & Ohook audit",
            "Windows & Office Licensing",
            "",
            { Show-OfficeActivationScreen -UseTrueColor $UseTrueColor }
        ),
        [MenuItem]::new(
            "3",
            "KMS Management",
            "KMS server inspection, hook warnings & cleanup",
            "Volume Licensing & Diagnostics",
            "",
            { Show-KmsManagementScreen -UseTrueColor $UseTrueColor }
        ),
        [MenuItem]::new(
            "4",
            "Activation Diagnostics",
            "Deep SPP telemetry, service health & error code lookup",
            "Volume Licensing & Diagnostics",
            "",
            { Show-ActivationDiagnosticsScreen -UseTrueColor $UseTrueColor }
        ),
        [MenuItem]::new(
            "5",
            "License Information",
            "Consolidated Windows, Office, BIOS & KMS report",
            "Reporting & Remediation",
            "",
            { Show-LicenseInformationScreen -UseTrueColor $UseTrueColor }
        ),
        [MenuItem]::new(
            "6",
            "Activation Troubleshooter",
            "Automated 6-point licensing check & guided recovery",
            "Reporting & Remediation",
            "",
            { Show-ActivationTroubleshooterScreen -UseTrueColor $UseTrueColor }
        )
    )

    $headerBlock = {
        Write-ToolkitHeader -Environment $Environment `
                            -OfficeStatus $OfficeStatus `
                            -IsAdmin $IsAdmin `
                            -Width $Width `
                            -UseTrueColor $UseTrueColor `
                            -ForceAscii $ForceAscii
    }

    Invoke-ToolkitMenuLoop -Items $hubItems `
                           -RenderHeader $headerBlock `
                           -Width $Width `
                           -UseTrueColor $UseTrueColor `
                           -ForceAscii $ForceAscii
}

<#
.SYNOPSIS
    Microsoft Office Licensing, vNext Token Verification, and Ohook Integrity Audit Module.
.DESCRIPTION
    Detects Microsoft Office Click-to-Run and Volume installations, inspects WMI/CIM
    Office licensing SKUs, decodes Microsoft 365 vNext JSON entitlement tokens,
    audits Office directories for unauthorized Ohook (sppc.dll) proxy modifications,
    and provides official Office activation troubleshooting.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from diagnostic research by @abbodi1406.
    Copyright (c) 2026 Marjuk Amin.
#>

class OfficeLicenseEntry {
    [string]$ProductName = "Office SKU"
    [string]$Description = "Unknown"
    [string]$PartialKey = "None"
    [string]$StatusText = "Unlicensed"
    [bool]$IsLicensed = $false
    [int]$GraceDays = 0
}

class OfficeVNextToken {
    [string]$ProductReleaseId = "Unknown"
    [string]$LicenseType = "User"
    [string]$State = "Unknown"
    [string]$ExpiresOn = "N/A"
    [string]$Scope = "User"
}

class OfficeActivationAuditReport {
    [bool]$IsInstalled = $false
    [string]$Version = "None"
    [string]$Architecture = "None"
    [string]$UpdateChannel = "None"
    [string]$ProductReleaseIds = "None"
    [string]$InstallPath = "None"
    [bool]$OhookDetected = $false
    [string[]]$OhookPaths = @()
    [OfficeLicenseEntry[]]$WmiLicenses = @()
    [OfficeVNextToken[]]$VNextTokens = @()
    [string[]]$LicensingNextModes = @()
}

function Test-OfficeOhookModification {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $foundPaths = @()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return $foundPaths
    }

    $roots = @($env:ProgramFiles, $env:ProgramW6432, ${env:ProgramFiles(x86)}) |
             Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
             Select-Object -Unique

    foreach ($root in $roots) {
        foreach ($ver in @(15, 16)) {
            $legacyDir = Join-Path -Path $root -ChildPath "Microsoft Office\Office$ver"
            if (Test-Path -LiteralPath $legacyDir) {
                $dlls = Get-ChildItem -Path $legacyDir -Filter "sppc*.dll" -ErrorAction SilentlyContinue
                foreach ($d in $dlls) {
                    $foundPaths += $d.FullName
                }
            }
        }

        foreach ($sysDir in @("System", "SystemX86")) {
            foreach ($offFolder in @("Microsoft Office", "Microsoft Office 15")) {
                $vfsDir = Join-Path -Path $root -ChildPath "$offFolder\root\vfs\$sysDir"
                if (Test-Path -LiteralPath $vfsDir) {
                    $dlls = Get-ChildItem -Path $vfsDir -Filter "sppc*.dll" -ErrorAction SilentlyContinue
                    foreach ($d in $dlls) {
                        $foundPaths += $d.FullName
                    }
                }
            }
        }
    }

    return ($foundPaths | Select-Object -Unique)
}

function Get-OfficeVNextTokens {
    [CmdletBinding()]
    [OutputType([OfficeVNextToken[]])]
    param()

    $tokens = @()
    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return $tokens
    }

    $locations = @(
        @{ Scope = "User"; Path = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Office\Licenses" },
        @{ Scope = "Device"; Path = Join-Path -Path $env:PROGRAMDATA -ChildPath "Microsoft\Office\Licenses" }
    )

    foreach ($loc in $locations) {
        if (Test-Path -LiteralPath $loc.Path) {
            $files = Get-ChildItem -Path $loc.Path -Recurse -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $rawJson = Get-Content -LiteralPath $file.FullName -Encoding Unicode -Raw -ErrorAction Stop | ConvertFrom-Json
                    if ($rawJson.License) {
                        $decodedBytes = [System.Convert]::FromBase64String($rawJson.License)
                        $decodedStr = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
                        $licObj = $decodedStr | ConvertFrom-Json

                        $tok = [OfficeVNextToken]::new()
                        $tok.Scope = $loc.Scope
                        if ($licObj.ProductReleaseId) { $tok.ProductReleaseId = [string]$licObj.ProductReleaseId }
                        if ($licObj.LicenseType) { $tok.LicenseType = [string]$licObj.LicenseType }
                        if ($licObj.ExpiresOn) { $tok.ExpiresOn = [string]$licObj.ExpiresOn }

                        $now = Get-Date
                        $tok.State = "Grace"
                        if ($licObj.Metadata.NotAfter -and ($now -gt (Get-Date $licObj.Metadata.NotAfter))) {
                            $tok.State = "Expired (RFM)"
                        }
                        elseif ($licObj.ExpiresOn -and ($now -lt (Get-Date $licObj.ExpiresOn))) {
                            $tok.State = "Licensed"
                        }
                        elseif ($licObj.Status -eq "Enabled") {
                            $tok.State = "Licensed"
                        }

                        $tokens += $tok
                    }
                }
                catch {
                    # Skip non-JSON or unreadable license cache files
                }
            }
        }
    }

    return $tokens
}

function Get-OfficeActivationDiagnostics {
    [CmdletBinding()]
    [OutputType([OfficeActivationAuditReport])]
    param()

    $audit = [OfficeActivationAuditReport]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        $audit.IsInstalled = $true
        $audit.Version = "16.0.17830.20166"
        $audit.Architecture = "x64"
        $audit.UpdateChannel = "Current Channel"
        $audit.ProductReleaseIds = "ProPlus2021Volume, M365Apps"
        $audit.InstallPath = "C:\Program Files\Microsoft Office"
        $audit.OhookDetected = $false

        $mockLic = [OfficeLicenseEntry]::new()
        $mockLic.ProductName = "Office 21, Office21ProPlus2021VL_KMS_Client_AE edition"
        $mockLic.Description = "Office 21, VOLUME_KMSCLIENT channel"
        $mockLic.PartialKey = "FXYTK"
        $mockLic.StatusText = "Licensed"
        $mockLic.IsLicensed = $true
        $mockLic.GraceDays = 180
        $audit.WmiLicenses += $mockLic

        $mockTok = [OfficeVNextToken]::new()
        $mockTok.ProductReleaseId = "O365ProPlusRetail"
        $mockTok.LicenseType = "Subscription"
        $mockTok.State = "Licensed"
        $mockTok.ExpiresOn = "2027-01-01"
        $mockTok.Scope = "User"
        $audit.VNextTokens += $mockTok

        return $audit
    }

    try {
        $c2rInfo = Get-OfficeInstallationReport
        $audit.IsInstalled = $c2rInfo.IsInstalled
        $audit.Version = $c2rInfo.Version
        $audit.Architecture = $c2rInfo.Platform
        $audit.UpdateChannel = $c2rInfo.UpdateChannel
        $audit.ProductReleaseIds = $c2rInfo.InstalledProducts
        $audit.InstallPath = $c2rInfo.ClientFolder

        # 1. Check Ohook modification status
        $ohookFiles = Test-OfficeOhookModification
        if ($ohookFiles.Count -gt 0) {
            $audit.OhookDetected = $true
            $audit.OhookPaths = $ohookFiles
        }

        # 2. Check vNext Registry Modes
        $vNextKey = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Licensing\LicensingNext"
        if (Test-Path -LiteralPath $vNextKey) {
            $props = Get-Item -Path $vNextKey -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
            foreach ($pName in $props) {
                if ($pName -match "retail|volume") {
                    $val = (Get-ItemProperty -Path $vNextKey -Name $pName -ErrorAction SilentlyContinue).$pName
                    $modeStr = switch ($val) {
                        2 { "vNext (Modern Account)" }
                        3 { "Device License" }
                        default { "Legacy (C2R/OSPP)" }
                    }
                    $audit.LicensingNextModes += "$pName = $modeStr"
                }
            }
        }

        # 3. Check vNext Tokens
        $audit.VNextTokens = Get-OfficeVNextTokens

        # 4. Query WMI SoftwareLicensingProduct for Office 15/16 AppID
        $officeAppId = "0ff1ce15-a989-479d-af46-f275c6370663"
        $products = Get-CimInstance -ClassName SoftwareLicensingProduct `
                                    -Filter "ApplicationID='$officeAppId' and PartialProductKey is not null" `
                                    -ErrorAction SilentlyContinue

        foreach ($p in $products) {
            $entry = [OfficeLicenseEntry]::new()
            $entry.ProductName = [string]$p.Name
            $entry.Description = [string]$p.Description
            $entry.PartialKey = [string]$p.PartialProductKey
            if ($null -ne $p.GracePeriodRemaining) {
                $entry.GraceDays = [int][Math]::Round($p.GracePeriodRemaining / 1440)
            }
            switch ([int]$p.LicenseStatus) {
                1 {
                    $entry.StatusText = "Licensed"
                    $entry.IsLicensed = $true
                }
                2 { $entry.StatusText = "Initial Grace Period ($($entry.GraceDays) days)" }
                3 { $entry.StatusText = "Out-of-Tolerance Grace ($($entry.GraceDays) days)" }
                4 { $entry.StatusText = "Non-Genuine Grace" }
                5 { $entry.StatusText = "Notification / Unlicensed" }
                6 { $entry.StatusText = "Extended Grace ($($entry.GraceDays) days)" }
                default { $entry.StatusText = "Unlicensed" }
            }
            $audit.WmiLicenses += $entry
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "OfficeActivation" -Message "Office diagnostic query warning: $($_.Exception.Message)"
    }

    return $audit
}

function Show-OfficeActivationScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    while ($true) {
        Clear-ToolkitScreen
        Write-ToolkitScreenTitle -Title "Microsoft Office Activation & Integrity" `
                                 -Subtitle "Click-to-Run Licensing, M365 vNext Tokens & Ohook Integrity Audit" `
                                 -UseTrueColor $UseTrueColor

        $audit = Get-OfficeActivationDiagnostics

        [System.Console]::WriteLine("  " + (Format-Colored -Text "INSTALLATION & OHOOK INTEGRITY AUDIT" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        $instColor = if ($audit.IsInstalled) { "Success" } else { "Warning" }
        $instText = if ($audit.IsInstalled) { "Installed ($($audit.Version) [$($audit.Architecture)])" } else { "Not Detected" }
        Write-ToolkitKeyValue -Key "Office Installation" -Value $instText -ValueColor $instColor -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Configured Products" -Value $audit.ProductReleaseIds -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Update Channel" -Value $audit.UpdateChannel -UseTrueColor $UseTrueColor

        if ($audit.OhookDetected) {
            Write-ToolkitKeyValue -Key "Ohook Integrity Check" -Value "[WARNING] Ohook sppc.dll Proxy Detected" -ValueColor "Warning" -UseTrueColor $UseTrueColor
            foreach ($op in $audit.OhookPaths) {
                Write-ToolkitKeyValue -Key "  Hooked Library" -Value $op -ValueColor "CrimsonAccent" -UseTrueColor $UseTrueColor
            }
        }
        else {
            Write-ToolkitKeyValue -Key "Ohook Integrity Check" -Value "Clean (No sppc.dll hooks in Office VFS)" -ValueColor "Success" -UseTrueColor $UseTrueColor
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "MICROSOFT 365 vNEXT & ACCOUNT LICENSES" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        if ($audit.VNextTokens.Count -eq 0 -and $audit.LicensingNextModes.Count -eq 0) {
            [System.Console]::WriteLine("  " + (Format-Colored -Text "No Microsoft 365 vNext subscription tokens detected in user/device profile." -Color "SecondaryText" -UseTrueColor $UseTrueColor))
        }
        else {
            foreach ($m in $audit.LicensingNextModes) {
                Write-ToolkitKeyValue -Key "LicensingNext Mode" -Value $m -UseTrueColor $UseTrueColor
            }
            foreach ($tok in $audit.VNextTokens) {
                $tColor = if ($tok.State -eq "Licensed") { "Success" } else { "Warning" }
                Write-ToolkitKeyValue -Key "vNext ($($tok.ProductReleaseId))" -Value "$($tok.State) [$($tok.LicenseType) | Exp: $($tok.ExpiresOn)]" -ValueColor $tColor -UseTrueColor $UseTrueColor
            }
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "WMI / OSPP INSTALLED PRODUCT LICENSES" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        if ($audit.WmiLicenses.Count -eq 0) {
            [System.Console]::WriteLine("  " + (Format-Colored -Text "No legacy/volume Office WMI product keys currently installed." -Color "SecondaryText" -UseTrueColor $UseTrueColor))
        }
        else {
            foreach ($lic in $audit.WmiLicenses) {
                $lColor = if ($lic.IsLicensed) { "Success" } else { "Warning" }
                Write-ToolkitKeyValue -Key "SKU Name" -Value $lic.ProductName -UseTrueColor $UseTrueColor
                Write-ToolkitKeyValue -Key "  Key / Status" -Value "Partial Key: $($lic.PartialKey) | State: $($lic.StatusText)" -ValueColor $lColor -UseTrueColor $UseTrueColor
            }
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "OFFICE LICENSING ACTIONS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  [1] Refresh Office Licensing & Token Telemetry")
        [System.Console]::WriteLine("  [2] Run Official OSPP.VBS /dstatus Diagnostic Query")
        [System.Console]::WriteLine("  [3] Clean Up Detected Ohook DLL Modifications (Restore Genuine State)")
        [System.Console]::WriteLine("  [0] Return to Activation Hub")
        [System.Console]::WriteLine()
        [System.Console]::Write("  Select an option [0-3]: ")

        $choice = [System.Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($choice) -or $choice.Trim() -eq "0") {
            break
        }

        switch ($choice.Trim()) {
            "1" {
                [System.Console]::WriteLine()
                Write-ToolkitProgressBar -Percent 100 -StatusMessage "Office licensing telemetry refreshed." -UseTrueColor $UseTrueColor
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "2" {
                [System.Console]::WriteLine()
                if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " [Linux Preview] OSPP.VBS requires a Windows Office host.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                $osppLocations = @(
                    "${env:ProgramFiles}\Microsoft Office\Office16\ospp.vbs",
                    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs"
                )
                $osppFile = $osppLocations | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

                if (-not $osppFile) {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Could not locate ospp.vbs in standard Office16 paths.")
                }
                else {
                    Write-ToolkitProgressBar -Percent 50 -StatusMessage "Executing cscript ospp.vbs /dstatus..." -UseTrueColor $UseTrueColor
                    $osppOut = & cscript.exe //nologo "$osppFile" /dstatus 2>&1
                    Write-ToolkitProgressBar -Percent 100 -StatusMessage "OSPP query finished." -UseTrueColor $UseTrueColor
                    [System.Console]::WriteLine()
                    foreach ($line in $osppOut) {
                        [System.Console]::WriteLine("  $line")
                    }
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "3" {
                if (-not $audit.OhookDetected) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " No Ohook DLL modifications were found on this machine. Office VFS is clean.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to remove hooked DLL files from Program Files.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                $proceed = Show-ToolkitConfirmation -ActionTitle "Remove Unauthorized Ohook DLL Proxy Files" `
                                                    -Description "Deletes custom sppc*.dll proxy files from the Office VFS folder so Office loads genuine Windows System32 sppc.dll." `
                                                    -RiskLevel "MediumRisk" `
                                                    -UseTrueColor $UseTrueColor
                if ($proceed) {
                    foreach ($hookPath in $audit.OhookPaths) {
                        # Safety check: Only delete inside Microsoft Office directories, never System32
                        if ($hookPath -match "Microsoft Office" -and $hookPath -notmatch "Windows\\System32") {
                            Remove-Item -LiteralPath $hookPath -Force -ErrorAction SilentlyContinue
                            [System.Console]::WriteLine("  Removed: $hookPath")
                            Write-ToolkitLog -Level "INFO" -Component "OfficeActivation" -Message "Removed Ohook file: $hookPath"
                        }
                    }
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " Ohook proxy cleanup complete.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
        }
    }
}

<#
.SYNOPSIS
    Key Management Service (KMS) Inspection, Security Audit, and Cleanup Module.
.DESCRIPTION
    Detects configured KMS servers, DNS SRV auto-discovery state, Client Machine IDs (CMID),
    and renewal intervals. Audits the system for unauthorized public KMS emulators or
    IFEO SppExtComObj hooks, provides cleanup routines (slmgr /ckms), and troubleshoots
    official organizational KMS connectivity on TCP port 1688.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Portions derived from diagnostic research by @abbodi1406.
    Copyright (c) 2026 Marjuk Amin.
#>

class KmsAuditReport {
    [bool]$IsKmsClientChannel = $false
    [string]$ClientMachineId = "Not Available"
    [string]$RegisteredKmsHost = "None (Auto-Discovery)"
    [int]$RegisteredKmsPort = 1688
    [string]$DiscoveredKmsHost = "None"
    [string]$DiscoveredKmsIp = "Not Available"
    [int]$ActivationIntervalMinutes = 120
    [int]$RenewalIntervalMinutes = 10080
    [bool]$HostCachingEnabled = $true
    [int]$RemainingGraceDays = 0
    [bool]$UnauthorizedConfigDetected = $false
    [string[]]$SecurityWarnings = @()
    [bool]$IfeoHookPresent = $false
    [string]$IfeoHookDetails = "None"
}

function Test-UnauthorizedKmsHost {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$HostName = ""
    )

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        return $false
    }

    $unauthorizedPatterns = @(
        "msguides\.com",
        "digiboy\.ir",
        "loli\.best",
        "xykz\.org",
        "kms8\.",
        "kms9\.",
        "kms\.srv\.crsoo",
        "kms\.cangshui",
        "^127\.0\.0\.",
        "^0\.0\.0\.0$",
        "^10\.0\.0\.10$",
        "^172\.16\.0\.2$"
    )

    foreach ($pat in $unauthorizedPatterns) {
        if ($HostName -match $pat) {
            return $true
        }
    }

    return $false
}

function Get-KmsConfigurationReport {
    [CmdletBinding()]
    [OutputType([KmsAuditReport])]
    param()

    $report = [KmsAuditReport]::new()

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        $report.IsKmsClientChannel = $false
        $report.ClientMachineId = "e5b8c2a1-9402-4f1a-8b12-90123456789a"
        $report.RegisteredKmsHost = "None (DNS Auto-Discovery)"
        $report.RegisteredKmsPort = 1688
        $report.DiscoveredKmsHost = "None"
        $report.UnauthorizedConfigDetected = $false
        return $report
    }

    try {
        # 1. Query SoftwareLicensingService for CMID and global KMS settings
        $sls = Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue
        if ($sls) {
            if ($sls.ClientMachineID) {
                $report.ClientMachineId = [string]$sls.ClientMachineID
            }
            if (-not [string]::IsNullOrWhiteSpace($sls.KeyManagementServiceName)) {
                $report.RegisteredKmsHost = [string]$sls.KeyManagementServiceName
            }
            if ($sls.KeyManagementServicePort) {
                $report.RegisteredKmsPort = [int]$sls.KeyManagementServicePort
            }
            if ($sls.VLActivationInterval) {
                $report.ActivationIntervalMinutes = [int]$sls.VLActivationInterval
            }
            if ($sls.VLRenewalInterval) {
                $report.RenewalIntervalMinutes = [int]$sls.VLRenewalInterval
            }
        }

        # 2. Query active KMS Client Product SKU
        $winAppId = "55c92734-d682-4d71-983e-d6ec3f16059f"
        $products = Get-CimInstance -ClassName SoftwareLicensingProduct `
                                    -Filter "ApplicationID='$winAppId' and PartialProductKey is not null" `
                                    -ErrorAction SilentlyContinue

        foreach ($p in $products) {
            if ($p.Description -match "VOLUME_KMSCLIENT") {
                $report.IsKmsClientChannel = $true
                if ($null -ne $p.GracePeriodRemaining) {
                    $report.RemainingGraceDays = [int][Math]::Round($p.GracePeriodRemaining / 1440)
                }
                if (-not [string]::IsNullOrWhiteSpace($p.KeyManagementServiceName)) {
                    $report.RegisteredKmsHost = [string]$p.KeyManagementServiceName
                }
                if ($p.KeyManagementServicePort -and $p.KeyManagementServicePort -ne 0) {
                    $report.RegisteredKmsPort = [int]$p.KeyManagementServicePort
                }
                if (-not [string]::IsNullOrWhiteSpace($p.DiscoveredKeyManagementServiceName)) {
                    $report.DiscoveredKmsHost = [string]$p.DiscoveredKeyManagementServiceName
                }
                if (-not [string]::IsNullOrWhiteSpace($p.DiscoveredKeyManagementServiceIpAddress)) {
                    $report.DiscoveredKmsIp = [string]$p.DiscoveredKeyManagementServiceIpAddress
                }
            }
        }

        # 3. Check SPP Registry for app-specific KMS overrides
        $sppKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        if (Test-Path -LiteralPath $sppKey) {
            $sppProps = Get-ItemProperty -Path $sppKey -ErrorAction SilentlyContinue
            if ($sppProps.KeyManagementServiceName -and $report.RegisteredKmsHost -match "^None") {
                $report.RegisteredKmsHost = [string]$sppProps.KeyManagementServiceName
            }
            if ($sppProps.DisableKeyManagementServiceHostCaching -eq 1) {
                $report.HostCachingEnabled = $false
            }
        }

        # 4. Check IFEO SppExtComObj.exe Hook (Unauthorized KMS Emulator Hook Detection)
        $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SppExtComObj.exe"
        if (Test-Path -LiteralPath $ifeoPath) {
            $ifeoProps = Get-ItemProperty -Path $ifeoPath -ErrorAction SilentlyContinue
            if ($ifeoProps.Debugger -or $null -ne $ifeoProps.KMS_Emulation) {
                $report.IfeoHookPresent = $true
                $report.UnauthorizedConfigDetected = $true
                $dbgVal = if ($ifeoProps.Debugger) { $ifeoProps.Debugger } else { "KMS_Emulation Registry Hook" }
                $report.IfeoHookDetails = "IFEO SppExtComObj.exe hook: $dbgVal"
                $report.SecurityWarnings += "Unauthorized IFEO Debugger hook detected on SppExtComObj.exe ($dbgVal)"
            }
        }

        # 5. Evaluate Registered KMS Host against known non-organizational / emulator servers
        if ($report.RegisteredKmsHost -notmatch "^None") {
            if (Test-UnauthorizedKmsHost -HostName $report.RegisteredKmsHost) {
                $report.UnauthorizedConfigDetected = $true
                $report.SecurityWarnings += "Registered KMS server '$($report.RegisteredKmsHost)' matches a known non-organizational or loopback KMS emulator."
            }
        }
    }
    catch {
        Write-ToolkitLog -Level "WARN" -Component "KmsManagement" -Message "KMS inspection warning: $($_.Exception.Message)"
    }

    return $report
}

function Test-KmsPortConnectivity {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Server,

        [Parameter(Mandatory = $false)]
        [int]$Port = 1688
    )

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return @{ Success = $true; LatencyMs = 15; Message = "TCP $Server`:$Port Connected (Mock)" }
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $tcp.BeginConnect($Server, $Port, $null, $null)
        $wait = $async.AsyncWaitHandle.WaitOne(3500, $false)
        if (-not $wait) {
            $tcp.Close()
            return @{ Success = $false; LatencyMs = 0; Message = "Connection timed out on TCP port $Port" }
        }
        $tcp.EndConnect($async)
        $sw.Stop()
        $tcp.Close()
        return @{ Success = $true; LatencyMs = [int]$sw.ElapsedMilliseconds; Message = "Reachable ($($sw.ElapsedMilliseconds) ms)" }
    }
    catch {
        $tcp.Close()
        return @{ Success = $false; LatencyMs = 0; Message = "Unreachable ($($_.Exception.Message))" }
    }
}

function Show-KmsManagementScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    while ($true) {
        Clear-ToolkitScreen
        Write-ToolkitScreenTitle -Title "KMS Configuration & Security Audit" `
                                 -Subtitle "Organizational Volume Licensing Inspection, Hook Detection & Cleanup" `
                                 -UseTrueColor $UseTrueColor

        $kms = Get-KmsConfigurationReport

        [System.Console]::WriteLine("  " + (Format-Colored -Text "KMS CLIENT CONFIGURATION & TELEMETRY" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        $chanText = if ($kms.IsKmsClientChannel) { "Active (VOLUME_KMSCLIENT Channel)" } else { "Inactive (Retail / OEM Channel In Use)" }
        $chanColor = if ($kms.IsKmsClientChannel) { "PrimaryText" } else { "SecondaryText" }
        Write-ToolkitKeyValue -Key "Volume KMS Client Mode" -Value $chanText -ValueColor $chanColor -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Client Machine ID (CMID)" -Value $kms.ClientMachineId -ValueColor "SecondaryText" -UseTrueColor $UseTrueColor

        $hostColor = if ($kms.UnauthorizedConfigDetected) { "Warning" } else { "PrimaryText" }
        Write-ToolkitKeyValue -Key "Registered KMS Server" -Value "$($kms.RegisteredKmsHost) (Port: $($kms.RegisteredKmsPort))" -ValueColor $hostColor -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "DNS Auto-Discovery Host" -Value "$($kms.DiscoveredKmsHost) [IP: $($kms.DiscoveredKmsIp)]" -UseTrueColor $UseTrueColor
        Write-ToolkitKeyValue -Key "Activation / Renewal" -Value "$($kms.ActivationIntervalMinutes) min / $($kms.RenewalIntervalMinutes) min" -UseTrueColor $UseTrueColor
        if ($kms.IsKmsClientChannel) {
            Write-ToolkitKeyValue -Key "Remaining KMS Grace" -Value "$($kms.RemainingGraceDays) days (of 180-day window)" -ValueColor "Success" -UseTrueColor $UseTrueColor
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "KMS INTEGRITY & UNAUTHORIZED HOOK AUDIT" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine()

        if ($kms.UnauthorizedConfigDetected) {
            Write-ToolkitKeyValue -Key "Audit Status" -Value "[WARNING] Non-Standard or Unauthorized KMS State" -ValueColor "Warning" -UseTrueColor $UseTrueColor
            foreach ($warn in $kms.SecurityWarnings) {
                [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " $warn")
            }
        }
        else {
            Write-ToolkitKeyValue -Key "Audit Status" -Value "Clean (No unauthorized KMS emulators or IFEO hooks)" -ValueColor "Success" -UseTrueColor $UseTrueColor
        }

        [System.Console]::WriteLine()
        [System.Console]::WriteLine("  " + (Format-Colored -Text "KMS MANAGEMENT & TROUBLESHOOTING OPERATIONS" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  [1] Clear Registered KMS Server & Remove IFEO Hooks (slmgr.vbs /ckms)")
        [System.Console]::WriteLine("  [2] Configure Official Organizational KMS Host (slmgr.vbs /skms)")
        [System.Console]::WriteLine("  [3] Test TCP Port 1688 Connectivity to KMS Host")
        [System.Console]::WriteLine("  [4] Query Organizational DNS SRV Records (_vlmcs._tcp)")
        [System.Console]::WriteLine("  [0] Return to Activation Hub")
        [System.Console]::WriteLine()
        [System.Console]::Write("  Select an option [0-4]: ")

        $choice = [System.Console]::ReadLine()
        if ([string]::IsNullOrWhiteSpace($choice) -or $choice.Trim() -eq "0") {
            break
        }

        switch ($choice.Trim()) {
            "1" {
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to clean up KMS configurations.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                $proceed = Show-ToolkitConfirmation -ActionTitle "Clear KMS Configuration & Unauthorized Hooks" `
                                                    -Description "Executes slmgr.vbs /ckms to clear hardcoded KMS servers and removes any unauthorized IFEO SppExtComObj.exe debugger hooks." `
                                                    -RiskLevel "MediumRisk" `
                                                    -UseTrueColor $UseTrueColor
                if ($proceed) {
                    Write-ToolkitProgressBar -Percent 40 -StatusMessage "Executing slmgr.vbs /ckms..." -UseTrueColor $UseTrueColor
                    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                        $out = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ckms 2>&1
                        [System.Console]::WriteLine("  slmgr: $($out -join ' ')")

                        # Remove IFEO SppExtComObj.exe hook if present
                        $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SppExtComObj.exe"
                        if (Test-Path -LiteralPath $ifeoPath) {
                            Remove-ItemProperty -Path $ifeoPath -Name "Debugger" -ErrorAction SilentlyContinue
                            Remove-ItemProperty -Path $ifeoPath -Name "KMS_Emulation" -ErrorAction SilentlyContinue
                            [System.Console]::WriteLine("  Removed IFEO SppExtComObj.exe hook entries.")
                        }
                    }
                    Write-ToolkitProgressBar -Percent 100 -StatusMessage "KMS configuration cleaned." -UseTrueColor $UseTrueColor
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " KMS server overrides cleared. Standard DNS auto-discovery restored.")
                    Write-ToolkitLog -Level "INFO" -Component "KmsManagement" -Message "Cleared KMS host configuration and IFEO hooks."
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "2" {
                if (-not (Test-ToolkitAdmin)) {
                    [System.Console]::WriteLine()
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "WARN" -UseTrueColor $UseTrueColor) + " Administrator privileges are required to set an organizational KMS server.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                [System.Console]::WriteLine()
                [System.Console]::Write("  Enter Organizational KMS Hostname or IP (e.g. kms.corp.example.com): ")
                $kmsHost = [System.Console]::ReadLine()
                if ([string]::IsNullOrWhiteSpace($kmsHost)) { continue }
                $cleanHost = $kmsHost.Trim()

                if (Test-UnauthorizedKmsHost -HostName $cleanHost) {
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "FAIL" -UseTrueColor $UseTrueColor) + " Blocked: '$cleanHost' is a known public emulator or loopback address. Only legitimate organizational KMS hosts are supported.")
                    Show-ToolkitPause -UseTrueColor $UseTrueColor
                    continue
                }

                $proceed = Show-ToolkitConfirmation -ActionTitle "Set Organizational KMS Server ($cleanHost)" `
                                                    -Description "Configures Windows Software Protection Platform to use $cleanHost via slmgr.vbs /skms." `
                                                    -RiskLevel "MediumRisk" `
                                                    -UseTrueColor $UseTrueColor
                if ($proceed) {
                    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                        $out = & cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /skms $cleanHost 2>&1
                        [System.Console]::WriteLine("  Output: $($out -join ' ')")
                    }
                    Write-ToolkitLog -Level "INFO" -Component "KmsManagement" -Message "Configured organizational KMS host: $cleanHost"
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "3" {
                [System.Console]::WriteLine()
                $targetHost = if ($kms.RegisteredKmsHost -notmatch "^None") { $kms.RegisteredKmsHost } elseif ($kms.DiscoveredKmsHost -notmatch "^None") { $kms.DiscoveredKmsHost } else { "" }
                if (-not $targetHost) {
                    [System.Console]::Write("  Enter KMS Hostname/IP to test TCP port 1688: ")
                    $targetHost = [System.Console]::ReadLine()
                }
                if (-not [string]::IsNullOrWhiteSpace($targetHost)) {
                    $cleanTarget = $targetHost.Trim()
                    Write-ToolkitProgressBar -Percent 50 -StatusMessage "Testing TCP socket connection to $cleanTarget`:$($kms.RegisteredKmsPort)..." -UseTrueColor $UseTrueColor
                    $res = Test-KmsPortConnectivity -Server $cleanTarget -Port $kms.RegisteredKmsPort
                    Write-ToolkitProgressBar -Percent 100 -StatusMessage "Test complete." -UseTrueColor $UseTrueColor
                    [System.Console]::WriteLine()
                    if ($res.Success) {
                        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " KMS TCP Port $($kms.RegisteredKmsPort): $($res.Message)")
                    }
                    else {
                        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "FAIL" -UseTrueColor $UseTrueColor) + " KMS TCP Port $($kms.RegisteredKmsPort): $($res.Message)")
                    }
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
            "4" {
                [System.Console]::WriteLine()
                Write-ToolkitProgressBar -Percent 50 -StatusMessage "Querying DNS SRV _vlmcs._tcp records..." -UseTrueColor $UseTrueColor
                if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                    try {
                        $srvRecords = Resolve-DnsName -Name "_vlmcs._tcp" -Type SRV -ErrorAction Stop
                        Write-ToolkitProgressBar -Percent 100 -StatusMessage "DNS SRV records found." -UseTrueColor $UseTrueColor
                        foreach ($rec in $srvRecords) {
                            if ($rec.NameTarget) {
                                [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "OK" -UseTrueColor $UseTrueColor) + " Discovered SRV Target: $($rec.NameTarget):$($rec.Port)")
                            }
                        }
                    }
                    catch {
                        Write-ToolkitProgressBar -Percent 100 -StatusMessage "DNS query finished." -UseTrueColor $UseTrueColor
                        [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " No _vlmcs._tcp SRV record found in current DNS search suffix.")
                    }
                }
                else {
                    Write-ToolkitProgressBar -Percent 100 -StatusMessage "Mock DNS SRV lookup complete." -UseTrueColor $UseTrueColor
                    [System.Console]::WriteLine("  " + (Get-StatusBadge -Status "INFO" -UseTrueColor $UseTrueColor) + " [Linux Preview] No active AD domain _vlmcs._tcp record.")
                }
                Show-ToolkitPause -UseTrueColor $UseTrueColor
            }
        }
    }
}

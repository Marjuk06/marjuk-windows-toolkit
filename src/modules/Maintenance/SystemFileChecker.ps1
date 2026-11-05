<#
.SYNOPSIS
    Managed System File Checker (SFC) maintenance module.
.DESCRIPTION
    Executes sfc /scannow with administrator validation, user confirmation,
    real-time output monitoring, and structured exit code interpretation.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Invoke-SystemFileChecker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "System File Integrity (SFC)" `
                             -Subtitle "Scan and Repair Corrupted Windows System Files" `
                             -UseTrueColor $UseTrueColor

    if (-not (Test-ToolkitAdmin)) {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "ADMINISTRATOR PRIVILEGES REQUIRED:" -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  System File Checker requires elevated administrator rights to inspect protected system files.")
        [System.Console]::WriteLine()

        $confirmElev = Show-ToolkitConfirmation -ActionTitle "Elevate Toolkit to Administrator" `
                                               -Description "Relaunch this toolkit with elevated administrator permissions." `
                                               -RiskLevel [SecurityRiskLevel]::LowRisk `
                                               -UseTrueColor $UseTrueColor

        if ($confirmElev) {
            Request-ToolkitElevation
        }
        return
    }

    $proceed = Show-ToolkitConfirmation -ActionTitle "Run System File Checker (sfc /scannow)" `
                                        -Description "Scans integrity of all protected system files and replaces corrupted files with cached copies." `
                                        -RiskLevel [SecurityRiskLevel]::MediumRisk `
                                        -UseTrueColor $UseTrueColor

    if (-not $proceed) {
        [System.Console]::WriteLine("  Operation cancelled by user.")
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  " + (Format-Colored -Text "Executing: sfc.exe /scannow ..." -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine("  " + (Format-Colored -Text "Please wait. This process may take several minutes to complete." -Color "SecondaryText" -UseTrueColor $UseTrueColor))
    [System.Console]::WriteLine()

    Write-ToolkitLog -Level "INFO" -Component "SFC" -Message "Starting sfc /scannow maintenance routine."

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Test environment mock
        Start-Sleep -Seconds 1
        [System.Console]::WriteLine("  [Test Mock] Windows Resource Protection did not find any integrity violations.")
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    $process = Start-Process -FilePath "$env:SystemRoot\System32\sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode

    [System.Console]::WriteLine()
    switch ($exitCode) {
        0 {
            [System.Console]::WriteLine("  " + (Format-Colored -Text "[SUCCESS] Windows Resource Protection did not find any integrity violations." -Color "Success" -Bold $true -UseTrueColor $UseTrueColor))
            Write-ToolkitLog -Level "INFO" -Component "SFC" -Message "SFC completed successfully with exit code 0."
        }
        default {
            [System.Console]::WriteLine("  " + (Format-Colored -Text "[NOTICE] SFC completed with exit code: $exitCode. Check CBS.log for detailed reports." -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor))
            Write-ToolkitLog -Level "WARN" -Component "SFC" -Message "SFC finished with exit code $exitCode."
        }
    }

    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


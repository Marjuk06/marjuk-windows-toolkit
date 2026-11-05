<#
.SYNOPSIS
    Managed Deployment Image Servicing and Management (DISM) component maintenance.
.DESCRIPTION
    Provides guided execution of DISM image servicing routines: CheckHealth,
    ScanHealth, and RestoreHealth with prerequisite elevation and confirmation checks.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Invoke-DismServicing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    Write-ToolkitScreenTitle -Title "Component Servicing (DISM)" `
                             -Subtitle "Windows Component Store Integrity and Image Repair" `
                             -UseTrueColor $UseTrueColor

    if (-not (Test-ToolkitAdmin)) {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "ADMINISTRATOR PRIVILEGES REQUIRED:" -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor))
        [System.Console]::WriteLine("  DISM image servicing requires elevated administrator rights.")
        [System.Console]::WriteLine()
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    [System.Console]::WriteLine("  Choose a DISM servicing operation:")
    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  [1] CheckHealth   Quickly inspects whether component store corruption has been flagged.")
    [System.Console]::WriteLine("  [2] ScanHealth    Scans component store for corruptions (Takes 5-10 minutes).")
    [System.Console]::WriteLine("  [3] RestoreHealth Scans and automatically repairs component store via Windows Update.")
    [System.Console]::WriteLine("  [0] Return        Go back to main menu.")
    [System.Console]::WriteLine()

    [System.Console]::Write("  Select an option [1-3, 0]: ")
    try {
        $key = [System.Console]::ReadKey($false).KeyChar
    }
    catch {
        $key = [System.Console]::ReadLine()
    }
    [System.Console]::WriteLine()

    $dismArg = switch ($key) {
        '1' { "/Cleanup-Image /CheckHealth" }
        '2' { "/Cleanup-Image /ScanHealth" }
        '3' { "/Cleanup-Image /RestoreHealth" }
        default { return }
    }

    $proceed = Show-ToolkitConfirmation -ActionTitle "Run DISM $dismArg" `
                                        -Description "Servicing the Windows component store using official DISM.exe." `
                                        -RiskLevel "MediumRisk" `
                                        -UseTrueColor $UseTrueColor

    if (-not $proceed) {
        [System.Console]::WriteLine("  Operation cancelled.")
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    [System.Console]::WriteLine()
    [System.Console]::WriteLine("  Executing: Dism.exe /Online $dismArg ...")
    [System.Console]::WriteLine("  Please wait. Do not close this terminal while servicing is in progress.")
    [System.Console]::WriteLine()

    Write-ToolkitLog -Level "INFO" -Component "DISM" -Message "Running Dism.exe /Online $dismArg"

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        # Test environment mock
        Start-Sleep -Seconds 1
        [System.Console]::WriteLine("  [Test Mock] The component store is healthy. The operation completed successfully.")
        Show-ToolkitPause -UseTrueColor $UseTrueColor
        return
    }

    $fullArgs = "/Online $dismArg"
    $process = Start-Process -FilePath "$env:SystemRoot\System32\Dism.exe" -ArgumentList $fullArgs -NoNewWindow -Wait -PassThru

    [System.Console]::WriteLine()
    if ($process.ExitCode -eq 0) {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "[SUCCESS] DISM operation completed successfully." -Color "Success" -Bold $true -UseTrueColor $UseTrueColor))
        Write-ToolkitLog -Level "INFO" -Component "DISM" -Message "DISM completed with exit code 0."
    }
    else {
        [System.Console]::WriteLine("  " + (Format-Colored -Text "[NOTICE] DISM completed with exit code: $($process.ExitCode)." -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor))
        Write-ToolkitLog -Level "WARN" -Component "DISM" -Message "DISM exited with code $($process.ExitCode)."
    }

    Show-ToolkitPause -UseTrueColor $UseTrueColor
}


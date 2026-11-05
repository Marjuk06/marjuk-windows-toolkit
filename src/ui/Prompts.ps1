<#
.SYNOPSIS
    User confirmation dialogs, risk alerts, and prompt handlers.
.DESCRIPTION
    Ensures that administrative and servicing operations require explicit, informed
    consent. Strictly presents risk classifications before executing any modification.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Show-ToolkitConfirmation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionTitle,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [SecurityRiskLevel]$RiskLevel = [SecurityRiskLevel]::LowRisk,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    [System.Console]::WriteLine()
    
    $riskBadge = switch ($RiskLevel) {
        ([SecurityRiskLevel]::ReadOnly)   { Format-Colored -Text "[READ-ONLY ACTION]" -Color "Success" -Bold $true -UseTrueColor $UseTrueColor }
        ([SecurityRiskLevel]::LowRisk)    { Format-Colored -Text "[LOW RISK OPERATION]" -Color "SecondaryText" -Bold $true -UseTrueColor $UseTrueColor }
        ([SecurityRiskLevel]::MediumRisk) { Format-Colored -Text "[MEDIUM RISK - SYSTEM SERVICING]" -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor }
        ([SecurityRiskLevel]::HighRisk)   { Format-Colored -Text "[HIGH RISK - SYSTEM MODIFICATION]" -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor }
    }

    $titleLine = "  " + (Format-Colored -Text "CONFIRMATION REQUIRED:" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor) + " $riskBadge"
    $actionLine = "  Operation  : " + (Format-Colored -Text $ActionTitle -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor)
    $descLine = "  Description: " + (Format-Colored -Text $Description -Color "SecondaryText" -UseTrueColor $UseTrueColor)

    [System.Console]::WriteLine($titleLine)
    [System.Console]::WriteLine($actionLine)
    [System.Console]::WriteLine($descLine)
    [System.Console]::WriteLine()

    if ($RiskLevel -eq [SecurityRiskLevel]::HighRisk) {
        $prompt = "  Type 'YES' in capital letters to proceed with this operation: "
        [System.Console]::Write((Format-Colored -Text $prompt -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor))
        $response = [System.Console]::ReadLine()
        return ($response -eq "YES")
    }
    else {
        $prompt = "  Do you want to proceed? [Y]es / [N]o (Default: No): "
        [System.Console]::Write((Format-Colored -Text $prompt -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor))
        
        try {
            $key = [System.Console]::ReadKey($false)
            [System.Console]::WriteLine()
            return ($key.KeyChar -eq 'Y' -or $key.KeyChar -eq 'y')
        }
        catch {
            # In non-interactive or redirected hosts
            $line = [System.Console]::ReadLine()
            return ($line -match "^[yY]")
        }
    }
}

function Show-ToolkitPause {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Message = "Press any key to return to menu...",

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    [System.Console]::WriteLine()
    $prompt = "  " + (Format-Colored -Text $Message -Color "SecondaryText" -UseTrueColor $UseTrueColor)
    [System.Console]::Write($prompt)

    try {
        [System.Console]::ReadKey($true) | Out-Null
    }
    catch {
        # Fallback for redirected console
        [System.Console]::ReadLine() | Out-Null
    }
    [System.Console]::WriteLine()
}


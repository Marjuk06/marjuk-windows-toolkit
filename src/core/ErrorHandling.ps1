<#
.SYNOPSIS
    Centralized exception and diagnostic error handling for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Formats exceptions into clean user-facing diagnostic messages without exposing raw
    PowerShell stack dumps to the terminal UI, while preserving full details in the log file.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Format-ToolkitError {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [string]$Context = "General"
    )

    $summary = "Error in [$Context]: $($Exception.Message)"
    Write-ToolkitLog -Level "ERROR" -Component $Context -Message "$summary`nStack Trace: $($Exception.StackTrace)"

    return $summary
}

function Invoke-ToolkitSafeAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [string]$Context = "Action",

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnError
    )

    try {
        & $Action
    }
    catch {
        $errorMessage = Format-ToolkitError -Exception $_.Exception -Context $Context
        if ($OnError) {
            & $OnError $errorMessage
        }
    }
}


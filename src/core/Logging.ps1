<#
.SYNOPSIS
    Centralized logging service for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Provides structured, timestamped log writing to a dedicated user temp directory.
    Supports log levels (DEBUG, INFO, WARN, ERROR) and automated retention cleanup.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

$script:ToolkitLogFilePath = $null

function Initialize-ToolkitLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Subdirectory = "MarjukToolkit\Logs",

        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 7
    )

    $tempRoot = [System.IO.Path]::GetTempPath()
    $logDirectory = Join-Path -Path $tempRoot -ChildPath $Subdirectory

    if (-not (Test-Path -LiteralPath $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    $dateString = (Get-Date).ToString("yyyyMMdd")
    $script:ToolkitLogFilePath = Join-Path -Path $logDirectory -ChildPath "toolkit-$dateString.log"

    # Clean up logs older than retention period
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        Get-ChildItem -Path $logDirectory -Filter "toolkit-*.log" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        # Silent ignore retention failure
    }

    Write-ToolkitLog -Level "INFO" -Message "Logging session initialized. Log target: $script:ToolkitLogFilePath"
}

function Write-ToolkitLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Component = "Core"
    )

    if (-not $script:ToolkitLogFilePath) {
        Initialize-ToolkitLogger
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"

    try {
        [System.IO.File]::AppendAllText($script:ToolkitLogFilePath, $logEntry + [System.Environment]::NewLine, [System.Text.Encoding]::UTF8)
    }
    catch {
        # Fail safe if log file is locked
    }
}


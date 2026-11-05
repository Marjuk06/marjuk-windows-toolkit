<#
.SYNOPSIS
    Configuration loader and settings manager for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Loads application settings from settings.json with resilient fallback defaults.
    Ensures safe operations even if the configuration file is missing or corrupted.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

class ToolkitConfig {
    [string]$AppName = "MARJUK AMIN WINDOWS TOOLKIT"
    [string]$AppVersion = "1.0.0"
    [string]$Tagline = "A better way to manage Windows."
    [string]$PrimaryDomain = "https://wintoolkit.marjukamin.com"
    [string]$TechnicalAlias = "https://activation.marjukamin.com"
    [string]$RepositoryUrl = "https://github.com/marjuk06/marjuk-windows-toolkit"
    [string]$Theme = "BurgundyCharcoal"
    [bool]$EnableTrueColor = $true
    [bool]$ForceAsciiBorders = $false
    [int]$StandardWidth = 94
    [int]$StandardHeight = 32
    [bool]$ShowTelemetryHeader = $true
    [bool]$LoggingEnabled = $true
    [string]$LogLevel = "Information"
    [int]$LogRetentionDays = 7
    [string]$LogDirectory = "MarjukToolkit\Logs"
    [bool]$CheckUpdatesOnStartup = $false
    [bool]$RequireElevationConfirmation = $true
    [bool]$SafetyPromptByDefault = $true
}

function Get-ToolkitConfiguration {
    [CmdletBinding()]
    [OutputType([ToolkitConfig])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )

    $config = [ToolkitConfig]::new()

    if (-not $ConfigPath) {
        $scriptRoot = $PSScriptRoot
        if (-not $scriptRoot) {
            $scriptRoot = (Get-Location).Path
        }
        $ConfigPath = Join-Path -Path $scriptRoot -ChildPath "../../config/settings.json"
    }

    if (Test-Path -LiteralPath $ConfigPath) {
        try {
            $rawContent = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop
            $parsedJson = ConvertFrom-Json -InputObject $rawContent -ErrorAction Stop

            if ($parsedJson.Application) {
                if ($parsedJson.Application.Name) { $config.AppName = [string]$parsedJson.Application.Name }
                if ($parsedJson.Application.Version) { $config.AppVersion = [string]$parsedJson.Application.Version }
                if ($parsedJson.Application.Tagline) { $config.Tagline = [string]$parsedJson.Application.Tagline }
                if ($parsedJson.Application.PrimaryDomain) { $config.PrimaryDomain = [string]$parsedJson.Application.PrimaryDomain }
                if ($parsedJson.Application.TechnicalAlias) { $config.TechnicalAlias = [string]$parsedJson.Application.TechnicalAlias }
                if ($parsedJson.Application.RepositoryUrl) { $config.RepositoryUrl = [string]$parsedJson.Application.RepositoryUrl }
            }

            if ($parsedJson.Interface) {
                if ($null -ne $parsedJson.Interface.EnableTrueColor) { $config.EnableTrueColor = [bool]$parsedJson.Interface.EnableTrueColor }
                if ($null -ne $parsedJson.Interface.ForceAsciiBorders) { $config.ForceAsciiBorders = [bool]$parsedJson.Interface.ForceAsciiBorders }
                if ($parsedJson.Interface.StandardWidth) { $config.StandardWidth = [int]$parsedJson.Interface.StandardWidth }
                if ($parsedJson.Interface.StandardHeight) { $config.StandardHeight = [int]$parsedJson.Interface.StandardHeight }
                if ($null -ne $parsedJson.Interface.ShowTelemetryHeader) { $config.ShowTelemetryHeader = [bool]$parsedJson.Interface.ShowTelemetryHeader }
            }

            if ($parsedJson.Logging) {
                if ($null -ne $parsedJson.Logging.Enabled) { $config.LoggingEnabled = [bool]$parsedJson.Logging.Enabled }
                if ($parsedJson.Logging.LogLevel) { $config.LogLevel = [string]$parsedJson.Logging.LogLevel }
                if ($parsedJson.Logging.RetentionDays) { $config.LogRetentionDays = [int]$parsedJson.Logging.RetentionDays }
                if ($parsedJson.Logging.LogDirectory) { $config.LogDirectory = [string]$parsedJson.Logging.LogDirectory }
            }

            if ($parsedJson.Services) {
                if ($null -ne $parsedJson.Services.CheckUpdatesOnStartup) { $config.CheckUpdatesOnStartup = [bool]$parsedJson.Services.CheckUpdatesOnStartup }
                if ($null -ne $parsedJson.Services.RequireElevationConfirmation) { $config.RequireElevationConfirmation = [bool]$parsedJson.Services.RequireElevationConfirmation }
                if ($null -ne $parsedJson.Services.SafetyPromptByDefault) { $config.SafetyPromptByDefault = [bool]$parsedJson.Services.SafetyPromptByDefault }
            }
        }
        catch {
            # In case of malformed JSON, return default configuration safely without crashing
            Write-Warning "Configuration file could not be parsed. Default settings will be used. Error: $($_.Exception.Message)"
        }
    }

    return $config
}


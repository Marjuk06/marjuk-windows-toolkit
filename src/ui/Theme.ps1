<#
.SYNOPSIS
    Terminal theme, color tokens, and ANSI escape sequence engine.
.DESCRIPTION
    Implements the Marjuk Amin Burgundy and Charcoal design system with TrueColor
    24-bit ANSI escape codes and graceful 16-color ConsoleColor fallbacks.
    Strictly enforces zero emojis, zero SVG, and predictable typography.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

$script:ESC = [char]27

# Theme Palette Tokens
$script:ThemePalette = @{
    # TrueColor 24-bit RGB codes
    Burgundy       = "$script:ESC[38;2;128;0;32m"
    BurgundyBg     = "$script:ESC[48;2;128;0;32m"
    CrimsonAccent  = "$script:ESC[38;2;217;56;90m"
    CrimsonBg      = "$script:ESC[48;2;217;56;90m"
    CharcoalBg     = "$script:ESC[48;2;18;18;20m"
    SurfaceBg      = "$script:ESC[48;2;26;26;30m"
    PrimaryText    = "$script:ESC[38;2;244;244;246m"
    SecondaryText  = "$script:ESC[38;2;142;142;147m"
    Success        = "$script:ESC[38;2;16;185;129m"
    SuccessBg      = "$script:ESC[48;2;16;185;129m"
    Warning        = "$script:ESC[38;2;245;158;11m"
    WarningBg      = "$script:ESC[48;2;245;158;11m"
    Error          = "$script:ESC[38;2;239;68;68m"
    ErrorBg        = "$script:ESC[48;2;239;68;68m"
    
    # Styles
    Bold           = "$script:ESC[1m"
    Dim            = "$script:ESC[2m"
    Reset          = "$script:ESC[0m"
}

# 16-color Fallback Codes
$script:FallbackPalette = @{
    Burgundy       = "$script:ESC[31m"
    BurgundyBg     = "$script:ESC[41m"
    CrimsonAccent  = "$script:ESC[91m"
    CrimsonBg      = "$script:ESC[101m"
    CharcoalBg     = "$script:ESC[40m"
    SurfaceBg      = "$script:ESC[100m"
    PrimaryText    = "$script:ESC[97m"
    SecondaryText  = "$script:ESC[37m"
    Success        = "$script:ESC[92m"
    SuccessBg      = "$script:ESC[102m"
    Warning        = "$script:ESC[93m"
    WarningBg      = "$script:ESC[103m"
    Error          = "$script:ESC[91m"
    ErrorBg        = "$script:ESC[101m"
    Bold           = "$script:ESC[1m"
    Dim            = "$script:ESC[2m"
    Reset          = "$script:ESC[0m"
}

function Get-ToolkitTheme {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    if ($UseTrueColor) {
        return $script:ThemePalette
    }
    else {
        return $script:FallbackPalette
    }
}

function Format-Colored {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$Color = "PrimaryText",

        [Parameter(Mandatory = $false)]
        [string]$Background = "",

        [Parameter(Mandatory = $false)]
        [bool]$Bold = $false,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    $palette = Get-ToolkitTheme -UseTrueColor $UseTrueColor
    $colorCode = if ($palette.ContainsKey($Color)) { $palette[$Color] } else { $palette["PrimaryText"] }
    $bgCode = if ($Background -and $palette.ContainsKey($Background)) { $palette[$Background] } else { "" }
    $boldCode = if ($Bold) { $palette["Bold"] } else { "" }
    $resetCode = $palette["Reset"]

    return "$boldCode$bgCode$colorCode$Text$resetCode"
}

function Clear-ToolkitScreen {
    [CmdletBinding()]
    param()

    # Clear screen and return cursor to home (0,0)
    [System.Console]::Write("$script:ESC[2J$script:ESC[H")
}

function Set-ToolkitCursorVisibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Visible
    )

    try {
        [System.Console]::CursorVisible = $Visible
    }
    catch {
        # Cursor API may fail in redirected host
    }
}


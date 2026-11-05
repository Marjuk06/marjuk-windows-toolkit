<#
.SYNOPSIS
    Screen layout, responsive header, and footer chrome for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Renders standardized top telemetry cards, screen titles, and bottom navigation
    bars. Adapts dynamically to terminal dimensions with clean rounded or ASCII borders.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Get-ToolkitOptimalWidth {
    try {
        $w = [Console]::WindowWidth
        if ($w -ge 84) { return 78 }
        if ($w -ge 70) { return ($w - 2) }
        return 76
    }
    catch {
        return 76
    }
}

function Write-ToolkitHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SystemEnvironmentInfo]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$OfficeStatus = "Undetected",

        [Parameter(Mandatory = $false)]
        [bool]$IsAdmin = $false,

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii
    $innerWidth = [Math]::Max(40, $Width - 2)

    # Line 1: Top Border with Product Brand
    $titleTag = " MARJUK AMIN // WINDOWS TOOLKIT "
    $prefix = "$($glyphs.TopLeft)$($glyphs.Horizontal) "
    $prefixRaw = 3 # 1 glyph + 1 glyph + 1 space

    $fillLength = [Math]::Max(2, $innerWidth - ($prefixRaw + $titleTag.Length + 1))
    $topFill = [string]::new($glyphs.Horizontal, $fillLength)

    $topLine = "$($glyphs.TopLeft)$($glyphs.Horizontal) " +
               (Format-Colored -Text $titleTag -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor) +
               (Format-Colored -Text $topFill -Color "Burgundy" -UseTrueColor $UseTrueColor) +
               "$($glyphs.Horizontal)$($glyphs.TopRight)"

    # Line 2: Telemetry Information Row (Mathematically fitted to $innerWidth)
    $shortOs = if ($Environment.OsName.Length -gt 24) {
        $Environment.OsName.Substring(0, 21) + "..."
    } else {
        $Environment.OsName
    }
    $osPart = "OS: $shortOs [$($Environment.Architecture)]"
    
    $shortOff = if ($OfficeStatus.Length -gt 16) {
        $OfficeStatus.Substring(0, 13) + "..."
    } else {
        $OfficeStatus
    }
    $offPart = "OFFICE: $shortOff"
    
    $adminTag = if ($IsAdmin) { "[ADMIN]" } else { "[USER]" }
    $adminBadgeColored = if ($IsAdmin) {
        Get-StatusBadge -Status "ADMIN" -UseTrueColor $UseTrueColor
    } else {
        Format-Colored -Text "[USER]" -Color "SecondaryText" -UseTrueColor $UseTrueColor
    }

    $leftRaw = "  $osPart   $offPart"
    $rightRaw = "STATUS: $adminTag  "
    
    # Calculate exact middle space fill
    $totalRawContent = $leftRaw.Length + $rightRaw.Length
    $middleSpacesCount = [Math]::Max(1, $innerWidth - $totalRawContent)
    $middleFill = " " * $middleSpacesCount

    $leftColored = "  " + (Format-Colored -Text $osPart -Color "PrimaryText" -UseTrueColor $UseTrueColor) +
                   "   " + (Format-Colored -Text $offPart -Color "SecondaryText" -UseTrueColor $UseTrueColor)
    $rightColored = (Format-Colored -Text "STATUS: " -Color "SecondaryText" -UseTrueColor $UseTrueColor) +
                    $adminBadgeColored + "  "

    $middleLine = "$($glyphs.Vertical)$leftColored$middleFill$rightColored$($glyphs.Vertical)"

    # Line 3: Bottom Border
    $bottomFill = [string]::new($glyphs.Horizontal, $innerWidth)
    $bottomLine = "$($glyphs.BottomLeft)" +
                  (Format-Colored -Text $bottomFill -Color "Burgundy" -UseTrueColor $UseTrueColor) +
                  "$($glyphs.BottomRight)"

    [System.Console]::WriteLine($topLine)
    [System.Console]::WriteLine($middleLine)
    [System.Console]::WriteLine($bottomLine)
    [System.Console]::WriteLine()
}

function Write-ToolkitScreenTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Subtitle = "",

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii

    $titleLine = "  " + (Format-Colored -Text $Title.ToUpper() -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor)
    [System.Console]::WriteLine($titleLine)

    if ($Subtitle) {
        $subLine = "  " + (Format-Colored -Text $Subtitle -Color "SecondaryText" -UseTrueColor $UseTrueColor)
        [System.Console]::WriteLine($subLine)
    }

    $dividerLen = [Math]::Max(10, $Width - 4)
    $divider = "  " + (Format-Colored -Text ([string]::new($glyphs.Horizontal, $dividerLen)) -Color "Burgundy" -UseTrueColor $UseTrueColor)
    [System.Console]::WriteLine($divider)
    [System.Console]::WriteLine()
}

function Write-ToolkitFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomControls = "",

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii

    $divider = (Format-Colored -Text ([string]::new($glyphs.Horizontal, $Width)) -Color "Burgundy" -UseTrueColor $UseTrueColor)
    [System.Console]::WriteLine()
    [System.Console]::WriteLine($divider)

    $controls = if ($CustomControls) {
        $CustomControls
    }
    else {
        " [Up/Down] Navigate   [Enter] Select   [1-8] Hotkey   [Esc/0] Back   [Q] Exit"
    }

    $formattedControls = Format-Colored -Text $controls -Color "SecondaryText" -UseTrueColor $UseTrueColor
    [System.Console]::WriteLine($formattedControls)
}

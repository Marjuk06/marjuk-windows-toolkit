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
        [int]$Width = 92,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii

    # Line 1: Top Border with Product Brand and Domain Link
    $leftTag = " MARJUK AMIN // WINDOWS TOOLKIT v1.0.0 "
    $rightTag = " https://wintoolkit.marjukamin.com "

    $spaceAvailable = $Width - ($leftTag.Length + $rightTag.Length + 4)
    if ($spaceAvailable -lt 4) {
        $rightTag = ""
        $spaceAvailable = $Width - ($leftTag.Length + 4)
    }

    $topBorderFill = [string]::new($glyphs.Horizontal, [Math]::Max(2, $spaceAvailable))
    $topLine = "$($glyphs.TopLeft)$($glyphs.Horizontal) " +
               (Format-Colored -Text $leftTag -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor) +
               (Format-Colored -Text $topBorderFill -Color "Burgundy" -UseTrueColor $UseTrueColor) +
               (Format-Colored -Text $rightTag -Color "SecondaryText" -UseTrueColor $UseTrueColor) +
               "$($glyphs.Horizontal)$($glyphs.TopRight)"

    # Line 2: Telemetry Information Row
    $osTag = "OS: $($Environment.OsName) ($($Environment.BuildNumber)) [$($Environment.Architecture)]"
    $offTag = "OFFICE: $OfficeStatus"
    $adminBadge = if ($IsAdmin) {
        Get-StatusBadge -Status "ADMIN" -UseTrueColor $UseTrueColor
    }
    else {
        Format-Colored -Text "[USER]" -Color "SecondaryText" -UseTrueColor $UseTrueColor
    }

    $telemetryContent = "  $osTag    $offTag    STATUS: $adminBadge"
    # Pad content inside the border
    $rawContentLength = 2 + $osTag.Length + 4 + $offTag.Length + 12 + 8 # Approximate stripped length
    $middleFillLength = [Math]::Max(2, $Width - 62)
    $middleFill = "".PadRight($middleFillLength)

    $middleLine = "$($glyphs.Vertical)  " +
                  (Format-Colored -Text $osTag -Color "PrimaryText" -UseTrueColor $UseTrueColor) +
                  "    " +
                  (Format-Colored -Text $offTag -Color "SecondaryText" -UseTrueColor $UseTrueColor) +
                  $middleFill +
                  "STATUS: $adminBadge  $($glyphs.Vertical)"

    # Line 3: Bottom Border
    $bottomLine = "$($glyphs.BottomLeft)" +
                  (Format-Colored -Text ([string]::new($glyphs.Horizontal, $Width - 2)) -Color "Burgundy" -UseTrueColor $UseTrueColor) +
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
        [int]$Width = 92,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    $titleLine = "  " + (Format-Colored -Text $Title.ToUpper() -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor)
    [System.Console]::WriteLine($titleLine)

    if ($Subtitle) {
        $subLine = "  " + (Format-Colored -Text $Subtitle -Color "SecondaryText" -UseTrueColor $UseTrueColor)
        [System.Console]::WriteLine($subLine)
    }

    $divider = "  " + (Format-Colored -Text ([string]::new([char]0x2500, $Width - 4)) -Color "Burgundy" -UseTrueColor $UseTrueColor)
    [System.Console]::WriteLine($divider)
    [System.Console]::WriteLine()
}

function Write-ToolkitFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomControls = "",

        [Parameter(Mandatory = $false)]
        [int]$Width = 92,

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
        " [Up/Down] Navigate   [Enter] Select   [1-8, A, S] Hotkey   [Esc/0] Back   [Q] Exit"
    }

    $formattedControls = Format-Colored -Text $controls -Color "SecondaryText" -UseTrueColor $UseTrueColor
    [System.Console]::WriteLine($formattedControls)
}


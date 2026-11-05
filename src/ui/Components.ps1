<#
.SYNOPSIS
    Reusable terminal UI components for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Provides standardized box borders, category headers, status badges,
    key-value rows, and progress indicators adhering to strict visual rules:
    zero emojis, zero SVG, clean text status tags, and predictable spacing.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

function Get-ToolkitBorderGlyphs {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    if ($ForceAscii) {
        return @{
            TopLeft     = "+"
            TopRight    = "+"
            BottomLeft  = "+"
            BottomRight = "+"
            Horizontal  = "-"
            Vertical    = "|"
            TDown       = "+"
            TUp         = "+"
            TLeft       = "+"
            TRight      = "+"
            Cross       = "+"
            Pointer     = ">"
        }
    }
    else {
        # Architectural rounded Unicode borders
        return @{
            TopLeft     = [char]0x256D # ╭
            TopRight    = [char]0x256E # ╮
            BottomLeft  = [char]0x2570 # ╰
            BottomRight = [char]0x256F # ╯
            Horizontal  = [char]0x2500 # ─
            Vertical    = [char]0x2502 # │
            TDown       = [char]0x252C # ┬
            TUp         = [char]0x2534 # ┴
            TLeft       = [char]0x251C # ├
            TRight      = [char]0x2524 # ┤
            Cross       = [char]0x253C # ┼
            Pointer     = [char]0x203A # ›
        }
    }
}

function Get-StatusBadge {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "WARN", "FAIL", "INFO", "ADMIN", "ACTIVE", "READY")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    switch ($Status) {
        "OK"     { return Format-Colored -Text "[OK]" -Color "Success" -Bold $true -UseTrueColor $UseTrueColor }
        "ACTIVE" { return Format-Colored -Text "[ACTIVE]" -Color "Success" -Bold $true -UseTrueColor $UseTrueColor }
        "READY"  { return Format-Colored -Text "[READY]" -Color "Success" -Bold $true -UseTrueColor $UseTrueColor }
        "WARN"   { return Format-Colored -Text "[WARN]" -Color "Warning" -Bold $true -UseTrueColor $UseTrueColor }
        "ADMIN"  { return Format-Colored -Text "[ADMIN]" -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor }
        "FAIL"   { return Format-Colored -Text "[FAIL]" -Color "Error" -Bold $true -UseTrueColor $UseTrueColor }
        "INFO"   { return Format-Colored -Text "[INFO]" -Color "SecondaryText" -Bold $false -UseTrueColor $UseTrueColor }
    }
}

function Write-ToolkitCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii
    $formattedTitle = " " + $Title.ToUpper() + " "
    $titleLength = $formattedTitle.Length
    $fillLength = [Math]::Max(0, $Width - $titleLength)
    $dividerLine = [string]::new($glyphs.Horizontal, $fillLength)

    $line = (Format-Colored -Text $formattedTitle -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor) +
            (Format-Colored -Text $dividerLine -Color "Burgundy" -UseTrueColor $UseTrueColor)

    [System.Console]::WriteLine($line)
}

function Write-ToolkitMenuRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Badge = "",

        [Parameter(Mandatory = $false)]
        [bool]$IsSelected = $false,

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $glyphs = Get-ToolkitBorderGlyphs -ForceAscii $ForceAscii

    $pointerStr = if ($IsSelected) { "$($glyphs.Pointer) " } else { "  " }
    $keyStr = "[$Key]"
    $titlePadded = $Title.PadRight(28)

    $leftPart = "$pointerStr$keyStr $titlePadded"
    $rightBadge = if ($Badge) { " $Badge" } else { "" }

    $remainingSpace = $Width - ($leftPart.Length + $rightBadge.Length + 1)
    $descStr = if ($Description -and $remainingSpace -gt 5) {
        if ($Description.Length -gt $remainingSpace) {
            $Description.Substring(0, $remainingSpace - 3) + "..."
        }
        else {
            $Description.PadRight($remainingSpace)
        }
    }
    else {
        "".PadRight([Math]::Max(0, $remainingSpace))
    }

    if ($IsSelected) {
        $formattedLeft = Format-Colored -Text $pointerStr -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor
        $formattedKey = Format-Colored -Text $keyStr -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor
        $formattedTitle = Format-Colored -Text " $titlePadded" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor
        $formattedDesc = Format-Colored -Text $descStr -Color "SecondaryText" -UseTrueColor $UseTrueColor
        $row = "$formattedLeft$formattedKey$formattedTitle$formattedDesc$rightBadge"
    }
    else {
        $formattedLeft = "  "
        $formattedKey = Format-Colored -Text $keyStr -Color "CrimsonAccent" -Bold $false -UseTrueColor $UseTrueColor
        $formattedTitle = Format-Colored -Text " $titlePadded" -Color "PrimaryText" -Bold $false -UseTrueColor $UseTrueColor
        $formattedDesc = Format-Colored -Text $descStr -Color "SecondaryText" -UseTrueColor $UseTrueColor
        $row = "$formattedLeft$formattedKey$formattedTitle$formattedDesc$rightBadge"
    }

    [System.Console]::WriteLine($row)
}

function Write-ToolkitKeyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Value = "None",

        [Parameter(Mandatory = $false)]
        [int]$KeyWidth = 26,

        [Parameter(Mandatory = $false)]
        [Alias("Color")]
        [string]$ValueColor = "PrimaryText",

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Value = "None"
    }

    $paddedKey = "  " + $Key.PadRight($KeyWidth)
    $keyText = Format-Colored -Text $paddedKey -Color "SecondaryText" -UseTrueColor $UseTrueColor
    $sepText = Format-Colored -Text ": " -Color "SecondaryText" -UseTrueColor $UseTrueColor
    $valText = Format-Colored -Text $Value -Color $ValueColor -Bold $true -UseTrueColor $UseTrueColor

    [System.Console]::WriteLine("$keyText$sepText$valText")
}

function Write-ToolkitProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Percent,

        [Parameter(Mandatory = $false)]
        [string]$StatusMessage = "",

        [Parameter(Mandatory = $false)]
        [int]$BarWidth = 40,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true
    )

    $clampedPercent = [Math]::Max(0, [Math]::Min(100, $Percent))
    $filledLength = [int][Math]::Round(($clampedPercent / 100.0) * $BarWidth)
    $emptyLength = $BarWidth - $filledLength

    $filledPart = [string]::new("=", $filledLength)
    $emptyPart = [string]::new(" ", $emptyLength)

    $barStr = "[" + (Format-Colored -Text $filledPart -Color "CrimsonAccent" -Bold $true -UseTrueColor $UseTrueColor) +
              $emptyPart + "] " +
              (Format-Colored -Text "$($clampedPercent.ToString().PadLeft(3))%" -Color "PrimaryText" -Bold $true -UseTrueColor $UseTrueColor)

    if ($StatusMessage) {
        $barStr += "  " + (Format-Colored -Text $StatusMessage -Color "SecondaryText" -UseTrueColor $UseTrueColor)
    }

    [System.Console]::WriteLine($barStr)
}


<#
.SYNOPSIS
    Interactive keyboard navigation controller for MARJUK AMIN WINDOWS TOOLKIT.
.DESCRIPTION
    Drives the terminal menu loop supporting Up/Down arrow-keys, numeric hotkeys,
    instant character jumps, Enter selection, Escape back-step, and Q exit.
.LICENSE
    Licensed under the GNU General Public License v3.0 (GPL-3.0).
    Copyright (c) 2026 Marjuk Amin.
#>

class MenuItem {
    [string]$Key
    [string]$Title
    [string]$Description
    [string]$Category
    [string]$Badge
    [scriptblock]$Action

    MenuItem([string]$key, [string]$title, [string]$desc, [string]$cat, [string]$badge, [scriptblock]$action) {
        $this.Key = $key
        $this.Title = $title
        $this.Description = $desc
        $this.Category = $cat
        $this.Badge = $badge
        $this.Action = $action
    }
}

function Invoke-ToolkitMenuLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [MenuItem[]]$Items,

        [Parameter(Mandatory = $true)]
        [scriptblock]$RenderHeader,

        [Parameter(Mandatory = $false)]
        [int]$Width = 76,

        [Parameter(Mandatory = $false)]
        [bool]$UseTrueColor = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ForceAscii = $false
    )

    $selectedIndex = 0
    $running = $true

    Set-ToolkitCursorVisibility -Visible $false

    try {
        while ($running) {
            Clear-ToolkitScreen

            # Render custom header
            & $RenderHeader

            # Render grouped menu items
            $currentCategory = ""
            for ($i = 0; $i -lt $Items.Count; $i++) {
                $item = $Items[$i]

                if ($item.Category -and $item.Category -ne $currentCategory) {
                    $currentCategory = $item.Category
                    [System.Console]::WriteLine()
                    Write-ToolkitCategory -Title $currentCategory -Width $Width -UseTrueColor $UseTrueColor -ForceAscii $ForceAscii
                }

                $isSelected = ($i -eq $selectedIndex)
                Write-ToolkitMenuRow -Key $item.Key `
                                     -Title $item.Title `
                                     -Description $item.Description `
                                     -Badge $item.Badge `
                                     -IsSelected $isSelected `
                                     -Width $Width `
                                     -UseTrueColor $UseTrueColor `
                                     -ForceAscii $ForceAscii
            }

            # Render standard footer
            Write-ToolkitFooter -Width $Width -UseTrueColor $UseTrueColor -ForceAscii $ForceAscii

            # Wait for user keypress
            try {
                $keyInfo = [System.Console]::ReadKey($true)
            }
            catch {
                # Fallback for redirected console
                break
            }

            switch ($keyInfo.Key) {
                ([System.ConsoleKey]::UpArrow) {
                    $selectedIndex--
                    if ($selectedIndex -lt 0) {
                        $selectedIndex = $Items.Count - 1
                    }
                }
                ([System.ConsoleKey]::DownArrow) {
                    $selectedIndex++
                    if ($selectedIndex -ge $Items.Count) {
                        $selectedIndex = 0
                    }
                }
                ([System.ConsoleKey]::Enter) {
                    $selectedItem = $Items[$selectedIndex]
                    if ($selectedItem.Action) {
                        Clear-ToolkitScreen
                        Set-ToolkitCursorVisibility -Visible $true
                        & $selectedItem.Action
                        Set-ToolkitCursorVisibility -Visible $false
                    }
                }
                ([System.ConsoleKey]::Escape) {
                    $running = $false
                }
                default {
                    $charPressed = $keyInfo.KeyChar.ToString()

                    if ($charPressed -eq 'q' -or $charPressed -eq 'Q') {
                        $running = $false
                        break
                    }

                    # Check for direct key match
                    for ($i = 0; $i -lt $Items.Count; $i++) {
                        if ($Items[$i].Key -eq $charPressed -or $Items[$i].Key.ToLower() -eq $charPressed.ToLower()) {
                            $selectedIndex = $i
                            Clear-ToolkitScreen
                            Set-ToolkitCursorVisibility -Visible $true
                            & $Items[$i].Action
                            Set-ToolkitCursorVisibility -Visible $false
                            break
                        }
                    }
                }
            }
        }
    }
    finally {
        Set-ToolkitCursorVisibility -Visible $true
        [System.Console]::Write("$script:ESC[0m")
    }
}


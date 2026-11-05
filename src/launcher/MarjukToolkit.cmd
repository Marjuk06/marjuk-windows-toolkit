@echo off
:: ============================================================================
:: MARJUK AMIN WINDOWS TOOLKIT — Launcher
:: A better way to manage Windows.
:: https://wintoolkit.marjukamin.com
::
:: Licensed under the GNU General Public License v3.0 (GPL-3.0).
:: Copyright (c) 2026 Marjuk Amin.
:: ============================================================================

setlocal EnableExtensions EnableDelayedExpansion
title MARJUK AMIN // WINDOWS TOOLKIT

:: Set UTF-8 codepage for clean Unicode border rendering
chcp 65001 >nul 2>&1

:: Resolve directory of this script
set "_TOOLKIT_DIR=%~dp0"
set "_MAIN_SCRIPT=%_TOOLKIT_DIR%main.ps1"

:: Verify PowerShell availability
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Windows PowerShell 5.1 is required to run Marjuk Amin Windows Toolkit.
    pause
    exit /b 1
)

:: Launch the main PowerShell application
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%_MAIN_SCRIPT%" %*

endlocal
exit /b %errorlevel%


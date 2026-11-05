#!/usr/bin/env python3
"""
MARJUK AMIN WINDOWS TOOLKIT — Linux Interactive Preview Engine
Allows full terminal UI preview, navigation, and validation directly on Linux.
"""

import os
import sys
import time

# TrueColor ANSI Theme Tokens (matching src/ui/Theme.ps1 exactly)
ESC = "\033"
THEME = {
    "Burgundy": f"{ESC}[38;2;128;0;32m",
    "BurgundyBg": f"{ESC}[48;2;128;0;32m",
    "CrimsonAccent": f"{ESC}[38;2;217;56;90m",
    "CharcoalBg": f"{ESC}[48;2;18;18;20m",
    "SurfaceBg": f"{ESC}[48;2;26;26;30m",
    "PrimaryText": f"{ESC}[38;2;244;244;246m",
    "SecondaryText": f"{ESC}[38;2;142;142;147m",
    "Success": f"{ESC}[38;2;16;185;129m",
    "Warning": f"{ESC}[38;2;245;158;11m",
    "Error": f"{ESC}[38;2;239;68;68m",
    "Bold": f"{ESC}[1m",
    "Dim": f"{ESC}[2m",
    "Reset": f"{ESC}[0m"
}

WIDTH = 76

def color(text, color_name="PrimaryText", bold=False):
    c = THEME.get(color_name, THEME["PrimaryText"])
    b = THEME["Bold"] if bold else ""
    return f"{b}{c}{text}{THEME['Reset']}"

def clear():
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()

def header():
    inner_w = WIDTH - 2
    t_tag = " MARJUK AMIN // WINDOWS TOOLKIT "
    prefix = "╭─ "
    top_fill = "─" * max(2, inner_w - (len(prefix) + len(t_tag) + 1))
    top = f"╭─ {color(t_tag, 'PrimaryText', True)}{color(top_fill, 'Burgundy')}─╮"
    
    os_part = "OS: Win 11 Pro [x64]"
    off_part = "OFFICE: M365 Apps"
    admin_tag = "[PREVIEW]"
    admin_badge = f"{THEME['Bold']}{THEME['CrimsonAccent']}{admin_tag}{THEME['Reset']}"
    
    left_raw = f"  {os_part}   {off_part}"
    right_raw = f"STATUS: {admin_tag}  "
    mid_fill = " " * max(1, inner_w - (len(left_raw) + len(right_raw)))
    
    left_colored = f"  {color(os_part, 'PrimaryText')}   {color(off_part, 'SecondaryText')}"
    right_colored = f"{color('STATUS: ', 'SecondaryText')}{admin_badge}  "
    mid = f"│{left_colored}{mid_fill}{right_colored}│"
    bot = f"╰{color('─'*inner_w, 'Burgundy')}╯\n"
    
    print(top)
    print(mid)
    print(bot)

def screen_title(title, sub=""):
    print(f"  {color(title.upper(), 'PrimaryText', True)}")
    if sub:
        print(f"  {color(sub, 'SecondaryText')}")
    print(f"  {color('─'*(WIDTH-4), 'Burgundy')}\n")

def pause():
    print(f"\n  {color('Press Enter to return to main dashboard...', 'SecondaryText')}")
    try:
        input()
    except:
        pass

def category(title):
    formatted = f" {title.upper()} "
    fill = "─" * max(2, WIDTH - len(formatted))
    print(f"{color(formatted, 'PrimaryText', True)}{color(fill, 'Burgundy')}")

def menu_row(key, title, desc):
    key_part = f"  {color(f'[{key}]', 'CrimsonAccent')} {color(title.ljust(24), 'PrimaryText')}"
    desc_part = color(desc[:WIDTH - 36], 'SecondaryText')
    print(f"{key_part} {desc_part}")

def show_system_overview():
    clear()
    screen_title("System & Hardware Overview", "Environmental and Platform Telemetry")
    print(f"  {color('HARDWARE & FIRMWARE SUMMARY', 'PrimaryText', True)}\n")
    print(f"  {'Computer Name'.ljust(24)}: {color('localhost', 'PrimaryText', True)}")
    print(f"  {'Platform / Kernel'.ljust(24)}: {color('Linux (Mock: Windows 11)', 'PrimaryText', True)}")
    print(f"  {'Processor'.ljust(24)}: {color('x86_64 Host Processor', 'PrimaryText', True)}")
    print(f"  {'Installed Memory'.ljust(24)}: {color('16.0 GB RAM (Available)', 'PrimaryText', True)}")
    print(f"  {'Secure Boot State'.ljust(24)}: {color('Enabled', 'Success', True)}")
    print(f"  {'TPM Readiness'.ljust(24)}: {color('TPM 2.0 Ready', 'Success', True)}\n")
    print(f"  {color('TERMINAL ENGINE TEST', 'PrimaryText', True)}\n")
    print(f"  {'Color Engine'.ljust(24)}: {color('24-bit TrueColor ANSI (#800020 Burgundy)', 'CrimsonAccent', True)}")
    print(f"  {'Status Tags'.ljust(24)}: {color('[OK]', 'Success', True)}  {color('[WARN]', 'Warning', True)}  {color('[ADMIN]', 'CrimsonAccent', True)}  {color('[INFO]', 'SecondaryText')}")
    pause()

def show_licensing():
    clear()
    screen_title("Windows Licensing Inspector", "WMI/CIM Licensing Verification (Read-Only)")
    print(f"  {color('OPERATING SYSTEM LICENSE REPORT', 'PrimaryText', True)}\n")
    print(f"  {'Product Name'.ljust(24)}: {color('Windows 11 Professional', 'PrimaryText', True)}")
    print(f"  {'License Description'.ljust(24)}: {color('RETAIL channel license', 'PrimaryText', True)}")
    print(f"  {'Channel'.ljust(24)}: {color('Retail', 'PrimaryText', True)}")
    print(f"  {'Partial Product Key'.ljust(24)}: {color('3V66T', 'PrimaryText', True)}")
    print(f"  {'Activation State'.ljust(24)}: {color('Licensed', 'Success', True)}\n")
    pause()

def show_office():
    clear()
    screen_title("Microsoft Office Discovery", "Click-to-Run Suite & Channel Verification")
    print(f"  {color('OFFICE INSTALLATION DETAILS', 'PrimaryText', True)}\n")
    print(f"  {'Installed Status'.ljust(24)}: {color('Installed', 'Success', True)}")
    print(f"  {'Version / Build'.ljust(24)}: {color('16.0.17830.20166', 'PrimaryText', True)}")
    print(f"  {'Architecture'.ljust(24)}: {color('x64', 'PrimaryText', True)}")
    print(f"  {'Update Channel'.ljust(24)}: {color('Current Channel', 'PrimaryText', True)}")
    print(f"  {'Product Release ID'.ljust(24)}: {color('Microsoft 365 Enterprise', 'PrimaryText', True)}")
    pause()

def show_sfc():
    clear()
    screen_title("System File Integrity (SFC)", "Protected Windows System File Scanner")
    print(f"  {color('CONFIRMATION REQUIRED:', 'PrimaryText', True)} {color('[SERVICING]', 'Warning', True)}")
    print(f"  Operation  : {color('Run System File Checker (sfc /scannow)', 'PrimaryText', True)}")
    print(f"  Description: {color('Scans protected system files and replaces corrupted files.', 'SecondaryText')}\n")
    pause()

def show_dism():
    clear()
    screen_title("Component Servicing (DISM)", "Windows Image Repair & Health Checks")
    print("  Choose a DISM servicing operation:\n")
    print("  [1] CheckHealth   Quickly inspects corruption flags.")
    print("  [2] ScanHealth    Scans component store for corruptions.")
    print("  [3] RestoreHealth Automatically repairs via Windows Update.")
    print("  [0] Return        Go back to main menu.\n")
    pause()

def show_service_repair():
    clear()
    screen_title("Licensing Service & Store Repair", "Repair Corrupted sppsvc & Refresh Official Licenses")
    print("  This maintenance routine will perform the following actions:")
    print("  1. Verify operational state of sppsvc and ClipSVC.")
    print("  2. Reset default service security descriptors.")
    print("  3. Refresh and re-install official OEM/Retail system licenses.")
    print("  4. Restart Software Protection service to flush stale memory.\n")
    pause()

def show_edition():
    clear()
    screen_title("Windows Edition Inspector", "Active SKU & Upgradable Editions")
    print(f"  {color('CURRENT COMPOSITION EDITION', 'PrimaryText', True)}\n")
    print(f"  {'Current Edition ID'.ljust(24)}: {color('Professional', 'PrimaryText', True)}")
    print(f"  {'Product Name'.ljust(24)}: {color('Windows 11 Pro', 'PrimaryText', True)}")
    print(f"  {'Installation Type'.ljust(24)}: {color('Client', 'PrimaryText', True)}\n")
    pause()

def show_network():
    clear()
    screen_title("Network & Telemetry Diagnostics", "Connectivity & Microsoft Verification Endpoints")
    print(f"  {'Microsoft Activation'.ljust(24)}: {color('kms.core.windows.net', 'SecondaryText')} -> {color('[24ms OK]', 'Success', True)}")
    print(f"  {'Windows Update CDN'.ljust(24)}: {color('windowsupdate.com', 'SecondaryText')} -> {color('[18ms OK]', 'Success', True)}")
    print(f"  {'Office CDN Service'.ljust(24)}: {color('officecdn.microsoft.com', 'SecondaryText')} -> {color('[22ms OK]', 'Success', True)}\n")
    pause()

def show_about():
    clear()
    screen_title("About, Credits & License", "Compliance and Project Information")
    print(f"  {color('MARJUK AMIN WINDOWS TOOLKIT', 'PrimaryText', True)}")
    print(f"  {color('A better way to manage Windows.', 'CrimsonAccent', True)}\n")
    print(f"  {'Product Version'.ljust(24)}: {color('1.0.0 (Release)', 'PrimaryText', True)}")
    print(f"  {'Author & Maintainer'.ljust(24)}: {color('Marjuk Amin (2026)', 'PrimaryText', True)}")
    print(f"  {'Official Portal'.ljust(24)}: {color('https://wintoolkit.marjukamin.com', 'PrimaryText', True)}")
    print(f"  {'License'.ljust(24)}: {color('GNU General Public License v3.0 (GPL-3.0)', 'Success', True)}\n")
    pause()

def main():
    while True:
        clear()
        header()
        
        category("System & Licensing Inspection")
        menu_row("1", "System Overview", "Hardware, processor, Secure Boot & TPM status")
        menu_row("2", "Licensing Inspector", "WMI, CIM, and vNext licensing diagnostics")
        menu_row("3", "Office Installation", "Click-to-Run versions and installed apps")
        print()
        
        category("System Maintenance & Repair")
        menu_row("4", "System File Integrity", "Execute SFC scan and analyze servicing logs")
        menu_row("5", "Component Servicing", "DISM CheckHealth, ScanHealth & RestoreHealth")
        menu_row("6", "Service & Store Repair", "Rebuild licensing tokens & restart sppsvc")
        print()
        
        category("Windows Management & Network")
        menu_row("7", "Windows Edition Info", "Current SKU and DISM target upgrades")
        menu_row("8", "Network Diagnostics", "Active adapters & Microsoft endpoints")
        print()
        
        category("Application Information")
        menu_row("A", "About & License", "GPL-3.0 license and project URLs")
        menu_row("Q", "Exit Toolkit", "Restore console and close application")
        print()
        
        print(color("─" * WIDTH, "Burgundy"))
        print(f" {color('[1-8, A] Select Option   [Q] Exit', 'SecondaryText')}")
        print()
        
        choice = input("  Select an option > ").strip().lower()
        
        if choice == '1':
            show_system_overview()
        elif choice == '2':
            show_licensing()
        elif choice == '3':
            show_office()
        elif choice == '4':
            show_sfc()
        elif choice == '5':
            show_dism()
        elif choice == '6':
            show_service_repair()
        elif choice == '7':
            show_edition()
        elif choice == '8':
            show_network()
        elif choice == 'a':
            show_about()
        elif choice == 'q':
            clear()
            print("\n  Toolkit preview closed cleanly.\n")
            break

if __name__ == "__main__":
    main()

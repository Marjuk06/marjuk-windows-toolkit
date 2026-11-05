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

def color(text, color_name="PrimaryText", bold=False):
    c = THEME.get(color_name, THEME["PrimaryText"])
    b = THEME["Bold"] if bold else ""
    return f"{b}{c}{text}{THEME['Reset']}"

def clear():
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()

def header(width=92):
    t_left = " MARJUK AMIN // WINDOWS TOOLKIT v1.0.0 "
    t_right = " https://wintoolkit.marjukamin.com "
    fill_len = max(2, width - (len(t_left) + len(t_right) + 4))
    
    top = f"╭─ {color(t_left, 'PrimaryText', True)}{color('─'*fill_len, 'Burgundy')}{color(t_right, 'SecondaryText')}─╮"
    
    os_tag = "OS: Linux Zorin OS 18.1 (Mock: Win 11 26100) [x64]"
    off_tag = "OFFICE: Microsoft 365 C2R"
    admin_badge = f"{THEME['Bold']}{THEME['CrimsonAccent']}[LINUX PREVIEW]{THEME['Reset']}"
    
    mid_fill = " " * max(2, width - (len(os_tag) + len(off_tag) + 36))
    mid = f"│  {color(os_tag, 'PrimaryText')}    {color(off_tag, 'SecondaryText')}{mid_fill}STATUS: {admin_badge}  │"
    bot = f"╰{color('─'*(width-2), 'Burgundy')}╯\n"
    
    print(top)
    print(mid)
    print(bot)

def screen_title(title, sub=""):
    print(f"  {color(title.upper(), 'PrimaryText', True)}")
    if sub:
        print(f"  {color(sub, 'SecondaryText')}")
    print(f"  {color('─'*88, 'Burgundy')}\n")

def pause():
    print(f"\n  {color('Press Enter to return to main dashboard...', 'SecondaryText')}")
    try:
        input()
    except:
        pass

def show_system_overview():
    clear()
    screen_title("System & Hardware Overview", "Environmental and Platform Telemetry")
    print(f"  {color('HARDWARE & FIRMWARE SUMMARY', 'PrimaryText', True)}\n")
    print(f"  {'Computer Name'.ljust(26)}: {color('localhost', 'PrimaryText', True)}")
    print(f"  {'Platform / Kernel'.ljust(26)}: {color('Linux 7.0.0-42-generic (x86_64)', 'PrimaryText', True)}")
    print(f"  {'Processor'.ljust(26)}: {color('x86_64 Host Processor (Multi-Core)', 'PrimaryText', True)}")
    print(f"  {'Installed Memory'.ljust(26)}: {color('16.0 GB RAM (Available)', 'PrimaryText', True)}")
    print(f"  {'Secure Boot State'.ljust(26)}: {color('Enabled (Mock Validated)', 'Success', True)}")
    print(f"  {'TPM Readiness'.ljust(26)}: {color('TPM 2.0 Ready (Mock)', 'Success', True)}\n")
    print(f"  {color('TERMINAL ENGINE TEST', 'PrimaryText', True)}\n")
    print(f"  {'Color Engine'.ljust(26)}: {color('24-bit TrueColor ANSI (#800020 Burgundy)', 'CrimsonAccent', True)}")
    print(f"  {'Status Tags'.ljust(26)}: {color('[OK]', 'Success', True)}  {color('[WARN]', 'Warning', True)}  {color('[ADMIN]', 'CrimsonAccent', True)}  {color('[INFO]', 'SecondaryText')}")
    pause()

def show_licensing():
    clear()
    screen_title("Windows Licensing Inspector", "Official WMI and CIM Licensing Verification (Read-Only)")
    print(f"  {color('OPERATING SYSTEM LICENSE REPORT', 'PrimaryText', True)}\n")
    print(f"  {'Product Name'.ljust(26)}: {color('Windows 11 Professional', 'PrimaryText', True)}")
    print(f"  {'License Description'.ljust(26)}: {color('Windows(R) Operating System, RETAIL channel', 'PrimaryText', True)}")
    print(f"  {'Channel'.ljust(26)}: {color('Retail', 'PrimaryText', True)}")
    print(f"  {'Partial Product Key'.ljust(26)}: {color('3V66T', 'PrimaryText', True)}")
    print(f"  {'Activation State'.ljust(26)}: {color('Licensed', 'Success', True)}\n")
    print(f"  {color('Note: In Windows, this executes real-time queries against SoftwareLicensingProduct CIM.', 'SecondaryText')}")
    pause()

def show_office():
    clear()
    screen_title("Microsoft Office Discovery", "Click-to-Run Suite & Servicing Channel Verification")
    print(f"  {color('OFFICE INSTALLATION DETAILS', 'PrimaryText', True)}\n")
    print(f"  {'Installed Status'.ljust(26)}: {color('Installed', 'Success', True)}")
    print(f"  {'Version / Build'.ljust(26)}: {color('16.0.17830.20166', 'PrimaryText', True)}")
    print(f"  {'Architecture'.ljust(26)}: {color('x64', 'PrimaryText', True)}")
    print(f"  {'Update Channel'.ljust(26)}: {color('Current Channel', 'PrimaryText', True)}")
    print(f"  {'Product Release ID'.ljust(26)}: {color('Microsoft 365 Apps for enterprise', 'PrimaryText', True)}")
    pause()

def show_sfc():
    clear()
    screen_title("System File Integrity (SFC)", "Protected Windows System File Scanner")
    print(f"  {color('CONFIRMATION REQUIRED:', 'PrimaryText', True)} {color('[MEDIUM RISK - SYSTEM SERVICING]', 'Warning', True)}")
    print(f"  Operation  : {color('Run System File Checker (sfc /scannow)', 'PrimaryText', True)}")
    print(f"  Description: {color('Scans integrity of all protected system files and replaces corrupted files.', 'SecondaryText')}\n")
    print(f"  {color('[Linux Preview Note] On Windows, this launches sfc.exe with real-time log parsing.', 'SecondaryText')}")
    pause()

def show_dism():
    clear()
    screen_title("Component Servicing (DISM)", "Windows Component Store Integrity and Image Repair")
    print("  Choose a DISM servicing operation:\n")
    print("  [1] CheckHealth   Quickly inspects whether component store corruption has been flagged.")
    print("  [2] ScanHealth    Scans component store for corruptions (Takes 5-10 minutes).")
    print("  [3] RestoreHealth Scans and automatically repairs component store via Windows Update.")
    print("  [0] Return        Go back to main menu.\n")
    print(f"  {color('[Linux Preview Note] DISM is supported natively on Windows host.', 'SecondaryText')}")
    pause()

def show_service_repair():
    clear()
    screen_title("Licensing Service & Store Repair", "Repair Corrupted sppsvc, ClipSVC, and Refresh Official Licenses")
    print("  This maintenance routine will perform the following actions:")
    print("  1. Verify the operational state of sppsvc and ClipSVC services.")
    print("  2. Reset default service security descriptors via sc.exe sdset.")
    print("  3. Refresh and re-install official OEM/Retail system licenses via slmgr.vbs /rilc.")
    print("  4. Restart the Software Protection service to flush stale memory locks.\n")
    print(f"  {color('[SAFE MAINTENANCE] Excludes all bypasses. Restores standard Windows servicing.', 'Success', True)}")
    pause()

def show_edition():
    clear()
    screen_title("Windows Edition & Target Inspector", "Official Windows SKU Information and DISM Servicing Targets")
    print(f"  {color('CURRENT EDITION CONFIGURATION', 'PrimaryText', True)}\n")
    print(f"  {'Installed Edition'.ljust(26)}: {color('Professional', 'Success', True)}")
    print(f"  {'Composition Edition'.ljust(26)}: {color('Enterprise', 'PrimaryText', True)}")
    print(f"  {'Windows Build'.ljust(26)}: {color('26100.2033', 'PrimaryText', True)}\n")
    print(f"  {color('AVAILABLE TARGET UPGRADE EDITIONS (DISM)', 'PrimaryText', True)}\n")
    print(f"  {color('[READY]', 'Success', True)}  Enterprise")
    print(f"  {color('[READY]', 'Success', True)}  Education")
    print(f"  {color('[READY]', 'Success', True)}  ProfessionalEducation")
    print(f"  {color('[READY]', 'Success', True)}  ProfessionalWorkstation\n")
    pause()

def show_network():
    clear()
    screen_title("Network & Connectivity Diagnostics", "Adapter Status and Microsoft Servicing Endpoint Verification")
    print(f"  {color('ACTIVE NETWORK ADAPTERS', 'PrimaryText', True)}\n")
    print(f"  {'Interface (Ethernet)'.ljust(26)}: {color('Gigabit Network Interface', 'PrimaryText', True)}")
    print(f"  {'  IPv4 Address'.ljust(26)}: {color('192.168.1.100 (Connected)', 'SecondaryText')}\n")
    print(f"  {color('OFFICIAL SERVICING ENDPOINT CONNECTIVITY', 'PrimaryText', True)}\n")
    
    endpoints = [
        ("Toolkit Portal", "https://wintoolkit.marjukamin.com", "Active (Cloudflare Global Edge)"),
        ("Windows Licensing", "https://licensing.mp.microsoft.com", "Reachable (HTTPS 200)"),
        ("Software Protection", "https://sls.microsoft.com", "Reachable (HTTPS 200)"),
        ("Office Click-to-Run CDN", "https://officecdn.microsoft.com", "Reachable (HTTPS 200)"),
        ("Windows Update CDN", "http://download.windowsupdate.com", "Reachable (HTTP 200)")
    ]
    for name, url, status in endpoints:
        print(f"  {color('[OK]', 'Success', True)}  {name.ljust(26)} {color(status, 'SecondaryText')}")
    pause()

def show_about():
    clear()
    screen_title("About, Credits and License", "Open Source Heritage, Compliance and Project Information")
    print(f"  {color('MARJUK AMIN WINDOWS TOOLKIT', 'PrimaryText', True)}")
    print(f"  {color('A better way to manage Windows.', 'CrimsonAccent', True)}\n")
    print(f"  {'Product Version'.ljust(26)}: {color('1.0.0 (Release)', 'PrimaryText', True)}")
    print(f"  {'Author & Maintainer'.ljust(26)}: {color('Marjuk Amin (2026)', 'PrimaryText', True)}")
    print(f"  {'Official Portal'.ljust(26)}: {color('https://wintoolkit.marjukamin.com', 'PrimaryText', True)}")
    print(f"  {'Source Repository'.ljust(26)}: {color('https://github.com/Marjuk06/marjuk-windows-toolkit', 'PrimaryText', True)}")
    print(f"  {'License'.ljust(26)}: {color('GNU General Public License v3.0 (GPL-3.0)', 'Success', True)}\n")
    print(f"  {color('OPEN-SOURCE HERITAGE & THIRD-PARTY CREDITS', 'PrimaryText', True)}")
    print("  - Microsoft-Activation-Scripts (MAS) v3.12: Upstream technical research (GPL-3.0)")
    print("  - @abbodi1406: Licensing status inspection research and Office C2R discovery")
    print("  - asdcorp: clic (Client Licensing Check) P/Invoke routines (MIT License)")
    print("  - Alex (aka may, ave9858): DISM API research\n")
    pause()

def main():
    while True:
        clear()
        header()
        
        print(f" {color('SYSTEM & LICENSING INSPECTION', 'PrimaryText', True)} {color('─'*59, 'Burgundy')}")
        print(f"  {color('[1]', 'CrimsonAccent')} {'System Overview'.ljust(28)} {color('Hardware, processor, memory, Secure Boot and TPM status', 'SecondaryText')}")
        print(f"  {color('[2]', 'CrimsonAccent')} {'Licensing Inspector'.ljust(28)} {color('Comprehensive WMI, CIM, and vNext licensing diagnostics', 'SecondaryText')}")
        print(f"  {color('[3]', 'CrimsonAccent')} {'Office Installation'.ljust(28)} {color('Click-to-Run versions, update channels, and installed apps', 'SecondaryText')}\n")
        
        print(f" {color('SYSTEM MAINTENANCE & REPAIR', 'PrimaryText', True)} {color('─'*61, 'Burgundy')}")
        print(f"  {color('[4]', 'CrimsonAccent')} {'System File Integrity'.ljust(28)} {color('Execute SFC scan and analyze component store logs', 'SecondaryText')}")
        print(f"  {color('[5]', 'CrimsonAccent')} {'Component Servicing (DISM)'.ljust(28)} {color('Verify, check, and restore Windows image health', 'SecondaryText')}")
        print(f"  {color('[6]', 'CrimsonAccent')} {'Service & Store Repair'.ljust(28)} {color('Rebuild licensing tokens, restart sppsvc, and verify WMI', 'SecondaryText')}\n")
        
        print(f" {color('WINDOWS MANAGEMENT & NETWORK', 'PrimaryText', True)} {color('─'*60, 'Burgundy')}")
        print(f"  {color('[7]', 'CrimsonAccent')} {'Windows Edition Info'.ljust(28)} {color('Current SKU, composition edition, and DISM target upgrades', 'SecondaryText')}")
        print(f"  {color('[8]', 'CrimsonAccent')} {'Network Diagnostics'.ljust(28)} {color('Active adapters, latency, and official Microsoft endpoints', 'SecondaryText')}\n")
        
        print(f" {color('APPLICATION INFORMATION', 'PrimaryText', True)} {color('─'*65, 'Burgundy')}")
        print(f"  {color('[A]', 'CrimsonAccent')} {'About, Credits & License'.ljust(28)} {color('GPL-3.0 license, upstream credits, and project URLs', 'SecondaryText')}")
        print(f"  {color('[Q]', 'CrimsonAccent')} {'Exit Toolkit'.ljust(28)} {color('Restore console and close application', 'SecondaryText')}\n")
        
        print(f"{color('─'*92, 'Burgundy')}")
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

if __name__ == '__main__':
    main()

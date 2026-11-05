# MARJUK AMIN WINDOWS TOOLKIT
### *A better way to manage Windows.*

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-800020.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-1A1A1E.svg)](https://wintoolkit.marjukamin.com)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-D9385A.svg)](https://wintoolkit.marjukamin.com)

**MARJUK AMIN WINDOWS TOOLKIT** is a modern, keyboard-driven terminal administration, diagnostic, and servicing suite engineered for Windows 10, Windows 11, and Windows Server environments.

Featuring a custom **Burgundy and Charcoal** terminal design system, the toolkit delivers an intuitive, fast, and structured command-line experience with zero emojis, architectural box borders, live telemetry, and explicit risk confirmation dialogs.

Official Portal: [https://wintoolkit.marjukamin.com](https://wintoolkit.marjukamin.com)  
Technical Alias: [https://activation.marjukamin.com](https://activation.marjukamin.com)  
GitHub Repository: [https://github.com/marjuk06/marjuk-windows-toolkit](https://github.com/marjuk06/marjuk-windows-toolkit)

---

## Key Capabilities

1. **System & Hardware Overview**: Comprehensive reporting of CPU architecture, core counts, RAM availability, motherboard model, UEFI Secure Boot state, and TPM readiness.
2. **Licensing Status Inspector**: Read-only diagnostic verification of Windows Software Protection Platform (SPP) licenses, partial product keys, channel types (Retail, OEM:DM, Volume:MAK/GVLK), and grace period timers.
3. **Office Installation Discovery**: Scans Click-to-Run (C2R) suites, installed applications, build revisions, and active update channels (Current, Monthly Enterprise, Semi-Annual, Beta).
4. **System File Checker (SFC)**: Managed, real-time execution of `sfc /scannow` with prerequisite privilege validation, risk disclosures, and structured exit-code analysis.
5. **Component Servicing (DISM)**: Guided execution of official Windows servicing routines: `CheckHealth`, `ScanHealth`, and `RestoreHealth` via Windows Update.
6. **Licensing Service & Store Repair**: Legitimate maintenance to restore official `sppsvc` and `ClipSVC` service descriptors (`sc.exe sdset`), resolve lockups, and refresh system licenses via `slmgr.vbs /rilc`.
7. **Windows Edition Information**: Analyzes current Windows edition, composition targets, and official DISM target upgrade paths.
8. **Network Diagnostics**: Verifies default gateway reachability, active IPv4 configurations, DNS resolution, and HTTPS connectivity to official Microsoft servicing endpoints.
9. **About & Compliance Screen**: Interactive display of GNU GPL-3.0 legal terms, author credits, and open-source heritage.

---

## Quick Start

### Method 1: Web Bootstrap (PowerShell)
Launch Windows PowerShell or Windows Terminal as Administrator and execute:

```powershell
irm https://wintoolkit.marjukamin.com | iex
```

*Note: The bootstrap script downloads and verifies the latest signed release directly into your session.*

### Method 2: Offline ZIP Release
1. Download `marjuk-windows-toolkit-v1.0.0.zip` from [Releases](https://github.com/marjuk06/marjuk-windows-toolkit/releases).
2. Extract the archive to any folder on your machine.
3. Double-click `MarjukToolkit.cmd` or execute inside PowerShell:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\src\launcher\main.ps1
   ```

### Method 3: Unattended Diagnostic CLI Switches
Run targeted diagnostic reports directly from the command line:

```powershell
# Display System & Hardware Telemetry
powershell -File .\src\launcher\main.ps1 -Info

# Display Windows Licensing Report
powershell -File .\src\launcher\main.ps1 -Licensing

# Display Office Discovery Report
powershell -File .\src\launcher\main.ps1 -Office

# Run Network & Microsoft Endpoint Checks
powershell -File .\src\launcher\main.ps1 -Network
```

---

## Terminal Navigation

The toolkit is completely keyboard-driven:

- **Up / Down Arrow Keys**: Move the cursor selection bar smoothly.
- **Enter**: Select and execute the highlighted option.
- **Numeric & Alpha Hotkeys (`1`–`8`, `A`, `S`)**: Instantly trigger options without navigating.
- **Escape / 0**: Return to previous menu.
- **Q**: Clean application exit and terminal restoration.

---

## Design System

The visual design system adheres strictly to professional terminal standards:

- **Primary Burgundy (`#800020`)**: Brand header, active selection bar, primary borders.
- **Crimson Accent (`#D9385A`)**: Active item indicator (`›`), highlighted badges.
- **Dark Charcoal (`#121214`)**: Console canvas background.
- **Surface (`#1A1A1E`)**: Card panels and category headings.
- **Primary Text (`#F4F4F6`)**: High-contrast labels and headings.
- **Secondary Text (`#8E8E93`)**: Descriptions, shortcuts, and metadata.
- **Strict Visual Rules**: No emojis, no SVG icons, no decorative Unicode clutter, no excessive ASCII art, and predictable rounded or ASCII borders.

---

## Architecture & Security Principles

- **No Bypass Mechanics**: The toolkit strictly excludes all licensing bypass, ticket forgery, DLL proxy hooking, and unauthorized KMS activation routines.
- **Explicit Confirmation**: Servicing routines (SFC, DISM, service repairs) present clear risk classifications and require explicit user consent before execution.
- **Structured Logging**: Diagnostic sessions write timestamped logs to `%TEMP%\MarjukToolkit\Logs` with automatic 7-day retention cleanup.
- **Clean Terminal Teardown**: Automatically restores cursor visibility, console colors, and input modes upon exit.

---

## Open-Source Heritage & License

This project is licensed under the **GNU General Public License Version 3 (GPL-3.0)**.  
See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md) for full terms and third-party attributions.

Based in part on technical research and diagnostic methods from Microsoft-Activation-Scripts (MAS) v3.12 (`massgravel`), `@abbodi1406`, and `asdcorp` (`clic` — MIT License).


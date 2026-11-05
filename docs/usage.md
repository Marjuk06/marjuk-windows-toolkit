# User Guide & Navigation Manual

The **MARJUK AMIN WINDOWS TOOLKIT** provides an intuitive, keyboard-driven terminal dashboard designed to streamline Windows maintenance, diagnostics, and licensing verification.

---

## 1. Terminal Controls & Keybindings

| Key / Shortcut | Action |
|---|---|
| **Up Arrow (`↑`)** | Move selection bar up |
| **Down Arrow (`↓`)** | Move selection bar down |
| **Enter** | Select and execute the highlighted module |
| **`1` – `8`** | Instant numeric hotkey jump to corresponding module |
| **`A`** | Open About, Credits & License screen |
| **`S`** | Open Settings and configuration screen |
| **Escape / `0`** | Go back to previous menu or dashboard |
| **`Q`** | Cleanly exit application and restore terminal state |

---

## 2. Module Overview

### [1] System Overview
Displays detailed hardware telemetry including CPU brand, core/thread counts, physical memory usage, system disk free space, UEFI Secure Boot status, and TPM 2.0 readiness.

### [2] Licensing Inspector
A purely read-only diagnostic utility querying Windows Software Protection Platform (SPP) via WMI/CIM. Displays Windows activation status (`Licensed`, `Grace`, `Notification`), product key channel (`Retail`, `OEM:DM`, `Volume:MAK`, `Volume:GVLK`), partial key, and remaining grace period.

### [3] Office Installation Discovery
Scans Microsoft Office Click-to-Run (C2R) suites, installed applications, architecture (`x86` vs `x64`), and active servicing channels (`Current`, `Monthly Enterprise`, `Semi-Annual Enterprise`, `Beta`).

### [4] System File Integrity (SFC)
A managed execution of `sfc /scannow`. Validates administrator elevation, prompts for confirmation, executes the scan with live monitoring, and provides human-readable analysis of the results.

### [5] Component Servicing (DISM)
Provides guided access to official Windows component store servicing:
- `CheckHealth`: Quick check to see if corruption has been detected.
- `ScanHealth`: Scans the component store for corruption (5–10 minutes).
- `RestoreHealth`: Scans and automatically repairs component store corruptions via Windows Update.

### [6] Licensing Store & Service Repair
Legitimate maintenance routine to recover corrupted `sppsvc` and `ClipSVC` services:
- Restores official service descriptors via `sc.exe sdset`.
- Re-registers system licensing files via `slmgr.vbs /rilc`.
- Restarts licensing services to flush locks.

### [7] Windows Edition Info
Displays current Windows SKU, composition edition, and queries available target upgrade paths via official DISM APIs.

### [8] Network & Connectivity Diagnostics
Inspects active network interfaces, verifies gateway connectivity, tests DNS resolution, and benchmarks HTTPS latency to official Microsoft Update and licensing endpoints.

---

## 3. Unattended CLI Mode

Automate diagnostic reports or integrate with external scripts using CLI switches:

```powershell
# Output hardware and OS telemetry
powershell -File .\src\launcher\main.ps1 -Info

# Output Windows licensing status report
powershell -File .\src\launcher\main.ps1 -Licensing

# Output Office discovery report
powershell -File .\src\launcher\main.ps1 -Office

# Output network diagnostic report
powershell -File .\src\launcher\main.ps1 -Network
```


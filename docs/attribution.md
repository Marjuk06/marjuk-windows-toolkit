# Open-Source Heritage & Technical Attribution

The **MARJUK AMIN WINDOWS TOOLKIT** is developed under the **GNU General Public License Version 3 (GPL-3.0)**.

This document details the open-source research, upstream contributors, and permissive licenses incorporated or referenced in this project.

---

## 1. Upstream Technical Origin

This project builds upon the extensive research conducted by the Windows open-source community into the Windows Software Protection Platform (SPP), Component-Based Servicing (CBS), and Deployment Image Servicing and Management (DISM).

### Microsoft-Activation-Scripts (MAS)
- **Repository**: https://github.com/massgravel/Microsoft-Activation-Scripts
- **Authors**: `massgravel`, `WindowsAddict`, and community contributors
- **License**: GNU General Public License v3.0 (GPL-3.0)
- **Contribution to this Toolkit**:
  - Servicing research and diagnostic commands in Windows maintenance.
  - Identification of official DISM edition switching targets.
  - Identification of Windows WMI/CIM licensing queries.

---

## 2. Key Researchers & Contributors

### @abbodi1406
- Author of `Check_Activation_Status.cmd` in MAS.
- Researched WMI `SoftwareLicensingProduct` query filters and Office Click-to-Run (C2R) registry detection.
- Contributed significantly to the PowerShell licensing ecosystem.

### asdcorp
- Author of `clic` (Client Licensing Check) and `Set-WindowsCbsEdition`.
- Provided foundational P/Invoke implementations for native Windows `slc.dll` / `sppc.dll` APIs under the **MIT License**.

### Alex (aka may, ave9858)
- Provided research into official DISM C API and offline servicing routines under GPL-3.0.

---

## 3. Independent Architectural Implementation

The following components of this toolkit are **independently authored by Marjuk Amin (2026)**:

1. **Modular Architecture**: Complete transition from monolithic batch `.cmd` scripts into a layered PowerShell 5.1/7 application.
2. **Burgundy & Charcoal Design System**: Custom 24-bit TrueColor ANSI theme engine (`Theme.ps1`) with 16-color fallback.
3. **Keyboard Navigation Engine**: Real-time cursor navigation (`Navigation.ps1`) supporting arrow-keys, instant hotkeys, and graceful console restoration.
4. **Safety & Risk Management**: Structured risk classification system (`Prompts.ps1`) preventing silent or unexpected system modifications.
5. **Telemetry Header & Dashboard**: Real-time environmental query card (`Layout.ps1`, `Dashboard.ps1`).
6. **Network & Endpoint Testing Engine**: Automated HTTPS reachability benchmarking for Microsoft servicing endpoints (`ConnectivityCheck.ps1`).
7. **Complete Exclusion of Circumvention Logic**: Removal of all ticket synthesis, DLL proxy hooking, and unauthorized activation logic.


# Changelog

All notable changes to the **MARJUK AMIN WINDOWS TOOLKIT** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-11-05

### Added
- **New Modular Architecture**: Full re-architecture into a clean, modular PowerShell 5.1 and 7 compatible codebase (`src/core/`, `src/ui/`, `src/modules/`, `src/launcher/`).
- **Burgundy & Charcoal Design System**: 24-bit TrueColor ANSI palette (`#800020` Burgundy, `#D9385A` Crimson Accent, `#121214` Charcoal) with automatic 16-color console fallback.
- **Keyboard Navigation Controller**: Smooth Up/Down arrow-key selection, instant numeric hotkeys (`1`–`8`, `A`, `S`), Enter selection, Escape back-step, and Q exit.
- **Live Telemetry Header**: Dynamic top card displaying OS edition, build number, processor architecture, Office C2R status, and Administrator elevation state.
- **System & Hardware Overview**: Comprehensive hardware summary querying CPU, RAM, Secure Boot state, and TPM 2.0 readiness.
- **Licensing Status Inspector**: Read-only verification of Windows Software Protection Platform licensing states, channel types, partial keys, and grace periods.
- **Office Installation Discovery**: Scans Click-to-Run suites, build revisions, and active servicing channels.
- **Managed System Maintenance**: Structured wrappers for `sfc /scannow` and DISM (`CheckHealth`, `ScanHealth`, `RestoreHealth`) with risk classifications and confirmation dialogs.
- **Licensing Service & Store Repair**: Restores official service descriptors (`sc.exe sdset`), restarts `sppsvc`/`ClipSVC`, and refreshes system licenses via `slmgr.vbs /rilc`.
- **Windows Edition Inspector**: Analyzes current edition composition and queries official DISM target upgrade editions.
- **Network & Endpoint Diagnostics**: Tests active network interfaces, gateway reachability, and HTTPS latency to official Microsoft servicing endpoints.
- **Interactive About & Compliance View**: Interactive screen displaying GNU GPL-3.0 terms, author credits, and upstream heritage.
- **Double-Click CMD Launcher**: `MarjukToolkit.cmd` with automatic UTF-8 codepage initialization and parameter passthrough.

### Removed
- **Permanently Excluded**: All ticket forgery (HWID), DLL proxy hooking (Ohook), SPP physical store injection (TSforge), third-party KMS emulator connections, and `$OEM$` pre-activation routines.
- **Removed**: Legacy ASCII box clutter, random window-size jumping (`mode CON:`), and active DNS update beacons.


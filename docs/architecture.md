# System Architecture & Design Philosophy

The **MARJUK AMIN WINDOWS TOOLKIT** is designed as a modular, layered Windows PowerShell application separating presentation, core system detection, and servicing logic.

---

## 1. Architectural Layers

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   PRESENTATION & TUI LAYER (src/ui/)                  │
│   Theme.ps1       Layout.ps1       Components.ps1   Navigation.ps1     │
│   (Burgundy ANSI) (Header/Chrome)  (Boxes/Badges)   (Key Controller)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                  CORE INFRASTRUCTURE (src/core/)                       │
│   Configuration.ps1   Environment.ps1   Permissions.ps1   Logging.ps1  │
│   (JSON Settings)     (Build/Terminal)  (UAC / Security)  (Session Log)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                 FUNCTIONAL MODULES (src/modules/)                      │
│   LicensingStatus/   Maintenance/      WindowsManagement/  Network/    │
│   (WMI / CIM / SLC)  (SFC / DISM)      (SKU & Servicing)   (Endpoints) │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Design Principles

1. **Separation of Presentation from Logic**: UI components (`Components.ps1`, `Theme.ps1`) contain zero business logic. Diagnostic modules query data and return typed objects (`WindowsLicenseDetail`, `SystemHardwareSummary`, `NetworkEndpointResult`), allowing headless CLI execution as easily as interactive rendering.
2. **Terminal Discipline**:
   - Zero emojis anywhere in code or console output.
   - 24-bit TrueColor ANSI with graceful fallback to standard 16-color console palettes.
   - Clean cursor management and restoration upon exit.
3. **Non-Destructive & Safe Operations**:
   - All diagnostic operations are strictly read-only.
   - All maintenance actions require explicit, informed consent with risk disclosures.
4. **Resilient Error Containment**:
   - Exceptions are captured via `Invoke-ToolkitSafeAction` and recorded to session log files (`%TEMP%\MarjukToolkit\Logs\toolkit-YYYYMMDD.log`) without leaking raw PowerShell stack traces to the terminal screen.


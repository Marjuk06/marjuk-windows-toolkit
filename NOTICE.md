# Legal Notices & Third-Party Attributions

**Product**: MARJUK AMIN WINDOWS TOOLKIT  
**Author & Maintainer**: Marjuk Amin (2026)  
**Primary Domain**: https://wintoolkit.marjukamin.com  
**Technical Alias**: https://activation.marjukamin.com  
**Repository**: https://github.com/marjuk06/marjuk-windows-toolkit  

---

## 1. Project Heritage & Modification Notice

This program is an independently architected, legitimate Windows system diagnostics, administration, and servicing utility. It is derived in part from technical research, diagnostic routines, and CBS/licensing investigation published by open-source Windows community developers.

In compliance with **Section 5(a) of the GNU General Public License Version 3 (GPL-3.0)**, notice is hereby given that this work contains substantial modifications, complete visual redesign, and architectural refactoring:

- **Date of Modification**: 2026
- **Modified By**: Marjuk Amin
- **Nature of Modification**:
  - Full architectural transformation from monolithic CMD batch scripts into a modular, object-oriented PowerShell 5.1/7 application.
  - Complete elimination of all licensing bypass, ticket forgery, DLL proxy hooking, and unauthorized activation mechanisms.
  - Implementation of a brand-new, keyboard-driven Terminal User Interface (TUI) featuring a Burgundy (`#800020`) and Dark Charcoal (`#121214`) design system.
  - Integration of structured logging, telemetry detection, permission escalation management, and interactive risk confirmation dialogs.

---

## 2. Upstream Projects & Copyright Holders

This project acknowledges the foundational technical research from the following open-source contributors:

### Microsoft-Activation-Scripts (MAS)
- **Upstream Repository**: https://github.com/massgravel/Microsoft-Activation-Scripts
- **Upstream Maintainer**: `massgravel` / `WindowsAddict` & contributors
- **License**: GNU General Public License v3.0 (GPL-3.0)

### @abbodi1406
- **Contributions**: Research in Windows Licensing status inspection via WMI/CIM, Office Click-to-Run (C2R) configuration parsing, and system servicing routines.
- **License**: GPL-3.0 / MIT

### Alex (aka may, ave9858)
- **Contributions**: DISM API research and Windows servicing mechanics.
- **License**: GPL-3.0

---

## 3. Embedded Third-Party Permissive Licenses

### `clic` (Client Licensing Check)
Portions of the native licensing status inspection routines derive from `clic`:

```text
Source: https://github.com/asdcorp/clic
Powershell port: abbodi1406
Copyright 2023 asdcorp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 4. Complete License Text

The complete text of the GNU General Public License Version 3 is available in the [LICENSE](LICENSE) file located in the root directory of this repository.


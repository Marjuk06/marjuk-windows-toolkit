# Installation & Deployment Guide

This guide covers all supported installation, deployment, and execution methods for the **MARJUK AMIN WINDOWS TOOLKIT**.

---

## Prerequisites

- **Operating System**: Windows 10 (Build 1709+), Windows 11 (all builds), or Windows Server 2016/2019/2022/2025.
- **PowerShell**: Windows PowerShell 5.1 (installed by default on Windows 10/11) or PowerShell 7+.
- **Console Environment**: Windows Terminal (`wt.exe`) or standard Windows Console Host (`conhost.exe`).

---

## Method 1: Web Bootstrap (Fastest)

Launch Windows PowerShell as Administrator and run:

```powershell
irm https://wintoolkit.marjukamin.com | iex
```

### What this does:
1. Connects to `https://wintoolkit.marjukamin.com` over TLS 1.3.
2. Downloads the official release payload to `%TEMP%\MarjukToolkit\App`.
3. Verifies file integrity.
4. Launches the interactive menu in your current console session.

---

## Method 2: Offline Release Archive (Air-Gapped / Enterprise)

For enterprise environments or machines without internet access:

1. Download `marjuk-windows-toolkit-v1.0.0.zip` and `SHA256SUMS.txt` from [GitHub Releases](https://github.com/marjuk06/marjuk-windows-toolkit/releases).
2. Verify the archive hash:
   ```powershell
   (Get-FileHash .\marjuk-windows-toolkit-v1.0.0.zip -Algorithm SHA256).Hash
   ```
3. Extract the archive to your desired location (e.g., `C:\Tools\MarjukToolkit`).
4. Execute `MarjukToolkit.cmd` or launch `src\launcher\main.ps1`:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\src\launcher\main.ps1
   ```

---

## Method 3: Git Clone (Developers)

```powershell
git clone https://github.com/marjuk06/marjuk-windows-toolkit.git
cd marjuk-windows-toolkit
.\src\launcher\MarjukToolkit.cmd
```


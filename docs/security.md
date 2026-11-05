# Security & Integrity Model

Security and user trust are core design requirements of the **MARJUK AMIN WINDOWS TOOLKIT**.

---

## 1. Non-Destructive Principles

- **No Bypass Mechanics**: The toolkit contains no key generators, DLL proxy hooking mechanisms, forged ticket generators, or third-party KMS emulator connections.
- **Read-Only by Default**: Modules inspecting licensing, Office installations, hardware telemetry, and network endpoints perform no writes to the Windows registry or file system.
- **Explicit Consent**: Destructive or system-modifying operations (e.g. `DISM /RestoreHealth`, `sfc /scannow`, or service permission re-registration) display risk levels and require interactive confirmation.

---

## 2. Elevation & Privilege Boundaries

- The toolkit launches in standard user privilege mode.
- When an administrator-only action is requested, `Permissions.ps1` verifies the user token via `WindowsPrincipal.IsInRole([WindowsBuiltInRole]::Administrator)`.
- If unprivileged, the application prompts the user before requesting UAC elevation (`Start-Process -Verb runas`).

---

## 3. Remote Bootstrap Security (`irm ... | iex`)

The remote bootstrap script served at `https://wintoolkit.marjukamin.com` follows defensive patterns:
1. **Encrypted Transport**: Served over HTTPS with TLS 1.3 and DNSSEC.
2. **Inspectable Code**: The bootstrap is human-readable, lightweight (~80 lines), and openly auditable.
3. **No Hidden Payloads**: Downloads official release archives directly into `%TEMP%\MarjukToolkit\App`.
4. **Offline Alternative**: Users who do not run remote bootstrap commands can download versioned release ZIP archives from GitHub Releases with published SHA-256 checksums.


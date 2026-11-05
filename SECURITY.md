# Security Policy

The **MARJUK AMIN WINDOWS TOOLKIT** is designed with security, transparency, and non-destructive operation as primary requirements.

---

## 1. Supported Versions

| Version | Supported |
|---|---|
| 1.0.x | Yes |
| < 1.0.0 | No |

---

## 2. Security Architecture & Trust Model

1. **Explicit Consent & Risk Classification**:
   - Administrative servicing routines (DISM, SFC, service resets) present clear risk disclosures and require explicit user confirmation before executing.
   - Read-only diagnostic modules cannot modify system configuration or registry hives.
2. **Exclusion of Circumvention Logic**:
   - The toolkit contains no key generators, DLL hooking payloads, ticket forgery tools, or third-party KMS emulator connections.
3. **Execution Policy & Elevation**:
   - The toolkit operates in standard User mode for diagnostics. When an operation requires Administrator privileges, the toolkit presents an explicit elevation prompt.
4. **Bootstrap Script Integrity (`irm ... | iex`)**:
   - The web bootstrap hosted at `https://wintoolkit.marjukamin.com` is served over HTTPS with strict TLS 1.3 encryption and DNSSEC.
   - For environments with strict security policies, download the offline release ZIP from GitHub Releases and verify the published SHA-256 checksum before execution.

---

## 3. Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

- **Email**: `security@marjukamin.com` (or submit a private security advisory on GitHub).
- Do not disclose security issues in public GitHub issues or discussions until an official patch has been published.
- Please include:
  - Description of the issue
  - Affected module and line numbers
  - Proof-of-concept steps to reproduce
  - Potential impact assessment


# Contributing Guidelines

Thank you for your interest in contributing to the **MARJUK AMIN WINDOWS TOOLKIT**.

---

## 1. Code Standards & Architecture Guidelines

1. **PowerShell Best Practices**:
   - Write clean, readable, multiline PowerShell code. Avoid compressed one-liners or cryptic aliases (`Get-ChildItem` instead of `gci`, `Invoke-RestMethod` instead of `irm` in library code).
   - Use standard `Verb-Noun` naming for all cmdlets and functions.
   - Add explicit parameter and return types to all functions.
   - Use `try/catch/finally` blocks with explicit error logging via `Write-ToolkitLog`.
2. **Strict UI Design Rules**:
   - **Zero Emojis**: Do not use emojis anywhere in code, comments, or terminal output.
   - **Zero SVG Icons or Decorative Glyphs**: Use clean text tags (`[OK]`, `[WARN]`, `[FAIL]`, `[INFO]`, `[ADMIN]`) and standard box-drawing characters.
   - **Color Discipline**: All colors must use tokens defined in `Theme.ps1` (Burgundy `#800020`, Crimson `#D9385A`, Charcoal `#121214`).
3. **Security & Non-Destructive Principles**:
   - Never introduce routines that bypass access controls, spoof licensing, or modify system files without explicit user confirmation.
   - Always classify operations by risk (`ReadOnly`, `LowRisk`, `MediumRisk`, `HighRisk`).

---

## 2. Development & Testing Workflow

1. Fork the repository on GitHub: `https://github.com/marjuk06/marjuk-windows-toolkit`.
2. Create a feature branch: `git checkout -b feature/your-feature-name`.
3. Run tests using `scripts/test.ps1`:
   ```powershell
   powershell -File .\scripts\test.ps1
   ```
4. Commit your changes with a descriptive message following Conventional Commits.
5. Push to your fork and submit a Pull Request.

---

## 3. License Agreement

By contributing to this repository, you agree that your contributions will be licensed under the **GNU General Public License Version 3 (GPL-3.0)**.


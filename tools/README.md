# Tools

The scripts that were used to inspect and build this configuration. They are included because they
made the diagnosis in [../docs/troubleshooting.md](../docs/troubleshooting.md) possible, and because a
Legion owner will want the same checks.

All of them were run on Windows with the bundled Node.js and PowerShell — no `git`, no `gh`, no
developer toolchain installed.

## PowerShell

| Script | What it does |
|---|---|
| `dump-oc-config.ps1` | loads a `config*.plist` as XML and prints the keys that actually matter — SMBIOS, boot-args, Booter/Kernel quirks, `Kernel → Patch`, `Kernel → Add`, `DeviceProperties` |
| `fix-usb-config.ps1` | first pass of edits on the as-delivered config (Booter quirks, SMBIOS model, `DeviceProperties` cleanup) |
| `fix-usb-config-2.ps1` | second pass — the step that actually fixed the panic: disables the three `_cpu_thread_alloc` patches, adds `CpuTscSync`, disables `WhateverGreen` |

Two Windows-specific notes, both of which cost time during the bring-up:

- **Execution policy blocks running these directly.** Invoke them without changing system policy:
  ```powershell
  $sb = [scriptblock]::Create((Get-Content -Raw .\dump-oc-config.ps1)); & $sb -Path .\config.plist
  ```
- **`config.plist` is XML**, so `[xml]` plus XPath is the reliable way to read it. Regex-parsing a plist
  will eventually bite you on `<data>` blocks.

## Node.js

| Script | What it does |
|---|---|
| `efi-manifest.mjs` | walks the whole `EFI/` tree, emits a SHA-256 per file, and lists the version of every kext by reading its `Info.plist`. This is what produced the kext table in [../docs/opencore-efi.md](../docs/opencore-efi.md) and the `SHA256SUMS` at the repo root |

```bash
node efi-manifest.mjs /path/to/EFI
```

## What is not here

The scripts that staged this repository (sanitising the SMBIOS identity out of the configs and logs,
trimming the ring-buffer padding out of the logs, generating `SHA256SUMS`) are specific to this
publish and are not included. Every transformation they performed is described in
[../docs/mac-identity.md](../docs/mac-identity.md) and [../logs/README.md](../logs/README.md), and the
result can be verified against `SHA256SUMS`.

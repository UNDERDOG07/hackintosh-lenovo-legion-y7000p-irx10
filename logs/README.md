# Logs

Two OpenCore logs from 2026-10-11, kept because they are the evidence for the diagnosis in
[`../docs/troubleshooting.md`](../docs/troubleshooting.md).

| File | What it is |
|---|---|
| `opencore-2026-10-11-165534.txt` | the last of the three panic boots; it ends in `OCVAR: Restoring FW NVRAM...` |
| `opencore-2026-10-11-172613.txt` | the last boot of the day, with the `_cpu_thread_alloc` patches disabled — a clean hand-off |

## What was changed before publishing

The originals are exactly 262,144 bytes each: OpenCore writes its log into a **ring buffer** that size,
and the unused tail is NUL padding. These copies have the NUL bytes and trailing spaces stripped, so
they are ~47 KB and ~66 KB of actual text.

The two real SMBIOS identity values that OpenCore prints while programming the tables
(`OC: Setting HW_MLB ...`, `OC: Setting MLB ...`, `OC: Setting HW_SSN ...`, `OC: Setting SSN ...`) have
been replaced with the same placeholders used in the configs. Nothing else was altered — the line
order, timings and content are untouched.

## Reading an OpenCore log

```powershell
# PowerShell: strip the NUL ring-buffer padding before doing anything else
(Get-Content -Raw .\opencore-2026-10-11-172613.txt) -replace "\0", "" -split "`r?`n" |
    Where-Object { $_ } | Select-Object -Last 20
```

```bash
# bash
tr -d '\0' < opencore-2026-10-11-172613.txt | grep -n 'EXITBS\|force HT\|OCAK'
```

Two lines worth understanding before you read anything into them:

- `AAPL: #[EB|LOG:EXITBS:START]` — OpenCore handing control to the macOS kernel. **Normal.** Every log
  ends here, including panic boots, because OpenCore stops logging once the kernel runs. A log cannot
  tell you whether macOS came up.
- `OCAK: 64-bit force HT enabled for Sequoia or later replace count - 1` followed by
  `OC: Kernel patcher result 0 for kernel (force HT enabled for Sequoia or later) - Success` — a kernel
  patch being applied. In a working config these lines do not exist.

To collect your own, set `Misc → Debug → Target` in the config and look in `EFI/OC/` on the EFI
partition of whichever disk you booted from.

## The other eighteen

The full set of twenty logs stayed on the installer stick. Their per-boot summary (line count, whether
the HT patch was applied, last line) is tabulated in
[`../docs/troubleshooting.md`](../docs/troubleshooting.md).

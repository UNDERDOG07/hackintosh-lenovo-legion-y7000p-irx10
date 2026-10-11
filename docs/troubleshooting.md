# Troubleshooting

This page exists because of one specific failure that took most of the bring-up day to find, and
because the two OpenCore logs in `../logs/` are the evidence for it.

## First: how to read an OpenCore log

`Misc → Debug → Target` makes OpenCore write a log to the EFI partition. Two things about the format
catch people out:

- **The file is a 262,144-byte ring buffer.** Every log on the stick is exactly that size, and the
  unused tail is NUL padding. Reading it as text gives you a wall of nothing. Strip the NULs first
  (`(Get-Content -Raw x.txt) -replace "\0", ""`, or `tr -d '\0'`).
- **`AAPL: #[EB|LOG:EXITBS:START]` is not an error.** It is OpenCore handing control to the macOS
  kernel. Every log ends there, successful or not — once the kernel is running, OpenCore stops
  writing. A log can therefore *never* prove the kernel booted; it can only prove the hand-off was
  clean.

## The 0.85-second panic

**Symptom.** The machine restarts almost immediately after the Apple logo appears. The panic report
says:

```
Darwin Kernel Version 24.6.0 ... RELEASE_X86_64
roots installed: 0
Panic diags file unavailable, panic occurred prior to initialization
System uptime in nanoseconds: 853226865
```

`853226865` ns = **0.85 seconds**. `roots installed: 0` means the kernel never even got the root
filesystem mounted.

**Root cause.** The config carried three hyper-threading patches against `_cpu_thread_alloc`, all
enabled. The decisive lines in the log are:

```
OCAK: 64-bit force HT enabled for Sequoia or later replace count - 1
OC: Kernel patcher result 0 for kernel (force HT enabled for Sequoia or later) - Success
```

A "successful" patch that should not have been applied at all — the reference machine's
`Kernel → Patch` section is empty. The patches rewrite `41 8B 86 94 01 00 00` (`mov eax,[rsi+0x194]`)
into `B8 FF 00 00 00 90 90` (`mov eax,0xFF; nop; nop`), forcing a thread count the kernel does not
expect on this CPU.

**Fix.** All three entries set to `Enabled=false`. That is the only difference that mattered between
the as-delivered `config-1401-original-BACKUP.plist` and the working `config.plist`.

This is the step the owner did with **[dsh](https://github.com/deepseek-ai/deepseek-harness)
(DeepSeek Harness)**: it read the OpenCore logs off the stick, matched the panic to the `force HT`
patch lines above, and disabled the three entries. See the
[README credits](../README.en.md#thanks-and-what-is-deliberately-not-in-this-repo).

## The twenty boots from 2026-10-11

Every launch writes a log. These are what the twenty on the stick contain, in order (`forceHT` = the
HT patch was applied on that boot):

| Log | Lines | forceHT | Ends at |
|---|---|---|---|
| `093337` | 754 | no | `EXITBS:START` @09:34:34 |
| `095107` | 754 | no | `EXITBS:START` @09:52:05 |
| `105358` | 867 | no | `EXITBS:START` @10:54:24 |
| `110243` | 895 | no | `EXITBS:START` @11:03:11 |
| `110529` | 889 | no | `EXITBS:START` @11:05:57 |
| `110636` | 895 | no | `EXITBS:START` @11:07:01 |
| `111704` | 894 | no | `EXITBS:START` @11:17:47 |
| `112444` | 894 | no | `EXITBS:START` @11:25:21 |
| `113632` | 894 | no | `EXITBS:START` @11:39:15 |
| `114643` | 894 | no | `EXITBS:START` @11:47:29 |
| `122407` | 894 | no | `EXITBS:START` @12:24:32 |
| `122920` | 894 | no | `EXITBS:START` @12:29:54 |
| `123521` | 894 | no | `EXITBS:START` @12:35:57 |
| `124022` | 894 | no | `EXITBS:START` @12:40:51 |
| `164457` | 760 | **YES** | `EXITBS:START` @16:45:56 — **panic** |
| `165034` | 760 | **YES** | `EXITBS:START` @16:51:30 — **panic** |
| `165156` | 521 | no | `OCVAR: Restoring FW NVRAM...` — Reset NVRAM |
| `165222` | 760 | **YES** | `EXITBS:START` @16:53:19 — **panic** |
| `165534` | 517 | no | `OCVAR: Restoring FW NVRAM...` — Reset NVRAM |
| `172613` | 754 | no | `EXITBS:START` @17:27:14 — **last clean hand-off, with the fixed config** |

The 14 boots between 09:33 and 12:40 never applied the patch and all handed off cleanly; the
afternoon's three panics are exactly the three boots where `forceHT=YES`.

Two logs are included — [`../logs/opencore-2026-10-11-165534.txt`](../logs/opencore-2026-10-11-165534.txt)
(the last panic, which ends in an NVRAM reset) and
[`../logs/opencore-2026-10-11-172613.txt`](../logs/opencore-2026-10-11-172613.txt) (the last boot of
the day, with the fix in place); see [`../logs/README.md`](../logs/README.md) for what was trimmed.
`172613` contains no error strings at all apart from the harmless
`AAPL: #[EB|CFG:ARG] force-error 0x0000000000000000 ... default`, and ends with
`OCSMC: SmcReadValue` calls, i.e. VirtualSMC was alive at hand-off.

## Recovery ladder

Work down this list; each step is cheaper than the next one.

1. **Won't boot after a config change.** Put the working `EFI/OC/config.plist` from this repo back,
   or copy it off a second stick. If it still fails and you suspect a kext, disable entries in
   `Kernel → Add` one at a time — Lilu and VirtualSMC are the only two you cannot remove.
2. **Booting is fine but there is no graphics.** Check that the boot-args in `EFI/OC/config.plist`
   are still there (`nvfb=1 nvaccel=1 nvfbheads=4`), then run `sudo ./uninstall.sh` from the driver's
   `pkgroot` and reinstall it from the macOS side.
3. **NVRAM is suspect.** Two of the twenty boots were Reset NVRAM boots, reachable from the picker
   with `ResetNvramEntry.efi`. It costs you nothing except boot-args.
4. **Revert to the as-delivered configuration.** `config-1401-original-BACKUP.plist` is the untouched
   state. Note it has the HT patches **enabled**, so it is a reference for diffing, not a fallback
   you can boot.
5. **Boot Windows and rebuild the stick.** The Windows entry is never touched by any of this, which is
   the whole point of installing macOS next to it in its own partition.

## Log-scrolling noise that is not a problem

In macOS, these repeat and mean nothing is wrong:

```
clFindFHBAndGetChipsetInfoIndex_IMPL
chipset.c:462 / chipset.c:557 assertions
busy timeout (60s): 'NVRM'
PV-SENTINEL REFUSED ... BootKC
kapi event type 5
```

## Things that do indicate a real problem

| Message | Meaning |
|---|---|
| `Xid 79: GPU has fallen off the bus` / `NV_ERR_GPU_IS_LOST` | the driver lost the GPU — this is what system sleep does. Sleep must stay disabled |
| `NVRM-fb: getAttribute 'mrdf' -> 0xe00002c7` | resolution change in progress; the machine is about to freeze |
| `CoreDisplay: Failed to create MetalDevice` (crash loop) | the driver's Metal allow-list step did not run or was undone |
| `roots installed: 0` + a sub-second uptime | a kernel patch or quirk is killing it before the root mount — compare against `../logs/opencore-2026-10-11-172613.txt` |

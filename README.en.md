# Lenovo Legion Y7000P IRX10 (83NN) — macOS 15 Sequoia Hackintosh

[中文](README.md) · **English**

A complete, actually-booted OpenCore EFI and field notes for running **macOS 15 Sequoia** on a
**Lenovo Legion Y7000P IRX10** (`i9-14900HX` + **NVIDIA RTX 5060 Laptop**, driven by the **NullMoth**
NVIDIA driver), installed next to Windows 11 on a **256 GB partition** — not on a wiped disk.

Everything here came off the USB installer stick that made it work. The point of this repo is the
same as the Pro 5 one it was modelled on: **where every piece came from, what was changed and why,
what works, and how to get back to a bootable state if you break it.**

The EFI in `EFI/` is a real, working copy. The only thing swapped out is the Mac identity —
`SystemSerialNumber`, `MLB` (board serial), `SystemUUID` and `ROM` are placeholders. **Generate your
own with GenSMBIOS before you use it** — see [docs/mac-identity.md](docs/mac-identity.md).

---

## How this was built

Five steps, in the order they happened. The detail for each is in `docs/`.

| # | Step | What it actually meant | Detail |
|---|---|---|---|
| 1 | Confirm the GPU driver | There is no Intel iGPU driver in any macOS, so the internal panel is only reachable through the dGPU. Establish that a driver for this GPU exists ([NullMoth](https://github.com/nullmoth/nvidia-macos-driver)), that it covers **macOS 15**, and that the panel is wired to the dGPU so BIOS can be set to discrete-only | [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) · [docs/hardware.md](docs/hardware.md) |
| 2 | Build the boot stick with the [`1401`](https://github.com/nullmoth/1401) tool | A Windows tool downloads macOS Sequoia 15, writes this `EFI/` to a FAT32 stick and labels it `1401`. Result: `EFI/` + `com.apple.recovery.boot/` + the driver package | [docs/install-guide.md](docs/install-guide.md#step-2--build-the-boot-stick) |
| 3 | Change BIOS | Secure Boot off, CSM off, Above 4G on, Resizable BAR on, **graphics mode = discrete only** | [docs/hardware.md](docs/hardware.md#bios) |
| 4 | First boot panicked → fix `config.plist` | The as-delivered config carried three `Kernel → Patch` entries that mangle hyper-threading setup; the kernel died 0.85 s after hand-off. Disabling them produced the working config | [docs/troubleshooting.md](docs/troubleshooting.md) |
| 5 | Reach the desktop, then install the driver | macOS installs with no GPU acceleration at all (framebuffer only). The driver is installed **inside macOS**, into `/Library/Extensions` — nothing GPU-related lives in the EFI | [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) |

Step 4 is the step people get stuck on, and it is the reason the diagnosis material in this repo is
longer than the install material: an OpenCore log, a root cause, and a diff against the untouched
config. That step was done with **[dsh](https://github.com/deepseek-ai/deepseek-harness) (DeepSeek
Harness)**, an AI coding agent — it read the log, found the three `Kernel → Patch` entries and fixed
`config.plist`. See the credits below.

---

## Status

Confirmed on this machine after the install that this repo documents.

| Area | Status | Notes |
|---|---|---|
| Graphics | ✅ NVIDIA RTX 5060 Laptop, Metal accelerated | [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) 1.13.0. Internal panel is wired to the dGPU, so **BIOS MUX must be set to discrete-only** |
| Boot | ✅ OpenCore from USB Fat32 (volume `1401`) | macOS is still started **from the stick** on this machine: the internal ESP and every Windows partition were left untouched. 20 boot logs from the bring-up day are summarised in [docs/troubleshooting.md](docs/troubleshooting.md) |
| Internal display | ✅ 2560×1600 @ 60 Hz | 240 Hz mode is advertised by the panel but not reachable |
| External display | 🟡 works, no hot-plug | An external monitor driven by the dGPU works, but it has to be connected before boot — plugging one in while macOS is running does not bring it up |
| Trackpad | ❌ not working | The VoodooI2C stack is in the EFI, but the touchpad was never made to work here — the owner reports it does not respond. Porting the reference EFI's `VoodooI2C-RPL-GPIO` is the first thing to try |
| Wi-Fi | ❌ no driver | The card fitted here is an AX1690i (`8086:7A70`), replaced by the owner — it is not in the `itlwm` support list. Use a USB adapter |
| Bluetooth | ✅ works | `IntelBluetoothFirmware` + `IntelBTPatcher` + `BlueToolFixup`; confirmed paired and working on this machine |
| Ethernet | ✅ works | Realtek `10EC:8168` with `RealtekRTL8111`. This is the network path to use — it is the one that works |
| Audio | ✅ works | ALC257 with `layout-id=99`; the **built-in speakers work**. The internal microphone also *responds* — it registers in the system sound test, but it was not rigorously tested |
| Keyboard | ✅ | VoodooPS2Controller |
| Keyboard lighting | ✅ works | The backlight is held by the EC/firmware, so the keys are lit in macOS — confirmed on this machine. There is no `LegionRGBUSBFix` in this EFI, so what works is *being lit*: **changing** the 4-zone colours or effects from macOS is not possible |
| Battery / sensors | ✅ works | VirtualSMC + SMCBatteryManager + SMCProcessor/SMCSuperIO, with YogaSMC for the Legion EC: fans spin and **Fn+Q switches performance mode** on this machine |
| Camera | ⚠️ untested | Never checked on this machine |
| System sleep | ❌ disabled | The driver loses the GPU on wake. Display sleep works |
| Changing resolution | ❌ dangerous | Freezes the system. Do not touch Display settings |
| Brightness control | ❌ none | `AppleBacklightDisplay` count is 0 |
| HDMI/DP audio | ❌ none | |
| CUDA | ❌ impossible | Not in the driver, not in macOS |
| Apple ID / iServices | ⚠️ untested | Needs your own generated serial, and `MacBookPro16,4` is a desktop-class SMBIOS |

Legend: ✅ confirmed on this machine · 🟡 configured and expected to work, not individually verified ·
❌ known not to work on this hardware/driver · ⚠️ not tested.

---

## Repository layout

| Path | Contents |
|---|---|
| `EFI/` | The working OpenCore EFI, copied file-for-file off the USB stick apart from three extra config variants the write-up does not cover (151 files, ~40 MB) |
| `EFI/OC/config.plist` | The configuration that booted successfully last (17:23 on 2026-10-11) |
| `EFI/OC/config-1401-original-BACKUP.plist` | Untouched state as delivered by the `1401` tool — the "before" of step 4; keep it, never edit it |
| `docs/` | Field notes (see below) |
| `logs/` | Two trimmed OpenCore logs: the panic, and the last clean hand-off |
| `reports/nullmoth/` | Driver install report: the machine profile the installer itself wrote, plus its upstream README/MANIFEST |
| `tools/` | The PowerShell/Node helpers used to dump, patch and verify the configuration |
| `SHA256SUMS` | Every file in `EFI/`, so you can prove your copy is unmodified |

---

## Documentation

| Document | Covers |
|---|---|
| [docs/hardware.md](docs/hardware.md) | Exact device IDs, what macOS can and cannot drive, BIOS prerequisites |
| [docs/install-guide.md](docs/install-guide.md) | The five steps end to end, and where you are allowed to deviate |
| [docs/opencore-efi.md](docs/opencore-efi.md) | Every kext and its version, SSDTs, quirks, patches, boot-args, and why each differs from the reference |
| [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) | The driver, its hard requirements, install/uninstall, and where to get it |
| [docs/troubleshooting.md](docs/troubleshooting.md) | The 0.85-second panic and its root cause, Reset NVRAM boots, reading OpenCore logs, recovery |
| [docs/peripherals.md](docs/peripherals.md) | Trackpad, Wi-Fi/Bluetooth, audio, camera, USB, storage, power, display |
| [docs/mac-identity.md](docs/mac-identity.md) | Why the serials are placeholders and how to generate your own |
| [docs/sources.md](docs/sources.md) | Every upstream project, version and download location used here |

> This README exists in two languages: [中文](README.md) (the default) and **English** (this file).
> The detailed documents under `docs/` are in English only.

---

## Quick facts

- **Machine**: Lenovo Legion Y7000P IRX10, board `LNVNB161216`, chipset `HM770`, EC `0x5508` generation.
- **CPU**: Intel Core i9-14900HX (Raptor Lake-HX, 24 cores) — no official Apple config page, carried by `CpuTscSync` + `CpuTopologyRebuild`.
- **GPU**: the Intel UHD iGPU (`8086:A788`, Xe) has **no driver at all** in any macOS. The RTX 5060 Laptop (`10DE:2D59` / `17AA:802F`) is the only display path.
- **Disk layout**: Windows 11 keeps its disk. macOS lives in an **APFS container created in ~256 GB of free space** next to it — the disk was partitioned, never wiped, and no Windows partition or the shared EFI system partition was modified. This machine still boots macOS **from the USB stick**; the EFI was never copied to the internal ESP.
- **Hard prerequisite #1**: BIOS graphics mode must be **discrete GPU only** (no hybrid/Optimus).
- **Hard prerequisite #2**: **Secure Boot off**.
- **Hard prerequisite #3**: the NullMoth driver installs its kexts into `/Library/Extensions`, **not** into `EFI/OC/Kexts`. Nothing GPU-related belongs in the EFI.
- **Driver works on macOS 15 only.** Package 1.13.0 declares `runtime_minimum_macos: 15.5` and is qualified on 15.8.1.
- The three `Kernel → Patch` entries that mangle hyper-threading setup (`base _cpu_thread_alloc`) are **set to `Enabled=false`** in `config.plist`. Leaving them on caused a kernel panic 0.85 s after hand-off — see [docs/troubleshooting.md](docs/troubleshooting.md).

---

## Thanks, and what is deliberately *not* in this repo

The single most important component here is not mine: it is **NullMoth**, the NVIDIA driver that
makes a Blackwell-era RTX 5060 Laptop usable under macOS 15. Without it this machine would be a
black screen. Credit for the driver, and for the `1401` boot-stick tooling, belongs entirely to
**[NullMoth Systems](https://nullmothsystems.com)**.

| What | Where |
|---|---|
| Author / project site | <https://nullmothsystems.com> |
| **NVIDIA driver for macOS 15** | <https://github.com/nullmoth/nvidia-macos-driver> |
| Driver releases (this machine runs `1.13.0`) | <https://github.com/nullmoth/nvidia-macos-driver/releases> |
| **`1401` boot-stick tool (Windows)** | <https://github.com/nullmoth/1401> |
| GitHub organisation | <https://github.com/nullmoth> |

Both are free, public projects — the driver repo says *Free, source included*, the `1401` repo says
*Free, never for sale* — but **this repository deliberately does not redistribute them.** The stick carried
`NullMoth/nullmoth-nvidia-1.13.0.tar.gz` (269,301,262 bytes) and `1401-Mac-1.13.0.zip`; neither the
tarball, nor `pkgroot/`, nor any `.kext`/`.bundle`/`.dylib` from it is mirrored here. Those two repos
are the official distribution channel; get the package there and follow its own instructions. What *is* included is
[`reports/nullmoth/system-profile.json`](reports/nullmoth/system-profile.json) — the machine profile
the installer itself wrote on this laptop — plus its untouched `README.txt` and `MANIFEST.txt`, so the
result below is reproducible and verifiable without shipping someone else's binaries.

**The diagnosis and this write-up were made with [dsh](https://github.com/deepseek-ai/deepseek-harness)
(DeepSeek Harness)**, the AI coding agent this machine's owner worked with throughout the install. Working from
the local chat session, it read the 262 KB OpenCore ring-buffer logs off the stick, identified the
kernel panic as the three `Kernel → Patch` hyper-threading patches, disabled them in `config.plist`
(that is step 4 above), and then built this repository — the documentation, the sanitised configs and
`SHA256SUMS`. That is where the credit for the *fix* belongs; the hardware, the flashing and the
driver install were the owner's own work.

Thanks are equally due to the OpenCore team and the kext authors listed in
[docs/sources.md](docs/sources.md), and to
[Ammarrrrrrr/legion-pro5-hackintosh](https://github.com/Ammarrrrrrr/legion-pro5-hackintosh), whose
repo this one is modelled on and whose working config was the reference every change here was
compared against.

Also not here: anything with a real Mac identity in it, and no kexts whose licences forbid
redistribution. Third-party kexts inside `EFI/OC/Kexts` remain under their own upstream licences
(listed in [docs/sources.md](docs/sources.md)); the documentation in this repo is
[CC BY-NC-SA 4.0](LICENSE).

---

## Disclaimer

This is a record of one specific machine and one specific driver version. Hackintosh configurations
are not portable between models, and the NVIDIA driver is explicitly non-commercial. Flashing an EFI
can leave a laptop unable to boot; keep the Windows entry working and test from a USB stick first.
No warranty of any kind.

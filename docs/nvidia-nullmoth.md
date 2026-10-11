# The NVIDIA driver (NullMoth)

The GPU on this laptop is an **RTX 5060 Laptop** — Blackwell, and far outside anything Apple ever
supported. There is no Apple driver, no `WhateverGreen` path, and no amount of EFI work that will
produce a picture.

What makes this machine usable is a third-party NVIDIA driver for macOS 15 called **NullMoth**. It is
not mine, it is not in this repository, and essentially all of the credit for this build belongs to
its authors.

## What it provides

From the package's own `MANIFEST.txt` and `BASELINE-IDENTITY.json` (version **1.13.0**):

| Piece | Goes to |
|---|---|
| `NVAccel.kext`, `NVRM.kext`, `NVRMAGDC.kext`, `NVRMFB.kext` | `/Library/Extensions` |
| `NVIDIAShared.bundle`, `NVMTLDriver.bundle`, `nvmtl` | `/Library/GPUBundles` |
| `NVAccel.kext` per-OS copies (the package ships one per macOS generation) | `/Library/NullMoth/kexts/` |
| GSP firmware `610.57.04` (`gsp_ga10x.bin`, `gsp_tu10x.bin`, µcodes) | `/Users/Shared/nvfw/nvidia/610.57.04` |

`NVMTLDriver.bundle` is the Metal path and is what actually makes the desktop render: it plus
`libnvmtl_translate`, an embedded LLVM (`air-runtime/libLLVM.dylib`, 145 MB) and a Vulkan ICD
(`libvulkan_nouveau.dylib`).

## Hard requirements

- **macOS 15 only.** `runtime_minimum_macos: 15.5`. The 1.13.0 package's own scope note says it
  "installs only on macOS 15".
- **Discrete-GPU-only BIOS mode.** The driver drives the panel that is wired to the RTX 5060.
- **Above 4G Decoding on, Resizable BAR on.** Without Re-Size BAR the driver loads and the screen
  stops at the boot text.
- **EFI-side boot arguments**: `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth` are in this repo's
  config.

## Install

With the original stick, the `1401-Mac` companion app does it. By hand:

```bash
tar -xzf nullmoth-nvidia-1.13.0.tar.gz
cd pkgroot
sudo ./install.sh
```

Uninstall is `sudo ./uninstall.sh` from the same directory.

Two design details from the package that matter when things go wrong:

- The installer **leaves the kexts switched off while the boot-picker "remove" flag is set**, so a
  restart still lands you somewhere bootable.
- It also makes the Metal allow-list readable by `WindowServer`; without that step the system hits a
  `CoreDisplay: Failed to create MetalDevice` crash loop right after installation.

## What the driver itself says is not qualified

Quoted from `BASELINE-IDENTITY.json`:

> `unqualified`: refresh changes with two displays connected (known issue, fix planned for 1.2) ·
> RTX 5090 physical qualification · universal device and application support · DRM · automatic
> internal EFI migration · optional DTrace capture

Its qualification record for 1.13.0 is: macOS **15.8.1**, RTX 5060, 2 displays, `guarded_boot:
passed`, refresh changes at 60/75/100 Hz committed on the changed display, Metal buffer copy verified,
with the known issue that after a refresh change on one display the other can show blank frames until
restart.

## What is deliberately not mirrored here

The stick carried:

- `NullMoth/nullmoth-nvidia-1.13.0.tar.gz` — 269,301,262 bytes
- `NullMoth/1401-Mac-1.13.0.zip` — 2,305,068 bytes

**Neither is in this repository**, and neither is `pkgroot/` nor any `.kext`, `.bundle` or `.dylib`
extracted from them. Get the driver from the project's own distribution channel.

What *is* included, because it is evidence rather than redistribution:

- [`reports/nullmoth/system-profile.json`](../reports/nullmoth/system-profile.json) — the profile the
  installer wrote on this laptop: board `LNVNB161216`, chipset `HM770`, CPU `i9-14900HX`
  (Raptor Lake-HX), platform Laptop, `smbios: MacBookPro16,2`, and a `disabled_devices` list naming
  the Intel UHD iGPU (`8086-A788`) and the NVIDIA HDMI audio device (`10DE-00AD`). It also records a
  per-file `efi_sha256` map of the `EFI/` on the stick.
- `upstream-README.txt` and `upstream-MANIFEST.txt`, unmodified.

## Thank you

To the NullMoth authors, and to everyone who publishes Legion hackintosh configurations and the
`Acidanthera` projects this EFI is built from: this laptop only runs macOS because you published your
work. Any error in this repository is mine; the parts that work are yours.

# The OpenCore EFI

Everything in `EFI/` is a byte-for-byte copy of what was on the install stick, apart from the Mac
identity values, which are placeholders, and three extra `config-*.plist` variants that this write-up
does not use and does not ship. `SHA256SUMS` at the repo root covers all 151 files.

- `EFI/BOOT/BOOTx64.efi` — the bootstrap loader.
- `EFI/OC/OpenCore.efi` — 872,448 bytes. The binary carries no readable version string (the
  `529.140.2` / `209.0.0` style strings inside it belong to the embedded Apple firmware tables), so
  this repo deliberately does **not** claim a version number — it claims a hash.
- `EFI/OC/Tools/` is empty.
- `EFI/OC/Resources/` is 3,609,827 bytes: picker icons, fonts and labels used by the OpenCore boot
  menu (this repo only ships the files the EFI already had).

## Kexts

26 bundles, all in `EFI/OC/Kexts`. 31 entries are enabled in `Kernel → Add` because several kexts are
nested (`VoodooI2C` pulls in `VoodooGPIO`, `VoodooI2CServices` and `VoodooInput`; `VoodooPS2Controller`
pulls in three plugins).

| Kext | Version | Bundle ID | Purpose |
|---|---|---|---|
| Lilu | 1.7.3 | `as.vit9696.Lilu` | kext patching framework — everything depends on it |
| VirtualSMC | 1.3.9 | `as.vit9696.VirtualSMC` | SMC emulation |
| SMCBatteryManager | 1.3.9 | | battery |
| SMCLightSensor | 1.3.9 | | ambient light sensor |
| SMCProcessor | 1.3.9 | | CPU temperature |
| SMCSuperIO | 1.3.9 | | fan/super-I/O |
| AppleALC | 1.9.9 | `as.vit9696.AppleALC` | audio, `layout-id=99` |
| WhateverGreen | 1.7.2 | `as.vit9696.WhateverGreen` | **present but disabled** — see below |
| AMFIPass | 1.4.1 | `com.dhinakg.AMFIPass` | lets kexts load with AMFI restrictions on |
| RestrictEvents | 1.1.7 | `as.vit9696.RestrictEvents` | suppresses CPU-name / memory notices |
| NVMeFix | 1.1.4 | `as.vit9696.NVMeFix` | NVMe power management |
| CpuTscSync | 1.1.2 | `org.lvs1974.driver.CpuTscSync` | **added during bring-up** — TSC sync on this HX part |
| CpuTopologyRebuild | 2.0.2 | `org.b00t0x.CpuTopologyRebuild` | rebuilds 24-core topology for macOS scheduling |
| BrightnessKeys | 1.0.4 | `as.vit9696.BrightnessKeys` | maps brightness keys (panel backlight itself is dead) |
| RealtekRTL8111 | 2.4.2 | `com.insanelymac.RealtekRTL8111` | wired Ethernet |
| itlwm | 2.3.0 | `com.zxystd.itlwm` | Intel Wi-Fi — **injected, but the on-board CNVi card is not supported** |
| IntelBluetoothFirmware | 2.5.0 | | Intel Bluetooth firmware upload |
| IntelBTPatcher | 2.5.0 | | Intel Bluetooth patching |
| BlueToolFixup | 2.7.3 | | Bluetooth stack fixups for macOS 12+ |
| VoodooI2C | 2.9.1 | | I2C HID stack (with `VoodooGPIO`, `VoodooI2CServices`) |
| VoodooI2CHID | 1.0 | | I2C HID touchpad |
| VoodooPS2Controller | 2.3.8 | | PS/2 keyboard (with Keyboard/Mouse/Trackpad plugins) |
| USBToolBox | 1.2.0 | | USB port mapping support |
| UTBDefault | 1.0 | `com.dhinakg.USBToolBox.injector` | default port map |
| XHCI-unsupported | 0.9.2 | `org.rehabman.injector.XHCI.unsupported` | XHCI quirk injector |
| YogaSMC | 1.5.3 | `org.zhen.YogaSMC` | Legion fan speeds, temperatures, Fn+Q |
| **WhateverGreen** | 1.7.2 | | **disabled**: it targets the Intel iGPU path, which does not exist on this machine |

## ACPI

Nine SSDTs, all prebuilt `.aml`:

| SSDT | Bytes |
|---|---|
| `SSDT-PLUG-ALT.aml` | 4120 |
| `SSDT-XOSI.aml` | 219 |
| `SSDT-USBX.aml` | 166 |
| `SSDT-SBUS.aml` | 128 |
| `SSDT-EC.aml` | 125 |
| `SSDT-GPI0.aml` | 124 |
| `SSDT-USB-Reset.aml` | 110 |
| `SSDT-MCHC.aml` | 105 |
| `SSDT-RTCAWAC.aml` | 78 |

## UEFI drivers

`HfsPlus.efi`, `OpenRuntime.efi`, `ResetNvramEntry.efi` — all enabled. `ResetNvramEntry` is what the
picker's Reset NVRAM entry uses; two of the twenty bring-up boots were Reset NVRAM boots.

## boot-args

In `config.plist`:

```
-v debug=0x100 keepsyms=1 -vi2c-force-polling ctrsmt=full nvfb=1 nvaccel=1 nvfbheads=4
-nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0
```

`nvfb`, `nvaccel`, `nvfbheads`, `nvkmsnosmooth` are the driver's own arguments; `-vi2c-force-polling`
and `ctrsmt=full` are for the I2C touchpad and the TSC sync; the two `amfi` arguments are what let
kexts load on macOS 15.

## Kernel patches — the important part

`Kernel → Patch` has three entries, all three against `base _cpu_thread_alloc`:

| Comment | Find | Replace |
|---|---|---|
| `force HT enabled for Sequoia or later` | `QYuGlAEAAA==` | `uP8AAACQkA==` |
| `force HT enabled for Mojave to Sonoma` | `i4iUAQAA` | `uf8AAACQ` |
| `force HT enabled for High Sierra or earlier (untested)` | `i4iQAQAA` | `uQAAAACQ` |

In `config-1401-original-BACKUP.plist` all three are `Enabled=true`. **In the working `config.plist`
all three are `Enabled=false`** — that single change is what turned a machine that panicked at 0.85 s
into one that installs.

Leaving them enabled is what caused this machine to panic 0.85 seconds after OpenCore handed off to
the kernel. Full analysis in [troubleshooting.md](troubleshooting.md).

## Quirks

`Booter → Quirks` — three were changed from the as-delivered values:

| Quirk | Value | As delivered | Why |
|---|---|---|---|
| `AllowRelocationBlock` | **false** | true | |
| `DevirtualiseMmio` | **false** | true | it was claiming ~276 MB of MMIO |
| `FixupAppleEfiImages` | **false** | true | |
| `AvoidRuntimeDefrag` | true | true | |
| `EnableSafeModeSlide` | true | true | |
| `ProtectUefiServices` | true | true | |
| `ProvideCustomSlide` | true | true | |
| `RebuildAppleMemoryMap` | true | true | |
| `SetupVirtualMap` | true | true | |
| `SyncRuntimePermissions` | true | true | |

`Kernel → Quirks`:

`AppleXcpmCfgLock` true · **`AppleXcpmExtraMsrs` true** (was false) · `CustomSMBIOSGuid` true ·
`DisableIoMapper` true · `DisableLinkeditJettison` true · `PanicNoKextDump` true ·
`PowerTimeoutKernelPanic` true · `ProvideCurrentCpuInfo` true · `XhciPortLimit` false

## PlatformInfo and DeviceProperties

Both configs in this repo share the same placeholder-safe skeleton:

- `SystemProductName` = `MacBookPro16,4` (the pristine backup says `MacBookPro16,2`)
- `Automatic` = true, `UpdateSMBIOSMode` = Custom, `CustomSMBIOSGuid` = true
- `SecureBootModel` = Disabled, `Vault` = Optional, `ScanPolicy` = 0, `DmgLoading` = Signed
- `ExposeSensitiveData` = 7
- `csr-active-config` = `QwoAAA==` = `0x0A43` — `ALLOW_UNTRUSTED_KEXTS`, `UNRESTRICTED_FS`,
  `UNRESTRICTED_NVRAM`, `ANY_RECOVERY_OS`, `UNAPPROVED_KEXTS`

`DeviceProperties → Add` is reduced to a single entry, `PciRoot(0x0)/Pci(0x1f,0x3)` with
`layout-id=99`. The as-delivered config also carried `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)` and
`PciRoot(0x0)/Pci(0x2,0x0)` — those are the GPU and the iGPU, and both were removed because the
NVIDIA path is handled by the driver in `/Library/Extensions`, not by the EFI.

## What differs from the reference (Legion Pro 5 16IRX9)

The reference EFI for the Pro 5 has kexts this one does not: `AirportItlwm`, `LegionRGBUSBFix`,
`UTBMap`, `VoodooI2C-RPL-GPIO` (a rebuilt VoodooGPIO) and `YogaSMC-Legion`. This machine uses
`itlwm` + `UTBDefault` + stock `VoodooI2C`/`YogaSMC` instead, and has **no** keyboard-lighting fix.
If you want the RGB lighting, that is the piece to port over — it was never pursued (or tested) here,
because the owner does not use it.

Two of those gaps have a visible consequence on this machine: the keyboard lighting does nothing, and
the **touchpad does not work** (see [peripherals.md](peripherals.md)). `VoodooI2C-RPL-GPIO` is the
first thing to try for the touchpad — the stock `VoodooGPIO` in this EFI has no Raptor Lake-HX GPIO
support, and the same controller ID works in the reference build where that kext is present.

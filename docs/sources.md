# Sources

Where every component in `EFI/` comes from, and at which version. All versions were read out of each
kext's `Info.plist` (`CFBundleShortVersionString` / `CFBundleVersion`) on the stick, not copied from a
release page.

## Bootloader

| Component | Version | Upstream |
|---|---|---|
| OpenCore (`OpenCore.efi`, `BOOTx64.efi`, `OpenRuntime.efi`, `ResetNvramEntry.efi`) | no readable version string in the binary — see `SHA256SUMS` | https://github.com/acidanthera/OpenCorePkg |
| OpenCanopy resources (`EFI/OC/Resources`: picker icons, fonts, labels) | as shipped with the above | https://github.com/acidanthera/OcBinaryData |
| `HfsPlus.efi` | as shipped | OpenCorePkg / Apple |

## Kexts

| Kext | Version | Upstream |
|---|---|---|
| Lilu | 1.7.3 | https://github.com/acidanthera/Lilu |
| VirtualSMC (+ SMCBatteryManager, SMCLightSensor, SMCProcessor, SMCSuperIO) | 1.3.9 | https://github.com/acidanthera/VirtualSMC |
| AppleALC | 1.9.9 | https://github.com/acidanthera/AppleALC |
| WhateverGreen *(disabled in the config)* | 1.7.2 | https://github.com/acidanthera/WhateverGreen |
| RestrictEvents | 1.1.7 | https://github.com/acidanthera/RestrictEvents |
| NVMeFix | 1.1.4 | https://github.com/acidanthera/NVMeFix |
| BrightnessKeys | 1.0.4 | https://github.com/acidanthera/BrightnessKeys |
| VoodooPS2Controller (+ Keyboard, Mouse, Trackpad) | 2.3.8 | https://github.com/acidanthera/VoodooPS2 |
| BlueToolFixup | 2.7.3 | https://github.com/acidanthera/BrcmPatchRAM |
| AMFIPass | 1.4.1 | https://github.com/dhinakg/AMFIPass |
| CpuTscSync | 1.1.2 | https://github.com/lvs1974/CpuTscSync |
| CpuTopologyRebuild | 2.0.2 | https://github.com/b00t0x/CpuTopologyRebuild |
| USBToolBox + UTBDefault | 1.2.0 / 1.0 | https://github.com/USBToolBox/kext |
| itlwm | 2.3.0 | https://github.com/OpenIntelWireless/itlwm |
| IntelBluetoothFirmware + IntelBTPatcher | 2.5.0 | https://github.com/OpenIntelWireless/IntelBluetoothFirmware |
| VoodooI2C (+ VoodooGPIO, VoodooI2CServices, VoodooInput) | 2.9.1 | https://github.com/VoodooI2C/VoodooI2C |
| VoodooI2CHID | 1.0 | https://github.com/VoodooI2C/VoodooI2CHID |
| RealtekRTL8111 | 2.4.2 | https://github.com/Mieze/RTL8111_driver_for_OS_X |
| XHCI-unsupported | 0.9.2 | https://github.com/RehabMan/OS-X-USB-Inject-All |
| YogaSMC | 1.5.3 | https://github.com/zhen-zen/YogaSMC |

## ACPI

The nine SSDTs are prebuilt `.aml` files. The common ones (`SSDT-EC`, `SSDT-PLUG-ALT`, `SSDT-SBUS`,
`SSDT-MCHC`, `SSDT-USBX`, `SSDT-USB-Reset`, `SSDT-XOSI`) originate from the Dortania OpenCore install
guide and the OpenCorePkg documentation; `SSDT-GPI0` and `SSDT-RTCAWAC` are machine-specific and come
with the Legion configuration this EFI is derived from.

- Dortania OpenCore Install Guide: https://dortania.github.io/OpenCore-Install-Guide/
- SSDT collection: https://github.com/dortania/Getting-Started-With-ACPI

## The NVIDIA driver

**NullMoth**, package version **1.13.0**. Distributed by its authors through their own channel;
**not mirrored in this repository**. See [nvidia-nullmoth.md](nvidia-nullmoth.md).

## The configuration this EFI is modelled on

- **`Ammarrrrrrr/legion-pro5-hackintosh`** — https://github.com/Ammarrrrrrr/legion-pro5-hackintosh
  A Legion Pro 5 16IRX9 (`83DF`) with the same I2C touchpad controller (`INTC1085`) and the same class
  of NVIDIA driver. The repo layout, the status table and much of the reasoning here follow it. If you
  have a Legion and are starting from scratch, read that one first.

## Tools used to build this repository

Everything in `tools/`, run with the bundled Node.js and PowerShell on Windows:

| Tool | What it does |
|---|---|
| `dump-oc-config.ps1` | extracts the interesting keys out of every `config*.plist` via XPath |
| `fix-usb-config.ps1`, `fix-usb-config-2.ps1` | the two edits that turned the as-delivered config into a bootable one |
| `efi-manifest.mjs` | walks the EFI, emits SHA-256 per file plus kext versions |

## The agent that did the diagnosis

The step-4 diagnosis — reading the 262 KB OpenCore ring-buffer logs, finding the three
`Kernel → Patch` hyper-threading patches and disabling them in `config.plist` — was done by
**[dsh](https://github.com/deepseek-ai/deepseek-harness) (DeepSeek Harness)**, an AI coding agent run
against the local chat session on this laptop. The same session produced the documentation in this
repository. See the credits in the [README](../README.en.md).

## Licensing of the included binaries

The kexts and bootloader in `EFI/` remain under **their own upstream licences** — most Acidanthera
kexts are BSD-3-Clause, while the VoodooI2C/VoodooPS2 family, `itlwm` and several others are
GPL-2.0. They are redistributed here unmodified, in the same way the reference repository does it.
Check each project's `LICENSE` before reusing them in anything commercial.

The NVIDIA driver is separate, is **not** distributed here, and carries its own non-commercial
terms.

The documentation in this repository is [CC BY-NC-SA 4.0](../LICENSE).

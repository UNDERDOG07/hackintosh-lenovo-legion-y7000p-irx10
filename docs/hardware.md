# Hardware

Lenovo **Legion Y7000P IRX10** — board `LNVNB161216`, chipset `HM770`, EC `0x5508` generation.
The ID block below is what the installer itself recorded in
[`reports/nullmoth/system-profile.json`](../reports/nullmoth/system-profile.json) plus what the PCI
scan on this machine reports.

## Devices

| Component | Detail | PCI / USB ID | macOS 15 |
|---|---|---|---|
| CPU | Intel Core i9-14900HX, Raptor Lake-HX, 24 cores / 32 threads | — | ✅ no Apple config page, but works with the right quirks |
| iGPU | Intel UHD Graphics, Xe architecture | `8086:A788` | ❌ **no driver exists**, in any macOS version |
| dGPU | NVIDIA RTX 5060 Laptop GPU, BAR1 8192 MB | `10DE:2D59` / subsystem `17AA:802F` | ✅ via the [NullMoth](https://github.com/nullmoth/nvidia-macos-driver) driver, macOS 15 only |
| Panel | BOE NE160QDM-NZB, 2560×1600, 240 Hz capable | — | 🟡 60 Hz, fixed resolution |
| Wi-Fi | AX1690i (Intel CNVi part), **fitted by the owner** as a replacement for the factory card | `8086:7A70` | ❌ not on the `itlwm` support list |
| Ethernet | Realtek PCIe GbE | `10EC:8168` | ✅ works (`RealtekRTL8111`) — the reliable network path on this machine |
| Audio | Realtek ALC257 codec, driven through Intel SST | `8086:7A50` | ✅ built-in speakers work; the internal mic responds to the sound test (not rigorously tested) |
| Trackpad | I2C HID touchpad on GPIO | `INTC1085` (`GPI0`) | ❌ **not working** — the kext stack is present but the touchpad never responded on this machine |
| Keyboard | PS/2, plus 4-zone RGB controller | RGB: `048d:c995` | ✅ keyboard; ⚠️ lighting untested (nothing in the EFI drives it) |
| Storage | 2 × NVMe — UMIS `RPJYJ1T24MM`, YMTC `YMSS2ED08D2`, **VMD disabled** | — | ✅ neither is on the macOS NVMe blacklist |
| Battery / sensors | Legion EC `0x5508` generation | — | ✅ works — VirtualSMC + SMCBatteryManager, fans and Fn+Q performance mode respond |
| Camera | built-in UVC | — | ⚠️ not tested on this machine |
| Bluetooth | same Intel CNVi combo module as the Wi-Fi card | — | ✅ works (`IntelBluetoothFirmware` + `IntelBTPatcher` + `BlueToolFixup`) |

## The three hard prerequisites

These are not preferences. Any one of them being wrong is the difference between a booting system and
a black screen.

1. **BIOS graphics mode = discrete GPU only.** The internal panel is physically wired to the RTX 5060,
   and the Intel iGPU has no macOS driver at all. In hybrid/Optimus mode the laptop reports the panel
   on the iGPU and there is nothing to drive it.
2. **Secure Boot off.** The OpenCore bootloader is not Microsoft-signed, so the firmware refuses to
   start it.
3. **The camera, GPU and audio kexts are split across two places.** GPU support lives in
   `/Library/Extensions` (installed by the driver package); everything else lives in `EFI/OC/Kexts`.
   Do not copy driver kexts into the EFI.

## BIOS settings the installer's own tooling asked for

The application that built the install stick scanned this machine and emitted this list (it printed
it in Chinese; the table below is the same content):

| Setting | Required | Why |
|---|---|---|
| Secure Boot | **Off** | unsigned bootloader |
| CSM / legacy boot | **Off** | macOS boots UEFI only; with CSM on, the GPU often hangs during early boot |
| Above 4G Decoding | **On** | the NVIDIA driver maps the full VRAM above the 4 GB boundary |
| Resizable BAR / Re-Size BAR | **On** | **required by the NVIDIA driver** — with it off the screen stops at the boot text |
| Fast Boot (firmware) | Off (optional) | can skip USB initialisation and hide the install stick |
| XHCI Hand-off | On (optional) | lets macOS take over USB port control |
| CFG Lock | Off (optional, usually hidden) | the EFI already handles it via `AppleXcpmCfgLock` |

On Lenovo consumer laptops the BIOS key is **F2**; the one-time boot menu is **F12**.

## Before you touch anything

- macOS does **not** have to take a whole disk. This install freed ~256 GB and created the APFS
  container in that free space, leaving Windows and the EFI system partition untouched. If you do
  give macOS a whole disk of its own, be certain which disk you are erasing — see
  [install-guide.md](install-guide.md) step 4.
- The machine this repo documents **still boots from the USB stick** — the EFI was never written to
  the internal ESP. That is the safest place to leave it while you are still experimenting, and
  nothing about the Windows installation has to change for it.
- **Save your BitLocker recovery key first**, then suspend BitLocker. Changing Secure Boot while
  BitLocker is armed can make Windows demand the recovery key on the next boot.
- Disable Windows Fast Startup and hibernation — a dirty NTFS flag plus a hibernation image is a
  reliable way to break the dual boot.
- Keep a wired network available during installation; the Wi-Fi card has no macOS driver.

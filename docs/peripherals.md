# Peripherals

Status per component, with the mechanism behind it. Items marked *not individually verified* are
configured the way the reference machine (Legion Pro 5 16IRX9) has them working, but were not
separately tested on this laptop before this repo was written.

## Trackpad — present in the config, not working

**On this machine the touchpad does not respond.** The kext stack is installed and the device ID
matched the reference build, but it was never made to work here, so treat this build as *keyboard +
mouse only* until someone fixes it.

What is in place:

- The touchpad is an I2C HID device on the `GPI0` pin controller, ID `INTC1085` — the **same
  controller ID as the known-working Pro 5 configuration**, which is why this was expected to work.
- `VoodooI2C` 2.9.1 (with `VoodooGPIO` and `VoodooI2CServices`), `VoodooI2CHID` 1.0, the `SSDT-GPI0.aml`
  ACPI table, and the boot-arg `-vi2c-force-polling` (polling instead of interrupts, because the GPIO
  interrupt configuration is not reliable here).

What to try, in order:

1. **`VoodooI2C-RPL-GPIO`** — a rebuilt `VoodooGPIO` with Raptor Lake GPIO support. The reference EFI
   has it and this one does not; the stock `VoodooGPIO` predates Raptor Lake-HX, which is the most
   likely reason nothing attaches here.
2. Check that `SSDT-GPI0.aml` matches this machine's `GPI0` namespace (it came from the installer
   tooling, not from a hand-built dump).
3. Drop `-vi2c-force-polling` once interrupts work, and compare against the reference build's I2C
   properties.

## Wi-Fi — no driver

The Wi-Fi card in this laptop is an **AX1690i** (`8086:7A70`), an Intel CNVi part that the owner
fitted in place of the factory module. It is not on the `itlwm` support list, so `itlwm` 2.3.0 is
injected but will not attach to it. There is no kext workaround.

**Use a USB Wi-Fi adapter, or wired Ethernet.** During installation this matters: the macOS installer
has no network at all without one of them.

An alternative worth trying if you want the internal card: `AirportItlwm`, which the reference EFI
uses. It is not in this EFI.

## Bluetooth — works

`IntelBluetoothFirmware` 2.5.0 + `IntelBTPatcher` 2.5.0 + `BlueToolFixup` 2.7.3 are all injected, and
Bluetooth is **confirmed working** on this machine.

This is worth calling out, because the Wi-Fi half of the same CNVi combo module has no driver at all:
the Bluetooth side is a separate USB-attached device and does not depend on the Wi-Fi kext, so the two
halves have entirely independent driver support.

## Audio

`AppleALC` 1.9.9 with `layout-id=99`, set through `DeviceProperties` on
`PciRoot(0x0)/Pci(0x1f,0x3)`. The codec is a **Realtek ALC257 behind Intel SST** (`8086:7A50`).

- The **built-in speakers work** with `layout-id=99` on this machine.
- The **internal microphone responds**: it registers a level in the system sound-input test. That is
  the whole of the evidence, though — it was not rigorously tested (no recording checked for level,
  noise or intelligibility), so treat "the mic works" as likely rather than proven. It is still worth
  noting, because Intel SST machines are usually listed as unsupported for the internal mic and this
  one demonstrably is not dead.
- **HDMI/DP audio: no.** It routes through the NVIDIA driver, which does not implement it.

If `layout-id=99` gives you nothing, the documented alternatives to try are 11, 18, 86, 96, 97, 100
and 101.

## Camera

**Not tested.** The status of the internal camera on this machine is simply unknown — it was not
checked before this repo was written, so nothing here should be read as a claim either way.

One caveat worth knowing if you go looking: Photo Booth has been reported to render black on this
driver, because it goes through Core Image, which cannot draw into the driver's Metal drawable. A
plain UVC capture path (FaceTime, QuickTime) is the thing to try first, and if it works there, the
camera itself is fine.

## USB

`USBToolBox` 1.2.0 plus `UTBDefault` 1.0 provide a default port map, and `SSDT-USB-Reset.aml` and
`SSDT-USBX.aml` are present for power properties and controller reset. `XHCI-unsupported` 0.9.2 is
injected for the unsupported-controller quirk.

The reference EFI uses a hand-built `UTBMap` instead of `UTBDefault`. If you hit a port that does not
work, building a real map with USBToolBox is the next step.

## Storage

Two NVMe drives, UMIS `RPJYJ1T24MM` and YMTC `YMSS2ED08D2`, with **VMD disabled** (if VMD is on, the
drives vanish behind Intel's RAID controller and macOS sees nothing). Neither model is on the macOS
NVMe problem list — that list is Samsung PM981/PM991, Micron 2200S and Intel 600p.

`NVMeFix` 1.1.4 handles power management.

## Power, battery and thermals — works

`VirtualSMC` 1.3.9 + `SMCBatteryManager` for the battery, `SMCProcessor` for CPU temperature,
`SMCSuperIO` for fan/Super-IO, `SMCLightSensor` for the ambient light sensor, and `YogaSMC` 1.5.3 for
Legion-specific features (fan speeds, temperatures, Fn+Q performance mode).

Confirmed on this machine: the fans run under macOS and **Fn+Q switches the performance mode**, which
is the Legion EC being read and written through `YogaSMC` — so the SMC side of the build is working,
not just present. Battery reporting comes through `SMCBatteryManager`.

## Sleep — disabled on purpose

**System sleep is broken and must stay off.** On wake the driver loses the GPU
(`Xid 79: GPU has fallen off the bus`, `NV_ERR_GPU_IS_LOST`), which produces a black screen and
eventually a `WindowServer` watchdog panic. Display sleep is fine.

```bash
sudo pmset -a disablesleep 1 sleep 0 standby 0 hibernatemode 0 powernap 0 proximitywake 0
```

## Display

- Internal panel: 2560×1600 at **60 Hz**. The panel advertises 240 Hz through DisplayID 2.0, but every
  EDID override is ignored and 8 bpc is not enough bandwidth at that mode anyway (DSC would be
  required). 60 Hz is what you get.
- **Do not change the resolution.** Every non-native mode goes through the driver's scaler path and
  freezes the whole system, logging `NVRM-fb: getAttribute 'mrdf' -> 0xe00002c7`.
- **Brightness control does not exist.** `AppleBacklightDisplay` count is 0 — the panel backlight is
  not exposed through the Apple brightness interface. `BrightnessKeys` is injected so the keys do not
  throw errors, but there is nothing to control.
- **External displays work, but there is no hot-plug.** A monitor attached to the dGPU output before
  the machine boots lights up normally; plugging one in while macOS is already running does not bring
  it up, so connect first and then boot. The driver's own caveat applies as well: after a refresh-rate
  change on one display the other can show blank frames until restart.

## Keyboard and lighting

PS/2 keyboard via `VoodooPS2Controller` 2.3.8. The 4-zone RGB controller (`048d:c995`) is **not driven
by anything in this EFI** — there is no `LegionRGBUSBFix`, so macOS has no way to change the lighting
and it behaves however the firmware left it. This was **never tested** either way, because the owner
does not use it; if you want it, `LegionRGBUSBFix` is the piece to port from the reference EFI.

## Ethernet — works

Realtek `10EC:8168` with `RealtekRTL8111` 2.4.2, **confirmed working**. With no Wi-Fi driver on this
machine, this (or a USB Wi-Fi dongle) is the network path.

The reference EFI uses version 3.0.0; swap the kext if you want that version, it is a drop-in
replacement for this chip.

## What is impossible, not just unimplemented

- **CUDA.** Not in the driver, not in macOS.
- **DRM playback** (Netflix/Apple TV in a browser). The driver's own unqualified list names DRM.
- **The Intel iGPU.** No driver exists in any macOS for Xe-generation integrated graphics, so
  hardware video decode on the iGPU is out; the NVIDIA driver handles decode.

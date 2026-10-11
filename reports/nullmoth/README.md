# NullMoth driver — install report

This folder documents the **result** of installing the NVIDIA driver on this laptop. It does **not**
contain the driver.

## What is here

| File | What it is |
|---|---|
| `system-profile.json` | the machine profile the driver's installer **wrote on this laptop** — untouched |
| `upstream-README.txt` | the `README.txt` from the driver distribution, unmodified |
| `upstream-MANIFEST.txt` | the package manifest, listing what the installer places on disk |

`system-profile.json` is the interesting one. It reports the machine the installer actually ran on:

- `board: LENOVO LNVNB161216`, `chipset: HM770`, `platform: Laptop`
- `cpu: Intel(R) Core(TM) i9-14900HX`, `cpu_codename: Raptor Lake-HX`
- `smbios: MacBookPro16,2`, `macos_version: "24.99.99"`
- `disabled_devices:` includes the Intel UHD iGPU (`8086-A788`) and the NVIDIA HDMI audio device
  (`10DE-00AD`)
- `identity_status: build_bound_live_unverified`, with every `qualification` entry
  `unverified` / `not_assessed` / `mapping_required`
- an `efi_sha256` map covering the files in the `EFI/` on the installer stick

That last field is why the profile is published: it lets you check the EFI in this repository against
the EFI the driver installer actually saw on this machine.

## What is deliberately missing

The installer stick also carried:

- `nullmoth-nvidia-1.13.0.tar.gz` — 269,301,262 bytes
- `1401-Mac-1.13.0.zip` — 2,305,068 bytes
- `pkgroot/` — `install.sh`, `uninstall.sh`, four `.kext` bundles, three GPU bundles, GSP firmware

**None of it is mirrored here**, and no `.kext`, `.bundle`, `.dylib` or firmware blob from it appears
anywhere in this repository. Get both packages from the project's own distribution channel:
**driver** <https://github.com/nullmoth/nvidia-macos-driver/releases>, **`1401` stick tool**
<https://github.com/nullmoth/1401>, **author/project site** <https://nullmothsystems.com>. See
[`../../docs/nvidia-nullmoth.md`](../../docs/nvidia-nullmoth.md).

The package's own metadata, quoted for reference (`pkgroot/BASELINE-IDENTITY.json`, version 1.13.0):

- `runtime_minimum_macos: "15.5"`, qualified on macOS `15.8.1` with an RTX 5060 and two displays
- `scope`: *"...This update installs only on macOS 15."*
- `unqualified`: DRM · RTX 5090 physical qualification · universal device and application support ·
  automatic internal EFI migration · optional DTrace capture · refresh changes with two displays
  connected

All credit for the driver belongs to its authors. Nothing in this repository would produce a picture
without it.

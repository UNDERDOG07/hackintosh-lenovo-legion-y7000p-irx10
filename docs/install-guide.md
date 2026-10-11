# Install guide

This is the order that worked on this machine — **not a script to follow blindly**. Every machine,
firmware version and driver build differs, so treat the five steps as the shape of the job and the
notes as the reasoning behind it. Where something can be done another way, it says so.

It is written for a **Windows-only environment** — no Mac, no `git`, no `gh` — because that is how
this install was done.

Read [hardware.md](hardware.md) first. The three hard prerequisites there are assumed throughout.

---

## The five steps at a glance

| # | Step | Done when |
|---|---|---|
| 1 | Confirm the GPU driver exists and covers your macOS version | You know which macOS release you are installing, and why |
| 2 | Build the boot stick with the `1401` tool | A FAT32 stick boots to the OpenCore picker |
| 3 | Change BIOS | Secure Boot off, CSM off, Above 4G + ReBAR on, graphics = discrete only |
| 4 | Install; if the first boot panics, read the log and fix `config.plist` | The installer finishes and the desktop comes up |
| 5 | Install the NVIDIA driver from inside macOS | The GPU is accelerated after a reboot |

---

## What you need

- **~256 GB of free space** for macOS, or a second drive. This install put macOS in an APFS
  container created in free space next to Windows — the disk was **partitioned, not wiped**. See
  step 4.
- A USB stick, 16 GB or larger. It will be wiped.
- A wired network connection (there is no working Wi-Fi on this model).
- Your BitLocker recovery key, written down somewhere that is not this laptop.
- The NVIDIA driver package from the NullMoth distribution
  (<https://github.com/nullmoth/nvidia-macos-driver/releases>, see
  [nvidia-nullmoth.md](nvidia-nullmoth.md)). It is **not** in this repo.

---

## Step 1 — Confirm the GPU driver first

Do this before downloading anything. On this laptop it is the whole ballgame:

- The Intel UHD iGPU (`8086:A788`) has **no driver in any macOS**. There is no fallback.
- The internal panel is wired to the dGPU, so BIOS can be set to **discrete-only** and the dGPU
  becomes the single display path.
- The NullMoth driver is qualified for **macOS 15 only** (package 1.13.0: `runtime_minimum_macos:
  15.5`, tested on 15.8.1). Pick the macOS release *after* reading that, not before.

If any of those three is untrue for your machine, stop here — no config change fixes a missing
driver. Details and the exact device IDs are in [hardware.md](hardware.md) and
[nvidia-nullmoth.md](nvidia-nullmoth.md).

## Step 2 — Build the boot stick

The stick used here was produced by a Windows application — the `1401` tool, published by the same
authors as the driver at <https://github.com/nullmoth/1401> — which:

1. asks for the target USB stick (4 GB minimum — use 16 GB),
2. writes this repo's `EFI/` to it,
3. downloads **macOS Sequoia 15** from Apple's servers and verifies each file against Apple's
   signature.

The result is a FAT32 stick whose volume label is `1401` and whose root contains `EFI/` and
`com.apple.recovery.boot/`. Keep the driver package in a folder on the stick too (the original kept
it under `NullMoth/`) — you will copy it into macOS in step 5.

Deviations that are fine:

- Building the stick by hand (a working OpenCore `EFI/` + `com.apple.recovery.boot` from Apple) is
  equivalent. So is any other tool that produces those two things.
- The `1401` label is just a name. It is not a version number — do not read anything into it.
- If your stick is small, the driver package can live on any other USB drive or on the Windows
  partition; it only has to be reachable from macOS.

## Step 3 — BIOS

Set these, save and exit (usually **F10**), and let Windows boot once to confirm nothing broke:

- Secure Boot → **Off**
- CSM → **Off**
- Above 4G Decoding → **On**
- Resizable BAR → **On**
- Graphics / MUX mode → **discrete GPU only**
- Fast Boot → Off, XHCI Hand-off → On (if your firmware exposes them)

Then boot the stick: F12 for the one-time boot menu, pick the entry marked **UEFI**.

## Step 4 — Install, and fix the config that panics

**4a. Give macOS its space.** Free up ~256 GB on the target disk (Windows Disk Management: shrink
the data partition, leave the space **unallocated**). Do **not** wipe the disk that holds Windows,
and do not delete the EFI system partition — the two systems share it.

**4b. Install.** At the OpenCore picker choose the entry whose name ends in **`(dmg)`** — that is the
installer. In the installer:

1. **Disk Utility → View → Show All Devices**.
2. Select the **physical disk** and use **Partition** (the `+` button) to create a new **APFS**
   container/volume in the free space, named `Macintosh HD`. *Never* erase the whole disk, and
   never touch the Windows partition or the ESP.
3. Quit Disk Utility, choose **Reinstall macOS**, pick `Macintosh HD`.
4. It reboots several times. **Every time, boot from the USB stick again** and pick the
   `macOS Installer` entry, until that entry is replaced by `Macintosh HD`.

If you are giving macOS a whole second drive instead, erasing that drive as APFS/GUID is fine — just
be certain which disk you are pointing at. Drive letters do not exist inside Disk Utility, so identify
the disk by model and size before you click anything.

**4c. If it panics instead of booting.** On this machine the as-delivered config killed the kernel
0.85 s after OpenCore handed off. The fix was:

1. Boot the stick, pick the entry, let it fail, and **keep the OpenCore log** that is written to the
   root of the stick (`opencore-*.txt`).
2. Compare the config against the untouched `EFI/OC/config-1401-original-BACKUP.plist`.
3. Disable the three `Kernel → Patch` entries with `Base = _cpu_thread_alloc` (`Enabled = false`).

That is exactly the difference between `config-1401-original-BACKUP.plist` and `config.plist` in
this repo, and it is what made the installer run. The full diagnosis — the log, the patch bytes, and
the two boot logs kept as evidence — is in [troubleshooting.md](troubleshooting.md). Read it before
changing random quirks; OpenCore panics have causes, and guessing usually makes them worse.

**4d. Keep the stick.** This machine still needs it to boot macOS. Copying the EFI to the internal
ESP is possible (see the end of this document), but do it *after* a few successful boots from the
stick.

## Step 5 — Install the NVIDIA driver from inside macOS

Do this **after** the first successful desktop boot. Until then macOS runs with no GPU acceleration
at all — that is expected, not a failure, and it is why step 1 comes first.

With the original stick this is the `1401-Mac` companion app (part of
<https://github.com/nullmoth/1401>); by hand it is:

```bash
tar -xzf nullmoth-nvidia-1.13.0.tar.gz
cd pkgroot
sudo ./install.sh
```

The installer writes the GPU kexts to `/Library/Extensions`, drops a machine profile at
`/Users/Shared/` and in the package directory, and keeps its own uninstaller next to it. After it
finishes, reboot. The first boot after installation initialises the GPU firmware; expect a long black
screen, not a hang.

What the package itself claims it is qualified for (`BASELINE-IDENTITY.json`, package 1.13.0):

- `runtime_minimum_macos: 15.5`
- qualified on macOS **15.8.1**, RTX 5060, 2 displays attached, Metal buffer copy verified
- explicitly **unqualified**: DRM playback, universal device/application support, automatic internal
  EFI migration, refresh-rate changes with two displays connected

---

## After the install: keeping it usable

This driver is fragile in specific, documented ways. The rules that keep the system usable:

```bash
# disable sleep (the GPU is lost on wake and the machine panics)
sudo pmset -a disablesleep 1 sleep 0 standby 0 hibernatemode 0 powernap 0 proximitywake 0
```

- Do not open **System Settings → Displays** and change the resolution. It freezes the machine.
- Do not install macOS point updates on autopilot. Read the driver package's notes first.
- Keep two things: the USB stick, and the driver's own `pkgroot/uninstall.sh`. Between them you can
  always get back to a bootable machine.

## Making the boot permanent (optional)

**The machine this repo documents never did this.** It still boots macOS from the USB stick, and no
Windows partition or the shared EFI system partition was modified for any of it — which is exactly why
the dual boot stayed safe. Do this only once you are bored of plugging the stick in:

- Copy `EFI/` to the internal ESP (`\EFI\OC\`) or add a UEFI boot entry pointing at it.
- **Verify the Windows boot entry still works before you touch the internal ESP.** Both systems share
  that partition.
- Then boot the internal entry a few times before you repurpose the stick.

## If it will not boot

1. **USB stick, OpenCore picker** — first, always. If the picker appears, the EFI is fine and the
   problem is later in the boot; if it does not, the ESP or the stick layout is the problem.
2. **Put the working config back.** Copy `EFI/OC/config.plist` from this repo (or off a second stick)
   over the one on the stick. Do **not** restore `config-1401-original-BACKUP.plist` to get out of
   trouble: it still has the HT patches enabled and will panic.
3. **Reset NVRAM** from the OpenCore picker (`ResetNvramEntry.efi` is in the EFI). Two of the twenty
   boots in [troubleshooting.md](troubleshooting.md) were exactly this.
4. **Run the driver's uninstaller** if the machine breaks right after a driver install or a macOS
   update.

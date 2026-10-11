# Mac identity (SMBIOS)

Every `config*.plist` in this repository has the real identity values replaced with placeholders:

| Key | Placeholder in this repo | What it does |
|---|---|---|
| `SystemSerialNumber` | `C02XXXXXXXXX` | the machine serial macOS sees |
| `MLB` (board serial) | `C02XXXXXXXXXXXXXX` | main logic board serial |
| `SystemUUID` | `00000000-0000-0000-0000-000000000000` | hardware UUID |
| `ROM` (`<data>`) | `AAAAAAAA` | the MAC address macOS reports for the primary interface |

The same four values appeared in the OpenCore logs from the bring-up day — OpenCore prints them when
it programs the SMBIOS tables (`OC: Setting MLB ...`, `OC: Setting SSN ...`). Those two log files in
`../logs/` have been redacted the same way.

**Do not use the placeholders as they are.** `C02XXXXXXXXX` is not a valid serial, and a shared or
invalid identity is the fastest way to get an Apple ID locked.

## Generate your own

The `MacBookPro16,4` SMBIOS this config uses (the pristine backup says `MacBookPro16,2`) is what the
NVIDIA driver's installer recorded as the running model — see
`../reports/nullmoth/system-profile.json`, field `smbios`.

The standard tool is **GenSMBIOS**. From any Mac (or the macOS side of this install):

1. Back up the config you are about to edit.
2. Generate a `MacBookPro16,4` set: serial, board serial (MLB), and UUID.
3. Put the serial in `SystemSerialNumber`, the board serial in `MLB`, and the generated UUID in
   `SystemUUID`.
4. Set `ROM` to a valid 6-byte MAC address encoded as base64 `<data>` — usually your Ethernet MAC, and
   it should differ from the real MAC of any interface you use. The reference machine uses its own.
5. Set `SystemProductName` to `MacBookPro16,4` (matching the SMBIOS you generated for) and keep
   `Automatic` = true, `UpdateSMBIOSMode` = Custom, `CustomSMBIOSGuid` = true.

Then reset NVRAM once (the picker has a **Reset NVRAM** entry, backed by `ResetNvramEntry.efi`) so the
old values are not replayed from NVRAM.

## A caution about iServices

Signing in to iCloud/iMessage with a generated identity is a change to what Apple sees. It was **not**
tested on this machine, and it is worth being deliberate about:

- Generate a *unique* serial, never one copied from another repo or another user.
- `MacBookPro16,4` is a small-form-factor desktop model, which makes the identity itself plausible,
  but the hardware behind it is not.
- Do not enable iServices until the machine boots reliably; a half-working install that phones home
  repeatedly is a good way to burn a serial.

## If you only want the machine to boot

Nothing in this repository's *boot* path depends on the identity. Graphics, Ethernet and USB all work
with the placeholders in place. Generate a real identity when you want App Store/iCloud, not before.

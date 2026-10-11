# fix-usb-config-2.ps1
#
# Second pass of edits over EFI/OC/config.plist on the installer stick, 2026-10-11.
#
# What this pass does is the one change that mattered: it sets Enabled=false on every entry of
# `Kernel -> Patch`. In the as-delivered config that array holds three "force HT enabled" patches
# against `_cpu_thread_alloc`; on this CPU they made the kernel panic 0.85 s after OpenCore handed
# off. With them off, the installer ran. Full diagnosis: ../docs/troubleshooting.md
#
# It edits the file in place. The state it produced is EFI/OC/config.plist in this repository; the
# state before both passes is EFI/OC/config-1401-original-BACKUP.plist.
$ErrorActionPreference = "Stop"
$Path = "F:\EFI\OC\config.plist"
$raw = [System.IO.File]::ReadAllText($Path)
$nl = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
$lines = New-Object System.Collections.ArrayList
foreach ($l in [System.IO.File]::ReadAllLines($Path)) { [void]$lines.Add($l) }
$log = New-Object System.Collections.ArrayList

# ---- Kernel/Patch: disable every entry (the working reference EFI has an empty array here) ----
$k = -1; for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '<key>Kernel</key>') { $k = $i; break } }
$kp = -1; for ($i=$k; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '<key>Patch</key>') { $kp = $i; break } }
$end = -1; for ($i=$kp; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*</array>\s*$') { $end = $i; break } }
$n = 0
for ($i=$kp; $i -lt $end; $i++) {
  if ($lines[$i] -match '<key>Enabled</key>' -and $lines[$i+1] -match '<true\s*/>') { $lines[$i+1] = ($lines[$i+1] -replace '<true\s*/>','<false/>'); $n++ }
}
[void]$log.Add("Kernel/Patch: disabled $n entries (L$($kp+1)-L$($end+1))")

$text = ([string]::Join($nl, [string[]]$lines)) + $nl
[System.IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
[void]$log.Add("wrote $Path (" + (Get-Item $Path).Length + " B)")
$log | ForEach-Object { Write-Output $_ }

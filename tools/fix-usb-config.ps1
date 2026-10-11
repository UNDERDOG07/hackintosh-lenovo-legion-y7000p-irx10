# fix-usb-config.ps1
#
# First pass of edits over EFI/OC/config.plist on the installer stick, 2026-10-11. It aligns the
# as-delivered config with the known-working Legion Pro 5 reference: three Booter quirks, one Kernel
# quirk, the SMBIOS model, DeviceProperties, and the kext list.
#
# It edits the file in place and keeps a copy of the result next to the script. The second pass is
# ../tools/fix-usb-config-2.ps1; what the state after both passes looks like is EFI/OC/config.plist
# in this repository, and what it looked like before them is EFI/OC/config-1401-original-BACKUP.plist.
$ErrorActionPreference = "Stop"
$Path = "F:\EFI\OC\config.plist"
$RecordPath = ".\config-fixed-20261011.plist"
$raw = [System.IO.File]::ReadAllText($Path)
$nl = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
$lines = New-Object System.Collections.ArrayList
foreach ($l in [System.IO.File]::ReadAllLines($Path)) { [void]$lines.Add($l) }
$log = New-Object System.Collections.ArrayList
$script:fail = 0

function Set-Bool([string]$Key, [string]$Value) {
  $idx = @(); for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('<key>' + [regex]::Escape($Key) + '</key>')) { $idx += $i } }
  if ($idx.Count -ne 1) { [void]$log.Add("FAIL(bool) $Key matches=$($idx.Count)"); $script:fail++; return }
  $i = $idx[0]
  if ($lines[$i+1] -notmatch '^\s*<(true|false)\s*/>\s*$') { [void]$log.Add("FAIL(bool) $Key next line = $($lines[$i+1])"); $script:fail++; return }
  [void]$log.Add("OK   $Key : $($lines[$i+1].Trim()) -> <$Value/>")
  $lines[$i+1] = ($lines[$i+1] -replace '<(true|false)\s*/>', "<$Value/>")
}
function Set-Str([string]$Key, [string]$Value) {
  $idx = @(); for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('<key>' + [regex]::Escape($Key) + '</key>')) { $idx += $i } }
  if ($idx.Count -ne 1) { [void]$log.Add("FAIL(str) $Key matches=$($idx.Count)"); $script:fail++; return }
  $i = $idx[0]
  if ($lines[$i+1] -notmatch '^\s*<string>') { [void]$log.Add("FAIL(str) $Key next line = $($lines[$i+1])"); $script:fail++; return }
  [void]$log.Add("OK   $Key : $($lines[$i+1].Trim()) -> <string>$Value</string>")
  $lines[$i+1] = ($lines[$i+1] -replace '<string>.*</string>', "<string>$Value</string>")
}
function Remove-PciChild([string]$PciKey) {
  $i = -1; for ($k=0; $k -lt $lines.Count; $k++) { if ($lines[$k] -match ('<key>' + [regex]::Escape($PciKey) + '</key>')) { $i = $k; break } }
  if ($i -lt 0) { [void]$log.Add("FAIL(rm) $PciKey not found"); $script:fail++; return }
  $j = $i + 1
  while ($j -lt $lines.Count -and $lines[$j] -notmatch '^\s*</dict>\s*$') { $j++ }
  if ($j -ge $lines.Count) { [void]$log.Add("FAIL(rm) $PciKey no close"); $script:fail++; return }
  [void]$log.Add("OK   removed DeviceProperties child $PciKey (lines $($i+1)-$($j+1))")
  $lines.RemoveRange($i, $j - $i + 1)
}
function Disable-Kext([string]$Bundle) {
  $i = -1; for ($k=0; $k -lt $lines.Count; $k++) { if ($lines[$k] -match ('<string>' + [regex]::Escape($Bundle) + '</string>')) { $i = $k; break } }
  if ($i -lt 0) { [void]$log.Add("FAIL(disable) $Bundle not found"); $script:fail++; return }
  for ($j = $i; $j -lt [Math]::Min($i + 8, $lines.Count); $j++) {
    if ($lines[$j] -match '<key>Enabled</key>') {
      if ($lines[$j+1] -match '^\s*<true\s*/>\s*$') { $lines[$j+1] = ($lines[$j+1] -replace '<true\s*/>', '<false/>'); [void]$log.Add("OK   $Bundle Enabled -> false") }
      else { [void]$log.Add("WARN $Bundle Enabled already $($lines[$j+1].Trim())") }
      return
    }
  }
  [void]$log.Add("FAIL(disable) $Bundle : no Enabled key nearby"); $script:fail++
}

# ---- 1. Booter/Quirks 对齐 83DF ----
Set-Bool 'AllowRelocationBlock' 'false'
Set-Bool 'DevirtualiseMmio' 'false'
Set-Bool 'FixupAppleEfiImages' 'false'
# ---- 2. Kernel/Quirks 对齐 83DF ----
Set-Bool 'AppleXcpmExtraMsrs' 'true'
# ---- 3. SMBIOS：换成有独显的机型 ----
Set-Str 'SystemProductName' 'MacBookPro16,4'
# ---- 4. DeviceProperties：只留 layout-id（与 83DF 一致）----
Remove-PciChild 'PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)'
Remove-PciChild 'PciRoot(0x0)/Pci(0x2,0x0)'
# ---- 5. WhateverGreen 关闭 ----
Disable-Kext 'WhateverGreen.kext'
# ---- 6. 插入 CpuTscSync（放在 CpuTopologyRebuild 之前）----
$tpl = @(
"`t`t`t<dict>",
"`t`t`t`t<key>Arch</key>",
"`t`t`t`t<string>Any</string>",
"`t`t`t`t<key>BundlePath</key>",
"`t`t`t`t<string>CpuTscSync.kext</string>",
"`t`t`t`t<key>Comment</key>",
"`t`t`t`t<string>CpuTscSync 1.1.2 for i9-14900HX (24 cores)</string>",
"`t`t`t`t<key>Enabled</key>",
"`t`t`t`t<true/>",
"`t`t`t`t<key>ExecutablePath</key>",
"`t`t`t`t<string>Contents/MacOS/CpuTscSync</string>",
"`t`t`t`t<key>MaxKernel</key>",
"`t`t`t`t<string></string>",
"`t`t`t`t<key>MinKernel</key>",
"`t`t`t`t<string></string>",
"`t`t`t`t<key>PlistPath</key>",
"`t`t`t`t<string>Contents/Info.plist</string>",
"`t`t`t</dict>"
)
$k = -1; for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '<string>CpuTopologyRebuild\.kext</string>') { $k = $i; break } }
if ($k -lt 0) { [void]$log.Add("FAIL(insert) CpuTopologyRebuild.kext not found"); $script:fail++ }
else {
  $d = -1; for ($j=$k; $j -ge 0; $j--) { if ($lines[$j] -match '^\s*<dict>\s*$') { $d = $j; break } }
  if ($d -lt 0) { [void]$log.Add("FAIL(insert) opening dict not found"); $script:fail++ }
  else { $lines.InsertRange($d, [string[]]$tpl); [void]$log.Add("OK   inserted CpuTscSync.kext Kernel/Add entry before line $($d+1)") }
}

$log | ForEach-Object { Write-Output $_ }
if ($script:fail -gt 0) { Write-Output "=== $($script:fail) check(s) failed, nothing written ==="; exit 1 }
$text = ([string]::Join($nl, [string[]]$lines)) + $nl
[System.IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
Copy-Item -LiteralPath $Path -Destination $RecordPath -Force
Write-Output ("=== wrote " + $Path + " (" + (Get-Item $Path).Length + " B), copy kept at " + $RecordPath)
param([Parameter(Mandatory=$true)][string]$Path)

$x = New-Object System.Xml.XmlDocument
$x.PreserveWhitespace = $false
$x.Load($Path)

function Get-Scalar([string]$key) {
  $n = $x.SelectSingleNode("//key[.='$key']/following-sibling::*[1]")
  if ($null -eq $n) { return '<absent>' }
  if ($n.Name -eq 'true') { return 'true' }
  if ($n.Name -eq 'false') { return 'false' }
  if ($n.Name -eq 'array') { return "<array len=$($n.ChildNodes.Count)>" }
  if ($n.Name -eq 'dict') { return '<dict>' }
  return $n.InnerText
}

"### FILE: $Path"
"# ---- PlatformInfo / SMBIOS ----"
foreach ($k in 'SystemProductName','SystemSerialNumber','MLB','SystemUUID','ROM','Automatic','UpdateSMBIOSMode','CustomSMBIOSGuid','SecureBootModel','SpoofVendor','SystemMemoryStatus') {
  "  {0,-22} = {1}" -f $k, (Get-Scalar $k)
}
"# ---- boot-args / NVRAM ----"
"  boot-args              = " + (Get-Scalar 'boot-args')
"  csr-active-config      = " + (Get-Scalar 'csr-active-config')
"  prev-lang:kbd          = " + (Get-Scalar 'prev-lang:kbd')
"# ---- Misc > Security ----"
foreach ($k in 'SecureBootModel','Vault','ScanPolicy','DmgLoading','AllowNvramReset','ExposeSensitiveData') {
  $n = $x.SelectSingleNode("//key[.='Security']/following-sibling::dict[1]/key[.='$k']/following-sibling::*[1]")
  $v = if ($null -eq $n) { '<absent>' } elseif ($n.Name -in 'true','false') { $n.Name } else { $n.InnerText }
  "  {0,-22} = {1}" -f $k, $v
}
"# ---- Booter > Quirks (non-default only shown raw) ----"
$q = $x.SelectNodes("//key[.='Booter']/following-sibling::dict[1]/key[.='Quirks']/following-sibling::dict[1]/*")
"  Booter.Quirks: " + (($q | ForEach-Object { if ($_.Name -in 'true','false') { $p = $_.PreviousSibling; while ($p -and $p.Name -ne 'key') { $p = $p.PreviousSibling }; "$($p.InnerText)=$($_.Name)" } }) -join ', ')
$kq = $x.SelectNodes("//key[.='Kernel']/following-sibling::dict[1]/key[.='Quirks']/following-sibling::dict[1]/*")
"  Kernel.Quirks: " + (($kq | ForEach-Object { if ($_.Name -in 'true','false') { $p = $_.PreviousSibling; while ($p -and $p.Name -ne 'key') { $p = $p.PreviousSibling }; "$($p.InnerText)=$($_.Name)" } }) -join ', ')
"# ---- Kernel > Patch ----"
$patches = $x.SelectNodes("//key[.='Kernel']/following-sibling::dict[1]/key[.='Patch']/following-sibling::array[1]/dict")
"  count = $($patches.Count)"
foreach ($p in $patches) {
  $en = $p.SelectSingleNode("key[.='Enabled']/following-sibling::*[1]")
  $cm = $p.SelectSingleNode("key[.='Comment']/following-sibling::*[1]")
  $bs = $p.SelectSingleNode("key[.='Base']/following-sibling::*[1]")
  $fd = $p.SelectSingleNode("key[.='Find']/following-sibling::*[1]")
  $rp = $p.SelectSingleNode("key[.='Replace']/following-sibling::*[1]")
  "  - enabled=$($en.Name) base='$($bs.InnerText)' comment='$($cm.InnerText)' find=$($fd.InnerText) replace=$($rp.InnerText)"
}
"# ---- Kernel > Add ----"
$adds = $x.SelectNodes("//key[.='Kernel']/following-sibling::dict[1]/key[.='Add']/following-sibling::array[1]/dict")
"  count = $($adds.Count)"
foreach ($a in $adds) {
  $en = $a.SelectSingleNode("key[.='Enabled']/following-sibling::*[1]")
  $bp = $a.SelectSingleNode("key[.='BundlePath']/following-sibling::*[1]")
  "  - {0,-34} enabled={1}" -f $bp.InnerText, $en.Name
}
"# ---- DeviceProperties > Add keys ----"
$dp = $x.SelectNodes("//key[.='DeviceProperties']/following-sibling::dict[1]/key[.='Add']/following-sibling::dict[1]/key")
"  " + (($dp | ForEach-Object { $_.InnerText }) -join ' | ')
"# ---- UEFI > Drivers ----"
$drv = $x.SelectNodes("//key[.='UEFI']/following-sibling::dict[1]/key[.='Drivers']/following-sibling::array[1]/*")
"  " + (($drv | ForEach-Object { if ($_.Name -eq 'dict') { $p=$_.SelectSingleNode("key[.='Path']/following-sibling::*[1]"); $e=$_.SelectSingleNode("key[.='Enabled']/following-sibling::*[1]"); "$($p.InnerText):$($e.Name)" } else { $_.InnerText } }) -join ' | ')
""

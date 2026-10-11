import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ROOT = process.argv[2] || 'F:\\EFI';
const out = [];

function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else out.push(p);
  }
}
walk(ROOT);

const rows = [];
for (const p of out) {
  const buf = fs.readFileSync(p);
  rows.push({
    rel: path.relative(ROOT, p).replace(/\\/g, '/'),
    size: buf.length,
    sha256: crypto.createHash('sha256').update(buf).digest('hex'),
  });
}

// kext versions
const kexts = [];
for (const dir of fs.readdirSync(path.join(ROOT, 'OC', 'Kexts'))) {
  if (!dir.endsWith('.kext')) continue;
  const info = path.join(ROOT, 'OC', 'Kexts', dir, 'Contents', 'Info.plist');
  let ver = '', ident = '';
  if (fs.existsSync(info)) {
    const t = fs.readFileSync(info, 'latin1');
    const g = (k) => {
      const m = t.match(new RegExp(`<key>${k}</key>\\s*<string>([^<]*)</string>`));
      return m ? m[1] : '';
    };
    ver = g('CFBundleShortVersionString') || g('CFBundleVersion');
    ident = g('CFBundleIdentifier');
  }
  kexts.push({ name: dir, ver, ident });
}

// OpenCore version string
const ocBuf = fs.readFileSync(path.join(ROOT, 'OC', 'OpenCore.efi'));
const ocStr = ocBuf.toString('latin1');
const ocVer = (ocStr.match(/(\d+\.\d+\.\d+)/g) || []).slice(0, 8);

// BOOTx64 version
const bootBuf = fs.readFileSync(path.join(ROOT, 'BOOT', 'BOOTx64.efi'));
const bootStr = bootBuf.toString('latin1');
const bootVer = (bootStr.match(/(\d+\.\d+\.\d+)/g) || []).slice(0, 8);

console.log('=== KEXTS (' + kexts.length + ') ===');
for (const k of kexts) console.log(`${k.name}\t${k.ver}\t${k.ident}`);
console.log('\n=== OpenCore.efi candidate versions ===', ocVer.join(', '));
console.log('=== BOOTx64.efi candidate versions ===', bootVer.join(', '));
console.log('\n=== FILES (' + rows.length + ') ===');
for (const r of rows) console.log(`${r.sha256}  ${String(r.size).padStart(10)}  ${r.rel}`);

fs.writeFileSync(process.argv[3] || 'D:\\DHS\u6d4b\u8bd5\\tools\\_efi-manifest.json',
  JSON.stringify({ root: ROOT, files: rows, kexts, ocVer, bootVer }, null, 1));

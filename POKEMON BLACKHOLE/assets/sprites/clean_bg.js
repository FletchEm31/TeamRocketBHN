'use strict';
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const SRC = path.join(__dirname, 'v11');
const DST = path.join(__dirname, 'v12');

// ---- CRC32 (PNG) ----
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
}

// ---- PNG decode (8-bit RGBA / RGB / grayscale+palette-not-supported beyond what we need) ----
function decode(file) {
  const b = fs.readFileSync(file);
  let p = 8, idat = [], w, h, bd, ct;
  while (p < b.length) {
    const len = b.readUInt32BE(p);
    const type = b.toString('ascii', p + 4, p + 8);
    if (type === 'IHDR') { w = b.readUInt32BE(p + 8); h = b.readUInt32BE(p + 12); bd = b[p + 16]; ct = b[p + 17]; }
    else if (type === 'IDAT') idat.push(b.slice(p + 8, p + 8 + len));
    else if (type === 'IEND') break;
    p += 12 + len;
  }
  if (bd !== 8 || ct !== 6) throw new Error(`${path.basename(file)}: unsupported bitDepth=${bd} colorType=${ct}`);
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const bpp = 4, stride = w * bpp + 1, out = Buffer.alloc(w * h * bpp);
  let prev = Buffer.alloc(w * bpp);
  for (let y = 0; y < h; y++) {
    const ft = raw[y * stride];
    const line = raw.slice(y * stride + 1, y * stride + 1 + w * bpp);
    const cur = Buffer.alloc(w * bpp);
    for (let i = 0; i < w * bpp; i++) {
      const a = i >= bpp ? cur[i - bpp] : 0;
      const bb = prev[i];
      const c = i >= bpp ? prev[i - bpp] : 0;
      let v = line[i];
      if (ft === 1) v = (v + a) & 255;
      else if (ft === 2) v = (v + bb) & 255;
      else if (ft === 3) v = (v + ((a + bb) >> 1)) & 255;
      else if (ft === 4) {
        const pa = Math.abs(bb - c), pb = Math.abs(a - c), pc = Math.abs(a + bb - 2 * c);
        const pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? bb : c);
        v = (v + pr) & 255;
      }
      cur[i] = v;
    }
    cur.copy(out, y * w * bpp);
    prev = cur;
  }
  return { w, h, out };
}

// ---- PNG encode (8-bit RGBA, filter 0) ----
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}
function encode(w, h, rgba) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const stride = w * 4;
  const raw = Buffer.alloc((stride + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (stride + 1)] = 0; // filter None
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, y * stride + stride);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
}

// ---- Background removal: estimate border bg color, clear border-connected
// pixels within tolerance. Connectivity protects interior same-color details
// (e.g. Charizard's black outlines, which never touch the border). ----
function cleanBg(w, h, out, opts) {
  const orig = Buffer.from(out); // compare against pristine colors
  // estimate bg color = most common quantized opaque border color
  const counts = new Map();
  const consider = (x, y) => {
    const i = (y * w + x) * 4;
    if (orig[i + 3] < 8) return;
    const key = (orig[i] >> 3) + ',' + (orig[i + 1] >> 3) + ',' + (orig[i + 2] >> 3);
    const e = counts.get(key) || { n: 0, r: 0, g: 0, b: 0 };
    e.n++; e.r += orig[i]; e.g += orig[i + 1]; e.b += orig[i + 2];
    counts.set(key, e);
  };
  for (let x = 0; x < w; x++) { consider(x, 0); consider(x, h - 1); }
  for (let y = 0; y < h; y++) { consider(0, y); consider(w - 1, y); }
  let best = null;
  for (const e of counts.values()) if (!best || e.n > best.n) best = e;
  const bg = best ? [best.r / best.n, best.g / best.n, best.b / best.n] : null;
  const tol2 = opts.tol * opts.tol;
  const isBg = (pi) => {
    const i = pi * 4;
    if (orig[i + 3] < 8) return true;
    if (!bg) return false;
    const dr = orig[i] - bg[0], dg = orig[i + 1] - bg[1], db = orig[i + 2] - bg[2];
    return dr * dr + dg * dg + db * db <= tol2;
  };
  const visited = new Uint8Array(w * h);
  const st = [];
  const seed = (x, y) => { const pi = y * w + x; if (!visited[pi]) { visited[pi] = 1; if (isBg(pi)) st.push(pi); } };
  for (let x = 0; x < w; x++) { seed(x, 0); seed(x, h - 1); }
  for (let y = 0; y < h; y++) { seed(0, y); seed(w - 1, y); }
  while (st.length) {
    const pi = st.pop(), i = pi * 4;
    out[i] = 0; out[i + 1] = 0; out[i + 2] = 0; out[i + 3] = 0;
    const x = pi % w, y = (pi / w) | 0;
    const nb = [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]];
    for (const [nx, ny] of nb) {
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      const npi = ny * w + nx;
      if (visited[npi]) continue;
      visited[npi] = 1;
      if (isBg(npi)) st.push(npi);
    }
  }
  return out;
}

// ---- surgical frame-line removal: clear isolated near-full rows/cols whose
// immediate neighbors are nearly empty (a floating line can't be sprite body). ----
function removeFrameLines(w, h, out) {
  const rowOp = y => { let o = 0; for (let x = 0; x < w; x++) if (out[(y * w + x) * 4 + 3] > 40) o++; return o; };
  const colOp = x => { let o = 0; for (let y = 0; y < h; y++) if (out[(y * w + x) * 4 + 3] > 40) o++; return o; };
  const clearRow = y => { for (let x = 0; x < w; x++) { const i = (y * w + x) * 4; out[i] = out[i+1] = out[i+2] = out[i+3] = 0; } };
  const clearCol = x => { for (let y = 0; y < h; y++) { const i = (y * w + x) * 4; out[i] = out[i+1] = out[i+2] = out[i+3] = 0; } };
  for (let y = 1; y < h - 1; y++) if (rowOp(y) > 0.6 * w && rowOp(y - 1) < 0.15 * w && rowOp(y + 1) < 0.15 * w) clearRow(y);
  for (let x = 1; x < w - 1; x++) if (colOp(x) > 0.6 * h && colOp(x - 1) < 0.15 * h && colOp(x + 1) < 0.15 * h) clearCol(x);
  return out;
}

// ---- run ----
if (!fs.existsSync(DST)) fs.mkdirSync(DST, { recursive: true });
// copy everything first (clean sprites + trainers pass through untouched)
for (const f of fs.readdirSync(SRC)) {
  if (f.endsWith('.png')) fs.copyFileSync(path.join(SRC, f), path.join(DST, f));
}

const SPECIES = ['blastoise', 'charizard', 'dragonair', 'gastly', 'kadabra', 'magikarp', 'magneton', 'mewtwo'];
const targets = [];
for (const s of SPECIES) { targets.push(s + '_front', s + '_back'); }

for (const name of targets) {
  const src = path.join(SRC, name + '.png');
  if (!fs.existsSync(src)) { console.log('SKIP (missing)', name); continue; }
  const { w, h, out } = decode(src);
  let cleaned = cleanBg(w, h, out, { tol: 60 }); // RGB distance from estimated bg color
  cleaned = removeFrameLines(w, h, cleaned);       // strip leftover dex-frame lines
  let op = 0; for (let i = 3; i < cleaned.length; i += 4) if (cleaned[i] > 10) op++;
  fs.writeFileSync(path.join(DST, name + '.png'), encode(w, h, cleaned));
  console.log(name.padEnd(18), 'opaque after:', Math.round(op / (w * h) * 100) + '%');
}
console.log('done -> v12');

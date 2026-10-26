// Bağımlılıksız QR üretici (bayt kipi, hata düzeltme L, sürüm 1–5 ≈ 106 bayta kadar). Biletin giriş kodu için yeterli.
// qrSvg(metin, {piksel}) -> SVG dizgesi (koyu modüller currentColor; kâğıt zemini üzerinde okunur).
const VERI = [19, 34, 55, 80, 108];      // L düzeyi veri kod sözcüğü sayısı (v1..v5)
const EC = [7, 10, 15, 20, 26];           // L düzeyi hata düzeltme sözcüğü sayısı
const HIZA = [[], [6, 18], [6, 22], [6, 26], [6, 30]];

// --- GF(256) / Reed-Solomon ---
const EXP = new Uint8Array(512), LOG = new Uint8Array(256);
for (let i = 0, x = 1; i < 255; i++) { EXP[i] = x; LOG[x] = i; x <<= 1; if (x & 256) x ^= 0x11d; }
for (let i = 255; i < 512; i++) EXP[i] = EXP[i - 255];
const carp = (a, b) => (a && b ? EXP[LOG[a] + LOG[b]] : 0);
function rsKalan(veri, n) {
  let g = [1];
  for (let i = 0; i < n; i++) { const y = new Array(g.length + 1).fill(0); g.forEach((c, j) => { y[j] ^= c; y[j + 1] ^= carp(c, EXP[i]); }); g = y; }
  const r = new Array(n).fill(0);
  for (const b of veri) {
    const f = b ^ r.shift(); r.push(0);
    for (let i = 0; i < n; i++) r[i] ^= carp(g[i + 1], f);
  }
  return r;
}

export function qrMatris(metin) {
  const bayt = [...new TextEncoder().encode(String(metin))];
  let v = 0;
  while (v < 5 && bayt.length + 2 > VERI[v]) v++;
  if (bayt.length + 2 > VERI[4]) throw new Error('QR için metin çok uzun');
  const ver = v + 1, n = 17 + 4 * ver;
  // bit akışı
  const bits = [];
  const yaz = (deger, adet) => { for (let i = adet - 1; i >= 0; i--) bits.push((deger >>> i) & 1); };
  yaz(4, 4); yaz(bayt.length, 8); bayt.forEach((b) => yaz(b, 8));
  const kap = VERI[v] * 8;
  yaz(0, Math.min(4, kap - bits.length));
  while (bits.length % 8) bits.push(0);
  for (let p = 0xec; bits.length < kap; p ^= 0xec ^ 0x11) yaz(p, 8);
  const kod = [];
  for (let i = 0; i < bits.length; i += 8) kod.push(parseInt(bits.slice(i, i + 8).join(''), 2));
  const tum = kod.concat(rsKalan(kod, EC[v]));

  const mod = Array.from({ length: n }, () => new Array(n).fill(false));
  const fn = Array.from({ length: n }, () => new Array(n).fill(false));
  const koy = (x, y, d) => { mod[y][x] = d; fn[y][x] = true; };
  // bulucu desenler
  const bulucu = (cx, cy) => {
    for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++) {
      const x = cx + dx, y = cy + dy; if (x < 0 || y < 0 || x >= n || y >= n) continue;
      const d = Math.max(Math.abs(dx), Math.abs(dy));
      koy(x, y, d !== 2 && d !== 4);
    }
  };
  bulucu(3, 3); bulucu(n - 4, 3); bulucu(3, n - 4);
  for (let i = 0; i < n; i++) { if (!fn[6][i]) koy(i, 6, i % 2 === 0); if (!fn[i][6]) koy(6, i, i % 2 === 0); }
  const h = HIZA[v];
  for (const cy of h) for (const cx of h) {
    if ((cx === 6 && cy === 6) || (cx === 6 && cy === n - 7) || (cx === n - 7 && cy === 6)) continue;
    for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) koy(cx + dx, cy + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1);
  }
  // biçim bölgesi (şimdilik ayır) + koyu modül
  for (let i = 0; i < 9; i++) { fn[8][i] = true; fn[i][8] = true; }
  for (let i = 0; i < 8; i++) { fn[8][n - 1 - i] = true; fn[n - 1 - i][8] = true; }
  koy(8, n - 8, true);
  // veri yerleştirme (zikzak)
  const dizi = [];
  tum.forEach((b) => { for (let i = 7; i >= 0; i--) dizi.push((b >> i) & 1); });
  let k = 0;
  for (let sag = n - 1; sag >= 1; sag -= 2) {
    if (sag === 6) sag = 5;
    for (let j = 0; j < n; j++) for (let c = 0; c < 2; c++) {
      const x = sag - c, yukari = ((sag + 1) & 2) === 0, y = yukari ? n - 1 - j : j;
      if (!fn[y][x] && k < dizi.length) mod[y][x] = dizi[k++] === 1;
    }
  }
  const maskeler = [
    (x, y) => (x + y) % 2 === 0, (x, y) => y % 2 === 0, (x, y) => x % 3 === 0, (x, y) => (x + y) % 3 === 0,
    (x, y) => (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0, (x, y) => ((x * y) % 2) + ((x * y) % 3) === 0,
    (x, y) => (((x * y) % 2) + ((x * y) % 3)) % 2 === 0, (x, y) => (((x + y) % 2) + ((x * y) % 3)) % 2 === 0,
  ];
  const bicim = (m) => { // hata düzeltme L = 01
    const d = (1 << 3) | m; let r = d;
    for (let i = 0; i < 10; i++) r = (r << 1) ^ ((r >>> 9) * 0x537);
    return ((d << 10) | r) ^ 0x5412;
  };
  const uygula = (m) => {
    const o = mod.map((s) => s.slice());
    for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) if (!fn[y][x] && maskeler[m](x, y)) o[y][x] = !o[y][x];
    const b = bicim(m), bit = (i) => ((b >>> i) & 1) === 1;
    for (let i = 0; i <= 5; i++) o[i][8] = bit(i);
    o[7][8] = bit(6); o[8][8] = bit(7); o[8][7] = bit(8);
    for (let i = 9; i < 15; i++) o[8][14 - i] = bit(i);
    for (let i = 0; i < 8; i++) o[8][n - 1 - i] = bit(i);
    for (let i = 8; i < 15; i++) o[n - 15 + i][8] = bit(i);
    o[n - 8][8] = true;
    return o;
  };
  const ceza = (o) => {
    let s = 0;
    for (let t = 0; t < 2; t++) {
      for (let a = 0; a < n; a++) {
        let say = 1, sonraki = t ? o[0][a] : o[a][0];
        const hat = [];
        for (let b = 0; b < n; b++) {
          const c = t ? o[b][a] : o[a][b]; hat.push(c);
          if (b) { if (c === sonraki) { say++; if (say === 5) s += 3; else if (say > 5) s++; } else { sonraki = c; say = 1; } }
        }
        const dz = hat.map((x) => (x ? 1 : 0)).join('');
        s += 40 * (dz.match(/(?=10111010000|00001011101)/g) || []).length;
      }
    }
    for (let y = 0; y < n - 1; y++) for (let x = 0; x < n - 1; x++) { const c = o[y][x]; if (c === o[y][x + 1] && c === o[y + 1][x] && c === o[y + 1][x + 1]) s += 3; }
    let koyu = 0; o.forEach((r) => r.forEach((c) => { if (c) koyu++; }));
    s += Math.floor(Math.abs((koyu * 20) / (n * n) - 10)) * 10;
    return s;
  };
  let en = null, enCeza = Infinity;
  for (let m = 0; m < 8; m++) { const o = uygula(m); const c = ceza(o); if (c < enCeza) { enCeza = c; en = o; } }
  return en;
}

export function qrSvg(metin, { piksel = 168, etiket = 'Giriş QR kodu' } = {}) {
  let m;
  try { m = qrMatris(metin); } catch { return ''; }
  const n = m.length, k = 4; // sessiz bölge
  let d = '';
  m.forEach((s, y) => { let x = 0; while (x < n) { if (s[x]) { let e = x; while (e < n && s[e]) e++; d += `M${x + k} ${y + k}h${e - x}v1h-${e - x}z`; x = e; } else x++; } });
  return `<svg class="qr" role="img" aria-label="${etiket}" width="${piksel}" height="${piksel}" viewBox="0 0 ${n + 2 * k} ${n + 2 * k}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#fff"/><path d="${d}" fill="#000"/></svg>`;
}

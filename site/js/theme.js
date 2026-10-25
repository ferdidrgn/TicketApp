// Tema motoru: mod (sistem/gündüz/gece) × palet (şarap / Material / özel renk).
// Mobil uygulamadaki 5 tema + özel vurgu rengiyle aynı mantık. Seçim localStorage'da.
const KEY = 'tiyatrol.tema.v1';
const PRESETS = [
  { id: 'sarap', ad: 'Şarap (TiyatRol)', renk: '#c50337' },
  { id: 'okyanus', ad: 'Okyanus', renk: '#1e6fd9' },
  { id: 'orman', ad: 'Orman', renk: '#2e8b57' },
  { id: 'mor', ad: 'Menekşe', renk: '#7e4bd8' },
  { id: 'kehribar', ad: 'Kehribar', renk: '#d98a00' },
  { id: 'doga', ad: 'Doğa (Material)', renk: '#4f8a5b', tonlu: true },
  { id: 'ahenk', ad: 'Ahenk (Material)', renk: '#8a63c7', tonlu: true },
];
const DEFAULTS = { mod: 'sistem', palet: 'sarap', ozel: '#c50337', material: false };

export const temaSecenekleri = PRESETS;
export function temaOku() {
  try { return { ...DEFAULTS, ...JSON.parse(localStorage.getItem(KEY) || '{}') }; }
  catch { return { ...DEFAULTS }; }
}
export function temaYaz(patch) {
  const s = { ...temaOku(), ...patch };
  try { localStorage.setItem(KEY, JSON.stringify(s)); } catch {}
  temaUygula(s);
  return s;
}

function hexToHsl(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex.trim());
  if (!m) return [350, 95, 40];
  const n = parseInt(m[1], 16);
  let r = (n >> 16) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn;
  let h = 0, s = 0; const l = (mx + mn) / 2;
  if (d) {
    s = d / (1 - Math.abs(2 * l - 1));
    if (mx === r) h = ((g - b) / d) % 6; else if (mx === g) h = (b - r) / d + 2; else h = (r - g) / d + 4;
    h = (h * 60 + 360) % 360;
  }
  return [h, s * 100, l * 100];
}
const hsl = (h, s, l) => `hsl(${h.toFixed(0)} ${Math.max(0, Math.min(100, s)).toFixed(0)}% ${Math.max(0, Math.min(100, l)).toFixed(0)}%)`;
function luminance(hex) {
  const n = parseInt(hex.replace('#', ''), 16);
  const f = (c) => { c /= 255; return c <= .03928 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4; };
  return .2126 * f(n >> 16) + .7152 * f((n >> 8) & 255) + .0722 * f(n & 255);
}

function seedOf(s) {
  if (s.palet === 'ozel') return s.ozel;
  return (PRESETS.find((p) => p.id === s.palet) || PRESETS[0]).renk;
}

export function temaUygula(s = temaOku()) {
  const dark = s.mod === 'gece' || (s.mod === 'sistem' && matchMedia('(prefers-color-scheme: dark)').matches);
  const seed = seedOf(s);
  const [h, sat] = hexToHsl(seed);
  const root = document.documentElement.style;
  const set = (k, v) => root.setProperty(k, v);
  // Vurgu: koyu zeminde biraz aydınlatılır, kontrast korunur.
  const accent = dark && hexToHsl(seed)[2] < 45 ? hsl(h, sat, hexToHsl(seed)[2] + 12) : seed;
  const accentHex = dark && hexToHsl(seed)[2] < 45 ? null : seed;
  set('--accent', accent);
  const probe = accentHex || seed;
  set('--accent-ink', luminance(probe) > .42 ? '#1a1410' : '#ffffff');
  const tonlu = !!(PRESETS.find((p) => p.id === s.palet) || {}).tonlu;
  const isDefault = s.palet === 'sarap';
  if (dark && tonlu) {
    set('--bg', hsl(h, 32, 8)); set('--surface', hsl(h, 30, 13)); set('--surface-2', hsl(h, 28, 20));
    set('--ink', hsl(h, 25, 94)); set('--ink-2', hsl(h, 16, 78)); set('--ink-3', hsl(h, 11, 62));
  } else if (tonlu) {
    set('--bg', hsl(h, 42, 96)); set('--surface', hsl(h, 45, 99)); set('--surface-2', hsl(h, 50, 91));
    set('--ink', hsl(h, 35, 10)); set('--ink-2', hsl(h, 18, 30)); set('--ink-3', hsl(h, 12, 46));
  } else if (dark) {
    if (isDefault) {
      set('--bg', '#0a0509'); set('--surface', '#160a10'); set('--surface-2', '#2b0f18');
      set('--ink', '#f2ecd9'); set('--ink-2', '#c9bba5'); set('--ink-3', '#9c8f79');
    } else {
      set('--bg', hsl(h, Math.min(sat, 30), 6)); set('--surface', hsl(h, Math.min(sat, 28), 10));
      set('--surface-2', hsl(h, Math.min(sat, 26), 16));
      set('--ink', hsl(h, 20, 93)); set('--ink-2', hsl(h, 14, 76)); set('--ink-3', hsl(h, 10, 60));
    }
  } else if (isDefault) {
    set('--bg', '#f8fafc'); set('--surface', '#ffffff'); set('--surface-2', '#fdeeee');
    set('--ink', '#14100f'); set('--ink-2', '#4a4340'); set('--ink-3', '#7a706b');
  } else {
    set('--bg', hsl(h, 30, 97)); set('--surface', '#ffffff'); set('--surface-2', hsl(h, 55, 94));
    set('--ink', hsl(h, 30, 10)); set('--ink-2', hsl(h, 14, 30)); set('--ink-3', hsl(h, 10, 46));
  }
  document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
  document.documentElement.dataset.mode = dark ? 'dark' : 'light';
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.content = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim();
}

temaUygula();
matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => temaUygula());

// Tema çekirdeği — KLASİK betik (modül değil): <head> içinde yüklenir, sayfa çizilmeden temayı uygular
// (böylece iskeletler/shimmer ilk karede de seçili temanın renginde görünür, siyah-kara flaş olmaz).
// js/theme.js bu çekirdeği modül olarak dışa aktarır.
(function () {
  var KEY = 'tiyatrol.tema.v1';
  var PRESETS = [
    { id: 'sarap', ad: 'Şarap (TiyatRol)', renk: '#c50337' },
    { id: 'okyanus', ad: 'Okyanus', renk: '#1e6fd9' },
    { id: 'orman', ad: 'Orman', renk: '#2e8b57' },
    { id: 'mor', ad: 'Menekşe', renk: '#7e4bd8' },
    { id: 'kehribar', ad: 'Kehribar', renk: '#d98a00' },
    { id: 'doga', ad: 'Doğa (Material)', renk: '#4f8a5b', tonlu: true },
    { id: 'ahenk', ad: 'Ahenk (Material)', renk: '#8a63c7', tonlu: true },
  ];
  var DEFAULTS = { mod: 'sistem', palet: 'sarap', ozel: '#c50337', material: false };

  function oku() {
    try { return Object.assign({}, DEFAULTS, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { return Object.assign({}, DEFAULTS); }
  }
  function hexToHsl(hex) {
    var m = /^#?([0-9a-f]{6})$/i.exec(String(hex).trim());
    if (!m) return [350, 95, 40];
    var n = parseInt(m[1], 16), r = (n >> 16) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn, h = 0, s = 0, l = (mx + mn) / 2;
    if (d) {
      s = d / (1 - Math.abs(2 * l - 1));
      if (mx === r) h = ((g - b) / d) % 6; else if (mx === g) h = (b - r) / d + 2; else h = (r - g) / d + 4;
      h = (h * 60 + 360) % 360;
    }
    return [h, s * 100, l * 100];
  }
  function hsl(h, s, l) { return 'hsl(' + h.toFixed(0) + ' ' + Math.max(0, Math.min(100, s)).toFixed(0) + '% ' + Math.max(0, Math.min(100, l)).toFixed(0) + '%)'; }
  function luminance(hex) {
    var n = parseInt(String(hex).replace('#', ''), 16);
    function f(c) { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
    return 0.2126 * f(n >> 16) + 0.7152 * f((n >> 8) & 255) + 0.0722 * f(n & 255);
  }
  function seedOf(s) {
    if (s.palet === 'ozel') return s.ozel;
    for (var i = 0; i < PRESETS.length; i++) if (PRESETS[i].id === s.palet) return PRESETS[i].renk;
    return PRESETS[0].renk;
  }
  function karanlikMi(s) {
    return s.mod === 'gece' || (s.mod === 'sistem' && matchMedia('(prefers-color-scheme: dark)').matches);
  }
  // Seçime göre tüm değişkenleri hesaplar (uygulamadan): önizleme kartları da bunu kullanır.
  function hesapla(s) {
    var dark = karanlikMi(s), seed = seedOf(s), hh = hexToHsl(seed), h = hh[0], sat = hh[1], v = {};
    var acik = dark && hh[2] < 45;
    v['--accent'] = acik ? hsl(h, sat, hh[2] + 12) : seed;
    v['--accent-ink'] = luminance(seed) > 0.42 ? '#1a1410' : '#ffffff';
    var tonlu = false, p;
    for (var i = 0; i < PRESETS.length; i++) if (PRESETS[i].id === s.palet) { p = PRESETS[i]; tonlu = !!p.tonlu; }
    var def = s.palet === 'sarap';
    if (dark && tonlu) { v['--bg'] = hsl(h, 32, 8); v['--surface'] = hsl(h, 30, 13); v['--surface-2'] = hsl(h, 28, 20); v['--ink'] = hsl(h, 25, 94); v['--ink-2'] = hsl(h, 16, 78); v['--ink-3'] = hsl(h, 11, 62); }
    else if (tonlu) { v['--bg'] = hsl(h, 42, 96); v['--surface'] = hsl(h, 45, 99); v['--surface-2'] = hsl(h, 50, 91); v['--ink'] = hsl(h, 35, 10); v['--ink-2'] = hsl(h, 18, 30); v['--ink-3'] = hsl(h, 12, 46); }
    else if (dark) {
      if (def) { v['--bg'] = '#0a0509'; v['--surface'] = '#160a10'; v['--surface-2'] = '#2b0f18'; v['--ink'] = '#f2ecd9'; v['--ink-2'] = '#c9bba5'; v['--ink-3'] = '#9c8f79'; }
      else { v['--bg'] = hsl(h, Math.min(sat, 30), 6); v['--surface'] = hsl(h, Math.min(sat, 28), 10); v['--surface-2'] = hsl(h, Math.min(sat, 26), 16); v['--ink'] = hsl(h, 20, 93); v['--ink-2'] = hsl(h, 14, 76); v['--ink-3'] = hsl(h, 10, 60); }
    } else if (def) { v['--bg'] = '#f8fafc'; v['--surface'] = '#ffffff'; v['--surface-2'] = '#fdeeee'; v['--ink'] = '#14100f'; v['--ink-2'] = '#4a4340'; v['--ink-3'] = '#7a706b'; }
    else { v['--bg'] = hsl(h, 30, 97); v['--surface'] = '#ffffff'; v['--surface-2'] = hsl(h, 55, 94); v['--ink'] = hsl(h, 30, 10); v['--ink-2'] = hsl(h, 14, 30); v['--ink-3'] = hsl(h, 10, 46); }
    v.__dark = dark;
    return v;
  }
  function uygula(s) {
    s = s || oku();
    var v = hesapla(s), st = document.documentElement.style;
    for (var k in v) if (k.indexOf('--') === 0) st.setProperty(k, v[k]);
    st.colorScheme = v.__dark ? 'dark' : 'light';
    document.documentElement.dataset.mode = v.__dark ? 'dark' : 'light';
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = v['--bg'];
  }
  function yaz(patch) {
    var s = Object.assign({}, oku(), patch);
    try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) {}
    uygula(s);
    return s;
  }
  window.TiyatTema = { PRESETS: PRESETS, oku: oku, yaz: yaz, uygula: uygula, hesapla: hesapla };
  uygula();
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () { uygula(); });
})();

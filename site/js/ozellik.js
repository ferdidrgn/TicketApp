// Genel özellikler: erişilebilirlik ayarları, çerez bildirimi, klavye kısayolları, PWA kurulumu,
// başa dön, paylaş menüsü. Her sayfada ui.js tarafından yüklenir.
const KEY = 'tiyatrol.erisim.v1';
const VARS = { yazi: 100, kontrast: false, sade: false, okuma: false };
export const erisimOku = () => { try { return { ...VARS, ...JSON.parse(localStorage.getItem(KEY) || '{}') }; } catch { return { ...VARS }; } };
export function erisimUygula(s = erisimOku()) {
  const k = document.documentElement;
  k.style.fontSize = `${s.yazi}%`;
  k.classList.toggle('kontrast', !!s.kontrast);
  k.classList.toggle('az-hareket', !!s.sade || matchMedia('(prefers-reduced-motion: reduce)').matches);
  k.classList.toggle('okuma', !!s.okuma);
}
export function erisimYaz(p) { const s = { ...erisimOku(), ...p }; try { localStorage.setItem(KEY, JSON.stringify(s)); } catch {} erisimUygula(s); return s; }
erisimUygula();

// ---------- Çerez / gizlilik bildirimi ----------
(() => {
  let tercih = null; try { tercih = localStorage.getItem('tiyatrol.cerez'); } catch {}
  if (tercih) return;
  const b = document.createElement('div'); b.className = 'cerez'; b.setAttribute('role', 'dialog'); b.setAttribute('aria-label', 'Çerez bildirimi');
  b.innerHTML = '<p><b>Çerezler ve saklama.</b> Sitemiz tema, il ve favori tercihlerini yalnızca tarayıcında saklar; seni izlemez. Reklam ve istatistik çerezleri ileride eklenirse önce izin isteriz. <a href="/gizlilik">Gizlilik politikası</a></p><div><button class="btn btn-primary btn-sm" data-c="evet">Tamam</button><button class="btn btn-ghost btn-sm" data-c="gerekli">Yalnızca gerekli</button></div>';
  setTimeout(() => document.body.append(b), 1200);
  b.addEventListener('click', (e) => { const c = e.target.closest('[data-c]'); if (!c) return; try { localStorage.setItem('tiyatrol.cerez', c.dataset.c); } catch {} b.classList.add('git'); setTimeout(() => b.remove(), 400); });
})();

// ---------- Başa dön (perde ipi: püskülü çek, perde açılsın) ----------
(() => {
  const b = document.createElement('button'); b.className = 'basa'; b.type = 'button'; b.setAttribute('aria-label', 'Sayfanın başına dön'); b.title = 'Perdeyi aç — başa dön';
  b.innerHTML = '<svg viewBox="0 0 64 92" width="100%" height="100%" aria-hidden="true">'
    + '<rect x="2" y="2" width="60" height="7" rx="3.5" class="b-rod"/>'
    + '<path class="b-perde" d="M5 9h54v6c0 16-7 26-14 31-3 2-5 5-5 9H24c0-4-2-7-5-9C12 41 5 31 5 15Z"/>'
    + '<path class="b-kat" d="M17 9v37M27 9v46M37 9v46M47 9v37"/>'
    + '<g class="b-ip"><path class="b-ipcizgi" d="M32 55v14"/><rect x="28.5" y="68" width="7" height="6" rx="2" class="b-altin"/>'
    + '<path class="b-altin" d="M26 74h12l3 14H23Z"/><path class="b-puskul" d="M27 80v8M32 80v8M37 80v8"/></g></svg>';
  document.body.append(b);
  const g = () => b.classList.toggle('on', scrollY > 900);
  addEventListener('scroll', () => requestAnimationFrame(g), { passive: true });
  b.addEventListener('click', () => {
    const az = matchMedia('(prefers-reduced-motion: reduce)').matches;
    b.classList.remove('cek'); void b.offsetWidth; if (!az) b.classList.add('cek');
    setTimeout(() => scrollTo({ top: 0, behavior: az ? 'auto' : 'smooth' }), az ? 0 : 180);
  });
})();

// ---------- Klavye kısayolları ----------
const SK = [['/', 'Aramayı aç'], ['g h', 'Vitrine git'], ['g k', 'Tüm oyunlar'], ['g m', 'Harita'], ['g t', 'Takvim'], ['g f', 'Favorilerim'], ['?', 'Bu pencereyi aç'], ['Esc', 'Pencereyi kapat']];
let onceki = '', zaman;
addEventListener('keydown', (e) => {
  if (/input|textarea|select/i.test(document.activeElement?.tagName || '') || e.ctrlKey || e.metaKey || e.altKey) return;
  if (e.key === '?') { e.preventDefault(); const m = document.createElement('div'); m.className = 'ks-bg'; m.innerHTML = `<div class="ks"><header><b>Klavye kısayolları</b><button class="btn btn-ghost btn-sm" data-k>Kapat</button></header><dl>${SK.map(([k, a]) => `<dt>${k.split(' ').map((x) => `<kbd>${x}</kbd>`).join(' ')}</dt><dd>${a}</dd>`).join('')}</dl></div>`; document.body.append(m); m.addEventListener('click', (ev) => { if (ev.target === m || ev.target.closest('[data-k]')) m.remove(); }); return; }
  if (e.key === 'Escape') document.querySelector('.ks-bg')?.remove();
  clearTimeout(zaman); zaman = setTimeout(() => { onceki = ''; }, 900);
  if (onceki === 'g') { const y = { h: '/vitrin', k: '/kesfet', m: '/harita', t: '/takvim', f: '/favoriler' }[e.key]; onceki = ''; if (y) location.href = y; return; }
  if (e.key === 'g') onceki = 'g';
});

// ---------- PWA: servis çalışanı + ana ekrana ekle ----------
if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
  addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
}
let kurulum = null;
addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); kurulum = e; document.dispatchEvent(new Event('pwa-hazir')); });
export const pwaKurulabilir = () => !!kurulum;
export async function pwaKur() { if (!kurulum) return false; kurulum.prompt(); const r = await kurulum.userChoice; kurulum = null; return r.outcome === 'accepted'; }

// ---------- Paylaş menüsü ----------
export function paylasMenusu(btn, baslik, metin = '') {
  document.querySelector('.pm-menu')?.remove();
  const url = location.href.split('#')[0], q = encodeURIComponent;
  const m = document.createElement('div'); m.className = 'pm-menu';
  m.innerHTML = `<a target="_blank" rel="noopener" href="https://wa.me/?text=${q(baslik + ' ' + url)}">WhatsApp</a><a target="_blank" rel="noopener" href="https://twitter.com/intent/tweet?text=${q(baslik)}&url=${q(url)}">X (Twitter)</a><a target="_blank" rel="noopener" href="https://www.facebook.com/sharer/sharer.php?u=${q(url)}">Facebook</a><a href="mailto:?subject=${q(baslik)}&body=${q(metin + '\n' + url)}">E-posta</a><button data-k>Bağlantıyı kopyala</button>${navigator.share ? '<button data-s>Diğer uygulamalar…</button>' : ''}`;
  const r = btn.getBoundingClientRect();
  m.style.left = `${Math.min(r.left + scrollX, innerWidth - 230)}px`; m.style.top = `${r.bottom + scrollY + 6}px`;
  document.body.append(m);
  m.addEventListener('click', async (e) => {
    if (e.target.closest('[data-k]')) { try { await navigator.clipboard.writeText(url); } catch {} import('./fav.js').then((f) => f.bildir('Bağlantı kopyalandı')); }
    if (e.target.closest('[data-s]')) { try { await navigator.share({ title: baslik, text: metin, url }); } catch {} }
    m.remove();
  });
  setTimeout(() => document.addEventListener('click', function k(ev) { if (!m.contains(ev.target)) { m.remove(); document.removeEventListener('click', k); } }), 0);
}

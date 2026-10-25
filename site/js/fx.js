// Sahne efektleri: perde açılışı, ışık imleci, giriş animasyonları, eğilen afişler,
// kaydırmayla yanan söz, bilet koçanı yırtma, kayan program şeridi.
// Kurallar (Emil/Impeccable): yalnızca transform+opacity, ease-out ≤ 600 ms, basınca .97,
// prefers-reduced-motion'da hareket yok ama içerik yerinde. JS çalışmazsa içerik gizli kalmaz.
const azHareket = matchMedia('(prefers-reduced-motion: reduce)').matches;
const dokunmatik = !matchMedia('(hover: hover)').matches;
const kok = document.documentElement;
kok.classList.add('js');
if (azHareket) kok.classList.add('az-hareket');

// ---------- Giriş animasyonları (parça parça) ----------
const HEDEFLER = '.sec-head, .cats .cat, .rail > .card, .top10 .t10, .day, .ag-row, .venue, .person, .guide, .sess, .budget-box, .mood, .gal img, .grid > .card, .block > h2, .story, .info-row, .band';
const io = 'IntersectionObserver' in window ? new IntersectionObserver((ent) => {
  for (const e of ent) if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
}, { rootMargin: '0px 0px -8% 0px', threshold: 0.05 }) : null;

export function canlandir(kok2 = document) {
  if (azHareket || !io || document.hidden) return; // arka plandaki sekmede animasyon çalışmaz; içerik gizli kalmasın
  kok2.querySelectorAll(HEDEFLER).forEach((el) => {
    if (el.dataset.rv) return;
    el.dataset.rv = '1';
    const kardes = [...el.parentElement.children].filter((c) => c.matches(HEDEFLER));
    el.style.setProperty('--i', Math.min(kardes.indexOf(el), 8));
    const r = el.getBoundingClientRect();
    if (r.top < innerHeight * 0.92 && r.bottom > 0) { el.classList.add('rv'); requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add('in'))); }
    else { el.classList.add('rv'); io.observe(el); }
  });
}
const ana = document.getElementById('main') || document.body;
let t;
new MutationObserver(() => { clearTimeout(t); t = setTimeout(() => { canlandir(); sozleriKur(); }, 40); }).observe(ana, { childList: true, subtree: true });
canlandir();
addEventListener('visibilitychange', () => { if (!document.hidden) canlandir(); });

// ---------- Eğilen afişler ----------
if (!dokunmatik && !azHareket) {
  let aktif = null;
  document.addEventListener('pointermove', (e) => {
    const pic = e.target.closest?.('.card .pic, .hero-art .poster');
    if (aktif && aktif !== pic) { aktif.style.transform = ''; aktif = null; }
    if (!pic) return;
    aktif = pic;
    const r = pic.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width - 0.5, y = (e.clientY - r.top) / r.height - 0.5;
    pic.style.transform = `perspective(700px) rotateY(${(x * 9).toFixed(2)}deg) rotateX(${(-y * 9).toFixed(2)}deg) translateY(-4px)`;
  }, { passive: true });
  document.addEventListener('pointerleave', () => { if (aktif) { aktif.style.transform = ''; aktif = null; } }, true);
}

// ---------- Işık imleci (hero) ----------
export function isikKur(el) {
  if (!el || dokunmatik || azHareket) return;
  let raf = 0, mx = 0, my = 0;
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect(); mx = e.clientX - r.left; my = e.clientY - r.top;
    if (!raf) raf = requestAnimationFrame(() => { raf = 0; el.style.setProperty('--mx', mx + 'px'); el.style.setProperty('--my', my + 'px'); el.classList.add('isik'); });
  }, { passive: true });
  el.addEventListener('pointerleave', () => el.classList.remove('isik'));
}

// ---------- Perde açılışı (oturum başına bir kez, ana sayfada) ----------
export function perdeAc() {
  let goruldu = false;
  try { goruldu = sessionStorage.getItem('perde') === '1'; sessionStorage.setItem('perde', '1'); } catch {}
  if (goruldu || azHareket) return;
  const p = document.createElement('div');
  p.className = 'perde'; p.setAttribute('aria-hidden', 'true');
  p.innerHTML = '<i class="sol"></i><i class="sag"></i><b>TİYATROL</b>';
  document.body.append(p);
  const bitir = () => { p.classList.add('acik'); setTimeout(() => p.remove(), 1500); };
  setTimeout(bitir, 650);
  p.addEventListener('click', bitir);
}

// ---------- Kaydırmayla yanan söz ----------
let sozAkis = null;
function sozleriKur() {
  document.querySelectorAll('.soz:not([data-k])').forEach((el) => {
    el.dataset.k = '1';
    const kel = el.textContent.trim().split(/\s+/);
    el.innerHTML = kel.map((w) => `<span>${w}</span>`).join(' ');
    if (azHareket) { el.querySelectorAll('span').forEach((s) => { s.style.opacity = 1; }); return; }
    const sp = [...el.querySelectorAll('span')];
    const guncel = () => {
      const r = el.getBoundingClientRect();
      const p = Math.min(1, Math.max(0, (innerHeight * 0.85 - r.top) / (innerHeight * 0.55 + r.height * 0.4)));
      const n = p * sp.length;
      sp.forEach((s, i) => { s.style.opacity = i < n ? 1 : 0.16; });
    };
    guncel();
    sozAkis = () => document.querySelectorAll('.soz[data-k]').forEach(() => 0);
    addEventListener('scroll', () => requestAnimationFrame(guncel), { passive: true });
  });
}
sozleriKur();

// ---------- Bilet koçanı yırtma ----------
document.addEventListener('click', (e) => {
  const b = e.target.closest('.ticket .btn-primary');
  if (!b) return;
  const bil = b.closest('.ticket');
  bil.classList.add('yirtildi');
  setTimeout(() => bil.classList.remove('yirtildi'), 1400);
});

// ---------- Basınca küçülme (dokunma geri bildirimi) ----------
document.addEventListener('pointerdown', (e) => {
  const c = e.target.closest('.card');
  if (c) c.classList.add('basili');
}, { passive: true });
addEventListener('pointerup', () => document.querySelectorAll('.card.basili').forEach((c) => c.classList.remove('basili')), { passive: true });

// ---------- Üst yükleme çubuğu ----------
(() => {
  const b = document.createElement('div'); b.id = 'yuk'; document.body.append(b);
  requestAnimationFrame(() => { b.style.transform = 'scaleX(.72)'; });
  const bitir = () => { b.style.transform = 'scaleX(1)'; setTimeout(() => { b.style.opacity = '0'; setTimeout(() => b.remove(), 400); }, 180); };
  document.addEventListener('veri-hazir', bitir, { once: true });
  setTimeout(bitir, 8000);
})();

// ---------- Bağlantıların üstüne gelince sayfayı önceden yükle ----------
const onYuklenen = new Set();
document.addEventListener('pointerover', (e) => {
  const a = e.target.closest?.('a[href^="/"]'); if (!a || onYuklenen.has(a.href)) return;
  if (a.target === '_blank' || /#/.test(a.getAttribute('href'))) return;
  onYuklenen.add(a.href);
  const l = document.createElement('link'); l.rel = 'prefetch'; l.href = a.href; document.head.append(l);
}, { passive: true });

// Detay sayfaları için ortak parçalar: "program ve bilet" iskeleti, bölüm çubuğu
// (scroll-spy), galeri/lightbox, takvime ekle menüsü, harita, SEO başlıkları.
import '../js/theme.js';
import { $, $$, esc, tarihUzun, saat, kisalt } from './util.js';
import { hataKutusu } from './ui.js';

export function baslikYaz(baslik, aciklama = '', gorsel = '') {
  document.title = `${baslik} — TiyatRol`;
  const set = (sel, val, attr = 'content') => { const el = $(sel); if (el && val) el.setAttribute(attr, val); };
  set('meta[name="description"]', kisalt(aciklama, 155));
  set('meta[property="og:title"]', `${baslik} — TiyatRol`);
  if (gorsel) { let m = $('meta[property="og:image"]'); if (!m) { m = document.createElement('meta'); m.setAttribute('property', 'og:image'); document.head.append(m); } m.setAttribute('content', gorsel); }
}

export function bulunamadi(ad) {
  $('#icerik').innerHTML = `<div class="empty" style="margin-top:48px"><h3>${esc(ad)} bulunamadı</h3><p>Bağlantı eski olabilir ya da kayıt kaldırılmış olabilir.</p><p style="margin-top:16px"><a class="btn btn-primary" href="/kesfet">Tüm oyunlara bak</a></p></div>`;
}
export const hata = (e) => { console.error(e); $('#icerik').innerHTML = hataKutusu(e.message); };

// Sol: yapışkan bilet. Sağ: program (başlık, bilgi, bölüm çubuğu, bölümler).
export function programIskeleti({ bilet, kirinti, baslik, bilgiler = '', bolumler }) {
  const nav = bolumler.filter((b) => b.html).map((b) => `<a href="#${b.id}">${esc(b.ad)}</a>`).join('');
  return `<div class="det">
    <aside>${bilet}</aside>
    <article class="prog"><div class="crumbs">${kirinti}</div><h1>${baslik}</h1>${bilgiler ? `<div class="facts">${bilgiler}</div>` : ''}
      <nav class="bar-nav" id="bnav" aria-label="Sayfa bölümleri">${nav}</nav>
      ${bolumler.filter((b) => b.html).map((b) => `<section class="block" id="${b.id}"><h2>${esc(b.ad)}</h2>${b.html}</section>`).join('')}
    </article></div>`;
}

export function etkilesimler() {
  // Bölüm çubuğu: kaydırınca aktif bölümü işaretle.
  const links = $$('#bnav a');
  if (links.length) {
    const secs = links.map((a) => $(a.getAttribute('href')));
    const io = new IntersectionObserver((ent) => {
      ent.forEach((e) => { if (e.isIntersecting) { links.forEach((a) => a.classList.toggle('on', a.getAttribute('href') === '#' + e.target.id)); } });
    }, { rootMargin: '-30% 0px -60% 0px' });
    secs.forEach((s) => s && io.observe(s));
    links[0].classList.add('on');
  }
  // Galeri gezgini: önceki/sonraki, klavye, kaydırma
  const lb = $('#lb');
  if (lb && !lb.dataset.k) {
    lb.dataset.k = '1';
    lb.insertAdjacentHTML('beforeend', '<button class="lb-btn lb-x" aria-label="Kapat">×</button><button class="lb-btn lb-p" aria-label="Önceki">‹</button><button class="lb-btn lb-n" aria-label="Sonraki">›</button>');
    let liste = [], k = 0;
    const goster = () => { lb.querySelector('img').src = liste[k]; };
    const git = (d) => { k = (k + d + liste.length) % liste.length; goster(); };
    document.addEventListener('lb-ac', (e) => { liste = e.detail.liste; k = e.detail.k; goster(); lb.classList.add('open'); });
    document.addEventListener('click', (e) => {
      const im = e.target.closest('.gal img, .mosaic img');
      if (im) { const hepsi = [...im.closest('.gal, .mosaic').querySelectorAll('img')]; liste = hepsi.map((x) => x.dataset.full || x.src); k = hepsi.indexOf(im); goster(); lb.classList.add('open'); return; }
      if (e.target.closest('.lb-p')) return git(-1);
      if (e.target.closest('.lb-n')) return git(1);
      if (e.target.closest('#lb')) lb.classList.remove('open');
    });
    addEventListener('keydown', (e) => {
      if (!lb.classList.contains('open')) return;
      if (e.key === 'Escape') lb.classList.remove('open'); if (e.key === 'ArrowRight') git(1); if (e.key === 'ArrowLeft') git(-1);
    });
  }
}

export const galeri = (urls, alt = '') => {
  if (!urls.length) return '';
  if (urls.length === 1) return `<div class="gal2 tek"><div class="g-sahne"><div class="g-track"><div class="g-slayt" style="--bl:url('${esc(urls[0])}')"><img src="${esc(urls[0])}" alt="${esc(alt)}" loading="lazy"></div></div></div></div>`;
  const ok = '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">';
  return `<div class="gal2" data-n="${urls.length}" data-alt="${esc(alt)}">
    <div class="g-sahne">
      <div class="g-track" tabindex="0" aria-label="Galeri, ${urls.length} fotoğraf">${urls.map((u, i) => `<div class="g-slayt" style="--bl:url('${esc(u)}')"><img src="${esc(u)}" alt="${esc(alt)} ${i + 1}" ${i > 1 ? 'loading="lazy"' : ''} data-full="${esc(u)}"></div>`).join('')}</div>
      <button class="g-ok g-p" aria-label="Önceki">${ok}<path d="m15 5-7 7 7 7"/></svg></button><button class="g-ok g-n" aria-label="Sonraki">${ok}<path d="m9 5 7 7-7 7"/></svg></button>
      <div class="g-ust"><span class="g-sayac">1 / ${urls.length}</span><span class="g-ar"><button class="g-tum" aria-label="Tüm fotoğrafları göster">${ok}<rect x="4" y="4" width="7" height="7" rx="1"/><rect x="13" y="4" width="7" height="7" rx="1"/><rect x="4" y="13" width="7" height="7" rx="1"/><rect x="13" y="13" width="7" height="7" rx="1"/></svg>Tümü</button><button class="g-buyut" aria-label="Tam ekran">${ok}<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/></svg></button></span></div>
      <div class="g-noktalar" aria-hidden="true">${urls.slice(0, 12).map((_, i) => `<i class="${i === 0 ? 'on' : ''}"></i>`).join('')}</div>
    </div>
    <div class="g-seritler" role="tablist">${urls.map((u, i) => `<button role="tab" class="${i === 0 ? 'on' : ''}" data-i="${i}" aria-label="${i + 1}. fotoğraf"><img src="${esc(u)}" alt="" loading="lazy"></button>`).join('')}</div>
  </div>`;
};

export function harita(lat, lng, adres = '') {
  if (lat == null || lng == null || (lat === 0 && lng === 0)) return '';
  const d = 0.006;
  const src = `https://www.openstreetmap.org/export/embed.html?bbox=${lng - d},${lat - d},${lng + d},${lat + d}&layer=mapnik&marker=${lat},${lng}`;
  return `<iframe class="map" title="Harita" loading="lazy" src="${src}"></iframe>
    <p style="margin-top:12px"><a class="btn btn-ghost btn-sm" target="_blank" rel="noopener" href="https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}">Yol tarifi al</a> <span class="tiny">${esc(adres)}</span></p>`;
}

// ---------- Takvime ekle ----------
const iso = (d) => `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}T${String(d.getHours()).padStart(2, '0')}${String(d.getMinutes()).padStart(2, '0')}00`;
export function takvimLinkleri({ baslik, bas, dakika = 90, yer = '', aciklama = '', url = '' }) {
  const bit = new Date(bas.getTime() + dakika * 60000);
  const q = encodeURIComponent;
  const det = `${aciklama}\n${url}`.trim();
  return {
    google: `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${q(baslik)}&dates=${iso(bas)}/${iso(bit)}&details=${q(det)}&location=${q(yer)}`,
    outlook: `https://outlook.live.com/calendar/0/deeplink/compose?path=/calendar/action/compose&rru=addevent&subject=${q(baslik)}&startdt=${q(bas.toISOString())}&enddt=${q(bit.toISOString())}&body=${q(det)}&location=${q(yer)}`,
    yahoo: `https://calendar.yahoo.com/?v=60&title=${q(baslik)}&st=${iso(bas)}&dur=${String(Math.floor(dakika / 60)).padStart(2, '0')}${String(dakika % 60).padStart(2, '0')}&desc=${q(det)}&in_loc=${q(yer)}`,
    ics: () => {
      const z = (s) => String(s).replace(/([,;\\])/g, '\\$1').replace(/\n/g, '\\n');
      const t = `BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//TiyatRol//TR\r\nBEGIN:VEVENT\r\nUID:${Date.now()}@tiyatrol.com\r\nDTSTAMP:${iso(new Date())}\r\nDTSTART:${iso(bas)}\r\nDTEND:${iso(bit)}\r\nSUMMARY:${z(baslik)}\r\nLOCATION:${z(yer)}\r\nDESCRIPTION:${z(det)}\r\nBEGIN:VALARM\r\nTRIGGER:-P1D\r\nACTION:DISPLAY\r\nDESCRIPTION:Yarın: ${z(baslik)}\r\nEND:VALARM\r\nBEGIN:VALARM\r\nTRIGGER:-PT2H\r\nACTION:DISPLAY\r\nDESCRIPTION:2 saat sonra: ${z(baslik)}\r\nEND:VALARM\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n`;
      const a = document.createElement('a');
      a.href = URL.createObjectURL(new Blob([t], { type: 'text/calendar' }));
      a.download = 'tiyatrol-seans.ics'; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
    },
  };
}
export function takvimMenusu(btn, veri) {
  const l = takvimLinkleri(veri);
  const m = document.createElement('div');
  m.style.cssText = 'position:absolute;z-index:70;background:var(--surface);color:var(--ink);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow);padding:6px;min-width:210px';
  m.innerHTML = `<a class="chip" style="display:flex;border:0;margin:2px 0" target="_blank" rel="noopener" href="${l.google}">Google Takvim</a><a class="chip" style="display:flex;border:0;margin:2px 0" target="_blank" rel="noopener" href="${l.outlook}">Outlook</a><a class="chip" style="display:flex;border:0;margin:2px 0" target="_blank" rel="noopener" href="${l.yahoo}">Yahoo</a><button class="chip" style="display:flex;width:100%;border:0;margin:2px 0" data-ics>Apple / .ics indir</button>`;
  const r = btn.getBoundingClientRect();
  m.style.left = `${r.left + scrollX}px`; m.style.top = `${r.bottom + scrollY + 6}px`;
  document.body.append(m);
  m.querySelector('[data-ics]').addEventListener('click', () => { l.ics(); m.remove(); });
  setTimeout(() => document.addEventListener('click', function k(e) { if (!m.contains(e.target)) { m.remove(); document.removeEventListener('click', k); } }), 0);
}
export const dakikaOku = (s) => { const n = parseInt(String(s || '').replace(/\D/g, ''), 10); return n >= 20 && n < 400 ? n : 90; };
export { tarihUzun, saat };

// ---------- Ortak canlı parçalar ----------
// Sayı animasyonu: 0'dan hedefe (ease-out)
export function sayAc(kok = document) {
  const az = matchMedia('(prefers-reduced-motion: reduce)').matches;
  kok.querySelectorAll('[data-say]').forEach((el) => {
    const hedef = +el.dataset.say; if (az || !hedef) { el.textContent = hedef; return; }
    const t0 = performance.now(), sure = 900;
    const adim = (t) => { const p = Math.min(1, (t - t0) / sure); el.textContent = Math.round(hedef * (1 - (1 - p) ** 3)); if (p < 1) requestAnimationFrame(adim); };
    requestAnimationFrame(adim);
  });
}
// Geri sayım: "12 gün 3 saat 05 dk"
export function geriSayim(el, hedef) {
  const g = () => {
    let ms = hedef - Date.now();
    if (ms <= 0) { el.textContent = 'Şimdi başlıyor'; return; }
    const gun = Math.floor(ms / 864e5); ms -= gun * 864e5;
    const sa = Math.floor(ms / 36e5); ms -= sa * 36e5;
    const dk = Math.floor(ms / 6e4);
    el.textContent = gun ? `${gun} gün ${sa} saat` : `${sa} saat ${String(dk).padStart(2, '0')} dk`;
  };
  g(); setInterval(g, 30000);
}
// Sekmeli panel: { id, ad, html, sayi }
export function sekmeler(kap, liste, baslangic = 0) {
  const l = liste.filter((x) => x.html);
  if (!l.length) { kap.innerHTML = ''; return; }
  const ciz = (i) => {
    kap.innerHTML = `<div class="tabs" role="tablist">${l.map((x, k) => `<button role="tab" aria-selected="${k === i}" class="${k === i ? 'on' : ''}" data-k="${k}">${esc(x.ad)}${x.sayi ? `<span class="n">${x.sayi}</span>` : ''}</button>`).join('')}</div><div class="panel" role="tabpanel">${l[i].html}</div>`;
    kap.querySelectorAll('.tabs button').forEach((b) => b.addEventListener('click', () => { ciz(+b.dataset.k); history.replaceState(null, '', '#' + l[+b.dataset.k].id); }));
  };
  const h = location.hash.slice(1); const ilk = l.findIndex((x) => x.id === h);
  ciz(ilk >= 0 ? ilk : baslangic);
}

// ---------- Galeri (kaydırmalı sahne + küçük resim şeridi + tüm fotoğraflar penceresi) ----------
// Tek olay yönetimi (delegasyon): sekme değişse bile yeniden bağlamaya gerek yok.
const gAz = matchMedia('(prefers-reduced-motion: reduce)').matches;
const gUrls = (g) => [...g.querySelectorAll('.g-slayt img')].map((x) => x.dataset.full || x.src);
function gGit(g, i, yumusak = true) {
  const t = g.querySelector('.g-track'), n = +g.dataset.n; i = (i + n) % n;
  t.scrollTo({ left: i * t.clientWidth, behavior: yumusak && !gAz ? 'smooth' : 'auto' });
  gIsaret(g, i);
}
function gIsaret(g, i) {
  if (g.dataset.k === String(i)) return; g.dataset.k = i;
  g.querySelector('.g-sayac').textContent = `${i + 1} / ${g.dataset.n}`;
  g.querySelectorAll('.g-seritler button').forEach((b, k) => { b.classList.toggle('on', k === i); if (k === i) b.scrollIntoView({ inline: 'center', block: 'nearest', behavior: gAz ? 'auto' : 'smooth' }); });
  g.querySelectorAll('.g-noktalar i').forEach((d, k) => d.classList.toggle('on', k === i % 12));
}
document.addEventListener('scroll', (e) => {
  const t = e.target; if (!t.classList || !t.classList.contains('g-track')) return;
  const g = t.closest('.gal2'); clearTimeout(t._gt);
  t._gt = setTimeout(() => gIsaret(g, Math.round(t.scrollLeft / t.clientWidth)), 60);
}, true);
document.addEventListener('click', (e) => {
  const g = e.target.closest('.gal2'); if (!g) { if (e.target.closest('.g-modal-kapat') || e.target.classList?.contains('g-modal')) document.querySelector('.g-modal')?.remove(); return; }
  const cur = () => +(g.dataset.k || 0);
  if (e.target.closest('.g-p')) return gGit(g, cur() - 1);
  if (e.target.closest('.g-n')) return gGit(g, cur() + 1);
  const th = e.target.closest('.g-seritler button'); if (th) return gGit(g, +th.dataset.i);
  if (e.target.closest('.g-buyut') || e.target.closest('.g-slayt img')) return document.dispatchEvent(new CustomEvent('lb-ac', { detail: { liste: gUrls(g), k: cur() } }));
  if (e.target.closest('.g-tum')) {
    const m = document.createElement('div'); m.className = 'g-modal'; m.setAttribute('role', 'dialog');
    m.innerHTML = `<div class="g-modal-k"><header><b>${g.dataset.n} fotoğraf</b><button class="g-modal-kapat btn btn-ghost btn-sm">Kapat</button></header><div class="g-izgara">${gUrls(g).map((u, i) => `<button data-i="${i}"><img src="${esc(u)}" alt="" loading="lazy"></button>`).join('')}</div></div>`;
    document.body.append(m);
    m.addEventListener('click', (ev) => { const b = ev.target.closest('[data-i]'); if (b) { m.remove(); gGit(g, +b.dataset.i, false); g.scrollIntoView({ block: 'center', behavior: 'smooth' }); } });
  }
});
addEventListener('keydown', (e) => {
  if (e.key === 'Escape') document.querySelector('.g-modal')?.remove();
  const g = document.activeElement?.closest?.('.gal2'); if (!g) return;
  if (e.key === 'ArrowRight') { e.preventDefault(); gGit(g, +(g.dataset.k || 0) + 1); } if (e.key === 'ArrowLeft') { e.preventDefault(); gGit(g, +(g.dataset.k || 0) - 1); }
});

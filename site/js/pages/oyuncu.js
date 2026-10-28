import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kelimeKelime, resim } from '../ui.js';
import { baslikYaz, bulunamadi, hata, etkilesimler, sekmeler, sayAc } from '../detay.js';
import { favMi } from '../fav.js';
import { paylasMenusu } from '../ozellik.js';
import { $, $$, esc, idFromPath, linkOf, baslangic, tarihUzun, saat, kisalt } from '../util.js';

kabukCiz('kesfet');
yukle().then((d) => {
  const p = d.playerById.get(idFromPath());
  if (!p) return bulunamadi('Oyuncu');
  baslikYaz(p.fullName, p.bio, p.imageUrl);
  const metin = (x) => (x && typeof x === 'object') ? [x.title || x.name || x.baslik || '', x.detail || x.description || x.aciklama || ''].filter(Boolean).join(' — ') : String(x ?? '').trim();
  const liste = (v) => (Array.isArray(v) ? v : String(v || '').split('\n')).map(metin).filter(Boolean);
  const odulOgeleri = (Array.isArray(p.achievements) ? p.achievements : String(p.achievements || '').split('\n')).map((x) => (x && typeof x === 'object') ? { baslik: x.title || x.name || x.baslik || '', detay: x.detail || x.description || x.aciklama || '', yil: x.year || x.yil || '' } : { baslik: String(x).trim(), detay: '', yil: '' }).filter((x) => x.baslik)
    .sort((a, b) => (parseInt(b.yil) || 0) - (parseInt(a.yil) || 0));
  const oduller = odulOgeleri, isbirlikleri = liste(p.collaborations);
  const sahnede = p.nowShows.filter((s) => s.state !== 'bitti');
  const sonraki = p.nowShows.map((s) => s.next).filter(Boolean).sort((a, b) => a.when - b.when)[0];
  const butunOyunlar = [...p.nowShows, ...p.oldShows];
  const ortaklar = new Map();
  butunOyunlar.forEach((s) => [...s.cast, ...s.pastCast].forEach((x) => { if (x.id !== p.id) ortaklar.set(x.id, x); }));
  const ort = [...ortaklar.values()];

  const kalpB = `<button type="button" class="kalp-b ${favMi(p.id, 'oyuncu') ? 'on' : ''}" data-fav="${p.id}" data-fav-tur="oyuncu" aria-pressed="${favMi(p.id, 'oyuncu')}"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.5 15.4 12 20 12 20Z"/></svg>Takip et</button>`;
  const yan = `<aside class="yan-kart">${sonraki ? `<h3>Sıradaki sahne</h3><div><b>${esc(sonraki.show.name)}</b><br><span class="muted">${tarihUzun(sonraki.when)} · ${saat(sonraki.when)}${sonraki.stage ? ` · ${esc(sonraki.stage.name)}` : ''}</span></div><a class="btn btn-primary" href="${linkOf('oyun', sonraki.show)}">Oyuna git</a>` : '<h3>Şu an sahnede değil</h3><p class="muted">Yeni bir oyunu açıklanınca burada görünür.</p>'}${ort.length ? `<h3 style="margin-top:8px">Birlikte oynadıkları</h3>${ort.slice(0, 5).map((o) => `<a class="ort" href="${linkOf('oyuncu', o)}"><div class="flower">${o.imageUrl ? `<img src="${esc(o.imageUrl)}" alt="" loading="lazy">` : esc(baslangic(o.fullName))}</div><b>${esc(o.fullName)}</b></a>`).join('')}` : ''}</aside>`;

  const bio = p.bio ? `<div class="pf-iki"><div><p class="story">${esc(p.bio)}</p>${isbirlikleri.length ? `<h3 style="margin:30px 0 12px;font-size:22px">İş birlikleri</h3><div class="facts">${isbirlikleri.map((o) => `<span class="chip">${esc(o)}</span>`).join('')}</div>` : ''}</div>${yan}</div>` : `<div class="pf-iki"><div class="empty">Biyografi eklenmedi.</div>${yan}</div>`;
  const tabHtml = [
    { id: 'hakkinda', ad: 'Hakkında', html: bio },
    { id: 'sahnede', ad: 'Sahnede', sayi: sahnede.length, html: sahnede.length ? ray(sahnede.map((s) => oyunKarti(s)).join('')) : '' },
    { id: 'gecmis', ad: 'Geçmiş oyunlar', sayi: p.oldShows.length, html: p.oldShows.length ? `<div class="grid">${p.oldShows.map((s) => oyunKarti(s)).join('')}</div>` : '' },
    { id: 'oduller', ad: 'Ödüller', sayi: oduller.length, html: oduller.length ? `<div class="odul-izgara">${oduller.map((a) => `<article class="odul"><div class="odul-yil">${esc(a.yil || '★')}</div><div><h3>${esc(a.baslik)}</h3>${a.detay ? `<p>${esc(a.detay)}</p>` : ''}</div><svg class="odul-kupa" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M7 4h10v5a5 5 0 0 1-10 0V4Z"/><path d="M7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3M12 14v4M8 20h8"/></svg></article>`).join('')}</div>` : '' },
  ];

  $('#icerik').innerHTML = `
  <section class="pf-hero"><div class="wrap pf-grid">
    <div class="pf-foto">${p.imageUrl ? `<img src="${esc(p.imageUrl)}" alt="${esc(p.fullName)}">` : `<div class="yok">${esc(baslangic(p.fullName))}</div>`}</div>
    <div class="pf-info"><div class="crumbs"><a href="/vitrin">Vitrin</a> / <a href="/kesfet?tur=oyuncular">Oyuncular</a></div><h1>${kelimeKelime(p.fullName)}</h1>
      ${p.quote ? `<p class="pf-soz">“${esc(p.quote)}”</p>` : ''}
      <div class="pf-sayilar"><div><b data-say="${sahnede.length}">0</b><span>Sahnede</span></div><div><b data-say="${p.oldShows.length}">0</b><span>Geçmiş oyun</span></div><div><b data-say="${ort.length}">0</b><span>Birlikte oynadığı</span></div></div>
      <div class="op-act">${sonraki ? `<a class="btn btn-primary" href="${linkOf('oyun', sonraki.show)}">Sıradaki oyununa git</a>` : ''}${kalpB}<button class="btn btn-ghost" id="paylas">Paylaş</button></div></div>
  </div></section>
  <div class="wrap"><div id="sekme-kap"></div></div>`;
  sekmeler($('#sekme-kap'), tabHtml);
  sayAc(); etkilesimler();
  $('#paylas').addEventListener('click', (ev) => paylasMenusu(ev.currentTarget, p.fullName, kisalt(p.bio, 120)));
}).catch(hata);

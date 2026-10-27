import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, etkilesimler, sekmeler, sayAc, harita } from '../detay.js';
import { favMi } from '../fav.js';
import { paylasMenusu } from '../ozellik.js';
import { $, esc, idFromPath, linkOf, tl, tarihUzun, saat, AYLAR, kisalt, baslangic } from '../util.js';

kabukCiz('sahneler');
yukle().then((d) => {
  const g = d.stageById.get(idFromPath());
  if (!g) return bulunamadi('Sahne');
  baslikYaz(g.name, g.description, g.imageUrl);
  const n = g.upcoming[0];
  const tel = String(g.communication || '').trim();
  const oynayan = g.shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
  const kalpB = `<button type="button" class="kalp-b ${favMi(g.id) ? 'on' : ''}" data-fav="${g.id}" aria-pressed="${favMi(g.id)}"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.5 15.4 12 20 12 20Z"/></svg>Takip et</button>`;
  const yol = g.lat != null && g.lng != null ? `https://www.google.com/maps/dir/?api=1&destination=${g.lat},${g.lng}` : '';

  const seans = g.upcoming.length ? `<div class="sessions">${g.upcoming.slice(0, 40).map((e) => `<a class="sess" href="${e.show ? linkOf('oyun', e.show) : '#'}"><div class="d"><b>${e.when.getDate()}</b><small>${AYLAR[e.when.getMonth()].slice(0, 3)}</small></div><div><b>${esc(e.show?.name || 'Oyun')}</b><br><span class="muted">${saat(e.when)}</span></div><div class="pr"><b>${e.priceNum ? tl(e.priceNum) : ''}</b></div><span class="btn btn-ghost btn-sm">Detay</span></a>`).join('')}</div>` : '';
  const yan = `<aside class="yan-kart"><h3>Nasıl gidilir?</h3>${g.address ? `<p class="muted">${esc(g.address)}</p>` : ''}${yol ? `<a class="btn btn-primary" target="_blank" rel="noopener" href="${yol}">Yol tarifi al</a>` : ''}${tel ? `<a class="btn btn-ghost" href="${/@/.test(tel) ? 'mailto:' : 'tel:'}${esc(tel)}">${/@/.test(tel) ? 'E-posta gönder' : 'Ara'}: ${esc(tel)}</a>` : ''}${g.capacity ? `<div class="info-row"><span>Kapasite</span><b>${esc(g.capacity)}</b></div>` : ''}</aside>`;
  const tabHtml = [
    { id: 'seanslar', ad: 'Seanslar', sayi: g.upcoming.length, html: seans },
    { id: 'hakkinda', ad: 'Hakkında', html: `<div class="pf-iki"><div>${g.description ? `<p class="story">${esc(g.description)}</p>` : '<div class="empty">Açıklama eklenmedi.</div>'}</div>${yan}</div>` },
    { id: 'oyunlar', ad: 'Bu sahnede oynayanlar', sayi: oynayan.length, html: oynayan.length ? `<div class="grid">${oynayan.map((s) => oyunKarti(s)).join('')}</div>` : '' },
    { id: 'konum', ad: 'Konum', html: harita(g.lat, g.lng, g.address) },
    { id: 'yakin', ad: 'Yakındaki sahneler', html: (() => { if (g.lat == null) return ''; const km = (a, b, c, e) => { const r = Math.PI / 180, x = (e - b) * r * Math.cos(((a + c) / 2) * r), y = (c - a) * r; return Math.sqrt(x * x + y * y) * 6371; }; const l = d.stages.filter((x) => x.id !== g.id && x.lat != null).map((x) => ({ x, k: km(g.lat, g.lng, x.lat, x.lng) })).filter((o) => o.k <= 40).sort((a, b) => a.k - b.k).slice(0, 6); return l.length ? `<div class="venues">${l.map(({ x, k }) => `<a class="venue" href="${linkOf('sahne', x)}">${x.imageUrl ? `<img src="${esc(x.imageUrl)}" alt="" loading="lazy">` : ''}<div><h3>${esc(x.name)}</h3><small>${k.toFixed(1)} km · ${x.upcoming.length} yaklaşan seans</small></div></a>`).join('')}</div>` : ''; })() },
  ];
  $('#icerik').innerHTML = `
  <section class="pf-hero"><div class="wrap pf-grid">
    <div class="pf-foto kare">${g.imageUrl ? `<img src="${esc(g.imageUrl)}" alt="${esc(g.name)}">` : `<div class="yok">${esc(baslangic(g.name))}</div>`}</div>
    <div class="pf-info"><div class="crumbs"><a href="/app">Vitrin</a> / <a href="/kesfet?tur=sahneler">Sahneler</a></div><h1>${kelimeKelime(g.name)}</h1>
      ${g.address ? `<p class="op-lead">${esc(g.address)}</p>` : ''}
      <div class="pf-sayilar"><div><b data-say="${g.upcoming.length}">0</b><span>Yaklaşan seans</span></div><div><b data-say="${oynayan.length}">0</b><span>Oyun</span></div>${g.capacity ? `<div><b>${esc(g.capacity)}</b><span>Kapasite</span></div>` : ''}</div>
      <div class="op-act">${n?.show ? `<a class="btn btn-primary" href="${linkOf('oyun', n.show)}">Sıradaki: ${esc(kisalt(n.show.name, 28))}</a>` : (yol ? `<a class="btn btn-primary" target="_blank" rel="noopener" href="${yol}">Yol tarifi al</a>` : '')}${kalpB}<button class="btn btn-ghost" id="paylas">Paylaş</button></div></div>
  </div></section>
  <div class="wrap"><div id="sekme-kap"></div></div>`;
  sekmeler($('#sekme-kap'), tabHtml);
  sayAc(); etkilesimler();
  $('#paylas').addEventListener('click', (ev) => paylasMenusu(ev.currentTarget, g.name, kisalt(g.description, 120)));
}).catch(hata);

import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, programIskeleti, etkilesimler, harita } from '../detay.js';
import { $, esc, idFromPath, linkOf, tl, tarihUzun, saat } from '../util.js';

kabukCiz('sahneler');
yukle().then((d) => {
  const st = d.stageById.get(idFromPath());
  if (!st) return bulunamadi('Sahne');
  baslikYaz(st.name, st.description, st.imageUrl);
  const n = st.upcoming[0];
  const tel = String(st.communication || '').trim();
  const bilet = `<div class="ticket"><div class="head"><span>Sahne künyesi</span><span>${n ? 'Perde açık' : 'Programda yok'}</span></div>
    ${st.imageUrl ? `<img class="poster" style="aspect-ratio:4/3" src="${esc(st.imageUrl)}" alt="${esc(st.name)}">` : ''}
    <div class="body"><div class="fields"><div class="fld"><small>Kapasite</small><b>${esc(st.capacity || '—')}</b></div><div class="fld"><small>Yaklaşan seans</small><b>${st.upcoming.length}</b></div>
      ${n ? `<div class="fld"><small>Sıradaki</small><b>${tarihUzun(n.when)} ${saat(n.when)}</b></div>` : ''}</div>
    <div class="perf"></div>${n?.show ? `<a class="btn btn-primary" href="${linkOf('oyun', n.show)}">Sıradaki oyunu gör</a>` : (st.lat != null ? `<a class="btn btn-primary" target="_blank" rel="noopener" href="https://www.google.com/maps/dir/?api=1&destination=${st.lat},${st.lng}">Yol tarifi al</a>` : '')}<div class="bars"></div></div></div>`;
  const seans = st.upcoming.length ? `<div class="sessions">${st.upcoming.slice(0, 30).map((e) => `<a class="sess" href="${e.show ? linkOf('oyun', e.show) : '#'}"><div class="d"><b>${e.when.getDate()}</b><small>${tarihUzun(e.when).split(' ')[1]}</small></div><div><b>${esc(e.show?.name || 'Oyun')}</b><br><span class="muted">${saat(e.when)}</span></div><div class="pr"><b>${e.priceNum ? tl(e.priceNum) : ''}</b></div><span class="btn btn-ghost btn-sm">Detay</span></a>`).join('')}</div>` : '';
  const bolumler = [
    { id: 'seanslar', ad: 'Seanslar', html: seans },
    { id: 'hakkinda', ad: 'Hakkında', html: st.description ? `<p class="story">${esc(st.description)}</p>` : '' },
    { id: 'oyunlar', ad: 'Bu sahnede oynayanlar', html: st.shows.length ? ray(st.shows.map((s) => oyunKarti(s)).join('')) : '' },
    { id: 'konum', ad: 'Konum ve iletişim', html: `${st.address ? `<p class="muted" style="margin-bottom:14px">${esc(st.address)}</p>` : ''}${harita(st.lat, st.lng)}${tel ? `<div class="info-row"><span>İletişim</span><a href="${/@/.test(tel) ? 'mailto:' : 'tel:'}${esc(tel)}"><b>${esc(tel)}</b></a></div>` : ''}` },
  ];
  $('#icerik').innerHTML = programIskeleti({ bilet, kirinti: '<a href="/">Vitrin</a> / <a href="/kesfet?tur=sahneler">Sahneler</a>', baslik: kelimeKelime(st.name), bilgiler: st.address ? `<span class="chip">${esc(st.address)}</span>` : '', bolumler });
  etkilesimler();
}).catch(hata);

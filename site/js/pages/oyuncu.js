import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, programIskeleti, etkilesimler } from '../detay.js';
import { $, esc, idFromPath, linkOf, baslangic } from '../util.js';

kabukCiz('kesfet');
yukle().then((d) => {
  const p = d.playerById.get(idFromPath());
  if (!p) return bulunamadi('Oyuncu');
  baslikYaz(p.fullName, p.bio, p.imageUrl);
  const sahnede = p.nowShows.length > 0;
  const liste = (v) => (Array.isArray(v) ? v : String(v || '').split('\n')).map((x) => String(x).trim()).filter(Boolean);
  const oduller = liste(p.achievements), isbirlikleri = liste(p.collaborations);
  const bilet = `<div class="ticket"><div class="head"><span>Oyuncu künyesi</span><span>${sahnede ? 'Sahnede' : 'Arşiv'}</span></div>
    ${p.imageUrl ? `<img class="poster" src="${esc(p.imageUrl)}" alt="${esc(p.fullName)}">` : `<div class="poster" style="display:grid;place-items:center;font:700 80px var(--font-display)">${esc(baslangic(p.fullName))}</div>`}
    <div class="body"><div class="fields"><div class="fld"><small>Şu an</small><b>${p.nowShows.length} oyun</b></div><div class="fld"><small>Geçmiş</small><b>${p.oldShows.length} oyun</b></div></div>
    <div class="perf"></div>${p.nowShows[0] ? `<a class="btn btn-primary" href="${linkOf('oyun', p.nowShows[0])}">Sahnedeki oyununa git</a>` : ''}<div class="bars"></div></div></div>`;
  const bolumler = [
    { id: 'biyografi', ad: 'Biyografi', html: p.bio ? `<p class="story">${esc(p.bio)}</p>` : '' },
    { id: 'sahnede', ad: 'Sahnede', html: p.nowShows.length ? ray(p.nowShows.map((s) => oyunKarti(s)).join('')) : '' },
    { id: 'oduller', ad: 'Ödüller', html: oduller.length ? `<ul class="sessions" style="list-style:none;padding:0">${oduller.map((o) => `<li class="sess" style="grid-template-columns:1fr">${esc(o)}</li>`).join('')}</ul>` : '' },
    { id: 'isbirlikleri', ad: 'İş birlikleri', html: isbirlikleri.length ? `<div class="facts">${isbirlikleri.map((o) => `<span class="chip">${esc(o)}</span>`).join('')}</div>` : '' },
    { id: 'gecmis', ad: 'Geçmiş oyunlar', html: p.oldShows.length ? ray(p.oldShows.map((s) => oyunKarti(s)).join('')) : '' },
  ];
  $('#icerik').innerHTML = programIskeleti({
    bilet, kirinti: '<a href="/">Vitrin</a> / <a href="/kesfet?tur=oyuncular">Oyuncular</a>', baslik: kelimeKelime(p.fullName),
    bilgiler: p.quote ? `<span style="font:600 24px/1.3 Caveat,cursive;color:var(--accent)">“${esc(p.quote)}”</span>` : '', bolumler,
  });
  etkilesimler();
}).catch(hata);

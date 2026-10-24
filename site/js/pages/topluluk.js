import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kisi, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, programIskeleti, etkilesimler, galeri } from '../detay.js';
import { $, esc, idFromPath, linkOf } from '../util.js';

kabukCiz('toplulukler');
yukle().then((d) => {
  const t = d.teamById.get(idFromPath());
  if (!t) return bulunamadi('Topluluk');
  baslikYaz(t.name, t.description, t.imageUrl);
  const sahnede = t.shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
  const gecmis = t.shows.filter((s) => s.state === 'bitti' || s.state === 'taslak');
  const oyuncular = [...new Map(t.shows.flatMap((s) => s.cast).map((p) => [p.id, p])).values()];
  const bilet = `<div class="ticket"><div class="head"><span>Topluluk künyesi</span><span>${sahnede.length ? 'Sahnede' : 'Arşiv'}</span></div>
    ${t.imageUrl ? `<img class="poster" style="aspect-ratio:4/3" src="${esc(t.imageUrl)}" alt="${esc(t.name)}">` : ''}
    <div class="body"><div class="fields"><div class="fld"><small>Sahnede</small><b>${sahnede.length} oyun</b></div><div class="fld"><small>Toplam</small><b>${t.shows.length} oyun</b></div></div>
    <div class="perf"></div>${sahnede[0] ? `<a class="btn btn-primary" href="${linkOf('oyun', sahnede[0])}">Oyuna git</a>` : ''}<div class="bars"></div></div></div>`;
  const bolumler = [
    { id: 'hakkinda', ad: 'Hakkında', html: t.description ? `<p class="story">${esc(t.description)}</p>` : '' },
    { id: 'sahnede', ad: 'Sahnede', html: sahnede.length ? ray(sahnede.map((s) => oyunKarti(s)).join('')) : '' },
    { id: 'kadro', ad: 'Kadro', html: oyuncular.length ? `<div class="people">${oyuncular.map(kisi).join('')}</div>` : '' },
    { id: 'galeri', ad: 'Galeri', html: galeri(t.photos, t.name) },
    { id: 'gecmis', ad: 'Geçmiş oyunlar', html: gecmis.length ? ray(gecmis.map((s) => oyunKarti(s)).join('')) : '' },
  ];
  $('#icerik').innerHTML = programIskeleti({ bilet, kirinti: '<a href="/">Vitrin</a> / <a href="/kesfet?tur=topluluklar">Topluluklar</a>', baslik: kelimeKelime(t.name), bolumler });
  etkilesimler();
}).catch(hata);

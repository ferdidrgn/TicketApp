import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, ray, kisi, resim, kelimeKelime } from '../ui.js';
import { baslikYaz, bulunamadi, hata, programIskeleti, etkilesimler, galeri, harita, takvimMenusu, dakikaOku } from '../detay.js';
import { $, $$, esc, idFromPath, linkOf, tl, tarihUzun, saat, gunKisa, kisalt } from '../util.js';

kabukCiz('kesfet');
yukle().then(ciz).catch(hata);

function ciz(d) {
  const s = d.showById.get(idFromPath());
  if (!s) return bulunamadi('Oyun');
  baslikYaz(s.name, s.description, s.imageUrl);
  const secili = { i: 0 };
  const seanslar = s.upcoming;
  const stage = (e) => e?.stage;

  const bilet = () => {
    const e = seanslar[secili.i];
    const buy = s.external
      ? `<a class="btn btn-primary" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Bileti al</a>`
      : `<a class="btn btn-primary" href="/uygulama">Bileti uygulamada al</a>`;
    return `<div class="ticket"><div class="head"><span>TiyatRol</span><span>Bilet</span></div>
      ${s.imageUrl ? `<img class="poster" src="${esc(s.imageUrl)}" alt="${esc(s.name)}">` : '<div class="poster"></div>'}
      <div class="body">
        ${e ? `<div class="fields"><div class="fld"><small>Tarih</small><b>${tarihUzun(e.when)}</b></div><div class="fld"><small>Saat</small><b>${saat(e.when)}</b></div>
          <div class="fld"><small>Sahne</small><b>${esc(stage(e)?.name || e.stageId || '—')}</b></div><div class="fld"><small>Fiyat</small><b>${e.priceNum ? tl(e.priceNum) : (e.priceNum === 0 ? 'Ücretsiz' : '—')}</b></div></div>
          ${seanslar.length > 1 ? `<div class="facts" style="margin:0">${seanslar.slice(0, 6).map((x, i) => `<button class="chip ${i === secili.i ? 'on' : ''}" data-s="${i}">${x.when.getDate()} ${gunKisa(x.when)} ${saat(x.when)}</button>`).join('')}</div>` : ''}`
        : `<div class="fld"><small>Durum</small><b>${s.state === 'bitti' ? 'Sezon sona erdi' : 'Seans açıklanmadı'}</b></div>`}
        <div class="perf"></div>
        ${s.state === 'bitti' ? '' : buy}
        ${e ? `<button class="btn btn-ghost" id="takvim" style="border-color:rgba(29,20,16,.3)">Takvime ekle</button>` : ''}
        <div class="bars" aria-hidden="true"></div></div></div>`;
  };

  const seansHtml = s.sessions.length ? `<div class="sessions">${s.sessions.slice().reverse().sort((a, b) => a.when - b.when).map((e) => {
    const gecmis = e.when < new Date();
    return `<div class="sess ${gecmis ? 'past' : ''}"><div class="d"><b>${e.when.getDate()}</b><small>${tarihUzun(e.when).split(' ')[1]}</small></div>
      <div><b>${esc(e.stage?.name || e.stageId || 'Sahne belirtilmedi')}</b><br><span class="muted">${gunKisa(e.when)} · ${saat(e.when)}</span></div>
      <div class="pr"><b>${e.priceNum ? tl(e.priceNum) : e.priceNum === 0 ? 'Ücretsiz' : ''}</b></div>
      ${gecmis ? '<span class="tiny">Geçti</span>' : (s.external ? `<a class="btn btn-ghost btn-sm" target="_blank" rel="noopener sponsored" href="${esc(s.externalTicketUrl)}">Bilet</a>` : '<a class="btn btn-ghost btn-sm" href="/uygulama">Bilet</a>')}</div>`;
  }).join('')}</div>` : '';

  const yer = s.next ? stage(s.next) : d.stageById.get(s.sessions.at(-1)?.stageId) || null;
  const bolumler = [
    { id: 'hikaye', ad: 'Hikâye', html: s.description ? `<p class="story">${esc(s.description)}</p>` : '' },
    { id: 'seanslar', ad: 'Seanslar', html: seansHtml },
    { id: 'kadro', ad: 'Kadro', html: s.cast.length ? `<div class="people">${s.cast.map(kisi).join('')}</div>` : '' },
    { id: 'mekan', ad: 'Mekân', html: yer ? `<p style="margin-bottom:14px"><a href="${linkOf('sahne', yer)}"><b>${esc(yer.name)}</b></a><br><span class="muted">${esc(yer.address || '')}</span></p>${harita(yer.lat, yer.lng, '')}` : (s.externalVenueName ? `<p><b>${esc(s.externalVenueName)}</b><br><span class="muted">${esc(s.externalVenueAddress || '')}</span></p>${harita(s.externalLat, s.externalLng)}` : '') },
    { id: 'galeri', ad: 'Galeri', html: galeri(s.photos, s.name) },
    { id: 'gecmis', ad: 'Eski kadro', html: s.pastCast.length ? `<div class="people">${s.pastCast.map(kisi).join('')}</div>` : '' },
    { id: 'benzer', ad: 'Benzer oyunlar', html: (() => { const b = d.shows.filter((x) => x.id !== s.id && x.cat === s.cat && x.state !== 'bitti').slice(0, 10); return b.length ? ray(b.map((x) => oyunKarti(x)).join('')) : ''; })() },
  ];
  const bilgi = [s.cat, s.duration && `${s.duration}`, s.ageLimit && `Yaş sınırı ${s.ageLimit}`, s.type].filter(Boolean).map((x) => `<span class="chip">${esc(x)}</span>`).join('');
  const kirinti = `<a href="/">Vitrin</a> / <a href="/kesfet?tur=${encodeURIComponent(s.cat)}">${esc(s.cat)}</a>${s.team ? ` / <a href="${linkOf('topluluk', s.team)}">${esc(s.team.name)}</a>` : ''}`;

  const render = () => {
    $('#icerik').innerHTML = programIskeleti({ bilet: bilet(), kirinti, baslik: kelimeKelime(s.name), bilgiler: bilgi, bolumler });
    etkilesimler();
    baglan();
  };
  const baglan = () => {
    $$('[data-s]').forEach((b) => b.addEventListener('click', () => {
      secili.i = +b.dataset.s; $('.ticket').parentElement.innerHTML = bilet(); baglan();
    }));
    $('#takvim')?.addEventListener('click', (ev) => {
      const e = seanslar[secili.i];
      takvimMenusu(ev.currentTarget, { baslik: s.name, bas: e.when, dakika: dakikaOku(s.duration), yer: [e.stage?.name, e.stage?.address].filter(Boolean).join(', '), aciklama: kisalt(s.description, 300), url: location.href });
    });
  };
  render();
  // Yapılandırılmış veri (arama motorları için)
  if (s.next) {
    const ld = document.createElement('script'); ld.type = 'application/ld+json';
    ld.textContent = JSON.stringify({ '@context': 'https://schema.org', '@type': 'TheaterEvent', name: s.name, description: kisalt(s.description, 300), image: s.imageUrl, startDate: s.next.when.toISOString(), location: { '@type': 'Place', name: s.next.stage?.name || '', address: s.next.stage?.address || '' }, offers: s.minPrice != null ? { '@type': 'Offer', price: s.minPrice, priceCurrency: 'TRY', url: s.externalTicketUrl || location.href } : undefined });
    document.head.append(ld);
  }
}

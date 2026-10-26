import '../theme.js';
import { yukle } from '../store.js';
import { perdeAc, isikKur } from '../fx.js';
import { ilOku, ilYaz } from '../iller.js';
import { tarihAyristir } from '../util.js';
import { mandala, KAMPANYA_SANAT } from '../ui.js';
import { temaYaz, temaOku, temaHesapla, temaSecenekleri } from '../theme.js';
import { takvimMenusu, dakikaOku } from '../detay.js';
import { kalpDugme } from '../fav.js';
import { alanAdi, kabukCiz, bolumBasligi, oyunKarti, ray, kisi, resim, afis, kelimeKelime, hataKutusu, iskelet } from '../ui.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, gunKisa, gunAdi, ayniGun, gunBasi, kisalt, AY_KISA } from '../util.js';

kabukCiz('ana');
perdeAc();
const home = $('#home');
home.innerHTML = `<section class="sec">${bolumBasligi('Yükleniyor')}<div class="rail">${iskelet(6)}</div></section>`;

yukle().then(ciz).catch((e) => { console.error(e); $('#hero').remove(); home.innerHTML = `<section class="sec">${hataKutusu(e.message)}</section>`; });

document.addEventListener('il-degisti', () => location.reload());

function ilSuz(d, il) {
  if (!il) return d;
  const shows = d.shows.filter((s) => s.iller.includes(il));
  const stages = d.stages.filter((g) => g.il === il);
  return { ...d, shows, stages, events: d.events.filter((e) => e.stage?.il === il),
    kategoriler: [...new Set(shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin').map((s) => s.cat))].sort((a, b) => a.localeCompare(b, 'tr')) };
}

function ciz(d0) {
  const il = ilOku();
  const d = ilSuz(d0, il);
  const now = new Date();
  const aktif = d.shows.filter((s) => s.state === 'aktif');
  const vitrin = d.shows.filter((s) => s.state === 'vitrin');
  const gorunen = [...aktif, ...vitrin];

  heroKur(d, aktif, vitrin);
  isikKur($('#hero'));
  seritKur(d);

  const hafta = aktif.filter((s) => s.next.when - now < 7 * 864e5).sort((a, b) => a.next.when - b.next.when);
  const sonCagri = aktif.filter((s) => s.upcoming.length <= 2 && s.next.when - now < 21 * 864e5).sort((a, b) => a.upcoming.at(-1).when - b.upcoming.at(-1).when);
  const top = [...aktif].sort((a, b) => b.upcoming.length - a.upcoming.length || a.next.when - b.next.when).slice(0, 10);
  const parts = [];

  // Kategoriler
  if (d.kategoriler.length > 1) {
    parts.push(`<section class="sec">${bolumBasligi('Türe göre keşfet')}<div class="cats">${d.kategoriler.map((k) => {
      const s = gorunen.find((x) => x.cat === k && afis(x));
      return `<a class="cat" href="/kesfet?tur=${encodeURIComponent(k)}"><div class="ring">${s ? `<img src="${esc(afis(s))}" alt="" loading="lazy">` : `<div class="ph">${esc(k[0])}</div>`}</div>${esc(k)}</a>`;
    }).join('')}</div></section>`);
  }

  if (hafta.length) parts.push(`<section class="sec">${bolumBasligi('Bu hafta sahnede', 'Önümüzdeki yedi günde perde açan oyunlar.', '/kesfet?zaman=hafta')}${ray(hafta.map((s) => oyunKarti(s)).join(''))}</section>`);

  // Kampanyalar: solda HD sahne grafiği, sağda yukarı akan kuponlar (kompakt, sayfa kaydırmayı engellemez)
  if (d.tumKampanyalar.some((c) => c.durum !== 'bitti')) {
    const kl = d.tumKampanyalar.filter((c) => c.durum !== 'bitti').slice(0, 8);
    const kart = (c) => `<a class="kv" href="${c.url && /^https?:/.test(c.url) ? esc(c.url) : '/kampanyalar'}" ${c.url && /^https?:/.test(c.url) ? 'target="_blank" rel="noopener sponsored"' : ''}>${c.imageUrl ? `<img src="${esc(c.imageUrl)}" alt="" loading="lazy">` : '<span class="kv-i"></span>'}<div><span class="durum ${c.durum}">${c.durum === 'son' ? 'Son günler' : 'Devam ediyor'}</span><b>${esc(c.title || 'Kampanya')}</b><small>${c.bit ? (c.kalanGun === 0 ? 'Bugün son gün' : `Son ${c.kalanGun} gün`) : 'Süresiz'}</small></div></a>`;
    parts.push(`<section class="sec"><div class="kamp-vitrin"><div class="kv-sol">${KAMPANYA_SANAT}<div class="kv-yazi"><h2>Kampanyalar</h2><p>Bilet fırsatları ve indirimler.</p><a class="btn btn-primary btn-sm" href="/kampanyalar">Tümünü gör</a></div></div>
      <div class="kv-sag ${kl.length > 2 ? 'akar' : ''}"><div class="kv-akis">${kl.map(kart).join('')}${kl.length > 2 ? kl.map(kart).join('') : ''}</div></div></div></section>`);
  }

  // Hafta sonu
  const hSonu = aktif.filter((s) => s.upcoming.some((e) => { const wd = e.when.getDay(); return (wd === 0 || wd === 6 || (wd === 5 && e.when.getHours() >= 17)) && e.when - now < 8 * 864e5; }));
  if (hSonu.length) parts.push(`<section class="sec">${bolumBasligi('Bu hafta sonu', 'Cuma akşamından pazara perde açılanlar.', '/kesfet?zaman=haftasonu')}${ray(hSonu.map((s) => oyunKarti(s)).join(''))}</section>`);

  // Ruh hâli
  const adaylar = gorunen.length ? gorunen : d.shows.filter((x) => x.state !== 'bitti');
  if (adaylar.length >= 2) parts.push(`<section class="sec">${bolumBasligi('Bu akşam ne izlesem?', 'Ruh hâlini seç, sana bir bilet çıkaralım.')}<div class="mood"><div><div class="mood-chips" id="mood-chips">${MOODS.map((m, i) => `<button class="chip" data-m="${i}">${m.ad}</button>`).join('')}</div><p class="tiny" style="margin-top:14px">Önerilen oyun seçtiğin ruh hâline göre türünden ve anlatımından bulunur.</p></div><div class="mood-out" id="mood-out"><div class="empty">Bir ruh hâli seç.</div></div></div></section>`);

  // Ajanda
  const gunler = [...new Map(d.events.filter((e) => e.when >= gunBasi(now) && e.show && e.show.state !== 'taslak').map((e) => [gunBasi(e.when).getTime(), gunBasi(e.when)])).values()].sort((a, b) => a - b).slice(0, 40);
  if (gunler.length) parts.push(`<section class="sec" id="ajanda">${bolumBasligi('Tarih seç', 'Perde açılan günleri gez; saat, sahne ve fiyat tek bakışta.')}<div class="pano" id="pano"></div></section>`);

  if (top.length >= 3) parts.push(`<section class="sec">${bolumBasligi('Şu an en çok oynayanlar', 'Önümüzdeki seans sayısına göre ilk on.')}<div class="top10">${top.map((s, i) => `<div class="t10"><span class="n">${i + 1}</span>${oyunKarti(s, { fiyat: false })}</div>`).join('')}</div></section>`);

  if (sonCagri.length) parts.push(`<section class="sec">${bolumBasligi('Son çağrı', 'Perdesi yakında kapanacak oyunlar.')}${ray(sonCagri.map((s) => oyunKarti(s, { rozet: `${s.upcoming.length} seans kaldı` })).join(''))}</section>`);

  // Bütçe
  const fiyatli = aktif.filter((s) => s.minPrice != null);
  if (fiyatli.length >= 3) {
    const mx = Math.ceil(Math.max(...fiyatli.map((s) => s.minPrice)) / 50) * 50, mn = Math.floor(Math.min(...fiyatli.map((s) => s.minPrice)) / 50) * 50;
    parts.push(`<section class="sec"><div class="budget"><div class="budget-box"><h2 style="font-size:28px">Bütçene göre</h2><p class="muted" style="margin-top:8px">Bilet fiyatı için üst sınırı seç.</p>
      <output id="bt">${tl(mx)}</output><input type="range" id="br" min="${mn}" max="${mx}" step="50" value="${mx}" aria-label="En yüksek bilet fiyatı"><p class="tiny" id="bn"></p></div><div id="brail"></div></div></section>`);
  }

  // Çocuklarla / ücretsiz / yeni eklenenler
  const cocuk = gorunen.filter((s) => /çocuk|masal|müzikal/i.test(`${s.cat} ${s.type || ''} ${s.name}`));
  if (cocuk.length) parts.push(`<section class="sec">${bolumBasligi('Çocuklarla', 'Çocuk oyunları ve aile seçimleri.', '/kesfet')}${ray(cocuk.map((s) => oyunKarti(s)).join(''))}</section>`);
  const bedava = aktif.filter((s) => s.upcoming.some((e) => e.priceNum === 0));
  if (bedava.length) parts.push(`<section class="sec">${bolumBasligi('Ücretsiz seanslar', 'Bilet gerektirmeyen ya da ücretsiz oyunlar.')}${ray(bedava.map((s) => oyunKarti(s)).join(''))}</section>`);
  const yeniler = [...gorunen].filter((s) => s._createdAt).sort((a, b) => (tarihAyristir(b._createdAt) || 0) - (tarihAyristir(a._createdAt) || 0)).slice(0, 10);
  if (yeniler.length >= 3) parts.push(`<section class="sec">${bolumBasligi('Yeni eklenenler', 'Programa son girenler.')}${ray(yeniler.map((s) => oyunKarti(s, { rozet: 'Yeni' })).join(''))}</section>`);

  // Tür bazlı raylar (en kalabalık 3 tür)
  const turSay = new Map(); gorunen.forEach((s) => turSay.set(s.cat, (turSay.get(s.cat) || 0) + 1));
  [...turSay.entries()].filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1]).slice(0, 3).forEach(([k]) => {
    parts.push(`<section class="sec">${bolumBasligi(`${k} oyunları`, '', `/kesfet?tur=${encodeURIComponent(k)}`)}${ray(gorunen.filter((s) => s.cat === k).map((s) => oyunKarti(s)).join(''))}</section>`);
  });

  // Haritada keşfet + il çipleri
  const ilCip = [...d0.ilSayilari.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10);
  const afisPaket = gorunen.filter((s) => s.imageUrl).slice(0, 4);
  parts.push(`<section class="sec"><div class="harita-bant"><div><h2>Haritada keşfet</h2><p class="muted">Oyunları ve sahneleri afişleriyle haritada gör; ilini seç, yakınındakileri bul.</p>
    ${ilCip.length ? `<div class="il-cipler">${ilCip.map(([i, n]) => `<button class="chip ${il === i ? 'on' : ''}" data-il="${esc(i)}">${esc(i)} <small>${n}</small></button>`).join('')}</div>` : ''}
    <a class="btn btn-primary" href="/harita" style="margin-top:18px">Haritayı aç</a></div>
    <a class="hb-afis" href="/harita" aria-label="Harita">${afisPaket.map((s, i) => `<img src="${esc(s.imageUrl)}" alt="" style="--i:${i}" loading="lazy">`).join('')}<i class="hb-pin"></i></a></div></section>`);

  const siralı = [...d.shows].sort((a, b) => (a.state === 'aktif' ? 0 : a.state === 'vitrin' ? 1 : a.state === 'taslak' ? 2 : 3) - (b.state === 'aktif' ? 0 : b.state === 'vitrin' ? 1 : b.state === 'taslak' ? 2 : 3));
  if (siralı.length) parts.push(`<section class="sec">${bolumBasligi('Tüm oyunlar', 'Repertuvardaki bütün oyunlar.', '/kesfet')}${ray(siralı.map((s) => oyunKarti(s, { rozet: s.state === 'taslak' ? 'Yakında' : '' })).join(''))}</section>`);

  if (d.stages.length) parts.push(`<section class="sec">${bolumBasligi('Sahneler', 'Perdenin açıldığı mekânlar.', '/kesfet?tur=sahneler')}<div class="venues">${d.stages.filter((s) => s.imageUrl).slice(0, 6).map((s) => `<a class="venue" href="${linkOf('sahne', s)}"><img src="${esc(s.imageUrl)}" alt="" loading="lazy"><div><h3>${esc(s.name)}</h3><small>${s.upcoming.length ? `${s.upcoming.length} yaklaşan seans` : esc(kisalt(s.address, 50))}</small></div></a>`).join('')}</div></section>`);

  // Günün repliği (her gün başka bir oyuncunun sözü)
  const sozlu = d.players.filter((p) => p.quote && p.quote.length > 8);
  if (sozlu.length) {
    const gun = Math.floor(Date.now() / 864e5), p = sozlu[gun % sozlu.length];
    parts.push(`<section class="sec"><div class="replik"><div><small class="tiny">GÜNÜN REPLİĞİ</small><blockquote>${esc(p.quote)}</blockquote><cite>— ${esc(p.fullName)}</cite></div><a href="${linkOf('oyuncu', p)}" aria-label="${esc(p.fullName)}"><div class="flower">${p.imageUrl ? `<img src="${esc(p.imageUrl)}" alt="" loading="lazy">` : esc(p.fullName[0])}</div></a></div></section>`);
  }
  // Oyuncu hikâyeleri
  const hik = d.players.filter((p) => p.imageUrl && (p.quote || p.nowShows.length)).slice(0, 14);
  if (hik.length >= 3) parts.push(`<section class="sec">${bolumBasligi('Sahnenin yüzleri', 'Sözleri ve sıradaki oyunlarıyla oyuncular.')}<div class="hikayeler">${hik.map((p) => `<a class="hik" href="${linkOf('oyuncu', p)}"><img src="${esc(p.imageUrl)}" alt="" loading="lazy"><div><b>${esc(p.fullName)}</b><small>${esc(p.quote ? '“' + kisalt(p.quote, 54) + '”' : (p.nowShows[0] ? p.nowShows[0].name : ''))}</small></div></a>`).join('')}</div></section>`);
  // Son baktıkların
  try {
    const ids = JSON.parse(localStorage.getItem('tiyatrol.son') || '[]');
    const l = ids.map((id) => d.showById.get(id)).filter(Boolean).slice(0, 10);
    if (l.length) parts.push(`<section class="sec">${bolumBasligi('Son baktıkların', 'Kaldığın yerden devam et.')}${ray(l.map((s) => oyunKarti(s)).join(''))}</section>`);
  } catch {}

  const oyuncular = d.players.filter((p) => p.nowShows.length).slice(0, 24);
  if (oyuncular.length) parts.push(`<section class="sec">${bolumBasligi('Sahnedeki oyuncular')}<div class="people">${oyuncular.map(kisi).join('')}</div></section>`);

  if (d.teams.length) parts.push(`<section class="sec">${bolumBasligi('Topluluklar', '', '/kesfet?tur=topluluklar')}<div class="people">${d.teams.slice(0, 20).map((t) => `<a class="person" href="${linkOf('topluluk', t)}"><div class="flower">${t.imageUrl ? `<img src="${esc(t.imageUrl)}" alt="" loading="lazy">` : esc(t.name[0])}</div><b>${esc(t.name)}</b></a>`).join('')}</div></section>`);

  parts.push(`<section class="soz-sec"><div class="soz-yan"><p class="soz">Perde açılır, ışık düşer, hikâye başlar. Sen yalnızca seansı seç.</p><p>Her akşam şehrin bir yerinde bir sahne yanıyor. TiyatRol, o ışığı bulman için var.</p></div></section>`);
  parts.push(`<section class="sec"><div class="guides">
    <div class="guide"><div class="rom">I. Perde</div><h3>Oyunu bul</h3><p>Türe, tarihe ya da bütçene göre süz; afişten oyunun hikâyesine, kadrosuna ve sahnesine geç.</p></div>
    <div class="guide"><div class="rom">II. Perde</div><h3>Seansı seç</h3><p>Her oyunun yaklaşan seansları saat, sahne ve fiyatıyla listelenir; takvimine tek dokunuşla ekle.</p></div>
    <div class="guide"><div class="rom">III. Perde</div><h3>Bileti al</h3><p>Bileti TiyatRol uygulamasından ya da oyunun organizatörünün sitesinden al; biletin hep uygulamada.</p></div></div></section>`);

  if (il) parts.unshift(`<section class="sec"><div class="il-bant"><span><b>${esc(il)}</b> programı gösteriliyor · ${aktif.length + vitrin.length} oyun</span><button class="btn btn-ghost btn-sm" id="il-tum">Tüm Türkiye'ye geç</button></div>${!aktif.length && !vitrin.length ? `<div class="empty" style="margin-top:20px"><h3>${esc(il)} için şu an program yok</h3><p>Yakındaki illere bakabilir ya da Tüm Türkiye'yi açabilirsin.</p></div>` : ''}</section>`);
  // Tema seçimi: her kutu seçeneğin gerçek renkleriyle dolu bir mini sayfa önizlemesi
  { const sec = temaOku();
    const L = [['sarap', 'gece', 'Şarap', 'Gece'], ['sarap', 'gunduz', 'Şarap', 'Gündüz'], ['okyanus', 'gece', 'Okyanus', 'Gece'], ['okyanus', 'gunduz', 'Okyanus', 'Gündüz'], ['orman', 'gece', 'Orman', 'Gece'], ['mor', 'gunduz', 'Menekşe', 'Gündüz'], ['mor', 'gece', 'Menekşe', 'Gece'], ['kehribar', 'gunduz', 'Kehribar', 'Gündüz'], ['doga', 'gece', 'Doğa', 'Material'], ['ahenk', 'gunduz', 'Ahenk', 'Material']];
    const kart = ([p, m, ad, alt]) => { const v = temaHesapla({ palet: p, mod: m, ozel: '#c50337' }); const aktif = sec.palet === p && (sec.mod === m);
      return `<button class="to-kart ${aktif ? 'on' : ''}" data-p="${p}" data-m="${m}" aria-label="${ad} ${alt}" style="--tb:${v['--bg']};--ts:${v['--surface']};--ts2:${v['--surface-2']};--ti:${v['--ink']};--ta:${v['--accent']};--tai:${v['--accent-ink']}"><span class="to-mini"><span class="to-bar"><i></i><i></i><i></i></span><span class="to-gv"><span class="to-poster"></span><span class="to-ic"><b></b><b></b><em>Bilet</em></span></span></span><span class="to-ad">${ad}<small>${alt}</small></span></button>`; };
    parts.push(`<section class="sec tema-sec"><div class="to-ust"><div><h2>Temanı seç</h2><p class="muted">Görünümü tek dokunuşla değiştir; seçimin hatırlanır.</p></div><label class="to-ozel">Özel renk <input type="color" id="to-ozel" value="${sec.ozel || '#c50337'}" aria-label="Özel vurgu rengi"></label></div><div class="to-izgara">${L.map(kart).join('')}</div></section>`);
  }

  // Bölümleri istenen sıraya diz (işaret metnine göre); sırada olmayanlar özgün sırasıyla sona gider
  const SIRA = [/tema-sec/, /id="ajanda"/, /<h2>[^<]* oyunları</, /harita-bant/, /soz-sec/, /<h2>Ücretsiz seanslar</, /ne izlesem/, /<h2>Bu hafta sahnede</, /<h2>Bu hafta sonu</, /en çok oynayanlar/, /<h2>Yeni eklenenler</, /<h2>Son çağrı</, /<h2>Çocuklarla</, /class="budget"/, /<h2>Tüm oyunlar</, /<h2>Sahneler</, /class="replik"/, /Sahnenin yüzleri/, /<h2>Son baktıkların</, /Sahnedeki oyuncular/, /<h2>Topluluklar</, /kamp-vitrin/, /class="guides"/];
  const rank = (s) => { const k = SIRA.findIndex((r) => r.test(s)); return k < 0 ? 99 : k; };
  parts.sort((a, b) => rank(a) - rank(b));
  home.innerHTML = parts.join('');
  $$('.to-kart').forEach((b) => b.addEventListener('click', () => { temaYaz({ palet: b.dataset.p, mod: b.dataset.m }); $$('.to-kart').forEach((x) => x.classList.toggle('on', x === b)); }));
  $('#to-ozel')?.addEventListener('input', (e) => { temaYaz({ palet: 'ozel', ozel: e.target.value }); $$('.to-kart').forEach((x) => x.classList.remove('on')); });
  document.getElementById('il-tum')?.addEventListener('click', () => ilYaz(''));
  document.querySelectorAll('.il-cipler [data-il]').forEach((b) => b.addEventListener('click', () => ilYaz(b.dataset.il)));
  if (adaylar.length >= 2) moodKur(adaylar);
  if (gunler.length) ajandaKur(d);
  if (fiyatli.length >= 3) butceKur(fiyatli);
}

function heroKur(d, aktif, vitrin) {
  const slaytlar = [
    ...d.campaigns.filter((c) => c.imageUrl).map((c) => ({ tip: 'kampanya', baslik: c.title || 'Kampanya', img: c.imageUrl, link: c.url || '/kesfet', kicker: 'Kampanya', lead: '', meta: [] })),
    ...[...aktif].sort((a, b) => (b.oneCikan ? 1 : 0) - (a.oneCikan ? 1 : 0) || a.next.when - b.next.when).slice(0, 5).map((s) => ({
      tip: 'oyun', baslik: s.name, img: afis(s), link: linkOf('oyun', s), kicker: s.cat, lead: kisalt(s.description, 170),
      meta: [['Sıradaki seans', `${tarihUzun(s.next.when)} · ${saat(s.next.when)}`], ['Sahne', s.next.stage?.name || '—'], ['Bilet', s.minPrice != null ? `${tl(s.minPrice)}'den` : 'Yakında']], damga: s.oneCikan ? 'Haftanın oyunu' : 'Bu hafta sahnede', dis: s.external ? alanAdi(s.externalTicketUrl) : '',
    })),
  ];
  if (!slaytlar.length) vitrin.slice(0, 3).forEach((s) => slaytlar.push({ tip: 'oyun', baslik: s.name, img: afis(s), link: linkOf('oyun', s), kicker: s.cat, lead: kisalt(s.description, 170), meta: [] }));
  const hero = $('#hero');
  if (!slaytlar.length) { hero.remove(); return; }
  const kart = (x, i) => `
    <div class="hero-slide ${i === 0 ? 'on' : ''}" data-i="${i}">
      <div class="hero-bg">${x.img ? `<img src="${esc(x.img)}" alt="">` : ''}</div>
      <div class="wrap"><div class="hero-grid">
        <div><div class="hero-kicker">${esc(x.kicker)}</div><h1>${x.tip === 'oyun' ? esc(x.baslik) : esc(x.baslik)}</h1>
          ${x.lead ? `<p class="lead">${esc(x.lead)}</p>` : ''}
          ${x.meta.length ? `<div class="hero-meta">${x.meta.map(([a, b]) => `<div><b>${a}</b><span>${esc(b)}</span></div>`).join('')}</div>` : ''}
          <div class="hero-cta"><a class="btn btn-primary" href="${esc(x.link)}">${x.tip === 'oyun' ? 'Seansları gör' : 'İncele'}</a><a class="btn btn-ghost" href="/kesfet">Tüm oyunlar</a></div></div>
        <a class="hero-art" href="${esc(x.link)}" aria-label="${esc(x.baslik)}">${x.img ? `<img class="poster" src="${esc(x.img)}" alt="${esc(x.baslik)}" ${i ? 'loading="lazy"' : ''}>` : ''}${x.damga ? `<span class="stamp">${esc(x.damga)}</span>` : ''}${x.dis ? `<span class="stamp" style="left:auto;right:-14px;bottom:auto;top:30px;transform:rotate(6deg)">Bilet: ${esc(x.dis)}</span>` : ''}</a>
      </div></div></div>`;
  hero.innerHTML = `<div class="hero-track" id="hero-track">${slaytlar.map(kart).join('')}</div>`
    + (slaytlar.length > 1 ? `<button class="hero-arrow l" aria-label="Önceki slayt"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="m15 5-7 7 7 7"/></svg></button><button class="hero-arrow r" aria-label="Sonraki slayt"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="m9 5 7 7-7 7"/></svg></button><div class="hero-dots">${slaytlar.map((_, i) => `<button aria-label="${i + 1}. slayt" class="${i === 0 ? 'on' : ''}"><i></i></button>`).join('')}</div><div class="hero-count" id="hero-count">1 / ${slaytlar.length}</div>` : '');
  if (slaytlar.length < 2) return;
  const track = $('#hero-track'), sl = $$('.hero-slide', hero), dots = $$('.hero-dots button', hero);
  let cur = 0, timer, durdur = false;
  const SURE = 7000;
  const isaret = (i) => {
    cur = i;
    sl.forEach((x, k) => x.classList.toggle('on', k === cur));
    dots.forEach((b, k) => { b.classList.remove('on', 'done'); if (k < cur) b.classList.add('done'); if (k === cur) { void b.offsetWidth; b.classList.add('on'); } });
    $('#hero-count').textContent = `${cur + 1} / ${sl.length}`;
    clearTimeout(timer); if (!durdur) timer = setTimeout(() => git(cur + 1), SURE);
  };
  const git = (i) => { i = (i + sl.length) % sl.length; track.scrollTo({ left: i * track.clientWidth, behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' }); isaret(i); };
  // kullanıcı kaydırırsa / sürüklerse etkin slaytı bul
  let st;
  track.addEventListener('scroll', () => { clearTimeout(st); st = setTimeout(() => { const i = Math.round(track.scrollLeft / track.clientWidth); if (i !== cur) isaret(i); }, 120); }, { passive: true });
  $('.hero-arrow.l', hero).addEventListener('click', () => git(cur - 1));
  $('.hero-arrow.r', hero).addEventListener('click', () => git(cur + 1));
  dots.forEach((b, i) => b.addEventListener('click', () => git(i)));
  addEventListener('keydown', (e) => { if (/input|textarea|select/i.test(document.activeElement?.tagName || '')) return; if (e.key === 'ArrowLeft') git(cur - 1); if (e.key === 'ArrowRight') git(cur + 1); });
  hero.addEventListener('pointerenter', () => { durdur = true; clearTimeout(timer); dots[cur]?.classList.remove('on'); });
  hero.addEventListener('pointerleave', () => { durdur = false; isaret(cur); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) clearTimeout(timer); else isaret(cur); });
  addEventListener('resize', () => track.scrollTo({ left: cur * track.clientWidth }));
  isaret(0);
}

function ajandaKur(d) {
  const kok = $('#pano'); const simdi = new Date(), bugun = gunBasi(simdi);
  const AY = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  const tum = d.events.filter((e) => e.show && e.show.state !== 'taslak' && e.when >= simdi).sort((a, b) => a.when - b.when);
  const turler = [...new Set(tum.map((e) => e.show.cat))].sort((a, b) => a.localeCompare(b, 'tr'));
  const gunlerSet = new Map(); tum.forEach((e) => { const k = gunBasi(e.when).getTime(); gunlerSet.set(k, (gunlerSet.get(k) || 0) + 1); });
  const ilkGun = tum[0] ? gunBasi(tum[0].when) : bugun;
  const st = { aralik: 'ilk', bas: ilkGun, bit: ilkGun, ay: new Date(ilkGun.getFullYear(), ilkGun.getMonth(), 1), tur: '', sayfa: 1 };
  const gunEk = (n) => { const x = new Date(bugun); x.setDate(x.getDate() + n); return x; };
  const hizli = { bugun: [bugun, bugun], yarin: [gunEk(1), gunEk(1)], hafta: [bugun, gunEk(6)], haftasonu: null, ay: [bugun, new Date(bugun.getFullYear(), bugun.getMonth() + 1, 0)] };
  const sonuc = () => tum.filter((e) => {
    const g = gunBasi(e.when);
    if (st.tur && e.show.cat !== st.tur) return false;
    if (st.aralik === 'haftasonu') { const wd = e.when.getDay(); return (wd === 0 || wd === 6 || (wd === 5 && e.when.getHours() >= 17)) && g - bugun < 8 * 864e5; }
    if (st.aralik === 'hepsi') return true;
    return g >= st.bas && g <= st.bit;
  });
  const ciz = () => {
    const l = sonuc(), gr = new Map(); l.forEach((e) => { const k = gunBasi(e.when).getTime(); (gr.get(k) || gr.set(k, []).get(k)).push(e); });
    const bas = new Date(st.ay), bos = (bas.getDay() + 6) % 7, gs = new Date(st.ay.getFullYear(), st.ay.getMonth() + 1, 0).getDate();
    const hucre = []; for (let i = 0; i < bos; i++) hucre.push('<i class="pm-bos2"></i>');
    for (let g = 1; g <= gs; g++) { const t = new Date(st.ay.getFullYear(), st.ay.getMonth(), g), n = gunlerSet.get(t.getTime()) || 0; const sec = st.aralik === 'ozel' || st.aralik === 'ilk' ? (t >= st.bas && t <= st.bit) : false;
      hucre.push(`<button class="pm-g ${n ? 'var' : ''} ${sec ? 'on' : ''} ${t.getTime() === bugun.getTime() ? 'bugun' : ''}" data-t="${t.getTime()}" ${n ? '' : 'tabindex="-1"'} aria-label="${g} ${AY[st.ay.getMonth()]}, ${n} seans">${g}${n ? `<u>${n}</u>` : ''}</button>`); }
    const HIZ = [['bugun', 'Bugün'], ['yarin', 'Yarın'], ['haftasonu', 'Hafta sonu'], ['hafta', 'Bu hafta'], ['ay', 'Bu ay'], ['hepsi', 'Tümü']];
    const sayfaBoy = 8 * st.sayfa, gorunen = [...gr.entries()].sort((a, b) => a[0] - b[0]);
    let sayac = 0; const bloklar = [];
    for (const [k, ev] of gorunen) { if (sayac >= sayfaBoy) break; const ek = ev.slice(0, sayfaBoy - sayac); sayac += ek.length; bloklar.push([k, ek, ev.length]); }
    const kalan = l.length - sayac;
    kok.innerHTML = `<div class="pano-ust"><div class="pano-hizli" role="group" aria-label="Hızlı tarih">${HIZ.map(([k, a]) => `<button class="chip ${st.aralik === k ? 'on' : ''}" data-h="${k}">${a}</button>`).join('')}</div>
      <div class="pano-tur"><button class="chip ${st.tur === '' ? 'on' : ''}" data-tur="">Tüm türler</button>${turler.map((t) => `<button class="chip ${st.tur === t ? 'on' : ''}" data-tur="${esc(t)}">${esc(t)}</button>`).join('')}</div></div>
    <div class="pano-govde"><aside class="pano-takvim"><div class="pt-ust"><button class="icon-btn" data-ay="-1" aria-label="Önceki ay">‹</button><b>${AY[st.ay.getMonth()]} ${st.ay.getFullYear()}</b><button class="icon-btn" data-ay="1" aria-label="Sonraki ay">›</button></div>
      <div class="pt-adlar">${['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'].map((x) => `<span>${x}</span>`).join('')}</div><div class="pt-izgara">${hucre.join('')}</div>
      <p class="tiny" style="margin-top:12px">Noktalı günlerde seans var. Bir güne dokun; iki güne sırayla dokunarak aralık seç.</p><div class="pt-ozet"><b>${l.length}</b> seans · <b>${new Set(l.map((e) => e.show.id)).size}</b> oyun</div></aside>
      <div class="pano-liste">${bloklar.map(([k, ev, toplam]) => { const t = new Date(k); const fark = Math.round((t - bugun) / 864e5);
        return `<section class="pg-gun"><header><h3>${esc(gunAdi(t))}, ${t.getDate()} ${AY[t.getMonth()]}</h3><span>${fark === 0 ? 'Bugün' : fark === 1 ? 'Yarın' : `${fark} gün sonra`} · ${toplam} seans</span></header>
        <div class="pg-kartlar">${ev.map((e) => `<article class="bilet2"><a class="b2-sol" href="${linkOf('oyun', e.show)}" aria-label="${esc(e.show.name)}"><div class="b2-saat"><b>${saat(e.when)}</b><small>${esc(e.stage?.il || gunKisa(e.when))}</small></div>${e.show.imageUrl ? `<img src="${esc(e.show.imageUrl)}" alt="" loading="lazy">` : '<span class="ph"></span>'}<div class="b2-g"><span class="tag">${esc(e.show.cat)}</span><h4>${esc(e.show.name)}</h4><p class="tiny">${esc(e.stage?.name || '')}</p></div></a>
          <div class="b2-sag"><b>${e.priceNum ? tl(e.priceNum) : (e.priceNum === 0 ? 'Ücretsiz' : '')}</b><div class="b2-ar"><button class="btn btn-ghost btn-sm" data-cal="${esc(e.docId)}" aria-label="Takvime ekle">Takvim</button>${kalpDugme(e.show.id, 'kalp ic')}</div></div></article>`).join('')}</div></section>`; }).join('') || '<div class="empty"><h3>Bu aralıkta seans yok</h3><p>Başka bir gün ya da tür seç.</p></div>'}
        ${kalan > 0 ? `<button class="btn btn-ghost" id="pano-daha" style="margin:8px auto 0;display:flex">${kalan} seans daha göster</button>` : ''}</div></div>`;
    $$('[data-h]', kok).forEach((b) => b.addEventListener('click', () => { const k = b.dataset.h; st.aralik = k; st.sayfa = 1; if (k === 'haftasonu' || k === 'hepsi') {} else if (hizli[k]) { st.bas = hizli[k][0]; st.bit = hizli[k][1]; st.ay = new Date(st.bas.getFullYear(), st.bas.getMonth(), 1); } ciz(); }));
    $$('[data-tur]', kok).forEach((b) => b.addEventListener('click', () => { st.tur = b.dataset.tur; st.sayfa = 1; ciz(); }));
    $$('[data-ay]', kok).forEach((b) => b.addEventListener('click', () => { st.ay = new Date(st.ay.getFullYear(), st.ay.getMonth() + (+b.dataset.ay), 1); ciz(); }));
    let ilk = null;
    $$('.pm-g.var', kok).forEach((b) => b.addEventListener('click', () => { const t = new Date(+b.dataset.t);
      if (st.aralik === 'ozel' && st.secimAcik) { st.bit = t < st.bas ? st.bas : t; if (t < st.bas) st.bas = t; st.secimAcik = false; } else { st.aralik = 'ozel'; st.bas = t; st.bit = t; st.secimAcik = true; }
      st.sayfa = 1; ciz(); }));
    $('#pano-daha')?.addEventListener('click', () => { st.sayfa++; ciz(); });
    $$('[data-cal]', kok).forEach((b) => b.addEventListener('click', () => { const e = tum.find((x) => x.docId === b.dataset.cal); if (!e) return; takvimMenusu(b, { baslik: e.show.name, bas: e.when, dakika: dakikaOku(e.show.duration), yer: [e.stage?.name, e.stage?.address].filter(Boolean).join(', '), aciklama: kisalt(e.show.description, 200), url: location.origin + linkOf('oyun', e.show) }); }));
  };
  ciz();
}

function butceKur(fiyatli) {
  const r = $('#br'), o = $('#bt'), n = $('#bn'), box = $('#brail');
  const g = () => {
    const m = +r.value; o.textContent = tl(m);
    const l = fiyatli.filter((s) => s.minPrice <= m).sort((a, b) => a.minPrice - b.minPrice);
    n.textContent = `${l.length} oyun bu bütçeye uyuyor`;
    box.innerHTML = l.length ? ray(l.slice(0, 12).map((s) => oyunKarti(s)).join('')) : '<div class="empty">Bu bütçeye uygun oyun yok.</div>';
  };
  r.addEventListener('input', g); g();
}

const MOODS = [
  { ad: 'Güldürsün', k: ['komedi', 'güldür', 'mizah', 'komik', 'eğlen'] },
  { ad: 'Düşündürsün', k: ['dram', 'trajedi', 'kara', 'toplum', 'varoluş', 'felsef'] },
  { ad: 'Çocuklarla', k: ['çocuk', 'masal', 'müzikal', 'aile'] },
  { ad: 'Romantik', k: ['aşk', 'romantik', 'sevgi', 'ilişki'] },
  { ad: 'Sıradışı', k: ['deneysel', 'oyun', 'sıra dışı', 'performans', 'monolog'] },
];
function moodKur(adaylar) {
  const out = $('#mood-out'); let son = -1;
  const sec = (m) => {
    const anahtar = MOODS[m].k;
    let l = adaylar.filter((x) => anahtar.some((a) => `${x.cat} ${x.type || ''} ${x.name} ${x.description || ''}`.toLocaleLowerCase('tr').includes(a)));
    if (!l.length) l = adaylar;
    let x; do { x = l[Math.floor(Math.random() * l.length)]; } while (l.length > 1 && x.id === son);
    son = x.id;
    const n = x.next;
    out.innerHTML = `<div class="m-ticket"><img class="afis" src="${esc(afis(x))}" alt="${esc(x.name)}"><div class="govde"><small>${esc(x.cat)}</small><h3>${esc(x.name)}</h3><p class="muted">${esc(kisalt(x.description, 130))}</p><small>${n ? `${tarihUzun(n.when)} · ${saat(n.when)}` : 'Seans yakında'}</small></div><div class="kocan"><small>${x.minPrice != null ? tl(x.minPrice) : 'Bilet'}</small><a class="btn btn-primary btn-sm" href="${linkOf('oyun', x)}">İncele</a><button class="btn btn-ghost btn-sm" data-yeni style="border-color:rgba(29,20,16,.3)">Başkası</button></div></div>`;
    out.querySelector('[data-yeni]').addEventListener('click', () => sec(m));
  };
  $$('#mood-chips .chip').forEach((b) => b.addEventListener('click', () => {
    $$('#mood-chips .chip').forEach((c) => c.classList.toggle('on', c === b));
    sec(+b.dataset.m);
  }));
}

function seritKur(d) {
  const now = new Date();
  const l = d.events.filter((e) => e.show && e.when >= now).sort((a, b) => a.when - b.when).slice(0, 14);
  if (!l.length) return;
  const parca = l.map((e) => `<a href="${linkOf('oyun', e.show)}">${tarihUzun(e.when).split(' ').slice(0, 2).join(' ')} · ${saat(e.when)} — ${esc(e.show.name)}${e.stage ? ` · ${esc(e.stage.name)}` : ''}</a>`).join('');
  const b = document.createElement('div'); b.className = 'band'; b.setAttribute('aria-label', 'Yaklaşan seanslar');
  b.innerHTML = `<div class="band-in">${parca}${parca}</div>`;
  const hero = $('#hero'); if (hero) hero.after(b);
}

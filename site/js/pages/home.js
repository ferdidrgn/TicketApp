import '../theme.js';
import { yukle } from '../store.js';
import { perdeAc, isikKur } from '../fx.js';
import { ilOku, ilYaz } from '../iller.js';
import { tarihAyristir } from '../util.js';
import { alanAdi, kabukCiz, bolumBasligi, oyunKarti, ray, kisi, resim, afis, kelimeKelime, hataKutusu, iskelet } from '../ui.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, gunKisa, ayniGun, gunBasi, kisalt, AY_KISA } from '../util.js';

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

  // Kampanya şeridi
  if (d.tumKampanyalar.some((c) => c.durum !== 'bitti')) {
    const kl = d.tumKampanyalar.filter((c) => c.durum !== 'bitti').slice(0, 6);
    parts.push(`<section class="sec">${bolumBasligi('Kampanyalar', 'Bilet fırsatları ve indirimler.', '/kampanyalar')}<div class="kamp-seridi">${kl.map((c) => `<a class="kamp" href="/kampanyalar">${c.imageUrl ? `<img src="${esc(c.imageUrl)}" alt="" loading="lazy">` : ''}<div><span class="durum ${c.durum}">${c.durum === 'son' ? 'Son günler' : 'Devam ediyor'}</span><b>${esc(c.title || 'Kampanya')}</b><small>${c.bit ? (c.kalanGun === 0 ? 'Bugün son gün' : `Son ${c.kalanGun} gün`) : 'Süresiz'}</small></div></a>`).join('')}</div></section>`);
  }

  // Hafta sonu
  const hSonu = aktif.filter((s) => s.upcoming.some((e) => { const wd = e.when.getDay(); return (wd === 0 || wd === 6 || (wd === 5 && e.when.getHours() >= 17)) && e.when - now < 8 * 864e5; }));
  if (hSonu.length) parts.push(`<section class="sec">${bolumBasligi('Bu hafta sonu', 'Cuma akşamından pazara perde açılanlar.', '/kesfet?zaman=haftasonu')}${ray(hSonu.map((s) => oyunKarti(s)).join(''))}</section>`);

  // Ruh hâli
  const adaylar = gorunen.length ? gorunen : d.shows.filter((x) => x.state !== 'bitti');
  if (adaylar.length >= 2) parts.push(`<section class="sec">${bolumBasligi('Bu akşam ne izlesem?', 'Ruh hâlini seç, sana bir bilet çıkaralım.')}<div class="mood"><div><div class="mood-chips" id="mood-chips">${MOODS.map((m, i) => `<button class="chip" data-m="${i}">${m.ad}</button>`).join('')}</div><p class="tiny" style="margin-top:14px">Önerilen oyun seçtiğin ruh hâline göre türünden ve anlatımından bulunur.</p></div><div class="mood-out" id="mood-out"><div class="empty">Bir ruh hâli seç.</div></div></div></section>`);

  // Ajanda
  const gunler = [...new Map(d.events.filter((e) => e.when >= gunBasi(now) && e.show && e.show.state !== 'taslak').map((e) => [gunBasi(e.when).getTime(), gunBasi(e.when)])).values()].sort((a, b) => a - b).slice(0, 40);
  if (gunler.length) parts.push(`<section class="sec" id="ajanda">${bolumBasligi('Tarih seç', 'Perde açılan günler — birini seç, o günün programını gör.')}<div class="dates" id="dates"></div><div class="agenda" id="agenda"></div></section>`);

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
  home.innerHTML = parts.join('');
  document.getElementById('il-tum')?.addEventListener('click', () => ilYaz(''));
  document.querySelectorAll('.il-cipler [data-il]').forEach((b) => b.addEventListener('click', () => ilYaz(b.dataset.il)));
  if (adaylar.length >= 2) moodKur(adaylar);
  if (gunler.length) ajandaKur(d, gunler);
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

function ajandaKur(d, gunler) {
  const dates = $('#dates'), ag = $('#agenda');
  let sec = gunler[0];
  const ciz = () => {
    dates.innerHTML = gunler.map((g) => `<button class="day ${ayniGun(g, sec) ? 'on' : ''}" data-t="${g.getTime()}"><small>${ayniGun(g, new Date()) ? 'Bugün' : gunKisa(g)}</small><b>${g.getDate()}</b><small>${AY_KISA[g.getMonth()]}</small></button>`).join('');
    const ev = d.events.filter((e) => e.show && e.show.state !== 'taslak' && ayniGun(e.when, sec)).sort((a, b) => a.when - b.when);
    ag.innerHTML = ev.map((e) => `<a class="ag-row" href="${linkOf('oyun', e.show)}"><span class="t">${saat(e.when)}</span>${e.show.imageUrl ? `<img src="${esc(e.show.imageUrl)}" alt="" loading="lazy">` : '<span class="ph"></span>'}<span class="nm">${esc(e.show.name)}<br><small class="tiny">${esc(e.show.cat)}</small></span><span class="vn">${esc(e.stage?.name || '')}</span><span class="btn btn-ghost btn-sm">${e.priceNum != null ? tl(e.priceNum) : 'Detay'}</span></a>`).join('') || '<div class="empty">Bu gün için seans yok.</div>';
  };
  dates.addEventListener('click', (e) => { const b = e.target.closest('.day'); if (!b) return; sec = new Date(+b.dataset.t); ciz(); });
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

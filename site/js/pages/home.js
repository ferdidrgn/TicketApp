import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, bolumBasligi, oyunKarti, ray, kisi, resim, afis, kelimeKelime, hataKutusu, iskelet } from '../ui.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, gunKisa, ayniGun, gunBasi, kisalt, AY_KISA } from '../util.js';

kabukCiz('ana');
const home = $('#home');
home.innerHTML = `<section class="sec">${bolumBasligi('Yükleniyor')}<div class="rail">${iskelet(6)}</div></section>`;

yukle().then(ciz).catch((e) => { console.error(e); $('#hero').remove(); home.innerHTML = `<section class="sec">${hataKutusu(e.message)}</section>`; });

function ciz(d) {
  const now = new Date();
  const aktif = d.shows.filter((s) => s.state === 'aktif');
  const vitrin = d.shows.filter((s) => s.state === 'vitrin');
  const gorunen = [...aktif, ...vitrin];

  heroKur(d, aktif, vitrin);

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

  const siralı = [...d.shows].sort((a, b) => (a.state === 'aktif' ? 0 : a.state === 'vitrin' ? 1 : a.state === 'taslak' ? 2 : 3) - (b.state === 'aktif' ? 0 : b.state === 'vitrin' ? 1 : b.state === 'taslak' ? 2 : 3));
  if (siralı.length) parts.push(`<section class="sec">${bolumBasligi('Tüm oyunlar', 'Repertuvardaki bütün oyunlar.', '/kesfet')}${ray(siralı.map((s) => oyunKarti(s, { rozet: s.state === 'taslak' ? 'Yakında' : '' })).join(''))}</section>`);

  if (d.stages.length) parts.push(`<section class="sec">${bolumBasligi('Sahneler', 'Perdenin açıldığı mekânlar.', '/kesfet?tur=sahneler')}<div class="venues">${d.stages.filter((s) => s.imageUrl).slice(0, 6).map((s) => `<a class="venue" href="${linkOf('sahne', s)}"><img src="${esc(s.imageUrl)}" alt="" loading="lazy"><div><h3>${esc(s.name)}</h3><small>${s.upcoming.length ? `${s.upcoming.length} yaklaşan seans` : esc(kisalt(s.address, 50))}</small></div></a>`).join('')}</div></section>`);

  const oyuncular = d.players.filter((p) => p.nowShows.length).slice(0, 24);
  if (oyuncular.length) parts.push(`<section class="sec">${bolumBasligi('Sahnedeki oyuncular')}<div class="people">${oyuncular.map(kisi).join('')}</div></section>`);

  if (d.teams.length) parts.push(`<section class="sec">${bolumBasligi('Topluluklar', '', '/kesfet?tur=topluluklar')}<div class="people">${d.teams.slice(0, 20).map((t) => `<a class="person" href="${linkOf('topluluk', t)}"><div class="flower">${t.imageUrl ? `<img src="${esc(t.imageUrl)}" alt="" loading="lazy">` : esc(t.name[0])}</div><b>${esc(t.name)}</b></a>`).join('')}</div></section>`);

  parts.push(`<section class="sec"><div class="guides">
    <div class="guide"><div class="n">1</div><h3>Oyunu bul</h3><p>Türe, tarihe ya da bütçene göre süz; afişten oyunun hikâyesine, kadrosuna ve sahnesine geç.</p></div>
    <div class="guide"><div class="n">2</div><h3>Seansı seç</h3><p>Her oyunun yaklaşan seansları saat, sahne ve fiyatıyla listelenir; takvimine tek dokunuşla ekle.</p></div>
    <div class="guide"><div class="n">3</div><h3>Bileti al</h3><p>Bileti TiyatRol uygulamasından ya da oyunun organizatörünün sitesinden al; biletin hep uygulamada.</p></div></div></section>`);

  home.innerHTML = parts.join('');
  if (gunler.length) ajandaKur(d, gunler);
  if (fiyatli.length >= 3) butceKur(fiyatli);
}

function heroKur(d, aktif, vitrin) {
  const slaytlar = [
    ...d.campaigns.filter((c) => c.imageUrl).map((c) => ({ tip: 'kampanya', baslik: c.title || 'Kampanya', img: c.imageUrl, link: c.url || '/kesfet', kicker: 'Kampanya', lead: '', meta: [] })),
    ...[...aktif].sort((a, b) => a.next.when - b.next.when).slice(0, 5).map((s) => ({
      tip: 'oyun', baslik: s.name, img: afis(s), link: linkOf('oyun', s), kicker: s.cat, lead: kisalt(s.description, 170),
      meta: [['Sıradaki seans', `${tarihUzun(s.next.when)} · ${saat(s.next.when)}`], ['Sahne', s.next.stage?.name || '—'], ['Bilet', s.minPrice != null ? `${tl(s.minPrice)}'den` : 'Yakında']], damga: 'Bu hafta sahnede',
    })),
  ];
  if (!slaytlar.length) vitrin.slice(0, 3).forEach((s) => slaytlar.push({ tip: 'oyun', baslik: s.name, img: afis(s), link: linkOf('oyun', s), kicker: s.cat, lead: kisalt(s.description, 170), meta: [] }));
  const hero = $('#hero');
  if (!slaytlar.length) { hero.remove(); return; }
  hero.innerHTML = slaytlar.map((x, i) => `
    <div class="hero-slide ${i === 0 ? 'on' : ''}">
      <div class="hero-bg">${x.img ? `<img src="${esc(x.img)}" alt="">` : ''}</div>
      <div class="wrap"><div class="hero-grid">
        <div><div class="hero-kicker">${esc(x.kicker)}</div><h1>${kelimeKelime(x.baslik)}</h1>
          ${x.lead ? `<p class="lead">${esc(x.lead)}</p>` : ''}
          ${x.meta.length ? `<div class="hero-meta">${x.meta.map(([a, b]) => `<div><b>${a}</b><span>${esc(b)}</span></div>`).join('')}</div>` : ''}
          <div class="hero-cta"><a class="btn btn-primary" href="${esc(x.link)}">${x.tip === 'oyun' ? 'Seansları gör' : 'İncele'}</a><a class="btn btn-ghost" href="/kesfet">Tüm oyunlar</a></div></div>
        <a class="hero-art" href="${esc(x.link)}" aria-label="${esc(x.baslik)}">${x.img ? `<img class="poster" src="${esc(x.img)}" alt="${esc(x.baslik)}" ${i ? 'loading="lazy"' : ''}>` : ''}${x.damga ? `<span class="stamp">${esc(x.damga)}</span>` : ''}</a>
      </div></div></div>`).join('') + (slaytlar.length > 1 ? `<div class="hero-dots">${slaytlar.map((_, i) => `<button aria-label="${i + 1}. slayt" class="${i === 0 ? 'on' : ''}"><i></i></button>`).join('')}</div>` : '');
  if (slaytlar.length < 2) return;
  const sl = $$('.hero-slide', hero), dots = $$('.hero-dots button', hero);
  let cur = 0, timer;
  const git = (i) => {
    cur = (i + sl.length) % sl.length;
    sl.forEach((s, k) => s.classList.toggle('on', k === cur));
    dots.forEach((b, k) => { b.classList.remove('on', 'done'); if (k < cur) b.classList.add('done'); if (k === cur) { void b.offsetWidth; b.classList.add('on'); } });
    clearTimeout(timer); timer = setTimeout(() => git(cur + 1), 7000);
  };
  dots.forEach((b, i) => b.addEventListener('click', () => git(i)));
  hero.addEventListener('mouseenter', () => clearTimeout(timer));
  hero.addEventListener('mouseleave', () => git(cur));
  git(0);
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

// Ortak arayüz: üst başlık + arama önerileri, altbilgi, tema paneli, kartlar, raylar.
import { yukle } from './store.js';
import './fx.js';
import './ozellik.js';
import { ILLER, ilOku, ilYaz, enYakinIl } from './iller.js';
import { kalpDugme, favListe } from './fav.js';
import { temaOku, temaYaz, temaSecenekleri } from './theme.js';
import { $, $$, esc, linkOf, tl, tarihUzun, saat, debounce, baslangic, kisalt, ayniGun, tarihAyristir } from './util.js';

const ICON = {
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
  user: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4.5-6 8-6s7 2 8 6"/></svg>',
  palette: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M12 3a9 9 0 1 0 0 18c1.4 0 2-1 1.6-2.2-.4-1.2.4-2.3 1.7-2.3H17a4 4 0 0 0 4-4c0-5-4-9.5-9-9.5Z"/><circle cx="7.5" cy="11" r="1"/><circle cx="10" cy="7" r="1"/><circle cx="15" cy="7.5" r="1"/></svg>',
  heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M12 20s-7.5-4.6-9.3-9.2C1.6 7.6 3.4 4.5 6.5 4.5c2 0 3.5 1.1 4.5 2.7h2c1-1.6 2.5-2.7 4.5-2.7 3.1 0 4.9 3.1 3.8 6.3C19.5 15.4 12 20 12 20Z"/></svg>',
  left: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m15 5-7 7 7 7"/></svg>',
  right: '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m9 5 7 7-7 7"/></svg>',
};
export const squiggle = '<svg viewBox="0 0 150 10" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M2 6c10-6 14 6 24 0s14 6 24 0 14 6 24 0 14 6 24 0 14 6 24 0 14 4 24 0"/></svg>';

export const afis = (s) => s?.imageUrl || '';
export function resim(url, alt = '', cls = '') {
  return url ? `<img src="${esc(url)}" alt="${esc(alt)}" loading="lazy" decoding="async" class="${cls}" onerror="this.replaceWith(Object.assign(document.createElement('div'),{className:'ph-poster',textContent:this.alt}))">` : `<div class="ph-poster">${esc(alt)}</div>`;
}

export function kabukCiz(aktif = '') {
  const nav = (id, href, ad, cls = '') => `<a href="${href}" class="${cls} ${aktif === id ? 'on' : ''}">${ad}</a>`;
  $('#hdr').outerHTML = `
  <div class="util"><div class="wrap"><span>Tiyatro bileti ve program rehberi</span>
    <div class="util-r"><a href="/yardim">Yardım</a><a href="mailto:info@tiyatrol.com">info@tiyatrol.com</a><a href="/uygulama">Uygulamayı indir</a></div></div></div>
  <header class="hdr" id="hdr">
    <div class="wrap hdr-main">
      <a href="/" class="brand" aria-label="TiyatRol ana sayfa"><img src="/img/logo.png" alt=""><span>TİYATROL</span></a>
      <button type="button" class="il-btn" id="il-btn" aria-label="İl seç"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s-7-6.2-7-11.2A7 7 0 0 1 19 9.8C19 14.800 12 21 12 21Z"/><circle cx="12" cy="9.8" r="2.5"/></svg><span id="il-ad">${ilOku() || 'Tüm Türkiye'}</span></button>
      <form class="search" role="search" action="/kesfet" autocomplete="off">
        <input id="q" name="q" type="search" placeholder="Oyun, oyuncu, sahne ya da topluluk ara" aria-label="Ara">
        <kbd>/</kbd><button aria-label="Ara">${ICON.search}</button>
        <div class="suggest" id="suggest"></div>
      </form>
      <div class="hdr-act">
        <button class="icon-btn" id="tema-ac" aria-label="Görünüm ayarları">${ICON.palette}</button>
        <a class="icon-btn fav-link" href="/favoriler" aria-label="Favorilerim">${ICON.heart}<i class="fav-n" id="fav-n"></i></a>
        <a class="icon-btn" href="/uygulama" aria-label="Uygulama">${ICON.user}</a>
      </div>
    </div>
    <nav class="nav" aria-label="Ana menü"><div class="wrap" id="nav">
      ${nav('ana', '/', 'Vitrin')}${nav('kesfet', '/kesfet', 'Tüm oyunlar')}${nav('harita', '/harita', 'Harita')}${nav('takvim', '/takvim', 'Takvim')}${nav('bugun', '/kesfet?zaman=bugun', 'Bu akşam', 'hot')}
      <span id="nav-turler"></span><span class="sp"></span>
      ${nav('sahneler', '/kesfet?tur=sahneler', 'Sahneler')}${nav('toplulukler', '/kesfet?tur=topluluklar', 'Topluluklar')}
    </div></nav>
  </header>`;
  $('#ftr').outerHTML = `
  <footer class="ftr" id="ftr"><div class="wrap">
    <div class="ftr-grid">
      <div><a href="/" class="brand"><img src="/img/logo.png" alt=""><span>TİYATROL</span></a>
        <p class="muted" style="margin-top:14px;max-width:34ch">Türkiye'nin tiyatro oyunlarını, sahnelerini ve topluluklarını tek yerde buluşturan program rehberi.</p></div>
      <div><h4>Keşfet</h4><a href="/kesfet">Tüm oyunlar</a><a href="/kesfet?zaman=hafta">Bu hafta</a><a href="/harita">Harita</a><a href="/takvim">Takvim</a><a href="/kampanyalar">Kampanyalar</a><a href="/favoriler">Favorilerim</a><a href="/kesfet?tur=sahneler">Sahneler</a><a href="/kesfet?tur=topluluklar">Topluluklar</a></div>
      <div><h4>Destek</h4><a href="/yardim">Yardım</a><a href="/ayarlar">Ayarlar</a><a href="/uygulama">Mobil uygulama</a><a href="mailto:info@tiyatrol.com">İletişim</a></div>
      <div><h4>Kurumsal</h4><a href="/gizlilik">Gizlilik</a><a href="/sartlar">Kullanım şartları</a><a href="/yonetim">Yönetim</a></div>
    </div>
    <div class="ftr-ad" aria-hidden="true">TİYATROL</div>
    <div class="ftr-bot"><span>© ${new Date().getFullYear()} TiyatRol</span><span>Bilet satın alma uygulamada ya da organizatör sitesinde yapılır.</span></div>
  </div></footer>`;
  temaPaneli();
  ilSecici();
  const favSay = () => { const n = favListe().length; const e = $('#fav-n'); if (e) { e.textContent = n || ''; e.style.display = n ? '' : 'none'; } };
  favSay(); document.addEventListener('fav-degisti', favSay);
  aramaKur();
  yukle().then((d) => {
    $('#nav-turler').outerHTML = d.kategoriler.slice(0, 7).map((k) => `<a href="/kesfet?tur=${encodeURIComponent(k)}">${esc(k)}</a>`).join('');
  }).catch(() => {});
}

function temaPaneli() {
  const bg = document.createElement('div'); bg.className = 'drawer-bg';
  const d = document.createElement('aside'); d.className = 'drawer'; d.setAttribute('aria-label', 'Görünüm ayarları');
  document.body.append(bg, d);
  const ciz = () => {
    const s = temaOku();
    d.innerHTML = `<h3>Görünüm</h3><p class="muted">Seçimin bu tarayıcıda hatırlanır.</p>
    <div class="grp"><b>Mod</b><div class="seg" role="group">
      ${[['sistem', 'Sistem'], ['gunduz', 'Gündüz'], ['gece', 'Gece']].map(([k, a]) => `<button data-mod="${k}" class="${s.mod === k ? 'on' : ''}">${a}</button>`).join('')}</div></div>
    <div class="grp"><b>Renk paleti</b><div class="swatches">
      ${temaSecenekleri.map((p) => `<button class="sw ${s.palet === p.id ? 'on' : ''}" data-pal="${p.id}"><i style="background:${p.renk}"></i>${p.ad}</button>`).join('')}
      <button class="sw ${s.palet === 'ozel' ? 'on' : ''}" data-pal="ozel"><i style="background:${s.ozel}"></i>Özel renk</button></div>
      ${s.palet === 'ozel' ? `<input type="color" id="ozel" value="${s.ozel}" aria-label="Özel vurgu rengi" style="margin-top:10px">` : ''}</div>
    <div class="grp"><button class="btn btn-ghost btn-sm" id="tema-kapat">Kapat</button></div>`;
  };
  const ac = (v) => { ciz(); bg.classList.toggle('open', v); d.classList.toggle('open', v); };
  $('#tema-ac').addEventListener('click', () => ac(true));
  bg.addEventListener('click', () => ac(false));
  addEventListener('keydown', (e) => { if (e.key === 'Escape') ac(false); });
  d.addEventListener('click', (e) => {
    const m = e.target.closest('[data-mod]'), p = e.target.closest('[data-pal]');
    if (m) { temaYaz({ mod: m.dataset.mod }); ciz(); }
    if (p) { temaYaz({ palet: p.dataset.pal }); ciz(); }
    if (e.target.id === 'tema-kapat') ac(false);
  });
  d.addEventListener('input', (e) => { if (e.target.id === 'ozel') { temaYaz({ palet: 'ozel', ozel: e.target.value }); } });
}


function ilSecici() {
  const bg = document.createElement('div'); bg.className = 'il-bg'; bg.setAttribute('role', 'dialog'); bg.setAttribute('aria-label', 'İl seç');
  bg.innerHTML = '<div class="il-modal"><header><h3>Hangi ilde izlemek istersin?</h3><input type="search" id="il-ara" placeholder="İl ara…" autocomplete="off"><div style="display:flex;gap:10px;flex-wrap:wrap"><button class="btn btn-primary btn-sm" id="il-konum">Konumumu kullan</button><button class="btn btn-ghost btn-sm" id="il-hepsi">Tüm Türkiye</button><button class="btn btn-ghost btn-sm" id="il-kapat" style="margin-left:auto">Kapat</button></div></header><div class="il-liste" id="il-liste"></div></div>';
  document.body.append(bg);
  const guncelle = () => { $('#il-ad').textContent = ilOku() || 'Tüm Türkiye'; };
  const ciz = (q = '') => {
    const sayi = window.__ilSayilari || new Map(), sec = ilOku();
    const t = q.toLocaleLowerCase('tr');
    const l = ILLER.filter((i) => !t || i.ad.toLocaleLowerCase('tr').includes(t));
    const var_ = l.filter((i) => sayi.get(i.ad)), yok = l.filter((i) => !sayi.get(i.ad));
    const dugme = (i, bos) => `<button class="il-o ${sec === i.ad ? 'on' : ''} ${bos ? 'bos' : ''}" data-il="${i.ad}">${i.ad}${sayi.get(i.ad) ? `<small>${sayi.get(i.ad)} oyun</small>` : ''}</button>`;
    $('#il-liste').innerHTML = (var_.length ? `<h5>Programı olan iller</h5>${var_.map((i) => dugme(i)).join('')}` : '') + (yok.length ? `<h5>Diğer iller</h5>${yok.map((i) => dugme(i, true)).join('')}` : '');
  };
  const ac = async () => {
    bg.classList.add('open');
    try { const { yukle } = await import('./store.js'); const d = await yukle(); window.__ilSayilari = d.ilSayilari; } catch {}
    ciz(); $('#il-ara').value = ''; $('#il-ara').focus();
  };
  const kapat = () => bg.classList.remove('open');
  $('#il-btn').addEventListener('click', ac);
  bg.addEventListener('click', (e) => { if (e.target === bg) kapat(); const b = e.target.closest('[data-il]'); if (b) { ilYaz(b.dataset.il); guncelle(); kapat(); } });
  $('#il-kapat').addEventListener('click', kapat);
  $('#il-hepsi').addEventListener('click', () => { ilYaz(''); guncelle(); kapat(); });
  $('#il-ara').addEventListener('input', (e) => ciz(e.target.value));
  $('#il-konum').addEventListener('click', () => {
    if (!navigator.geolocation) return;
    $('#il-konum').textContent = 'Konum alınıyor…';
    navigator.geolocation.getCurrentPosition((p) => { const il = enYakinIl(p.coords.latitude, p.coords.longitude, 200); if (il) { ilYaz(il.ad); guncelle(); } kapat(); $('#il-konum').textContent = 'Konumumu kullan'; }, () => { $('#il-konum').textContent = 'Konum izni verilmedi'; }, { timeout: 9000 });
  });
  addEventListener('keydown', (e) => { if (e.key === 'Escape') kapat(); });
  document.addEventListener('il-degisti', guncelle);
}

function aramaKur() {
  const q = $('#q'), box = $('#suggest');
  const url = new URLSearchParams(location.search).get('q');
  if (url && location.pathname.startsWith('/kesfet')) q.value = url;
  const perde = document.createElement('div'); perde.className = 'arama-perde'; document.body.append(perde);
  const kapat = () => { box.classList.remove('open'); document.body.classList.remove('arama'); };
  perde.addEventListener('click', () => { kapat(); q.blur(); });
  // daktilo ipucu
  const ipuclari = ['Oyun ara…', 'Oyuncu ara…', 'Sahne ara…', 'Topluluk ara…', 'Komedi, dram, çocuk oyunu…'];
  let ii = 0, ci = 0, sil = false, tm;
  const yazIpucu = () => {
    if (document.activeElement === q || q.value) { tm = setTimeout(yazIpucu, 1200); return; }
    const m = ipuclari[ii];
    ci += sil ? -1 : 1;
    q.placeholder = m.slice(0, ci) + '│';
    let gec = sil ? 28 : 70;
    if (!sil && ci === m.length) { sil = true; gec = 1400; }
    else if (sil && ci === 0) { sil = false; ii = (ii + 1) % ipuclari.length; gec = 350; }
    tm = setTimeout(yazIpucu, gec);
  };
  if (!matchMedia('(prefers-reduced-motion: reduce)').matches) yazIpucu();
  const sonlar = () => { try { return JSON.parse(localStorage.getItem('tiyatrol.arama') || '[]'); } catch { return []; } };
  const sonYaz = (t) => { try { const l = [t, ...sonlar().filter((x) => x !== t)].slice(0, 5); localStorage.setItem('tiyatrol.arama', JSON.stringify(l)); } catch {} };
  let hl = -1;
  const ciz = debounce(async () => {
    const t = q.value.trim().toLocaleLowerCase('tr');
    document.body.classList.add('arama');
    let d; try { d = await yukle(); } catch { return; }
    const row = (kind, x, sub = '', img = x.imageUrl) => `<a href="${linkOf(kind, x)}">${img ? `<img src="${esc(img)}" alt="" loading="lazy">` : '<span class="ph"></span>'}<span>${esc(x.name)}<small>${esc(sub)}</small></span></a>`;
    if (t.length < 2) {
      const aktif = d.shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin').slice(0, 8);
      box.innerHTML = `<h5>Hızlı başla</h5><div class="sg-chips">${d.kategoriler.slice(0, 8).map((k) => `<a class="chip" href="/kesfet?tur=${encodeURIComponent(k)}">${esc(k)}</a>`).join('')}<a class="chip" href="/kesfet?zaman=bugun">Bu akşam</a><a class="chip" href="/kesfet?zaman=hafta">Bu hafta</a></div>`
        + (sonlar().length ? `<h5>Son aramaların</h5><div class="sg-chips">${sonlar().map((x) => `<a class="chip" href="/kesfet?q=${encodeURIComponent(x)}">${esc(x)}</a>`).join('')}</div>` : '')
        + (aktif.length ? `<h5>Şimdi sahnede</h5><div class="sg-row">${aktif.map((s) => `<a href="${linkOf('oyun', s)}">${s.imageUrl ? `<img src="${esc(s.imageUrl)}" alt="" loading="lazy">` : ''}<span>${esc(s.name)}</span></a>`).join('')}</div>` : '');
      box.classList.add('open'); hl = -1; return;
    }
    const eslesme = (a) => String(a || '').toLocaleLowerCase('tr').includes(t);
    const o = d.shows.filter((s) => s.state !== 'taslak' && (eslesme(s.name) || eslesme(s.cat))).slice(0, 6);
    const k = d.players.filter((p) => eslesme(p.fullName)).slice(0, 4);
    const s = d.stages.filter((x) => eslesme(x.name)).slice(0, 3);
    const tp = d.teams.filter((x) => eslesme(x.name)).slice(0, 3);
    const grp = (b, arr, f) => arr.length ? `<h5>${b}</h5><div class="sg-grid">${arr.map(f).join('')}</div>` : '';
    box.innerHTML = grp('Oyunlar', o, (x) => row('oyun', x, x.next ? `${tarihUzun(x.next.when)} · ${saat(x.next.when)}` : x.cat))
      + grp('Oyuncular', k, (x) => row('oyuncu', x))
      + grp('Sahneler', s, (x) => row('sahne', x, x.address))
      + grp('Topluluklar', tp, (x) => row('topluluk', x))
      || `<h5>“${esc(q.value)}” için sonuç yok</h5><div class="sg-chips"><a class="chip" href="/kesfet">Tüm oyunlara bak</a></div>`;
    box.classList.add('open'); hl = -1;
  }, 140);
  q.addEventListener('input', ciz);
  q.addEventListener('focus', ciz);
  q.closest('form').addEventListener('submit', () => { if (q.value.trim()) sonYaz(q.value.trim()); });
  q.addEventListener('keydown', (e) => {
    const items = $$('a', box);
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault(); hl = (hl + (e.key === 'ArrowDown' ? 1 : -1) + items.length) % (items.length || 1);
      items.forEach((a, i) => a.classList.toggle('hl', i === hl)); items[hl]?.scrollIntoView({ block: 'nearest' });
    } else if (e.key === 'Enter' && hl >= 0 && items[hl]) { e.preventDefault(); location.href = items[hl].href; }
    else if (e.key === 'Escape') { kapat(); q.blur(); }
  });
  addEventListener('keydown', (e) => { if (e.key === '/' && !/input|textarea|select/i.test(document.activeElement?.tagName || '')) { e.preventDefault(); q.focus(); } });
  document.addEventListener('click', (e) => { if (!e.target.closest('.search') && !e.target.closest('.arama-perde')) kapat(); });
}

export function bolumBasligi(baslik, alt = '', link = '', linkMetni = 'Tümü') {
  return `<div class="sec-head"><div><h2>${esc(baslik)}${squiggle}</h2>${alt ? `<p>${esc(alt)}</p>` : ''}</div>${link ? `<a class="link-more" href="${link}">${linkMetni} →</a>` : ''}</div>`;
}

export const DIS_IKON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/></svg>';
export const alanAdi = (u) => { try { return new URL(u).hostname.replace(/^www\./, ''); } catch { return ''; } };

export function oyunKarti(s, { rozet = '', fiyat = true } = {}) {
  const n = s.next;
  const dis = s.external;
  const alan = dis ? alanAdi(s.externalTicketUrl) : '';
  const sub = n ? `${tarihUzun(n.when)} · ${saat(n.when)}` : s.state === 'bitti' ? 'Sezon bitti' : s.cat;
  const bugunMu = n && ayniGun(n.when, new Date());
  const yeniMi = s._createdAt && (Date.now() - (tarihAyristir(s._createdAt) || 0)) < 14 * 864e5;
  const b = rozet || (s.state === 'bitti' ? 'Bitti' : s.state === 'vitrin' ? 'Vitrinde' : bugunMu ? 'Bugün' : (s.upcoming.length && s.upcoming.length <= 2 ? 'Son seanslar' : (yeniMi ? 'Yeni' : '')));
  const bSinif = s.state === 'bitti' ? 'dim' : (b === 'Yeni' ? 'yeni' : b === 'Son seanslar' ? 'son' : b === 'Bugün' ? 'bugun' : '');
  const fp = fiyat && s.minPrice != null ? `<div class="price">${tl(s.minPrice)}'den</div>` : '';
  const yildiz = s.ratingCount ? `<span class="yildiz" title="${s.ratingAvg.toFixed(1)} / 5 (${s.ratingCount} yorum)">★ ${s.ratingAvg.toFixed(1)}</span>` : '';
  const ERIS = { AD: ['Sesli betimleme', '#2563eb'], CAP: ['Altyazılı', '#7c3aed'], BSL: ['İşaret dili', '#dc2626'], R: ['Rahat gösterim', '#16a34a'], TS: ['İşaret dili', '#dc2626'] };
  const eris = (s.accessKodlari || []).filter((k) => ERIS[k]).map((k) => `<span class="er" style="background:${ERIS[k][1]}" title="${ERIS[k][0]}">${k}</span>`).join('');
  const disSatir = dis ? `<div class="sub-dis">${DIS_IKON}Bilet: ${esc(alan || 'başka platform')}</div>` : '';
  return `<article class="card"><a class="card-a" href="${linkOf('oyun', s)}" aria-label="${esc(s.name)}">
    <div class="pic">${resim(afis(s), s.name)}${b ? `<span class="badge ${bSinif}">${esc(b)}</span>` : ''}${eris ? `<span class="er-grup">${eris}</span>` : ''}${dis ? `<span class="dis" title="Bu oyunun biletleri başka bir platformda satılıyor">${DIS_IKON}<span>Biletler ${esc(alan || 'başka platformda')}</span></span>` : ''}</div>
    <h3>${esc(s.name)}</h3><div class="sub">${esc(sub)} ${yildiz}</div>${disSatir || fp}</a>${kalpDugme(s.id)}</article>`;
}

export function ray(htmlKartlar) {
  const id = 'r' + Math.random().toString(36).slice(2, 7);
  setTimeout(() => {
    const r = document.getElementById(id); if (!r) return;
    const git = (y) => r.scrollBy({ left: y * r.clientWidth * .8, behavior: 'smooth' });
    r.parentElement.querySelector('.l')?.addEventListener('click', () => git(-1));
    r.parentElement.querySelector('.r')?.addEventListener('click', () => git(1));
  });
  return `<div class="rail-wrap"><button class="rail-btn l" aria-label="Geri">${ICON.left}</button><div class="rail" id="${id}">${htmlKartlar}</div><button class="rail-btn r" aria-label="İleri">${ICON.right}</button></div>`;
}

export const kisi = (p) => `<a class="person" href="${linkOf('oyuncu', p)}"><div class="flower">${p.imageUrl ? `<img src="${esc(p.imageUrl)}" alt="${esc(p.fullName)}" loading="lazy">` : esc(baslangic(p.fullName))}</div><b>${esc(p.fullName)}</b></a>`;

export function kelimeKelime(metin) {
  return String(metin).split(/\s+/).map((w, i) => `<span class="w" style="animation-delay:${Math.min(i * 70, 700)}ms">${esc(w)}</span>`).join(' ');
}

export const iskelet = (n = 6) => Array.from({ length: n }, () => '<div class="card"><div class="pic skel"></div></div>').join('');
export const hataKutusu = (m) => `<div class="err"><b>Veriler yüklenemedi.</b><p class="muted">${esc(m || 'İnternet bağlantını kontrol edip sayfayı yenile.')}</p></div>`;
export { kisalt };

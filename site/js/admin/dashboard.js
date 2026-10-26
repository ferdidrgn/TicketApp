// Yönetim paneli — "Genel bakış" DASHBOARD'u: KPI kartları + satır içi SVG grafikler (harici kütüphane yok).
// Veri: adminStats callable (yalnız admin; sunucuda denetlenir). Maliyet notu: docs/BILDIRIM-ISTATISTIK.md
// Renkler tema değişkenlerinden gelir (--accent, --ink-*, --line...) -> tema değişince grafikler de değişir.
import { fonksiyon } from '../firebase.js';
import { $, $$, esc, debounce } from '../util.js';

const AY = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
const AY_UZUN = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const sayi = (n) => (n == null ? '—' : Number(n).toLocaleString('tr-TR'));
const yuzde = (r) => (r == null ? '—' : `%${Math.round(r * 100)}`);
const ayAdi = (mk, uzun) => `${(uzun ? AY_UZUN : AY)[+mk.slice(5, 7) - 1]}${uzun || mk.slice(5, 7) === '01' ? ` ${mk.slice(0, 4)}` : ''}`;
const istanbulAy = () => new Date(Date.now() + 3 * 3600e3).toISOString().slice(0, 7);
const sonAylar = () => { const [y, m] = istanbulAy().split('-').map(Number); return Array.from({ length: 12 }, (_, i) => { const d = new Date(Date.UTC(y, m - 1 - i, 1)); return d.toISOString().slice(0, 7); }); };
const nice = (max) => { if (max <= 4) return 4; const p = 10 ** Math.floor(Math.log10(max)); for (const k of [1, 2, 2.5, 5, 10]) if (k * p >= max) return k * p; return max; };

// ---- SVG grafikleri (genişlik = kapsayıcı genişliği; telefonda okunur kalır)
function eksen(w, h, pad, ust) {
  let s = '';
  for (let i = 0; i <= 4; i++) {
    const y = pad.t + ((h - pad.t - pad.b) * i) / 4;
    s += `<line class="ch-grid" x1="${pad.l}" x2="${w - pad.r}" y1="${y}" y2="${y}"/><text class="ch-txt" x="${pad.l - 6}" y="${y + 4}" text-anchor="end">${sayi(Math.round((ust * (4 - i)) / 4))}</text>`;
  }
  return s;
}
function xEtiket(w, pad, n, etiket, mod, h) {
  const iw = w - pad.l - pad.r, adim = Math.max(1, Math.ceil(n / Math.max(2, Math.floor(iw / 38))));
  let s = '';
  for (let i = 0; i < n; i += adim) s += `<text class="ch-txt" x="${pad.l + (mod === 'bar' ? ((i + 0.5) * iw) / n : n === 1 ? iw / 2 : (i * iw) / (n - 1))}" y="${h - 6}" text-anchor="middle">${esc(etiket(i))}</text>`;
  return s;
}
/** Sütun grafiği. veri: [{e: etiket, v: sayı, t: açıklama}] */
function sutun(host, veri, { ad, h = 190 }) {
  const w = Math.max(240, host.clientWidth || 320), pad = { l: 38, r: 6, t: 10, b: 24 };
  const max = nice(Math.max(1, ...veri.map((d) => d.v))), iw = w - pad.l - pad.r, ih = h - pad.t - pad.b, bw = Math.max(2, (iw / veri.length) * 0.68);
  let g = eksen(w, h, pad, max);
  veri.forEach((d, i) => {
    const bh = (d.v / max) * ih, x = pad.l + ((i + 0.5) * iw) / veri.length - bw / 2;
    g += `<rect class="ch-bar" data-i="${i}" x="${x.toFixed(1)}" y="${(pad.t + ih - bh).toFixed(1)}" width="${bw.toFixed(1)}" height="${Math.max(d.v > 0 ? 1.5 : 0, bh).toFixed(1)}" rx="2"/>`;
  });
  g += xEtiket(w, pad, veri.length, (i) => veri[i].e, 'bar', h);
  host.innerHTML = `<svg class="ch-svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img" aria-label="${esc(ad)}">${g}</svg><div class="ch-read" aria-live="polite">${esc(veri.length ? 'Ayrıntı için çubuğa dokun.' : 'Veri yok.')}</div>`;
  okuma(host, veri, (svg, ev) => { const r = svg.getBoundingClientRect(); return Math.floor(((ev.clientX - r.left - pad.l) / iw) * veri.length); });
}
/** Çizgi grafiği. seriler: [{ad, d: [sayı]}], etiket: i -> metin */
function cizgi(host, seri, etiket, { ad, h = 190 }) {
  const n = seri.length, w = Math.max(240, host.clientWidth || 320), pad = { l: 38, r: 12, t: 10, b: 24 };
  const max = nice(Math.max(1, ...seri.map((d) => d.v))), iw = w - pad.l - pad.r, ih = h - pad.t - pad.b;
  const px = (i) => pad.l + (n === 1 ? iw / 2 : (i * iw) / (n - 1)), py = (v) => pad.t + ih - (v / max) * ih;
  const pts = seri.map((d, i) => `${px(i).toFixed(1)},${py(d.v).toFixed(1)}`);
  let g = eksen(w, h, pad, max);
  g += `<polygon class="ch-area" points="${px(0).toFixed(1)},${pad.t + ih} ${pts.join(' ')} ${px(n - 1).toFixed(1)},${pad.t + ih}"/><polyline class="ch-line" points="${pts.join(' ')}"/>`;
  seri.forEach((d, i) => { g += `<circle class="ch-dot" data-i="${i}" cx="${px(i).toFixed(1)}" cy="${py(d.v).toFixed(1)}" r="${i === n - 1 ? 4.5 : 3}"/>`; });
  g += xEtiket(w, pad, n, etiket, 'line', h);
  host.innerHTML = `<svg class="ch-svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img" aria-label="${esc(ad)}">${g}</svg><div class="ch-read" aria-live="polite">Ayrıntı için grafiğe dokun.</div>`;
  okuma(host, seri, (svg, ev) => { const r = svg.getBoundingClientRect(); return Math.round(((ev.clientX - r.left - pad.l) / iw) * (n - 1)); });
}
function okuma(host, veri, idxOf) {
  const svg = $('svg', host), out = $('.ch-read', host);
  const goster = (ev) => {
    const i = Math.max(0, Math.min(veri.length - 1, idxOf(svg, ev)));
    if (!veri[i]) return;
    $$('[data-i]', svg).forEach((el) => el.classList.toggle('on', +el.dataset.i === i));
    out.textContent = veri[i].t || `${veri[i].e}: ${sayi(veri[i].v)}`;
  };
  svg.addEventListener('pointermove', goster); svg.addEventListener('pointerdown', goster);
}
const yatay = (satirlar, { bos = 'Veri yok.', fmt = sayi } = {}) => {
  if (!satirlar.length) return `<p class="muted">${esc(bos)}</p>`;
  const max = Math.max(1, ...satirlar.map((s) => s.v));
  return `<div class="hb-list">${satirlar.map((s) => `<div class="hb"><span class="hb-l" title="${esc(s.e)}">${esc(s.e)}</span><span class="hb-t"><i style="width:${Math.max(2, (s.v / max) * 100).toFixed(1)}%"></i></span><b>${esc(s.g || fmt(s.v))}</b></div>`).join('')}</div>`;
};

export function dashboard(m, { veri, bildir, hataMesaji }) {
  const st = { ay: istanbulAy(), oyun: '', veri: null, yukleniyor: false };
  const onbellek = new Map(); // ay -> {t, r}; 2 dk içinde tekrar sorgulanmaz (maliyet)
  m.innerHTML = `<div class="adm-top"><h1>Genel bakış</h1>
      <div class="dash-tools"><label class="sr-only" for="d-ay">Ay</label><select class="in" id="d-ay" aria-label="Ay">${sonAylar().map((a) => `<option value="${a}">${ayAdi(a, true)}</option>`).join('')}</select>
      <button class="btn btn-ghost btn-sm" id="d-yenile">Yenile</button></div></div>
    <div id="d-icerik" aria-live="polite"><div class="skel" style="height:120px"></div></div>`;
  $('#d-ay', m).addEventListener('change', (e) => { st.ay = e.target.value; yukle(); });
  $('#d-yenile', m).addEventListener('click', () => yukle(true));

  async function yukle(zorla) {
    const k = $('#d-icerik', m);
    const o = onbellek.get(st.ay);
    if (!zorla && o && Date.now() - o.t < 120000) { st.veri = o.r; return ciz(); }
    k.innerHTML = '<div class="skel" style="height:120px"></div><div class="skel" style="height:220px;margin-top:16px"></div>';
    try {
      const f = await fonksiyon('adminStats');
      const r = (await f({ month: st.ay })).data;
      onbellek.set(st.ay, { t: Date.now(), r }); st.veri = r;
      ciz();
    } catch (e) { k.innerHTML = `<div class="bk-alert" role="alert">İstatistikler alınamadı: ${esc(hataMesaji(e))}</div>`; }
  }

  function kart(deger, ad, ipucu, sinif = '') {
    return `<div class="kpi ${sinif}"><b>${esc(deger)}</b><span>${esc(ad)}</span>${ipucu ? `<small>${esc(ipucu)}</small>` : ''}</div>`;
  }

  function ciz() {
    const r = st.veri, k = $('#d-icerik', m), K = r.kpi;
    const seansGelecek = r.sessions.filter((s) => s.ms != null && s.ms >= r.generatedAt - 3600e3);
    k.innerHTML = `
      <div class="kpis">
        ${kart(sayi(K.viewsMonth), 'Görüntülenme', `${ayAdi(r.month, true)} · oyun sayfası ${sayi(K.showViewsMonth)}`)}
        ${kart(sayi(K.reservations.month), 'Rezervasyon (bu ay)', `toplam aktif ${sayi(K.reservations.total)} · iptaller hariç`)}
        ${kart(sayi(K.freeTickets.month), 'Ücretsiz bilet (bu ay)', `toplam aktif ${sayi(K.freeTickets.total)}`)}
        ${kart(sayi(K.upcomingSessions), 'Yaklaşan seans', `${sayi(K.activeShows)} aktif oyun`)}
        ${kart(yuzde(K.cancelRate), 'İptal oranı', `${sayi(K.cancelled)} iptal / ${sayi(K.ticketsAllTime)} bilet (tüm zamanlar)`, K.cancelRate > 0.25 ? 'warn' : '')}
        ${kart(yuzde(K.noShowRate), 'Gelmeme oranı', `${sayi(K.noShow)} bilet "gelmedi"`, K.noShowRate > 0.2 ? 'warn' : '')}
        ${kart(sayi(K.checkedIn), 'Kapıdan geçen', `aktif biletlerin ${yuzde(K.checkInRate)}`)}
        ${kart(yuzde(K.conversion), 'Görüntülenme → bilet', 'bu ay oluşan bilet / oyun sayfası görüntülenmesi')}
      </div>
      <div class="dash-grid">
        <section class="bk-card"><h2>Günlük görüntülenme</h2><div id="c-gun"></div></section>
        <section class="bk-card"><div class="ch-head"><h2>Aylık trend</h2><select class="in" id="d-oyun" aria-label="Oyun seç"><option value="">Tüm içerik</option>${r.trend.shows.map((s) => `<option value="${esc(s.showId)}" ${st.oyun === s.showId ? 'selected' : ''}>${esc(s.name)}</option>`).join('')}</select></div><div id="c-trend"></div></section>
        <section class="bk-card"><h2>En çok görüntülenen oyunlar</h2>${yatay(r.topShows.filter((s) => s.views > 0).slice(0, 8).map((s) => ({ e: s.name, v: s.views })), { bos: 'Bu ay henüz görüntülenme yok.' })}</section>
        <section class="bk-card"><h2>Seans doluluğu</h2>${yatay(seansGelecek.filter((s) => s.occupancy != null).slice(0, 10).map((s) => ({ e: `${s.show || 'Oyun'} · ${s.ms ? new Date(s.ms).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', timeZone: 'Europe/Istanbul' }) : ''}`, v: s.occupancy, g: `%${Math.round(s.occupancy * 100)} (${s.seatsSold}/${s.seatsTotal})` })), { bos: 'Koltuk düzeni oluşmuş yaklaşan seans yok.' })}</section>
        <section class="bk-card dash-wide"><h2>Oyunlar</h2>${oyunTablo(r)}</section>
        <section class="bk-card"><h2>Mekân sıralaması</h2>${yatay(r.venues.map((v) => ({ e: v.name, v: v.seatsSold, g: `${v.seatsSold} koltuk · ${v.occupancy == null ? '—' : yuzde(v.occupancy)}` })), { bos: 'Mekân verisi yok.' })}</section>
        <section class="bk-card"><h2>Öne çıkanlar (bu ay)</h2><h3 class="dash-h3">Mekânlar</h3>${yatay(r.topStages.slice(0, 5).map((x) => ({ e: x.name, v: x.views })), { bos: 'Henüz yok.' })}<h3 class="dash-h3">Oyuncular</h3>${yatay(r.topPlayers.slice(0, 5).map((x) => ({ e: x.name, v: x.views })), { bos: 'Henüz yok.' })}</section>
      </div>
      <p class="muted dash-note">Görüntülenme sayaçları çerezsiz ve kimliksizdir (yalnız toplu sayı). Veri ${new Date(r.generatedAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })} itibarıyla; ${sayi(r.limits.events)} seans okundu.</p>`;
    $('#d-oyun', m).addEventListener('change', (e) => { st.oyun = e.target.value; trend(); });
    gun(); trend();
  }

  function oyunTablo(r) {
    if (!r.topShows.length) return '<p class="muted">Henüz oyun verisi yok.</p>';
    return `<div class="tbl-wrap"><table class="tbl"><thead><tr><th>Oyun</th><th>Görüntülenme</th><th>Bilet</th><th>Bu ay bilet</th><th>Dönüşüm</th><th>Yaklaşan</th><th>Doluluk</th></tr></thead><tbody>
      ${r.topShows.map((s) => `<tr><td>${esc(s.name)}</td><td>${sayi(s.views)}</td><td>${sayi(s.tickets)}</td><td>${sayi(s.ticketsMonth)}</td><td>${yuzde(s.conversion)}</td><td>${sayi(s.upcoming)}</td><td>${s.occupancy == null ? '—' : `${yuzde(s.occupancy)} <span class="muted">(${s.seatsSold}/${s.seatsTotal})</span>`}</td></tr>`).join('')}</tbody></table></div>
      ${r.limits.showRowsCapped ? '<p class="muted dash-note">Maliyeti düşük tutmak için en çok görüntülenen 20 oyun gösteriliyor.</p>' : ''}`;
  }

  function gun() {
    const r = st.veri, host = $('#c-gun', m);
    if (!host) return;
    const [y, mo] = r.month.split('-').map(Number), gunSayisi = new Date(y, mo, 0).getDate();
    const harita = new Map(r.days.map((d) => [d.day, d.views]));
    const veriG = Array.from({ length: gunSayisi }, (_, i) => { const dk = `${r.month}-${String(i + 1).padStart(2, '0')}`; const v = harita.get(dk) || 0; return { e: String(i + 1), v, t: `${i + 1} ${AY_UZUN[mo - 1]}: ${sayi(v)} görüntülenme` }; });
    sutun(host, veriG, { ad: `${ayAdi(r.month, true)} günlük görüntülenme` });
  }
  function trend() {
    const r = st.veri, host = $('#c-trend', m);
    if (!host) return;
    const s = st.oyun ? r.trend.shows.find((x) => x.showId === st.oyun) : null;
    const d = (s ? s.values : r.trend.total).map((v, i) => ({ v, e: ayAdi(r.trend.months[i]), t: `${ayAdi(r.trend.months[i], true)}: ${sayi(v)} görüntülenme` }));
    cizgi(host, d, (i) => ayAdi(r.trend.months[i]), { ad: `Aylık görüntülenme trendi${s ? ` — ${s.name}` : ''}` });
  }
  const yenidenCiz = debounce(() => { if (st.veri && $('#c-gun', m)) { gun(); trend(); } }, 150);
  window.addEventListener('resize', yenidenCiz);
  const izle = new MutationObserver(() => { if (!document.body.contains(m) || !$('#d-ay', m)) { window.removeEventListener('resize', yenidenCiz); izle.disconnect(); } });
  izle.observe(m, { childList: true });
  yukle();
}

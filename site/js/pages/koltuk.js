// Koltuk seçimi: /koltuk/<eventId>
// Salon planı (Seats/{stageId}) + koltuk durumları (Event.seats) CANLI dinlenir. İstemci yalnızca seçim yapar;
// tutma / ödeme / onay Cloud Functions'tadır. İstemci ASLA fiyat/tutar göndermez, Event/Ticket'a doğrudan yazmaz.
// 3 koltuk sınırı istemcide yalnızca KOLAYLIKTIR; asıl sınır sunucudadır.
import { kabukCiz, resim } from '../ui.js';
import { yukle } from '../store.js';
import { db, doc, onSnapshot, getDoc, collection, query, where } from '../firebase.js';
import { girisGerekli, oturumDinle, oturumBekle, mevcut } from '../auth.js';
import { koltukTut, tutmaBirak, odemeBaslat, ucretsizOnayla, guvenliUrl, rezervasyonOnayla, satisAyari } from '../bilet-api.js';
import { $, $$, esc, tl, sayi, tarihUzun, saat, tarihAyristir, linkOf } from '../util.js';

const EID = decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() || '');
const LIMIT = 3;
const ADMIN_BLOK = '__ADMIN_BLOCKED__'; // ESKİ yönetici bloğu işareti (kimlik değil); yeni biçim status:'blocked'
const HOLD_MS = 10 * 60 * 1000;
const SAAT_TOLERANSI = 3000; // istemci saati sapmasına karşı: süresi bu kadar geçmeden 'boş' gösterme
const SURE_VARSAYILAN = 600;
const HALKA = 2 * Math.PI * 22;

const S = {
  ev: null, show: null, stage: null,
  duzen: null, koltuklar: {}, seatsBos: true,
  secili: [], adim: 'sec', hold: null, bekliyor: false,
  mesaj: '', banner: null, iframe: '', zaman: null, dugme: new Map(), satirlar: [], konum: new Map(), odak: '', z: 1,
  duzenHazir: false, siparisAbone: null,
  satis: { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 },
  siparisler: [], benim: new Set(), yoksay: new Set(), siparislerAbone: null, siparislerUid: '',
};

kabukCiz('kesfet');
const kok = $('#icerik');
const yaz = (html) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = html; };
const bosEkran = (b, m, link = '<a class="btn btn-primary" href="/kesfet">Oyunlara dön</a>') =>
  yaz(`<div class="empty" style="margin-top:48px"><h3>${esc(b)}</h3><p>${esc(m)}</p><p style="margin-top:16px">${link}</p></div>`);

const ucretsizMi = () => {
  const p = S.ev?.price;
  if (p == null || p === '') return false;
  return /^\s*(ücretsiz|free)\s*$/i.test(String(p)) || sayi(p) === 0;
};
/** Ücretli etkinlikte satış kapalı mı? (ücretsiz biletler her modda çalışır) */
const satisKapali = () => S.satis.mode === 'kapali' && !(S.hold ? S.hold.free : ucretsizMi());
const kartAcik = () => S.satis.mode === 'online';
const sahneAcik = () => S.satis.mode === 'rezervasyon';
const fiyat = () => sayi(S.ev?.price);
const para = (n) => (n === 0 ? 'Ücretsiz' : tl(n));
const benimUid = () => mevcut()?.uid || '';
const zamanMs = (v) => (v?.toMillis ? v.toMillis() : typeof v === 'number' ? v : Date.parse(v) || 0);
const seansGecti = () => !!(S.when && S.when < new Date());

function canli(m) { const e = $('#canli'); if (e) { e.textContent = ''; setTimeout(() => { e.textContent = m; }, 30); } }
let toastT;
function bildir(m, tur = 'hata') {
  S.mesaj = m; canli(m);
  let t = $('#k-toast');
  if (!t) { t = document.createElement('div'); t.id = 'k-toast'; t.className = 'k-toast'; t.setAttribute('role', 'status'); document.body.append(t); }
  t.textContent = m; t.className = `k-toast on ${tur}`;
  clearTimeout(toastT); toastT = setTimeout(() => { t.classList.remove('on'); }, 4800);
  panelCiz();
}

// ---------- Salon düzeni ----------
const ayir = (id) => {
  const m = /^(.*?)(\d+)$/.exec(id);
  return m ? [m[1].trim().replace(/[\s\-_.:]+$/, ''), +m[2]] : ['', NaN];
};
function duzenKur(sd, esMap) {
  const META = new Set(['closedSeatsId', '_id', '_createdAt', '_updatedAt']);
  const kapali = new Set((Array.isArray(sd?.closedSeatsId) ? sd.closedSeatsId : []).map(String));
  const grup = new Map();
  const ekle = (etiket, id) => { if (!grup.has(etiket)) grup.set(etiket, []); grup.get(etiket).push(id); };
  if (sd && Array.isArray(sd.seatsId)) sd.seatsId.filter((x) => typeof x === 'string' && x).forEach((id) => ekle(ayir(id)[0], id));
  else if (sd) for (const [k, v] of Object.entries(sd)) { if (!META.has(k) && Array.isArray(v)) v.filter((x) => typeof x === 'string' && x).forEach((id) => ekle(k, id)); }
  if (!grup.size) Object.keys(esMap || {}).forEach((id) => ekle(ayir(id)[0], id));
  const anahtarlar = [...grup.keys()].sort((a, b) => a.length - b.length || a.localeCompare(b, 'tr', { numeric: true }));
  let satirlar = anahtarlar.map((k) => ({
    ad: k,
    koltuklar: grup.get(k).map((id) => ({ id, num: ayir(id)[1] })).sort((a, b) => (isNaN(a.num) || isNaN(b.num) ? 0 : a.num - b.num)),
  }));
  // etiketsiz (numaralandırılamayan) düzen: 12'şerli sıralara böl
  if (satirlar.length === 1 && satirlar[0].ad === '' && satirlar[0].koltuklar.length > 14) {
    const hepsi = satirlar[0].koltuklar; satirlar = [];
    for (let i = 0; i < hepsi.length; i += 12) satirlar.push({ ad: String(i / 12 + 1), koltuklar: hepsi.slice(i, i + 12) });
  }
  return { satirlar, kapali };
}

// ---------- Koltuk durumu ----------
function durum(id) {
  if (S.duzen?.kapali.has(id)) return 'kapali';
  const m = S.koltuklar[id];
  if (!m) return S.seatsBos ? 'bos' : 'kapali';
  // Event herkese açık okunur ve kullanıcı kimliği İÇERMEZ. "Benim" tespiti kullanıcının KENDİ Order belgelerinden gelir.
  switch (m.status) {
    case 'available': return 'bos';
    case 'reserved':
      if (S.benim.has(id)) return 'benim';
      return holdBitti(m) ? 'bos' : 'rezerve'; // süresi dolmuş tutma: sunucu da bu koltuğu verir (lazy takeover)
    case 'sold': return m.customerId === ADMIN_BLOK ? 'kapali' : 'dolu';
    case 'blocked': return 'kapali';
    default: return 'kapali';
  }
}
function holdBitti(m) {
  const bitis = typeof m.holdExpiresAt === 'number' ? m.holdExpiresAt : (zamanMs(m.reservedAt) ? zamanMs(m.reservedAt) + HOLD_MS : 0);
  return bitis > 0 ? bitis + SAAT_TOLERANSI < Date.now() : true;
}
/** Kullanıcının bu seanstaki canlı (held/paying, süresi dolmamış) siparişleri -> 'benim' koltuk kümesi. */
function benimKur() {
  const set = new Set();
  for (const o of S.siparisler) {
    if (!['held', 'paying'].includes(o.status) || S.yoksay.has(o.id)) continue;
    if (zamanMs(o.expiresAt) + SAAT_TOLERANSI < Date.now()) continue;
    (o.seatIds || []).forEach((x) => set.add(String(x)));
  }
  S.benim = set;
}
const DURUM_METNI = { bos: 'boş', secili: 'seçili', benim: 'senin için tutuluyor', dolu: 'dolu', rezerve: 'başkası için tutuluyor', kapali: 'satışa kapalı' };
const koltukAdi = (id) => { const [r, n] = ayir(id); return r && !isNaN(n) ? `Sıra ${r}, koltuk ${n}` : id; };

function boya() {
  const sinir = S.adim === 'sec' && S.secili.length >= LIMIT;
  for (const [id, el] of S.dugme) {
    let c = durum(id);
    if (S.hold?.seatIds.includes(id)) c = 'benim';
    else if (c === 'bos' && S.secili.includes(id)) c = 'secili';
    else if (c === 'benim' && !S.hold) c = 'benim';
    const sinifi = `koltuk ${c}${sinir && c === 'bos' ? ' sinir' : ''}`;
    if (el.className.replace(/ salla/, '') !== sinifi) el.className = sinifi;
    el.setAttribute('aria-pressed', c === 'secili' || c === 'benim' ? 'true' : 'false');
    el.setAttribute('aria-disabled', ['dolu', 'rezerve', 'kapali'].includes(c) || S.adim !== 'sec' ? 'true' : 'false');
    el.setAttribute('aria-label', `${koltukAdi(id)}, ${DURUM_METNI[c]}`);
  }
  // başkası alırsa seçimden düşür
  const dusen = S.secili.filter((id) => durum(id) !== 'bos');
  if (dusen.length && S.adim === 'sec' && !S.bekliyor) { // tutma sürerken kendi koltuklarımız 'rezerve' görünebilir
    S.secili = S.secili.filter((id) => !dusen.includes(id));
    bildir(`${dusen.join(', ')} az önce başka biri tarafından alındı. Seçimden çıkarıldı.`);
  }
  const say = $('#k-say');
  if (say) say.textContent = `${S.hold ? S.hold.seatIds.length : S.secili.length} / ${LIMIT} koltuk`;
}

function planCiz() {
  const { satirlar } = S.duzen;
  S.dugme.clear(); S.satirlar = []; S.konum.clear();
  const html = satirlar.map((s, r) => {
    const ids = [];
    let onceki = null;
    const hucre = s.koltuklar.map((k) => {
      ids.push(k.id);
      const bosluk = onceki != null && !isNaN(k.num) && k.num - onceki > 1 ? '<span class="bosluk" aria-hidden="true"></span>' : '';
      onceki = isNaN(k.num) ? onceki : k.num;
      return `${bosluk}<button type="button" class="koltuk bos" data-id="${esc(k.id)}" tabindex="-1"><span>${esc(isNaN(k.num) ? k.id : k.num)}</span></button>`;
    }).join('');
    S.satirlar.push(ids); ids.forEach((id, c) => S.konum.set(id, [r, c]));
    return `<div class="satir" role="group" aria-label="${s.ad ? `Sıra ${esc(s.ad)}` : 'Koltuklar'}"><span class="satir-ad" aria-hidden="true">${esc(s.ad)}</span>${hucre}<span class="satir-ad" aria-hidden="true">${esc(s.ad)}</span></div>`;
  }).join('');
  $('#planic').innerHTML = `<div class="sahne-isaret" aria-hidden="true">SAHNE</div><div class="satirlar">${html}</div>`;
  $$('#planic .koltuk').forEach((el) => S.dugme.set(el.dataset.id, el));
  const ilk = [...S.dugme.keys()].find((id) => durum(id) === 'bos') || [...S.dugme.keys()][0];
  if (ilk) { S.odak = ilk; S.dugme.get(ilk).tabIndex = 0; }
  sigdir();
  boya();
}

const zSinir = (z) => Math.min(2, Math.max(0.45, z));
function zoom(z, yumusak = false) {
  S.z = zSinir(z);
  const ic = $('#planic'); if (!ic) return;
  ic.style.setProperty('--z', S.z.toFixed(3));
  const o = $('#zoom-oran'); if (o) o.textContent = `${Math.round(S.z * 100)}%`;
  void yumusak;
}
function sigdir() {
  const gorus = $('#gorus'), ic = $('#planic'); if (!gorus || !ic) return;
  ic.style.setProperty('--z', '1');
  const genis = ic.scrollWidth, alan = gorus.clientWidth - 24;
  const mobil = innerWidth <= 960;
  zoom(Math.min(1.25, Math.max(mobil ? 0.8 : 0.6, alan / genis)));
  gorus.scrollLeft = Math.max(0, (gorus.scrollWidth - gorus.clientWidth) / 2);
}

// ---------- Seçim ----------
async function sec(id) {
  if (S.adim !== 'sec' || S.bekliyor || seansGecti()) return;
  if (!mevcut()) { const u = await girisGerekli('Koltuk seçmek için giriş yap.'); if (!u) return; boya(); }
  const d = durum(id);
  const varMi = S.secili.includes(id);
  if (!varMi && d !== 'bos') { bildir(`${koltukAdi(id)} ${DURUM_METNI[d]}.`, 'bilgi'); return; }
  if (varMi) S.secili = S.secili.filter((x) => x !== id);
  else if (S.secili.length >= LIMIT) {
    const el = S.dugme.get(id);
    el.classList.remove('salla'); void el.offsetWidth; el.classList.add('salla');
    bildir(`Bir etkinlik için en fazla ${LIMIT} koltuk seçebilirsin. Önce seçtiklerinden birini kaldır.`, 'bilgi');
    return;
  } else S.secili = [...S.secili, id];
  S.mesaj = '';
  boya(); panelCiz();
  canli(varMi ? `${koltukAdi(id)} seçimden çıkarıldı.` : `${koltukAdi(id)} seçildi. ${S.secili.length} koltuk seçili.`);
}

function oklarla(e) {
  const t = e.target.closest('.koltuk'); if (!t) return;
  const tus = e.key;
  if (tus === 'Enter' || tus === ' ') { e.preventDefault(); sec(t.dataset.id); return; }
  const [r, c] = S.konum.get(t.dataset.id) || [0, 0];
  let hedef = null;
  const satir = S.satirlar[r];
  if (tus === 'ArrowRight') hedef = satir[Math.min(satir.length - 1, c + 1)];
  else if (tus === 'ArrowLeft') hedef = satir[Math.max(0, c - 1)];
  else if (tus === 'Home') hedef = satir[0];
  else if (tus === 'End') hedef = satir[satir.length - 1];
  else if (tus === 'ArrowDown' || tus === 'ArrowUp') {
    const s2 = S.satirlar[r + (tus === 'ArrowDown' ? 1 : -1)];
    if (s2) hedef = s2[Math.min(s2.length - 1, Math.round((c / Math.max(1, satir.length - 1)) * (s2.length - 1)))];
  } else return;
  e.preventDefault();
  if (!hedef) return;
  S.dugme.get(S.odak).tabIndex = -1;
  S.odak = hedef; const el = S.dugme.get(hedef); el.tabIndex = 0; el.focus();
}

// ---------- Tutma / ödeme ----------
function tutmaKur(r) {
  const toplamSure = Math.max(30, Math.round((r.expiresAt - Date.now()) / 1000));
  S.hold = { paying: !!r.paying, orderId: r.orderId, expiresAt: r.expiresAt, total: r.total, currency: r.currency || 'TRY', free: !!r.free, seatIds: r.seatIds, seats: r.seats || [], toplamSure: Math.min(toplamSure, SURE_VARSAYILAN) };
  S.adim = 'tut'; S.secili = []; S.banner = null;
  sayacBaslat(); siparisDinle(r.orderId);
}
function tutmaTemizle() {
  if (S.hold) S.yoksay.add(S.hold.orderId);
  S.hold = null; S.iframe = '';
  clearInterval(S.zaman); S.zaman = null;
  S.siparisAbone?.(); S.siparisAbone = null;
}

async function tut() {
  if (S.bekliyor || S.adim !== 'sec') return;
  const u = await girisGerekli('Koltuk tutmak için giriş yap.');
  if (!u) return;
  if (!S.secili.length) return bildir('Önce en az bir koltuk seç.', 'bilgi');
  S.bekliyor = true; S.mesaj = ''; panelCiz();
  try {
    const r = await koltukTut(EID, S.secili);
    tutmaKur({
      orderId: r.orderId, expiresAt: Number(r.expiresAt), total: r.total, currency: r.currency, free: r.free,
      seatIds: (r.seats || []).map((x) => x.id), seats: r.seats,
    });
    canli(`Koltukların tutuldu. ${Math.round((S.hold.expiresAt - Date.now()) / 60000)} dakika içinde tamamlamalısın.`);
  } catch (e) {
    bildir(e.message);
    if (e.kod === 'failed-precondition') S.secili = S.secili.filter((id) => durum(id) === 'bos');
    if (e.kod === 'unauthenticated') girisGerekli('Oturumun kapanmış. Devam etmek için tekrar giriş yap.');
  } finally { S.bekliyor = false; boya(); panelCiz(); }
}

async function birak(sessiz = false) {
  if (!S.hold || S.bekliyor) return;
  const id = S.hold.orderId;
  S.bekliyor = true; panelCiz();
  try { await tutmaBirak(id); } catch (e) { if (!sessiz) console.warn('releaseHold', e.kod); }
  S.bekliyor = false;
  tutmaTemizle(); S.adim = 'sec'; boya(); panelCiz();
  if (!sessiz) canli('Koltuklar bırakıldı. Yeniden seçebilirsin.');
}

async function ode() {
  if (S.bekliyor || !S.hold) return;
  S.bekliyor = true; S.mesaj = ''; panelCiz();
  try {
    const r = await odemeBaslat(S.hold.orderId);
    if (r.paymentPageUrl) {
      const u = guvenliUrl(r.paymentPageUrl);
      if (!u) throw new Error('Ödeme sayfası doğrulanamadı. Biraz sonra tekrar dene.');
      S.adim = 'odeme'; panelCiz(); canli('Ödeme sayfasına yönlendiriliyorsun.');
      location.assign(u); return;
    }
    if (r.checkoutFormContent) {
      S.adim = 'odeme'; S.iframe = String(r.checkoutFormContent);
      S.bekliyor = false; panelCiz(); formKapsulu(); return;
    }
    throw new Error('Ödeme başlatılamadı. Biraz sonra tekrar dene.');
  } catch (e) { bildir(e.message); S.bekliyor = false; panelCiz(); }
}
// iyzico formu: kendi origin'imizden yalıtılmış (allow-same-origin YOK) sandbox iframe'de gösterilir.
function formKapsulu() {
  const k = $('#odeme-yer'); if (!k) return;
  const f = document.createElement('iframe');
  f.className = 'odeme-cerceve'; f.title = 'Güvenli ödeme formu';
  f.setAttribute('sandbox', 'allow-scripts allow-forms allow-popups allow-top-navigation');
  f.setAttribute('referrerpolicy', 'no-referrer');
  f.srcdoc = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><body style="margin:0;font-family:system-ui,sans-serif">${S.iframe}</body>`;
  k.replaceChildren(f);
}

async function onayla() {
  if (S.bekliyor || !S.hold) return;
  S.bekliyor = true; S.mesaj = ''; panelCiz();
  try {
    await ucretsizOnayla(S.hold.orderId);
    const id = S.hold.orderId; tutmaTemizle();
    location.assign(`/odeme-sonuc?order=${encodeURIComponent(id)}&durum=basarili`);
  } catch (e) { bildir(e.message); S.bekliyor = false; panelCiz(); }
}

async function rezerve() {
  if (S.bekliyor || !S.hold || !sahneAcik()) return;
  S.bekliyor = true; S.mesaj = ''; panelCiz();
  try {
    await rezervasyonOnayla(S.hold.orderId);
    const id = S.hold.orderId; tutmaTemizle();
    location.assign(`/odeme-sonuc?order=${encodeURIComponent(id)}&durum=rezervasyon`);
  } catch (e) {
    bildir(e.message); S.bekliyor = false; panelCiz();
    if (e.kod === 'unauthenticated') girisGerekli('Oturumun kapanmış. Devam etmek için tekrar giriş yap.');
  }
}

function sureDoldu() {
  if (!S.hold) return;
  if (S.adim === 'odeme') { location.assign(`/odeme-sonuc?order=${encodeURIComponent(S.hold.orderId)}`); return; }
  const id = S.hold.orderId;
  tutmaTemizle(); S.adim = 'sec'; S.secili = [];
  tutmaBirak(id).catch(() => {});
  S.banner = { tur: 'hata', baslik: 'Süre doldu', metin: 'Koltukların serbest bırakıldı. İstersen aynı koltukları ya da yenilerini tekrar seçebilirsin.' };
  boya(); panelCiz(); bannerCiz(); canli('Süre doldu. Koltukların serbest bırakıldı.');
  scrollTo({ top: 0, behavior: 'smooth' });
}

function siparisDinle(orderId) {
  S.siparisAbone?.();
  S.siparisAbone = onSnapshot(doc(db, 'Order', orderId), (s) => {
    if (!s.exists() || !S.hold || S.hold.orderId !== orderId) return;
    const st = s.data().status;
    if (st === 'paid' || st === 'free_confirmed') { tutmaTemizle(); location.assign(`/odeme-sonuc?order=${encodeURIComponent(orderId)}&durum=basarili`); }
    else if (st === 'expired' || st === 'cancelled') sureDoldu();
    else if (!['held', 'paying', 'failed'].includes(st)) { tutmaTemizle(); location.assign(`/odeme-sonuc?order=${encodeURIComponent(orderId)}&durum=rezervasyon`); }
    else if (st === 'failed') { if (S.adim === 'odeme') location.assign(`/odeme-sonuc?order=${encodeURIComponent(orderId)}&durum=hata`); }
  }, (e) => console.warn('Order dinlenemedi', e?.code));
}

// ---------- Geri sayım ----------
function sayacBaslat() {
  clearInterval(S.zaman);
  let sonDuyuru = 9999;
  const adim = () => {
    if (!S.hold) return clearInterval(S.zaman);
    const kalan = Math.max(0, Math.ceil((S.hold.expiresAt - Date.now()) / 1000));
    const m = `${String(Math.floor(kalan / 60)).padStart(2, '0')}:${String(kalan % 60).padStart(2, '0')}`;
    $$('[data-sure]').forEach((e) => { e.textContent = m; });
    $$('.sayac-kutu').forEach((e) => e.classList.toggle('az', kalan <= 60));
    $$('.sayac-kutu .ilerle').forEach((e) => { e.style.strokeDashoffset = String(HALKA * (1 - Math.min(1, kalan / S.hold.toplamSure))); });
    for (const esik of [60, 30, 10]) if (kalan <= esik && sonDuyuru > esik) { sonDuyuru = esik; canli(`Süre dolmak üzere: ${esik} saniye kaldı.`); }
    if (kalan <= 0) sureDoldu();
  };
  adim(); S.zaman = setInterval(adim, 1000);
}

// ---------- Arayüz ----------
const IKON_BILGI = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/></svg>';

function bannerCiz() {
  const b = $('#k-banner'); if (!b) return;
  b.innerHTML = S.banner ? `<div class="k-uyari ${S.banner.tur}" role="alert">${IKON_BILGI}<div><b>${esc(S.banner.baslik)}</b>${esc(S.banner.metin)}</div></div>` : '';
}

function ozetSatirlari() {
  const ids = S.hold ? S.hold.seatIds : S.secili;
  const fy = new Map((S.hold?.seats || []).map((x) => [x.id, x.price]));
  return ids.map((id) => `<span class="k-etiket ${S.hold ? 'sabit' : ''}"><b>${esc(id)}</b>${fy.has(id) && fy.get(id) != null ? `<small>${para(fy.get(id))}</small>` : ''}${S.hold ? '' : `<button type="button" data-act="cikar" data-id="${esc(id)}" aria-label="${esc(koltukAdi(id))} seçimini kaldır">×</button>`}</span>`).join('')
    || '<span class="k-sec-yok">Henüz koltuk seçmedin. Plandan en fazla 3 koltuk seç.</span>';
}

function odemeMenusu() {
  const lim = S.satis.rezervasyonLimit, saatIptal = S.satis.iptalSaat;
  const sahne = sahneAcik() ? `<label class="odeme-k on"><input type="radio" name="yontem" value="sahne" checked><span><b>Sahnede öde (rezervasyon)</b><small>Koltuğun senin adına ayrılır, tutarı etkinlik günü gişede ödersin. Kişi başı toplam en fazla ${lim} rezervasyon; etkinlikten ${saatIptal} saat öncesine kadar iptal edebilirsin.</small></span></label>` : '';
  const kart = kartAcik()
    ? `<label class="odeme-k on"><input type="radio" name="yontem" value="kart" checked><span><b>Kart ile öde (iyzico)</b><small>Ödeme iyzico güvenli sayfasında alınır.</small></span></label>`
    : `<label class="odeme-k kapali" aria-disabled="true"><input type="radio" name="yontem" value="kart" disabled aria-describedby="kart-kapali"><span><b>Kart ile öde (iyzico)<em class="rozet">Yakında</em></b><small id="kart-kapali">Şu anda ödeme sistemi çalışmıyor.</small></span></label>`;
  return `<fieldset class="odeme-sec"><legend>Ödeme yöntemi</legend>${sahne}${kart}</fieldset>`;
}

function panelCiz() {
  const p = $('#k-panel'), alt = $('#k-alt'); if (!p) return;
  const e = S.ev, when = S.when;
  const ucr = S.hold ? S.hold.free : ucretsizMi();
  const n = S.hold ? S.hold.seatIds.length : S.secili.length;
  const toplam = S.hold ? S.hold.total : (fiyat() != null ? fiyat() * n : null);
  const toplamMetin = ucr ? 'Ücretsiz' : toplam == null ? '—' : para(toplam);
  const kapali = seansGecti() || S.show?.external;
  const bek = S.bekliyor;
  let govde = '', basl = 'Koltuk seçimi', btn = '', altBtn = '', altOzet = '';

  if (S.adim === 'sec') {
    const sk = satisKapali();
    const dis = !n || bek || kapali || sk;
    btn = `<button type="button" class="btn btn-primary" data-act="tut" ${dis ? 'disabled' : ''}>${bek ? 'Tutuluyor…' : sk ? 'Bilet satışı kapalı' : n ? `Koltukları tut (${n})` : 'Koltuk seç'}</button>`;
    govde = `<div class="k-secililer" aria-label="Seçilen koltuklar">${ozetSatirlari()}</div>
      <div class="k-toplam"><span>${ucr ? 'Bilet' : 'Tahmini tutar'}</span><b>${toplamMetin}</b></div>
      <p class="k-not">${ucr ? 'Ücretsiz bilet — kişi başı toplam 3. Koltukları tuttuktan sonra tek adımda onaylarsın.' : sk ? 'Bilet satışı şu an kapalı. Koltuk seçimine bakabilirsin ama bilet alınamaz.' : 'Kesin tutar koltukları tuttuğunda gösterilir. Tutulan koltuklar 10 dakika senin için ayrılır; ardından ödeme yöntemini seçersin.'}</p>`;
    altOzet = `<b>${n ? toplamMetin : 'Koltuk seç'}</b><small>${n ? esc(S.secili.join(', ')) : `En fazla ${LIMIT} koltuk`}</small>`;
    altBtn = btn;
  } else {
    basl = S.adim === 'odeme' ? 'Ödeme' : 'Koltukların tutuluyor';
    const h = S.hold;
    const sayac = `<div class="sayac-kutu" role="timer" aria-label="Kalan süre"><svg viewBox="0 0 52 52" aria-hidden="true"><circle class="iz" cx="26" cy="26" r="22"/><circle class="ilerle" cx="26" cy="26" r="22" stroke-dasharray="${HALKA}" stroke-dashoffset="0"/></svg><div><b data-sure>--:--</b><small>${S.adim === 'odeme' ? 'Ödemeyi bu sürede tamamla' : 'Süre dolunca koltuklar serbest kalır'}</small></div></div>`;
    if (S.adim === 'odeme') {
      govde = `${sayac}<div id="odeme-yer"><p class="k-not">Ödeme formu yükleniyor…</p></div><p class="k-not">Kart bilgilerin TiyatRol sunucularına gelmez; iyzico güvenli ödeme sayfasında işlenir.</p>`;
      altOzet = `<b data-sure>--:--</b><small>Ödeme sürüyor</small>`;
    } else {
      const sk = satisKapali();
      btn = h.free
        ? `<button type="button" class="btn btn-primary" data-act="onayla" ${bek ? 'disabled' : ''}>${bek ? 'Onaylanıyor…' : 'Ücretsiz bileti onayla'}</button>`
        : sk ? '<button type="button" class="btn btn-primary" disabled>Bilet satışı kapalı</button>'
        : sahneAcik() ? `<button type="button" class="btn btn-primary" data-act="rezerve" ${bek ? 'disabled' : ''}>${bek ? 'Onaylanıyor…' : `Rezervasyonu onayla · ${toplamMetin}`}</button>`
        : `<button type="button" class="btn btn-primary" data-act="ode" ${bek ? 'disabled' : ''}>${bek ? 'Bekle…' : `Ödemeye geç · ${toplamMetin}`}</button>`;
      altBtn = btn;
      govde = `${sayac}<div class="k-secililer" aria-label="Tutulan koltuklar">${ozetSatirlari()}</div>
        <div class="k-toplam"><span>${h.free ? 'Bilet' : 'Toplam'}</span><b>${toplamMetin}</b></div>
        ${h.free ? '<p class="k-not">Ücretsiz bilet — kişi başı toplam 3. Onayladığında biletin Biletlerim sayfasına eklenir.</p>' : sk ? '<p class="k-not" role="note">Bilet satışı şu an kapalı. Koltukların süre dolana kadar ayrılı kalır; vazgeçebilirsin.</p>' : `${odemeMenusu()}<p class="k-not">Tutar sunucuda hesaplandı.</p>`}`;
      altOzet = `<b data-sure>--:--</b><small>${esc(h.seatIds.join(', '))}</small>`;
    }
  }
  const vazgec = S.adim === 'tut' && !S.hold?.paying ? `<button type="button" class="btn btn-ghost" data-act="birak" ${bek ? 'disabled' : ''}>Vazgeç, koltukları bırak</button>` : '';
  p.innerHTML = `<div class="ticket"><div class="head"><span>TiyatRol</span><span>${basl}</span></div>
    <div class="body">
      <div class="k-baslik">${esc(S.show?.name || 'Seans')}</div>
      <div class="fields"><div class="fld"><small>Tarih</small><b>${when ? tarihUzun(when) : '—'}</b></div><div class="fld"><small>Saat</small><b>${when ? saat(when) : '—'}</b></div>
        <div class="fld" style="grid-column:1/-1"><small>Sahne</small><b>${esc(S.stage?.name || e?.stageId || '—')}</b></div></div>
      <div class="perf"></div>
      ${kapali ? `<p class="k-mesaj" role="alert" style="display:block">${seansGecti() ? 'Bu seans gerçekleşti; koltuk seçilemez.' : 'Bu oyunun biletleri başka bir platformda satılıyor.'}</p>` : govde}
      <div class="k-mesaj" role="alert">${esc(S.mesaj)}</div>
      ${kapali ? '' : btn}${vazgec}
      <div class="bars" aria-hidden="true"></div></div></div>`;
  if (alt) alt.innerHTML = kapali ? '' : `<div class="k-ozet">${altOzet}</div>${altBtn}`;
  if (S.hold && S.zaman) sayacBaslat();
  if (S.adim === 'odeme' && S.iframe) formKapsulu();
}

function iskeleCiz() {
  const s = S.show, e = S.ev;
  const kirinti = `<a href="/">Vitrin</a> / ${s ? `<a href="${linkOf('oyun', s)}">${esc(s.name)}</a>` : 'Oyun'} / Koltuk seçimi`;
  const sahneAd = S.stage?.name || e.stageId || '';
  yaz(`<section class="k-sayfa">
    <div class="crumbs">${kirinti}</div>
    <div class="k-ust">${resim(s?.imageUrl, s?.name || 'Oyun')}
      <div><h1>${esc(s?.name || 'Koltuk seçimi')}</h1>
      <p>${S.when ? `${tarihUzun(S.when)} · ${saat(S.when)}` : ''}${sahneAd ? ` · ${esc(sahneAd)}` : ''}</p></div>
      ${s ? `<a class="btn btn-ghost btn-sm" href="${linkOf('oyun', s)}#seanslar" style="margin-left:auto">Seansı değiştir</a>` : ''}</div>
    <div id="k-banner"></div>
    <div class="k-izgara">
      <div class="k-sol">
        <div id="k-bilgi">${!ucretsizMi() && S.satis.mode === 'kapali' ? `<div class="k-uyari kapali-satis" role="note">${IKON_BILGI}<div><b>Bilet satışı şu an kapalı</b>Koltuk planına bakabilirsin; satış açıldığında burada bilet alabilirsin.</div></div>` : ''}${!ucretsizMi() && S.satis.mode === 'rezervasyon' ? `<div class="k-uyari rezervasyon" role="note">${IKON_BILGI}<div><b>Rezervasyon — ödeme sahnede</b>Koltuğunu ayırt, tutarı etkinlik günü gişede öde. Kişi başı toplam en fazla ${S.satis.rezervasyonLimit} rezervasyon; ${S.satis.iptalSaat} saat öncesine kadar iptal edebilirsin.</div></div>` : ''}${ucretsizMi() ? `<div class="k-uyari ucretsiz">${IKON_BILGI}<div><b>Ücretsiz bilet — kişi başı toplam 3</b>Bu etkinlik ücretsiz. Aynı hesap için toplam en fazla 3 ücretsiz bilet alınabilir.</div></div>` : ''}</div>
        <div class="plan-kutu">
          <div class="plan-arac"><b id="k-say" aria-live="off">0 / ${LIMIT} koltuk</b>
            <div class="plan-zoom" role="group" aria-label="Plan yakınlaştırma"><button type="button" data-zoom="-" aria-label="Uzaklaştır">−</button><output id="zoom-oran" aria-live="off">100%</output><button type="button" data-zoom="+" aria-label="Yakınlaştır">+</button><button type="button" class="btn btn-ghost btn-sm" data-zoom="fit">Sığdır</button></div></div>
          <div class="plan-gorus" id="gorus" tabindex="-1"><div class="plan-ic" id="planic"><div class="skel" style="width:min(520px,80vw);height:260px"></div></div></div>
          <div class="lejant" aria-label="Renk açıklaması">
            <span><i class="koltuk bos"></i>Boş</span><span><i class="koltuk secili"></i>Seçili</span><span><i class="koltuk benim"></i>Sana ayrıldı</span>
            <span><i class="koltuk rezerve"></i>Başkası tutuyor</span><span><i class="koltuk dolu"></i>Dolu</span><span><i class="koltuk kapali"></i>Satışa kapalı</span></div>
        </div>
        <p class="tiny" style="margin-top:12px">Klavye: ok tuşlarıyla koltuklar arasında gez, Enter ile seç. Telefonda iki parmakla yakınlaştırabilirsin.</p>
      </div>
      <aside class="k-sag" id="k-panel" aria-label="Seçim özeti"></aside>
    </div>
  </section>`);
  if (!$('#k-alt')) { const a = document.createElement('div'); a.id = 'k-alt'; a.className = 'k-alt'; document.body.append(a); }
  if (!$('#canli')) { const c = document.createElement('div'); c.id = 'canli'; c.className = 'sr'; c.setAttribute('role', 'status'); c.setAttribute('aria-live', 'polite'); document.body.append(c); }

  const ic = $('#planic'), gorus = $('#gorus');
  ic.addEventListener('click', (ev) => { const t = ev.target.closest('.koltuk'); if (t) sec(t.dataset.id); });
  ic.addEventListener('keydown', oklarla);
  ic.addEventListener('focusin', (ev) => { const t = ev.target.closest('.koltuk'); if (t && t.dataset.id !== S.odak) { S.dugme.get(S.odak).tabIndex = -1; S.odak = t.dataset.id; t.tabIndex = 0; } });
  $('.plan-zoom').addEventListener('click', (ev) => {
    const b = ev.target.closest('[data-zoom]'); if (!b) return;
    if (b.dataset.zoom === 'fit') sigdir(); else zoom(S.z + (b.dataset.zoom === '+' ? 0.15 : -0.15));
  });
  // iki parmakla yakınlaştırma
  let d0 = 0, z0 = 1;
  const uzak = (t) => Math.hypot(t[0].clientX - t[1].clientX, t[0].clientY - t[1].clientY);
  gorus.addEventListener('touchstart', (ev) => { if (ev.touches.length === 2) { d0 = uzak(ev.touches); z0 = S.z; } }, { passive: true });
  gorus.addEventListener('touchmove', (ev) => { if (ev.touches.length === 2 && d0) { ev.preventDefault(); zoom(z0 * (uzak(ev.touches) / d0)); } }, { passive: false });
  gorus.addEventListener('touchend', () => { d0 = 0; }, { passive: true });
  addEventListener('resize', () => { if (!S.hold) sigdir(); });
}

document.addEventListener('click', (ev) => {
  const b = ev.target.closest('[data-act]'); if (!b || b.disabled) return;
  const a = b.dataset.act;
  if (a === 'tut') tut();
  else if (a === 'ode') ode();
  else if (a === 'onayla') onayla();
  else if (a === 'rezerve') rezerve();
  else if (a === 'birak') birak();
  else if (a === 'cikar') { S.secili = S.secili.filter((x) => x !== b.dataset.id); S.mesaj = ''; boya(); panelCiz(); }
});

// ---------- Başlangıç ----------
/**
 * Sayfa yenilenir / başka sekme / başka cihazdan dönülürse süren tutmayı KULLANICININ KENDİ Order belgelerinden sürdürür
 * (sessionStorage'a bağlı değil). 'held' -> kaldığı yerden devam ya da "Vazgeç"; 'paying' -> "Ödemeye geç" aynı oturumu açar.
 */
function devam() {
  if (S.hold || !mevcut()) return;
  const o = S.siparisler
    .filter((x) => ['held', 'paying'].includes(x.status) && !S.yoksay.has(x.id) && zamanMs(x.expiresAt) > Date.now() + 2000)
    .sort((a, b) => zamanMs(b.expiresAt) - zamanMs(a.expiresAt))[0];
  if (!o) return;
  tutmaKur({ orderId: o.id, expiresAt: zamanMs(o.expiresAt), total: o.total, currency: o.currency, free: o.free ?? o.total === 0, seatIds: (o.seatIds || []).map(String), seats: [], paying: o.status === 'paying' });
  boya(); panelCiz(); bannerCiz();
}

function siparisleriDinle(uid) {
  if (S.siparislerUid === uid) return;
  S.siparislerAbone?.(); S.siparislerAbone = null; S.siparislerUid = uid || ''; S.siparisler = []; benimKur();
  if (!uid) return;
  // kurallar: yalnızca where userId == uid sorgusu izinli
  S.siparislerAbone = onSnapshot(query(collection(db, 'Order'), where('userId', '==', uid), where('eventId', '==', EID)), (qs) => {
    S.siparisler = qs.docs.map((d) => ({ id: d.id, ...d.data() }));
    benimKur(); devam();
    if ($('#planic')) { boya(); panelCiz(); }
  }, (e) => console.warn('Siparişler dinlenemedi', e?.code));
}

function seansBilgisi(veri, d) {
  const ev = d?.events.find((x) => x.docId === EID || x.id === EID);
  S.show = ev?.show || d?.showById.get(veri.showId) || null;
  S.stage = ev?.stage || d?.stageById.get(veri.stageId) || null;
  S.when = tarihAyristir(veri.date);
}

async function baslat() {
  if (!/^[\w.-]{1,128}$/.test(EID)) return bosEkran('Geçersiz bağlantı', 'Bu koltuk seçimi adresi tanınmadı.');
await oturumBekle();
  S.satis = await satisAyari(); // hata olursa varsayılan (rezervasyon)
  let d = null; try { d = await yukle(); } catch {}
  let ilk = true;
  onSnapshot(doc(db, 'Event', EID), (snap) => {
    if (!snap.exists()) return bosEkran('Seans bulunamadı', 'Bağlantı eski olabilir ya da seans kaldırılmış olabilir.');
    const veri = snap.data();
    S.ev = veri; S.koltuklar = veri.seats && typeof veri.seats === 'object' ? veri.seats : {};
    S.seatsBos = !Object.keys(S.koltuklar).length;
    if (ilk) {
      ilk = false;
      seansBilgisi(veri, d);
      if (S.show?.external) {
        return bosEkran('Biletler başka platformda', 'Bu oyunun biletleri organizatörün kendi sayfasında satılıyor.', `<a class="btn btn-primary" target="_blank" rel="noopener sponsored" href="${esc(S.show.externalTicketUrl)}">Bilet sayfasına git</a>`);
      }
      iskeleCiz(); panelCiz();
      if (seansGecti()) { S.banner = { tur: 'bilgi', baslik: 'Bu seans gerçekleşti', metin: 'Geçmiş seanslar için koltuk seçilemez. Oyunun diğer seanslarına bakabilirsin.' }; bannerCiz(); }
      // salon planı
      const sid = String(veri.stageId || '');
      if (!sid) { S.duzen = duzenKur(null, S.koltuklar); S.duzenHazir = true; S.duzen.satirlar.length ? planCiz() : planYok(); return; }
      onSnapshot(doc(db, 'Seats', sid), (ss) => {
        const yeni = duzenKur(ss.exists() ? ss.data() : null, S.koltuklar);
        S.duzen = yeni;
        if (!yeni.satirlar.length) return planYok();
        const imza = yeni.satirlar.map((r) => r.ad + ':' + r.koltuklar.map((k) => k.id).join(',')).join('|');
        if (imza !== S.duzenImza) { S.duzenImza = imza; planCiz(); } else boya();
        panelCiz();
      }, () => { S.duzen = duzenKur(null, S.koltuklar); S.duzen.satirlar.length ? planCiz() : planYok(); });
      if (mevcut()) siparisleriDinle(mevcut().uid);
      else girisGerekli('Koltuk seçmek için giriş yap.').then((u) => { if (u) boya(); });
    } else {
      S.when = tarihAyristir(veri.date) || S.when;
      if (S.duzen && !S.duzen.satirlar.length) { S.duzen = duzenKur(null, S.koltuklar); if (S.duzen.satirlar.length) planCiz(); }
      boya(); panelCiz();
    }
  }, () => bosEkran('Seans yüklenemedi', 'Bağlantını kontrol edip sayfayı yenile.', '<a class="btn btn-primary" href="">Yenile</a>'));
  oturumDinle((u) => {
    if (!u) { S.secili = []; if (S.hold) tutmaTemizle(); S.adim = 'sec'; }
    siparisleriDinle(u ? u.uid : '');
    if ($('#planic')) { boya(); panelCiz(); }
  });
  // süresi dolan 'rezerve' koltuklar, kimse bir şey yapmadan da haritada boşalsın
  setInterval(() => { if (S.dugme.size) { benimKur(); boya(); } }, 5000);
}
function planYok() {
  const ic = $('#planic'); if (ic) ic.innerHTML = '<div class="empty">Bu sahne için salon planı henüz hazır değil. Biletler için yakında tekrar dene.</div>';
}

baslat();

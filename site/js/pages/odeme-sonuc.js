// Ödeme sonucu: /odeme-sonuc?order=<id>&durum=basarili|hata
// Order belgesi CANLI dinlenir (webhook gecikebilir): 'paying' ise bekleme ekranı, sonra otomatik güncellenir.
// URL'deki "durum" yalnızca ipucudur; gerçek durum Order.status'tür (sunucu yazar).
import { kabukCiz } from '../ui.js';
import { db, doc, getDoc, onSnapshot } from '../firebase.js';
import { girisGerekli, oturumDinle } from '../auth.js';
import { biletleriDinle, biletKarti, biletlerBagla } from '../bilet-ortak.js';
import { $, esc, tl } from '../util.js';

// iyzico formu iframe içinden döndüyse üst pencereye çık
if (window.top !== window.self) { try { window.top.location.replace(window.location.href); } catch {} }

kabukCiz('');
const kok = $('#icerik');
const p = new URLSearchParams(location.search);
const ORDER = /^[\w.-]{1,128}$/.test(p.get('order') || '') ? p.get('order') : '';
const URL_DURUM = p.get('durum') === 'basarili' ? 'basarili' : p.get('durum') === 'hata' ? 'hata' : '';
const yaz = (h) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = h; };

const IKON = {
  ok: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12.5 4.5 4.5L19 7.500"/></svg>',
  hata: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>',
  bekle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 3a9 9 0 1 0 9 9" /></svg>',
};
const kart = (tur, baslik, metin, act = '') =>
  `<div class="s-kart" role="status"><div class="s-ikon ${tur}">${IKON[tur]}</div><h1>${esc(baslik)}</h1><p>${metin}</p><div class="s-act">${act}</div></div>`;

let order = null, biletler = [], bilAbone = null, ordAbone = null, basla = Date.now(), yenileTimer = null, uzadi = false;

function ciz() {
  if (!ORDER) return yaz(`<section class="s-sayfa">${kart('hata', 'Sipariş bulunamadı', 'Bağlantı eksik ya da hatalı görünüyor.', '<a class="btn btn-primary" href="/biletlerim">Biletlerim</a>')}</section>`);
  if (order === undefined) return yaz(`<section class="s-sayfa">${kart('hata', 'Sipariş bulunamadı', 'Bu siparişi görüntüleme yetkin yok ya da sipariş mevcut değil.', '<a class="btn btn-primary" href="/biletlerim">Biletlerim</a><a class="btn btn-ghost" href="/kesfet">Oyunlara göz at</a>')}</section>`);
  if (order === null) return yaz('<section class="s-sayfa"><div class="skel" style="width:min(560px,100%);height:280px"></div></section>');
  const st = order.status, geri = order.eventId ? `/koltuk/${encodeURIComponent(order.eventId)}` : '/kesfet';
  if (st === 'paid' || st === 'free_confirmed') {
    const ilgili = biletler.filter((b) => (order.ticketIds || []).includes(b.id) || b.orderId === ORDER || (b.eventId === order.eventId && b.koltuklar.some((k) => (order.seatIds || []).includes(k))));
    const ucretsiz = st === 'free_confirmed';
    yaz(`<section class="s-sayfa">${kart('ok', ucretsiz ? 'Ücretsiz biletin hazır' : 'Ödemen alındı, biletin hazır', ucretsiz ? 'Biletin hesabına eklendi. Girişte QR kodunu göstermen yeterli.' : `${order.total != null ? `${esc(tl(order.total))} tutarındaki ` : ''}ödemen başarıyla alındı. Girişte QR kodunu göstermen yeterli.`, '<a class="btn btn-primary" href="/biletlerim">Tüm biletlerim</a><a class="btn btn-ghost" href="/kesfet">Başka oyunlara bak</a>')}
      <div class="s-biletler" aria-live="polite">${ilgili.length ? ilgili.map((b, i) => biletKarti(b, i)).join('') : '<div class="skel" style="height:190px"></div><p class="tiny" style="text-align:center">Biletlerin hazırlanıyor…</p>'}</div></section>`);
    biletlerBagla(kok, ilgili);
    return;
  }
  if (st === 'paying' || (st === 'held' && URL_DURUM === 'basarili')) {
    if (URL_DURUM === 'hata') return yaz(`<section class="s-sayfa">${kart('hata', 'Ödeme tamamlanamadı', 'Ödeme başarısız oldu ya da iptal edildi. Kartından para çekilmedi. Süren dolmadıysa aynı koltuklarla tekrar deneyebilirsin.', `<a class="btn btn-primary" href="${geri}">Tekrar dene</a><a class="btn btn-ghost" href="/kesfet">Oyunlara dön</a>`)}</section>`);
    const uzun = Date.now() - basla > 60000;
    return yaz(`<section class="s-sayfa">${kart('bekle', 'Ödemen doğrulanıyor', uzun ? 'Bankadan onay gelmesi beklenenden uzun sürdü. Ödemen alındıysa biletin birkaç dakika içinde Biletlerim sayfasında görünür. Bu sayfayı açık bırakabilir ya da yenileyebilirsin.' : 'Bankanın onayı bekleniyor; genellikle birkaç saniye sürer. Bu sayfayı kapatma, otomatik güncellenir.', `<button type="button" class="btn btn-ghost" id="yenile">Durumu yenile</button>${uzun ? '<a class="btn btn-primary" href="/biletlerim">Biletlerim</a>' : ''}`)}</section>`),
      $('#yenile')?.addEventListener('click', yenile);
  }
  if (st === 'held') return yaz(`<section class="s-sayfa">${kart('bekle', 'Ödeme tamamlanmadı', 'Koltukların hâlâ senin için ayrılmış olabilir. Süre dolmadan ödemeyi tamamla.', `<a class="btn btn-primary" href="${geri}">Koltuk sayfasına dön</a>`)}</section>`);
  if (st === 'expired') return yaz(`<section class="s-sayfa">${kart('hata', 'Süre doldu', 'Koltuklar serbest bırakıldı. Ödemen alındıysa birkaç dakika içinde biletin Biletlerim sayfasında görünür; görünmezse bize ulaş.', `<a class="btn btn-primary" href="${geri}">Yeniden seç</a><a class="btn btn-ghost" href="/biletlerim">Biletlerim</a>`)}</section>`);
  yaz(`<section class="s-sayfa">${kart('hata', st === 'cancelled' ? 'Sipariş iptal edildi' : 'Ödeme tamamlanamadı', 'Ödeme başarısız oldu ya da iptal edildi. Kartından para çekilmedi. Tekrar deneyebilirsin.', `<a class="btn btn-primary" href="${geri}">Tekrar dene</a><a class="btn btn-ghost" href="/kesfet">Oyunlara dön</a>`)}</section>`);
}

async function yenile() {
  try { const s = await getDoc(doc(db, 'Order', ORDER)); order = s.exists() ? { ...s.data() } : undefined; } catch { /* dinleyici zaten çalışıyor */ }
  ciz();
}

function baslat(u) {
  ordAbone?.(); bilAbone?.(); clearInterval(yenileTimer);
  order = null; biletler = []; ciz();
  if (!u || !ORDER) return;
  ordAbone = onSnapshot(doc(db, 'Order', ORDER), (s) => { order = s.exists() ? { ...s.data() } : undefined; ciz(); }, () => { order = undefined; ciz(); });
  bilAbone = biletleriDinle(u.uid, (l) => { biletler = l; if (order && (order.status === 'paid' || order.status === 'free_confirmed')) ciz(); });
  // webhook gecikirse: 'paying' durumunda sunucudan periyodik yenile (en çok 3 dk); sonra durdur
  yenileTimer = setInterval(() => {
    if (Date.now() - basla > 180000) return clearInterval(yenileTimer);
    if (order && (order.status === 'paying' || order.status === 'held')) yenile();
    if (!uzadi && Date.now() - basla > 60000) { uzadi = true; ciz(); }
  }, 4000);
}

if (!ORDER) ciz();
oturumDinle((u) => {
  if (!u) {
    yaz(`<section class="s-sayfa"><div class="empty"><h3>Siparişini görmek için giriş yap</h3><p>Siparişlerin hesabına bağlıdır.</p><p style="margin-top:16px"><button type="button" class="btn btn-primary" id="giris">Giriş yap</button></p></div></section>`);
    $('#giris')?.addEventListener('click', () => girisGerekli('Siparişini görmek için giriş yap.'));
    return girisGerekli('Siparişini görmek için giriş yap.');
  }
  baslat(u);
});

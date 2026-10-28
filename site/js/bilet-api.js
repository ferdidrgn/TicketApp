// Bilet satın alma API'si (Cloud Functions, europe-west1). İstemci ASLA fiyat/tutar göndermez; sunucu hesaplar.
// Hata kodları: unauthenticated, failed-precondition, resource-exhausted, invalid-argument, permission-denied, not-found.
import { fonksiyon, auth, db, doc, getDoc } from './firebase.js';
import { silmeBekliyor } from './hesap-sil.js';

const VARSAYILAN = {
  unauthenticated: 'Oturumun kapanmış. Devam etmek için tekrar giriş yap.',
  'failed-precondition': 'Seçtiğin koltuklardan biri artık müsait değil ya da süre doldu. Koltukları yeniden seç.',
  'resource-exhausted': 'Bu etkinlik için koltuk sınırına ulaştın.',
  'invalid-argument': 'Seçimin geçersiz görünüyor. Sayfayı yenileyip tekrar dene.',
  'permission-denied': 'Bu işlem için yetkin yok.',
  'not-found': 'Kayıt bulunamadı. Süre dolmuş olabilir.',
  ACCOUNT_DELETION_PENDING: 'Hesabınız silinmek üzere; devam etmek için silmeyi iptal edin.',
  PHONE_REQUIRED: 'Bilet ve rezervasyon için telefon numaranı doğrulaman gerekiyor.',
  unavailable: 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.',
};
const SUNUCU_MESAJI = new Set(['failed-precondition', 'resource-exhausted', 'invalid-argument', 'permission-denied', 'not-found']);

/** Callable hatasını kullanıcıya gösterilebilir Türkçe mesaja çevirir (teknik ayrıntı sızdırmaz). */
export function apiHata(e) {
  const kod = String(e?.code || '').replace('functions/', '');
  let msg = '';
  // Sunucu sözleşmesi: failed-precondition + details.code === 'PHONE_REQUIRED' (doğrulanmış telefon yok).
  if (kod === 'failed-precondition' && (e?.details?.code === 'PHONE_REQUIRED' || e?.details === 'PHONE_REQUIRED')) {
    const h = new Error(VARSAYILAN.PHONE_REQUIRED); h.kod = 'PHONE_REQUIRED'; return h;
  }
  if (kod === 'failed-precondition' && (e?.details?.code === 'ACCOUNT_DELETION_PENDING' || e?.details === 'ACCOUNT_DELETION_PENDING')) {
    const h = new Error(VARSAYILAN.ACCOUNT_DELETION_PENDING); h.kod = 'ACCOUNT_DELETION_PENDING'; return h;
  }
  // Etkinlik başına limit: sunucu details = { code:'EVENT_LIMIT', limit, used, remaining }.
  if (kod === 'resource-exhausted' && e?.details?.code === 'EVENT_LIMIT') {
    const d = e.details;
    const h = new Error(String(e?.message || '').startsWith('Bu etkinlik için') ? e.message : `Bu etkinlik için en fazla ${d.limit} bilet alabilirsin. Şu an ${d.used} biletin var; ${d.remaining} bilet daha alabilirsin.`);
    h.kod = 'EVENT_LIMIT'; h.limit = d.limit; h.used = d.used; h.remaining = d.remaining; return h;
  }
  // Sunucunun yazdığı Türkçe mesaj yalnızca bilinen iş hatalarında gösterilir; "internal" vb. genel mesaja düşer.
  if (SUNUCU_MESAJI.has(kod)) {
    const m = String(e?.message || '').trim();
    if (m && m.length < 240 && !/^(Error|FirebaseError|INTERNAL)/i.test(m) && !/functions\/|https?:\/\//.test(m)) msg = m;
  }
  const hata = new Error(msg || VARSAYILAN[kod] || 'İşlem şu an tamamlanamadı. Biraz sonra tekrar dene.');
  hata.kod = kod;
  return hata;
}

// Telefon doğrulaması isteyen satış callable'ları. İstemci kontrolü yalnızca UX içindir; asıl güvenlik sunucudadır.
const TELEFONLU = new Set(['holdSeats', 'confirmFree', 'confirmReservation', 'startPayment', 'getEventQuota']);
async function cagir(ad, veri) {
  // Kapı sırası sunucuyla aynı (docs/HESAP-SILME.md §3): silinmek üzere işaretli hesap telefon sorusundan ÖNCE ACCOUNT_DELETION_PENDING alır.
  if (TELEFONLU.has(ad) && silmeBekliyor()) {
    const h = new Error(VARSAYILAN.ACCOUNT_DELETION_PENDING); h.kod = 'ACCOUNT_DELETION_PENDING'; throw h;
  }
  if (TELEFONLU.has(ad) && auth.currentUser && !auth.currentUser.phoneNumber) {
    const h = new Error(VARSAYILAN.PHONE_REQUIRED); h.kod = 'PHONE_REQUIRED'; throw h;
  }
  try {
    const f = await fonksiyon(ad);
    return (await f(veri)).data;
  } catch (e) { throw apiHata(e); }
}

/** Etkinlik başına bilet hakkı (sunucu otoritesi): { limit, used, remaining, held, ... }. Hata olursa null (sayfa yine çalışır, sunucu denetler). */
export async function etkinlikKotasi(eventId) {
  try { return await cagir('getEventQuota', { eventId }); } catch { return null; }
}
export const koltukTut = (eventId, seatIds) => cagir('holdSeats', { eventId, seatIds });
export const tutmaBirak = (orderId) => cagir('releaseHold', { orderId });
export const ucretsizOnayla = (orderId) => cagir('confirmFree', { orderId });
/** returnUrl daima kendi origin'imiz; sunucu iyzico dönüşünde buraya yönlendirir. */
export const odemeBaslat = (orderId) =>
  cagir('startPayment', { orderId, provider: 'iyzico', returnUrl: `${location.origin}/odeme-sonuc?order=${encodeURIComponent(orderId)}` });

/** Rezervasyon (ödeme sahnede): ücretli siparişi bilete çevirir. Başarıda { ticketIds, status:'rezervasyon' }. */
export const rezervasyonOnayla = (orderId) => cagir('confirmReservation', { orderId });
/** Kendi venue/ücretsiz biletini iptal eder (sunucu iptal süresini denetler). */
export const biletIptal = (ticketId) => cagir('cancelTicket', { ticketId });

const SATIS_VARSAYILAN = { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 };
/** Config/satis (herkes okur). Yoksa ya da okunamazsa güvenli varsayılan: rezervasyon modu. */
export async function satisAyari() {
  try {
    const s = await getDoc(doc(db, 'Config', 'satis'));
    const d = s.exists() ? s.data() : {};
    const mode = ['kapali', 'rezervasyon', 'online'].includes(d.mode) ? d.mode : SATIS_VARSAYILAN.mode;
    const lim = Number(d.rezervasyonLimit), saat = Number(d.iptalSaat);
    return { mode, rezervasyonLimit: lim > 0 ? Math.floor(lim) : SATIS_VARSAYILAN.rezervasyonLimit, iptalSaat: saat >= 0 && Number.isFinite(saat) ? saat : SATIS_VARSAYILAN.iptalSaat };
  } catch { return { ...SATIS_VARSAYILAN }; }
}
export const satisEtiketi = (mode) => (mode === 'online' ? 'Bilet al' : mode === 'kapali' ? 'Bilet satışı kapalı' : 'Rezervasyon yap');

/** Yönlendirilecek ödeme adresi güvenli mi? https (ya da emülatörde yerel http). */
export function guvenliUrl(u) {
  try {
    const x = new URL(u, location.origin);
    if (x.protocol === 'https:') return x.href;
    if (x.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(x.hostname) && ['localhost', '127.0.0.1'].includes(location.hostname)) return x.href;
  } catch {}
  return '';
}

// SADECE TEST — gerçek backend'in YERİNE GEÇMEZ.
// Sözleşmeye uygun SAHTE callable'lar: holdSeats, releaseHold, startPayment, confirmFree, confirmReservation, cancelTicket
// (+ Config/satis: SATIS_MODE=kapali|rezervasyon|online verilirse açılışta yazılır; REZ_LIMIT, IPTAL_SAAT).
// Cloud Functions emülatörünün HTTP protokolünü taklit eder (127.0.0.1:5001) ve Firestore emülatörüne REST ile yazar.
// Gerçek kimlik doğrulama YOK: Auth emülatörünün ürettiği (imzasız) kimlik belirtecindeki uid'e güvenir.
//   node site/tools/mock-functions/server.mjs        (HOLD_SECONDS=20 PAY_MODE=ok|fail PAY_DELAY_MS=3000)
import http from 'node:http';
import { oku, yaz, guncelle, yeniId, listele } from '../emu-rest.mjs';

const PORT = +(process.env.PORT || 5001);
const HOLD = +(process.env.HOLD_SECONDS || 600);
const PAY_MODE = process.env.PAY_MODE || 'ok';
const PAY_DELAY = +(process.env.PAY_DELAY_MS || 3000);
const LIMIT = 3;
const REZ_LIMIT = +(process.env.REZ_LIMIT || 3);
const IPTAL_SAAT = +(process.env.IPTAL_SAAT || 24);

class Hata extends Error { constructor(status, msg, details) { super(msg); this.status = status; this.details = details; } }
const HTTP = { INVALID_ARGUMENT: 400, FAILED_PRECONDITION: 400, UNAUTHENTICATED: 401, PERMISSION_DENIED: 403, NOT_FOUND: 404, RESOURCE_EXHAUSTED: 429, INTERNAL: 500 };

// Hesap silme (docs/HESAP-SILME.md): gelecek bilet -> UPCOMING_TICKETS; pending iken satış -> ACCOUNT_DELETION_PENDING.
const SATIN_ALMA = new Set(['holdSeats', 'confirmFree', 'confirmReservation', 'startPayment']);
const SIL_GUN = +(process.env.DELETE_DAYS || 30);
async function requestAccountDeletion(uid) {
  const u = await oku(`User/${uid}`);
  if (u?.deletionStatus === 'pending') return { status: 'pending', scheduledAt: u.deletionScheduledAt, requestedAt: u.deletionRequestedAt, already: true };
  const gelecek = (await listele('Ticket')).filter((t) => t.customerId === uid && t.paymentStatus !== 'cancelled' && !t.cancelledAt && (tarihAyristir(t.eventDate) || 0) > new Date())
    .sort((a, b) => tarihAyristir(a.eventDate) - tarihAyristir(b.eventDate));
  if (gelecek.length) {
    throw new Hata('FAILED_PRECONDITION', 'UPCOMING_TICKETS', { code: 'UPCOMING_TICKETS', count: gelecek.reduce((n, t) => n + (t.buySeats?.length || 1), 0), nextEventDate: tarihAyristir(gelecek[0].eventDate).toISOString(), nextEventTitle: gelecek[0].showName || '' });
  }
  const simdi = new Date().toISOString(), scheduledAt = new Date(Date.now() + SIL_GUN * 864e5).toISOString();
  await guncelle(`User/${uid}`, { deletionStatus: 'pending', deletionScheduledAt: scheduledAt, deletionRequestedAt: simdi });
  return { status: 'pending', scheduledAt, requestedAt: simdi, already: false };
}
async function cancelAccountDeletion(uid) {
  const u = await oku(`User/${uid}`);
  const was = u?.deletionStatus === 'pending';
  if (was) await guncelle(`User/${uid}`, { deletionStatus: null, deletionScheduledAt: null, deletionRequestedAt: null });
  return { status: 'active', wasPending: was };
}

// Telefon doğrulaması (docs/TELEFON-DOGRULAMA.md): token'da phone_number yoksa failed-precondition + details.code PHONE_REQUIRED.
const TELEFONLU = new Set(['holdSeats', 'confirmFree', 'confirmReservation', 'startPayment']);
function telefonAl(req) {
  const t = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  try { return JSON.parse(Buffer.from(t.split('.')[1], 'base64url').toString()).phone_number || ''; } catch { return ''; }
}
async function syncPhoneVerification(uid, _d, req) {
  const tel = telefonAl(req);
  if (!tel) return { isPhoneActive: false };
  await guncelle(`User/${uid}`, { phoneNumber: tel, isPhoneActive: true }).catch(() => {});
  return { isPhoneActive: true, phoneNumber: tel };
}
function uidAl(req) {
  const t = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  try { const j = JSON.parse(Buffer.from(t.split('.')[1], 'base64url').toString()); const uid = j.user_id || j.sub; if (uid) return uid; } catch {}
  throw new Hata('UNAUTHENTICATED', 'Bu işlem için giriş yapmalısın.');
}
const tarihAyristir = (v) => { const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})[,\s]+(\d{1,2}):(\d{2})/.exec(String(v || '')); return m ? new Date(+m[3], +m[2] - 1, +m[1], +m[4], +m[5]) : null; };
const ucretsizMi = (p) => Number(String(p ?? '').replace(',', '.')) === 0 && String(p ?? '') !== '';

async function biletSayisi(uid, eventId) {
  const b = await listele('Ticket');
  return b.filter((t) => t.customerId === uid && t.eventId === eventId).reduce((n, t) => n + (t.buySeats?.length || 0), 0);
}

async function holdSeats(uid, { eventId, seatIds }) {
  if (typeof eventId !== 'string' || !eventId) throw new Hata('INVALID_ARGUMENT', 'Etkinlik belirtilmedi.');
  if (!Array.isArray(seatIds) || !seatIds.length || seatIds.some((s) => typeof s !== 'string') || new Set(seatIds).size !== seatIds.length) throw new Hata('INVALID_ARGUMENT', 'Koltuk seçimi geçersiz.');
  if (seatIds.length > LIMIT) throw new Hata('RESOURCE_EXHAUSTED', `Bir etkinlikte en fazla ${LIMIT} koltuk seçebilirsin.`);
  const ev = await oku(`Event/${eventId}`);
  if (!ev) throw new Hata('NOT_FOUND', 'Etkinlik bulunamadı.');
  const when = tarihAyristir(ev.date);
  if (when && when < new Date()) throw new Hata('FAILED_PRECONDITION', 'Bu seans geçmiş; bilet alınamaz.');
  const seats = ev.seats || {};
  const benim = Object.values(seats).filter((x) => x.customerId === uid && x.status === 'reserved').length;
  const ucretsiz = ucretsizMi(ev.price);
  if (ucretsiz) {
    const var_ = await biletSayisi(uid, eventId);
    if (var_ + benim + seatIds.length > LIMIT) throw new Hata('RESOURCE_EXHAUSTED', `Ücretsiz etkinliklerde kişi başı toplam en fazla ${LIMIT} bilet alabilirsin. Şu an ${var_ + benim} biletin/ayırtman var.`);
  } else if (benim + seatIds.length > LIMIT) throw new Hata('RESOURCE_EXHAUSTED', `Bir etkinlikte en fazla ${LIMIT} aktif koltuğun olabilir.`);
  const kapali = (await oku(`Seats/${ev.stageId}`))?.closedSeatsId || [];
  for (const id of seatIds) {
    if (kapali.includes(id) || !seats[id] || seats[id].status !== 'available') throw new Hata('FAILED_PRECONDITION', `${id} koltuğu artık müsait değil. Lütfen başka bir koltuk seç.`);
  }
  const fiyat = Number(String(ev.price ?? '0').replace(',', '.')) || 0;
  const simdi = Date.now(), bitis = simdi + HOLD * 1000;
  const alan = {};
  seatIds.forEach((id) => { alan[`seats.${id}`] = { status: 'reserved', customerId: uid, reservedAt: simdi }; });
  await guncelle(`Event/${eventId}`, alan);
  const orderId = yeniId();
  const total = fiyat * seatIds.length;
  await yaz(`Order/${orderId}`, { _id: orderId, customerId: uid, eventId, showId: ev.showId || '', stageId: ev.stageId || '', userId: uid, status: 'held', seatIds, total, currency: 'TRY', free: ucretsiz, expiresAt: bitis, createdAt: simdi });
  return { orderId, expiresAt: bitis, total, currency: 'TRY', free: ucretsiz, seats: seatIds.map((id) => ({ id, price: fiyat })) };
}

async function siparisAl(uid, orderId) {
  if (typeof orderId !== 'string' || !orderId) throw new Hata('INVALID_ARGUMENT', 'Sipariş belirtilmedi.');
  const o = await oku(`Order/${orderId}`);
  if (!o) throw new Hata('NOT_FOUND', 'Sipariş bulunamadı.');
  if (o.customerId !== uid) throw new Hata('PERMISSION_DENIED', 'Bu sipariş sana ait değil.');
  return o;
}
async function koltuklariSerbestBirak(o, durum) {
  const alan = {}; o.seatIds.forEach((id) => { alan[`seats.${id}`] = { status: 'available', customerId: null }; });
  await guncelle(`Event/${o.eventId}`, alan);
  await guncelle(`Order/${o._id}`, { status: durum });
}
async function releaseHold(uid, { orderId }) {
  const o = await siparisAl(uid, orderId);
  if (o.status === 'held') await koltuklariSerbestBirak(o, 'cancelled');
  return { ok: true };
}
async function satisTamamla(o, durum) {
  const ev = await oku(`Event/${o.eventId}`); const show = ev?.showId ? await oku(`Show/${ev.showId}`) : null; const st = ev?.stageId ? await oku(`Stage/${ev.stageId}`) : null;
  const alan = {}; o.seatIds.forEach((id) => { alan[`seats.${id}`] = { status: 'sold', customerId: o.customerId, soldAt: Date.now() }; });
  await guncelle(`Event/${o.eventId}`, alan);
  const tid = yeniId();
  await yaz(`Ticket/${tid}`, { _id: tid, customerId: o.customerId, eventId: o.eventId, showId: ev?.showId || '', stageId: ev?.stageId || '', showName: show?.name || '', showImageUrl: show?.imageUrl || '', stageName: st?.name || '', eventDate: ev?.date || '', buySeats: o.seatIds, orderPrice: String(o.total), orderMethod: 'web', orderId: o._id, isPast: false });
  await guncelle(`Order/${o._id}`, { status: durum, ticketIds: [tid] });
  return [tid];
}
async function confirmFree(uid, { orderId }) {
  const o = await siparisAl(uid, orderId);
  if (!o.free) throw new Hata('FAILED_PRECONDITION', 'Bu sipariş ücretli; ödeme gerekir.');
  if (o.status !== 'held' || o.expiresAt < Date.now()) throw new Hata('FAILED_PRECONDITION', 'Süre doldu. Koltukları yeniden seç.');
  return { ticketIds: await satisTamamla(o, 'free_confirmed') };
}
async function satisModu() { return (await oku('Config/satis'))?.mode || 'rezervasyon'; }
async function confirmReservation(uid, { orderId }) {
  const o = await siparisAl(uid, orderId);
  if (o.free) throw new Hata('FAILED_PRECONDITION', 'Bu sipariş ücretsiz; ücretsiz bileti onayla.');
  if ((await satisModu()) !== 'rezervasyon') throw new Hata('FAILED_PRECONDITION', 'Rezervasyon şu anda kullanılamıyor.');
  if (o.status !== 'held' || o.expiresAt < Date.now()) throw new Hata('FAILED_PRECONDITION', 'Süre doldu. Koltukları yeniden seç.');
  const var_ = (await listele('Ticket')).filter((t) => t.customerId === uid && ['pay_at_venue'].includes(t.paymentStatus)).reduce((n, t) => n + (t.buySeats?.length || 0), 0);
  if (var_ + o.seatIds.length > REZ_LIMIT) throw new Hata('RESOURCE_EXHAUSTED', `Kişi başı toplam en fazla ${REZ_LIMIT} rezervasyon yapabilirsin. Şu an ${var_} aktif rezervasyonun var.`);
  const ev = await oku(`Event/${o.eventId}`); const show = ev?.showId ? await oku(`Show/${ev.showId}`) : null; const st = ev?.stageId ? await oku(`Stage/${ev.stageId}`) : null;
  const alan = {}; o.seatIds.forEach((id) => { alan[`seats.${id}`] = { status: 'sold', customerId: uid, soldAt: Date.now() }; });
  await guncelle(`Event/${o.eventId}`, alan);
  await yaz(`Ticket/${orderId}`, { _id: orderId, customerId: uid, eventId: o.eventId, showId: ev?.showId || '', stageId: ev?.stageId || '', showName: show?.name || '', showImageUrl: show?.imageUrl || '', stageName: st?.name || '', eventDate: ev?.date || '', buySeats: o.seatIds, orderPrice: String(o.total), orderMethod: 'venue', paymentStatus: 'pay_at_venue', orderId, isPast: false });
  await guncelle(`Order/${orderId}`, { status: 'rezervasyon', ticketIds: [orderId] });
  return { ticketIds: [orderId], status: 'rezervasyon' };
}
async function cancelTicket(uid, { ticketId }) {
  if (typeof ticketId !== 'string' || !ticketId) throw new Hata('INVALID_ARGUMENT', 'Bilet belirtilmedi.');
  const t = await oku(`Ticket/${ticketId}`);
  if (!t) throw new Hata('NOT_FOUND', 'Bilet bulunamadı.');
  if (t.customerId !== uid) throw new Hata('PERMISSION_DENIED', 'Bu bilet sana ait değil.');
  if (!['venue', 'free'].includes(t.orderMethod) || ['paid', 'no_show', 'cancelled'].includes(t.paymentStatus)) throw new Hata('FAILED_PRECONDITION', 'Bu bilet iptal edilemez.');
  const when = tarihAyristir(t.eventDate);
  if (when && when.getTime() - Date.now() < IPTAL_SAAT * 3600e3) throw new Hata('FAILED_PRECONDITION', `Etkinliğe ${IPTAL_SAAT} saatten az kaldığı için bu bilet artık iptal edilemez.`);
  const alan = {}; (t.buySeats || []).forEach((id) => { alan[`seats.${id}`] = { status: 'available', customerId: null }; });
  await guncelle(`Event/${t.eventId}`, alan);
  await guncelle(`Ticket/${ticketId}`, { paymentStatus: 'cancelled', cancelledAt: Date.now() });
  return { ok: true };
}
async function startPayment(uid, { orderId, provider, returnUrl }) {
  const o = await siparisAl(uid, orderId);
  if ((await satisModu()) !== 'online') throw new Hata('FAILED_PRECONDITION', 'Online ödeme şu anda çalışmıyor. Rezervasyon yaparak sahnede ödeyebilirsin.');
  if (provider !== 'iyzico') throw new Hata('INVALID_ARGUMENT', 'Ödeme sağlayıcısı geçersiz.');
  if (o.free) throw new Hata('FAILED_PRECONDITION', 'Bu sipariş ücretsiz.');
  if (o.status !== 'held' || o.expiresAt < Date.now()) throw new Hata('FAILED_PRECONDITION', 'Süre doldu. Koltukları yeniden seç.');
  let u; try { u = new URL(returnUrl); } catch { throw new Hata('INVALID_ARGUMENT', 'Dönüş adresi geçersiz.'); }
  if (!['localhost', '127.0.0.1'].includes(u.hostname)) throw new Hata('INVALID_ARGUMENT', 'Dönüş adresi geçersiz.');
  await guncelle(`Order/${orderId}`, { status: 'paying' });
  // iyzico dönüşünü taklit et: gecikmeli webhook
  setTimeout(async () => {
    try {
      const g = await oku(`Order/${orderId}`);
      if (PAY_MODE === 'fail') await koltuklariSerbestBirak(g, 'failed'); else await satisTamamla(g, 'paid');
    } catch (e) { console.error('callback hatası', e.message); }
  }, PAY_DELAY);
  const donus = new URL('/odeme-sonuc', u.origin); donus.searchParams.set('order', orderId); donus.searchParams.set('durum', PAY_MODE === 'fail' ? 'hata' : 'basarili');
  return { provider: 'iyzico', paymentPageUrl: donus.href, token: 'mock-token' };
}

// Süresi dolan tutmaları temizle (gerçek backend'in zamanlanmış görevi gibi)
setInterval(async () => {
  try {
    for (const o of await listele('Order')) if (o.status === 'held' && o.expiresAt < Date.now()) { await koltuklariSerbestBirak({ ...o, _id: o.id }, 'expired'); console.log('süre doldu', o.id); }
  } catch {}
}, 2000);

const ISLEVLER = { requestAccountDeletion, cancelAccountDeletion, syncPhoneVerification, holdSeats, releaseHold, startPayment, confirmFree, confirmReservation, cancelTicket };
if (process.env.SATIS_MODE) yaz('Config/satis', { mode: process.env.SATIS_MODE, rezervasyonLimit: REZ_LIMIT, iptalSaat: IPTAL_SAAT }).then(() => console.log('Config/satis =', process.env.SATIS_MODE)).catch((e) => console.error(e.message));
const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-headers': 'authorization,content-type,firebase-instance-id-token,x-firebase-appcheck', 'access-control-allow-methods': 'POST,OPTIONS' };
http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') { res.writeHead(204, CORS); return res.end(); }
  const ad = req.url.split('?')[0].split('/').pop();
  const yanit = (kod, o) => { res.writeHead(kod, { ...CORS, 'content-type': 'application/json' }); res.end(JSON.stringify(o)); };
  try {
    if (!ISLEVLER[ad]) throw new Hata('NOT_FOUND', 'Fonksiyon yok.');
    let govde = ''; for await (const c of req) govde += c;
    const { data } = JSON.parse(govde || '{}');
    const uid = uidAl(req);
    if (TELEFONLU.has(ad) && !telefonAl(req)) throw new Hata('FAILED_PRECONDITION', 'PHONE_REQUIRED', { code: 'PHONE_REQUIRED' });
    if (SATIN_ALMA.has(ad) && (await oku(`User/${uid}`))?.deletionStatus === 'pending') throw new Hata('FAILED_PRECONDITION', 'ACCOUNT_DELETION_PENDING', { code: 'ACCOUNT_DELETION_PENDING' });
    const sonuc = await ISLEVLER[ad](uid, data || {}, req);
    yanit(200, { result: sonuc });
  } catch (e) {
    const st = e instanceof Hata ? e.status : 'INTERNAL';
    if (!(e instanceof Hata)) console.error(e);
    yanit(HTTP[st] || 500, { error: { message: e instanceof Hata ? e.message : 'INTERNAL', status: st, ...(e.details ? { details: e.details } : {}) } });
  }
}).listen(PORT, '127.0.0.1', () => console.log(`Sahte callable sunucusu http://127.0.0.1:${PORT} (HOLD_SECONDS=${HOLD}, PAY_MODE=${PAY_MODE})`));

'use strict';
// L-1: etkinlik başına bilet limiti (telefon bazlı) + getEventQuota ön sorgusu + global toplam limit bayrakları.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { normalizeSatis } = require('../src/orders');
const { db, makeService, seedEvent, uidN, clearDb, expectCode, keyFor, makeAdmin, clock } = H;

const P1 = '+905552220001', P2 = '+905552220002';
const REZ = { mode: 'rezervasyon', rezervasyonLimit: 0, iptalSaat: 1, etkinlikBasinaLimit: 3, ucretsizToplamLimit: 0 };
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };
const SEATS = ['A1', 'A2', 'A3', 'A4', 'A5'];

beforeEach(async () => { await clearDb(); });

async function reserve(svc, uid, phone, ev, seatIds) {
  const h = await svc.holdSeats(uid, { eventId: ev, seatIds }, { phone });
  await svc.confirmReservation(uid, { orderId: h.orderId }, { phone });
  return h;
}

test('aynı telefon, iki farklı uid: etkinlik limiti ortak; hata biçimi ve Türkçe mesaj', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent();
  const a = uidN(), b = uidN();
  await reserve(svc, a, P1, ev, ['A1', 'A2']);
  await svc.holdSeats(b, { eventId: ev, seatIds: ['A3'] }, { phone: P1 }); // 2 + 1 = 3, tam sınır
  const e = await expectCode(svc.holdSeats(b, { eventId: ev, seatIds: ['A3', 'A4'] }, { phone: P1 }), 'resource-exhausted');
  assert.equal(e.details.code, 'EVENT_LIMIT');
  assert.deepEqual({ ...e.details }, { code: 'EVENT_LIMIT', limit: 3, used: 2, remaining: 1, eventId: ev });
  assert.equal(e.message, 'Bu etkinlik için en fazla 3 bilet alabilirsin. Şu an 2 biletin var; 1 bilet daha alabilirsin.');
  // başka telefon etkilenmez
  await svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A4'] }, { phone: P2 });
});

test('3 bilet aldıktan sonra yeniden girip 3 daha almak mümkün değil (tüm yöntemler toplanır)', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent();
  const u = uidN();
  await reserve(svc, u, P1, ev, ['A1', 'A2', 'A3']);
  const e = await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] }, { phone: P1 }), 'resource-exhausted');
  assert.equal(e.details.code, 'EVENT_LIMIT');
  assert.equal(e.details.remaining, 0);
  // başka bir yöntemle (ücretli->ücretsiz farkı yok; aynı etkinlik) yine reddedilir
  await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A4'] }, { phone: P1 }), 'resource-exhausted');
});

test('biletlere yalnızca phoneKey ÖZETİ yazılır (düz telefon yok)', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent();
  const h = await reserve(svc, uidN(), P1, ev, ['A1']);
  const t = await get('Ticket', h.orderId);
  assert.equal(t.phoneKey, keyFor(P1));
  assert.equal(JSON.stringify(t).includes('5552220001'), false);
});

test('iptal hakkı iade eder (kullanıcı ve yönetici iptali); gelmedi sayılmaz', async () => {
  const { svc } = makeService({ satis: REZ });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const u = uidN();
  const h1 = await reserve(svc, u, P1, ev, ['A1', 'A2']);
  const h2 = await reserve(svc, u, P1, ev, ['A3']);
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] }, { phone: P1 }), 'resource-exhausted');
  await svc.cancelTicket(u, { ticketId: h1.orderId });
  const q = await svc.getEventQuota(u, { eventId: ev }, { phone: P1 });
  assert.equal(q.used, 1); assert.equal(q.remaining, 2);
  await svc.holdSeats(u, { eventId: ev, seatIds: ['A4', 'A5'] }, { phone: P1 }); // 1 + 2 = 3
  await svc.adminSetTicketStatus(admin, { ticketId: h2.orderId, paymentStatus: 'no_show' });
  assert.equal((await svc.getEventQuota(u, { eventId: ev }, { phone: P1 })).used, 0);
});

test('eşzamanlı iki hold (iki uid, tek telefon): toplam limit aşılamaz', async () => {
  const { svc } = makeService({ satis: REZ });
  for (let i = 0; i < 4; i++) {
    const ev = await seedEvent();
    const ph = '+90555222' + String(3000 + i);
    const res = await Promise.allSettled([
      svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: ph }),
      svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A3', 'A4'] }, { phone: ph }),
    ]);
    assert.equal(res.filter((r) => r.status === 'fulfilled').length, 1, `tur ${i}`);
    const rej = res.find((r) => r.status === 'rejected').reason;
    assert.equal(rej.details && rej.details.code, 'EVENT_LIMIT');
  }
});

test('tutulan (hold) koltuklar da sayılır: iki cihaz/uid, ayrı ayrı hold + onay', async () => {
  const loose = makeService({ satis: { ...REZ, etkinlikBasinaLimit: 5 } }).svc;
  const strict = makeService({ satis: REZ }).svc;
  const ev = await seedEvent();
  const a = uidN(), b = uidN();
  const ha = await loose.holdSeats(a, { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: P1 });
  const hb = await loose.holdSeats(b, { eventId: ev, seatIds: ['A3', 'A4'] }, { phone: P1 });
  const res = await Promise.allSettled([
    strict.confirmReservation(a, { orderId: ha.orderId }, { phone: P1 }),
    strict.confirmReservation(b, { orderId: hb.orderId }, { phone: P1 }),
  ]);
  // her biri diğerinin tutmasını görür: 2 + 2 > 3 -> ikisi de reddedilir (toplam 3 aşılmaz)
  assert.equal(res.filter((r) => r.status === 'fulfilled').length, 0);
  for (const r of res) assert.equal(r.reason.details.code, 'EVENT_LIMIT');
  // biri bırakınca diğeri onaylanır
  await strict.releaseHold(b, { orderId: hb.orderId });
  await strict.confirmReservation(a, { orderId: ha.orderId }, { phone: P1 });
});

test('eşzamanlı iki onay: confirm anında da sayılır (hold sonrası başka bilet alınmış)', async () => {
  const loose = makeService({ satis: { ...REZ, etkinlikBasinaLimit: 5 } }).svc;
  const strict = makeService({ satis: REZ }).svc;
  const ev = await seedEvent();
  const a = uidN();
  await reserve(loose, a, P1, ev, ['A1', 'A2']); // 2 bilet
  const h = await loose.holdSeats(a, { eventId: ev, seatIds: ['A3', 'A4'] }, { phone: P1 }); // gevşek limit: izinli
  const e = await expectCode(strict.confirmReservation(a, { orderId: h.orderId }, { phone: P1 }), 'resource-exhausted');
  assert.equal(e.details.code, 'EVENT_LIMIT');
  assert.equal(e.details.used, 2);
});

test('farklı etkinlikler birbirini etkilemez', async () => {
  const { svc } = makeService({ satis: REZ });
  const e1 = await seedEvent(), e2 = await seedEvent();
  await reserve(svc, uidN(), P1, e1, ['A1', 'A2', 'A3']);
  await reserve(svc, uidN(), P1, e2, ['A1', 'A2', 'A3']);
  assert.equal((await svc.getEventQuota(uidN(), { eventId: e1 }, { phone: P1 })).used, 3);
});

test('süresi dolan hold sayılmaz', async () => {
  const now = clock();
  const { svc } = makeService({ satis: REZ, now });
  const ev = await seedEvent();
  const u = uidN();
  await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] }, { phone: P1 });
  const q = await svc.getEventQuota(uidN(), { eventId: ev }, { phone: P1 });
  assert.equal(q.held, 3);
  now.advance(11 * 60 * 1000);
  const q2 = await svc.getEventQuota(uidN(), { eventId: ev }, { phone: P1 });
  assert.equal(q2.held, 0); assert.equal(q2.remaining, 3);
});

test('getEventQuota: sayılar doğru, kişisel veri sızmaz, telefonsuz PHONE_REQUIRED, yanlış etkinlik not-found, hız sınırı', async () => {
  const { svc } = makeService({ satis: { ...REZ, rezervasyonLimit: 5, ucretsizToplamLimit: 4 } });
  const ev = await seedEvent();
  const free = await seedEvent({ price: '0' });
  const u = uidN();
  await reserve(svc, u, P1, ev, ['A1']);
  const hf = await svc.holdSeats(u, { eventId: free, seatIds: ['A1', 'A2'] }, { phone: P1 });
  await svc.confirmFree(u, { orderId: hf.orderId }, { phone: P1 });
  await svc.holdSeats(u, { eventId: ev, seatIds: ['A2'] }, { phone: P1 });
  const q = await svc.getEventQuota(u, { eventId: ev }, { phone: P1 });
  assert.equal(q.limit, 3); assert.equal(q.sold, 0); assert.equal(q.reserved, 1); assert.equal(q.free, 0);
  assert.equal(q.used, 1); assert.equal(q.held, 1); assert.equal(q.remaining, 2);
  assert.deepEqual(q.global, { freeLimit: 4, freeUsed: 2, reservationLimit: 5, reservationUsed: 1 });
  const json = JSON.stringify(q);
  assert.equal(json.includes(u), false); assert.equal(json.includes('5552220001'), false); assert.equal(json.includes('ph_'), false);
  const qf = await svc.getEventQuota(u, { eventId: free }, { phone: P1 });
  assert.equal(qf.free, 2); assert.equal(qf.remaining, 1);

  const e = await expectCode(svc.getEventQuota(u, { eventId: ev }, { phone: null }), 'failed-precondition');
  assert.equal(e.details.code, 'PHONE_REQUIRED');
  await expectCode(svc.getEventQuota(u, { eventId: 'yok' }, { phone: P1 }), 'not-found');
  await expectCode(svc.getEventQuota(u, { eventId: 'a/b' }, { phone: P1 }), 'invalid-argument');
  let last;
  for (let i = 0; i < 40; i++) { try { await svc.getEventQuota(u, { eventId: ev }, { phone: P2 }); } catch (x) { last = x; break; } }
  assert.equal(last && last.code, 'resource-exhausted');
});

test('global bayraklar: varsayılan davranış korunur (ücretsiz toplam 3, rezervasyon toplam 3); 0 = KAPALI', async () => {
  const def = makeService({ satis: { mode: 'rezervasyon' } }).svc; // eksik alanlar -> varsayılan
  const f1 = await seedEvent({ price: '0' }), f2 = await seedEvent({ price: '0' });
  const u = uidN();
  const h = await def.holdSeats(u, { eventId: f1, seatIds: ['A1', 'A2', 'A3'] }, { phone: P1 });
  await def.confirmFree(u, { orderId: h.orderId }, { phone: P1 });
  const e = await expectCode(def.holdSeats(u, { eventId: f2, seatIds: ['A1'] }, { phone: P1 }), 'resource-exhausted');
  assert.equal(e.details.code, 'FREE_LIMIT');
  assert.equal(e.message, 'Ücretsiz etkinliklerde toplam en fazla 3 bilet alabilirsiniz.');
  // ucretsizToplamLimit 0: global kapalı, farklı etkinlikte yeniden alınabilir
  const off = makeService({ satis: { mode: 'rezervasyon', ucretsizToplamLimit: 0 } }).svc;
  await off.holdSeats(u, { eventId: f2, seatIds: ['A1'] }, { phone: P1 });
  // rezervasyon varsayılan 3 toplam
  const r1 = await seedEvent(), r2 = await seedEvent();
  const u2 = uidN();
  await reserve(def, u2, P2, r1, ['A1', 'A2', 'A3']);
  const h2 = await def.holdSeats(u2, { eventId: r2, seatIds: ['A1'] }, { phone: P2 });
  const e2 = await expectCode(def.confirmReservation(u2, { orderId: h2.orderId }, { phone: P2 }), 'resource-exhausted');
  assert.equal(e2.message, 'Toplam en fazla 3 rezervasyon yapabilirsiniz.');
  const offRes = makeService({ satis: { mode: 'rezervasyon', rezervasyonLimit: 0 } }).svc;
  await offRes.confirmReservation(u2, { orderId: h2.orderId }, { phone: P2 });
});

test('normalizeSatis: yeni alanların sınırları ve varsayılanları', () => {
  assert.equal(normalizeSatis(null).etkinlikBasinaLimit, 3);
  assert.equal(normalizeSatis(null).ucretsizToplamLimit, 3);
  assert.equal(normalizeSatis({ etkinlikBasinaLimit: 20 }).etkinlikBasinaLimit, 20);
  for (const bad of [0, 21, -1, 2.5, '3', null]) assert.equal(normalizeSatis({ etkinlikBasinaLimit: bad }).etkinlikBasinaLimit, 3);
  assert.equal(normalizeSatis({ ucretsizToplamLimit: 0 }).ucretsizToplamLimit, 0);
  assert.equal(normalizeSatis({ ucretsizToplamLimit: 51 }).ucretsizToplamLimit, 3);
});

test('Config/satis.etkinlikBasinaLimit = 5: 5 koltuk alınır, 6. reddedilir; 20 üstü tek çağrı reddedilir', async () => {
  const { svc } = makeService({ satis: { ...REZ, etkinlikBasinaLimit: 5 } });
  const ev = await seedEvent({ seatNames: Array.from({ length: 30 }, (_, i) => `S${i + 1}`) });
  await reserve(svc, uidN(), P1, ev, ['S1', 'S2', 'S3', 'S4', 'S5']);
  await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: ['S6'] }, { phone: P1 }), 'resource-exhausted');
  await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: Array.from({ length: 21 }, (_, i) => `S${i + 1}`) }, { phone: P2 }), 'resource-exhausted');
});

test('ödemesi süren (paying) sipariş de sayılır', async () => {
  const { svc } = makeService({ satis: { mode: 'online', etkinlikBasinaLimit: 3 } });
  const ev = await seedEvent({ price: '100' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] }, { phone: P1 });
  await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/x' }, { phone: P1 });
  const e = await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A4'] }, { phone: P1 }), 'resource-exhausted');
  assert.equal(e.details.used, 3);
});

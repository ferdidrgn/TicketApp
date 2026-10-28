'use strict';
// Hesap silme — ÇAPRAZ DENETİM testleri (28.10.2026): güvenli taraf (bilinmeyen tarih), yarış, aynı telefonla yeniden kayıt.
// Firestore + Auth emülatörü gerekir.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getAuth } = require('firebase-admin/auth');
const H = require('./helpers');
const { createAccountDeletion } = require('../src/accountDeletion');
const { db, makeService, seedEvent, eventDate, uidN, clearDb, expectCode, phoneFor, keyFor, TEST_SALT } = H;

const auth = getAuth();
const DAY = 864e5;
const silent = { error() {}, info() {}, warn() {} };
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };

beforeEach(async () => { await clearDb(); });

function sut({ clk, svc } = {}) {
  return createAccountDeletion({ db, auth, orderService: svc || makeService().raw, salt: TEST_SALT, now: clk || Date.now, log: silent, deleteProfileImage: async () => {} });
}
async function mkUser() {
  const uid = uidN();
  await auth.createUser({ uid, email: `${uid}@example.com`.toLowerCase() });
  await db.collection('User').doc(uid).set({ _id: uid, role: 'user', firstName: 'Ayşe', phoneNumber: phoneFor(uid), phoneKey: keyFor(phoneFor(uid)) });
  return uid;
}
const authGone = async (uid) => { try { await auth.getUser(uid); return false; } catch (e) { return e.code === 'auth/user-not-found'; } };

let n = 0;
/** Tarihi ayrıştırılamayan ve etkinliği bulunmayan aktif bilet. */
async function putBadDateTicket(uid) {
  const id = `bad${++n}_${Date.now()}`;
  await db.collection('Ticket').doc(id).set({
    _id: id, customerId: uid, eventId: 'yok-boyle-bir-etkinlik', orderId: id, orderMethod: 'venue', buySeats: ['B3'], paymentStatus: 'pay_at_venue',
    showName: 'Eski Oyun', eventDate: 'tarih bilinmiyor',
  });
  return id;
}
async function putPastTicket(uid) {
  const ev = await seedEvent({ date: eventDate(-5 * DAY) });
  const id = `past${++n}_${Date.now()}`;
  await db.collection('Ticket').doc(id).set({ _id: id, customerId: uid, eventId: ev, orderId: id, buySeats: ['A1'], paymentStatus: 'paid', showName: 'Geçmiş', eventDate: eventDate(-5 * DAY) });
  return id;
}

test('GÜVENLİ TARAF: tarihi ayrıştırılamayan aktif bilet "gelecek" sayılır -> istek reddedilir (nextEventDate yok), hiçbir veri değişmez; geçmiş bilet engellemez', async () => {
  const uid = await mkUser();
  await putBadDateTicket(uid);
  const e = await expectCode(sut().requestAccountDeletion(uid), 'failed-precondition');
  assert.equal(e.message, 'UPCOMING_TICKETS'); assert.equal(e.details.code, 'UPCOMING_TICKETS'); assert.equal(e.details.count, 1);
  assert.equal(e.details.nextEventDate, undefined);
  assert.equal(await get('AccountDeletion', uid), null);
  assert.ok(!(await authGone(uid)));
  const uid2 = await mkUser();
  await putPastTicket(uid2);
  assert.equal((await sut().requestAccountDeletion(uid2)).status, 'pending');
});

test('30. günde tarihi bilinmeyen bilet çıkmışsa silme 30 gün ertelenir (yönetici incelemesi), veri silinmez; bilet iptal edilince silinir', async () => {
  const uid = await mkUser();
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  const tid = await putBadDateTicket(uid);
  const r = await sut({ clk: () => t0 + 31 * DAY }).processDue();
  assert.equal(r.postponed, 1); assert.equal(r.deleted, 0);
  const rec = await get('AccountDeletion', uid);
  assert.equal(rec.lastPostponeReason, 'unparseable_ticket_date');
  assert.equal(rec.scheduledAt.toMillis(), t0 + 61 * DAY);
  assert.ok(!(await authGone(uid)));
  assert.equal((await get('Ticket', tid)).customerId, uid, 'bilet anonimleşmedi');
  await db.collection('Ticket').doc(tid).update({ paymentStatus: 'cancelled' }); // yönetici incelemesi sonucu
  const r2 = await sut({ clk: () => t0 + 62 * DAY }).processDue();
  assert.equal(r2.deleted, 1); assert.ok(await authGone(uid));
});

test('YARIŞ: aynı anda requestAccountDeletion ve ücretsiz bilet onayı -> asla "pending + aktif bilet" birlikte olmaz', async () => {
  const { svc, raw } = makeService();
  for (let i = 0; i < 6; i++) {
    const uid = await mkUser();
    const ev = await seedEvent({ price: '0' });
    const h = await svc.holdSeats(uid, { eventId: ev, seatIds: ['A1'] });
    const [conf, req] = await Promise.allSettled([svc.confirmFree(uid, { orderId: h.orderId }), sut({ svc: raw }).requestAccountDeletion(uid)]);
    const ticket = await get('Ticket', h.orderId);
    const rec = await get('AccountDeletion', uid);
    if (ticket && ticket.paymentStatus !== 'cancelled') {
      assert.notEqual(rec && rec.status, 'pending', `tur ${i}: bilet var ama hesap pending`);
      assert.equal(req.status, 'rejected', `tur ${i}: istek reddedilmeliydi`);
    } else {
      assert.equal(conf.status, 'rejected', `tur ${i}: bilet yokken onay reddedilmeliydi`);
      assert.equal(rec && rec.status, 'pending');
    }
  }
});

test('silme sonrası AYNI telefonla yeniden kayıt: yeni uid, ph_ sayacı korunur (ücretsiz bilet hakkı sıfırlanmaz)', async () => {
  const { svc, raw } = makeService();
  const uid = await mkUser();
  const phone = phoneFor(uid);
  await db.collection('UserLimits').doc(keyFor(phone)).set({ freeTickets: 2, reservations: 0 });
  await db.collection('UserLimits').doc(uid).set({ phoneKey: keyFor(phone), freeTickets: 2, reservations: 0 });
  const t0 = Date.now();
  await sut({ svc: raw, clk: () => t0 }).requestAccountDeletion(uid, { phone });
  await sut({ svc: raw, clk: () => t0 + 31 * DAY }).processDue();
  assert.ok(await authGone(uid));
  assert.equal((await get('UserLimits', keyFor(phone))).freeTickets, 2, 'telefon sayacı kalmalı');
  assert.equal(await get('UserLimits', uid), null);
  const uid2 = await mkUser(); // aynı telefon, yeni hesap
  // 2 (kalan sayaç) + 2 > 3: tutma aşamasında reddedilir
  await expectCode(svc.holdSeats(uid2, { eventId: await seedEvent({ price: '0' }), seatIds: ['A1', 'A2'] }, { phone }), 'resource-exhausted');
  const h1 = await svc.holdSeats(uid2, { eventId: await seedEvent({ price: '0' }), seatIds: ['A1'] }, { phone });
  await svc.confirmFree(uid2, { orderId: h1.orderId }, { phone }); // 2 + 1 = 3: son hak
});

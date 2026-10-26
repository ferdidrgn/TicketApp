'use strict';
// UÇTAN UCA ÖDEME: gerçek functions/index.js (Functions emülatörü) + Auth emülatörü + SAHTE iyzico sunucusu.
// Functions emülatörü IYZICO_BASE_URL'i functions/.env.local'dan (http://127.0.0.1:8787) ve sahte sırları
// functions/.secret.local'dan okur. Gerçek iyzico sandbox'ı DEĞİLDİR.
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, clearDb, seedEvent, PROJECT } = require('./helpers');
const { startMock } = require('./mock-iyzico/server');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
const RU = 'https://tiyatrol-web.web.app/odeme-sonuc';
let mock; let n = 0;

async function signUp() {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `e2e${++n}_${Date.now()}@example.com`, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
}
async function call(name, data, token) {
  const r = await fetch(url(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
/** iyzico'nun tarayıcıyı callbackUrl'e POST ettirmesi. */
async function browserCallback(token) {
  const r = await fetch(url('iyzicoCallback'), { method: 'POST', redirect: 'manual', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: `token=${encodeURIComponent(token)}` });
  return { status: r.status, location: r.headers.get('location') };
}
const get = async (col, id) => (await db.collection(col).doc(id).get()).data();
const ticketsOf = async (uid) => (await db.collection('Ticket').where('customerId', '==', uid).get()).docs.map((d) => d.data());

async function start(price = '120', seats = ['A1', 'A2']) {
  const ev = await seedEvent({ price, showId: `s${++n}` });
  const u = await signUp();
  const h = await call('holdSeats', { eventId: ev, seatIds: seats }, u.token);
  assert.equal(h.status, 200, JSON.stringify(h.body));
  const p = await call('startPayment', { orderId: h.body.result.orderId, provider: 'iyzico', returnUrl: RU }, u.token);
  assert.equal(p.status, 200, JSON.stringify(p.body));
  return { ev, u, orderId: h.body.result.orderId, hold: h.body.result, pay: p.body.result };
}

before(async () => {
  mock = await startMock({ port: 8787 });
  for (let i = 0; i < 60; i++) {
    try { const r = await call('holdSeats', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
after(async () => { await mock.close(); });
beforeEach(async () => { await clearDb(); mock.sessions.clear(); mock.log.length = 0; });

test('E2E mutlu yol: kayıt → holdSeats → startPayment → mock token → callback → Ticket + Notification, koltuklar sold', async () => {
  const { ev, u, orderId, hold, pay } = await start();
  assert.equal(hold.total, 240);
  assert.ok(pay.token.startsWith('mocktok_'));
  assert.ok(pay.checkoutFormContent.startsWith('<script>'));
  // sunucu iyzico'ya DOĞRU şekli gönderdi (mock zorunlu alanları ve imzayı denetler)
  const s = mock.sessions.get(pay.token).body;
  assert.equal(s.price, '240.00'); assert.equal(s.paidPrice, '240.00'); assert.equal(s.currency, 'TRY');
  assert.equal(s.basketId, orderId); assert.equal(s.conversationId, orderId); assert.equal(s.locale, 'tr');
  assert.ok(s.buyer.gsmNumber && s.buyer.identityNumber && s.buyer.email.includes('@'));
  assert.equal(s.basketItems[0].itemType, 'VIRTUAL'); assert.deepEqual(s.enabledInstallments, [1]);
  assert.match(s.callbackUrl, /\/iyzicoCallback$/);
  assert.equal((await get('Order', orderId)).status, 'paying');

  mock.pay(pay.token, 'success');
  const cb = await browserCallback(pay.token);
  assert.equal(cb.status, 302);
  assert.match(cb.location, new RegExp(`/odeme-sonuc\\?order=${orderId}&durum=basarili$`));

  const t = await ticketsOf(u.uid);
  assert.equal(t.length, 1);
  assert.deepEqual(t[0].buySeats, ['A1', 'A2']); assert.equal(t[0].orderPrice, '240.00'); assert.equal(t[0].orderMethod, 'card');
  const notes = await db.collection('Notification').where('userId', '==', u.uid).get();
  assert.equal(notes.size, 1);
  const o = await get('Order', orderId);
  assert.equal(o.status, 'paid'); assert.equal(o.paymentId, `pay_${pay.token}`);
  const seats = (await get('Event', ev)).seats;
  assert.deepEqual(seats.A1, { status: 'sold', orderId }); assert.deepEqual(seats.A2, { status: 'sold', orderId });
  assert.ok(!JSON.stringify(seats).includes(u.uid));
});

test('E2E aynı callback tekrar (ardışık + eşzamanlı) → tek bilet, tek bildirim', async () => {
  const { u, orderId, pay } = await start();
  mock.pay(pay.token, 'success');
  const rs = await Promise.all([1, 2, 3, 4].map(() => browserCallback(pay.token)));
  for (const r of rs) assert.match(r.location, /durum=basarili$/);
  await browserCallback(pay.token);
  assert.equal((await ticketsOf(u.uid)).length, 1);
  assert.equal((await db.collection('Notification').where('userId', '==', u.uid).get()).size, 1);
  assert.equal((await get('Order', orderId)).status, 'paid');
});

test('E2E tutarı oynanmış sonuç (paidPrice farklı) → bilet YOK, koltuk serbest, refundRequired', async () => {
  const { ev, u, orderId, pay } = await start();
  mock.pay(pay.token, 'success', { paidPrice: 1 });
  const cb = await browserCallback(pay.token);
  assert.match(cb.location, /durum=hata$/);
  assert.equal((await ticketsOf(u.uid)).length, 0);
  const o = await get('Order', orderId);
  assert.equal(o.status, 'failed'); assert.equal(o.refundRequired, true);
  assert.deepEqual((await get('Event', ev)).seats.A1, { status: 'available' });
});

test('E2E ödeme başarısız (kart reddi) → koltuk serbest, bilet yok, refundRequired YOK', async () => {
  const { ev, u, orderId, pay } = await start();
  mock.pay(pay.token, 'fail');
  assert.match((await browserCallback(pay.token)).location, /durum=hata$/);
  const o = await get('Order', orderId);
  assert.equal(o.status, 'failed'); assert.equal(o.refundRequired, undefined);
  assert.deepEqual((await get('Event', ev)).seats.A1, { status: 'available' });
  assert.equal((await ticketsOf(u.uid)).length, 0);
});

test('E2E sahte / başkasının token\'ı ile callback → bilet yok, sipariş değişmez', async () => {
  const a = await start('50', ['A1']);
  const b = await start('50', ['A1']);
  mock.pay(a.pay.token, 'success');
  // B'nin siparişi için A'nın token'ı gönderilemez: token → yalnızca A'nın siparişini kapatır
  assert.match((await browserCallback('mocktok_uydurma_123456')).location, /durum=hata$/);
  assert.equal((await get('Order', b.orderId)).status, 'paying');
  assert.equal((await ticketsOf(b.u.uid)).length, 0);
  await browserCallback(a.pay.token);
  assert.equal((await ticketsOf(a.u.uid)).length, 1);
  assert.equal((await ticketsOf(b.u.uid)).length, 0);
});

test('E2E süre dolmuş siparişe GEÇ başarılı callback (koltuk başkasında) → bilet yok, refundRequired; diğer kullanıcı etkilenmez', async () => {
  const { ev, u, orderId, pay } = await start('80', ['A1']);
  // zamanı geri al: ödeme penceresi doldu (sunucu saati değil, veri: holdExpiresAt/expiresAt geçmişte)
  const geri = Date.now() - 60e3;
  await db.collection('Event').doc(ev).update({ 'seats.A1.holdExpiresAt': geri });
  await db.collection('Order').doc(orderId).update({ expiresAt: new Date(geri) });
  // B koltuğu devralır (lazy takeover, gerçek callable)
  const b = await signUp();
  const hb = await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, b.token);
  assert.equal(hb.status, 200, JSON.stringify(hb.body));
  // A iyzico'da geç öder
  mock.pay(pay.token, 'success');
  assert.match((await browserCallback(pay.token)).location, /durum=hata$/);
  const o = await get('Order', orderId);
  assert.equal(o.status, 'failed'); assert.equal(o.refundRequired, true); assert.equal(o.failureReason, 'paid_but_unfulfillable');
  assert.equal((await ticketsOf(u.uid)).length, 0);
  assert.equal((await get('Event', ev)).seats.A1.orderId, hb.body.result.orderId);
});

test('E2E iyzico inceleme (fraudStatus 0): bilet verilmez, sipariş paying kalır', async () => {
  const { orderId, u, pay } = await start();
  mock.pay(pay.token, 'review');
  assert.match((await browserCallback(pay.token)).location, /durum=hata$/);
  assert.equal((await get('Order', orderId)).status, 'paying');
  assert.equal((await ticketsOf(u.uid)).length, 0);
  mock.pay(pay.token, 'success'); // inceleme onaylandı
  assert.match((await browserCallback(pay.token)).location, /durum=basarili$/);
  assert.equal((await ticketsOf(u.uid)).length, 1);
});

test('E2E ücretsiz akış: hold → confirmFree → bilet; iyzico\'ya HİÇ istek gitmez', async () => {
  const ev = await seedEvent({ price: '0', showId: 'free-e2e' });
  const u = await signUp();
  const h = await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, u.token);
  assert.equal(h.body.result.free, true);
  const pay = await call('startPayment', { orderId: h.body.result.orderId, provider: 'iyzico', returnUrl: RU }, u.token);
  assert.equal(pay.body.error.status, 'INVALID_ARGUMENT');
  const c = await call('confirmFree', { orderId: h.body.result.orderId }, u.token);
  assert.equal(c.status, 200);
  assert.equal((await ticketsOf(u.uid)).length, 1);
  assert.equal(mock.log.length, 0);
});

test('E2E başka kullanıcı başkasının siparişi için ödeme başlatamaz / bırakamaz', async () => {
  const { orderId } = await start();
  const x = await signUp();
  const p = await call('startPayment', { orderId, provider: 'iyzico', returnUrl: RU }, x.token);
  assert.equal(p.body.error.status, 'PERMISSION_DENIED');
  const r = await call('releaseHold', { orderId }, x.token);
  assert.equal(r.body.error.status, 'PERMISSION_DENIED');
});

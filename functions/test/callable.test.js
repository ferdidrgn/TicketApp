'use strict';
// Functions EMÜLATÖRÜ üzerinden uçtan uca: gerçek index.js, Auth emülatörü, HTTP.
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, clearDb, seedEvent, PROJECT, signInPhone, phoneFor } = require('./helpers');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;

async function signUp(email, { phone = true } = {}) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  if (!phone) return { token: j.idToken, uid: j.localId };
  // Satış callable'ları doğrulanmış telefon ister: e-posta hesabına SMS doğrulamasıyla telefon bağla (token'da phone_number olur).
  return signInPhone(phoneFor(email), j.idToken);
}
async function call(name, data, token) {
  const r = await fetch(url(name), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}

before(async () => {
  // Fonksiyon emülatörü yüklenene kadar bekle.
  for (let i = 0; i < 60; i++) {
    try { const r = await call('holdSeats', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); });

test('yetkisiz çağrı reddedilir (hepsi UNAUTHENTICATED)', { timeout: 240000 }, async () => {
  for (const n of ['holdSeats', 'releaseHold', 'startPayment', 'confirmFree', 'confirmReservation', 'cancelTicket', 'adminSetTicketStatus', 'adminCheckIn', 'adminHealth', 'adminStats', 'adminCancelled', 'adminNotifyPreview', 'adminSendNotification']) {
    const r = await call(n, { eventId: 'e', seatIds: ['A1'], orderId: 'o', provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app' });
    assert.equal(r.status, 401, n);
    assert.equal(r.body.error.status, 'UNAUTHENTICATED', n);
  }
});

test('giriş yapmış kullanıcı: istemci fiyatı yok sayılır, ücretsiz akış uçtan uca çalışır', async () => {
  const ev = await seedEvent({ price: '0' });
  const paid = await seedEvent({ price: '80', showId: 'show2' });
  const { token, uid } = await signUp('t1@example.com');

  const bad = await call('holdSeats', { eventId: ev, seatIds: [] }, token);
  assert.equal(bad.body.error.status, 'INVALID_ARGUMENT');

  const h = await call('holdSeats', { eventId: paid, seatIds: ['A1', 'A2'], total: 0.01, price: 0 }, token);
  assert.equal(h.status, 200);
  assert.equal(h.body.result.total, 160);
  assert.equal(h.body.result.free, false);

  const f = await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, token);
  assert.equal(f.body.result.free, true);
  const c = await call('confirmFree', { orderId: f.body.result.orderId }, token);
  assert.equal(c.status, 200);
  assert.deepEqual(c.body.result.ticketIds, [f.body.result.orderId]);
  assert.equal((await db.collection('Ticket').doc(f.body.result.orderId).get()).data().customerId, uid);

  // başka kullanıcı başkasının siparişini bırakamaz
  const other = await signUp('t2@example.com');
  const rel = await call('releaseHold', { orderId: h.body.result.orderId }, other.token);
  assert.equal(rel.body.error.status, 'PERMISSION_DENIED');
});

test('iyzicoCallback: sahte token 302 ile hata sayfasına yönlendirir, bilet üretmez', async () => {
  const r = await fetch(url('iyzicoCallback'), {
    method: 'POST', redirect: 'manual', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'token=sahte-token-123456',
  });
  assert.equal(r.status, 302);
  const loc = r.headers.get('location');
  assert.match(loc, /\/odeme-sonuc\?durum=hata$/);
  assert.equal((await db.collection('Ticket').get()).size, 0);
});

test('uçtan uca (gerçek index.js): varsayılan mod rezervasyon -> startPayment reddedilir, rezervasyon + iptal + admin kapı', async () => {
  const ev = await seedEvent({ price: '80' });
  const { token, uid } = await signUp('r1@example.com');
  const h = await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, token);
  assert.equal(h.status, 200);
  const sp = await call('startPayment', { orderId: h.body.result.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/odeme-sonuc' }, token);
  assert.equal(sp.body.error.status, 'FAILED_PRECONDITION');
  assert.match(sp.body.error.message, /Online ödeme şu anda çalışmıyor/);
  const cr = await call('confirmReservation', { orderId: h.body.result.orderId }, token);
  assert.equal(cr.status, 200);
  assert.equal(cr.body.result.status, 'rezervasyon');
  const t = (await db.collection('Ticket').doc(h.body.result.orderId).get()).data();
  assert.equal(t.paymentStatus, 'pay_at_venue'); assert.equal(t.customerId, uid);

  // admin olmayan yönetici işlevlerini çağıramaz
  for (const [n, d] of [['adminHealth', {}], ['adminStats', {}], ['adminNotifyPreview', { target: { type: 'all' } }], ['adminSendNotification', { target: { type: 'all' }, title: 'a', body: 'b', confirm: true }], ['adminCheckIn', { ticketId: t._id }], ['adminSetTicketStatus', { ticketId: t._id, paymentStatus: 'paid' }]]) {
    const r = await call(n, d, token);
    assert.equal(r.body.error.status, 'PERMISSION_DENIED', n);
  }
  await db.collection('User').doc(uid).set({ role: 'admin' });
  const ci = await call('adminCheckIn', { ticketId: t._id }, token);
  assert.equal(ci.body.result.ok, true);
  const ci2 = await call('adminCheckIn', { ticketId: t._id }, token);
  assert.equal(ci2.body.result.already, true);
  const hl = await call('adminHealth', {}, token);
  assert.equal(hl.status, 200);
  assert.equal(hl.body.result.reservations.total, 1);
});

test('trackView (gerçek index.js, HTTP): POST+izinli origin sayar; GET 405; kötü gövde 400; origin yok/bot/izinsiz sessiz 204 ve sayaç artmaz', async () => {
  await db.collection('Show').doc('show1').set({ name: 'x' });
  const UA = 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36';
  const post = (body, headers = {}) => fetch(url('trackView'), { method: 'POST', headers: { 'Content-Type': 'text/plain', 'User-Agent': UA, Origin: 'https://tiyatrol-web.web.app', ...headers }, body: typeof body === 'string' ? body : JSON.stringify(body) });
  const total = async () => { const d = (await db.collection('Stats').doc('views').collection('months').get()).docs[0]; return d ? d.data().total : 0; };
  const r1 = await post({ k: 'show', id: 'show1' });
  assert.equal(r1.status, 204);
  assert.equal(await total(), 1);
  assert.equal((await fetch(url('trackView'), { method: 'GET', headers: { Origin: 'https://tiyatrol-web.web.app' } })).status, 405);
  assert.equal((await post('{bozuk')).status, 400);
  assert.equal((await post({ k: 'show', id: '../x' })).status, 400);
  assert.equal((await post({ k: 'show', id: 'show1' }, { Origin: 'https://evil.example' })).status, 204);
  assert.equal((await post({ k: 'show', id: 'show1' }, { 'User-Agent': 'Googlebot/2.1' })).status, 204);
  assert.equal((await fetch(url('trackView'), { method: 'POST', headers: { 'Content-Type': 'application/json', 'User-Agent': UA }, body: JSON.stringify({ k: 'show', id: 'show1' }) })).status, 204); // origin yok
  assert.equal(await total(), 1);
  const pre = await fetch(url('trackView'), { method: 'OPTIONS', headers: { Origin: 'https://tiyatrol-web.web.app', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type' } });
  assert.ok(pre.status < 300); assert.equal(pre.headers.get('access-control-allow-origin'), 'https://tiyatrol-web.web.app');
});

test('adminSendNotification (gerçek index.js, HTTP): yönetici olmayan reddedilir; yönetici kişiye gönderir (FCM yoksa başarısız sayılır, uygulama içi yazılır)', async () => {
  const { token, uid } = await signUp('nf1@example.com');
  const denied = await call('adminSendNotification', { target: { type: 'user', id: uid }, title: 'a', body: 'b' }, token);
  assert.equal(denied.body.error.status, 'PERMISSION_DENIED');
  await db.collection('User').doc(uid).set({ role: 'admin' });
  const ok = await call('adminSendNotification', { target: { type: 'user', id: uid }, title: 'Test', body: 'Merhaba', requestId: 'e2e_istek_0001' }, token);
  assert.equal(ok.status, 200);
  assert.equal(ok.body.result.recipients, 1); assert.equal(ok.body.result.withToken, 0); // token yok -> FCM'e hiç gidilmez
  assert.equal((await db.collection('Notification').where('userId', '==', uid).get()).size, 1);
  const again = await call('adminSendNotification', { target: { type: 'user', id: uid }, title: 'Test', body: 'Merhaba', requestId: 'e2e_istek_0001' }, token);
  assert.equal(again.body.result.duplicate, true);
  const st = await call('adminStats', {}, token);
  assert.equal(st.status, 200); assert.equal(st.body.result.trend.months.length, 12);
});

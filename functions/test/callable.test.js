'use strict';
// Functions EMÜLATÖRÜ üzerinden uçtan uca: gerçek index.js, Auth emülatörü, HTTP.
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, clearDb, seedEvent, PROJECT } = require('./helpers');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;

async function signUp(email) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
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

test('yetkisiz çağrı reddedilir (hepsi UNAUTHENTICATED)', async () => {
  for (const n of ['holdSeats', 'releaseHold', 'startPayment', 'confirmFree']) {
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

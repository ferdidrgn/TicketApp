'use strict';
// Ekip yöneticisi callable'ları — gerçek index.js, Functions + Auth emülatörü, HTTP (guarded, App Check, HttpsError eşlemesi).
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, clearDb, eventDate, PROJECT, Timestamp } = require('./helpers');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;

async function signUp(email) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
}
async function call(name, data, token) {
  const r = await fetch(url(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
const NAMES = ['getMyManagedTeams', 'teamNotifyPreview', 'teamSendNotification', 'teamCheckIn', 'teamStats', 'adminSetTeamManager'];

before(async () => {
  for (let i = 0; i < 60; i++) {
    try { const r = await call('getMyManagedTeams', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); });

test('team callable\'ları girişsiz 401 UNAUTHENTICATED', async () => {
  for (const n of NAMES) { const r = await call(n, {}); assert.equal(r.status, 401, n); assert.equal(r.body.error.status, 'UNAUTHENTICATED', n); }
});

test('uçtan uca: yönetici kendi seansına gönderir, başka ekibe PERMISSION_DENIED, atama yalnız admin; kapı yalnız kendi bileti', async () => {
  const mgr = await signUp('mgr-e2e@example.com');
  const other = await signUp('other-e2e@example.com');
  const adm = await signUp('adm-e2e@example.com');
  await db.collection('User').doc(adm.uid).set({ role: 'admin', firstName: 'A', lastName: 'D' });
  await db.collection('User').doc(mgr.uid).set({ role: 'user', firstName: 'M', lastName: 'G' });
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' }); await db.collection('Team').doc('tB').set({ name: 'Ekip B' });
  await db.collection('Stage').doc('st1').set({ name: 'Sahne 1' });
  await db.collection('Show').doc('sA').set({ name: 'Hamlet', teamId: 'tA', eventsId: ['eA'] });
  await db.collection('Show').doc('sB').set({ name: 'Macbeth', teamId: 'tB', eventsId: ['eB'] });
  await db.collection('Event').doc('eA').set({ _id: 'eA', showId: 'sA', stageId: 'st1', date: eventDate(3600e3), price: '100', seats: { A1: { status: 'sold' } } });
  await db.collection('Event').doc('eB').set({ _id: 'eB', showId: 'sB', stageId: 'st1', date: eventDate(3600e3), price: '100', seats: {} });
  await db.collection('User').doc('cust1').set({ role: 'user', firstName: 'Mus', lastName: 'Teri' }); // fcmToken yok -> yalnız uygulama içi kutu
  await db.collection('Ticket').doc('tkA').set({ _id: 'tkA', customerId: 'cust1', eventId: 'eA', showId: 'sA', buySeats: ['A1'], paymentStatus: 'pay_at_venue', showName: 'Hamlet', stageName: 'Sahne 1', eventDate: '' });
  await db.collection('Ticket').doc('tkB').set({ _id: 'tkB', customerId: 'cust1', eventId: 'eB', showId: 'sB', buySeats: ['A1'], paymentStatus: 'pay_at_venue' });

  // atama: yönetici/herkes yapamaz, admin yapar
  let r = await call('adminSetTeamManager', { teamId: 'tA', email: 'mgr-e2e@example.com', action: 'add' }, mgr.token);
  assert.equal(r.body.error.status, 'PERMISSION_DENIED');
  r = await call('adminSetTeamManager', { teamId: 'tA', email: 'mgr-e2e@example.com', action: 'add' }, adm.token);
  assert.equal(r.status, 200); assert.equal(r.body.result.status, 'active');

  r = await call('getMyManagedTeams', {}, mgr.token);
  assert.equal(r.body.result.teams.length, 1); assert.equal(r.body.result.teams[0].shows[0].events[0].eventId, 'eA');
  assert.equal((await call('getMyManagedTeams', {}, other.token)).body.result.teams.length, 0);

  const pv = await call('teamNotifyPreview', { target: { type: 'event', id: 'eA' }, template: 'basladi' }, mgr.token);
  assert.equal(pv.body.result.recipients, 1);
  const rid = 'rid_e2e_000001';
  const ok = await call('teamSendNotification', { target: { type: 'event', id: 'eA' }, template: 'basladi', confirm: true, requestId: rid }, mgr.token);
  assert.equal(ok.status, 200); assert.equal(ok.body.result.recipients, 1); assert.equal(ok.body.result.inApp, 1);
  const log = (await db.collection('NotificationLog').get()).docs.map((d) => d.data())[0];
  assert.equal(log.sentByRole, 'teamManager'); assert.equal(log.teamId, 'tA');
  const dup = await call('teamSendNotification', { target: { type: 'event', id: 'eA' }, template: 'basladi', confirm: true, requestId: rid }, mgr.token);
  assert.equal(dup.body.result.duplicate, true);

  const bad = await call('teamSendNotification', { target: { type: 'event', id: 'eB' }, template: 'basladi', confirm: true, requestId: 'rid_e2e_000002' }, mgr.token);
  assert.equal(bad.body.error.status, 'PERMISSION_DENIED');
  const all = await call('teamSendNotification', { target: { type: 'all' }, template: 'genel', title: 'a', body: 'b', confirm: true, requestId: 'rid_e2e_000003' }, mgr.token);
  assert.equal(all.body.error.status, 'PERMISSION_DENIED');
  const url1 = await call('teamSendNotification', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'a', body: 'bak http://x.com', confirm: true, requestId: 'rid_e2e_000004' }, mgr.token);
  assert.equal(url1.body.error.status, 'INVALID_ARGUMENT');

  const ci = await call('teamCheckIn', { ticketId: 'tkA', eventId: 'eA' }, mgr.token);
  assert.equal(ci.body.result.ok, true);
  assert.ok(!JSON.stringify(ci.body).includes('cust1') && !JSON.stringify(ci.body).includes('Mus'));
  assert.equal((await call('teamCheckIn', { ticketId: 'tkB' }, mgr.token)).body.error.status, 'NOT_FOUND');
  const st = await call('teamStats', {}, mgr.token);
  assert.equal(st.body.result.shows[0].events[0].checkedIn, 1);
});

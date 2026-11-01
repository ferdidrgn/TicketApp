'use strict';
// Arkadaşa gönder / grup planı (F-6). Gerçek index.js, Functions + Auth + Firestore emülatörü, HTTP; kurallar rules-unit-testing ile.
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { getAuth } = require('firebase-admin/auth');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, getDocs, collection } = require('firebase/firestore');
const { db, clearDb, PROJECT, eventDate, TEST_SALT } = require('./helpers');
const { createAccountDeletion } = require('../src/accountDeletion');
const cfg = require('../src/config');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
const DAY = 864e5;
const silent = { error() {}, info() {}, warn() {} };
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };

async function call(name, data, token) {
  const r = await fetch(url(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
const errOf = (r) => r.body.error || {};
async function signUpEmail(prefix) {
  const email = `${prefix}-${Math.random().toString(36).slice(2, 8)}@example.com`;
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error('signUp başarısız: ' + JSON.stringify(j));
  return { token: j.idToken, uid: j.localId };
}
async function anonUser() {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ returnSecureToken: true }) });
  const j = await r.json(); return { token: j.idToken, uid: j.localId };
}
let ck = 0;
const key = () => `devicekey${String(++ck).padStart(8, '0')}abcdef`;
const respond = (planId, o = {}) => call('respondPlan', { planId, name: 'Deniz', choice: 'gelirim', clientKey: key(), ...o });

async function seed() {
  await db.collection('Show').doc('s1').set({ name: 'Hamlet', eventsId: ['eArr'] });
  await db.collection('Event').doc('e1').set({ showId: 's1', date: eventDate(3 * DAY), price: '100', seats: {} });
  await db.collection('Event').doc('ePast').set({ showId: 's1', date: eventDate(-3 * DAY), seats: {} });
  await db.collection('Event').doc('eOther').set({ showId: 'sX', date: eventDate(3 * DAY), seats: {} });
  await db.collection('Event').doc('eArr').set({ date: eventDate(4 * DAY), seats: {} }); // showId boş -> Show.eventsId yedeği
}
async function newPlan(u, o = { showId: 's1', eventId: 'e1' }) {
  const r = await call('createPlan', o, u.token);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  return r.body.result.id;
}

before(async () => {
  for (let i = 0; i < 60; i++) {
    try { const r = await call('respondPlan', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); await seed(); });

test('createPlan: girişli kullanıcı plan üretir; belgede oluşturan kimliği YOK; TTL alanı 7 gün; sahip kaydı ayrı ve kapalı', async () => {
  const u = await signUpEmail('own');
  const t0 = Date.now();
  const r = await call('createPlan', { showId: 's1', eventId: 'e1' }, u.token);
  assert.equal(r.status, 200);
  const id = r.body.result.id;
  assert.match(id, /^[A-Za-z0-9]{12}$/); assert.equal(r.body.result.path, `/plan/${id}`);
  const p = await get('Plan', id);
  assert.equal(p.showName, 'Hamlet'); assert.equal(p.showId, 's1'); assert.equal(p.eventId, 'e1');
  assert.ok(!JSON.stringify(p).includes(u.uid), 'plan belgesinde uid olmamalı');
  for (const k of Object.keys(p)) assert.ok(!/creator|owner|uid|name$|phone|mail/i.test(k) || k === 'showName', `beklenmeyen alan: ${k}`);
  const exp = p.expireAt.toMillis();
  assert.ok(Math.abs(exp - (t0 + cfg.PLAN.TTL_MS)) < 60e3, 'expireAt ~7 gün');
  assert.equal(p.eventDate.toMillis() > t0, true);
  assert.equal((await get('PlanOwner', id)).creatorUid, u.uid);
  // seansız (oyun planı) + Show.eventsId yedeği
  assert.equal((await call('createPlan', { showId: 's1' }, u.token)).status, 200);
  assert.equal((await call('createPlan', { showId: 's1', eventId: 'eArr' }, u.token)).status, 200);
});

test('createPlan reddedilenler: girişsiz 401, anonim, başka oyunun seansı, geçmiş seans, olmayan oyun/seans, hesap silme beklemede', async () => {
  const u = await signUpEmail('own');
  assert.equal((await call('createPlan', { showId: 's1' })).status, 401);
  const an = await anonUser();
  assert.equal(errOf(await call('createPlan', { showId: 's1' }, an.token)).status, 'PERMISSION_DENIED');
  assert.equal((await call('createPlan', { showId: 's1', eventId: 'eOther' }, u.token)).status, 400);
  assert.equal(errOf(await call('createPlan', { showId: 's1', eventId: 'ePast' }, u.token)).status, 'FAILED_PRECONDITION');
  assert.equal((await call('createPlan', { showId: 'yok' }, u.token)).status, 404);
  assert.equal((await call('createPlan', { showId: 's1', eventId: 'yok' }, u.token)).status, 404);
  assert.ok((await call('createPlan', { eventId: 'e1' }, u.token)).status >= 400);
  await db.collection('AccountDeletion').doc(u.uid).set({ uid: u.uid, status: 'pending', scheduledAt: new Date(Date.now() + DAY) });
  assert.equal(errOf(await call('createPlan', { showId: 's1' }, u.token)).details.code, 'ACCOUNT_DELETION_PENDING');
});

test('createPlan hız sınırı: kullanıcı başına saatlik tavan; küresel günlük plan tavanı', async () => {
  const u = await signUpEmail('own'); let last;
  for (let i = 0; i < cfg.PLAN.CREATE.perHour + 1; i++) last = await call('createPlan', { showId: 's1' }, u.token);
  assert.equal(errOf(last).status, 'RESOURCE_EXHAUSTED');
  // küresel tavan: bugünkü sayaç dolu gösterilir
  const u2 = await signUpEmail('own2');
  const day = new Date(Date.now() + 3 * 3600e3).toISOString().slice(0, 10);
  await db.collection('PlanLimits').doc(`day_${day}`).set({ plans: cfg.PLAN.GLOBAL_DAILY.plans });
  assert.equal(errOf(await call('createPlan', { showId: 's1' }, u2.token)).status, 'RESOURCE_EXHAUSTED');
});

test('respondPlan: GİRİŞSİZ yanıt; sayaçlar doğru; aynı cihaz değiştirince eskisi -1 yenisi +1; sayı artmaz', async () => {
  const u = await signUpEmail('own'); const id = await newPlan(u);
  const k = key();
  let r = await call('respondPlan', { planId: id, name: 'Deniz', choice: 'gelirim', clientKey: k });
  assert.equal(r.status, 200, JSON.stringify(r.body)); assert.equal(r.body.result.created, true);
  await respond(id, { name: 'Ece', choice: 'belki' });
  let p = await get('Plan', id); assert.deepEqual(p.counts, { gelirim: 1, belki: 1, gelemem: 0 }); assert.equal(p.responseCount, 2);
  r = await call('respondPlan', { planId: id, name: 'Deniz K', choice: 'gelemem', clientKey: k });
  assert.equal(r.body.result.created, false);
  p = await get('Plan', id); assert.deepEqual(p.counts, { gelirim: 0, belki: 1, gelemem: 1 }); assert.equal(p.responseCount, 2);
  // yanıt belgesi: düz cihaz anahtarı saklanmaz, uid/IP yok, TTL alanı var
  const rs = await db.collection('Plan').doc(id).collection('responses').get();
  assert.equal(rs.size, 2);
  for (const d of rs.docs) {
    assert.ok(!d.id.includes(k)); assert.ok(d.data().expireAt); assert.deepEqual(Object.keys(d.data()).sort(), ['choice', 'expireAt', 'name', 'updatedAt', 'updates']);
  }
});

test('respondPlan doğrulama: ad süzgeci (küfür/URL/e-posta/telefon/etiket), 30 karakter, geçersiz yanıt/plan/anahtar, süresi dolmuş/yok plan', async () => {
  const u = await signUpEmail('own'); const id = await newPlan(u);
  for (const name of ['siktir git', 'https://x.com', 'a@b.com', '05551234567', '<b>x</b>', '', '   ', 'x'.repeat(31), '@kullanici']) {
    assert.equal((await respond(id, { name })).status, 400, name);
  }
  assert.equal((await respond(id, { choice: 'hepsi' })).status, 400);
  assert.equal((await respond(id, { clientKey: 'kisa' })).status, 400);
  assert.equal((await respond('../x/y', {})).status, 400);
  assert.equal((await respond('AbCdEfGhIjKl', {})).status, 404);
  assert.equal((await respond(id, { name: 'Ayşe Nur-Ç' })).status, 200);
  assert.equal((await get('Plan', id)).responseCount, 1);
  await db.collection('Plan').doc(id).update({ expireAt: new Date(Date.now() - 1000) });
  assert.equal((await respond(id, {})).status, 404);
});

test('plan başına en fazla 50 yanıt; yanıt başına en fazla 10 değiştirme; küresel günlük yanıt tavanı', async () => {
  const u = await signUpEmail('own'); const id = await newPlan(u);
  await db.collection('Plan').doc(id).update({ responseCount: cfg.PLAN.MAX_RESPONSES });
  assert.equal(errOf(await respond(id)).status, 'RESOURCE_EXHAUSTED');
  await db.collection('Plan').doc(id).update({ responseCount: 0 });
  const k = key(); let last;
  for (let i = 0; i < cfg.PLAN.UPDATES_MAX + 2; i++) last = await call('respondPlan', { planId: id, name: 'Deniz', choice: i % 2 ? 'belki' : 'gelirim', clientKey: k });
  assert.equal(errOf(last).status, 'RESOURCE_EXHAUSTED');
  const day = new Date(Date.now() + 3 * 3600e3).toISOString().slice(0, 10);
  await db.collection('PlanLimits').doc(`day_${day}`).set({ responses: cfg.PLAN.GLOBAL_DAILY.responses });
  assert.equal(errOf(await respond(id)).status, 'RESOURCE_EXHAUSTED');
});

test('getPlanResponses: yalnız plan sahibi görür; ad + yanıt döner, başka kişisel alan YOK', async () => {
  const o = await signUpEmail('own'), x = await signUpEmail('other'); const id = await newPlan(o);
  await respond(id, { name: 'Deniz', choice: 'gelirim' }); await respond(id, { name: 'Ece', choice: 'belki' });
  assert.equal(errOf(await call('getPlanResponses', { planId: id }, x.token)).status, 'PERMISSION_DENIED');
  assert.equal((await call('getPlanResponses', { planId: id })).status, 401);
  const r = await call('getPlanResponses', { planId: id }, o.token);
  assert.equal(r.status, 200);
  assert.deepEqual(r.body.result.items.map((i) => i.name).sort(), ['Deniz', 'Ece']);
  for (const i of r.body.result.items) assert.deepEqual(Object.keys(i).sort(), ['at', 'choice', 'name']);
});

test('hesap silme: kullanıcının planları + yanıtlar + sahip kaydı + limit silinir; başkasının planı kalır', async () => {
  const a = await signUpEmail('own'), b = await signUpEmail('own2');
  const pa = await newPlan(a), pb = await newPlan(b);
  await respond(pa); await respond(pb);
  await createAccountDeletion({ db, auth: getAuth(), salt: TEST_SALT, log: silent }).purge(a.uid);
  assert.equal(await get('Plan', pa), null); assert.equal(await get('PlanOwner', pa), null); assert.equal(await get('PlanLimits', a.uid), null);
  assert.equal((await db.collection('Plan').doc(pa).collection('responses').get()).size, 0);
  assert.ok(await get('Plan', pb)); assert.equal((await db.collection('Plan').doc(pb).collection('responses').get()).size, 1);
});

let env;
const [h, pt] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
test('kurallar: Plan tek belge herkese okunur ama LİSTELENEMEZ; yanıtlar/sahip/limit kapalı; istemci hiçbir şey yazamaz', async () => {
  env = await initializeTestEnvironment({ projectId: 'rules-test', firestore: { host: h, port: Number(pt), rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8') } });
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (c) => {
      const d = c.firestore();
      await setDoc(doc(d, 'User/admin1'), { role: 'admin' });
      await setDoc(doc(d, 'Plan/pl1'), { showId: 's1', counts: { gelirim: 0 }, responseCount: 0 });
      await setDoc(doc(d, 'Plan/pl1/responses/k1'), { name: 'Deniz', choice: 'gelirim' });
      await setDoc(doc(d, 'PlanOwner/pl1'), { creatorUid: 'alice' });
      await setDoc(doc(d, 'PlanLimits/alice'), { hourCount: 1 });
    });
    const as = (u) => env.authenticatedContext(u).firestore(), anon = () => env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon(), 'Plan/pl1')));
    await assertFails(getDocs(collection(anon(), 'Plan')));
    await assertFails(getDocs(collection(as('alice'), 'Plan')));
    for (const ctx of [anon(), as('alice'), as('admin1')]) {
      await assertFails(setDoc(doc(ctx, 'Plan/pl2'), { showId: 's1' }));
      await assertFails(updateDoc(doc(ctx, 'Plan/pl1'), { 'counts.gelirim': 50 }));
      await assertFails(deleteDoc(doc(ctx, 'Plan/pl1')));
      await assertFails(getDoc(doc(ctx, 'Plan/pl1/responses/k1')));
      await assertFails(getDocs(collection(ctx, 'Plan/pl1/responses')));
      await assertFails(setDoc(doc(ctx, 'Plan/pl1/responses/k2'), { name: 'x', choice: 'belki' }));
      await assertFails(getDoc(doc(ctx, 'PlanOwner/pl1')));
      await assertFails(setDoc(doc(ctx, 'PlanOwner/pl1'), { creatorUid: 'bob' }));
      await assertFails(getDoc(doc(ctx, 'PlanLimits/alice')));
    }
  } finally { await env.cleanup(); }
});

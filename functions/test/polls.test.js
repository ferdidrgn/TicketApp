'use strict';
// Anket / oylama (F-5). Gerçek index.js, Functions + Auth + Firestore emülatörü, HTTP; kurallar ayrıca rules-unit-testing ile.
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { getAuth } = require('firebase-admin/auth');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, getDocs, collection } = require('firebase/firestore');
const { db, clearDb, PROJECT, signInPhone, TEST_SALT } = require('./helpers');
const { createAccountDeletion } = require('../src/accountDeletion');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
const HOUR = 36e5, DAY = 864e5;
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };
const silent = { error() {}, info() {}, warn() {} };

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
let ph = 0;
const nextPhone = () => `+90555888${String(1000 + ++ph)}`;
const phoneUser = async (phone = nextPhone()) => { const u = await signInPhone(phone); await db.collection('User').doc(u.uid).set({ _id: u.uid, role: 'user' }); return { ...u, phone }; };
async function adminUser() { const a = await signUpEmail('adm'); await db.collection('User').doc(a.uid).set({ _id: a.uid, role: 'admin' }); return a; }

const seedPoll = (extra = {}) => ({
  question: 'Sonraki sezon hangisi?', options: [{ label: 'Hamlet' }, { label: 'Macbeth' }, { label: 'Othello', showId: 's1' }],
  endsAt: new Date(Date.now() + 3 * DAY).toISOString(), ...extra,
});
async function newPoll(admin, extra) {
  const r = await call('adminCreatePoll', seedPoll(extra), admin.token);
  assert.equal(r.status, 200, JSON.stringify(r.body));
  return r.body.result.id;
}
const vote = (token, pollId, optionId) => call('votePoll', { pollId, optionId }, token);

before(async () => {
  for (let i = 0; i < 60; i++) {
    try { const r = await call('myPollVote', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); await db.collection('Show').doc('s1').set({ name: 'Othello' }); });

test('admin: anket oluşturur (2-6 seçenek, metin süzgeci, tarih); admin olmayan reddedilir; kapatma/yeniden açma', async () => {
  const adm = await adminUser(), u = await phoneUser();
  assert.equal(errOf(await call('adminCreatePoll', seedPoll(), u.token)).status, 'PERMISSION_DENIED');
  assert.equal((await call('adminCreatePoll', seedPoll())).status, 401);
  for (const bad of [
    { options: [{ label: 'Tek' }] }, { options: Array.from({ length: 7 }, (_, i) => ({ label: 'S' + i })) },
    { question: 'siktir' }, { question: 'Bak https://x.com' }, { options: [{ label: 'A' }, { label: 'a' }] },
    { endsAt: new Date(Date.now() - DAY).toISOString() }, { endsAt: 'bozuk' }, { options: [{ label: 'A' }, { label: 'B', showId: 'yok' }] },
    { endsAt: new Date(Date.now() + 400 * DAY).toISOString() },
  ]) {
    const r = await call('adminCreatePoll', seedPoll(bad), adm.token);
    assert.ok(r.status >= 400, JSON.stringify(bad));
  }
  const id = await newPoll(adm);
  const p = await get('Poll', id);
  assert.deepEqual(p.counts, { o1: 0, o2: 0, o3: 0 }); assert.equal(p.totalVotes, 0); assert.equal(p.status, 'active');
  assert.equal(p.options[2].showId, 's1'); assert.equal(p.createdBy, undefined, 'admin kimliği kamuya açık belgede olmamalı');
  assert.equal((await call('adminClosePoll', { pollId: id }, adm.token)).status, 200);
  assert.equal((await get('Poll', id)).status, 'closed');
  assert.equal((await call('adminClosePoll', { pollId: id, reopen: true }, adm.token)).status, 200);
  assert.equal((await get('Poll', id)).status, 'active');
  assert.equal(errOf(await call('adminClosePoll', { pollId: id }, u.token)).status, 'PERMISSION_DENIED');
});

test('tek oy: ilk oy +1; aynı seçenek tekrarı sayacı artırmaz; değiştirme eskisini -1 yenisini +1 (toplam sabit)', async () => {
  const adm = await adminUser(), u = await phoneUser(); const id = await newPoll(adm);
  assert.equal((await vote(u.token, id, 'o1')).body.result.changed, true);
  let p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 1, o2: 0, o3: 0 }); assert.equal(p.totalVotes, 1);
  const again = await vote(u.token, id, 'o1');
  assert.equal(again.body.result.changed, false);
  p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 1, o2: 0, o3: 0 }); assert.equal(p.totalVotes, 1);
  const ch = await vote(u.token, id, 'o2');
  assert.equal(ch.body.result.replaced, true);
  p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 0, o2: 1, o3: 0 }); assert.equal(p.totalVotes, 1);
  assert.equal((await get('Poll', id).then(() => db.collection('Poll').doc(id).collection('votes').doc(u.uid).get())).data().optionId, 'o2');
  assert.equal((await call('myPollVote', { pollId: id }, u.token)).body.result.optionId, 'o2');
  const u2 = await phoneUser(); await vote(u2.token, id, 'o2');
  p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 0, o2: 2, o3: 0 }); assert.equal(p.totalVotes, 2);
});

test('eşzamanlı oylar: 8 farklı kullanıcı -> sayaç tam doğru', async () => {
  const adm = await adminUser(); const id = await newPoll(adm);
  const us = []; for (let i = 0; i < 8; i++) us.push(await phoneUser());
  const rs = await Promise.all(us.map((u, i) => vote(u.token, id, i % 2 ? 'o1' : 'o3')));
  rs.forEach((r) => assert.equal(r.status, 200, JSON.stringify(r.body)));
  const p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 4, o2: 0, o3: 4 }); assert.equal(p.totalVotes, 8);
});

test('reddedilenler: girişsiz 401, telefonsuz PHONE_REQUIRED, geçersiz seçenek/anket, bitmiş/kapalı/başlamamış anket', async () => {
  const adm = await adminUser(), u = await phoneUser(), e = await signUpEmail('nophone'); const id = await newPoll(adm);
  assert.equal((await call('votePoll', { pollId: id, optionId: 'o1' })).status, 401);
  const np = await vote(e.token, id, 'o1');
  assert.equal(errOf(np).status, 'FAILED_PRECONDITION'); assert.equal(errOf(np).details.code, 'PHONE_REQUIRED');
  assert.equal((await vote(u.token, id, 'o9')).status, 400);
  assert.equal((await vote(u.token, 'yok', 'o1')).status, 404);
  assert.ok((await call('votePoll', { pollId: id }, u.token)).status >= 400);
  // süresi bitmiş
  await db.collection('Poll').doc(id).update({ endsAt: new Date(Date.now() - 1000) });
  assert.equal(errOf(await vote(u.token, id, 'o1')).status, 'FAILED_PRECONDITION');
  // admin kapattı
  await db.collection('Poll').doc(id).update({ endsAt: new Date(Date.now() + DAY) });
  await call('adminClosePoll', { pollId: id }, adm.token);
  assert.equal(errOf(await vote(u.token, id, 'o1')).status, 'FAILED_PRECONDITION');
  // henüz başlamamış
  const id2 = await newPoll(adm, { startsAt: new Date(Date.now() + HOUR).toISOString() });
  assert.equal(errOf(await vote(u.token, id2, 'o1')).status, 'FAILED_PRECONDITION');
  assert.equal((await get('Poll', id)).totalVotes, 0);
});

test('hesap silme beklemede -> oy reddedilir', async () => {
  const adm = await adminUser(), u = await phoneUser(); const id = await newPoll(adm);
  await db.collection('AccountDeletion').doc(u.uid).set({ uid: u.uid, status: 'pending', scheduledAt: new Date(Date.now() + DAY) });
  const r = await vote(u.token, id, 'o1');
  assert.equal(errOf(r).details.code, 'ACCOUNT_DELETION_PENDING');
});

test('hız sınırı: saatlik tavan aşılınca resource-exhausted', async () => {
  const adm = await adminUser(), u = await phoneUser(); const id = await newPoll(adm);
  let last;
  for (let i = 0; i < 22; i++) last = await vote(u.token, id, i % 2 ? 'o1' : 'o2');
  assert.equal(errOf(last).status, 'RESOURCE_EXHAUSTED');
});

test('aynı telefon yeni hesapla tekrar oy veremez: hesap silinip aynı numarayla açılınca oy DEĞİŞİR, toplam 1 kalır', async () => {
  const adm = await adminUser(); const id = await newPoll(adm);
  const a = await phoneUser(); await vote(a.token, id, 'o1');
  await createAccountDeletion({ db, auth: getAuth(), salt: TEST_SALT, log: silent }).purge(a.uid);
  // phoneVotes için sunucu tuzu emülatörde farklı olabilir: belge sayısı üzerinden doğrula
  const pv1 = await db.collection('Poll').doc(id).collection('phoneVotes').get();
  assert.equal(pv1.size, 1, 'telefon özeti oyu hesap silinince KALMALI');
  assert.equal((await db.collection('Poll').doc(id).collection('votes').doc(a.uid).get()).exists, false, 'uid kimlikli oy silinmeli');
  assert.deepEqual((await get('Poll', id)).counts, { o1: 1, o2: 0, o3: 0 }, 'sayaç KALMALI (toplam bozulmaz)');
  const b = await phoneUser(a.phone); assert.notEqual(b.uid, a.uid);
  const r = await vote(b.token, id, 'o2');
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const p = await get('Poll', id);
  assert.deepEqual(p.counts, { o1: 0, o2: 1, o3: 0 }); assert.equal(p.totalVotes, 1, 'aynı kişi ikinci oy sayılmamalı');
  assert.equal((await db.collection('Poll').doc(id).collection('phoneVotes').get()).size, 1);
});

test('hesap silme kapsamı: votes/{uid} ve PollLimits silinir; sayaç ve phoneVotes kalır; phoneVotes uid içermez', async () => {
  const adm = await adminUser(); const id = await newPoll(adm);
  const a = await phoneUser(), b = await phoneUser();
  await vote(a.token, id, 'o1'); await vote(b.token, id, 'o1');
  assert.ok(await get('PollLimits', a.uid));
  const pvDocs = (await db.collection('Poll').doc(id).collection('phoneVotes').get()).docs;
  for (const d of pvDocs) assert.ok(!JSON.stringify(d.data()).includes(a.uid) && !JSON.stringify(d.data()).includes(b.uid), 'phoneVotes uid sızdırmamalı');
  for (const d of pvDocs) assert.ok(/^ph_[0-9a-f]{64}$/.test(d.id), 'belge kimliği özet olmalı, düz telefon değil');
  await createAccountDeletion({ db, auth: getAuth(), salt: TEST_SALT, log: silent }).purge(a.uid);
  assert.equal(await get('PollLimits', a.uid), null);
  assert.equal((await db.collection('Poll').doc(id).collection('votes').doc(a.uid).get()).exists, false);
  assert.equal((await db.collection('Poll').doc(id).collection('votes').doc(b.uid).get()).exists, true, 'başkasının oyu etkilenmez');
  const p = await get('Poll', id); assert.deepEqual(p.counts, { o1: 2, o2: 0, o3: 0 }); assert.equal(p.totalVotes, 2);
  assert.equal((await db.collection('Poll').doc(id).collection('phoneVotes').get()).size, 2);
});

// ------------------------------------------------------------------ kurallar
let env;
const [h, pt] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
test('kurallar: Poll herkese okunur; istemci Poll/oy/sayaç yazamaz; votes yalnız sahibi okur; phoneVotes/PollLimits kapalı', async () => {
  env = await initializeTestEnvironment({ projectId: 'rules-test', firestore: { host: h, port: Number(pt), rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8') } });
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (c) => {
      const d = c.firestore();
      await setDoc(doc(d, 'User/admin1'), { role: 'admin' }); await setDoc(doc(d, 'User/alice'), { role: 'user' });
      await setDoc(doc(d, 'Poll/p1'), { question: 'x', counts: { o1: 0 }, totalVotes: 0, status: 'active' });
      await setDoc(doc(d, 'Poll/p1/votes/alice'), { optionId: 'o1' });
      await setDoc(doc(d, 'Poll/p1/votes/bob'), { optionId: 'o1' });
      await setDoc(doc(d, 'Poll/p1/phoneVotes/ph_x'), { optionId: 'o1' });
      await setDoc(doc(d, 'PollLimits/alice'), { hourCount: 1 });
    });
    const as = (u) => env.authenticatedContext(u).firestore(), anon = () => env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon(), 'Poll/p1')));
    await assertSucceeds(getDocs(collection(anon(), 'Poll')));
    for (const u of ['alice', 'admin1']) {
      await assertFails(updateDoc(doc(as(u), 'Poll/p1'), { 'counts.o1': 999 }));
      await assertFails(updateDoc(doc(as(u), 'Poll/p1'), { status: 'closed' }));
      await assertFails(setDoc(doc(as(u), 'Poll/p2'), { question: 'y' }));
      await assertFails(deleteDoc(doc(as(u), 'Poll/p1')));
    }
    await assertFails(setDoc(doc(as('alice'), 'Poll/p1/votes/alice'), { optionId: 'o2' }));
    await assertFails(setDoc(doc(as('alice'), 'Poll/p1/votes/bob'), { optionId: 'o2' }));
    await assertFails(deleteDoc(doc(as('alice'), 'Poll/p1/votes/alice')));
    await assertSucceeds(getDoc(doc(as('alice'), 'Poll/p1/votes/alice')));
    await assertFails(getDoc(doc(as('alice'), 'Poll/p1/votes/bob')));
    await assertFails(getDoc(doc(anon(), 'Poll/p1/votes/alice')));
    await assertFails(getDoc(doc(as('admin1'), 'Poll/p1/votes/alice')));
    await assertFails(getDoc(doc(as('alice'), 'Poll/p1/phoneVotes/ph_x')));
    await assertFails(setDoc(doc(as('alice'), 'Poll/p1/phoneVotes/ph_y'), { optionId: 'o1' }));
    await assertFails(getDoc(doc(as('alice'), 'PollLimits/alice')));
    await assertFails(setDoc(doc(as('alice'), 'PollLimits/alice'), { hourCount: 0 }));
  } finally { await env.cleanup(); }
});

'use strict';
// Ekibe soru sor (Q-2): ön onaylı Q&A. Gerçek index.js, Functions + Auth + Firestore emülatörü, HTTP. docs/SSS-BOTU.md
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getAuth } = require('firebase-admin/auth');
const { db, clearDb, PROJECT, Timestamp, signInPhone } = require('./helpers');
const { createAccountDeletion } = require('../src/accountDeletion');

const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
const DAY = 864e5;
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };

async function signUpEmail(prefix) {
  const email = `${prefix}-${Math.random().toString(36).slice(2, 8)}@example.com`;
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  if (!j.idToken) throw new Error('signUp başarısız: ' + JSON.stringify(j));
  return { token: j.idToken, uid: j.localId };
}
async function call(name, data, token) {
  const r = await fetch(url(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
const errOf = (r) => r.body.error || {};
let phSeq = 0;
const nextPhone = () => `+90555888${String(1000 + ++phSeq)}`;
async function phoneUser(first = 'Ayşe', last = 'Kaya') {
  const u = await signInPhone(nextPhone());
  await db.collection('User').doc(u.uid).set({ _id: u.uid, role: 'user', firstName: first, lastName: last });
  return u;
}
async function seedBase() {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' }); await db.collection('Team').doc('tB').set({ name: 'Ekip B' });
  await db.collection('Show').doc('s1').set({ name: 'Hamlet', teamId: 'tA' });
  await db.collection('Show').doc('sB').set({ name: 'Macbeth', teamId: 'tB' });
}
async function manager(teamId, first = 'Ekip') {
  const m = await phoneUser(first, 'Yönetici');
  await db.collection('TeamManager').doc(`${teamId}_${m.uid}`).set({ teamId, uid: m.uid, status: 'active', addedBy: 'x' });
  return m;
}
async function admin() { const a = await phoneUser('Yön', 'Etici'); await db.collection('User').doc(a.uid).update({ role: 'admin' }); return a; }
const ask = (token, o = {}) => call('askQuestion', { showId: 's1', text: 'Bu oyun çocuklara uygun mu, kaç dakika sürüyor?', ...o }, token);
const publish = (mgr, id, answer = 'Evet, 8 yaş üstü için uygundur.') => call('answerQuestion', { id, answer }, mgr.token);

before(async () => {
  for (let i = 0; i < 60; i++) {
    try { const r = await call('askQuestion', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); await seedBase(); });

test('girişsiz 401; telefonsuz hesap PHONE_REQUIRED; silme beklemede ACCOUNT_DELETION_PENDING; olmayan oyun 404', async () => {
  assert.equal((await call('askQuestion', { showId: 's1', text: 'merhaba nasılsınız' })).status, 401);
  const e = await signUpEmail('nophone');
  const r = await ask(e.token);
  assert.equal(errOf(r).status, 'FAILED_PRECONDITION'); assert.equal(errOf(r).details.code, 'PHONE_REQUIRED');
  assert.equal((await db.collection('Question').get()).size, 0);
  const u = await phoneUser();
  await db.collection('AccountDeletion').doc(u.uid).set({ uid: u.uid, status: 'pending', scheduledAt: Timestamp.fromMillis(Date.now() + DAY) });
  assert.equal(errOf(await ask(u.token)).details.code, 'ACCOUNT_DELETION_PENDING');
  const v = await phoneUser();
  assert.equal((await ask(v.token, { showId: 'yok' })).status, 404);
});

test('doğrulama + filtre: kısa/uzun, URL, telefon, e-posta, küfür reddedilir; temiz soru kabul edilir', async () => {
  const u = await phoneUser();
  for (const text of ['kısa', 'x'.repeat(301), 'www.site.com adresine bakın', 'beni 0555 123 45 67 numarasından ara', 'yaz bana a@b.com', 'siiiktir git bu ne oyun', 'ne zaman başlıyor @kisi']) {
    const r = await ask(u.token, { text });
    assert.equal(r.status, 400, text.slice(0, 20));
  }
  assert.equal((await ask(u.token, { text: 123 })).status, 400);
  assert.equal((await ask(u.token, { showId: 'a/b' })).status, 400);
  assert.equal((await db.collection('Question').get()).size, 0);
  assert.equal((await ask(u.token)).status, 200);
});

test('hız sınırı: saatte 3 soru, 4. çağrı RESOURCE_EXHAUSTED', async () => {
  const u = await phoneUser();
  for (let i = 0; i < 3; i++) assert.equal((await ask(u.token, { text: `Merhaba, soru numarası ${i} burada` })).status, 200, `#${i}`);
  const r = await ask(u.token);
  assert.equal(r.status, 429); assert.equal(errOf(r).status, 'RESOURCE_EXHAUSTED');
});

test('ön onay: soru bekleyen doğar (uid belgede YOK, ad türetilir); sahibi myQuestions ile görür; başkası göremez; yanıtla -> yayınlanır', async () => {
  const u = await phoneUser(); const other = await phoneUser();
  const r = await ask(u.token); assert.equal(r.status, 200);
  const id = r.body.result.id;
  const d = await get('Question', id);
  assert.equal(d.status, 'pending'); assert.equal(d.hidden, true); assert.equal(d.askerName, 'Ayşe K.'); assert.equal(d.showId, 's1');
  assert.ok(!JSON.stringify(d).includes(u.uid), 'Question belgesinde uid olmamalı');
  assert.equal((await get('QuestionOwner', id)).uid, u.uid);
  const mine = (await call('myQuestions', { showId: 's1' }, u.token)).body.result.items;
  assert.equal(mine.length, 1); assert.equal(mine[0].status, 'pending'); assert.ok(!JSON.stringify(mine).includes(u.uid));
  assert.equal((await call('myQuestions', {}, other.token)).body.result.items.length, 0);
  const mgr = await manager('tA');
  assert.equal((await publish(mgr, id)).status, 200);
  const a = await get('Question', id);
  assert.equal(a.status, 'answered'); assert.equal(a.hidden, false); assert.equal(a.answeredBy, 'Ekip A'); assert.ok(a.answeredAt);
  assert.equal((await call('myQuestions', {}, u.token)).body.result.items[0].answer, 'Evet, 8 yaş üstü için uygundur.');
  const logs = (await db.collection('ModerationLog').get()).docs.map((x) => x.data());
  assert.equal(logs.length, 1); assert.equal(logs[0].action, 'question_answer'); assert.equal(logs[0].byRole, 'teamManager');
});

test('ekip kapsamı: başka ekibin yöneticisi / sıradan kullanıcı yanıtlayamaz-reddedemez-gizleyemez-listeleyemez; admin yapabilir; cevap URL/küfür/boş reddedilir', async () => {
  const u = await phoneUser(); const id = (await ask(u.token)).body.result.id;
  const mgrB = await manager('tB'); const usr = await phoneUser(); const mgrA = await manager('tA'); const adm = await admin();
  for (const who of [mgrB, usr]) {
    assert.equal(errOf(await publish(who, id)).status, 'PERMISSION_DENIED');
    assert.equal(errOf(await call('rejectQuestion', { id, reason: 'uygunsuz' }, who.token)).status, 'PERMISSION_DENIED');
    assert.equal(errOf(await call('hideQuestion', { id, reason: 'uygunsuz' }, who.token)).status, 'PERMISSION_DENIED');
    assert.equal(errOf(await call('teamQuestions', { showId: 's1' }, who.token)).status, 'PERMISSION_DENIED');
  }
  assert.equal(errOf(await call('answerQuestion', { id: 'yok', answer: 'xx' }, usr.token)).status, 'PERMISSION_DENIED'); // varlık sızmaz
  assert.equal((await get('Question', id)).status, 'pending');
  for (const answer of ['', 'bakınız https://x.com', 'siiiktir', 'y'.repeat(601)]) assert.equal((await publish(mgrA, id, answer)).status, 400, answer.slice(0, 12));
  const l = (await call('teamQuestions', { showId: 's1' }, mgrA.token)).body.result.items;
  assert.equal(l.length, 1); assert.ok(!JSON.stringify(l).includes(u.uid));
  assert.equal((await call('answerQuestion', { id, answer: 'Tamamdır.' }, adm.token)).status, 200);
  assert.equal((await get('Question', id)).answeredBy, 'Ekip A');
  // yeniden yanıt (düzenleme) yayında kalır
  assert.equal((await publish(mgrA, id, 'Güncel cevap.')).status, 200);
  assert.equal((await get('Question', id)).answer, 'Güncel cevap.');
});

test('reddet/gizle/geri aç: sebep zorunlu, ModerationLog yazılır; reddedilen yanıtlanamaz', async () => {
  const u = await phoneUser(); const q1 = (await ask(u.token)).body.result.id; const q2 = (await ask(u.token, { text: 'Başka bir sorum daha var, bakar mısınız' })).body.result.id;
  const mgr = await manager('tA');
  assert.equal((await call('rejectQuestion', { id: q1 }, mgr.token)).status, 400);
  assert.equal((await call('rejectQuestion', { id: q1, reason: 'konu dışı' }, mgr.token)).status, 200);
  let d = await get('Question', q1); assert.equal(d.status, 'rejected'); assert.equal(d.hidden, true);
  assert.equal(errOf(await publish(mgr, q1)).status, 'FAILED_PRECONDITION');
  assert.equal((await get('Question', q1)).status, 'rejected');
  await publish(mgr, q2);
  assert.equal((await call('hideQuestion', { id: q2, reason: 'yanlış bilgi' }, mgr.token)).status, 200);
  d = await get('Question', q2); assert.equal(d.status, 'hidden'); assert.equal(d.hidden, true);
  assert.equal((await call('hideQuestion', { id: q2, reason: 'yanlış alarm', restore: true }, mgr.token)).status, 200);
  d = await get('Question', q2); assert.equal(d.status, 'answered'); assert.equal(d.hidden, false);
  const acts = (await db.collection('ModerationLog').orderBy('at').get()).docs.map((x) => x.data().action);
  assert.deepEqual(acts, ['question_reject', 'question_answer', 'question_hide', 'question_restore']);
});

test('şikâyet (type question): 3 FARKLI telefonlu -> otomatik gizleme; 2 yetmez; kendi/tekrar/telefonsuz sayılmaz; yalnız yayındaki soru; geçersiz neden', async () => {
  const u = await phoneUser(); const id = (await ask(u.token)).body.result.id;
  const rep = (token, o = {}) => call('reportContent', { type: 'question', id, reason: 'spam', ...o }, token);
  const r1 = await phoneUser(), r2 = await phoneUser(), r3 = await phoneUser();
  assert.equal((await rep(r1.token)).status, 404, 'bekleyen soru şikâyet edilemez (görünmez)');
  await publish(await manager('tA'), id);
  assert.equal((await rep(u.token)).status, 400); // kendi sorusu
  assert.equal((await rep(r1.token, { reason: 'hack' })).status, 400);
  assert.equal((await rep(r1.token)).body.result.hidden, false);
  assert.equal((await rep(r1.token)).body.result.already, true);
  const np = await signUpEmail('np-q'); await rep(np.token);
  assert.equal((await rep(r2.token)).body.result.hidden, false);
  assert.equal((await get('Question', id)).reportCount, 2);
  assert.equal((await rep(r3.token)).body.result.hidden, true);
  const d = await get('Question', id); assert.equal(d.status, 'hidden'); assert.equal(d.hidden, true); assert.equal(d.hiddenReason, 'reports');
  assert.equal((await get('QuestionReport', `${id}_${r1.uid}`)).counted, true);
  assert.equal((await get('QuestionReport', `${id}_${np.uid}`)).counted, false);
  assert.equal((await call('reportContent', { type: 'question', id: 'yok', reason: 'spam' }, r1.token)).status, 404);
});

test('engelle: blockUser({questionId}) sunucuda uid çözer, blocks belgesine askerKey yazar; uid istemciye dönmez; kendini engelleyemez', async () => {
  const u = await phoneUser(); const id = (await ask(u.token)).body.result.id; const v = await phoneUser();
  await publish(await manager('tA'), id);
  const r = await call('blockUser', { questionId: id }, v.token);
  assert.equal(r.status, 200); assert.ok(!JSON.stringify(r.body).includes(u.uid));
  const b = await db.collection('User').doc(v.uid).collection('blocks').doc(u.uid).get();
  assert.ok(b.exists); assert.equal(b.data().askerKey, (await get('Question', id)).askerKey);
  assert.equal((await call('blockUser', { questionId: id }, u.token)).status, 400);
  assert.equal((await call('blockUser', { questionId: 'yok' }, v.token)).status, 404);
});

test('hesap silme: sahiplik/şikâyet/sayaç silinir; normal soru silinir; şikâyetli yayın anonimleşir; başkasının sorusuna dokunulmaz; uid hiçbir yerde kalmaz', async () => {
  const u = await phoneUser(); const w = await phoneUser();
  const q1 = (await ask(u.token)).body.result.id; const q2 = (await ask(u.token, { text: 'İkinci sorum burada, yanıt bekliyorum' })).body.result.id;
  const qw = (await ask(w.token, { text: 'Başka birinin sorusu, dokunulmamalı' })).body.result.id;
  const mgr = await manager('tA'); await publish(mgr, q2); await publish(mgr, qw);
  await db.collection('Question').doc(q2).update({ reportCount: 2 });
  await db.collection('QuestionReport').doc(`${qw}_${u.uid}`).set({ questionId: qw, userId: u.uid, reason: 'spam' });
  const svc = createAccountDeletion({ db, auth: getAuth(), salt: 'tiyatrol-phone-v1:ticketappflutter', now: () => Date.now(), log: { error() {}, info() {}, warn() {} }, deleteProfileImage: async () => {} });
  await svc.purge(u.uid);
  assert.equal(await get('Question', q1), null);
  const ev = await get('Question', q2);
  assert.ok(ev && ev.hidden === true && ev.askerName === '' && ev.askerKey === '' && ev.text.length <= 120);
  assert.equal(await get('QuestionOwner', q1), null); assert.equal(await get('QuestionOwner', q2), null);
  assert.equal(await get('QuestionLimits', u.uid), null);
  assert.equal((await db.collection('QuestionReport').where('userId', '==', u.uid).get()).size, 0);
  assert.equal((await get('Question', qw)).status, 'answered'); assert.ok(await get('QuestionOwner', qw));
  assert.equal((await db.collection('ModerationLog').where('questionId', '==', q1).get()).docs.every((x) => x.data().textSnapshot === ''), true);
  for (const c of ['Question', 'QuestionOwner', 'QuestionReport', 'QuestionLimits', 'ModerationLog']) {
    const s = await db.collection(c).get();
    s.docs.forEach((x) => assert.ok(!(x.id + JSON.stringify(x.data())).includes(u.uid), `${c}/${x.id} uid içeriyor`));
  }
});

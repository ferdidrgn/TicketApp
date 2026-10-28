'use strict';
// Doğrulanmış yorum + moderasyon (Q-1/M-1). Gerçek index.js, Functions + Auth + Firestore emülatörü, HTTP.
const { test, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getAuth } = require('firebase-admin/auth');
const { db, clearDb, eventDate, PROJECT, Timestamp, signInPhone, uidN } = require('./helpers');
const { createAccountDeletion, anonId } = require('../src/accountDeletion');
const { checkText } = require('../src/moderation-words');
const { publicName } = require('../src/reviews');

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
const nextPhone = () => `+90555777${String(1000 + ++phSeq)}`;
/** Telefonlu kullanıcı + User belgesi. */
async function phoneUser(first = 'Ayşe', last = 'Kaya') {
  const u = await signInPhone(nextPhone());
  await db.collection('User').doc(u.uid).set({ _id: u.uid, role: 'user', firstName: first, lastName: last });
  return u;
}
let tseq = 0;
/** Oyun s1 için (varsayılan) etkinlik + kullanıcıya bilet. delta<0 geçmiş. */
async function ticketFor(uid, { delta = -2 * DAY, status = 'paid', showId = 's1', usedAt, ev } = {}) {
  const eventId = ev || `ev${++tseq}_${Date.now()}`;
  await db.collection('Event').doc(eventId).set({ _id: eventId, showId, stageId: 'st1', date: eventDate(delta), price: '100', seats: {} });
  const id = `tk${++tseq}_${Date.now()}`;
  await db.collection('Ticket').doc(id).set({ _id: id, customerId: uid, eventId, showId, paymentStatus: status, buySeats: ['A1'], ...(usedAt ? { usedAt } : {}) });
  return { id, eventId };
}
async function seedBase() {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' }); await db.collection('Team').doc('tB').set({ name: 'Ekip B' });
  await db.collection('Show').doc('s1').set({ name: 'Hamlet', teamId: 'tA' });
  await db.collection('Show').doc('sB').set({ name: 'Macbeth', teamId: 'tB' });
}
const submit = (token, o = {}) => call('submitReview', { showId: 's1', rating: 5, text: 'Harika bir oyundu', ...o }, token);

before(async () => {
  for (let i = 0; i < 60; i++) {
    try { const r = await call('canReview', {}); if (r.status) return; } catch { /* henüz yok */ }
    await new Promise((res) => setTimeout(res, 1000));
  }
  throw new Error('functions emülatörü yanıt vermiyor');
});
beforeEach(async () => { await clearDb(); await seedBase(); });

test('birim: publicName "Ad S." üretir; kelime filtresi varyantları yakalar, masum metni geçirir', () => {
  assert.equal(publicName({ firstName: 'ayşe', lastName: 'ıpek' }), 'ayşe I.');
  assert.equal(publicName({ firstName: 'Ali', lastName: '' }), 'Ali');
  assert.equal(publicName({ firstName: '', lastName: 'X' }), 'Seyirci');
  assert.equal(publicName({ firstName: 'Ali<script>', lastName: 'Veli' }), 'Aliscript V.');
  for (const t of ['siiiktir', 's.i.k.t.i.r', 'OROSPU', 'am1na koyim', 'gavur']) assert.ok(checkText(t).flagged, t);
  for (const t of ['Harika oyun, sık sık gitmek isterim', 'Götürdü beni', 'Salak komedi değil çok iyiydi']) assert.ok(!checkText(t).flagged, t);
});

test('girişsiz 401; telefonsuz hesap PHONE_REQUIRED', async () => {
  assert.equal((await call('submitReview', { showId: 's1', rating: 5 })).status, 401);
  const e = await signUpEmail('nophone');
  await ticketFor(e.uid);
  const r = await submit(e.token);
  assert.equal(errOf(r).status, 'FAILED_PRECONDITION'); assert.equal(errOf(r).details.code, 'PHONE_REQUIRED');
  assert.equal(await get('Review', `${e.uid}_s1`), null);
});

test('doğrulanmamış katılımcı reddi: biletsiz / yalnız gelecek seans / iptal / gelmedi / başka oyunun bileti -> NOT_VERIFIED_ATTENDEE', async () => {
  const u = await phoneUser();
  let r = await submit(u.token);
  assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE'); // bilet yok
  await ticketFor(u.uid, { delta: 3 * DAY }); // gelecek seans
  r = await submit(u.token); assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE');
  await ticketFor(u.uid, { status: 'cancelled' });
  await ticketFor(u.uid, { status: 'no_show' });
  r = await submit(u.token); assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE');
  await ticketFor(u.uid, { showId: 'sB' }); // başka oyun
  r = await submit(u.token); assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE');
  // başkasının bileti sayılmaz
  const o = await phoneUser(); await ticketFor(o.uid);
  r = await submit(u.token); assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE');
  assert.equal(await get('Review', `${u.uid}_s1`), null);
  // canReview aynı sonucu açıklar
  const cr = await call('canReview', { showId: 's1' }, u.token);
  assert.equal(cr.body.result.canReview, false); assert.equal(cr.body.result.code, 'NOT_VERIFIED_ATTENDEE');
});

test('Event.showId TEK doğruluk kaynağı: biletteki showId yanlış/başka olsa da etkinliğin oyunu esas; showId boşsa Show.eventsId yedeği', async () => {
  const u = await phoneUser();
  const t = await ticketFor(u.uid, { showId: 'sB' }); // bilet alanı sB; etkinlik sB
  await db.collection('Ticket').doc(t.id).update({ showId: 's1' }); // bilet yalan söylüyor
  let r = await submit(u.token); assert.equal(errOf(r).details.code, 'NOT_VERIFIED_ATTENDEE');
  // etkinlik showId'siz + Show.eventsId yedeği
  await db.collection('Event').doc(t.eventId).update({ showId: '' });
  await db.collection('Show').doc('s1').update({ eventsId: [t.eventId] });
  r = await submit(u.token); assert.equal(r.status, 200);
});

test('doğrulanmış kabul: userName sunucuda türetilir (istemci adı/fotoğrafı/verified yok sayılır), kimlik uid_showId, Show.ratingAvg/Count güncellenir', async () => {
  const u = await phoneUser('Ayşe', 'Kaya');
  await ticketFor(u.uid, { usedAt: Timestamp.now() });
  const r = await call('submitReview', { showId: 's1', rating: 4, text: '  Çok beğendim  ', userName: 'Sahte Admin', userImage: 'https://evil/x.png', verified: false, hidden: true, userId: 'baska' }, u.token);
  assert.equal(r.status, 200); assert.equal(r.body.result.status, 'published');
  const d = await get('Review', `${u.uid}_s1`);
  assert.equal(d.userName, 'Ayşe K.'); assert.equal(d.userImage, ''); assert.equal(d.userId, u.uid);
  assert.equal(d.verified, true); assert.equal(d.attended, true); assert.equal(d.hidden, false); assert.equal(d.status, 'published');
  assert.equal(d.text, 'Çok beğendim'); assert.equal(d.rating, 4);
  assert.ok(d.createdAt && d.createdAt.toMillis); assert.ok(Math.abs(d.createdAt.toMillis() - Date.now()) < 60000, 'sunucu zamanı');
  const s = await get('Show', 's1');
  assert.equal(s.ratingCount, 1); assert.equal(s.ratingAvg, 4);
  assert.equal((await call('canReview', { showId: 's1' }, u.token)).body.result.canReview, true);
});

test('tek yorum: ikinci çağrı AYNI belgeyi günceller (createdAt korunur), ortalama yeniden hesaplanır; sahibi silince önbellek düşer', async () => {
  const u = await phoneUser(); const u2 = await phoneUser('Mehmet', 'Demir');
  await ticketFor(u.uid); await ticketFor(u2.uid);
  await submit(u.token, { rating: 5 });
  const c1 = (await get('Review', `${u.uid}_s1`)).createdAt.toMillis();
  await new Promise((res) => setTimeout(res, 30));
  assert.equal((await submit(u.token, { rating: 2, text: 'fikrim değişti' })).body.result.updated, true);
  const snap = await db.collection('Review').where('userId', '==', u.uid).get();
  assert.equal(snap.size, 1);
  assert.equal(snap.docs[0].data().createdAt.toMillis(), c1); assert.equal(snap.docs[0].data().rating, 2);
  await submit(u2.token, { rating: 4 });
  let s = await get('Show', 's1'); assert.equal(s.ratingCount, 2); assert.equal(s.ratingAvg, 3);
  assert.equal((await call('deleteMyReview', { showId: 's1' }, u.token)).status, 200);
  s = await get('Show', 's1'); assert.equal(s.ratingCount, 1); assert.equal(s.ratingAvg, 4);
});

test('metin filtresi: URL/telefon/e-posta/uzunluk/puan reddedilir; küfür reddedilmez, status:pending ile kuyruğa düşer (yayında sayılmaz)', async () => {
  const u = await phoneUser(); await ticketFor(u.uid);
  for (const text of ['bak http://spam.example/x', 'www.spam.com iyi', 'bana ulaş 0532 123 45 67', 'mail a@b.co yaz', 'yaz @kullanici', 'x'.repeat(601), 'wa.me/90555']) {
    const r = await submit(u.token, { text }); assert.equal(r.status, 400, text); assert.equal(errOf(r).status, 'INVALID_ARGUMENT', text);
  }
  for (const rating of [0, 6, 4.5, '5', null]) assert.equal((await submit(u.token, { rating })).status, 400, String(rating));
  assert.equal((await call('submitReview', { showId: 'yok', rating: 5, text: 'x' }, u.token)).status, 404);
  assert.equal(await get('Review', `${u.uid}_s1`), null);
  const r = await submit(u.token, { text: 'siiiktir git bu ne oyun' });
  assert.equal(r.status, 200); assert.equal(r.body.result.pending, true);
  const d = await get('Review', `${u.uid}_s1`);
  assert.equal(d.status, 'pending'); assert.equal(d.hidden, true); assert.equal(d.queue, true); assert.equal(d.hiddenReason, 'pending');
  assert.equal((await get('Show', 's1')).ratingCount, 0, 'bekleyen yorum puana girmez');
  // temiz metinle düzeltince yayına çıkar
  const r2 = await submit(u.token, { text: 'özür dilerim, güzel oyundu' });
  assert.equal(r2.body.result.status, 'published'); assert.equal((await get('Show', 's1')).ratingCount, 1);
});

test('hız sınırı: saatte 5 yazma, 6. çağrı RESOURCE_EXHAUSTED', async () => {
  const u = await phoneUser(); await ticketFor(u.uid);
  for (let i = 0; i < 5; i++) assert.equal((await submit(u.token, { rating: 1 + (i % 5) })).status, 200, `#${i}`);
  const r = await submit(u.token);
  assert.equal(r.status, 429); assert.equal(errOf(r).status, 'RESOURCE_EXHAUSTED');
});

test('hesap silme beklemede: ACCOUNT_DELETION_PENDING', async () => {
  const u = await phoneUser(); await ticketFor(u.uid);
  await db.collection('AccountDeletion').doc(u.uid).set({ uid: u.uid, status: 'pending', scheduledAt: Timestamp.fromMillis(Date.now() + DAY) });
  const r = await submit(u.token); assert.equal(errOf(r).details.code, 'ACCOUNT_DELETION_PENDING');
});

test('şikâyet: 3 FARKLI telefonlu kullanıcı -> otomatik gizleme (+puan düşer); 2 yetmez; tekrar/kendi/telefonsuz sayılmaz; doğrulanmamış tür/neden reddedilir', async () => {
  const author = await phoneUser(); await ticketFor(author.uid);
  const other = await phoneUser(); await ticketFor(other.uid);
  await submit(author.token, { rating: 1, text: 'kötü' }); await submit(other.token, { rating: 5, text: 'iyi' });
  assert.equal((await get('Show', 's1')).ratingCount, 2);
  const rid = `${author.uid}_s1`;
  const rep = (token, o = {}) => call('reportContent', { type: 'review', id: rid, reason: 'hakaret', ...o }, token);
  const r1 = await phoneUser(), r2 = await phoneUser(), r3 = await phoneUser();
  assert.equal((await rep(author.token)).status, 400); // kendi yorumu
  assert.equal((await rep(r1.token, { reason: 'hack' })).status, 400);
  assert.equal((await rep(r1.token, { type: 'question' })).status, 400);
  assert.equal((await rep(r1.token, { detail: 'x'.repeat(201) })).status, 400);
  assert.equal((await call('reportContent', { type: 'review', id: 'yok_yok', reason: 'spam' }, r1.token)).status, 404);
  assert.equal((await rep(r1.token)).body.result.hidden, false);
  assert.equal((await rep(r1.token)).body.result.already, true); // aynı kişi tekrar sayılmaz
  const np = await signUpEmail('np-report');
  await rep(np.token); // telefonsuz: kayıt var ama eşiğe sayılmaz
  assert.equal((await rep(r2.token)).body.result.hidden, false);
  let d = await get('Review', rid); assert.equal(d.reportCount, 2); assert.equal(d.hidden, false); assert.equal(d.queue, true);
  assert.equal((await rep(r3.token)).body.result.hidden, true);
  d = await get('Review', rid); assert.equal(d.hidden, true); assert.equal(d.hiddenReason, 'reports'); assert.equal(d.status, 'hidden'); assert.equal(d.reportCount, 3);
  const s = await get('Show', 's1'); assert.equal(s.ratingCount, 1); assert.equal(s.ratingAvg, 5);
  const rr = await get('ReviewReport', `${rid}_${r1.uid}`); assert.equal(rr.reason, 'hakaret'); assert.equal(rr.counted, true);
  assert.equal((await get('ReviewReport', `${rid}_${np.uid}`)).counted, false);
  // yazar kilitli yorumu düzenleyemez/silemez
  assert.equal(errOf(await submit(author.token)).details.code, 'REVIEW_LOCKED');
  assert.equal(errOf(await call('deleteMyReview', { showId: 's1' }, author.token)).details.code, 'REVIEW_LOCKED');
});

test('engelleme: blockUser/unblockUser User/{me}/blocks/{uid} yazar; kendini engelleyemez; geçersiz kimlik reddedilir', async () => {
  const a = await phoneUser(), b = await phoneUser();
  assert.equal((await call('blockUser', { uid: b.uid }, a.token)).status, 200);
  assert.ok(await get('User', a.uid) && (await db.collection('User').doc(a.uid).collection('blocks').doc(b.uid).get()).exists);
  assert.equal((await call('blockUser', { uid: a.uid }, a.token)).status, 400);
  assert.equal((await call('blockUser', { uid: 'a/b' }, a.token)).status, 400);
  assert.equal((await call('unblockUser', { uid: b.uid }, a.token)).status, 200);
  assert.equal((await db.collection('User').doc(a.uid).collection('blocks').doc(b.uid).get()).exists, false);
  assert.equal((await call('blockUser', { uid: b.uid })).status, 401);
});

async function admin() {
  const a = await phoneUser('Yön', 'Etici'); await db.collection('User').doc(a.uid).update({ role: 'admin' }); return a;
}

test('admin moderasyonu: sebep zorunlu; hide/restore/delete ModerationLog yazar; restore sonrası yeni eşik gerekir; yalnız admin', async () => {
  const author = await phoneUser(); await ticketFor(author.uid);
  await submit(author.token, { rating: 3 });
  const rid = `${author.uid}_s1`;
  const adm = await admin(); const usr = await phoneUser();
  assert.equal(errOf(await call('adminModerate', { reviewId: rid, action: 'hide', reason: 'x' }, usr.token)).status, 'PERMISSION_DENIED');
  assert.equal(errOf(await call('adminModerate', { reviewId: rid, action: 'hide' }, adm.token)).status, 'INVALID_ARGUMENT'); // sebep yok
  assert.equal((await call('adminModerate', { reviewId: rid, action: 'zehirle', reason: 'xxx' }, adm.token)).status, 400);
  assert.equal((await call('adminModerate', { reviewId: rid, action: 'hide', reason: 'Hakaret içeriyor' }, adm.token)).status, 200);
  let d = await get('Review', rid); assert.equal(d.hidden, true); assert.equal(d.hiddenReason, 'moderator');
  assert.equal((await get('Show', 's1')).ratingCount, 0);
  assert.equal((await call('adminModerate', { reviewId: rid, action: 'restore', reason: 'yanlış alarm' }, adm.token)).status, 200);
  d = await get('Review', rid); assert.equal(d.hidden, false); assert.equal(d.hiddenReason, null); assert.equal((await get('Show', 's1')).ratingCount, 1);
  // geri açıldıktan sonra tek şikâyet tekrar gizlemez; baseline'dan itibaren 3 gerekir
  const rs = [await phoneUser(), await phoneUser(), await phoneUser()];
  d = await get('Review', rid); await db.collection('Review').doc(rid).update({ reportCount: 3, reportBaseline: 3 });
  await call('reportContent', { type: 'review', id: rid, reason: 'spam' }, rs[0].token);
  assert.equal((await get('Review', rid)).hidden, false);
  await call('reportContent', { type: 'review', id: rid, reason: 'spam' }, rs[1].token);
  await call('reportContent', { type: 'review', id: rid, reason: 'spam' }, rs[2].token);
  assert.equal((await get('Review', rid)).hidden, true);
  assert.equal((await call('adminModerate', { reviewId: rid, action: 'delete', reason: 'kalıcı kaldırma' }, adm.token)).status, 200);
  assert.equal(await get('Review', rid), null);
  assert.equal((await db.collection('ReviewReport').where('reviewId', '==', rid).get()).size, 0);
  const logs = (await db.collection('ModerationLog').orderBy('at').get()).docs.map((x) => x.data());
  assert.deepEqual(logs.map((l) => l.action), ['hide', 'restore', 'delete']);
  assert.ok(logs.every((l) => l.by === adm.uid && l.byRole === 'admin' && l.reviewId === rid && l.reason && l.at && l.targetUid === author.uid));
  assert.equal(logs[2].rating, 3); assert.ok(typeof logs[2].textSnapshot === 'string');
});

test('ekip yöneticisi kapsamı: kendi ekibinin oyunundaki yorumu gizler/geri açar; başka ekibin yorumu, silme ve başka oyunun listesi reddedilir; admin değildir', async () => {
  const mgr = await phoneUser('Ekip', 'Yön');
  await db.collection('TeamManager').doc(`tA_${mgr.uid}`).set({ teamId: 'tA', uid: mgr.uid, status: 'active', addedBy: 'x' });
  const a1 = await phoneUser(); await ticketFor(a1.uid);
  const b1 = await phoneUser(); await ticketFor(b1.uid, { showId: 'sB' });
  await submit(a1.token); await call('submitReview', { showId: 'sB', rating: 4, text: 'iyi' }, b1.token);
  const ra = `${a1.uid}_s1`, rb = `${b1.uid}_sB`;
  assert.equal((await call('teamModerate', { reviewId: ra, action: 'hide', reason: 'uygunsuz dil' }, mgr.token)).status, 200);
  assert.equal((await get('Review', ra)).hidden, true);
  assert.equal(errOf(await call('teamModerate', { reviewId: rb, action: 'hide', reason: 'başka ekip' }, mgr.token)).status, 'PERMISSION_DENIED');
  assert.equal((await get('Review', rb)).hidden, false);
  assert.equal(errOf(await call('teamModerate', { reviewId: ra, action: 'delete', reason: 'silmek istiyorum' }, mgr.token)).status, 'PERMISSION_DENIED');
  assert.ok(await get('Review', ra));
  assert.equal(errOf(await call('adminModerate', { reviewId: ra, action: 'restore', reason: 'deneme' }, mgr.token)).status, 'PERMISSION_DENIED');
  const lst = await call('teamReviews', { showId: 's1' }, mgr.token);
  assert.equal(lst.status, 200); assert.equal(lst.body.result.items.length, 1); assert.equal(lst.body.result.items[0].hidden, true);
  assert.ok(!('userId' in lst.body.result.items[0]), 'yazar userId alanı dönmez');
  assert.equal(errOf(await call('teamReviews', { showId: 'sB' }, mgr.token)).status, 'PERMISSION_DENIED');
  assert.equal((await call('teamModerate', { reviewId: ra, action: 'restore', reason: 'tekrar yayın' }, mgr.token)).status, 200);
  // yetkisi geri alınan yönetici
  await db.collection('TeamManager').doc(`tA_${mgr.uid}`).update({ status: 'revoked' });
  assert.equal(errOf(await call('teamModerate', { reviewId: ra, action: 'hide', reason: 'artık yetki yok' }, mgr.token)).status, 'PERMISSION_DENIED');
  // sıradan kullanıcı
  assert.equal(errOf(await call('teamModerate', { reviewId: ra, action: 'hide', reason: 'ben kimim' }, a1.token)).status, 'PERMISSION_DENIED');
  const logs = (await db.collection('ModerationLog').get()).docs.map((x) => x.data());
  assert.ok(logs.length === 2 && logs.every((l) => l.byRole === 'teamManager'));
});

test('hesap silme kapsamı: yorum silinir (puan düşer), delil (gizli+şikâyetli) yorum uid\'siz anonimleşir; blocks/ReviewLimits/ModerationLog uid taşımaz', async () => {
  const auth = getAuth();
  const uid = uidN();
  await auth.createUser({ uid, email: `${uid}@example.com`.toLowerCase() });
  await db.collection('User').doc(uid).set({ _id: uid, role: 'user', firstName: 'Ayşe', lastName: 'Kaya' });
  await db.collection('Show').doc('s2').set({ name: 'Başka', ratingAvg: 5, ratingCount: 1 });
  await db.collection('Show').doc('s1').update({ ratingAvg: 4, ratingCount: 1 });
  await db.collection('Review').doc(`${uid}_s1`).set({ showId: 's1', userId: uid, userName: 'Ayşe K.', rating: 4, text: 'güzel', hidden: false, status: 'published', reportCount: 0 });
  await db.collection('Review').doc(`${uid}_s2`).set({ showId: 's2', userId: uid, userName: 'Ayşe K.', rating: 1, text: 'kötü kötü', hidden: true, status: 'hidden', hiddenReason: 'reports', reportCount: 3 });
  await db.collection('ReviewReport').doc(`${uid}_s2_rep1`).set({ reviewId: `${uid}_s2`, userId: 'rep1', counted: true });
  await db.collection('ReviewReport').doc('baskasi_s9_' + uid).set({ reviewId: 'baskasi_s9', userId: uid, counted: true });
  await db.collection('User').doc(uid).collection('blocks').doc('x1').set({ blockedAt: Timestamp.now() });
  await db.collection('ReviewLimits').doc(uid).set({ subHourCount: 1 });
  await db.collection('ModerationLog').doc('m1').set({ by: 'adminX', targetUid: uid, reviewId: `${uid}_s2`, action: 'hide', reason: 'r', textSnapshot: 'kötü kötü' });
  await db.collection('ModerationLog').doc('m2').set({ by: uid, targetUid: 'baska', reviewId: 'baska_s1', action: 'restore', reason: 'r', textSnapshot: 'ok' });
  const svc = createAccountDeletion({ db, auth, salt: 'tiyatrol-phone-v1:ticketappflutter', now: () => Date.now(), log: { error() {}, info() {}, warn() {} }, deleteProfileImage: async () => {} });
  await svc.purge(uid);
  assert.equal(await get('Review', `${uid}_s1`), null);
  assert.equal(await get('Review', `${uid}_s2`), null);
  const ev = await get('Review', `${anonId(uid)}_s2`);
  assert.ok(ev && ev.hidden === true && ev.userId === anonId(uid) && ev.userName === '' && ev.text.length <= 120);
  assert.equal((await get('Show', 's1')).ratingCount, 0);
  assert.equal((await db.collection('User').doc(uid).collection('blocks').get()).size, 0);
  assert.equal(await get('ReviewLimits', uid), null);
  assert.equal((await db.collection('ReviewReport').where('userId', '==', uid).get()).size, 0);
  assert.equal((await db.collection('ReviewReport').where('reviewId', '==', `${uid}_s2`).get()).size, 0);
  // hiçbir koleksiyonda uid kalmaz
  const hits = [];
  for (const col of await db.listCollections()) {
    for (const d of (await col.get()).docs) {
      if (col.id === 'AccountDeletion') continue;
      if (`${d.id} ${JSON.stringify(d.data())}`.includes(uid)) hits.push(`${col.id}/${d.id}`);
    }
  }
  assert.deepEqual(hits, []);
  const m1 = await get('ModerationLog', 'm1'), m2 = await get('ModerationLog', 'm2');
  assert.equal(m1.targetUid, anonId(uid)); assert.equal(m1.textSnapshot, ''); assert.equal(m1.reviewId, `${anonId(uid)}_s2`); assert.equal(m2.by, anonId(uid));
});

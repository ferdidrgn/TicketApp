'use strict';
// 30 gün bekleme süreli hesap silme (docs/HESAP-SILME.md). Firestore + Auth emülatörü gerekir.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getAuth } = require('firebase-admin/auth');
const H = require('./helpers');
const cfg = require('../src/config');
const { createAccountDeletion, anonId } = require('../src/accountDeletion');
const { db, makeService, seedEvent, eventDate, uidN, clearDb, makeAdmin, expectCode, phoneFor, keyFor, Timestamp, PROJECT, TEST_SALT } = H;

const auth = getAuth();
const DAY = 864e5;
const silent = { error() {}, info() {}, warn() {} };
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };

beforeEach(async () => { await clearDb(); });

/** Hesap silme servisi; `clk` enjekte saat, `authImpl` hata enjekte etmek için. */
function sut({ clk, svc, authImpl, images } = {}) {
  const raw = svc || makeService().raw;
  return createAccountDeletion({
    db, auth: authImpl || auth, orderService: raw, salt: TEST_SALT, now: clk || Date.now, log: silent,
    deleteProfileImage: async (uid) => { if (images) images.push(uid); },
  });
}

/** Gerçek (e-posta) Auth kullanıcısı + User belgesi. */
async function mkUser(extra = {}) {
  const uid = uidN();
  await auth.createUser({ uid, email: `${uid}@example.com`.toLowerCase() });
  await db.collection('User').doc(uid).set({ _id: uid, role: 'user', firstName: 'Ayşe', lastName: 'Yılmaz', eMail: `${uid}@example.com`, phoneNumber: phoneFor(uid), phoneKey: keyFor(phoneFor(uid)), fcmToken: 'tok', ...extra });
  return uid;
}

let tseq = 0;
/** Doğrudan bilet yazar (etkinlik tarihi deltaMs sonra). */
async function putTicket(uid, { delta = 7 * DAY, status = 'paid', usedAt, title = 'Test Oyunu', method = 'card' } = {}) {
  const ev = await seedEvent({ date: eventDate(delta) });
  const id = `tk${++tseq}_${Date.now()}`;
  await db.collection('Ticket').doc(id).set({
    _id: id, customerId: uid, eventId: ev, showId: 'show1', stageId: 'stage1', orderId: id, orderMethod: method, orderPrice: '100.00',
    buySeats: ['A1'], paymentStatus: status, showName: title, eventDate: eventDate(delta), ...(usedAt ? { usedAt } : {}),
  });
  await db.collection('Order').doc(id).set({ userId: uid, phoneKey: keyFor(phoneFor(uid)), eventId: ev, status: 'paid', total: 100, totalKurus: 10000, paymentId: 'pay_1' });
  return { id, ev };
}

const authGone = async (uid) => { try { await auth.getUser(uid); return false; } catch (e) { return e.code === 'auth/user-not-found'; } };

// ------------------------------------------------------------------ reddetme / kabul
test('gelecek tarihli aktif bilet varsa istek REDDEDİLİR: UPCOMING_TICKETS + sayı + en yakın tarih/başlık; hiçbir veri değişmez', async () => {
  const uid = await mkUser();
  const near = await putTicket(uid, { delta: 3 * DAY, title: 'Yakın Oyun' });
  await putTicket(uid, { delta: 20 * DAY, status: 'pay_at_venue', method: 'venue' });
  const e = await expectCode(sut().requestAccountDeletion(uid), 'failed-precondition');
  assert.equal(e.message, 'UPCOMING_TICKETS');
  assert.equal(e.details.code, 'UPCOMING_TICKETS');
  assert.equal(e.details.count, 2);
  assert.equal(e.details.nextEventTitle, 'Yakın Oyun');
  const ms = Date.parse(e.details.nextEventDate);
  assert.ok(Math.abs(ms - (Date.now() + 3 * DAY)) < 2 * 60000, 'en yakın etkinlik tarihi (ISO)');
  assert.equal(await get('AccountDeletion', uid), null);
  const u = await get('User', uid);
  assert.equal(u.deletionStatus, undefined); assert.equal(u.deletionScheduledAt, undefined);
  assert.ok(!(await authGone(uid)));
  assert.ok(near.id);
});

test('geçmiş / iptal / gelmedi / kullanılmış biletler engellemez; pending alanları yazılır (scheduledAt = +30 gün, düz telefon yok)', async () => {
  const uid = await mkUser();
  await putTicket(uid, { delta: -3 * DAY });
  await putTicket(uid, { delta: 10 * DAY, status: 'cancelled' });
  await putTicket(uid, { delta: 10 * DAY, status: 'no_show' });
  await putTicket(uid, { delta: 10 * DAY, usedAt: Timestamp.now() });
  const t0 = Date.now();
  const r = await sut({ clk: () => t0 }).requestAccountDeletion(uid, { phone: phoneFor(uid) });
  assert.equal(r.status, 'pending'); assert.equal(r.already, false);
  assert.equal(Date.parse(r.scheduledAt), t0 + 30 * DAY);
  const rec = await get('AccountDeletion', uid);
  assert.equal(rec.status, 'pending'); assert.equal(rec.uid, uid);
  assert.equal(rec.scheduledAt.toMillis(), t0 + 30 * DAY); assert.equal(rec.requestedAt.toMillis(), t0);
  assert.equal(rec.phoneKey, keyFor(phoneFor(uid)));
  const u = await get('User', uid);
  assert.equal(u.deletionStatus, 'pending'); assert.equal(u.deletionScheduledAt.toMillis(), t0 + 30 * DAY); assert.equal(u.firstName, 'Ayşe');
  assert.ok(!JSON.stringify(rec).includes(phoneFor(uid)), 'AccountDeletion düz telefon içermemeli');
  assert.ok(!JSON.stringify(rec).includes('example.com'), 'AccountDeletion e-posta içermemeli');
  assert.ok(!(await authGone(uid)), 'hesap HEMEN silinmez');
  assert.deepEqual(await sut().getAccountDeletionStatus(uid), { status: 'pending', scheduledAt: r.scheduledAt, requestedAt: iso(t0) });
});
const iso = (ms) => new Date(ms).toISOString();

test('tekrar çağrı idempotent: aynı scheduledAt, süre uzamaz', async () => {
  const uid = await mkUser();
  const t0 = Date.now();
  const a = await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  const b = await sut({ clk: () => t0 + 5 * DAY }).requestAccountDeletion(uid);
  assert.equal(b.already, true); assert.equal(b.scheduledAt, a.scheduledAt);
  assert.equal((await get('AccountDeletion', uid)).scheduledAt.toMillis(), t0 + 30 * DAY);
});

test('User belgesi yoksa tam taslak oluşur (role:user) ve deletion alanları yazılır', async () => {
  const uid = uidN();
  await auth.createUser({ uid, email: `${uid}@example.com`.toLowerCase() });
  await sut().requestAccountDeletion(uid);
  const u = await get('User', uid);
  assert.equal(u.role, 'user'); assert.equal(u._id, uid); assert.equal(u.deletionStatus, 'pending');
});

test('askıdaki koltuk tutmaları (held) sayılmaz, serbest bırakılır', async () => {
  const { svc, raw } = makeService();
  const uid = await mkUser();
  const ev = await seedEvent({ price: '100' });
  const h = await svc.holdSeats(uid, { eventId: ev, seatIds: ['A1', 'A2'] });
  await sut({ svc: raw }).requestAccountDeletion(uid);
  assert.equal((await get('Order', h.orderId)).status, 'cancelled');
  assert.equal((await get('Event', ev)).seats.A1.status, 'available');
});

// ------------------------------------------------------------------ bekleme süresi: satış reddi / iptal serbest
test('pending iken holdSeats/confirmFree/confirmReservation/startPayment ACCOUNT_DELETION_PENDING (PHONE_REQUIRED\'dan ÖNCE); cancelTicket serbest', async () => {
  const { svc } = makeService({ satis: 'db' });
  await H.setSatis({ mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 });
  const uid = await mkUser();
  const ev = await seedEvent({ price: '0' });
  const h = await svc.holdSeats(uid, { eventId: ev, seatIds: ['A1'] });
  await svc.confirmFree(uid, { orderId: h.orderId }); // henüz pending değil -> bilet alındı
  // Bilet varken istek reddedilir; pending'i sunucu belgesiyle simüle et (örn. 'paying' siparişin sonradan bilete dönüşmesi)
  const t0 = Date.now();
  await db.collection('AccountDeletion').doc(uid).set({ uid, status: 'pending', requestedAt: Timestamp.fromMillis(t0), scheduledAt: Timestamp.fromMillis(t0 + 30 * DAY) });
  const ev2 = await seedEvent({ price: '100' });
  const calls = [
    () => svc.holdSeats(uid, { eventId: ev2, seatIds: ['A1'] }),
    () => svc.confirmFree(uid, { orderId: 'x' }),
    () => svc.confirmReservation(uid, { orderId: 'x' }),
    () => svc.startPayment(uid, { orderId: 'x', provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/a' }),
    () => svc.holdSeats(uid, { eventId: ev2, seatIds: ['A1'] }, { phone: null }), // telefon yok: yine önce silme kapısı
  ];
  for (const c of calls) {
    const e = await expectCode(c(), 'failed-precondition');
    assert.equal(e.message, 'ACCOUNT_DELETION_PENDING');
    assert.equal(e.details.code, 'ACCOUNT_DELETION_PENDING');
    assert.equal(Date.parse(e.details.scheduledAt), t0 + 30 * DAY);
  }
  assert.equal((await db.collection('Order').get()).size, 1, 'yeni sipariş yazılmadı');
  await svc.cancelTicket(uid, { ticketId: h.orderId }); // iptal serbest
  assert.equal((await get('Ticket', h.orderId)).paymentStatus, 'cancelled');
});

test('YARIŞ KAPISI: onay işlemi içinde de denetlenir (held sipariş, sonradan pending olunca confirmFree reddedilir)', async () => {
  const { svc } = makeService();
  const uid = await mkUser();
  const ev = await seedEvent({ price: '0' });
  const h = await svc.holdSeats(uid, { eventId: ev, seatIds: ['A1'] });
  await db.collection('AccountDeletion').doc(uid).set({ uid, status: 'deleting', requestedAt: Timestamp.now(), scheduledAt: Timestamp.now() });
  await expectCode(svc.confirmFree(uid, { orderId: h.orderId }), 'failed-precondition');
  assert.equal(await get('Ticket', h.orderId), null);
});

// ------------------------------------------------------------------ vazgeç
test('cancelAccountDeletion: pending -> active, alanlar ve belge temizlenir, satış yeniden açılır; süresi dolmuş ama işlenmemiş de iptal edilir; kayıt yoksa idempotent', async () => {
  const { svc } = makeService();
  const uid = await mkUser();
  const t0 = Date.now() - 40 * DAY; // vadesi geçmiş ama işlenmemiş
  const s = sut({ clk: () => t0 });
  await s.requestAccountDeletion(uid);
  const r = await sut().cancelAccountDeletion(uid);
  assert.deepEqual(r, { status: 'active', wasPending: true });
  assert.equal(await get('AccountDeletion', uid), null);
  const u = await get('User', uid);
  assert.equal(u.deletionStatus, undefined); assert.equal(u.deletionScheduledAt, undefined); assert.equal(u.deletionRequestedAt, undefined);
  assert.equal(u.firstName, 'Ayşe');
  const ev = await seedEvent({ price: '0' });
  await svc.holdSeats(uid, { eventId: ev, seatIds: ['A1'] }); // satış serbest
  assert.deepEqual(await sut().cancelAccountDeletion(uid), { status: 'active', wasPending: false });
  assert.deepEqual(await sut().getAccountDeletionStatus(uid), { status: 'active' });
});

test('işlem başladıysa (deleting) vazgeçilemez: DELETION_IN_PROGRESS; request da aynı', async () => {
  const uid = await mkUser();
  await db.collection('AccountDeletion').doc(uid).set({ uid, status: 'deleting', requestedAt: Timestamp.now(), scheduledAt: Timestamp.now() });
  const e = await expectCode(sut().cancelAccountDeletion(uid), 'failed-precondition');
  assert.equal(e.details.code, 'DELETION_IN_PROGRESS');
  await expectCode(sut().requestAccountDeletion(uid), 'failed-precondition');
});

// ------------------------------------------------------------------ anonim hesap
test('anonim (misafir) hesap: bekleme yok, Auth + User anında silinir -> {status:deleted}', async () => {
  const uid = uidN();
  await auth.createUser({ uid }); // e-posta/telefon/sağlayıcı yok = anonim benzeri
  await db.collection('User').doc(uid).set({ _id: uid, role: 'guest' });
  const r = await sut().requestAccountDeletion(uid);
  assert.deepEqual(r, { status: 'deleted' });
  assert.ok(await authGone(uid));
  assert.equal(await get('User', uid), null);
  const rec = await get('AccountDeletion', uid);
  assert.equal(rec.status, 'deleted'); assert.ok(rec.deletedAt); assert.equal(rec.scheduledAt, undefined); assert.equal(rec.uid, undefined);
});

// ------------------------------------------------------------------ zamanlanmış silme
test('süresi dolan kayıt: Auth + User silinir; Ticket/Order ANONİMLEŞİR ama silinmez; Notification/Review/uid-limit silinir; ph_ sayaç KALIR; mezar taşı kişisel veri içermez', async () => {
  const uid = await mkUser();
  const key = keyFor(phoneFor(uid));
  const tk = await putTicket(uid, { delta: -2 * DAY });
  await db.collection('Notification').doc('n1').set({ userId: uid, title: 'x' });
  await db.collection('Notification').doc('n2').set({ userId: 'baska', title: 'y' });
  await db.collection('Review').doc(`${uid}_show1`).set({ userId: uid, showId: 'show1', rating: 5, text: 'iyi', userName: 'Ayşe' });
  await db.collection('ReviewReport').doc('rr1').set({ userId: uid, reviewId: 'z' });
  await db.collection('UserLimits').doc(uid).set({ phoneKey: key, freeTickets: 2 });
  await db.collection('UserLimits').doc(key).set({ freeTickets: 2, reservations: 1 });
  const images = [];
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid, { phone: phoneFor(uid) });

  // 29. gün: dokunulmaz
  const early = await sut({ clk: () => t0 + 29 * DAY, images }).processDue();
  assert.equal(early.deleted, 0);
  assert.ok(!(await authGone(uid)));

  const r = await sut({ clk: () => t0 + 31 * DAY, images }).processDue();
  assert.equal(r.deleted, 1); assert.equal(r.failed, 0);
  assert.ok(await authGone(uid));
  assert.equal(await get('User', uid), null);
  assert.deepEqual(images, [uid]);
  const tkd = await get('Ticket', tk.id);
  assert.equal(tkd.customerId, anonId(uid)); assert.equal(tkd.orderPrice, '100.00'); assert.deepEqual(tkd.buySeats, ['A1']); assert.equal(tkd.showName, 'Test Oyunu');
  const od = await get('Order', tk.id);
  assert.equal(od.userId, anonId(uid)); assert.equal(od.phoneKey, undefined); assert.equal(od.totalKurus, 10000); assert.equal(od.paymentId, 'pay_1');
  assert.equal(await get('Notification', 'n1'), null); assert.ok(await get('Notification', 'n2'));
  assert.equal(await get('Review', `${uid}_show1`), null); assert.equal(await get('ReviewReport', 'rr1'), null);
  assert.equal(await get('UserLimits', uid), null);
  assert.equal((await get('UserLimits', key)).freeTickets, 2, 'telefon sayacı KASITLI kalır');
  const rec = await get('AccountDeletion', uid);
  assert.deepEqual(Object.keys(rec).sort(), ['deletedAt', 'status']);
  assert.equal(rec.status, 'deleted');
  const hb = await get('System', 'processAccountDeletions');
  assert.equal(hb.deleted, 1); assert.ok(hb.lastRunAt);
  // aynı telefonla yeni hesap: ücretsiz hak sıfırlanmadı
  const { svc } = makeService();
  const fresh = uidN();
  const ev = await seedEvent({ price: '0' });
  await expectCode(svc.holdSeats(fresh, { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: phoneFor(uid) }), 'resource-exhausted');
  // tekrar çalıştırma: işlenecek bir şey yok, hata yok
  const again = await sut({ clk: () => t0 + 32 * DAY }).processDue();
  assert.equal(again.scanned, 0);
});

test('30. günde gelecek bilet çıkmışsa silme ERTELENİR (son etkinlik + 1 gün), kullanıcıya bildirim; sonra silinir', async () => {
  const uid = await mkUser();
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  const late = await putTicket(uid, { delta: 45 * DAY, status: 'pay_at_venue', method: 'venue' }); // pending sırasında bilete dönüşen sipariş
  const evMs = Date.now() + 45 * DAY; // etkinlik tarihi (dakika hassasiyetinde)
  const r = await sut({ clk: () => t0 + 31 * DAY }).processDue();
  assert.equal(r.postponed, 1); assert.equal(r.deleted, 0);
  const rec = await get('AccountDeletion', uid);
  assert.equal(rec.status, 'pending'); assert.equal(rec.postponedCount, 1);
  assert.ok(Math.abs(rec.scheduledAt.toMillis() - (evMs + DAY)) < 3 * 60000);
  assert.equal((await get('User', uid)).deletionScheduledAt.toMillis(), rec.scheduledAt.toMillis());
  assert.ok(!(await authGone(uid)));
  const notes = (await db.collection('Notification').where('userId', '==', uid).get()).docs;
  assert.equal(notes.length, 1); assert.match(notes[0].data().body, /ertelendi/);
  // bilet tarihi geçince silinir
  const r2 = await sut({ clk: () => evMs + 3 * DAY }).processDue();
  assert.equal(r2.deleted, 1);
  assert.ok(await authGone(uid));
  assert.equal((await get('Ticket', late.id)).customerId, anonId(uid));
});

test('ödemesi süren (paying) sipariş varsa silme 1 gün ertelenir', async () => {
  const uid = await mkUser();
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  await db.collection('Order').doc('pay1').set({ userId: uid, status: 'paying', eventId: 'e', seatIds: [] });
  const r = await sut({ clk: () => t0 + 31 * DAY }).processDue();
  assert.equal(r.postponed, 1);
  assert.ok(!(await authGone(uid)));
});

test('DAYANIKLILIK: bir kullanıcının hatası diğerlerini durdurmaz; yığınlı sayfalama; yarım kalan silme yeniden denenince tamamlanır (idempotent)', async () => {
  const saved = cfg.ACCOUNT_DELETION.BATCH;
  cfg.ACCOUNT_DELETION.BATCH = 2; // 5 kayıt -> 3 sayfa
  try {
    const t0 = Date.now();
    const uids = [];
    for (let i = 0; i < 5; i++) { const u = await mkUser(); uids.push(u); await sut({ clk: () => t0 + i * 1000 }).requestAccountDeletion(u); }
    await putTicket(uids[1], { delta: -DAY });
    const bad = uids[1];
    const flaky = new Proxy(auth, { get: (t, p) => (p === 'deleteUser' ? async (id) => { if (id === bad) { const e = new Error('boom'); e.code = 'auth/internal-error'; throw e; } return t.deleteUser(id); } : typeof t[p] === 'function' ? t[p].bind(t) : t[p]) });
    const later = t0 + 31 * DAY;
    const r = await sut({ clk: () => later, authImpl: flaky }).processDue();
    assert.equal(r.scanned, 5); assert.equal(r.deleted, 4); assert.equal(r.failed, 1);
    for (const u of uids) assert.equal(await authGone(u), u !== bad);
    const rec = await get('AccountDeletion', bad);
    assert.equal(rec.status, 'deleting'); assert.equal(rec.lastError, 'auth/internal-error'); assert.equal(rec.attempts, 1); assert.equal(rec.errorCount, 1); assert.equal(rec.claimedAt, undefined);
    // yarım: bilet anonimleşti AMA Auth hatasında User belgesi SİLİNMEDİ (kurtarılabilir); yeniden denemede tamamlanır
    assert.ok(await get('User', bad));
    const r2 = await sut({ clk: () => later + 1000 }).processDue();
    assert.equal(r2.deleted, 1); assert.equal(r2.failed, 0);
    assert.ok(await authGone(bad));
    assert.equal((await get('AccountDeletion', bad)).status, 'deleted');
    assert.equal((await get('System', 'processAccountDeletions')).deleted, 1);
  } finally { cfg.ACCOUNT_DELETION.BATCH = saved; }
});

test('maxPerRun sınırı: kalan ertesi çalışmaya bırakılır; taze "deleting" kilidi atlanır, bayat kilit yeniden alınır', async () => {
  const t0 = Date.now();
  const us = [];
  for (let i = 0; i < 3; i++) { const u = await mkUser(); us.push(u); await sut({ clk: () => t0 }).requestAccountDeletion(u); }
  const later = t0 + 31 * DAY;
  const r = await sut({ clk: () => later }).processDue({ maxPerRun: 2 });
  assert.equal(r.deleted, 2); assert.equal(r.remainingDue, 1);
  // taze kilit
  const left = us.find((u) => true && true);
  const [rest] = (await db.collection('AccountDeletion').where('status', '==', 'pending').get()).docs;
  await rest.ref.update({ status: 'deleting', claimedAt: Timestamp.fromMillis(later - 60 * 1000) });
  assert.equal((await sut({ clk: () => later }).processDue()).deleted, 0);
  assert.equal((await sut({ clk: () => later + cfg.ACCOUNT_DELETION.CLAIM_MS + 1000 }).processDue()).deleted, 1);
  assert.ok(left);
});

test('adminHealth.accountDeletion: bekleyen/vadesi geçmiş sayısı + kalp atışı', async () => {
  const { raw } = makeService();
  const admin = await makeAdmin();
  const t0 = Date.now() - 40 * DAY;
  const u = await mkUser();
  await sut({ clk: () => t0 }).requestAccountDeletion(u);
  let h = (await raw.adminHealth(admin)).accountDeletion;
  assert.equal(h.pending, 1); assert.equal(h.overdue, 1); assert.equal(h.lastRunAt, null); assert.equal(h.stale, true);
  await sut().processDue();
  h = (await raw.adminHealth(admin)).accountDeletion;
  assert.equal(h.pending, 0); assert.equal(h.overdue, 0); assert.equal(h.deleted, 1); assert.ok(h.lastRunAt); assert.equal(h.stale, false);
});

// ------------------------------------------------------------------ uçtan uca (gerçek index.js)
const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
async function call(name, data, token) {
  const r = await fetch(`http://${FN}/${PROJECT}/europe-west1/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
async function signUp(body) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ returnSecureToken: true, ...body }) });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
}

test('E2E: istek -> pending; durum; satış ACCOUNT_DELETION_PENDING (PHONE_REQUIRED\'dan önce); vazgeç; admin olmayan elle tetikleyemez; admin tetikler; anonim anında silinir', { timeout: 120000 }, async () => {
  const em = await signUp({ email: 'sil@example.com', password: 'Test1234!' });
  assert.equal((await call('requestAccountDeletion', {})).body.error.status, 'UNAUTHENTICATED');
  const r = await call('requestAccountDeletion', {}, em.token);
  assert.equal(r.status, 200); assert.equal(r.body.result.status, 'pending');
  assert.ok(Math.abs(Date.parse(r.body.result.scheduledAt) - (Date.now() + 30 * DAY)) < 5 * 60000);
  assert.equal((await call('requestAccountDeletion', {}, em.token)).body.result.already, true);
  assert.equal((await call('getAccountDeletionStatus', {}, em.token)).body.result.status, 'pending');
  const u = await get('User', em.uid);
  assert.equal(u.deletionStatus, 'pending');
  const ev = await seedEvent({ price: '0' });
  const hold = await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, em.token); // telefonsuz token: yine silme kapısı önce
  assert.equal(hold.body.error.message, 'ACCOUNT_DELETION_PENDING');
  assert.equal(hold.body.error.details.code, 'ACCOUNT_DELETION_PENDING');
  assert.equal((await call('adminProcessAccountDeletions', {}, em.token)).body.error.status, 'PERMISSION_DENIED');
  const c = await call('cancelAccountDeletion', {}, em.token);
  assert.deepEqual(c.body.result, { status: 'active', wasPending: true });
  assert.equal((await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, em.token)).body.error.message, 'PHONE_REQUIRED'); // kapı kalktı
  // admin elle tetikleme
  const ad = await signUp({ email: 'admin@example.com', password: 'Test1234!' });
  await db.collection('User').doc(ad.uid).set({ role: 'admin' });
  const p = await call('adminProcessAccountDeletions', {}, ad.token);
  assert.equal(p.status, 200); assert.equal(p.body.result.failed, 0);
  // anonim
  const an = await signUp({});
  const d = await call('requestAccountDeletion', {}, an.token);
  assert.deepEqual(d.body.result, { status: 'deleted' });
  assert.ok(await authGone(an.uid));
  // gelecek biletle reddedilir (HTTP hata gövdesi)
  const withTk = await signUp({ email: 'bilet@example.com', password: 'Test1234!' });
  await putTicket(withTk.uid, { delta: 5 * DAY });
  const rej = await call('requestAccountDeletion', {}, withTk.token);
  assert.equal(rej.body.error.status, 'FAILED_PRECONDITION');
  assert.equal(rej.body.error.message, 'UPCOMING_TICKETS');
  assert.equal(rej.body.error.details.count, 1);
});

// ------------------------------------------------------------------ KAPSAM + HATA ENJEKSİYONU (yarım kalma / atomiklik kanıtı)
const { deleteProfileImages } = require('../src/storage');

/** Tüm koleksiyonlarda (kök) belge içeriği + kimliklerinde `needles`i arar. AccountDeletion/{uid} kimliği hariç (mezar taşı anahtarı). */
async function scanPii(needles) {
  const hits = [];
  for (const col of await db.listCollections()) {
    const snap = await col.get();
    for (const d of snap.docs) {
      const blob = JSON.stringify(d.data(), (k, v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : v));
      const hay = col.id === 'AccountDeletion' ? blob : `${d.id} ${blob}`;
      for (const n of needles) if (hay.includes(n)) hits.push(`${col.id}/${d.id} ~ ${n}`);
    }
  }
  return hits;
}

test('KAPSAM: silme sonrası uid / e-posta / telefon / ad-soyad HİÇBİR koleksiyonda kalmaz (eski biçim alanlar dahil); ph_ sayaç KALIR; başkasının verisine dokunulmaz', async () => {
  const uid = await mkUser();
  const phone = phoneFor(uid), key = keyFor(phone), email = `${uid}@example.com`.toLowerCase();
  const tk = await putTicket(uid, { delta: -2 * DAY });
  const tk2 = await putTicket(uid, { delta: -9 * DAY, status: 'cancelled' });
  // eski biçim kalıntılar: bilette kişisel alanlar, etkinlik koltuğunda customerId, sipariş
  await db.collection('Ticket').doc(tk.id).update({ customerName: 'Ayşe Yılmaz', email, phone, buyerName: 'Ayşe' });
  await db.collection('Event').doc(tk.ev).update({ 'seats.A1': { status: 'sold', orderId: tk.id, customerId: uid }, 'seats.A2': { status: 'sold', orderId: 'baskasi', customerId: 'baska-kisi' } });
  await db.collection('Notification').doc('n1').set({ userId: uid, title: 'Merhaba Ayşe Yılmaz', body: email });
  await db.collection('Review').doc(`${uid}_show1`).set({ userId: uid, showId: 'show1', rating: 4, text: 'güzel', userName: 'Ayşe Yılmaz', userImage: 'https://x/ppics/a.jpg' });
  await db.collection('ReviewReport').doc('rr1').set({ userId: uid, reviewId: 'r' });
  await db.collection('NotificationLog').doc('nl1').set({ sentBy: uid, sentByName: 'Ayşe Yılmaz', title: 't' });
  await db.collection('UserLimits').doc(uid).set({ phoneKey: key, freeTickets: 1, reservations: 0 });
  await db.collection('UserLimits').doc(key).set({ freeTickets: 1, reservations: 0 });
  await db.collection('Notification').doc('baskasi').set({ userId: 'baska-kisi', title: 'ok' });
  assert.ok((await scanPii([uid, email, phone, 'Ayşe', 'Yılmaz'])).length > 5, 'tarama kendini doğrulamalı: silmeden önce bulur');

  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid, { phone });
  const r = await sut({ clk: () => t0 + 31 * DAY }).processDue();
  assert.equal(r.deleted, 1);
  assert.deepEqual(await scanPii([uid, email, phone, 'Ayşe', 'Yılmaz', 'ayşe']), []);
  assert.ok(await authGone(uid));
  // yasal saklama kaldı: mali alanlar duruyor
  const a = await get('Ticket', tk.id), b = await get('Ticket', tk2.id);
  assert.equal(a.customerId, anonId(uid)); assert.equal(b.customerId, anonId(uid));
  assert.equal(a.orderPrice, '100.00'); assert.equal(b.paymentStatus, 'cancelled'); assert.equal(a.customerName, undefined); assert.equal(a.email, undefined);
  assert.equal((await get('UserLimits', key)).freeTickets, 1);
  assert.ok(await get('Notification', 'baskasi'));
  const ev = await get('Event', tk.ev);
  assert.equal(ev.seats.A1.customerId, undefined); assert.equal(ev.seats.A1.status, 'sold'); assert.equal(ev.seats.A2.customerId, 'baska-kisi');
  const nl = await get('NotificationLog', 'nl1');
  assert.equal(nl.sentBy, anonId(uid)); assert.equal(nl.sentByName, '');
});

test('HATA ENJEKSİYONU: Storage silme hatası -> Firestore/Auth verisine HİÇ dokunulmaz, kayıt yeniden denenebilir kalır; ertesi çalışma tamamlar', async () => {
  const uid = await mkUser();
  const tk = await putTicket(uid, { delta: -DAY });
  await db.collection('Notification').doc('n1').set({ userId: uid });
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  let fail = true; const calls = [];
  const mk = (clk) => createAccountDeletion({ db, auth, orderService: null, salt: TEST_SALT, now: clk, log: silent, deleteProfileImage: async (u) => { calls.push(u); if (fail) { const e = new Error('storage down (ayse@example.com)'); e.code = 'storage/unavailable'; throw e; } } });
  const later = t0 + 31 * DAY;
  const r1 = await mk(() => later).processDue();
  assert.equal(r1.failed, 1); assert.equal(r1.deleted, 0);
  assert.ok(!(await authGone(uid))); assert.ok(await get('User', uid));
  assert.equal((await get('Ticket', tk.id)).customerId, uid, 'bilet anonimleşmedi (storage ilk adım)');
  assert.ok(await get('Notification', 'n1'));
  const rec = await get('AccountDeletion', uid);
  assert.equal(rec.status, 'deleting'); assert.equal(rec.errorCount, 1); assert.equal(rec.lastError, 'storage/unavailable'); assert.equal(rec.claimedAt, undefined);
  assert.ok(!JSON.stringify(rec).includes('ayse@example.com'), 'hata MESAJI (kişisel veri içerebilir) kayda yazılmaz');
  // yarım kalan hesap iptal edilemez (kısmen silinmiş olabilir)
  await expectCode(sut().cancelAccountDeletion(uid), 'failed-precondition');
  fail = false;
  const r2 = await mk(() => later + 1000).processDue();
  assert.equal(r2.deleted, 1);
  assert.deepEqual(await scanPii([uid]), []);
  assert.ok(calls.length >= 2);
});

/** Firestore sarmalayıcı: n. batch.commit() hata verir (Ticket anonimleştirme sayfalarını yarıda keser). */
function flakyDb(failOnCommit) {
  let n = 0;
  return new Proxy(db, {
    get(t, p) {
      if (p === 'batch') return () => { const b = t.batch(); const c = b.commit.bind(b); b.commit = async () => { n += 1; if (n === failOnCommit) throw Object.assign(new Error('commit kesildi'), { code: 'unavailable' }); return c(); }; return b; };
      const v = t[p]; return typeof v === 'function' ? v.bind(t) : v;
    },
  });
}

test('HATA ENJEKSİYONU: 2. sayfada kesilen bilet anonimleştirme -> yeniden çalışınca kalanlar tamamlanır; çift işlem / kayıp yok; User kurtarılabilir kaldı', async () => {
  const saved = cfg.ACCOUNT_DELETION.DOC_BATCH;
  cfg.ACCOUNT_DELETION.DOC_BATCH = 2; // 5 bilet = 3 sayfa
  try {
    const uid = await mkUser();
    const ids = [];
    for (let i = 0; i < 5; i++) ids.push((await putTicket(uid, { delta: -DAY })).id);
    const t0 = Date.now();
    await sut({ clk: () => t0 }).requestAccountDeletion(uid);
    const later = t0 + 31 * DAY;
    const bad = createAccountDeletion({ db: flakyDb(2), auth, salt: TEST_SALT, now: () => later, log: silent });
    const r1 = await bad.processDue();
    assert.equal(r1.failed, 1);
    const mid = await Promise.all(ids.map((id) => get('Ticket', id)));
    assert.equal(mid.filter((t) => t.customerId === anonId(uid)).length, 2, 'ilk sayfa tamamlandı');
    assert.equal(mid.filter((t) => t.customerId === uid).length, 3, 'kalanlar henüz kişisel');
    assert.ok(await get('User', uid)); assert.ok(!(await authGone(uid)));
    const r2 = await sut({ clk: () => later + 1000 }).processDue();
    assert.equal(r2.deleted, 1);
    const end = await Promise.all(ids.map((id) => get('Ticket', id)));
    assert.equal(end.length, 5);
    assert.ok(end.every((t) => t.customerId === anonId(uid) && t.orderPrice === '100.00'));
    assert.equal((await db.collection('Ticket').get()).size, 5, 'bilet silinmedi / çoğalmadı');
    assert.deepEqual(await scanPii([uid]), []);
  } finally { cfg.ACCOUNT_DELETION.DOC_BATCH = saved; }
});

test('ÇÖKME / LEASE: "deleting"de bırakılmış taze kilit atlanır, bayat kilit (çökmüş işleyici) devralınır ve işlem tamamlanır', async () => {
  const uid = await mkUser();
  await putTicket(uid, { delta: -DAY });
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  const later = t0 + 31 * DAY;
  // işleyici çöktü: yarım iş (ör. bilet zaten anonimleşmiş) + kilit
  await db.collection('AccountDeletion').doc(uid).update({ status: 'deleting', claimedAt: Timestamp.fromMillis(later - 60000), attempts: 1 });
  assert.equal((await sut({ clk: () => later }).processDue()).deleted, 0, 'taze kilit: başka işleyici çalışıyor sayılır');
  assert.ok(!(await authGone(uid)));
  const r = await sut({ clk: () => later + cfg.ACCOUNT_DELETION.CLAIM_MS + 1 }).processDue();
  assert.equal(r.deleted, 1);
  assert.ok(await authGone(uid));
});

test('EŞZAMANLI iki işleyici aynı kullanıcıyı işleyemez (kilit): biri siler, diğeri atlar; Storage/Auth bir kez çağrılır', async () => {
  const uid = await mkUser();
  await putTicket(uid, { delta: -DAY });
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  const imgs = [];
  const a = sut({ clk: () => t0 + 31 * DAY, images: imgs }), b = sut({ clk: () => t0 + 31 * DAY, images: imgs });
  const out = await Promise.all([a.processOne(uid), b.processOne(uid)]);
  assert.deepEqual([...out].sort(), ['deleted', 'skipped']);
  assert.equal(imgs.length, 1);
  assert.deepEqual(await scanPii([uid]), []);
});

test('Auth kullanıcısı zaten silinmişse (user-not-found) silme BAŞARI sayılır (yeniden deneme güvenli)', async () => {
  const uid = await mkUser();
  const t0 = Date.now();
  await sut({ clk: () => t0 }).requestAccountDeletion(uid);
  await auth.deleteUser(uid);
  const r = await sut({ clk: () => t0 + 31 * DAY }).processDue();
  assert.equal(r.deleted, 1); assert.equal(r.failed, 0);
  assert.equal(await get('User', uid), null);
});

test('adminHealth.accountDeletion.failing: errorCount >= eşik olan kayıtlar sayılır', async () => {
  const { raw } = makeService();
  const admin = await makeAdmin();
  const t = Date.now();
  await db.collection('AccountDeletion').doc('x1').set({ uid: 'x1', status: 'deleting', scheduledAt: Timestamp.fromMillis(t - DAY), errorCount: cfg.ACCOUNT_DELETION.FAILING_AT, lastError: 'auth/internal-error' });
  await db.collection('AccountDeletion').doc('x2').set({ uid: 'x2', status: 'deleting', scheduledAt: Timestamp.fromMillis(t - DAY), errorCount: 1 });
  const h = (await raw.adminHealth(admin)).accountDeletion;
  assert.equal(h.failing, 1); assert.equal(h.overdue, 2); assert.equal(h.stale, true);
});

// ------------------------------------------------------------------ Storage
test('Storage yardımcısı: ppics/{uid}. ve ppics/{uid}/ ÖN EKLERİNİ siler (jpg/png/webp/alt klasör); geçersiz uid reddedilir', async () => {
  const seen = [];
  await deleteProfileImages({ deleteFiles: async (o) => { seen.push(o); } }, 'abc123');
  assert.deepEqual(seen, [{ prefix: 'ppics/abc123.', force: true }, { prefix: 'ppics/abc123/', force: true }]);
  for (const bad of ['', 'a/b', '../x', 'a.b', null]) await assert.rejects(deleteProfileImages({ deleteFiles: async () => {} }, bad));
});

test('Storage EMÜLATÖRÜ (varsa): ppics/{uid}.jpg/.png/alt klasör silinir, başka uid dosyası ve diğer klasörler KALIR; ikinci çağrı hatasız', { skip: !process.env.FIREBASE_STORAGE_EMULATOR_HOST }, async () => {
  const { getStorage } = require('firebase-admin/storage');
  const bucket = getStorage().bucket(`${PROJECT}.appspot.com`);
  const uid = 'storageUser1';
  const put = (n) => bucket.file(n).save(Buffer.from('x'), { contentType: 'image/jpeg' });
  await Promise.all(['ppics/storageUser1.jpg', 'ppics/storageUser1.png', 'ppics/storageUser1/a.webp', 'ppics/storageUser10.jpg', 'ppics/baska.jpg', 'ShowImages/s1.jpg'].map(put));
  await deleteProfileImages(bucket, uid);
  const [files] = await bucket.getFiles();
  assert.deepEqual(files.map((f) => f.name).sort(), ['ShowImages/s1.jpg', 'ppics/baska.jpg', 'ppics/storageUser10.jpg']);
  await deleteProfileImages(bucket, uid); // dosya yok: hata yok
  // uçtan uca: silme akışı Storage'ı da temizler
  await put('ppics/storageUser2.jpg');
  const real = createAccountDeletion({ db, auth, salt: TEST_SALT, now: Date.now, log: silent, deleteProfileImage: (u) => deleteProfileImages(bucket, u) });
  const u2 = 'storageUser2';
  await auth.createUser({ uid: u2, email: 'st2@example.com' });
  await db.collection('User').doc(u2).set({ role: 'user' });
  const t0 = Date.now();
  await createAccountDeletion({ db, auth, salt: TEST_SALT, now: () => t0, log: silent }).requestAccountDeletion(u2);
  const rr = await createAccountDeletion({ db, auth, salt: TEST_SALT, now: () => t0 + 31 * DAY, log: silent, deleteProfileImage: (u) => deleteProfileImages(bucket, u) }).processDue();
  assert.equal(rr.deleted, 1);
  assert.equal((await bucket.file('ppics/storageUser2.jpg').exists())[0], false);
  assert.ok(real);
});

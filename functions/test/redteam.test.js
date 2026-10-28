'use strict';
/**
 * RED-TEAM (S-1, docs/GUVENLIK-DENETIMI.md): saldırgan gözüyle denemeler. Hepsinin REDDEDİLMESİ beklenir.
 * Gerçek firestore.rules + storage.rules (emülatör), gerçek functions/index.js (functions emülatörü, HTTP).
 * Çalıştırma: npm --prefix functions run test:emulator  (firestore, auth, functions, storage emülatörleri gerekir)
 */
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, query, where, limit, serverTimestamp, deleteField, Timestamp } = require('firebase/firestore');
const { ref: sref, uploadBytes, getBytes, deleteObject, listAll } = require('firebase/storage');

const ROOT = path.join(__dirname, '..', '..');
const RULES = fs.readFileSync(path.join(ROOT, 'firestore.rules'), 'utf8');
const [fsHost, fsPort] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
const STORAGE_HOST = process.env.FIREBASE_STORAGE_EMULATOR_HOST;

let env;
before(async () => {
  const cfg = { projectId: 'redteam-test', firestore: { host: fsHost, port: Number(fsPort), rules: RULES } };
  if (STORAGE_HOST) {
    const [h, p] = STORAGE_HOST.split(':');
    cfg.storage = { host: h, port: Number(p), rules: fs.readFileSync(path.join(ROOT, 'storage.rules'), 'utf8') };
  }
  env = await initializeTestEnvironment(cfg);
});
after(async () => { await env.cleanup(); });

const PH = '+905551112233';
const asUid = (uid, claims = {}) => env.authenticatedContext(uid, claims);
const as = (uid, claims) => asUid(uid, claims).firestore();
const asPhone = (uid) => as(uid, { phone_number: PH });
const asAnonProvider = (uid) => as(uid, { firebase: { sign_in_provider: 'anonymous' } });
const anon = () => env.unauthenticatedContext().firestore();

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/admin1'), { role: 'admin' });
    await setDoc(doc(d, 'User/alice'), { role: 'user', firstName: 'A' });
    await setDoc(doc(d, 'User/bob'), { role: 'user' });
    await setDoc(doc(d, 'User/norole'), { firstName: 'NoRole' }); // role alanı YOK
    await setDoc(doc(d, 'User/nullrole'), { role: null });
    await setDoc(doc(d, 'User/capadmin'), { role: 'Admin' }); // büyük harf
    await setDoc(doc(d, 'User/arradmin'), { role: ['admin'] });
    await setDoc(doc(d, 'User/mapadmin'), { role: { name: 'admin' } });
    await setDoc(doc(d, 'Show/s1'), { name: 'Oyun' });
    await setDoc(doc(d, 'Event/e1'), { price: '100', seats: { A1: { status: 'available' } } });
    await setDoc(doc(d, 'Team/t1'), { name: 'Ekip' });
    await setDoc(doc(d, 'Stage/g1'), { name: 'Sahne' });
    await setDoc(doc(d, 'Player/p1'), { name: 'Oyuncu' });
    await setDoc(doc(d, 'Campaign/c1'), { name: 'Kampanya' });
    await setDoc(doc(d, 'Ticket/t1'), { customerId: 'alice', eventId: 'e1', buySeats: ['A1'] });
    await setDoc(doc(d, 'Order/o1'), { userId: 'alice', status: 'held' });
    await setDoc(doc(d, 'UserLimits/alice'), { freeTickets: 3 });
    await setDoc(doc(d, 'Config/satis'), { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 });
    await setDoc(doc(d, 'Stats/views/days/2026-01-01'), { total: 5 });
    await setDoc(doc(d, 'System/expireHolds'), { lastRunAt: 1 });
    await setDoc(doc(d, 'NotificationLog/n1'), { title: 'x' });
    await setDoc(doc(d, 'AccountDeletion/bob'), { status: 'pending' });
    await setDoc(doc(d, 'Notification/n1'), { userId: 'alice', title: 'x', isRead: false });
    await setDoc(doc(d, 'Review/alice_s1'), { showId: 's1', userId: 'alice', userName: 'A', userImage: '', rating: 4, text: 'iyi', hidden: false });
  });
});

// ------------------------------------------------------------------ (a) role yükseltme
test('(a) create: kendi User belgesini role admin/curator/büyük harf/dizi/map ile oluşturma REDDEDİLİR', async () => {
  const d = as('mallory');
  for (const role of ['admin', 'curator', 'Admin', 'ADMIN', ['admin'], { name: 'admin' }, 5, true]) {
    await assertFails(setDoc(doc(d, 'User/mallory'), { role, firstName: 'M' }));
  }
  await assertFails(setDoc(doc(d, 'User/mallory'), { role: 'admin' }, { merge: true }));
  await assertSucceeds(setDoc(doc(d, 'User/mallory'), { role: 'user', firstName: 'M' })); // meşru kayıt çalışır
  await assertSucceeds(setDoc(doc(as('m2'), 'User/m2'), { firstName: 'rolsüz' })); // role alanı hiç yok = 'user' sayılır
});

test('(a) update: role değiştirme (set merge, update, silme, tür karışıklığı, nested) REDDEDİLİR; sonra Show yazamaz', async () => {
  const d = as('alice');
  const u = doc(d, 'User/alice');
  await assertFails(updateDoc(u, { role: 'admin' }));
  await assertFails(updateDoc(u, { role: 'curator' }));
  await assertFails(updateDoc(u, { role: 'Admin' }));
  await assertFails(updateDoc(u, { role: ['admin'] }));
  await assertFails(updateDoc(u, { role: { name: 'admin' } }));
  await assertFails(updateDoc(u, { role: deleteField() }));
  await assertFails(setDoc(u, { role: 'admin' }, { merge: true }));
  await assertFails(setDoc(u, { role: 'admin', firstName: 'A' })); // tam üzerine yazma
  await assertFails(setDoc(u, { firstName: 'A' })); // role alanını SİLEREK üzerine yazma
  await assertFails(deleteDoc(u));
  // role olmayan belgeye role ekleme
  await assertFails(updateDoc(doc(as('norole'), 'User/norole'), { role: 'admin' }));
  await assertFails(updateDoc(doc(as('nullrole'), 'User/nullrole'), { role: 'admin' }));
  // nested alan zararsızdır: izin verilse bile isAdmin() bunu OKUMAZ
  await updateDoc(u, { 'profile.role': 'admin' }).catch(() => {});
  await assertFails(setDoc(doc(d, 'Show/hack'), { name: 'x' }));
  await assertFails(updateDoc(doc(d, 'Show/s1'), { name: 'hacked' }));
});

test('(a) update: sunucu alanları (isPhoneActive:true, phoneVerifiedAt, phoneKey, deletion*) istemciden yazılamaz', async () => {
  const d = as('alice');
  const u = doc(d, 'User/alice');
  await assertFails(updateDoc(u, { isPhoneActive: true }));
  await assertFails(updateDoc(u, { phoneVerifiedAt: Timestamp.now() }));
  await assertFails(updateDoc(u, { phoneKey: 'abc' }));
  await assertFails(updateDoc(u, { deletionStatus: 'deleted' }));
  await assertFails(updateDoc(u, { deletionScheduledAt: Timestamp.now() }));
  await assertFails(updateDoc(u, { phoneNumber: '+905000000000' })); // token'daki doğrulanmış numara değil
  await assertFails(updateDoc(u, { notifPrefs: { loudAlarm: true, evil: 1 } }));
  await assertFails(updateDoc(u, { notifPrefs: 'x' }));
  await assertSucceeds(updateDoc(u, { firstName: 'Ayşe', notifPrefs: { loudAlarm: false } }));
});

// ------------------------------------------------------------------ (b) başkasının User belgesi
test('(b) başkasının User belgesini okuma/yazma/listeleme/silme REDDEDİLİR', async () => {
  const d = as('alice');
  await assertFails(getDoc(doc(d, 'User/bob')));
  await assertFails(updateDoc(doc(d, 'User/bob'), { firstName: 'x' }));
  await assertFails(setDoc(doc(d, 'User/bob'), { role: 'user' }));
  await assertFails(deleteDoc(doc(d, 'User/bob')));
  await assertFails(getDocs(collection(d, 'User')));
  await assertFails(getDocs(query(collection(d, 'User'), where('role', '==', 'admin'))));
  await assertFails(getDoc(doc(anon(), 'User/alice')));
  await assertFails(getDocs(collection(as('admin1'), 'User'))); // admin bile istemciden tüm kullanıcıları listeleyemez
  await assertSucceeds(getDoc(doc(d, 'User/alice')));
});

// ------------------------------------------------------------------ (c) koleksiyon yazma/okuma matrisi
test('(c) normal kullanıcı ve anonim: tüm korumalı koleksiyonlara yazamaz', async () => {
  const targets = [
    'Ticket/t1', 'Ticket/yeni', 'Order/o1', 'Order/yeni', 'Event/e1', 'Event/yeni', 'Show/s1', 'Show/yeni', 'Team/t1', 'Team/yeni',
    'Stage/g1', 'Player/p1', 'Campaign/c1', 'Seats/g1', 'AppTools/x', 'Config/satis', 'Config/bildirim', 'Config/yeni',
    'Stats/views', 'Stats/views/days/2026-01-01', 'Stats/views/days/yeni', 'System/expireHolds', 'System/x', 'NotificationLog/n1', 'NotificationLog/yeni',
    'AccountDeletion/alice', 'AccountDeletion/bob', 'UserLimits/alice', 'UserLimits/bob', 'Gizli/x', 'TeamManager/alice_t1', 'Admin/alice',
  ];
  for (const d of [as('alice'), asPhone('alice'), anon()]) {
    for (const t of targets) {
      await assertFails(setDoc(doc(d, t), { x: 1, role: 'admin', customerId: 'alice', userId: 'alice' }), `set ${t}`);
      await assertFails(setDoc(doc(d, t), { x: 1 }, { merge: true }), `merge ${t}`);
      await assertFails(deleteDoc(doc(d, t)), `delete ${t}`);
    }
    await assertFails(updateDoc(doc(d, 'Event/e1'), { 'seats.A1.status': 'sold' }));
    await assertFails(updateDoc(doc(d, 'Ticket/t1'), { customerId: 'alice', showName: 'x' }));
    await assertFails(updateDoc(doc(d, 'Order/o1'), { status: 'paid' }));
    await assertFails(updateDoc(doc(d, 'UserLimits/alice'), { freeTickets: 0 }));
    await assertFails(updateDoc(doc(d, 'Config/satis'), { mode: 'kapali' }));
  }
});

test('(c) korumalı koleksiyonlar okunamaz (başkasının bileti/siparişi/limiti, yönetim verileri, bilinmeyen koleksiyon)', async () => {
  for (const d of [as('bob'), anon()]) {
    for (const t of ['Ticket/t1', 'Order/o1', 'UserLimits/alice', 'Stats/views/days/2026-01-01', 'System/expireHolds', 'NotificationLog/n1', 'AccountDeletion/bob', 'Notification/n1', 'Gizli/x']) {
      await assertFails(getDoc(doc(d, t)), `get ${t}`);
    }
    await assertFails(getDocs(collection(d, 'Ticket')));
    await assertFails(getDocs(collection(d, 'Order')));
    await assertFails(getDocs(collection(d, 'Notification')));
    await assertFails(getDocs(collection(d, 'NotificationLog')));
    await assertFails(getDocs(query(collection(d, 'Ticket'), where('customerId', '==', 'alice')))); // sahte sorgu
  }
  await assertSucceeds(getDoc(doc(as('alice'), 'Ticket/t1')));
  await assertSucceeds(getDoc(doc(as('alice'), 'Order/o1')));
});

test('(c) bilet sahibi kendi kimliğini başkasına çeviremez; admin bile bilet/sipariş uyduramaz', async () => {
  await assertFails(updateDoc(doc(as('alice'), 'Ticket/t1'), { customerId: 'bob' }));
  const a = as('admin1');
  await assertFails(setDoc(doc(a, 'Ticket/adminyeni'), { customerId: 'alice' }));
  await assertFails(updateDoc(doc(a, 'Ticket/t1'), { orderPrice: '0.00' })); // yalnız arşiv özet alanları
  await assertFails(updateDoc(doc(a, 'Ticket/t1'), { customerId: 'admin1' }));
  await assertFails(setDoc(doc(a, 'Order/o9'), { userId: 'admin1' }));
  await assertFails(deleteDoc(doc(a, 'Ticket/t1')));
  await assertSucceeds(updateDoc(doc(a, 'Ticket/t1'), { showName: 'Arşiv' }));
});

// ------------------------------------------------------------------ (d) Team / yönetici olma yolları
test('(d) kendini Team yöneticisi/admin yapma yolları kapalı', async () => {
  const d = as('alice');
  await assertFails(updateDoc(doc(d, 'Team/t1'), { managers: ['alice'], adminIds: ['alice'], ownerId: 'alice' }));
  await assertFails(setDoc(doc(d, 'Team/t1'), { name: 'Ekip', managers: ['alice'] }));
  await assertFails(setDoc(doc(d, 'Team/benim'), { name: 'Ekibim', ownerId: 'alice' }));
  await assertFails(setDoc(doc(d, 'TeamManager/alice_t1'), { userId: 'alice', teamId: 't1', status: 'approved' }));
  await assertFails(setDoc(doc(d, 'User/alice'), { role: 'admin', teamId: 't1' }));
  // User belgesine rastgele alan eklemek (kuralda alan beyaz listesi yok) YETKİ VERMEZ: yetki yalnızca `role == 'admin'` okur.
  await assertSucceeds(updateDoc(doc(d, 'User/alice'), { managedTeams: ['t1'], isAdmin: true, admin: true }));
  await assertFails(setDoc(doc(d, 'Show/hack'), { name: 'x' }));
  await assertFails(updateDoc(doc(d, 'Team/t1'), { name: 'ele geçirildi' }));
});

// ------------------------------------------------------------------ (e) isAdmin() get() hileleri
test('(e) isAdmin hileleri: belgesiz, silinmiş, role eksik/null/büyük harf/dizi/map kullanıcılar içerik yazamaz', async () => {
  for (const uid of ['hayalet', 'norole', 'nullrole', 'capadmin', 'arradmin', 'mapadmin', 'alice']) {
    const d = as(uid);
    await assertFails(setDoc(doc(d, 'Show/hack'), { name: 'x' }), uid);
    await assertFails(updateDoc(doc(d, 'Event/e1'), { price: '0' }), uid);
    await assertFails(setDoc(doc(d, 'Config/satis'), { mode: 'online', rezervasyonLimit: 1, iptalSaat: 1 }), uid);
    await assertFails(getDoc(doc(d, 'AccountDeletion/bob')), uid);
    await assertFails(getDoc(doc(d, 'System/expireHolds')), uid);
  }
  // admin belgesi silinince (Admin SDK ile) yetki ANINDA biter
  await assertSucceeds(setDoc(doc(as('admin1'), 'Show/ok'), { name: 'ok' }));
  await env.withSecurityRulesDisabled(async (ctx) => { await deleteDoc(doc(ctx.firestore(), 'User/admin1')); });
  await assertFails(setDoc(doc(as('admin1'), 'Show/ok2'), { name: 'x' }));
  // role admin'den 'user'a düşünce biter
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'User/admin1'), { role: 'user' }); });
  await assertFails(setDoc(doc(as('admin1'), 'Show/ok3'), { name: 'x' }));
  // anonim: get() çalışmaz
  await assertFails(setDoc(doc(anon(), 'Show/anon'), { name: 'x' }));
  // custom claim ile admin olunmaz (kural claim'e güvenmez, belgeye bakar)
  await assertFails(setDoc(doc(as('alice', { admin: true, role: 'admin', isAdmin: true }), 'Show/claim'), { name: 'x' }));
  // e-posta ile admin olunmaz
  await assertFails(setDoc(doc(as('alice', { email: 'admin@tiyatrol.com', email_verified: true }), 'Show/mail'), { name: 'x' }));
});

test('(e) Config şeması: admin bile geçersiz satış modu/limit yazamaz', async () => {
  const a = as('admin1');
  await assertFails(setDoc(doc(a, 'Config/satis'), { mode: 'bedava', rezervasyonLimit: 3, iptalSaat: 24 }));
  await assertFails(setDoc(doc(a, 'Config/satis'), { mode: 'online', rezervasyonLimit: 9999, iptalSaat: 24 }));
  await assertFails(deleteDoc(doc(a, 'Config/satis')));
});

// ------------------------------------------------------------------ (f) Review / ReviewReport / Notification
const rev = (o = {}) => ({ showId: 's1', userId: 'carol', userName: 'Carol', userImage: '', rating: 5, text: 'harika', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), hidden: false, ...o });

test('(f) Review create: gerçek mobil payload telefonlu kullanıcıyla geçer; telefonsuz/anonim/sahte kimlik/aralık dışı reddedilir', async () => {
  const c = asPhone('carol');
  await assertSucceeds(setDoc(doc(c, 'Review/carol_s1'), rev())); // mobil ReviewRepository.upsert (ilk yazım) ile birebir
  // telefonsuz hesap
  await assertFails(setDoc(doc(as('dave'), 'Review/dave_s1'), rev({ userId: 'dave' })));
  // anonim sağlayıcı (telefon claim'i olsa bile)
  await assertFails(setDoc(doc(as('erin', { phone_number: PH, firebase: { sign_in_provider: 'anonymous' } }), 'Review/erin_s1'), rev({ userId: 'erin' })));
  await assertFails(setDoc(doc(anon(), 'Review/x_s1'), rev({ userId: 'x' })));
});

test('(f) Review create: taklit, sunucu alanı, tür/boyut/değer saldırıları reddedilir', async () => {
  const c = asPhone('carol');
  const bad = async (o, id = 'carol_s1') => assertFails(setDoc(doc(c, `Review/${id}`), rev(o)), JSON.stringify(Object.keys(o)));
  await bad({ userId: 'bob' }); // başkası adına
  await assertFails(setDoc(doc(c, 'Review/bob_s1'), rev({ userId: 'bob' })));
  await assertFails(setDoc(doc(c, 'Review/bob_s1'), rev())); // başkasının kimliğiyle belge
  await assertFails(setDoc(doc(c, 'Review/carol_s2'), rev())); // kimlik showId ile uyuşmuyor
  await assertFails(setDoc(doc(c, 'Review/carol_yok'), rev({ showId: 'yok' }))); // olmayan oyun
  await bad({ rating: 0 }); await bad({ rating: 6 }); await bad({ rating: 5.5 }); await bad({ rating: '5' }); await bad({ rating: null });
  await bad({ text: 'x'.repeat(601) }); await bad({ text: 5 }); await bad({ text: ['a'] });
  await bad({ hidden: true }); await bad({ hidden: 'false' });
  await bad({ verified: true }); await bad({ isAdmin: true }); await bad({ likes: 9999 }); await bad({ role: 'admin' }); // fazladan alan
  await bad({ userName: 'x'.repeat(81) }); await bad({ userName: { a: 1 } }); await bad({ userImage: 'x'.repeat(601) });
  await bad({ showId: 5 }); await bad({ showId: '' });
  await bad({ createdAt: Timestamp.fromDate(new Date('2001-01-01')) }); // istemci zamanı
  await bad({ updatedAt: Timestamp.fromDate(new Date('2001-01-01')) });
  const { createdAt, ...noCreated } = rev(); void createdAt; // zorunlu createdAt eksik
  await assertFails(setDoc(doc(c, 'Review/carol_s1'), noCreated));
  const { text, ...noText } = rev(); void text; // zorunlu text eksik
  await assertFails(setDoc(doc(c, 'Review/carol_s1'), noText));
});

test('(f) Review update/delete: yalnız sahibi (telefonlu); alan kilidi; admin yalnız hidden', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'Review/carol_s1'), rev({ createdAt: Timestamp.now(), updatedAt: Timestamp.now() })); });
  const c = asPhone('carol');
  // mobil güncelleme payload'ı (tüm alanlar tekrar yazılır, createdAt/hidden yok)
  await assertSucceeds(updateDoc(doc(c, 'Review/carol_s1'), { showId: 's1', userId: 'carol', userName: 'Carol', userImage: '', rating: 3, text: 'idare eder', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { hidden: true }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { userId: 'bob' }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { showId: 's2' }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { rating: 9, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { text: 'x'.repeat(601), updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { text: 5, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { verified: true }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { createdAt: Timestamp.now() }));
  await assertFails(updateDoc(doc(c, 'Review/carol_s1'), { updatedAt: Timestamp.fromDate(new Date('2001-01-01')) }));
  // başkası
  await assertFails(updateDoc(doc(asPhone('mallory'), 'Review/carol_s1'), { rating: 1, updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(asPhone('mallory'), 'Review/carol_s1')));
  await assertFails(updateDoc(doc(asPhone('mallory'), 'Review/carol_s1'), { hidden: true }));
  // telefonu olmayan sahip güncelleyemez
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'Review/dave_s1'), rev({ userId: 'dave' })); });
  await assertFails(updateDoc(doc(as('dave'), 'Review/dave_s1'), { rating: 1, updatedAt: serverTimestamp() }));
  // admin: yalnız hidden
  const a = as('admin1');
  await assertSucceeds(updateDoc(doc(a, 'Review/carol_s1'), { hidden: true }));
  await assertFails(updateDoc(doc(a, 'Review/carol_s1'), { text: 'sansür', hidden: true }));
  await assertFails(updateDoc(doc(a, 'Review/carol_s1'), { hidden: 'evet' }));
  // sahibi siler
  await assertSucceeds(deleteDoc(doc(c, 'Review/carol_s1')));
});

test('(f) ReviewReport: id biçimi, alan listesi, boyut; yalnız admin okur; güncelleme/silme yok', async () => {
  const c = as('carol');
  await assertSucceeds(setDoc(doc(c, 'ReviewReport/alice_s1_carol'), { reviewId: 'alice_s1', userId: 'carol', createdAt: serverTimestamp() })); // mobil payload
  await assertFails(setDoc(doc(c, 'ReviewReport/alice_s1_carol'), { reviewId: 'alice_s1', userId: 'carol', createdAt: serverTimestamp() })); // tekrar = update
  await assertSucceeds(setDoc(doc(as('erin'), 'ReviewReport/alice_s1_erin'), { reviewId: 'alice_s1', userId: 'erin', createdAt: serverTimestamp(), reason: 'spam' }));
  const bad = (id, o) => assertFails(setDoc(doc(as('frank'), `ReviewReport/${id}`), { reviewId: 'alice_s1', userId: 'frank', createdAt: serverTimestamp(), ...o }), id);
  await bad('rastgele-1', {}); // kimlik biçimi
  await bad('alice_s1_carol2', {}); await bad('alice_s1_carol', { userId: 'carol' }); // başkasının adına
  await bad('alice_s1_frank', { reviewId: 'bob_s9' }); // olmayan yorum
  await bad('alice_s1_frank', { reason: 'x'.repeat(201) }); await bad('alice_s1_frank', { reason: 5 });
  await bad('alice_s1_frank', { extra: 1 }); await bad('alice_s1_frank', { createdAt: Timestamp.fromDate(new Date('2001-01-01')) });
  await assertFails(setDoc(doc(asAnonProvider('anon1'), 'ReviewReport/alice_s1_anon1'), { reviewId: 'alice_s1', userId: 'anon1', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(anon(), 'ReviewReport/alice_s1_x'), { reviewId: 'alice_s1', userId: 'x', createdAt: serverTimestamp() }));
  await assertFails(getDoc(doc(c, 'ReviewReport/alice_s1_carol')));
  await assertFails(getDocs(collection(c, 'ReviewReport')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'ReviewReport/alice_s1_carol')));
  await assertFails(updateDoc(doc(c, 'ReviewReport/alice_s1_carol'), { reason: 'x' }));
  await assertFails(deleteDoc(doc(c, 'ReviewReport/alice_s1_carol')));
});

test('(f) Notification: istemci create EDEMEZ (sahte/sınırsız); yalnız kendi isRead alanı güncellenir; başkasınınkini okuyamaz', async () => {
  const a = as('alice');
  await assertFails(setDoc(doc(a, 'Notification/yeni'), { userId: 'alice', title: 'Ödeme alındı', body: 'sahte', isRead: false }));
  await assertFails(setDoc(doc(a, 'Notification/yeni'), { userId: 'bob', title: 'x' }));
  for (let i = 0; i < 5; i++) await assertFails(setDoc(doc(a, `Notification/spam${i}`), { userId: 'alice', title: 'x'.repeat(100000) }));
  await assertSucceeds(updateDoc(doc(a, 'Notification/n1'), { isRead: true }));
  await assertFails(updateDoc(doc(a, 'Notification/n1'), { isRead: 'evet' }));
  await assertFails(updateDoc(doc(a, 'Notification/n1'), { title: 'değişti' }));
  await assertFails(updateDoc(doc(a, 'Notification/n1'), { userId: 'bob' }));
  await assertFails(updateDoc(doc(as('bob'), 'Notification/n1'), { isRead: true }));
  await assertFails(deleteDoc(doc(as('bob'), 'Notification/n1')));
  await assertFails(getDoc(doc(as('bob'), 'Notification/n1')));
  await assertSucceeds(getDocs(query(collection(a, 'Notification'), where('userId', '==', 'alice'))));
  await assertSucceeds(deleteDoc(doc(a, 'Notification/n1')));
});

// ------------------------------------------------------------------ (i) kural kalıntısı taraması
test('(i) kural dosyası taraması: `allow write/create/update/delete: if true` yok; `if true` yalnız bilinen herkese açık OKUMA yollarında', async () => {
  const lines = RULES.split('\n');
  const stripped = lines.map((l) => l.replace(/\/\/.*$/, ''));
  const text = stripped.join('\n');
  // 1) yazma izinlerinde sabit true
  const writeTrue = [...text.matchAll(/allow\s+([a-z, ]+):\s*if\s+true\s*;/g)].filter((m) => /create|update|delete|write/.test(m[1]));
  assert.equal(writeTrue.length, 0, 'sabit-true YAZMA izni bulundu');
  // 2) 'if true' okuma izinleri hangi match bloklarında
  const open = [];
  let cur = null;
  for (const l of stripped) {
    const m = /match\s+(\/[^\s{]+(?:\/\{[^}]+\})?)\s*\{/.exec(l);
    if (m) cur = m[1];
    if (/allow\s+(read|get|list)[^:]*:\s*if\s+true/.test(l)) open.push(cur);
  }
  assert.deepEqual(open.sort(), ['/AppTools/{docId}', '/Campaign/{campaignId}', '/Config/{docId}', '/Event/{eventId}', '/Player/{playerId}', '/Review/{reviewId}', '/Seats/{stageId}', '/Show/{showId}', '/Stage/{stageId}', '/Team/{teamId}']);
  // 3) son kural tümüyle kapalı wildcard
  assert.match(text, /match\s+\/\{document=\*\*\}\s*\{\s*allow\s+read,\s*write:\s*if\s+false;\s*\}/);
  // 4) wildcard/recursive allow'lar: yalnız Stats (okuma admin, yazma false) ve son deny
  const rec = [...text.matchAll(/match\s+([^\s{]*\{[a-zA-Z]+=\*\*\})/g)].map((m) => m[1]);
  assert.deepEqual(rec.sort(), ['/Stats/{document=**}', '/{document=**}']);
});

// ------------------------------------------------------------------ (j) sınırsız liste okuma
test('(j) KAYIT: herkese açık koleksiyonlar sorgu limiti olmadan listelenebilir (web tüm koleksiyonu okur; mobil isLimit=false kullanır) -> bilinen/kabul edilen risk', async () => {
  // Bu test mevcut davranışı BELGELER: limit zorunluluğu getirmek web (site/js/store.js) ve mobil sorguları kırar.
  for (const c of ['Show', 'Stage', 'Team', 'Player', 'Campaign', 'Event', 'Review']) await assertSucceeds(getDocs(collection(anon(), c)));
  await assertSucceeds(getDocs(query(collection(anon(), 'Show'), limit(20))));
  // Ama kişisel/yönetim koleksiyonları HİÇBİR sorguyla listelenemez:
  for (const c of ['User', 'Ticket', 'Order', 'UserLimits', 'AccountDeletion', 'Stats', 'System', 'NotificationLog', 'ReviewReport', 'Notification']) {
    await assertFails(getDocs(collection(as('alice'), c)), c);
    await assertFails(getDocs(query(collection(as('alice'), c), limit(1))), c);
  }
});

// ------------------------------------------------------------------ STORAGE
const SKIP_ST = !STORAGE_HOST && 'Storage emülatörü yok';
const PNG = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);
const meta = { contentType: 'image/jpeg' };
const st = (uid, claims) => (uid ? asUid(uid, claims).storage() : env.unauthenticatedContext().storage());

test('(storage) profil fotoğrafı: yalnız sahibi yazar; başkası/anonim/yanlış tür/büyük dosya reddedilir', { skip: SKIP_ST }, async () => {
  const mine = sref(st('alice'), 'ppics/alice.jpg');
  await assertSucceeds(uploadBytes(mine, PNG, meta));
  await assertSucceeds(getBytes(mine));
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/bob.jpg'), PNG, meta)); // başkasının dosyası
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/alice.jpg.exe'), PNG, meta));
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/alice10.jpg'), PNG, meta));
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/x/alice.jpg'), PNG, meta));
  await assertFails(uploadBytes(sref(st(null), 'ppics/alice.jpg'), PNG, meta)); // anonim
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/alice.jpg'), PNG, { contentType: 'text/html' }));
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/alice.jpg'), PNG, { contentType: 'image/svg+xml' }));
  await assertFails(uploadBytes(sref(st('alice'), 'ppics/alice.jpg'), new Uint8Array(5 * 1024 * 1024 + 1), meta)); // > 5MB
  await assertFails(deleteObject(sref(st('bob'), 'ppics/alice.jpg')));
  await assertFails(getBytes(sref(st(null), 'ppics/alice.jpg'))); // oturumsuz doğrudan okuma yok (token'lı URL ayrı)
  await assertFails(listAll(sref(st('alice'), 'ppics')));
  await assertSucceeds(deleteObject(mine));
});

test('(storage) yönetim görselleri: yalnız admin yazar; kullanıcı/anonim yazamaz; web images/ yolu; varsayılan kapalı', { skip: SKIP_ST }, async () => {
  const mkAdmin = async (uid, role) => env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), `User/${uid}`), { role }); });
  await mkAdmin('adm', 'admin'); await mkAdmin('usr', 'user'); await mkAdmin('capadm', 'Admin');
  for (const p of ['ShowImages/s1.jpg', 'PlayerImages/p1.jpg', 'StageImages/g1.jpg', 'TeamImages/t1.jpg', 'images/Show/123-a.png']) {
    await assertSucceeds(uploadBytes(sref(st('adm'), p), PNG, meta), p);
    await assertFails(uploadBytes(sref(st('usr'), p), PNG, meta), p);
    await assertFails(uploadBytes(sref(st('capadm'), p), PNG, meta), p);
    await assertFails(uploadBytes(sref(st('nodoc'), p), PNG, meta), p);
    await assertFails(uploadBytes(sref(st(null), p), PNG, meta), p);
    await assertFails(deleteObject(sref(st('usr'), p)), p);
    await assertSucceeds(getBytes(sref(st(null), p)), p); // herkese açık görsel
  }
  await assertFails(uploadBytes(sref(st('adm'), 'ShowImages/s1.jpg'), PNG, { contentType: 'text/html' }));
  await assertFails(uploadBytes(sref(st('adm'), 'ShowImages/s1.jpg'), new Uint8Array(10 * 1024 * 1024 + 1), meta));
  await assertFails(uploadBytes(sref(st('adm'), 'baska/dosya.jpg'), PNG, meta)); // tanımsız dizin = kapalı
  await assertFails(uploadBytes(sref(st('adm'), 'index.html'), PNG, { contentType: 'text/html' }));
  await assertFails(getBytes(sref(st('adm'), 'baska/dosya.jpg')));
  await assertFails(listAll(sref(st('adm'), 'ShowImages')));
  await assertSucceeds(deleteObject(sref(st('adm'), 'ShowImages/s1.jpg')));
});

// ------------------------------------------------------------------ FONKSİYONLAR (HTTP, functions emülatörü)
const FN = process.env.FUNCTIONS_EMULATOR_HOST;
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const PROJECT = 'ticketappflutter';
const SKIP_FN = !FN && 'Functions emülatörü yok';
const fnUrl = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
async function fnCall(name, data, token) {
  const r = await fetch(fnUrl(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
async function signUp(email) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }) });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
}
const adminDb = () => {
  const { initializeApp, getApps } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  process.env.GCLOUD_PROJECT = PROJECT;
  if (!getApps().length) initializeApp({ projectId: PROJECT });
  return getFirestore();
};

test('(g) OTOMATİK TARAMA: index.js içindeki TÜM admin* callable\'ları yetkisiz (anonim) -> UNAUTHENTICATED, admin olmayan -> PERMISSION_DENIED', { skip: SKIP_FN, timeout: 300000 }, async () => {
  const src = fs.readFileSync(path.join(ROOT, 'functions', 'index.js'), 'utf8');
  const names = [...src.matchAll(/^exports\.(admin\w+)\s*=/gm)].map((m) => m[1]);
  assert.ok(names.length >= 8, `admin* callable sayısı beklenenden az: ${names.join(',')}`);
  for (const must of ['adminSendNotification', 'adminSetTicketStatus', 'adminCheckIn', 'adminHealth', 'adminStats', 'adminProcessAccountDeletions', 'adminNotifyPreview', 'adminCancelled']) assert.ok(names.includes(must), `${must} taramada yok`);
  for (let i = 0; i < 40; i++) { try { const r = await fnCall('adminHealth', {}); if (r.status) break; } catch { /* henüz yok */ } await new Promise((r) => setTimeout(r, 1000)); }
  const db = adminDb();
  const user = await signUp('rt-user@example.com'); // User belgesi YOK
  const user2 = await signUp('rt-user2@example.com');
  await db.collection('User').doc(user2.uid).set({ role: 'user' });
  const cap = await signUp('rt-cap@example.com');
  await db.collection('User').doc(cap.uid).set({ role: 'Admin' }); // büyük harf = admin DEĞİL
  const cur = await signUp('rt-cur@example.com');
  await db.collection('User').doc(cur.uid).set({ role: 'curator' });
  const payload = { eventId: 'e', orderId: 'o', ticketId: 't', title: 'x', body: 'y', audience: 'all', status: 'cancelled' };
  for (const n of names) {
    const a = await fnCall(n, payload);
    assert.equal(a.status, 401, `${n} anonim`);
    assert.equal(a.body.error.status, 'UNAUTHENTICATED', n);
    for (const [label, u] of [['belgesiz', user], ['user', user2], ['Admin(büyük harf)', cap], ['curator', cur]]) {
      const r = await fnCall(n, payload, u.token);
      assert.equal(r.status, 403, `${n} ${label}: ${JSON.stringify(r.body)}`);
      assert.equal(r.body.error.status, 'PERMISSION_DENIED', `${n} ${label}`);
    }
  }
  // kullanıcı kendini admin yapmaya çalışıp (kural reddeder) sonra çağırırsa yine reddedilir: belge hiç değişmedi
  assert.equal((await db.collection('User').doc(user2.uid).get()).data().role, 'user');
});

test('(g) tüm kullanıcı callable\'ları anonim çağrıda UNAUTHENTICATED; hata gövdesi iç ayrıntı/iz sızdırmaz', { skip: SKIP_FN, timeout: 120000 }, async () => {
  const src = fs.readFileSync(path.join(ROOT, 'functions', 'index.js'), 'utf8');
  const names = [...src.matchAll(/^exports\.(\w+)\s*=\s*onCall\(/gm)].map((m) => m[1]);
  assert.ok(names.length >= 18, names.join(','));
  for (const n of names) {
    const r = await fnCall(n, { eventId: 'x', seatIds: ['A1'], orderId: 'x' });
    assert.equal(r.status, 401, n);
    assert.equal(r.body.error.status, 'UNAUTHENTICATED', n);
    const raw = JSON.stringify(r.body);
    assert.ok(!/stack|at \w+ \(|node_modules|firebase-admin|\/functions\//i.test(raw), `${n}: iç ayrıntı sızıyor: ${raw}`);
  }
  // girişli ama bozuk girdi -> güvenli hata
  const u = await signUp('rt-bad@example.com');
  for (const bad of [null, 5, 'x', [], { eventId: { $ne: 1 } }, { seatIds: 'A1' }, { orderId: ['a'] }]) {
    const r = await fnCall('releaseHold', bad, u.token);
    assert.ok(r.status >= 400 && r.status < 500, `${JSON.stringify(bad)} -> ${r.status}`);
    assert.ok(!/stack|node_modules|firebase-admin/i.test(JSON.stringify(r.body)));
  }
});

test('(h) trackView kötüye kullanımı: yöntem/origin/bot/boyut; X-Forwarded-For döndürerek sayaç şişirme IP\'den bağımsız tavana takılır', { skip: SKIP_FN, timeout: 120000 }, async () => {
  const db = adminDb();
  await db.collection('Show').doc('rt_show').set({ name: 'RT' });
  const url = fnUrl('trackView');
  const good = { Origin: 'https://tiyatrol.web.app', 'User-Agent': 'Mozilla/5.0 (X11) Safari/605', 'Content-Type': 'application/json' };
  const post = (h, body) => fetch(url, { method: 'POST', headers: { ...good, ...h }, body: typeof body === 'string' ? body : JSON.stringify(body) });
  for (let i = 0; i < 40; i++) { try { const r = await post({}, { k: 'show', id: 'yok' }); if (r.status) break; } catch { /* henüz yok */ } await new Promise((r) => setTimeout(r, 1000)); }
  assert.equal((await fetch(url, { method: 'GET', headers: good })).status, 405);
  assert.equal((await fetch(url, { method: 'PUT', headers: good, body: '{}' })).status, 405);
  assert.equal((await post({}, '{bozuk')).status, 400);
  assert.equal((await post({}, { k: 'show', id: 'x'.repeat(5000) })).status, 400);
  assert.equal((await post({}, { k: '__proto__', id: 'a' })).status, 400);
  assert.equal((await post({}, { k: 'User', id: 'alice' })).status, 400); // koleksiyon adı sızdırılamaz
  const total = async () => { const q = await db.collection('Stats').doc('views').collection('days').get(); let t = 0; q.forEach((d) => { t += d.data()['show_rt_show'] || 0; }); return t; };
  const before = await total();
  assert.equal((await post({ Origin: 'https://evil.example' }, { k: 'show', id: 'rt_show' })).status, 204); // origin sahte
  assert.equal((await post({ 'User-Agent': 'curl/8.0' }, { k: 'show', id: 'rt_show' })).status, 204); // bot
  await new Promise((r) => setTimeout(r, 500));
  assert.equal(await total(), before, 'sahte origin/bot sayaç artırdı');
  // IP döndürme saldırısı: her istek farklı X-Forwarded-For
  const N = 300;
  await Promise.all(Array.from({ length: N }, (_, i) => post({ 'X-Forwarded-For': `203.0.${Math.floor(i / 250)}.${i % 250 + 1}` }, { k: 'show', id: 'rt_show' })));
  await new Promise((r) => setTimeout(r, 1500));
  const added = (await total()) - before;
  assert.ok(added <= 120, `X-Forwarded-For döndürme ile ${added} sayım yazıldı (tavan 120/dk/hedef)`);
});

test('(h) trackView: Stats dışına yazamaz, yeni Show/Stage uydurulamaz', { skip: SKIP_FN }, async () => {
  const db = adminDb();
  const url = fnUrl('trackView');
  const hdr = { Origin: 'https://tiyatrol.web.app', 'User-Agent': 'Mozilla/5.0 Safari/605', 'Content-Type': 'application/json' };
  const r = await fetch(url, { method: 'POST', headers: hdr, body: JSON.stringify({ k: 'show', id: 'uydurma_oyun_1' }) });
  assert.equal(r.status, 204);
  await new Promise((x) => setTimeout(x, 500));
  assert.equal((await db.collection('Show').doc('uydurma_oyun_1').get()).exists, false);
  const s = await db.collection('Stats').doc('views').collection('days').get();
  s.forEach((d) => assert.equal(d.data()['show_uydurma_oyun_1'], undefined));
});

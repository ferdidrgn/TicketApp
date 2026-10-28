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
  const cfg = { projectId: 'ticketappflutter', firestore: { host: fsHost, port: Number(fsPort), rules: RULES } };
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

test('(f) Review (Q-1): istemci HİÇBİR yoldan yorum yazamaz/güncelleyemez/silemez (yazma yalnız sunucu callable) — telefonlu, admin, sahibi dahil', async () => {
  const c = asPhone('carol');
  // eski mobil payload'ı artık REDDEDİLİR (mobil submitReview callable'ına taşındı)
  await assertFails(setDoc(doc(c, 'Review/carol_s1'), rev()));
  await assertFails(setDoc(doc(c, 'Review/carol_s1'), { ...rev(), verified: true }));
  await assertFails(setDoc(doc(as('dave'), 'Review/dave_s1'), rev({ userId: 'dave' })));
  await assertFails(setDoc(doc(anon(), 'Review/x_s1'), rev({ userId: 'x' })));
  await assertFails(setDoc(doc(as('admin1'), 'Review/admin1_s1'), rev({ userId: 'admin1' })));
  // mevcut yoruma (alice_s1) sahibi, başkası, admin: güncelleme/silme yok
  const al = asPhone('alice');
  await assertFails(updateDoc(doc(al, 'Review/alice_s1'), { text: 'değişti', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(al, 'Review/alice_s1'), { rating: 1 }));
  await assertFails(updateDoc(doc(al, 'Review/alice_s1'), { hidden: false, verified: true }));
  await assertFails(deleteDoc(doc(al, 'Review/alice_s1')));
  await assertFails(updateDoc(doc(asPhone('mallory'), 'Review/alice_s1'), { hidden: true }));
  await assertFails(deleteDoc(doc(asPhone('mallory'), 'Review/alice_s1')));
  const a = as('admin1');
  await assertFails(updateDoc(doc(a, 'Review/alice_s1'), { hidden: true })); // admin da callable (adminModerate + ModerationLog) kullanır
  await assertFails(deleteDoc(doc(a, 'Review/alice_s1')));
});

test('(f) Review okuma: görünür yorum herkese; gizli yorum yalnız yazarına ve admine; sorgu hidden==false ile kısıtlanmalı', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'Review/bob_s1'), { showId: 's1', userId: 'bob', rating: 2, text: 'gizli', hidden: true, status: 'hidden', hiddenReason: 'moderator' });
  });
  await assertSucceeds(getDoc(doc(anon(), 'Review/alice_s1')));
  await assertFails(getDoc(doc(anon(), 'Review/bob_s1')));
  await assertFails(getDoc(doc(as('alice'), 'Review/bob_s1')));
  await assertSucceeds(getDoc(doc(as('bob'), 'Review/bob_s1'))); // yazar kendi gizli yorumunu görür
  await assertSucceeds(getDoc(doc(as('admin1'), 'Review/bob_s1')));
  await assertSucceeds(getDocs(query(collection(anon(), 'Review'), where('showId', '==', 's1'), where('hidden', '==', false))));
  await assertFails(getDocs(query(collection(anon(), 'Review'), where('showId', '==', 's1')))); // kısıtsız sorgu gizlileri de kapsar
  await assertFails(getDocs(query(collection(anon(), 'Review'), where('hidden', '==', true))));
  await assertSucceeds(getDocs(query(collection(as('bob'), 'Review'), where('userId', '==', 'bob'))));
  await assertSucceeds(getDocs(query(collection(as('admin1'), 'Review'), where('hidden', '==', true))));
});

test('(f) ReviewReport / ModerationLog / ReviewLimits: istemci yazamaz; ReviewReport ve ModerationLog yalnız admin okur', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'ReviewReport/alice_s1_carol'), { reviewId: 'alice_s1', userId: 'carol', counted: true });
    await setDoc(doc(d, 'ModerationLog/m1'), { by: 'admin1', action: 'hide', reviewId: 'alice_s1' });
    await setDoc(doc(d, 'ReviewLimits/carol'), { subHourCount: 1 });
  });
  const c = asPhone('carol'), ad = as('admin1'), al = as('alice'), an = anon();
  await assertFails(setDoc(doc(c, 'ReviewReport/alice_s1_erin'), { reviewId: 'alice_s1', userId: 'carol', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(ad, 'ReviewReport/alice_s1_admin1'), { reviewId: 'alice_s1', userId: 'admin1', createdAt: serverTimestamp() }));
  await assertFails(getDoc(doc(c, 'ReviewReport/alice_s1_carol')));
  await assertFails(getDocs(collection(c, 'ReviewReport')));
  await assertSucceeds(getDoc(doc(ad, 'ReviewReport/alice_s1_carol')));
  await assertFails(updateDoc(doc(c, 'ReviewReport/alice_s1_carol'), { reason: 'x' }));
  await assertFails(deleteDoc(doc(c, 'ReviewReport/alice_s1_carol')));
  for (const [id, who] of [['ModerationLog/m1', c], ['ModerationLog/m1', al], ['ModerationLog/m1', an]]) await assertFails(getDoc(doc(who, id)));
  await assertSucceeds(getDoc(doc(ad, 'ModerationLog/m1')));
  await assertFails(setDoc(doc(ad, 'ModerationLog/m2'), { by: 'admin1' }));
  await assertFails(updateDoc(doc(ad, 'ModerationLog/m1'), { reason: 'sil' }));
  await assertFails(deleteDoc(doc(ad, 'ModerationLog/m1')));
  await assertFails(setDoc(doc(c, 'ModerationLog/m3'), { by: 'carol' }));
  await assertFails(getDoc(doc(c, 'ReviewLimits/carol'))); await assertFails(setDoc(doc(c, 'ReviewLimits/carol'), { subHourCount: 0 }));
});

test('(f) User/{me}/blocks: yalnız kendi listesini okur/yazar; biçim ve sunucu zamanı zorunlu; başkasınınkine erişim yok', async () => {
  const a = asPhone('alice');
  await assertSucceeds(setDoc(doc(a, 'User/alice/blocks/bob'), { blockedAt: serverTimestamp() }));
  await assertSucceeds(getDoc(doc(a, 'User/alice/blocks/bob')));
  await assertSucceeds(getDocs(collection(a, 'User/alice/blocks')));
  await assertFails(setDoc(doc(a, 'User/alice/blocks/alice'), { blockedAt: serverTimestamp() })); // kendini engelleme
  await assertFails(setDoc(doc(a, 'User/alice/blocks/x1'), { blockedAt: serverTimestamp(), extra: 1 }));
  await assertFails(setDoc(doc(a, 'User/alice/blocks/x2'), { blockedAt: Timestamp.fromDate(new Date('2001-01-01')) }));
  await assertFails(setDoc(doc(a, 'User/alice/blocks/x3'), {}));
  await assertFails(updateDoc(doc(a, 'User/alice/blocks/bob'), { blockedAt: serverTimestamp() }));
  // başkası: okuyamaz/yazamaz/silemez; admin de okuyamaz
  await assertFails(getDoc(doc(as('bob'), 'User/alice/blocks/bob')));
  await assertFails(getDocs(collection(as('bob'), 'User/alice/blocks')));
  await assertFails(setDoc(doc(as('bob'), 'User/alice/blocks/zed'), { blockedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(as('bob'), 'User/alice/blocks/bob')));
  await assertFails(getDoc(doc(as('admin1'), 'User/alice/blocks/bob')));
  await assertFails(setDoc(doc(anon(), 'User/alice/blocks/zed'), { blockedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(asAnonProvider('anon1'), 'User/anon1/blocks/zed'), { blockedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(doc(a, 'User/alice/blocks/bob')));
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
    const m = /match\s+(\/\S+)\s*\{/.exec(l);
    if (m) cur = m[1];
    if (/allow\s+(read|get|list)[^:]*:\s*if\s+true/.test(l)) open.push(cur);
  }
  assert.deepEqual(open.sort(), ['/AppTools/{docId}', '/Campaign/{campaignId}', '/Config/{docId}', '/Event/{eventId}', '/Player/{playerId}', '/Seats/{stageId}', '/Show/{showId}', '/Stage/{stageId}', '/Team/{teamId}']);
  // 3) son kural tümüyle kapalı wildcard
  assert.match(text, /match\s+\/\{document=\*\*\}\s*\{\s*allow\s+read,\s*write:\s*if\s+false;\s*\}/);
  // 4) wildcard/recursive allow'lar: yalnız Stats (okuma admin, yazma false) ve son deny
  const rec = [...text.matchAll(/match\s+([^\s{]*\{[a-zA-Z]+=\*\*\})/g)].map((m) => m[1]);
  assert.deepEqual(rec.sort(), ['/Stats/{document=**}', '/{document=**}']);
});

// ------------------------------------------------------------------ (j) sınırsız liste okuma
test('(j) KAYIT: herkese açık koleksiyonlar sorgu limiti olmadan listelenebilir (web tüm koleksiyonu okur; mobil isLimit=false kullanır) -> bilinen/kabul edilen risk', async () => {
  // Bu test mevcut davranışı BELGELER: limit zorunluluğu getirmek web (site/js/store.js) ve mobil sorguları kırar.
  for (const c of ['Show', 'Stage', 'Team', 'Player', 'Campaign', 'Event']) await assertSucceeds(getDocs(collection(anon(), c)));
  // Review (Q-1): gizli yorumlar yüzünden artık YALNIZ `hidden==false` kısıtlı sorgu çalışır (site/js/store.js + mobil buna göre güncellendi).
  await assertSucceeds(getDocs(query(collection(anon(), 'Review'), where('hidden', '==', false))));
  await assertFails(getDocs(collection(anon(), 'Review')));
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

test('(g) tüm kullanıcı callable\'ları anonim çağrıda UNAUTHENTICATED; hata gövdesi iç ayrıntı/iz sızdırmaz', { skip: SKIP_FN, timeout: 280000 }, async () => {
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

test('(h) trackView kötüye kullanımı: yöntem/origin/bot/boyut; X-Forwarded-For döndürerek sayaç şişirme IP\'den bağımsız tavana takılır', { skip: SKIP_FN, timeout: 280000 }, async () => {
  const db = adminDb();
  await db.collection('Show').doc('rt_show').set({ name: 'RT' });
  const url = fnUrl('trackView');
  const good = { Origin: 'https://tiyatrol.web.app', 'User-Agent': 'Mozilla/5.0 (X11) Safari/605', 'Content-Type': 'application/json' };
  const post = (h, body) => fetch(url, { signal: AbortSignal.timeout(60000), method: 'POST', headers: { ...good, ...h }, body: typeof body === 'string' ? body : JSON.stringify(body) });
  for (let i = 0; i < 40; i++) { try { const r = await post({}, { k: 'show', id: 'yok' }); if (r.status) break; } catch { /* henüz yok */ } await new Promise((r) => setTimeout(r, 1000)); }
  console.log('h:warm'); assert.equal((await fetch(url, { signal: AbortSignal.timeout(30000), method: 'GET', headers: good })).status, 405); console.log('h:get');
  assert.equal((await fetch(url, { method: 'PUT', headers: good, body: '{}' })).status, 405);
  assert.equal((await post({}, '{bozuk')).status, 400);
  assert.equal((await post({}, { k: 'show', id: 'x'.repeat(5000) })).status, 400);
  assert.equal((await post({}, { k: '__proto__', id: 'a' })).status, 400);
  assert.equal((await post({}, { k: 'User', id: 'alice' })).status, 400); // koleksiyon adı sızdırılamaz
  const total = async () => { const q = await db.collection('Stats').doc('views').collection('days').get(); let t = 0; q.forEach((d) => { t += d.data()['show_rt_show'] || 0; }); return t; };
  console.log('h:pre'); const before = await total(); console.log('h:before', before);
  assert.equal((await post({ Origin: 'https://evil.example' }, { k: 'show', id: 'rt_show' })).status, 204); // origin sahte
  assert.equal((await post({ 'User-Agent': 'curl/8.0' }, { k: 'show', id: 'rt_show' })).status, 204); // bot
  await new Promise((r) => setTimeout(r, 500));
  assert.equal(await total(), before, 'sahte origin/bot sayaç artırdı');
  // IP döndürme saldırısı: her istek farklı X-Forwarded-For
  // aynı IP: hedef başına dakikada en çok 6 sayılır
  for (let i = 0; i < 20; i++) await post({ 'X-Forwarded-For': '198.51.100.7' }, { k: 'show', id: 'rt_show' });
  await new Promise((r) => setTimeout(r, 800));
  const same = (await total()) - before;
  console.log('h:sameIp', same);
  assert.ok(same <= 6, `aynı IP ile ${same} sayım yazıldı (tavan 6/dk)`);
  console.log('h:flood'); const N = 150;
  for (let i = 0; i < N; i++) await (async () => post({ 'X-Forwarded-For': `203.0.${Math.floor(i / 250)}.${i % 250 + 1}` }, { k: 'show', id: 'rt_show' }))();
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

'use strict';
const { test, before, after, beforeEach } = require('node:test');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } = require('firebase/firestore');

let env;
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'rules-test',
    firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8') },
  });
});
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/admin1'), { role: 'admin' });
    await setDoc(doc(d, 'User/alice'), { role: 'user' });
    await setDoc(doc(d, 'User/bob'), { role: 'user' });
    await setDoc(doc(d, 'Event/e1'), { price: '100', seats: { A1: { status: 'available' }, A2: { status: 'sold', orderId: 'o2' } } });
    await setDoc(doc(d, 'Ticket/t1'), { customerId: 'alice', eventId: 'e1', buySeats: ['A1'], orderPrice: '100.00', showName: 'x', showImageUrl: '', stageName: '', eventDate: '' });
    await setDoc(doc(d, 'Order/o1'), { userId: 'alice', eventId: 'e1', total: 100, status: 'held' });
    await setDoc(doc(d, 'UserLimits/alice'), { freeTickets: 3 });
    await setDoc(doc(d, 'Config/satis'), { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 });
    await setDoc(doc(d, 'System/expireHolds'), { lastRunAt: 1, expiredOrders: 0, releasedSeats: 0 });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

test('Event.seats: istemci (giriş yapmış, sahibi bile) yazamaz', async () => {
  const d = as('alice');
  await assertFails(updateDoc(doc(d, 'Event/e1'), { 'seats.A1.status': 'sold', 'seats.A1.customerId': 'alice' }));
  await assertFails(updateDoc(doc(d, 'Event/e1'), { 'seats.A2.customerId': 'alice' })); // başkasının koltuğunu çalma
  await assertFails(updateDoc(doc(d, 'Event/e1'), { price: '0' }));
  await assertFails(setDoc(doc(d, 'Event/e2'), { price: '0', seats: {} }));
  await assertFails(deleteDoc(doc(d, 'Event/e1')));
  await assertFails(updateDoc(doc(anon(), 'Event/e1'), { 'seats.A1.status': 'reserved' }));
});

test('Event: herkes okur, admin yazar', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'Event/e1')));
  await assertSucceeds(updateDoc(doc(as('admin1'), 'Event/e1'), { price: '120' }));
});

test('Ticket: istemci create/update/delete edemez (geçerli görünen bilet bile)', async () => {
  const d = as('alice');
  await assertFails(setDoc(doc(d, 'Ticket/yeni'), { customerId: 'alice', eventId: 'e1', buySeats: ['A2'], orderPrice: '0.00' }));
  await assertFails(setDoc(doc(d, 'Ticket/t2'), { customerId: 'alice', eventId: 'e1', buySeats: ['A1'] }));
  await assertFails(updateDoc(doc(d, 'Ticket/t1'), { orderPrice: '0.00' }));
  await assertFails(updateDoc(doc(d, 'Ticket/t1'), { showName: 'y' }));
  await assertFails(deleteDoc(doc(d, 'Ticket/t1')));
  await assertFails(setDoc(doc(as('admin1'), 'Ticket/adminyeni'), { customerId: 'alice' }));
});

test('Ticket: sahibi okur, başkası okuyamaz; admin arşiv alanlarını günceller ama fiyatı değil', async () => {
  await assertSucceeds(getDoc(doc(as('alice'), 'Ticket/t1')));
  await assertFails(getDoc(doc(as('bob'), 'Ticket/t1')));
  await assertFails(getDoc(doc(anon(), 'Ticket/t1')));
  await assertSucceeds(updateDoc(doc(as('admin1'), 'Ticket/t1'), { showName: 'Arşiv' }));
  await assertFails(updateDoc(doc(as('admin1'), 'Ticket/t1'), { orderPrice: '1.00' }));
  await assertFails(updateDoc(doc(as('admin1'), 'Ticket/t1'), { customerId: 'bob' }));
});

test('Order: yalnızca sahibi okur; hiç kimse (admin dahil) istemciden yazamaz', async () => {
  await assertSucceeds(getDoc(doc(as('alice'), 'Order/o1')));
  await assertFails(getDoc(doc(as('bob'), 'Order/o1')));
  await assertFails(getDoc(doc(anon(), 'Order/o1')));
  await assertFails(updateDoc(doc(as('alice'), 'Order/o1'), { status: 'paid' }));
  await assertFails(updateDoc(doc(as('alice'), 'Order/o1'), { total: 0 }));
  await assertFails(setDoc(doc(as('alice'), 'Order/o9'), { userId: 'alice', status: 'paid', total: 0 }));
  await assertFails(deleteDoc(doc(as('alice'), 'Order/o1')));
  await assertFails(updateDoc(doc(as('admin1'), 'Order/o1'), { status: 'paid' }));
  // başkasının siparişlerini sorgulama
  await assertFails(getDocs(query(collection(as('bob'), 'Order'), where('userId', '==', 'alice'))));
  await assertSucceeds(getDocs(query(collection(as('alice'), 'Order'), where('userId', '==', 'alice'))));
});

test('UserLimits: sahibi okur; kimse istemciden yazamaz (ücretsiz sayaç sıfırlanamaz)', async () => {
  await assertSucceeds(getDoc(doc(as('alice'), 'UserLimits/alice')));
  await assertFails(getDoc(doc(as('bob'), 'UserLimits/alice')));
  await assertFails(updateDoc(doc(as('alice'), 'UserLimits/alice'), { freeTickets: 0 }));
  await assertFails(setDoc(doc(as('bob'), 'UserLimits/bob'), { freeTickets: 0 }));
  await assertFails(deleteDoc(doc(as('alice'), 'UserLimits/alice')));
});

test('Diğer kurallar korunur: Show herkese açık okuma, yalnızca admin yazma; User role değişmez', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'Show/s1'), { name: 'x' }); });
  await assertSucceeds(getDoc(doc(anon(), 'Show/s1')));
  await assertFails(updateDoc(doc(as('alice'), 'Show/s1'), { name: 'y' }));
  await assertSucceeds(updateDoc(doc(as('admin1'), 'Show/s1'), { name: 'y' }));
  await assertFails(updateDoc(doc(as('alice'), 'User/alice'), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(as('alice'), 'User/alice'), { city: 'Ankara' }));
  await assertFails(getDoc(doc(as('bob'), 'User/alice')));
});

test('Config/satis: herkes okur; yalnızca admin yazar ve şema doğrulanır', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'Config/satis')));
  await assertSucceeds(getDoc(doc(as('alice'), 'Config/satis')));
  await assertFails(updateDoc(doc(as('alice'), 'Config/satis'), { mode: 'online' }));
  await assertFails(setDoc(doc(as('alice'), 'Config/satis'), { mode: 'online', rezervasyonLimit: 3, iptalSaat: 24 }));
  await assertFails(setDoc(doc(anon(), 'Config/satis'), { mode: 'online', rezervasyonLimit: 3, iptalSaat: 24 }));
  await assertFails(deleteDoc(doc(as('admin1'), 'Config/satis')));
  await assertSucceeds(setDoc(doc(as('admin1'), 'Config/satis'), { mode: 'online', rezervasyonLimit: 5, iptalSaat: 12 }));
  await assertSucceeds(setDoc(doc(as('admin1'), 'Config/satis'), { mode: 'kapali', rezervasyonLimit: 3, iptalSaat: 24 }));
  await assertFails(setDoc(doc(as('admin1'), 'Config/satis'), { mode: 'bedava', rezervasyonLimit: 3, iptalSaat: 24 }));
  await assertFails(setDoc(doc(as('admin1'), 'Config/satis'), { mode: 'online', rezervasyonLimit: '3', iptalSaat: 24 }));
  await assertFails(setDoc(doc(as('admin1'), 'Config/satis'), { mode: 'online', rezervasyonLimit: -1, iptalSaat: 24 }));
});

test('System: yalnızca admin okur; kimse istemciden yazamaz', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'System/expireHolds')));
  await assertFails(getDoc(doc(as('alice'), 'System/expireHolds')));
  await assertFails(getDoc(doc(anon(), 'System/expireHolds')));
  await assertFails(setDoc(doc(as('admin1'), 'System/expireHolds'), { lastRunAt: 2 }));
  await assertFails(setDoc(doc(as('alice'), 'System/expireHolds'), { lastRunAt: 2 }));
});

test('Ticket: admin durum/kullanım alanlarını istemciden değiştiremez (yalnızca callable)', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'Ticket/t1'), { paymentStatus: 'paid' }));
  await assertFails(updateDoc(doc(as('admin1'), 'Ticket/t1'), { usedAt: 1 }));
  await assertFails(updateDoc(doc(as('alice'), 'Ticket/t1'), { paymentStatus: 'cancelled' }));
  await assertSucceeds(getDoc(doc(as('admin1'), 'Ticket/t1')));
});

test('Stats ve NotificationLog: yalnızca admin okur; kimse (admin dahil) istemciden yazamaz', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'Stats/views/months/2026-10'), { total: 3, show_total: 3, show_s1: 3 });
    await setDoc(doc(d, 'Stats/views/days/2026-10-26'), { total: 3 });
    await setDoc(doc(d, 'NotificationLog/l1'), { sentBy: 'admin1', title: 'x', recipients: 2 });
  });
  for (const p of ['Stats/views/months/2026-10', 'Stats/views/days/2026-10-26', 'NotificationLog/l1']) {
    await assertSucceeds(getDoc(doc(as('admin1'), p)));
    await assertFails(getDoc(doc(as('alice'), p)));
    await assertFails(getDoc(doc(anon(), p)));
  }
  await assertFails(setDoc(doc(as('admin1'), 'Stats/views/months/2026-10'), { total: 999 }));
  await assertFails(updateDoc(doc(as('admin1'), 'Stats/views/days/2026-10-26'), { total: 999 }));
  await assertFails(setDoc(doc(as('alice'), 'Stats/views/days/2026-10-27'), { total: 1 }));
  await assertFails(setDoc(doc(anon(), 'Stats/views/days/2026-10-27'), { total: 1 }));
  await assertFails(setDoc(doc(as('admin1'), 'NotificationLog/l2'), { sentBy: 'admin1' }));
  await assertFails(deleteDoc(doc(as('admin1'), 'NotificationLog/l1')));
  await assertFails(getDocs(collection(as('alice'), 'NotificationLog')));
  await assertSucceeds(getDocs(collection(as('admin1'), 'NotificationLog')));
});

test('Config/bildirim: herkes okur; yalnızca admin yazar ve autoReminders mantıksal olmalı', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'Config/bildirim'), { autoReminders: false }));
  await assertSucceeds(getDoc(doc(as('alice'), 'Config/bildirim')));
  await assertFails(setDoc(doc(as('alice'), 'Config/bildirim'), { autoReminders: false }));
  await assertFails(setDoc(doc(as('admin1'), 'Config/bildirim'), { autoReminders: 'hayır' }));
  await assertFails(setDoc(doc(as('admin1'), 'Config/bildirim'), { baska: 1 }));
});

test('Notification: yönetici bile başkası adına uygulama içi bildirim yazamaz (duyuru yalnızca sunucudan)', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'Notification/n1'), { userId: 'alice', title: 'x', body: 'y', isRead: false }));
  await assertFails(setDoc(doc(as('bob'), 'Notification/n2'), { userId: 'alice', title: 'x', body: 'y', isRead: false }));
});

// ---- Telefon doğrulama alanları (docs/TELEFON-DOGRULAMA.md): isPhoneActive / phoneVerifiedAt / phoneKey / phoneNumber
const asPhone = (uid, phone) => env.authenticatedContext(uid, phone ? { phone_number: phone } : {}).firestore();

test('User create: isPhoneActive yalnızca false/null/yok; true, phoneVerifiedAt, phoneKey istemciden YAZILAMAZ', async () => {
  const n = (u) => doc(as(u), `User/${u}`);
  await assertSucceeds(setDoc(n('c1'), { role: 'user', firstName: 'A', isPhoneActive: false, phoneNumber: '', fcmToken: 'x', favorites: [] }));
  await assertSucceeds(setDoc(n('c2'), { firstName: 'A' })); // alan yok
  await assertSucceeds(setDoc(n('c3'), { firstName: 'A', isPhoneActive: null, phoneNumber: null }));
  await assertFails(setDoc(n('c4'), { firstName: 'A', isPhoneActive: true }));
  await assertFails(setDoc(n('c5'), { firstName: 'A', isPhoneActive: 'true' }));
  await assertFails(setDoc(n('c6'), { firstName: 'A', phoneVerifiedAt: 1 }));
  await assertFails(setDoc(n('c7'), { firstName: 'A', phoneKey: 'ph_x' }));
  await assertFails(setDoc(n('c8'), { role: 'admin', isPhoneActive: false }));
  await assertFails(setDoc(doc(as('c9'), 'User/baskasi'), { firstName: 'A' }));
});

test('User create: phoneNumber yalnızca boş ya da token\'daki phone_number ile birebir aynı olabilir', async () => {
  await assertFails(setDoc(doc(as('d1'), 'User/d1'), { phoneNumber: '+905551234567' })); // telefon doğrulanmamış
  await assertFails(setDoc(doc(asPhone('d2', '+905551234567'), 'User/d2'), { phoneNumber: '+905559999999' })); // başkasının/uydurma numara
  await assertSucceeds(setDoc(doc(asPhone('d3', '+905551234567'), 'User/d3'), { phoneNumber: '+905551234567', isPhoneActive: false }));
  await assertSucceeds(setDoc(doc(as('d4'), 'User/d4'), { phoneNumber: '' }));
});

test('User update: isPhoneActive true\'ya çekilemez; sunucunun yazdığı alanlar korunur; ad/fcmToken/favori güncellemesi serbest', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/p1'), { role: 'user', isPhoneActive: false, phoneNumber: '' });
    await setDoc(doc(d, 'User/p2'), { role: 'user', isPhoneActive: true, phoneNumber: '+905551234567', phoneKey: 'ph_abc', phoneVerifiedAt: 111 });
  });
  const p1 = as('p1'), p2 = as('p2');
  await assertFails(updateDoc(doc(p1, 'User/p1'), { isPhoneActive: true }));
  await assertFails(updateDoc(doc(p1, 'User/p1'), { phoneVerifiedAt: 5 }));
  await assertFails(updateDoc(doc(p1, 'User/p1'), { phoneKey: 'ph_x' }));
  await assertFails(updateDoc(doc(p1, 'User/p1'), { phoneNumber: '+905551234567' })); // token'da telefon yok
  await assertFails(updateDoc(doc(asPhone('p1', '+905551234567'), 'User/p1'), { phoneNumber: '+905550000000' })); // token ile uyuşmuyor
  await assertSucceeds(updateDoc(doc(asPhone('p1', '+905551234567'), 'User/p1'), { phoneNumber: '+905551234567' }));
  await assertSucceeds(updateDoc(doc(p1, 'User/p1'), { firstName: 'Ada', fcmToken: 't', favorites: ['s1'], isPhoneActive: false }));
  // doğrulanmış kullanıcı: tam-belge güncellemesi (aynı değerler) geçer; sunucu alanlarını bozamaz
  await assertSucceeds(updateDoc(doc(p2, 'User/p2'), { firstName: 'Ada', isPhoneActive: true, phoneNumber: '+905551234567', phoneKey: 'ph_abc', phoneVerifiedAt: 111 }));
  await assertFails(updateDoc(doc(p2, 'User/p2'), { phoneVerifiedAt: 999 }));
  await assertFails(updateDoc(doc(p2, 'User/p2'), { phoneKey: 'ph_zzz' }));
  await assertFails(updateDoc(doc(p2, 'User/p2'), { phoneNumber: '+905550000000' }));
  await assertSucceeds(updateDoc(doc(p2, 'User/p2'), { isPhoneActive: false })); // düşürmek zararsız; sunucu yeniden doğrular
  await assertFails(updateDoc(doc(p1, 'User/p1'), { role: 'admin' }));
});

// ---- GERÇEK istemci yük örnekleri (çapraz denetim): mobil UserModel.toFirestore + datasource, web kullaniciBelgesi, sunucu taslağı
const MOBIL_CREATE = (uid) => ({ // auth_mutation_provider._handlePostLogin: User.empty(uid).copyWith(...) -> UserModel.toFirestore()
  _createdAt: '', _updatedAt: '', _id: uid, firstName: 'Yeni', lastName: 'Kullanıcı', imageUrl: '', phoneNumber: '', eMail: 'a@b.co',
  city: '', isPhoneActive: false, fcmToken: 'tok', role: 'user', favoriteShows: [], favoriteStages: [], favoritePlayers: [], ticketsId: [],
});
const WEB_CREATE = (uid) => ({ // site/js/auth.js kullaniciBelgesiYaz
  _id: uid, _createdAt: 'x', _updatedAt: 'x', firstName: 'Ada', lastName: 'L', imageUrl: '', phoneNumber: '', eMail: 'a@b.co', city: '',
  isPhoneActive: false, fcmToken: '', role: 'user', favoriteShows: [], favoriteStages: [], favoritePlayers: [], ticketsId: [],
});
// sunucunun (syncPhoneVerification) yazdığı belge
const SUNUCU_BELGESI = (uid) => ({ ...WEB_CREATE(uid), phoneNumber: '+905551234567', isPhoneActive: true, phoneKey: 'ph_abc', phoneVerifiedAt: 111 });

test('gerçek istemci yükleri: mobil/web KAYIT (create) rules\'tan geçer, telefon alanı yazımı geçmez', async () => {
  await assertSucceeds(setDoc(doc(as('m1'), 'User/m1'), MOBIL_CREATE('m1')));
  await assertSucceeds(setDoc(doc(as('w1'), 'User/w1'), WEB_CREATE('w1'))); // Google (telefonsuz token)
  await assertSucceeds(setDoc(doc(asPhone('w2', '+905551234567'), 'User/w2'), WEB_CREATE('w2'))); // telefonla giriş, numara boş yazılır
  // eski/kötü istemci: kullanıcı yazısı numara ya da true
  await assertFails(setDoc(doc(as('m2'), 'User/m2'), { ...MOBIL_CREATE('m2'), phoneNumber: '+905551234567' }));
  await assertFails(setDoc(doc(as('m3'), 'User/m3'), { ...MOBIL_CREATE('m3'), isPhoneActive: true }));
  await assertFails(setDoc(doc(as('m4'), 'User/m4'), { ...MOBIL_CREATE('m4'), role: 'admin' }));
});

test('gerçek istemci yükleri: mobil GÜNCELLEME (isPhoneActive/phoneNumber çıkarılmış) sunucunun yazdığı belgede geçer; eski istemci (numara ezme) reddedilir', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'User/s1'), SUNUCU_BELGESI('s1')); });
  const d = doc(asPhone('s1', '+905551234567'), 'User/s1');
  const { phoneNumber, isPhoneActive, ...guncelleme } = { ...MOBIL_CREATE('s1'), fcmToken: 'yeni', firstName: 'Ada', _updatedAt: 'y' };
  await assertSucceeds(updateDoc(d, guncelleme));
  // telefon çıkarılmamış eski istemci: boş numara/false ile ezmeye çalışır
  await assertSucceeds(updateDoc(d, { phoneNumber: '' })); // boşaltmak zararsız; sunucu sonraki girişte yeniden yazar
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), 'User/s2'), SUNUCU_BELGESI('s2')); });
  await assertFails(updateDoc(doc(as('s2'), 'User/s2'), { phoneNumber: '+905550000000' })); // uydurma numara
  await assertFails(updateDoc(doc(as('s2'), 'User/s2'), { phoneKey: 'ph_baska', phoneVerifiedAt: 5 }));
});

test('sunucu taslağı (role:user, _id, listeler) mobil güncelleme yüküyle UYUMLU; role\'süz taslak mobil güncellemeyi KIRARDI (regresyon kanıtı)', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/t1'), SUNUCU_BELGESI('t1'));
    await setDoc(doc(d, 'User/t2'), { phoneNumber: '+905551234567', isPhoneActive: true, phoneKey: 'ph_abc', phoneVerifiedAt: 111 }); // eski (eksik) taslak
  });
  const { phoneNumber, isPhoneActive, ...upd } = MOBIL_CREATE('t1');
  await assertSucceeds(updateDoc(doc(asPhone('t1', '+905551234567'), 'User/t1'), upd));
  await assertFails(updateDoc(doc(asPhone('t2', '+905551234567'), 'User/t2'), { ...upd, _id: 't2' })); // role null -> 'user' reddedilir
});

// ------------------------------------------------------------------ hesap silme (docs/HESAP-SILME.md)
test('hesap silme: istemci User.deletion* alanlarını YAZAMAZ (create/update), kendi alanlarını OKUR; User belgesini SİLEMEZ', async () => {
  const ts = (n) => new Date(n);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/p1'), { role: 'user', firstName: 'A', deletionStatus: 'pending', deletionScheduledAt: ts(1000), deletionRequestedAt: ts(500) });
    await setDoc(doc(d, 'User/p2'), { role: 'user', firstName: 'B' });
    await setDoc(doc(d, 'AccountDeletion/p1'), { uid: 'p1', status: 'pending' });
  });
  const own = await assertSucceeds(getDoc(doc(as('p1'), 'User/p1')));
  if (own.data().deletionStatus !== 'pending') throw new Error('kendi deletion alanı okunamadı');
  await assertFails(getDoc(doc(as('p2'), 'User/p1')));
  await assertFails(updateDoc(doc(as('p2'), 'User/p2'), { deletionStatus: 'pending' }));
  await assertFails(updateDoc(doc(as('p2'), 'User/p2'), { deletionScheduledAt: ts(9) }));
  await assertFails(updateDoc(doc(as('p1'), 'User/p1'), { deletionStatus: 'active' }));
  await assertFails(updateDoc(doc(as('p1'), 'User/p1'), { deletionScheduledAt: ts(999999999) }));
  await assertFails(updateDoc(doc(as('p1'), 'User/p1'), { deletionRequestedAt: ts(1) }));
  await assertFails(setDoc(doc(as('newu'), 'User/newu'), { role: 'user', deletionStatus: 'pending' }));
  await assertSucceeds(updateDoc(doc(as('p1'), 'User/p1'), { fcmToken: 'x' })); // bekleme sürecinde diğer alanlar güncellenebilir
  await assertFails(deleteDoc(doc(as('p2'), 'User/p2'))); // User silme istemciden kapalı (sunucu akışı zorunlu)
  await assertFails(getDoc(doc(as('p1'), 'AccountDeletion/p1')));
  await assertFails(setDoc(doc(as('p1'), 'AccountDeletion/p1'), { status: 'cancelled' }));
  await assertFails(deleteDoc(doc(as('p1'), 'AccountDeletion/p1')));
  await assertFails(setDoc(doc(as('admin1'), 'AccountDeletion/p1'), { status: 'pending' }));
  await assertSucceeds(getDoc(doc(as('admin1'), 'AccountDeletion/p1')));
});

test('hesap silme mezar taşı: deleting/deleted uid eski token ile User yazamaz/yeniden oluşturamaz; pending engellemez', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/z1'), { role: 'user' });
    await setDoc(doc(d, 'AccountDeletion/z1'), { uid: 'z1', status: 'deleting' });
    await setDoc(doc(d, 'AccountDeletion/z2'), { uid: 'z2', status: 'deleted' });
    await setDoc(doc(d, 'AccountDeletion/z3'), { uid: 'z3', status: 'pending' });
    await setDoc(doc(d, 'User/z3'), { role: 'user', deletionStatus: 'pending' });
  });
  await assertFails(updateDoc(doc(as('z1'), 'User/z1'), { fcmToken: 'x' }));
  await assertFails(setDoc(doc(as('z2'), 'User/z2'), { role: 'user' }));
  await assertSucceeds(updateDoc(doc(as('z3'), 'User/z3'), { fcmToken: 'x' }));
});

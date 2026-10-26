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

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
    await setDoc(doc(d, 'Event/e1'), { price: '100', seats: { A1: { status: 'available', customerId: null }, A2: { status: 'sold', customerId: 'bob' } } });
    await setDoc(doc(d, 'Ticket/t1'), { customerId: 'alice', eventId: 'e1', buySeats: ['A1'], orderPrice: '100.00', showName: 'x', showImageUrl: '', stageName: '', eventDate: '' });
    await setDoc(doc(d, 'Order/o1'), { userId: 'alice', eventId: 'e1', total: 100, status: 'held' });
    await setDoc(doc(d, 'UserLimits/alice'), { freeTickets: 3 });
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

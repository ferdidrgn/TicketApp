'use strict';
// İKİ KULLANICILI SIZINTI DENETİMİ: A kullanıcısı B'nin verisini OKUYAMAZ / YAZAMAZ / LİSTELEYEMEZ (sorgu `where` ile de).
// Admin hariç. Kural dosyası: ../../firestore.rules (gerçek emülatör).
const { test, before, after, beforeEach } = require('node:test');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs, limit } = require('firebase/firestore');

let env;
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'leak-test',
    firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8') },
  });
});
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/admin1'), { role: 'admin', eMail: 'admin@x.com' });
    await setDoc(doc(d, 'User/alice'), { role: 'user', eMail: 'alice@x.com', phoneNumber: '+905550000001', firstName: 'Alice' });
    await setDoc(doc(d, 'User/bob'), { role: 'user', eMail: 'bob@x.com', phoneNumber: '+905550000002', firstName: 'Bob' });
    await setDoc(doc(d, 'Ticket/tb'), { customerId: 'bob', eventId: 'e1', buySeats: ['A1'], orderPrice: '100.00' });
    await setDoc(doc(d, 'Ticket/ta'), { customerId: 'alice', eventId: 'e1', buySeats: ['A2'], orderPrice: '100.00' });
    await setDoc(doc(d, 'Order/ob'), { userId: 'bob', eventId: 'e1', status: 'paying', seatIds: ['A1'], providerToken: 'tok-secret', paymentSession: { token: 'tok-secret' } });
    await setDoc(doc(d, 'Order/oa'), { userId: 'alice', eventId: 'e1', status: 'held', seatIds: ['A2'] });
    await setDoc(doc(d, 'Notification/nb'), { userId: 'bob', title: 'x', isRead: false });
    await setDoc(doc(d, 'Notification/na'), { userId: 'alice', title: 'y', isRead: false });
    await setDoc(doc(d, 'UserLimits/bob'), { freeTickets: 1 });
    await setDoc(doc(d, 'UserLimits/alice'), { freeTickets: 0 });
    await setDoc(doc(d, 'ReviewReport/rb'), { userId: 'bob', reviewId: 'x' });
    await setDoc(doc(d, 'Review/bob_s1'), { userId: 'bob', showId: 's1', rating: 5, text: 'iyi', hidden: false, userName: 'Bob K.' });
    await setDoc(doc(d, 'Event/e1'), { price: '100', seats: { A1: { status: 'sold', orderId: 'ob' }, A2: { status: 'available' } } });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const COLS_PRIVATE = [['User', 'bob', null], ['Ticket', 'tb', 'customerId'], ['Order', 'ob', 'userId'], ['Notification', 'nb', 'userId'], ['UserLimits', 'bob', null]];

test('A, B\'nin User / Ticket / Order / Notification / UserLimits belgelerini OKUYAMAZ', async () => {
  for (const [col, id] of COLS_PRIVATE) {
    await assertFails(getDoc(doc(as('alice'), `${col}/${id}`)));
    await assertFails(getDoc(doc(anon(), `${col}/${id}`)));
  }
});

test('A, B\'nin belgelerini YAZAMAZ / GÜNCELLEYEMEZ / SİLEMEZ', async () => {
  const a = as('alice');
  await assertFails(setDoc(doc(a, 'User/bob'), { role: 'user', eMail: 'hack@x.com' }));
  await assertFails(updateDoc(doc(a, 'User/bob'), { city: 'X' }));
  await assertFails(deleteDoc(doc(a, 'User/bob')));
  await assertFails(updateDoc(doc(a, 'Ticket/tb'), { showName: 'x' }));
  await assertFails(setDoc(doc(a, 'Ticket/tx'), { customerId: 'bob', eventId: 'e1' }));
  await assertFails(deleteDoc(doc(a, 'Ticket/tb')));
  await assertFails(updateDoc(doc(a, 'Order/ob'), { status: 'paid' }));
  await assertFails(deleteDoc(doc(a, 'Order/ob')));
  await assertFails(updateDoc(doc(a, 'Notification/nb'), { isRead: true }));
  await assertFails(deleteDoc(doc(a, 'Notification/nb')));
  await assertFails(setDoc(doc(a, 'Notification/nx'), { userId: 'bob', title: 'sahte' })); // B adına bildirim
  await assertFails(setDoc(doc(a, 'UserLimits/bob'), { freeTickets: 0 }));
  await assertFails(updateDoc(doc(a, 'UserLimits/bob'), { freeTickets: 0 }));
  await assertFails(setDoc(doc(a, 'UserLimits/alice'), { freeTickets: 0 })); // kendi sayacını da yazamaz
});

test('A, B\'nin belgelerini LİSTELEYEMEZ: where(B), where(A)+kapsamsız, limit, sınırsız koleksiyon sorguları', async () => {
  const a = as('alice');
  const sorgular = [
    query(collection(a, 'Ticket'), where('customerId', '==', 'bob')),
    query(collection(a, 'Ticket')),
    query(collection(a, 'Ticket'), where('eventId', '==', 'e1')), // etkinlik bazlı: B'ninkiler dahil -> reddedilmeli
    query(collection(a, 'Order'), where('userId', '==', 'bob')),
    query(collection(a, 'Order'), where('eventId', '==', 'e1')),
    query(collection(a, 'Order'), where('providerToken', '==', 'tok-secret')),
    query(collection(a, 'Order'), where('status', '==', 'paying')),
    query(collection(a, 'Order'), limit(5)),
    query(collection(a, 'Notification'), where('userId', '==', 'bob')),
    query(collection(a, 'Notification')),
    query(collection(a, 'User')),
    query(collection(a, 'User'), where('eMail', '==', 'bob@x.com')),
    query(collection(a, 'User'), where('phoneNumber', '==', '+905550000002')),
    query(collection(a, 'UserLimits')),
    query(collection(a, 'ReviewReport')),
  ];
  for (const q of sorgular) await assertFails(getDocs(q));
  // kendi verisini kendi filtresiyle listeleyebilir (meşru kullanım)
  await assertSucceeds(getDocs(query(collection(a, 'Ticket'), where('customerId', '==', 'alice'))));
  await assertSucceeds(getDocs(query(collection(a, 'Order'), where('userId', '==', 'alice'))));
  await assertSucceeds(getDocs(query(collection(a, 'Order'), where('userId', '==', 'alice'), where('eventId', '==', 'e1'))));
  await assertSucceeds(getDocs(query(collection(a, 'Notification'), where('userId', '==', 'alice'))));
});

test('Eşleşen kümede B belgesi geçerse sorgu reddedilir (A\'nın filtresi B\'yi kapsıyorsa)', async () => {
  // userId != 'alice' ya da 'in' ile B'yi içeren sorgular
  const a = as('alice');
  await assertFails(getDocs(query(collection(a, 'Order'), where('userId', 'in', ['alice', 'bob']))));
  await assertFails(getDocs(query(collection(a, 'Ticket'), where('customerId', 'in', ['alice', 'bob']))));
  await assertFails(getDocs(query(collection(a, 'Order'), where('userId', '!=', 'alice'))));
});

test('Admin dışında kimse başkasının verisine erişemez; admin biletleri okur ama sipariş/limit/bildirim/kullanıcı okuyamaz-yazamaz', async () => {
  const ad = as('admin1');
  await assertSucceeds(getDoc(doc(ad, 'Ticket/tb')));
  await assertSucceeds(getDocs(query(collection(ad, 'Ticket'), where('eventId', '==', 'e1'))));
  await assertSucceeds(getDocs(query(collection(ad, 'ReviewReport'))));
  await assertFails(updateDoc(doc(ad, 'Order/ob'), { status: 'paid' }));
  await assertFails(updateDoc(doc(ad, 'UserLimits/bob'), { freeTickets: 0 }));
  await assertFails(updateDoc(doc(ad, 'Ticket/tb'), { customerId: 'admin1' }));
});

test('Event.seats herkese açık okunur ama kullanıcı kimliği içermez; koltuk haritası istemciden yazılamaz', async () => {
  const snap = await assertSucceeds(getDoc(doc(anon(), 'Event/e1')));
  const raw = JSON.stringify(snap.data());
  for (const s of ['bob', 'alice', 'customerId', '@']) if (raw.includes(s)) throw new Error(`Event içinde ${s} var`);
  await assertFails(updateDoc(doc(as('alice'), 'Event/e1'), { 'seats.A2.status': 'sold' }));
});

test('YETKİ YÜKSELTME: kullanıcı User belgesini role:admin ile OLUŞTURAMAZ (create), role güncelleyemez; silip yeniden oluşturma da engellenir', async () => {
  const c = env.authenticatedContext('carol').firestore();
  await assertFails(setDoc(doc(c, 'User/carol'), { role: 'admin', eMail: 'c@x.com' }));
  await assertFails(setDoc(doc(c, 'User/carol'), { role: 'curator' }));
  await assertSucceeds(setDoc(doc(c, 'User/carol'), { role: 'user', eMail: 'c@x.com' }));
  await assertFails(updateDoc(doc(c, 'User/carol'), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(c, 'User/carol'), { city: 'İzmir' }));
  await assertSucceeds(deleteDoc(doc(c, 'User/carol')));
  await assertFails(setDoc(doc(c, 'User/carol'), { role: 'admin' }));
  // alanı hiç yazmayan yeni kullanıcı (role yok) geçerli kalır; admin olamaz
  await assertSucceeds(setDoc(doc(c, 'User/carol'), { eMail: 'c@x.com' }));
  await assertFails(updateDoc(doc(c, 'User/carol'), { role: 'admin' }));
  // başkası adına belge oluşturma
  await assertFails(setDoc(doc(c, 'User/dave'), { role: 'user' }));
});

test('Review: kullanıcı adı/foto KAMUYA AÇIK (bilinçli ürün kararı) ama başkası yorumu yazamaz/silemez', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'Review/bob_s1')));
  await assertFails(updateDoc(doc(as('alice'), 'Review/bob_s1'), { text: 'hack' }));
  await assertFails(deleteDoc(doc(as('alice'), 'Review/bob_s1')));
  await assertFails(setDoc(doc(as('alice'), 'Review/bob_s2'), { userId: 'bob', showId: 's2', rating: 5, text: 'x', hidden: false }));
  await assertFails(getDoc(doc(as('alice'), 'ReviewReport/rb')));
});

test('Tanımsız koleksiyonlar kapalı (deny-by-default)', async () => {
  await assertFails(getDoc(doc(as('alice'), 'Gizli/x')));
  await assertFails(setDoc(doc(as('alice'), 'Gizli/x'), { a: 1 }));
});

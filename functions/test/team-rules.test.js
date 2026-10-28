'use strict';
// EKİP YÖNETİCİSİ kuralları (docs/EKIP-YONETICISI.md): TeamManager yetki belgesi istemciden yazılamaz; rol ek yetki vermez.
const { test, before, after, beforeEach } = require('node:test');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } = require('firebase/firestore');

let env;
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'team-rules-test',
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
    await setDoc(doc(d, 'User/mgr1'), { role: 'user' });
    await setDoc(doc(d, 'Team/tA'), { name: 'Ekip A' });
    await setDoc(doc(d, 'Show/sA'), { name: 'Oyun A', teamId: 'tA', eventsId: ['e1'] });
    await setDoc(doc(d, 'Event/e1'), { showId: 'sA', price: '100', seats: { A1: { status: 'available' } } });
    await setDoc(doc(d, 'Ticket/t1'), { customerId: 'alice', eventId: 'e1', buySeats: ['A1'], orderPrice: '100.00', showName: 'x', showImageUrl: '', stageName: '', eventDate: '' });
    await setDoc(doc(d, 'Order/o1'), { userId: 'alice', eventId: 'e1', total: 100, status: 'held' });
    await setDoc(doc(d, 'TeamManager/tA_mgr1'), { teamId: 'tA', uid: 'mgr1', status: 'active', addedBy: 'admin1' });
    await setDoc(doc(d, 'TeamManager/tA_bob'), { teamId: 'tA', uid: 'bob', status: 'active', addedBy: 'admin1' });
    await setDoc(doc(d, 'TeamManagerLog/l1'), { action: 'add', teamId: 'tA', targetUid: 'mgr1', by: 'admin1' });
    await setDoc(doc(d, 'TeamLimits/mgr1'), { hourCount: 1 });
    await setDoc(doc(d, 'NotificationLog/n1'), { sentBy: 'admin1' });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

test('TeamManager: istemci (yönetici ve admin dahil) yazamaz/silemez', async () => {
  const m = as('mgr1');
  await assertFails(updateDoc(doc(m, 'TeamManager/tA_mgr1'), { status: 'active', teamId: 'tB' }));
  await assertFails(setDoc(doc(m, 'TeamManager/tB_mgr1'), { teamId: 'tB', uid: 'mgr1', status: 'active', addedBy: 'mgr1' }));
  await assertFails(setDoc(doc(as('alice'), 'TeamManager/tA_alice'), { teamId: 'tA', uid: 'alice', status: 'active', addedBy: 'alice' }));
  await assertFails(deleteDoc(doc(m, 'TeamManager/tA_mgr1')));
  await assertFails(setDoc(doc(as('admin1'), 'TeamManager/tA_x'), { teamId: 'tA', uid: 'x', status: 'active' })); // admin de callable üzerinden atar
  await assertFails(updateDoc(doc(as('admin1'), 'TeamManager/tA_mgr1'), { status: 'revoked' }));
});

test('TeamManager okuma: admin hepsini, yönetici yalnız kendi kaydını; günlük/limit belgeleri kapalı', async () => {
  const m = as('mgr1');
  await assertSucceeds(getDoc(doc(m, 'TeamManager/tA_mgr1')));
  await assertFails(getDoc(doc(m, 'TeamManager/tA_bob')));
  await assertSucceeds(getDocs(query(collection(m, 'TeamManager'), where('uid', '==', 'mgr1'))));
  await assertFails(getDocs(collection(m, 'TeamManager')));
  await assertFails(getDocs(query(collection(m, 'TeamManager'), where('teamId', '==', 'tA'))));
  await assertFails(getDoc(doc(anon(), 'TeamManager/tA_mgr1')));
  await assertFails(getDoc(doc(as('alice'), 'TeamManager/tA_mgr1')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'TeamManager/tA_bob')));
  await assertFails(getDoc(doc(m, 'TeamManagerLog/l1')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'TeamManagerLog/l1')));
  await assertFails(setDoc(doc(as('admin1'), 'TeamManagerLog/l2'), { action: 'x' }));
  await assertFails(getDoc(doc(m, 'TeamLimits/mgr1')));
  await assertFails(setDoc(doc(m, 'TeamLimits/mgr1'), { hourCount: 0 }));
  await assertFails(getDoc(doc(as('admin1'), 'TeamLimits/mgr1')));
});

test('ekip yöneticisi rolü ek yetki vermez: Ticket/Event/Show/Team/Order/NotificationLog/User.role yazılamaz; başkasının bileti okunamaz', async () => {
  const m = as('mgr1');
  await assertFails(getDoc(doc(m, 'Ticket/t1')));
  await assertFails(getDocs(query(collection(m, 'Ticket'), where('eventId', '==', 'e1'))));
  await assertFails(updateDoc(doc(m, 'Ticket/t1'), { showName: 'x' }));
  await assertFails(updateDoc(doc(m, 'Ticket/t1'), { usedAt: new Date() }));
  await assertFails(setDoc(doc(m, 'Ticket/yeni'), { customerId: 'mgr1', eventId: 'e1' }));
  await assertFails(deleteDoc(doc(m, 'Ticket/t1')));
  await assertFails(updateDoc(doc(m, 'Event/e1'), { price: '1' }));
  await assertFails(updateDoc(doc(m, 'Event/e1'), { 'seats.A1.status': 'sold' }));
  await assertFails(updateDoc(doc(m, 'Show/sA'), { name: 'Hack' }));
  await assertFails(updateDoc(doc(m, 'Show/sA'), { teamId: 'tB' }));
  await assertFails(updateDoc(doc(m, 'Team/tA'), { name: 'Hack' }));
  await assertFails(getDoc(doc(m, 'Order/o1')));
  await assertFails(getDoc(doc(m, 'NotificationLog/n1')));
  await assertFails(updateDoc(doc(m, 'User/mgr1'), { role: 'admin' }));
  await assertFails(setDoc(doc(m, 'User/mgr1'), { role: 'admin' }));
});

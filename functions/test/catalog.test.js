'use strict';
// Show/Stage/Event silme — yalnız admin, yalnız biletsiz kayıt (09.11.2026 güvenlik denetimi:
// firestore.rules'da bu üç koleksiyonun delete'i artık `false`; tek silme yolu bu callable'lar).
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, clearDb, makeAdmin, expectCode, uidN } = H;
const { seedTicket } = require('./notify-helpers');
const { createCatalog } = require('../src/catalog');

beforeEach(async () => { await clearDb(); });

function makeCatalog() {
  const deleted = [];
  const storage = { bucket: () => ({ file: (path) => ({ delete: async () => { deleted.push(path); } }) }) };
  return { c: createCatalog({ db, storage }), deleted };
}

async function normalUser() {
  const uid = uidN();
  await db.collection('User').doc(uid).set({ role: 'user' });
  return uid;
}

test('adminDeleteShow: admin olmayan reddedilir; olmayan kayıt NOT_FOUND; bilet varsa FAILED_PRECONDITION', async () => {
  const { c } = makeCatalog();
  const admin = await makeAdmin();
  const usr = await normalUser();
  await db.collection('Show').doc('s1').set({ name: 'Hamlet' });

  await expectCode(c.adminDeleteShow(usr, { showId: 's1' }), 'permission-denied');
  assert.ok((await db.collection('Show').doc('s1').get()).exists, 'yetkisiz denemeden sonra hâlâ var olmalı');

  await expectCode(c.adminDeleteShow(admin, { showId: 'yok' }), 'not-found');

  await seedTicket({ customerId: 'u1', eventId: 'e1', showId: 's1' });
  await expectCode(c.adminDeleteShow(admin, { showId: 's1' }), 'failed-precondition');
  assert.ok((await db.collection('Show').doc('s1').get()).exists, 'biletli oyun silinmemeli');
});

test('adminDeleteShow: biletsiz oyunu admin siler, görseli de sunucuda siler', async () => {
  const { c, deleted } = makeCatalog();
  const admin = await makeAdmin();
  await db.collection('Show').doc('s2').set({ name: 'Macbeth' });

  const r = await c.adminDeleteShow(admin, { showId: 's2' });
  assert.deepEqual(r, { ok: true });
  assert.equal((await db.collection('Show').doc('s2').get()).exists, false);
  assert.deepEqual(deleted, ['ShowImages/s2.jpg']);
});

test('adminDeleteStage: aynı kurallar — admin yetkisi, bilet kontrolü, görsel temizliği', async () => {
  const { c, deleted } = makeCatalog();
  const admin = await makeAdmin();
  const usr = await normalUser();
  await db.collection('Stage').doc('st1').set({ name: 'Kadıköy Sahnesi' });

  await expectCode(c.adminDeleteStage(usr, { stageId: 'st1' }), 'permission-denied');

  await db.collection('Ticket').doc('t1').set({ customerId: 'u1', stageId: 'st1', eventId: 'e1', showId: 's1' });
  await expectCode(c.adminDeleteStage(admin, { stageId: 'st1' }), 'failed-precondition');

  await db.collection('Ticket').doc('t1').delete();
  const r = await c.adminDeleteStage(admin, { stageId: 'st1' });
  assert.deepEqual(r, { ok: true });
  assert.equal((await db.collection('Stage').doc('st1').get()).exists, false);
  assert.deepEqual(deleted, ['StageImages/st1.jpg']);
});

test('adminDeleteEvent: aynı kurallar, görsel silme yok (Event\'in görseli yok)', async () => {
  const { c, deleted } = makeCatalog();
  const admin = await makeAdmin();
  const usr = await normalUser();
  await db.collection('Event').doc('e2').set({ showId: 's1', stageId: 'st1', date: '15.12.2026,20:00' });

  await expectCode(c.adminDeleteEvent(usr, { eventId: 'e2' }), 'permission-denied');

  await seedTicket({ customerId: 'u1', eventId: 'e2', showId: 's1' });
  await expectCode(c.adminDeleteEvent(admin, { eventId: 'e2' }), 'failed-precondition');

  await db.collection('Ticket').get().then((s) => Promise.all(s.docs.map((d) => d.ref.delete())));
  const r = await c.adminDeleteEvent(admin, { eventId: 'e2' });
  assert.deepEqual(r, { ok: true });
  assert.equal((await db.collection('Event').doc('e2').get()).exists, false);
  assert.deepEqual(deleted, []);
});

test('bilet iptal edilmiş olsa bile sayılır (güvenli taraf — iptal edilmiş biletler de tarihçe için korunur)', async () => {
  const { c } = makeCatalog();
  const admin = await makeAdmin();
  await db.collection('Show').doc('s3').set({ name: 'İptal Testi' });
  await seedTicket({ customerId: 'u1', eventId: 'e1', showId: 's3', paymentStatus: 'cancelled' });
  await expectCode(c.adminDeleteShow(admin, { showId: 's3' }), 'failed-precondition');
});

test('adminUpsertSeatPlan: canonical metadata, server timestamps ve random-ID migration', async () => {
  const { c } = makeCatalog();
  const admin = await makeAdmin();
  await db.collection('Stage').doc('st1').set({ name: 'Sahne Bir', address: 'Kadıköy' });
  await db.collection('Seats').doc('randomLegacy').set({
    stageId: 'st1', seatsId: ['A1'], closedSeatsId: [], _createdAt: '2026-01-01T00:00:00.000Z',
  });

  const result = await c.adminUpsertSeatPlan(admin, {
    stageId: 'st1', seatIds: ['A1', 'A2'], closedSeatIds: ['A2'], updateStageCapacity: true,
  });
  assert.deepEqual(result, { stageId: 'st1', seatCount: 2, migrated: true });
  const canonical = (await db.collection('Seats').doc('st1').get()).data();
  assert.equal(canonical.stageId, 'st1');
  assert.deepEqual(canonical.seatIds, ['A1', 'A2']);
  assert.deepEqual(canonical.closedSeatIds, ['A2']);
  assert.equal(canonical.schemaVersion, 2);
  assert.equal(typeof canonical.createdAt.toMillis, 'function');
  assert.equal(typeof canonical.updatedAt.toMillis, 'function');
  assert.equal((await db.collection('Seats').doc('randomLegacy').get()).exists, false);
  assert.equal((await db.collection('Stage').doc('st1').get()).data().capacity, '2');
});

test('adminUpsertSeatPlan: admin olmayan ve duplicate/bozuk plan reddedilir', async () => {
  const { c } = makeCatalog();
  const usr = await normalUser();
  await db.collection('Stage').doc('st1').set({ name: 'Sahne Bir' });
  await expectCode(c.adminUpsertSeatPlan(usr, { stageId: 'st1', seatIds: ['A1'] }), 'permission-denied');
  const admin = await makeAdmin();
  await expectCode(c.adminUpsertSeatPlan(admin, { stageId: 'st1', seatIds: ['A1', 'A1'] }), 'invalid-argument');
  await expectCode(c.adminUpsertSeatPlan(admin, { stageId: 'st1', seatIds: ['A.1'] }), 'invalid-argument');
});

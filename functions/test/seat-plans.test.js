'use strict';
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, clearDb, makeAdmin, expectCode, seedEvent, makeService } = require('./helpers');
const { createSeatPlans } = require('../src/seatPlans');

beforeEach(clearDb);
const service = () => createSeatPlans({ db, now: () => Date.UTC(2026, 10, 19) });

test('seat plans: admin permission, missing stage and malformed input', async () => {
  const svc = service();
  await expectCode(svc.adminUpsertSeatPlan('user', { stageId: 's', seatIds: ['A1'] }), 'permission-denied');
  const uid = await makeAdmin();
  await expectCode(svc.adminUpsertSeatPlan(uid, { stageId: 'missing', seatIds: ['A1'] }), 'not-found');
  for (const seatIds of [[], ['A1', 'A1'], ['A.1'], [null], Array(5001).fill('A1')]) {
    await expectCode(svc.adminUpsertSeatPlan(uid, { stageId: 's', seatIds }), 'invalid-argument');
  }
  await expectCode(svc.adminUpsertSeatPlan(uid, { stageId: 's', seatIds: ['A1'], closedSeatIds: 'A1' }), 'invalid-argument');
  await expectCode(svc.adminUpsertSeatPlan(uid, { stageId: 's', seatIds: ['A1'], updateStageCapacity: 'true' }), 'invalid-argument');
});

test('seat plans: legacy migration preserves closures and creation date without changing existing events', async () => {
  const uid = await makeAdmin();
  const eventId = await seedEvent({ stageId: 's', seatNames: ['old-seat'] });
  const eventBefore = (await db.collection('Event').doc(eventId).get()).data();
  await db.collection('Seats').doc('random-legacy-id').set({
    stageId: 's', A: ['A1', 'A2'], closedSeatsId: ['A2'], _createdAt: '2025-01-01T00:00:00.000Z',
  });
  const result = await service().adminUpsertSeatPlan(uid, {
    stageId: 's', seatIds: ['A1', 'A2', 'A3'], updateStageCapacity: true,
  });
  assert.equal(result.seatCount, 3);
  const plan = (await db.collection('Seats').doc('s').get()).data();
  assert.deepEqual(plan.seatIds, ['A1', 'A2', 'A3']);
  assert.deepEqual(plan.seatsId, plan.seatIds);
  assert.deepEqual(plan.closedSeatIds, ['A2']);
  assert.deepEqual(plan.closedSeatsId, ['A2']);
  assert.equal(plan.createdAt, '2025-01-01T00:00:00.000Z');
  assert.equal((await db.collection('Seats').doc('random-legacy-id').get()).exists, false);
  assert.equal((await db.collection('Stage').doc('s').get()).data().capacity, '3');
  assert.deepEqual((await db.collection('Event').doc(eventId).get()).data(), eventBefore);
  await service().adminUpsertSeatPlan(uid, { stageId: 's', seatIds: ['A1'] });
  assert.deepEqual((await db.collection('Seats').doc('s').get()).data().closedSeatIds, []);
  assert.equal((await db.collection('Stage').doc('s').get()).data().capacity, '3');
});

for (const legacy of [false, true]) {
  test(`seat purchase: ${legacy ? 'legacy document' : 'new flat schema'} initializes blocked seats safely`, async () => {
    const eventId = await seedEvent({ stageId: 's', seatNames: [] });
    await db.collection('Seats').doc(legacy ? 'random' : 's').set({
      stageId: 's', seatIds: ['A1', 'A2'], closedSeatIds: ['A2'], createdBy: ['not-a-seat'],
    });
    const { svc } = makeService();
    await expectCode(svc.holdSeats('user', { eventId, seatIds: ['A2'] }), 'failed-precondition');
    await svc.holdSeats('user', { eventId, seatIds: ['A1'] });
    const seats = (await db.collection('Event').doc(eventId).get()).data().seats;
    assert.deepEqual(Object.keys(seats).sort(), ['A1', 'A2']);
    assert.equal(seats.A2.status, 'blocked');
    assert.equal(seats.A1.status, 'reserved');
  });
}

test('seat plans: canonical document wins over legacy duplicate', async () => {
  const uid = await makeAdmin();
  await db.collection('Stage').doc('s').set({ name: 'Stage' });
  await db.collection('Seats').doc('s').set({ seatIds: ['A1'], closedSeatIds: [] });
  await db.collection('Seats').doc('old').set({ stageId: 's', seatsId: ['A1'], closedSeatsId: ['A1'] });
  await service().adminUpsertSeatPlan(uid, { stageId: 's', seatIds: ['A1'] });
  assert.deepEqual((await db.collection('Seats').doc('s').get()).data().closedSeatIds, []);
});

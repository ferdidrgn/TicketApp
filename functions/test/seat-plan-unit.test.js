'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readSeatPlan, createSeatPlans } = require('../src/seatPlans');

const fixtures = [
  {
    name: 'row layout excludes metadata arrays and duplicate seats',
    data: { A: ['A1', 'A2', 'A1', null], B: ['B1'], closedSeatsId: ['A2'], createdBy: ['admin'], stageId: 'stage' },
    ids: ['A1', 'A2', 'B1'], closed: ['A2'],
  },
  {
    name: 'legacy flat layout',
    data: { seatsId: ['A1', 'BA1'], closedSeatsId: ['BA1', 'removed'] },
    ids: ['A1', 'BA1'], closed: ['BA1'],
  },
  {
    name: 'new fields take precedence over stale legacy fields',
    data: { seatIds: ['C1'], seatsId: ['A1'], closedSeatIds: [], closedSeatsId: ['C1'] },
    ids: ['C1'], closed: [],
  },
  { name: 'empty plan', data: {}, ids: [], closed: [] },
];

for (const f of fixtures) {
  test(`server reader: ${f.name}`, () => {
    assert.deepEqual(readSeatPlan(f.data), { seatIds: f.ids, closedSeatIds: f.closed });
  });
  test(`web reader: ${f.name}`, async () => {
    const { seatPlanRows, closedSeatIds } = await import('../../site/js/seat-plan.js');
    const ids = seatPlanRows(f.data).flatMap(([, row]) => row);
    assert.deepEqual(ids, f.ids);
    assert.deepEqual(closedSeatIds(f.data).filter((id) => ids.includes(id)), f.closed);
  });
}

// Minimal transaction double: real Firestore integration lives in seat-plans.test.js.
// Enforces all reads before writes and commits only after the callback succeeds.
function database(initial) {
  const docs = new Map(Object.entries(initial));
  const snapshot = (ref) => ({ ref, id: ref.id, exists: docs.has(ref.path), data: () => docs.get(ref.path) });
  const db = {
    collection: (name) => ({
      doc: (id) => ({ path: `${name}/${id}`, id, get: async function () { return snapshot(this); } }),
      where: (field, op, value) => ({ limit: (count) => ({ name, field, value, count }) }),
    }),
    runTransaction: async (callback) => {
      const writes = [];
      const result = await callback({
        get: async (ref) => {
          assert.equal(writes.length, 0, 'transaction cannot read after writing');
          if (ref.path) return snapshot(ref);
          const matches = [...docs].filter(([path, data]) =>
            path.startsWith(`${ref.name}/`) && data[ref.field] === ref.value)
            .slice(0, ref.count).map(([path]) => snapshot({ path, id: path.split('/')[1] }));
          return { empty: !matches.length, docs: matches };
        },
        set: (ref, data) => writes.push(() => docs.set(ref.path, data)),
        update: (ref, data) => writes.push(() => docs.set(ref.path, { ...docs.get(ref.path), ...data })),
        delete: (ref) => writes.push(() => docs.delete(ref.path)),
      });
      writes.forEach((write) => write());
      return result;
    },
  };
  return { db, docs };
}

test('admin save migrates old layout, keeps closures and leaves event history unchanged', async () => {
  const { db, docs } = database({
    'User/admin': { role: 'admin' }, 'Stage/s': { name: 'Test', capacity: '2', address: 'Address' },
    'Seats/random': { stageId: 's', A: ['A1', 'A2'], closedSeatsId: ['A2'], _createdAt: 'original-date' },
    'Event/e': { stageId: 's', seats: { A1: { status: 'sold' } } },
  });
  const event = structuredClone(docs.get('Event/e'));
  const svc = createSeatPlans({ db, now: () => 0 });
  assert.deepEqual(await svc.adminUpsertSeatPlan('admin', {
    stageId: 's', seatIds: ['A1', 'A2', 'B1'], updateStageCapacity: true,
  }), { ok: true, stageId: 's', seatCount: 3 });
  const plan = docs.get('Seats/s');
  assert.deepEqual(plan.seatIds, ['A1', 'A2', 'B1']);
  assert.deepEqual(plan.seatsId, plan.seatIds);
  assert.deepEqual(plan.closedSeatIds, ['A2']);
  assert.deepEqual(plan.closedSeatsId, plan.closedSeatIds);
  assert.equal(plan.createdAt, 'original-date');
  assert.equal(plan.stageName, 'Test');
  assert.equal(plan.updatedAt, '1970-01-01T00:00:00.000Z');
  assert.equal(docs.has('Seats/random'), false);
  assert.equal(docs.get('Stage/s').capacity, '3');
  assert.deepEqual(docs.get('Event/e'), event);
  await svc.adminUpsertSeatPlan('admin', { stageId: 's', seatIds: ['A1'] });
  assert.deepEqual(docs.get('Seats/s').closedSeatIds, []);
  assert.equal(docs.get('Stage/s').capacity, '3', 'capacity is only changed on request');
});

test('admin save validates role, stage and layout before committing changes', async () => {
  const { db, docs } = database({ 'User/admin': { role: 'admin' }, 'Stage/s': { name: 'Test' } });
  const svc = createSeatPlans({ db });
  const expectCode = async (promise, code) => assert.rejects(promise, (error) => error.code === code);
  await expectCode(svc.adminUpsertSeatPlan('user', { stageId: 's', seatIds: ['A1'] }), 'permission-denied');
  await expectCode(svc.adminUpsertSeatPlan('admin', { stageId: 'missing', seatIds: ['A1'] }), 'not-found');
  for (const seatIds of [[], ['A1', 'A1'], ['A.1'], [null], Array(5001).fill('A1')]) {
    await expectCode(svc.adminUpsertSeatPlan('admin', { stageId: 's', seatIds }), 'invalid-argument');
  }
  await expectCode(svc.adminUpsertSeatPlan('admin', { stageId: 's', seatIds: ['A1'], closedSeatIds: 'A1' }), 'invalid-argument');
  assert.equal(docs.has('Seats/s'), false);
});

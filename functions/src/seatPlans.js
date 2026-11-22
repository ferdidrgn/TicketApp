'use strict';
const { err, makeAssertAdmin, validateId } = require('./util');
const { MAX_SEAT_ID_LENGTH } = require('./config');

const META = new Set([
  'seatIds', 'seatsId', 'closedSeatIds', 'closedSeatsId', '_id',
  '_createdAt', '_updatedAt', 'createdAt', 'updatedAt', 'createdBy',
  'updatedBy', 'schemaVersion', 'seatCount', 'stageId', 'stageName', 'address',
]);

function readSeatPlan(data = {}) {
  const flat = data.seatIds ?? data.seatsId;
  const ids = Array.isArray(flat) ? flat : Object.entries(data)
    .filter(([key, value]) => !META.has(key) && Array.isArray(value))
    .flatMap(([, value]) => value);
  const seatIds = [...new Set(ids.filter((id) => typeof id === 'string' && id))];
  const closed = data.closedSeatIds ?? data.closedSeatsId;
  const closedSeatIds = Array.isArray(closed) ? closed.filter((id) => seatIds.includes(id)) : [];
  return { seatIds, closedSeatIds: [...new Set(closedSeatIds)] };
}

async function findSeatPlan(tx, db, stageId) {
  const canonical = await tx.get(db.collection('Seats').doc(stageId));
  if (canonical.exists) return canonical;
  const legacy = await tx.get(db.collection('Seats').where('stageId', '==', stageId).limit(1));
  return legacy.empty ? canonical : legacy.docs[0];
}

function validatePlanIds(ids, allowEmpty = false) {
  if (!Array.isArray(ids) || (!allowEmpty && !ids.length) || ids.length > 5000) {
    throw err('invalid-argument', 'Koltuk planı 1–5000 koltuk içermelidir.');
  }
  if (ids.some((id) => typeof id !== 'string' || !id.length ||
      id.length > MAX_SEAT_ID_LENGTH || !/^[A-Za-z0-9_-]+$/.test(id)) ||
      new Set(ids).size !== ids.length) {
    throw err('invalid-argument', 'Koltuk kimlikleri geçerli ve benzersiz olmalıdır.');
  }
  return ids;
}

function createSeatPlans({ db, now = Date.now }) {
  const assertAdmin = makeAssertAdmin(db);

  async function adminUpsertSeatPlan(uid, data) {
    await assertAdmin(uid);
    const stageId = validateId(data && data.stageId, 'sahne');
    const seatIds = validatePlanIds(data.seatIds);
    if (data.closedSeatIds !== undefined) validatePlanIds(data.closedSeatIds, true);
    if (data.updateStageCapacity !== undefined && typeof data.updateStageCapacity !== 'boolean') {
      throw err('invalid-argument', 'Kapasite güncelleme seçimi geçersiz.');
    }
    return db.runTransaction(async (tx) => {
      const stageRef = db.collection('Stage').doc(stageId);
      const stage = await tx.get(stageRef);
      if (!stage.exists) throw err('not-found', 'Sahne bulunamadı.');
      const previous = await findSeatPlan(tx, db, stageId);
      const old = previous.exists ? previous.data() : {};
      const closed = data.closedSeatIds ?? readSeatPlan(old).closedSeatIds;
      // Removed seats cannot remain in the closed-seat list.
      const closedSeatIds = closed.filter((id) => seatIds.includes(id));
      const stamp = new Date(now()).toISOString();
      const createdAt = old.createdAt ?? old._createdAt ?? stamp;
      tx.set(db.collection('Seats').doc(stageId), {
        _id: stageId, stageId, stageName: stage.data().name || '',
        address: stage.data().address || '', schemaVersion: 2,
        seatIds, seatsId: seatIds, closedSeatIds, closedSeatsId: closedSeatIds,
        seatCount: seatIds.length, createdAt, _createdAt: createdAt,
        updatedAt: stamp, _updatedAt: stamp,
        createdBy: old.createdBy || uid, updatedBy: uid,
      });
      if (previous.exists && previous.id !== stageId) tx.delete(previous.ref);
      if (data.updateStageCapacity) {
        tx.update(stageRef, { capacity: String(seatIds.length), _updatedAt: stamp });
      }
      return { ok: true, stageId, seatCount: seatIds.length };
    });
  }

  return { adminUpsertSeatPlan };
}

module.exports = { createSeatPlans, readSeatPlan, findSeatPlan };

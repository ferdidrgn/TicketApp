'use strict';
/**
 * Biletli oyun/sahne/seans SİLİNEMEZ — bu kural eskiden yalnızca istemci kodundaydı
 * (lib/features/admin/presentation/widgets/delete_guard.dart); firestore.rules'da
 * Show/Stage/Event'in delete'i yalnızca isAdmin() şartına bağlıydı, yani çalıntı/
 * ele geçirilmiş bir admin hesabı uygulamayı hiç kullanmadan (Firestore Console'dan
 * ya da doğrudan SDK ile) biletli bir kaydı silebilirdi (09.11.2026 güvenlik
 * denetiminde bulundu). Artık silme SADECE bu callable'lar üzerinden; firestore.rules
 * bu üç koleksiyonda `allow delete: if false` olarak kapatıldı (Order/Ticket/
 * UserLimits'te zaten uygulanan desenin aynısı). Aynı bilet kontrolü (Ticket'ta
 * showId/stageId/eventId eşleşmesi) burada sunucuda tekrarlanır — istemcideki
 * delete_guard.dart artık yalnızca "boşuna istek atma" ön-uyarısıdır, gerçek
 * güvenlik sınırı burasıdır.
 */
const { getStorage } = require('firebase-admin/storage');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { err, makeAssertAdmin, validateId } = require('./util');

const MAX_SEAT_PLAN_SIZE = 2000;
const MAX_SEAT_ID_LENGTH = 16;

function normalizeSeatPlanIds(value, label) {
  if (!Array.isArray(value) || value.length < 1 || value.length > MAX_SEAT_PLAN_SIZE) {
    throw err('invalid-argument', `${label} geçersiz.`);
  }
  const out = [];
  const seen = new Set();
  for (const raw of value) {
    if (typeof raw !== 'string' || raw.length < 1 || raw.length > MAX_SEAT_ID_LENGTH || !/^[A-Za-z0-9_-]+$/.test(raw)) {
      throw err('invalid-argument', 'Geçersiz koltuk kimliği.');
    }
    if (seen.has(raw)) throw err('invalid-argument', 'Aynı koltuk birden fazla kez eklenemez.');
    seen.add(raw); out.push(raw);
  }
  return out;
}

function existingTimestamp(value) {
  if (value && typeof value.toMillis === 'function') return value;
  if (typeof value === 'string' || value instanceof Date) {
    const ms = new Date(value).getTime();
    if (Number.isFinite(ms)) return Timestamp.fromMillis(ms);
  }
  return null;
}

function createCatalog({ db, storage = getStorage() }) {
  const col = (n) => db.collection(n);
  const assertAdmin = makeAssertAdmin(db);

  async function assertNoTickets(field, id, label) {
    const snap = await col('Ticket').where(field, '==', id).limit(1).count().get();
    if (snap.data().count > 0) {
      throw err('failed-precondition', `"${label}" için bilet var; biletli bir kayıt silinemez.`);
    }
  }

  async function deleteStorageQuiet(path) {
    try {
      await storage.bucket().file(path).delete();
    } catch (_) {
      // Görsel yoksa hatayı yut (addShow/addStage'deki ile aynı desen).
    }
  }

  async function adminDeleteShow(uid, data) {
    await assertAdmin(uid);
    const id = validateId(data && data.showId, 'oyun');
    const ref = col('Show').doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw err('not-found', 'Oyun bulunamadı.');
    await assertNoTickets('showId', id, snap.data().name || id);
    await deleteStorageQuiet(`ShowImages/${id}.jpg`);
    await ref.delete();
    return { ok: true };
  }

  async function adminDeleteStage(uid, data) {
    await assertAdmin(uid);
    const id = validateId(data && data.stageId, 'sahne');
    const ref = col('Stage').doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw err('not-found', 'Sahne bulunamadı.');
    await assertNoTickets('stageId', id, snap.data().name || id);
    await deleteStorageQuiet(`StageImages/${id}.jpg`);
    await ref.delete();
    return { ok: true };
  }

  async function adminDeleteEvent(uid, data) {
    await assertAdmin(uid);
    const id = validateId(data && data.eventId, 'seans');
    const ref = col('Event').doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw err('not-found', 'Seans bulunamadı.');
    await assertNoTickets('eventId', id, snap.data().showId || id);
    await ref.delete();
    return { ok: true };
  }

  async function adminUpsertSeatPlan(uid, data) {
    await assertAdmin(uid);
    const stageId = validateId(data && data.stageId, 'sahne');
    const seatIds = normalizeSeatPlanIds(data && data.seatIds, 'Koltuk planı');
    const requestedClosed = Array.isArray(data && data.closedSeatIds) ? data.closedSeatIds : [];
    if (requestedClosed.some((id) => typeof id !== 'string' || id.length < 1 || id.length > MAX_SEAT_ID_LENGTH || !/^[A-Za-z0-9_-]+$/.test(id))) {
      throw err('invalid-argument', 'Kapalı koltuk listesi geçersiz.');
    }
    const closedSeatIds = [...new Set(requestedClosed)].filter((id) => seatIds.includes(id));
    const stageRef = col('Stage').doc(stageId);
    const canonicalRef = col('Seats').doc(stageId);
    const legacyQuery = col('Seats').where('stageId', '==', stageId).limit(1);
    const updateCapacity = data && data.updateStageCapacity === true;

    return db.runTransaction(async (tx) => {
      const [stageSnap, canonicalSnap, legacySnap] = await Promise.all([
        tx.get(stageRef), tx.get(canonicalRef), tx.get(legacyQuery),
      ]);
      if (!stageSnap.exists) throw err('not-found', 'Sahne bulunamadı.');
      const stage = stageSnap.data() || {};
      const legacyDoc = legacySnap.docs.find((d) => d.id !== stageId) || null;
      const previous = canonicalSnap.exists ? canonicalSnap.data() : (legacyDoc ? legacyDoc.data() : {});
      const createdAt = existingTimestamp(previous.createdAt || previous._createdAt) || FieldValue.serverTimestamp();
      const stageName = typeof stage.name === 'string' ? stage.name.trim() : '';
      const address = typeof stage.address === 'string' ? stage.address.trim() : '';
      const doc = {
        _id: stageId, stageId, stageName, address, schemaVersion: 2,
        seatIds, closedSeatIds, seatsId: seatIds, closedSeatsId: closedSeatIds,
        seatCount: seatIds.length,
        createdAt, updatedAt: FieldValue.serverTimestamp(),
        _createdAt: createdAt, _updatedAt: FieldValue.serverTimestamp(),
        createdBy: previous.createdBy || uid, updatedBy: uid,
      };
      tx.set(canonicalRef, doc, { merge: true });
      if (legacyDoc) tx.delete(legacyDoc.ref);
      if (updateCapacity) tx.update(stageRef, {
        capacity: String(seatIds.length), _updatedAt: FieldValue.serverTimestamp(),
      });
      return { stageId, seatCount: seatIds.length, migrated: !!legacyDoc };
    });
  }

  return { adminDeleteShow, adminDeleteStage, adminDeleteEvent, adminUpsertSeatPlan };
}

module.exports = { createCatalog };

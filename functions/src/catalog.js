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
const { err, makeAssertAdmin, validateId } = require('./util');

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

  return { adminDeleteShow, adminDeleteStage, adminDeleteEvent };
}

module.exports = { createCatalog };

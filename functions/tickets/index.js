/**
 * Kapıda bilet doğrulama (QR tarama). Bilet QR kodu sadece ham
 * `Ticket` doküman ID'sini taşır (bkz. lib/features/tickets/presentation/
 * pages/ticket_details_modal.dart — QrImageView(data: ticketId)).
 *
 * Bu fonksiyon SADECE admin/curator rolündeki hesaplar tarafından
 * çağrılabilir (Firestore'daki User.role alanı — client'ın kendi
 * beyanına değil, sunucunun okuduğu gerçek role güveniyoruz).
 *
 * Bir bilet en fazla BİR KEZ geçerli sayılır: ilk okutulduğunda
 * `checkedInAt` alanı işaretlenir, ikinci okutmada "already_used"
 * hatası döner — aynı QR kodun ekran görüntüsü/fotoğrafıyla birden
 * fazla kişinin girmesini engeller.
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const TICKET_COLLECTION = 'Ticket';
const USER_COLLECTION = 'User';
const SHOW_COLLECTION = 'Show';

async function requirePrivileged(db, uid) {
  const userSnap = await db.collection(USER_COLLECTION).doc(uid).get();
  const role = userSnap.exists ? userSnap.data().role : null;
  if (role !== 'admin' && role !== 'curator') {
    throw new HttpsError('permission-denied', 'Bu işlem için yetkin yok.');
  }
}

exports.validateTicket = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Giriş yapmalısınız.');

  const db = getFirestore();
  await requirePrivileged(db, auth.uid);

  const { ticketId } = request.data || {};
  if (!ticketId || typeof ticketId !== 'string') {
    throw new HttpsError('invalid-argument', 'Geçersiz bilet kodu.');
  }

  const ticketRef = db.collection(TICKET_COLLECTION).doc(ticketId);

  let resultStatus;
  let ticketData;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ticketRef);
    if (!snap.exists) {
      resultStatus = 'not_found';
      return;
    }
    ticketData = snap.data();
    if (ticketData.checkedInAt) {
      resultStatus = 'already_used';
      return;
    }
    tx.update(ticketRef, {
      checkedInAt: FieldValue.serverTimestamp(),
      checkedInBy: auth.uid,
    });
    resultStatus = 'valid';
  });

  if (resultStatus === 'not_found') {
    throw new HttpsError('not-found', 'Bu bilet sistemde bulunamadı.');
  }

  const showSnap = ticketData.showId
      ? await db.collection(SHOW_COLLECTION).doc(ticketData.showId).get()
      : null;
  const showName =
      showSnap && showSnap.exists ? (showSnap.data().name || 'Etkinlik') : 'Etkinlik';
  const seatCount = Array.isArray(ticketData.buySeats) ? ticketData.buySeats.length : 0;

  if (resultStatus === 'already_used') {
    throw new HttpsError(
      'already-exists',
      `Bu bilet daha önce kullanılmış! (${showName}, ${seatCount} koltuk)`,
    );
  }

  return { status: 'valid', showName, seatCount, orderMethod: ticketData.orderMethod || null };
});

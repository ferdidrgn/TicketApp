/**
 * Ücretsiz etkinlikler için bilet talep akışı.
 *
 * Bir etkinlik "ücretsiz" sayılır eğer `price` alanı 0 (veya küçüğü) ise —
 * ayrı bir Firestore alanı gerekmiyor (bkz. lib/features/events/domain/
 * entities/event.dart: Event.isFree). Küratör bir etkinliği ücretsiz
 * yapmak isterse sadece fiyatını "0" olarak ayarlaması yeterli.
 *
 * "Etkinlik başına en fazla 3 bilet" kuralı burada AYRICA kontrol
 * edilmiyor — koltuk rezervasyon adımında (attemptReservation, bkz.
 * event_remote_data_source_and_impl.dart) zaten "bir kullanıcı bir
 * etkinlikte en fazla 3 koltuk rezerve edebilir" kısıtı var; bu fonksiyon
 * sadece GERÇEKTEN rezerve edilmiş koltukları bilete çevirir.
 *
 * SMS: Twilio'nun resmi "Trigger SMS" Firebase Extension'ının varsayılan
 * koleksiyon adını (`messages`) kullanıyoruz. ⚠️ Farklı bir SMS extension'ı
 * veya farklı bir koleksiyon adı kullanıyorsanız SMS_TRIGGER_COLLECTION'ı
 * güncelleyin. Extension kurulu/doğru yapılandırılmış değilse bile bilet
 * oluşturma işlemi BAŞARISIZ OLMAZ — SMS ayrı, best-effort bir adımdır.
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const EVENT_COLLECTION = 'Event';
const SHOW_COLLECTION = 'Show';
const TICKET_COLLECTION = 'Ticket';
const USER_COLLECTION = 'User';
const SMS_TRIGGER_COLLECTION = 'messages';

/** Türkiye numaralarını E.164 formatına ("+90...") normalize eder. */
function normalizeTrPhone(raw) {
  if (!raw) return null;
  const digits = raw.replace(/[^\d+]/g, '');
  if (!digits) return null;
  if (digits.startsWith('+')) return digits;
  if (digits.startsWith('90')) return `+${digits}`;
  if (digits.startsWith('0')) return `+90${digits.slice(1)}`;
  return `+90${digits}`;
}

exports.claimFreeTicket = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Bu işlem için giriş yapmalısınız.');
  const customerId = auth.uid;

  const { eventId, seatIds } = request.data || {};
  if (!eventId || !Array.isArray(seatIds) || seatIds.length === 0) {
    throw new HttpsError('invalid-argument', 'eventId ve seatIds zorunludur.');
  }

  const db = getFirestore();
  const eventRef = db.collection(EVENT_COLLECTION).doc(eventId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) throw new HttpsError('not-found', 'Etkinlik bulunamadı.');
  const eventData = eventSnap.data();

  // 🔒 Etkinliğin GERÇEKTEN ücretsiz olduğunu sunucu tarafında doğrula —
  // client'ın "bu etkinlik ücretsiz" iddiasına güvenilmez.
  const price = parseFloat(eventData.price);
  const isFree = Number.isFinite(price) && price <= 0;
  if (!isFree) {
    throw new HttpsError('failed-precondition', 'Bu etkinlik ücretsiz değil.');
  }

  const userSnap = await db.collection(USER_COLLECTION).doc(customerId).get();
  const userData = userSnap.exists ? userSnap.data() : null;
  const phone = normalizeTrPhone(userData?.phoneNumber) || normalizeTrPhone(auth.token.phone_number);
  if (!phone) {
    throw new HttpsError(
      'failed-precondition',
      'Ücretsiz bilet alabilmek için profilinde bir telefon numarası olmalı. ' +
      'Lütfen önce profilini güncelle.',
    );
  }

  let ticketId;
  await db.runTransaction(async (tx) => {
    const freshEventSnap = await tx.get(eventRef);
    if (!freshEventSnap.exists) throw new Error(`Etkinlik bulunamadı: ${eventId}`);
    const seats = freshEventSnap.data().seats || {};

    // 🔒 Koltukların GERÇEKTEN bu kullanıcı tarafından rezerve edildiğini
    // doğrula (aynı desen: functions/payments/index.js finalizePayment).
    const invalidSeats = seatIds.filter((id) => {
      const s = seats[id];
      return !(s && s.status === 'reserved' && s.customerId === customerId);
    });
    if (invalidSeats.length > 0) {
      throw new HttpsError(
        'failed-precondition',
        `Şu koltuklar rezervasyonunuzda değil (süresi dolmuş olabilir): ${invalidSeats.join(', ')}`,
      );
    }

    for (const seatId of seatIds) {
      tx.update(eventRef, {
        [`seats.${seatId}.status`]: 'sold',
        [`seats.${seatId}.customerId`]: customerId,
        [`seats.${seatId}.soldAt`]: FieldValue.serverTimestamp(),
      });
    }

    const ticketRef = db.collection(TICKET_COLLECTION).doc();
    ticketId = ticketRef.id;
    tx.set(ticketRef, {
      _id: ticketRef.id,
      _createdAt: FieldValue.serverTimestamp(),
      _updatedAt: new Date().toISOString(),
      customerId,
      showId: eventData.showId || null,
      stageId: eventData.stageId || null,
      eventId,
      orderMethod: 'free',
      orderPrice: '0.00',
      buySeats: seatIds,
      isPast: false,
    });
  });

  // 📲 SMS bildirimi — best-effort, bilet oluşturma başarısını ETKİLEMEZ.
  try {
    const showSnap = eventData.showId
        ? await db.collection(SHOW_COLLECTION).doc(eventData.showId).get()
        : null;
    const showName = showSnap && showSnap.exists ? (showSnap.data().name || 'Etkinlik') : 'Etkinlik';
    await db.collection(SMS_TRIGGER_COLLECTION).add({
      to: phone,
      body:
          `TiyatRol: "${showName}" için ${seatIds.length} adet ücretsiz biletin hazır! ` +
          'Biletlerim sayfasından görüntüleyebilirsin.',
    });
  } catch (err) {
    console.error('Ücretsiz bilet SMS tetikleme başarısız (bilet yine de oluşturuldu):', err);
  }

  return { ticketId };
});

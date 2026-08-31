/**
 * Süresi dolmuş koltuk rezervasyonlarını serbest bırakır.
 *
 * BULUNAN GERÇEK BUG: Kullanıcı bir koltuk seçip (status: 'reserved')
 * ödeme ekranına gelmeden uygulamadan çıkarsa (geri tuşu DIŞINDA bir
 * yol — uygulama çökmesi, sekmeyi kapatma, internetin gitmesi vb.),
 * o koltuk SONSUZA KADAR "reserved" kalıyordu; seat_details.dart'taki
 * dispose() sadece normal (temiz) çıkışları serbest bırakıyor,
 * sunucu tarafında hiçbir TTL/temizlik mekanizması yoktu.
 *
 * Bu zamanlanmış fonksiyon her 5 dakikada bir tüm etkinlikleri tarar;
 * `reservedAt` üzerinden 10 dakikadan (reservationTimerProvider'daki
 * geri sayımla aynı süre — bkz. lib/features/events/presentation/
 * providers/event_provider.dart) eski "reserved" koltukları
 * `available`'a döndürür.
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore } = require('firebase-admin/firestore');

const EVENT_COLLECTION = 'Event';
const RESERVATION_TTL_MS = 10 * 60 * 1000; // 10 dakika
const BATCH_CHUNK_SIZE = 400; // Firestore batch limiti 500 — güvenli pay bırakıyoruz.

exports.releaseExpiredReservations = onSchedule('every 5 minutes', async () => {
  const db = getFirestore();
  const now = Date.now();

  const eventsSnap = await db.collection(EVENT_COLLECTION).get();
  const pendingUpdates = [];

  for (const doc of eventsSnap.docs) {
    const seats = doc.data().seats || {};
    const fieldUpdates = {};

    for (const [seatId, seatData] of Object.entries(seats)) {
      if (!seatData || seatData.status !== 'reserved' || !seatData.reservedAt) continue;
      const reservedAtMs = typeof seatData.reservedAt.toMillis === 'function'
          ? seatData.reservedAt.toMillis()
          : 0;
      if (now - reservedAtMs > RESERVATION_TTL_MS) {
        fieldUpdates[`seats.${seatId}.status`] = 'available';
        fieldUpdates[`seats.${seatId}.customerId`] = null;
        fieldUpdates[`seats.${seatId}.reservedAt`] = null;
      }
    }

    if (Object.keys(fieldUpdates).length > 0) {
      pendingUpdates.push({ ref: doc.ref, fieldUpdates });
    }
  }

  if (pendingUpdates.length === 0) {
    console.log('releaseExpiredReservations: süresi dolmuş rezervasyon yok.');
    return;
  }

  for (let i = 0; i < pendingUpdates.length; i += BATCH_CHUNK_SIZE) {
    const batch = db.batch();
    for (const { ref, fieldUpdates } of pendingUpdates.slice(i, i + BATCH_CHUNK_SIZE)) {
      batch.update(ref, fieldUpdates);
    }
    await batch.commit();
  }

  console.log(`releaseExpiredReservations: ${pendingUpdates.length} etkinlikte süresi dolmuş koltuklar serbest bırakıldı.`);
});

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
 * 🔒 GÜVENLİK — DOĞRULANMIŞ KİMLİK ZORUNLULUĞU:
 * SMS, kullanıcının Firestore'daki serbest metin `phoneNumber` alanına
 * DEĞİL, Firebase Auth'un kendi ID token'ındaki `phone_number` alanına
 * gönderilir. Bu alan SADECE gerçek bir OTP doğrulaması (Phone Auth ile
 * giriş/linkleme) sonrası dolar — yani kullanıcı Firestore'daki profilini
 * değiştirerek başka birinin numarasına SMS gönderilmesini SAĞLAYAMAZ.
 * Ayrıca hesabın en az bir kanaldan (doğrulanmış telefon VEYA Google ile
 * doğrulanmış e-posta) kimlik doğrulaması yapmış olması şart koşulur —
 * bu, tek kullanımlık/sahte hesapların ücretsiz bilet "farm"lamasını
 * zorlaştırır.
 *
 * SMS: Twilio'nun resmi "Trigger SMS" Firebase Extension'ının varsayılan
 * koleksiyon adını (`messages`) kullanıyoruz. ⚠️ Farklı bir SMS extension'ı
 * veya farklı bir koleksiyon adı kullanıyorsanız SMS_TRIGGER_COLLECTION'ı
 * güncelleyin. Extension kurulu/doğru yapılandırılmış değilse bile bilet
 * oluşturma işlemi BAŞARISIZ OLMAZ — SMS ayrı, best-effort bir adımdır.
 * Doğrulanmış telefonu olmayan (sadece e-posta ile doğrulanmış) kullanıcılar
 * yine de ücretsiz bileti alır, sadece SMS gönderilmez.
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const EVENT_COLLECTION = 'Event';
const SHOW_COLLECTION = 'Show';
const TICKET_COLLECTION = 'Ticket';
const SMS_TRIGGER_COLLECTION = 'messages';

exports.claimFreeTicket = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Bu işlem için giriş yapmalısınız.');
  const customerId = auth.uid;

  // 🔒 Bu kullanıcının en az bir kanaldan GERÇEKTEN doğrulanmış olduğundan
  // emin ol — Firebase Auth ID token'ındaki bu alanlar client tarafından
  // taklit edilemez (Firebase Admin SDK tarafından imza doğrulanır).
  const verifiedPhone = auth.token.phone_number || null; // Sadece OTP ile doğrulanmışsa dolu.
  const isEmailVerified = auth.token.email_verified === true; // Google ile girişte otomatik true.
  if (!verifiedPhone && !isEmailVerified) {
    throw new HttpsError(
      'failed-precondition',
      'Ücretsiz bilet alabilmek için hesabının telefon (OTP ile) veya ' +
      'Google e-postası ile doğrulanmış olması gerekiyor.',
    );
  }

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

  // 📲 SMS bildirimi — SADECE gerçekten OTP ile doğrulanmış bir telefon
  // varsa gönderilir; best-effort, bilet oluşturma başarısını ETKİLEMEZ.
  let smsSent = false;
  if (verifiedPhone) {
    try {
      const showSnap = eventData.showId
          ? await db.collection(SHOW_COLLECTION).doc(eventData.showId).get()
          : null;
      const showName = showSnap && showSnap.exists ? (showSnap.data().name || 'Etkinlik') : 'Etkinlik';
      await db.collection(SMS_TRIGGER_COLLECTION).add({
        to: verifiedPhone,
        body:
            `TiyatRol: "${showName}" için ${seatIds.length} adet ücretsiz biletin hazır! ` +
            'Biletlerim sayfasından görüntüleyebilirsin.',
      });
      smsSent = true;
    } catch (err) {
      console.error('Ücretsiz bilet SMS tetikleme başarısız (bilet yine de oluşturuldu):', err);
    }
  }

  return { ticketId, smsSent };
});

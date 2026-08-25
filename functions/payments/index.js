/**
 * Ödeme oturumu oluşturma + sağlayıcı webhook'ları.
 *
 * Mimari (üç sağlayıcı için de aynı):
 *   1) Flutter uygulaması `createPaymentSession` callable'ını çağırır.
 *      Bu fonksiyon TUTARI VE KOLTUK REZERVASYONUNU SUNUCU TARAFINDA
 *      doğrular (client'ın gönderdiği tutara asla güvenilmez), bir
 *      `Payment/{paymentId}` dökümanı ('pending') oluşturur ve seçilen
 *      sağlayıcıda bir ödeme oturumu açıp `checkoutUrl` döner.
 *   2) Uygulama bu URL'i (harici tarayıcıda) açar, kullanıcı kartıyla
 *      öder.
 *   3) Sağlayıcı bizim webhook endpoint'imize (imzalı/doğrulanabilir bir
 *      şekilde) sonucu bildirir. Webhook, ödeme gerçekten başarılıysa
 *      `finalizePayment` ile — Admin SDK kullanarak, Firestore güvenlik
 *      kurallarını atlayarak — koltukları 'sold' yapar ve Ticket
 *      dökümanını OLUŞTURUR. Yani gerçek bir bilet, YALNIZCA sağlayıcı
 *      ödemeyi doğruladıktan sonra, sunucu tarafında oluşur.
 *   4) Flutter uygulaması `Payment/{paymentId}` dökümanını dinleyerek
 *      (Firestore stream) sonucu öğrenir.
 *
 * Bu, mevcut client-side `confirmPurchase` akışından (bkz.
 * event_remote_data_source_and_impl.dart) BAĞIMSIZ, ayrı bir yoldur —
 * onu bozmaz. "Kredi/Banka Kartı" ödeme seçeneği Flutter tarafında bu
 * akışa yönlendirilmelidir; "Havale/EFT" seçeneği (manuel, anlık onaylı)
 * olduğu gibi bırakılmıştır.
 */

const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const {
  ALL_PAYMENT_SECRETS,
  IYZICO_API_KEY,
  IYZICO_SECRET_KEY,
  IYZICO_BASE_URL,
  PAYTR_MERCHANT_ID,
  PAYTR_MERCHANT_KEY,
  PAYTR_MERCHANT_SALT,
  STRIPE_SECRET_KEY,
  STRIPE_WEBHOOK_SECRET,
} = require('./secrets');
const iyzico = require('./iyzico');
const paytr = require('./paytr');
const stripeProvider = require('./stripe');

const PAYMENT_COLLECTION = 'Payment';
const EVENT_COLLECTION = 'Event';
const TICKET_COLLECTION = 'Ticket';
const VALID_PROVIDERS = ['iyzico', 'paytr', 'stripe'];

/**
 * Bu Cloud Functions'ların dağıtıldığı temel URL. Varsayılan v2 bölgesi
 * `us-central1`'dir — farklı bir bölgede deploy ederseniz veya özel bir
 * domain kullanıyorsanız `PAYMENTS_BASE_URL` ortam değişkenini
 * (`firebase functions:config` yerine v2'de `.env` dosyası ile) ayarlayın.
 */
function functionsBaseUrl() {
  if (process.env.PAYMENTS_BASE_URL) return process.env.PAYMENTS_BASE_URL;
  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'YOUR_PROJECT_ID';
  return `https://us-central1-${projectId}.cloudfunctions.net`;
}

function landingHtml({ title, message }) {
  return `<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>body{font-family:system-ui,sans-serif;background:#09090B;color:#fff;
display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:24px;text-align:center}
div{max-width:420px}h1{font-size:20px}p{color:#A1A1AA}</style></head>
<body><div><h1>${title}</h1><p>${message}</p></div></body></html>`;
}

// ==============================================================================
// 1. ÖDEME OTURUMU OLUŞTUR (callable — Flutter'dan çağrılır)
// ==============================================================================

exports.createPaymentSession = onCall({ secrets: ALL_PAYMENT_SECRETS }, async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Bu işlem için giriş yapmalısınız.');
  const customerId = auth.uid;

  const { provider, eventId, seatIds } = request.data || {};
  if (!VALID_PROVIDERS.includes(provider)) {
    throw new HttpsError('invalid-argument', 'Geçersiz ödeme sağlayıcısı.');
  }
  if (!eventId || !Array.isArray(seatIds) || seatIds.length === 0) {
    throw new HttpsError('invalid-argument', 'eventId ve seatIds zorunludur.');
  }

  const db = getFirestore();
  const eventSnap = await db.collection(EVENT_COLLECTION).doc(eventId).get();
  if (!eventSnap.exists) throw new HttpsError('not-found', 'Etkinlik bulunamadı.');
  const eventData = eventSnap.data();

  // 🔒 Koltukların GERÇEKTEN bu kullanıcı tarafından rezerve edildiğini
  // sunucu tarafında doğrula — client'ın iddiasına güvenilmez.
  const seats = eventData.seats || {};
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

  // 🔒 Tutarı SUNUCU TARAFINDA hesapla — client'tan gelen bir fiyata asla güvenilmez.
  const unitPrice = parseFloat(eventData.price);
  if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
    throw new HttpsError('failed-precondition', 'Etkinlik fiyatı geçersiz.');
  }
  const amount = Math.round(unitPrice * seatIds.length * 100) / 100;

  const paymentRef = db.collection(PAYMENT_COLLECTION).doc();
  const paymentId = paymentRef.id;

  await paymentRef.set({
    provider,
    status: 'pending',
    customerId,
    eventId,
    showId: eventData.showId || null,
    stageId: eventData.stageId || null,
    seatIds,
    amount,
    currency: 'TRY',
    providerRef: null,
    failureReason: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  const base = functionsBaseUrl();
  const customerEmail = auth.token.email || undefined;
  const customerName = auth.token.name || undefined;

  try {
    let result;
    if (provider === 'iyzico') {
      result = await iyzico.createSession(
        {
          paymentId,
          amount,
          currency: 'TRY',
          customerId,
          customerEmail,
          customerName,
          callbackUrl: `${base}/iyzicoWebhook`,
          basketDescription: 'TiyatRol Bileti',
        },
        {
          apiKey: IYZICO_API_KEY.value(),
          secretKey: IYZICO_SECRET_KEY.value(),
          baseUrl: IYZICO_BASE_URL.value(),
        },
      );
    } else if (provider === 'paytr') {
      result = await paytr.createSession(
        {
          paymentId,
          amount,
          customerId,
          customerEmail: customerEmail || 'no-reply@tiyatrol.app',
          customerName,
          userIp: request.rawRequest?.ip,
          basketDescription: 'TiyatRol Bileti',
          okUrl: `${base}/paymentLanding?status=ok`,
          failUrl: `${base}/paymentLanding?status=fail`,
        },
        {
          merchantId: PAYTR_MERCHANT_ID.value(),
          merchantKey: PAYTR_MERCHANT_KEY.value(),
          merchantSalt: PAYTR_MERCHANT_SALT.value(),
        },
      );
    } else {
      result = await stripeProvider.createSession(
        {
          paymentId,
          amount,
          currency: 'try',
          customerEmail,
          basketDescription: 'TiyatRol Bileti',
          successUrl: `${base}/paymentLanding?status=ok`,
          cancelUrl: `${base}/paymentLanding?status=fail`,
        },
        { secretKey: STRIPE_SECRET_KEY.value() },
      );
    }

    await paymentRef.update({ providerRef: result.providerRef, updatedAt: FieldValue.serverTimestamp() });
    return { paymentId, checkoutUrl: result.checkoutUrl };
  } catch (err) {
    await paymentRef.update({
      status: 'failed',
      failureReason: String(err.message || err),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (err.code === 'not-configured') {
      // Flutter tarafı bu spesifik mesajı yakalayıp "ödeme henüz aktif
      // değil" durumuna düşebilir (bkz. lib/features/payments).
      throw new HttpsError('failed-precondition', `PAYMENT_PROVIDER_NOT_CONFIGURED: ${err.message}`);
    }
    console.error('createPaymentSession failed:', err);
    throw new HttpsError('internal', `Ödeme oturumu oluşturulamadı: ${err.message}`);
  }
});

// ==============================================================================
// 2. ÖDEMEYİ SONUÇLANDIR (ortak, tüm sağlayıcılar için) — Admin SDK ile
//    Firestore güvenlik kurallarını atlayarak koltukları satar ve bileti
//    oluşturur. Idempotent'tir: Payment zaten 'pending' değilse no-op.
// ==============================================================================

async function finalizePayment(paymentId, success, failureReason) {
  const db = getFirestore();
  const paymentRef = db.collection(PAYMENT_COLLECTION).doc(paymentId);

  await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (!paymentSnap.exists) throw new Error(`Payment bulunamadı: ${paymentId}`);
    const payment = paymentSnap.data();
    if (payment.status !== 'pending') return; // Zaten sonuçlanmış — idempotent.

    if (!success) {
      tx.update(paymentRef, {
        status: 'failed',
        failureReason: failureReason || 'Ödeme sağlayıcı tarafından reddedildi.',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const eventRef = db.collection(EVENT_COLLECTION).doc(payment.eventId);
    const eventSnap = await tx.get(eventRef);
    if (!eventSnap.exists) throw new Error(`Event bulunamadı: ${payment.eventId}`);
    const seats = eventSnap.data().seats || {};

    const invalidSeats = payment.seatIds.filter((id) => {
      const s = seats[id];
      return !(s && s.status === 'reserved' && s.customerId === payment.customerId);
    });
    if (invalidSeats.length > 0) {
      // Ödeme alındı ama koltuk artık geçerli değil (süresi dolmuş/başkasına
      // satılmış) — bu durumda gerçek hayatta iade süreci tetiklenmelidir.
      // Şimdilik Payment'ı 'failed' işaretleyip nedeni kaydediyoruz ki en
      // azından bilet YANLIŞLIKLA oluşmasın; iade akışı ayrı bir iş.
      tx.update(paymentRef, {
        status: 'failed',
        failureReason: `Ödeme alındı ancak koltuk artık geçerli değil (İADE GEREKEBİLİR): ${invalidSeats.join(', ')}`,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    for (const seatId of payment.seatIds) {
      tx.update(eventRef, {
        [`seats.${seatId}.status`]: 'sold',
        [`seats.${seatId}.customerId`]: payment.customerId,
        [`seats.${seatId}.soldAt`]: FieldValue.serverTimestamp(),
      });
    }

    const nowIso = new Date().toISOString();
    const ticketRef = db.collection(TICKET_COLLECTION).doc();
    tx.set(ticketRef, {
      _id: ticketRef.id,
      _createdAt: FieldValue.serverTimestamp(),
      _updatedAt: nowIso,
      customerId: payment.customerId,
      showId: payment.showId,
      stageId: payment.stageId,
      eventId: payment.eventId,
      orderMethod: payment.provider,
      orderPrice: payment.amount.toFixed(2),
      buySeats: payment.seatIds,
      isPast: false,
    });

    tx.update(paymentRef, {
      status: 'paid',
      ticketId: ticketRef.id,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

// ==============================================================================
// 3. SAĞLAYICI WEBHOOK'LARI
// ==============================================================================

/** iyzico, ödeme sonrası kullanıcının tarayıcısını `token` ile buraya POST eder. */
exports.iyzicoWebhook = onRequest({ secrets: ALL_PAYMENT_SECRETS }, async (req, res) => {
  const token = req.body?.token;
  if (!token) {
    res.status(400).send(landingHtml({ title: 'Hata', message: 'Eksik ödeme bilgisi.' }));
    return;
  }
  try {
    const { success, paymentId } = await iyzico.verifyAndGetStatus(token, {
      apiKey: IYZICO_API_KEY.value(),
      secretKey: IYZICO_SECRET_KEY.value(),
      baseUrl: IYZICO_BASE_URL.value(),
    });
    if (paymentId) await finalizePayment(paymentId, success, success ? null : 'iyzico ödeme başarısız.');
    res.status(200).send(
      landingHtml(
        success
          ? { title: 'Ödeme Alındı 🎉', message: 'Artık uygulamaya dönebilirsiniz, biletiniz hazırlanıyor.' }
          : { title: 'Ödeme Başarısız', message: 'Uygulamaya dönüp tekrar deneyebilirsiniz.' },
      ),
    );
  } catch (err) {
    console.error('iyzicoWebhook failed:', err);
    res.status(500).send(landingHtml({ title: 'Hata', message: 'Ödeme doğrulanamadı, lütfen destek ile iletişime geçin.' }));
  }
});

/** PayTR, panelde tanımlı "Bildirim URL" olarak buraya sunucu-sunucu POST eder. */
exports.paytrWebhook = onRequest({ secrets: ALL_PAYMENT_SECRETS }, async (req, res) => {
  try {
    const { success, paymentRef } = paytr.verifyNotification(req.body || {}, {
      merchantKey: PAYTR_MERCHANT_KEY.value(),
      merchantSalt: PAYTR_MERCHANT_SALT.value(),
    });
    // merchant_oid, createPaymentSession'da paymentId (Firestore doküman ID'si)
    // ile birebir aynı üretiliyor (paytr.js: alfasayısal karakterler
    // korunuyor) — bu yüzden doğrudan Payment doküman ID'si olarak kullanılır.
    await finalizePayment(paymentRef, success, success ? null : 'PayTR ödeme başarısız.');
    res.status(200).send('OK'); // PayTR, "OK" dönmezse bildirimi tekrar dener.
  } catch (err) {
    console.error('paytrWebhook failed:', err);
    res.status(400).send('FAIL');
  }
});

/** Stripe, olay bazlı (event-based) webhook — imza doğrulaması ham body ister. */
exports.stripeWebhook = onRequest({ secrets: ALL_PAYMENT_SECRETS }, async (req, res) => {
  const signature = req.headers['stripe-signature'];
  try {
    const { success, paymentId } = stripeProvider.verifyWebhook(req.rawBody, signature, {
      secretKey: STRIPE_SECRET_KEY.value(),
      webhookSecret: STRIPE_WEBHOOK_SECRET.value(),
    });
    if (success !== null && paymentId) {
      await finalizePayment(paymentId, success, success ? null : 'Stripe ödeme başarısız.');
    }
    res.status(200).json({ received: true });
  } catch (err) {
    console.error('stripeWebhook signature/verify failed:', err);
    res.status(400).send(`Webhook Error: ${err.message}`);
  }
});

/** PayTR ok/fail ve Stripe success/cancel yönlendirmeleri için ortak, basit iniş sayfası. */
exports.paymentLanding = onRequest((req, res) => {
  const ok = req.query.status !== 'fail';
  res.status(200).send(
    landingHtml(
      ok
        ? { title: 'Ödeme Alındı 🎉', message: 'Artık uygulamaya dönebilirsiniz, biletiniz hazırlanıyor.' }
        : { title: 'Ödeme Tamamlanmadı', message: 'Uygulamaya dönüp tekrar deneyebilirsiniz.' },
    ),
  );
});

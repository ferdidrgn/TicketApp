/**
 * TiyatRol - Push bildirim Cloud Functions'ları.
 *
 * Bu fonksiyonlar Firestore'da yeni bir Campaign, Show veya Ticket dökümanı
 * oluşturulduğunda otomatik çalışır: hem uygulama-içi bildirim merkezi için
 * `Notification` koleksiyonuna bir kayıt ekler hem de gerçek bir FCM push
 * bildirimi gönderir.
 *
 * DEPLOY ETMEK İÇİN (bu dosyaları yazan ajan bunu SİZİN YERİNİZE YAPAMAZ,
 * çünkü Firebase CLI login + faturalandırma onayı gerektirir):
 *   1) Firebase projesini Blaze (kullandıkça öde) plana yükseltin
 *      (Cloud Functions'ı deploy edebilmek için zorunlu; Blaze'de de
 *      düşük trafikli bir uygulama için pratikte ücretsiz kotanın içinde
 *      kalırsınız).
 *   2) `cd functions && npm install`
 *   3) `firebase deploy --only functions`
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

// 💳 Ödeme sağlayıcı entegrasyonları (iyzico/PayTR/Stripe) — bkz.
// functions/payments/index.js. Gerçek API anahtarları eklenip
// `firebase functions:secrets:set` ile tanımlanana kadar bu fonksiyonlar
// 'PAYMENT_PROVIDER_NOT_CONFIGURED' hatası döner, deploy'u bozmaz.
const payments = require('./payments');
exports.createPaymentSession = payments.createPaymentSession;
exports.iyzicoWebhook = payments.iyzicoWebhook;
exports.paytrWebhook = payments.paytrWebhook;
exports.stripeWebhook = payments.stripeWebhook;
exports.paymentLanding = payments.paymentLanding;

// 🎁 Ücretsiz etkinlik bilet talebi (bkz. functions/freeTickets/index.js).
// SMS için Twilio'nun resmi "Trigger SMS" Firebase Extension'ının
// varsayılan `messages` koleksiyonunu kullanıyor.
const freeTickets = require('./freeTickets');
exports.claimFreeTicket = freeTickets.claimFreeTicket;

// 🎫 Kapıda bilet doğrulama / QR tarama (bkz. functions/tickets/index.js).
// Sadece admin/curator rolündeki hesaplar çağırabilir.
const tickets = require('./tickets');
exports.validateTicket = tickets.validateTicket;

const ALL_USERS_TOPIC = 'all_users';
const NOTIFICATION_COLLECTION = 'Notification';

/**
 * Uygulama-içi bildirim merkezine bir kayıt ekler ve `all_users` topic'ine
 * (tüm kullanıcılara, ücretsiz/limitsiz) gerçek bir push bildirimi gönderir.
 */
async function broadcastToAllUsers({ title, body, route, type }) {
  const db = getFirestore();

  await db.collection(NOTIFICATION_COLLECTION).add({
    title,
    body,
    route: route || null,
    type: type || 'general',
    targetUserId: 'all',
    readBy: [],
    _createdAt: FieldValue.serverTimestamp(),
  });

  await getMessaging().send({
    topic: ALL_USERS_TOPIC,
    notification: { title, body },
    data: { route: route || '' },
  });
}

/**
 * Sadece belirli bir kullanıcıya (kendi FCM token'ı üzerinden) bildirim
 * gönderir ve bildirim merkezine o kullanıcıya özel bir kayıt ekler.
 */
async function notifyUser({ userId, title, body, route, type }) {
  const db = getFirestore();

  await db.collection(NOTIFICATION_COLLECTION).add({
    title,
    body,
    route: route || null,
    type: type || 'general',
    targetUserId: userId,
    readBy: [],
    _createdAt: FieldValue.serverTimestamp(),
  });

  const userDoc = await db.collection('User').doc(userId).get();
  const token = userDoc.exists ? userDoc.data().fcmToken : null;
  if (!token) return;

  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: { route: route || '' },
    });
  } catch (err) {
    // Token artık geçersizse (uygulama silinmiş, çıkış yapılmış vb.)
    // tüm fonksiyonun çökmesini istemiyoruz — sadece logluyoruz.
    console.error(`FCM gönderimi başarısız (user: ${userId}):`, err);
  }
}

// 🎉 Yeni kampanya eklendiğinde herkese bildirim gönder.
exports.onCampaignCreated = onDocumentCreated(
  'Campaign/{campaignId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    await broadcastToAllUsers({
      title: 'Yeni Kampanya! 🎉',
      body: data.title || data.name || 'Yeni bir kampanya seni bekliyor.',
      route: '/campaign-details',
      type: 'campaign',
    });
  },
);

// 🎭 Yeni bir oyun/gösteri eklendiğinde herkese bildirim gönder.
exports.onShowCreated = onDocumentCreated('Show/{showId}', async (event) => {
  const data = event.data?.data();
  const showId = event.params.showId;
  if (!data) return;

  await broadcastToAllUsers({
    title: 'Yeni Oyun Sahnede! 🎭',
    body: `${data.name || 'Yeni bir oyun'} artık TiyatRol'de.`,
    route: `/show/${showId}`,
    type: 'show',
  });
});

// 🎫 Bilet satın alındığında SADECE o kullanıcıya bildirim gönder.
exports.onTicketCreated = onDocumentCreated(
  'Ticket/{ticketId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.customerId) return;

    await notifyUser({
      userId: data.customerId,
      title: 'Biletin Hazır! 🎫',
      body: 'Satın alma işlemin tamamlandı, biletin "Biletlerim" sayfasında seni bekliyor.',
      route: '/my-tickets/' + data.customerId,
      type: 'ticket',
    });
  },
);

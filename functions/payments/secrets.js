/**
 * Ödeme sağlayıcı sırları (Firebase Functions v2 Secret Manager).
 *
 * Hiçbir gerçek anahtar bu dosyada YOK ve olmamalı — sadece secret'ların
 * İSİMLERİ tanımlanıyor. Gerçek değerleri Firebase CLI ile ayarlarsınız:
 *
 *   firebase functions:secrets:set IYZICO_API_KEY
 *   firebase functions:secrets:set IYZICO_SECRET_KEY
 *   firebase functions:secrets:set IYZICO_BASE_URL   # örn: https://sandbox-api.iyzipay.com
 *
 *   firebase functions:secrets:set PAYTR_MERCHANT_ID
 *   firebase functions:secrets:set PAYTR_MERCHANT_KEY
 *   firebase functions:secrets:set PAYTR_MERCHANT_SALT
 *
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 *
 * Her komut sizden değeri terminalde (gizli girişle) ister, hiçbir yere
 * yazılmaz/commit edilmez. `firebase deploy --only functions` sırasında bu
 * fonksiyonlar bu secret'lara otomatik erişim alır.
 */

const { defineSecret } = require('firebase-functions/params');

const IYZICO_API_KEY = defineSecret('IYZICO_API_KEY');
const IYZICO_SECRET_KEY = defineSecret('IYZICO_SECRET_KEY');
const IYZICO_BASE_URL = defineSecret('IYZICO_BASE_URL');

const PAYTR_MERCHANT_ID = defineSecret('PAYTR_MERCHANT_ID');
const PAYTR_MERCHANT_KEY = defineSecret('PAYTR_MERCHANT_KEY');
const PAYTR_MERCHANT_SALT = defineSecret('PAYTR_MERCHANT_SALT');

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');

const ALL_PAYMENT_SECRETS = [
  IYZICO_API_KEY,
  IYZICO_SECRET_KEY,
  IYZICO_BASE_URL,
  PAYTR_MERCHANT_ID,
  PAYTR_MERCHANT_KEY,
  PAYTR_MERCHANT_SALT,
  STRIPE_SECRET_KEY,
  STRIPE_WEBHOOK_SECRET,
];

module.exports = {
  IYZICO_API_KEY,
  IYZICO_SECRET_KEY,
  IYZICO_BASE_URL,
  PAYTR_MERCHANT_ID,
  PAYTR_MERCHANT_KEY,
  PAYTR_MERCHANT_SALT,
  STRIPE_SECRET_KEY,
  STRIPE_WEBHOOK_SECRET,
  ALL_PAYMENT_SECRETS,
};

'use strict';
/**
 * TiyatRol güvenli bilet satış backend'i — Cloud Functions 2nd gen, Node 20, europe-west1.
 * Ayrıntı ve kurulum: docs/ODEME-GUVENLIK.md
 */
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret, defineString, defineBoolean } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const cfg = require('./src/config');
const { err } = require('./src/util');
const { createService } = require('./src/orders');
const { createProvider } = require('./providers');

if (!getApps().length) initializeApp();

// ---- Sırlar / parametreler (repoda anahtar YOK). Kurulum: docs/ODEME-GUVENLIK.md
const IYZICO_API_KEY = defineSecret('IYZICO_API_KEY');
const IYZICO_SECRET_KEY = defineSecret('IYZICO_SECRET_KEY');
const IYZICO_BASE_URL = defineString('IYZICO_BASE_URL', { default: 'https://sandbox-api.iyzipay.com' });
const SITE_URL = defineString('SITE_URL', { default: 'https://tiyatrol-web.web.app' });
const ENFORCE_APP_CHECK = defineBoolean('ENFORCE_APP_CHECK', { default: false });

const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
const origins = emulator ? [...cfg.ALLOWED_ORIGINS, /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/] : cfg.ALLOWED_ORIGINS;
const base = { region: cfg.REGION, cors: origins, maxInstances: 20 };

function callbackUrl() {
  const project = process.env.GCLOUD_PROJECT || 'ticketappflutter';
  return `https://${cfg.REGION}-${project}.cloudfunctions.net/iyzicoCallback`;
}

function getService(withSecrets) {
  return createService({
    db: getFirestore(),
    callbackUrl: callbackUrl(),
    siteUrl: SITE_URL.value(),
    allowedOrigins: cfg.ALLOWED_ORIGINS,
    log: logger,
    getProvider: (name) => {
      if (!withSecrets) return null;
      return createProvider(name, {
        apiKey: IYZICO_API_KEY.value(), secretKey: IYZICO_SECRET_KEY.value(), baseUrl: IYZICO_BASE_URL.value(),
      });
    },
  });
}

/** Ortak giriş kapısı: giriş zorunlu, (isteğe bağlı) App Check zorunlu, beklenmeyen hatalar sızdırılmaz. */
function guarded(fn) {
  return async (request) => {
    if (!request.auth || !request.auth.uid) throw err('unauthenticated', 'Devam etmek için giriş yapmalısınız.');
    if (ENFORCE_APP_CHECK.value() && !request.app) throw err('failed-precondition', 'Uygulama doğrulaması başarısız.');
    try {
      return await fn(request);
    } catch (e) {
      if (e && e.httpErrorCode) throw e; // HttpsError (Türkçe mesajlı, kullanıcıya gösterilebilir)
      logger.error('Beklenmeyen hata', { name: e && e.name, code: e && e.code }); // ayrıntı/PII loglanmaz
      throw err('internal', 'Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  };
}

exports.holdSeats = onCall(base, guarded((req) => getService(false).holdSeats(req.auth.uid, req.data)));
exports.releaseHold = onCall(base, guarded((req) => getService(false).releaseHold(req.auth.uid, req.data)));
exports.confirmFree = onCall(base, guarded((req) => getService(false).confirmFree(req.auth.uid, req.data)));
exports.confirmReservation = onCall(base, guarded((req) => getService(false).confirmReservation(req.auth.uid, req.data)));
exports.cancelTicket = onCall(base, guarded((req) => getService(false).cancelTicket(req.auth.uid, req.data)));
// Yönetici callable'ları: yetki sunucuda User/{uid}.role == 'admin' ile denetlenir.
exports.adminSetTicketStatus = onCall(base, guarded((req) => getService(false).adminSetTicketStatus(req.auth.uid, req.data)));
exports.adminCheckIn = onCall(base, guarded((req) => getService(false).adminCheckIn(req.auth.uid, req.data)));
exports.adminHealth = onCall(base, guarded((req) => getService(false).adminHealth(req.auth.uid)));
exports.startPayment = onCall({ ...base, secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY] },
  guarded((req) => getService(true).startPayment(req.auth.uid, req.data, {
    email: req.auth.token && req.auth.token.email,
    ip: req.rawRequest && req.rawRequest.ip,
  })));

/** iyzico dönüşü (tarayıcı POST). Sonuç SUNUCUDA token ile doğrulanır; yönlendirme her durumda 302. */
exports.iyzicoCallback = onRequest(
  { region: cfg.REGION, secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY], maxInstances: 20 },
  async (req, res) => {
    const site = SITE_URL.value().replace(/\/+$/, '');
    const go = (orderId, ok) => {
      const q = (orderId ? `order=${encodeURIComponent(orderId)}&` : '') + `durum=${ok ? 'basarili' : 'hata'}`;
      res.redirect(302, `${site}/odeme-sonuc?${q}`);
    };
    if (req.method !== 'POST') return go(null, false);
    try {
      const token = req.body && typeof req.body.token === 'string' ? req.body.token : '';
      const r = await getService(true).handleProviderCallback({ providerName: 'iyzico', token });
      return go(r.orderId, r.ok);
    } catch (e) {
      logger.error('iyzicoCallback hata', { name: e && e.name, code: e && e.code });
      return go(null, false);
    }
  });

/** Süresi dolan tutmaları serbest bırakır (ve kaçan ödemeleri sağlayıcıya sorarak kurtarır). */
exports.expireHolds = onSchedule(
  { region: cfg.REGION, schedule: 'every 5 minutes', timeZone: 'Europe/Istanbul', secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY], timeoutSeconds: 300 },
  async () => {
    const r = await getService(true).expireHolds();
    logger.info('expireHolds', r);
  });

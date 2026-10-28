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
const { getMessaging } = require('firebase-admin/messaging');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');

const cfg = require('./src/config');
const { err, makeAssertAdmin } = require('./src/util');
const { createService } = require('./src/orders');
const { createStats } = require('./src/stats');
const { createNotifier } = require('./src/notify');
const { createPhoneSync, resolvePhoneSalt } = require('./src/phone');
const { createAccountDeletion } = require('./src/accountDeletion');
const { deleteProfileImages } = require('./src/storage');
const { createProvider } = require('./providers');

if (!getApps().length) initializeApp();

// ---- Sırlar / parametreler (repoda anahtar YOK). Kurulum: docs/ODEME-GUVENLIK.md
const IYZICO_API_KEY = defineSecret('IYZICO_API_KEY');
const IYZICO_SECRET_KEY = defineSecret('IYZICO_SECRET_KEY');
const IYZICO_BASE_URL = defineString('IYZICO_BASE_URL', { default: 'https://sandbox-api.iyzipay.com' });
const SITE_URL = defineString('SITE_URL', { default: 'https://tiyatrol-web.web.app' });
// Telefon limit anahtarı tuzu. ÜRETİMDE MUTLAKA ayarlayın (docs/ODEME-GUVENLIK.md); sonradan DEĞİŞTİRİLİRSE tüm telefon sayaçları sıfırlanır.
const PHONE_HASH_SALT = defineString('PHONE_HASH_SALT', { default: '' });
const ENFORCE_APP_CHECK =defineBoolean('ENFORCE_APP_CHECK', { default: false });

const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
const origins = emulator ? [...cfg.ALLOWED_ORIGINS, /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/] : cfg.ALLOWED_ORIGINS;
const base = { region: cfg.REGION, cors: origins, maxInstances: 20 };

function callbackUrl() {
  const project = process.env.GCLOUD_PROJECT || 'ticketappflutter';
  return `https://${cfg.REGION}-${project}.cloudfunctions.net/iyzicoCallback`;
}

/**
 * Telefon limit tuzu. ÜRETİMDE PHONE_HASH_SALT (>=16 karakter) ZORUNLU: yoksa null döner ve telefon gerektiren tüm işlemler
 * FAIL-CLOSED reddedilir (depoda görünen zayıf tuzla sessizce çalışmaz; log'da yüksek sesle uyarılır). Sabit geliştirme tuzu
 * yalnızca emülatörde kullanılır.
 */
let saltUyarildi = false;
function phoneSalt() {
  const s = resolvePhoneSalt({ value: PHONE_HASH_SALT.value(), emulator, project: process.env.GCLOUD_PROJECT });
  if (s == null && !saltUyarildi) {
    saltUyarildi = true;
    logger.error('PHONE_HASH_SALT tanımsız ya da 16 karakterden kısa: bilet satışı ve telefon senkronu KAPALI. docs/ODEME-GUVENLIK.md "Telefon tuzu".');
  }
  return s;
}

/** Token'daki doğrulanmış telefon (E.164) — sunucunun TEK telefon kaynağı. */
const phoneCtx = (req) => ({ phone: req.auth && req.auth.token && req.auth.token.phone_number });

function getService(withSecrets) {
  return createService({
    phoneSalt: phoneSalt(),
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

function getDeletion() {
  return createAccountDeletion({
    db: getFirestore(), auth: getAuth(), orderService: getService(false), salt: phoneSalt(), log: logger,
    // Profil görseli: ppics/{uid}.* (ön ek; src/storage.js). Storage emülatörü yoksa emülatörde gerçek Google API'ye çıkılmaz.
    deleteProfileImage: async (uid) => {
      if (emulator && !process.env.FIREBASE_STORAGE_EMULATOR_HOST) return;
      await deleteProfileImages(getStorage().bucket(), uid);
    },
  });
}
function getStats() { return createStats({ db: getFirestore(), log: logger }); }
function getNotifier() {
  const db = getFirestore();
  return createNotifier({ db, messaging: getMessaging(), assertAdmin: makeAssertAdmin(db), log: logger });
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

exports.holdSeats = onCall(base, guarded((req) => getService(false).holdSeats(req.auth.uid, req.data, phoneCtx(req))));
exports.releaseHold = onCall(base, guarded((req) => getService(false).releaseHold(req.auth.uid, req.data)));
exports.confirmFree = onCall(base, guarded((req) => getService(false).confirmFree(req.auth.uid, req.data, phoneCtx(req))));
exports.confirmReservation = onCall(base, guarded((req) => getService(false).confirmReservation(req.auth.uid, req.data, phoneCtx(req))));
exports.cancelTicket = onCall(base, guarded((req) => getService(false).cancelTicket(req.auth.uid, req.data)));
// Telefon doğrulama senkronu: istemci giriş/telefon bağlama sonrası (getIdToken(true) ardından) çağırır. docs/TELEFON-DOGRULAMA.md
exports.syncPhoneVerification = onCall(base, guarded((req) =>
  createPhoneSync({ db: getFirestore(), salt: phoneSalt(), log: logger }).syncPhoneVerification(req.auth.uid, phoneCtx(req))));
// Hesap silme (30 gün bekleme). Ayrıntı/sözleşme: docs/HESAP-SILME.md
exports.requestAccountDeletion = onCall(base, guarded((req) => getDeletion().requestAccountDeletion(req.auth.uid, phoneCtx(req))));
exports.cancelAccountDeletion = onCall(base, guarded((req) => getDeletion().cancelAccountDeletion(req.auth.uid)));
exports.getAccountDeletionStatus = onCall(base, guarded((req) => getDeletion().getAccountDeletionStatus(req.auth.uid)));
exports.adminProcessAccountDeletions = onCall({ ...base, timeoutSeconds: 540, memory: '512MiB' }, guarded(async (req) => {
  await makeAssertAdmin(getFirestore())(req.auth.uid);
  return getDeletion().processDue();
}));
// Yönetici callable'ları: yetki sunucuda User/{uid}.role == 'admin' ile denetlenir.
exports.adminSetTicketStatus = onCall(base, guarded((req) => getService(false).adminSetTicketStatus(req.auth.uid, req.data)));
exports.adminCheckIn = onCall(base, guarded((req) => getService(false).adminCheckIn(req.auth.uid, req.data)));
exports.adminHealth = onCall(base, guarded((req) => getService(false).adminHealth(req.auth.uid)));
// İstatistik + bildirim (yönetici; yetki sunucuda). Ayrıntı: docs/BILDIRIM-ISTATISTIK.md
exports.adminStats = onCall({ ...base, timeoutSeconds: 120, memory: '512MiB' },
  guarded((req) => getStats().adminStats(makeAssertAdmin(getFirestore()), req.auth.uid, req.data)));
exports.adminCancelled = onCall(base, guarded((req) => getStats().adminCancelled(makeAssertAdmin(getFirestore()), req.auth.uid, req.data)));
exports.adminNotifyPreview = onCall(base, guarded((req) => getNotifier().adminNotifyPreview(req.auth.uid, req.data)));
exports.adminSendNotification = onCall({ ...base, timeoutSeconds: 300 }, guarded((req) => getNotifier().adminSendNotification(req.auth.uid, req.data)));
exports.startPayment = onCall({ ...base, secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY] },
  guarded((req) => getService(true).startPayment(req.auth.uid, req.data, {
    email: req.auth.token && req.auth.token.email,
    ...phoneCtx(req),
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

/**
 * Görüntülenme sayacı. Herkese açık ama: yalnız POST, izinli origin, bot UA'sı yok sayılır, IP hız sınırı (instance başına),
 * yalnız var olan Show/Player/Stage/Team kimliği sayılır. Çerez/IP/UA SAKLANMAZ. Yanıt her zaman gövdesiz (204) -> bilgi sızdırmaz.
 */
exports.trackView = onRequest({ region: cfg.REGION, cors: origins, maxInstances: 5, memory: '256MiB', timeoutSeconds: 10 }, async (req, res) => {
  try {
    const r = await getStats().trackView({
      method: req.method, body: req.body, ip: req.ip, ua: req.get('user-agent'), origin: req.get('origin'), allowedOrigins: origins,
    });
    res.status(r.status).end();
  } catch (e) {
    logger.error('trackView hata', { name: e && e.name, code: e && e.code });
    res.status(204).end(); // sayaç hatası ziyaretçiyi etkilemez
  }
});

/** Seansa ~24 saat ve ~2 saat kala biletlilere hatırlatma. Config/bildirim.autoReminders=false ile kapanır. Production'da Cloud Scheduler gerekir. */
exports.eventReminders = onSchedule(
  { region: cfg.REGION, schedule: 'every 15 minutes', timeZone: 'Europe/Istanbul', timeoutSeconds: 300 },
  async () => {
    const r = await getNotifier().eventReminders();
    logger.info('eventReminders', r);
  });

/** Süresi (30 gün) dolan hesap silme taleplerini işler. Günde 1 (03:00 TR). Production'da Cloud Scheduler (Blaze) gerekir. docs/HESAP-SILME.md */
exports.processAccountDeletions = onSchedule(
  { region: cfg.REGION, schedule: '0 3 * * *', timeZone: 'Europe/Istanbul', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    const r = await getDeletion().processDue();
    logger.info('processAccountDeletions', r);
  });

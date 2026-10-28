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
const { createTeam } = require('./src/team');
const { deleteProfileImages } = require('./src/storage');
const { createProvider } = require('./providers');

if (!getApps().length) initializeApp();

// ---- Sırlar / parametreler (repoda anahtar YOK). Kurulum: docs/ODEME-GUVENLIK.md
const IYZICO_API_KEY = defineSecret('IYZICO_API_KEY');
const IYZICO_SECRET_KEY = defineSecret('IYZICO_SECRET_KEY');
const IYZICO_BASE_URL = defineString('IYZICO_BASE_URL', { default: 'https://sandbox-api.iyzipay.com' });
const SITE_URL = defineString('SITE_URL', { default: 'https://tiyatrol.web.app' });
// Telefon limit anahtarı tuzu = SECRET MANAGER sırrı (GitHub Actions etkileşimsiz deploy edebilsin diye param DEĞİL).
// Kurulum (bir kez): `firebase functions:secrets:set PHONE_HASH_SALT --project ticketappflutter` (>=16 karakter, örn. `openssl rand -hex 32`).
// Sonradan DEĞİŞTİRİLİRSE tüm telefon sayaçları sıfırlanır. Tuzu okuyan HER fonksiyon `secrets: [PHONE_HASH_SALT]` almalıdır (aşağıda `salted`).
const PHONE_HASH_SALT = defineSecret('PHONE_HASH_SALT');
const ENFORCE_APP_CHECK =defineBoolean('ENFORCE_APP_CHECK', { default: false });

const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
const origins = emulator ? [...cfg.ALLOWED_ORIGINS, /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/] : cfg.ALLOWED_ORIGINS;
const base = { region: cfg.REGION, cors: origins, maxInstances: 20 };
// phoneSalt() çağıran her onCall (getService / getDeletion / syncPhoneVerification kullananlar) tuz sırrına bağlanır; yoksa üretimde .value() boş döner.
const salted = { ...base, secrets: [PHONE_HASH_SALT] };

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
  // Emülatörde sır, functions/.secret.local ya da ortamdan (PHONE_HASH_SALT) okunur; yoksa resolvePhoneSalt sabit geliştirme tuzunu verir.
  const raw = emulator ? process.env.PHONE_HASH_SALT || '' : PHONE_HASH_SALT.value();
  const s = resolvePhoneSalt({ value: raw, emulator, project: process.env.GCLOUD_PROJECT });
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

function getTeam() {
  return createTeam({ db: getFirestore(), auth: getAuth(), notifier: getNotifier(), log: logger });
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

exports.holdSeats = onCall(salted, guarded((req) => getService(false).holdSeats(req.auth.uid, req.data, phoneCtx(req))));
exports.releaseHold = onCall(salted, guarded((req) => getService(false).releaseHold(req.auth.uid, req.data)));
exports.confirmFree = onCall(salted, guarded((req) => getService(false).confirmFree(req.auth.uid, req.data, phoneCtx(req))));
exports.confirmReservation = onCall(salted, guarded((req) => getService(false).confirmReservation(req.auth.uid, req.data, phoneCtx(req))));
exports.cancelTicket = onCall(salted, guarded((req) => getService(false).cancelTicket(req.auth.uid, req.data)));
// Telefon doğrulama senkronu: istemci giriş/telefon bağlama sonrası (getIdToken(true) ardından) çağırır. docs/TELEFON-DOGRULAMA.md
exports.syncPhoneVerification = onCall(salted, guarded((req) =>
  createPhoneSync({ db: getFirestore(), salt: phoneSalt(), log: logger }).syncPhoneVerification(req.auth.uid, phoneCtx(req))));
// Hesap silme (30 gün bekleme). Ayrıntı/sözleşme: docs/HESAP-SILME.md
exports.requestAccountDeletion = onCall(salted, guarded((req) => getDeletion().requestAccountDeletion(req.auth.uid, phoneCtx(req))));
exports.cancelAccountDeletion = onCall(salted, guarded((req) => getDeletion().cancelAccountDeletion(req.auth.uid)));
exports.getAccountDeletionStatus = onCall(salted, guarded((req) => getDeletion().getAccountDeletionStatus(req.auth.uid)));
exports.adminProcessAccountDeletions = onCall({ ...salted, timeoutSeconds: 540, memory: '512MiB' }, guarded(async (req) => {
  await makeAssertAdmin(getFirestore())(req.auth.uid);
  return getDeletion().processDue();
}));
// Yönetici callable'ları: yetki sunucuda User/{uid}.role == 'admin' ile denetlenir.
exports.adminSetTicketStatus = onCall(salted, guarded((req) => getService(false).adminSetTicketStatus(req.auth.uid, req.data)));
exports.adminCheckIn = onCall(salted, guarded((req) => getService(false).adminCheckIn(req.auth.uid, req.data)));
exports.adminHealth = onCall(salted, guarded((req) => getService(false).adminHealth(req.auth.uid)));
// İstatistik + bildirim (yönetici; yetki sunucuda). Ayrıntı: docs/BILDIRIM-ISTATISTIK.md
exports.adminStats = onCall({ ...base, timeoutSeconds: 120, memory: '512MiB' },
  guarded((req) => getStats().adminStats(makeAssertAdmin(getFirestore()), req.auth.uid, req.data)));
exports.adminCancelled = onCall(base, guarded((req) => getStats().adminCancelled(makeAssertAdmin(getFirestore()), req.auth.uid, req.data)));
exports.adminNotifyPreview = onCall(base, guarded((req) => getNotifier().adminNotifyPreview(req.auth.uid, req.data)));
exports.adminSendNotification = onCall({ ...base, timeoutSeconds: 300 }, guarded((req) => getNotifier().adminSendNotification(req.auth.uid, req.data)));
// Ekip yöneticisi (admin DEĞİL; yalnız kendi ekibinin oyunu/seansı). Kapsam sunucuda hesaplanır, istemci teamId'si kabul edilmez. docs/EKIP-YONETICISI.md
exports.getMyManagedTeams = onCall({ ...base, timeoutSeconds: 60 }, guarded((req) => getTeam().getMyManagedTeams(req.auth.uid)));
exports.teamNotifyPreview = onCall(base, guarded((req) => getTeam().teamNotifyPreview(req.auth.uid, req.data)));
exports.teamSendNotification = onCall({ ...base, timeoutSeconds: 300 }, guarded((req) => getTeam().teamSendNotification(req.auth.uid, req.data)));
exports.teamCheckIn = onCall(base, guarded((req) => getTeam().teamCheckIn(req.auth.uid, req.data)));
exports.teamStats = onCall({ ...base, timeoutSeconds: 120 }, guarded((req) => getTeam().teamStats(req.auth.uid, req.data)));
exports.adminSetTeamManager = onCall(base, guarded((req) => getTeam().adminSetTeamManager(req.auth.uid, req.data)));
exports.startPayment = onCall({ ...base, secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY, PHONE_HASH_SALT] },
  guarded((req) => getService(true).startPayment(req.auth.uid, req.data, {
    email: req.auth.token && req.auth.token.email,
    ...phoneCtx(req),
    ip: req.rawRequest && req.rawRequest.ip,
  })));

/** iyzico dönüşü (tarayıcı POST). Sonuç SUNUCUDA token ile doğrulanır; yönlendirme her durumda 302. */
exports.iyzicoCallback = onRequest(
  { region: cfg.REGION, secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY, PHONE_HASH_SALT], maxInstances: 20 },
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
  { region: cfg.REGION, schedule: 'every 5 minutes', timeZone: 'Europe/Istanbul', secrets: [IYZICO_API_KEY, IYZICO_SECRET_KEY, PHONE_HASH_SALT], timeoutSeconds: 300 },
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
  { region: cfg.REGION, schedule: '0 3 * * *', timeZone: 'Europe/Istanbul', timeoutSeconds: 540, memory: '512MiB', secrets: [PHONE_HASH_SALT] },
  async () => {
    const r = await getDeletion().processDue();
    logger.info('processAccountDeletions', r);
  });

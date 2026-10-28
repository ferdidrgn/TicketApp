'use strict';
// Sabitler. Değiştirmek için kod değişikliği + deploy gerekir (bilinçli: istemci etkileyemez).
module.exports = {
  REGION: 'europe-west1',
  CURRENCY: 'TRY',
  SEAT_LIMIT_PER_EVENT: 3, // bir kullanıcı bir etkinlikte en fazla (reserved+sold) koltuk
  FREE_TICKET_LIMIT: 3, // TÜM ücretsiz etkinliklerde toplam bilet
  HOLD_MS: 10 * 60 * 1000, // koltuk tutma süresi
  PAYMENT_WINDOW_MS: 30 * 60 * 1000, // ödeme başlayınca tutma süresi (iyzico token ömrü)
  HOLD_RATE: { max: 8, windowMs: 60 * 1000 }, // kullanıcı başına dakikada hold denemesi
  MAX_SEAT_ID_LENGTH: 16,
  ADMIN_BLOCK_CUSTOMER_ID: '__ADMIN_BLOCKED__',
  EXPIRE_BATCH: 200,
  // Satış modu (Config/satis). 'kapali' | 'rezervasyon' (ödeme sahnede) | 'online' (iyzico). Belge yoksa varsayılan.
  SATIS_MODES: ['kapali', 'rezervasyon', 'online'],
  SATIS_DEFAULT: { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 },
  HEARTBEAT_STALE_MS: 15 * 60 * 1000, // expireHolds bu süredir çalışmadıysa panel kırmızı uyarır
  STUCK_GRACE_MS: 10 * 60 * 1000, // süresi bu kadar önce dolmuş ama hâlâ held/paying -> "takılı"

  // Bildirim (docs/BILDIRIM-ISTATISTIK.md)
  NOTIFY: {
    TOPIC_ALL: 'all_users', ALARM_CHANNEL: 'tiyatrol_alarm', DEFAULT_CHANNEL: 'tiyatrol_default', TITLE_MAX: 60, BODY_MAX: 240,
    RATE: { max: 30, windowMs: 60 * 60 * 1000 }, // yönetici başına saatlik gönderim
    TIMED_WINDOW_MS: 24 * 60 * 60 * 1000, // sahne şablonları yalnızca seanstan ±24 saat
    MULTICAST_CHUNK: 500, MAX_INAPP_ALL: 5000, MAX_TICKETS_SCAN: 20000,
    ALARM_TTL_MS: 2 * 60 * 1000, // alarm gecikirse anlamsız: 2 dk sonra düşer
    REMINDER_STALE_MS: 45 * 60 * 1000, // eventReminders bu süredir çalışmadıysa panel uyarır (zamanlama: 15 dk)
  },

  // Ekip yöneticisi (docs/EKIP-YONETICISI.md): yönetici başına ayrı sayaç (TeamLimits/{uid}).
  TEAM: {
    RATE_HOUR: { max: 10, windowMs: 60 * 60 * 1000 }, RATE_DAY: { max: 30, windowMs: 24 * 60 * 60 * 1000 },
    PER_TARGET: { max: 5, windowMs: 24 * 60 * 60 * 1000 }, // AYNI seansa/oyuna 24 saatte
    CHECKIN_WINDOW_MS: 24 * 60 * 60 * 1000, // kapı kontrolü yalnız seansa ±24 saat
    LIST_PAST_MS: 24 * 60 * 60 * 1000, LIST_FUTURE_MS: 90 * 24 * 60 * 60 * 1000, MAX_EVENTS_PER_SHOW: 40, MAX_SHOWS_PER_TEAM: 50,
  },

  // Doğrulanmış yorum + moderasyon (docs/UGC-KURALLARI.md)
  REVIEW: {
    TEXT_MAX: 600, DETAIL_MAX: 200, AUTO_HIDE_AT: 3, MAX_BLOCKS: 200, MAX_TICKETS_SCAN: 500,
    SUBMIT: { perHour: 5, perDay: 20 }, REPORT: { perHour: 10, perDay: 40 },
  },

  // Hesap silme (docs/HESAP-SILME.md)
  ACCOUNT_DELETION: {
    GRACE_MS: 30 * 24 * 60 * 60 * 1000, // bekleme süresi
    BATCH: 50, MAX_PER_RUN: 100, // zamanlanmış çalışmada yığın boyutu / üst sınır
    TIME_BUDGET_MS: 7 * 60 * 1000, // bir çalışmada en çok bu kadar işlenir (kalanı ertesi gün/elle)
    CLAIM_MS: 15 * 60 * 1000, // 'deleting' kilidi bu süre sonra yeniden alınabilir
    STALE_MS: 36 * 60 * 60 * 1000, // günlük iş bu süredir çalışmadıysa panel uyarır
    FAILING_AT: 3, // errorCount bu değere ulaşan kayıtlar adminHealth'te "hata veren" sayılır
    DOC_BATCH: 400, // anonimleştirme/silme batch boyutu (<=500)
  },

  // Etkinlik tarihi "gg.aa.yyyy,ss:dd" yerel (Türkiye, UTC+3, DST yok) saat olarak yazılır.
  TZ_OFFSET_MIN: 180,
  ALLOWED_ORIGINS: [
    'https://tiyatrol.web.app', 'https://tiyatrol.firebaseapp.com',
    'https://tiyatrol-web.web.app', 'https://tiyatrol-web.firebaseapp.com',
    'https://tiyatroekip.web.app', 'https://tiyatroekip.firebaseapp.com',
  ],
  // iyzico zorunlu alan: gerçek TCKN toplanmıyor (docs/ODEME-GUVENLIK.md, kalan riskler).
  IYZICO_PLACEHOLDER_IDENTITY: '11111111111',
};

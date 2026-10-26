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

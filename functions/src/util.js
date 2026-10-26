'use strict';
const { HttpsError } = require('firebase-functions/v2/https');
const cfg = require('./config');

const err = (code, msg) => new HttpsError(code, msg);

/** "250", "250,50", "1.250,50", "250.5" -> kuruş (tam sayı). Boş/0 -> 0. Geçersiz -> null. */
function parsePriceKurus(v) {
  if (v == null) return 0;
  let s = String(v).trim().replace(/\s|₺|TL|tl/g, '');
  if (s === '') return 0;
  if (s.includes('.') && s.includes(',')) s = s.replace(/\./g, '').replace(',', '.');
  else s = s.replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(s)) return null;
  const [t, k = ''] = s.split('.');
  const kurus = Number(t) * 100 + Number((k + '00').slice(0, 2));
  return Number.isSafeInteger(kurus) && kurus <= 100000000 ? kurus : null;
}

/** Event.date: Timestamp | "gg.aa.yyyy,ss:dd" | ISO (bölgesiz ise İstanbul saati). -> epoch ms | null */
function parseEventDateMs(v) {
  if (!v) return null;
  if (typeof v.toMillis === 'function') return v.toMillis();
  const s = String(v).trim();
  const tz = cfg.TZ_OFFSET_MIN * 60000;
  let m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})[,\s]+(\d{1,2}):(\d{2})/.exec(s);
  if (m) return Date.UTC(+m[3], +m[2] - 1, +m[1], +m[4], +m[5]) - tz;
  m = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$/.exec(s);
  if (m) return Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]) - tz;
  const d = Date.parse(s);
  return Number.isNaN(d) ? null : d;
}

const kurusToTl = (k) => k / 100;
const kurusStr = (k) => (k / 100).toFixed(2);

function validateId(v, name) {
  if (typeof v !== 'string' || v.length < 1 || v.length > 128 || v.includes('/')) {
    throw err('invalid-argument', `Geçersiz ${name}.`);
  }
  return v;
}

function validateSeatIds(v) {
  if (!Array.isArray(v) || v.length < 1) throw err('invalid-argument', 'En az bir koltuk seçmelisiniz.');
  if (v.length > cfg.SEAT_LIMIT_PER_EVENT) {
    throw err('resource-exhausted', `Bir etkinlikte en fazla ${cfg.SEAT_LIMIT_PER_EVENT} koltuk alabilirsiniz.`);
  }
  const seen = new Set();
  for (const s of v) {
    if (typeof s !== 'string' || s.length < 1 || s.length > cfg.MAX_SEAT_ID_LENGTH || !/^[A-Za-z0-9_-]+$/.test(s)) {
      throw err('invalid-argument', 'Geçersiz koltuk bilgisi.');
    }
    if (seen.has(s)) throw err('invalid-argument', 'Aynı koltuk birden fazla kez seçilemez.');
    seen.add(s);
  }
  return v;
}

/** Sunucuda yönetici denetimi: User/{uid}.role == 'admin'. İstemci kontrolü güvenlik sayılmaz. */
function makeAssertAdmin(db) {
  return async (uid) => {
    const u = await db.collection('User').doc(uid).get();
    if (!u.exists || u.data().role !== 'admin') throw err('permission-denied', 'Bu işlem için yönetici yetkisi gerekir.');
  };
}

module.exports = { makeAssertAdmin, err, parsePriceKurus, parseEventDateMs, kurusToTl, kurusStr, validateId, validateSeatIds };

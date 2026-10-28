'use strict';
/**
 * Bildirim tercihleri (docs/BILDIRIM-TERCIHLERI.md). Saf fonksiyonlar: Firestore/FCM bilmez, testi kolay.
 * Şema: User/{uid}.notifPrefs = { loudAlarm, reminders, changes, thankYou, newShows, marketing, quietStart, quietEnd }.
 */
const cfg = require('./config');

/** Kategori -> notifPrefs anahtarı. `announcement` ve `alarm` (sahne kumandası) tercihe bağlı DEĞİL. */
const CATEGORY_KEY = { change: 'changes', reminder: 'reminders', thankYou: 'thankYou', newShows: 'newShows', marketing: 'marketing' };
/** Anahtar varsayılanları (alan yok = varsayılan). */
const DEFAULTS = { loudAlarm: false, reminders: true, changes: true, thankYou: true, newShows: false, marketing: false };
/** Sessiz saatten muaf (işlemsel / canlı) kategoriler. */
const QUIET_EXEMPT = new Set(['change', 'announcement', 'alarm']);
/** Seansa bu kadar ya da daha az kala hatırlatma sessiz saatten muaftır. */
const NEAR_REMINDER_MS = 3 * 3600e3;

const HHMM = /^([01]\d|2[0-3]):([0-5]\d)$/;
const minutesOf = (s) => { const m = typeof s === 'string' && HHMM.exec(s); return m ? Number(m[1]) * 60 + Number(m[2]) : null; };

/** Geçerli bir map değilse boş sayılır; bilinmeyen/yanlış tipli değerler yok sayılır (okuma tarafı savunmacı). */
function normalize(prefs) {
  const p = prefs && typeof prefs === 'object' && !Array.isArray(prefs) ? prefs : {};
  const out = {};
  for (const k of Object.keys(DEFAULTS)) out[k] = typeof p[k] === 'boolean' ? p[k] : DEFAULTS[k];
  const qs = minutesOf(p.quietStart), qe = minutesOf(p.quietEnd);
  out.quietStart = qs != null && qe != null && qs !== qe ? p.quietStart : null; // ikisi birlikte geçerli olmalı
  out.quietEnd = out.quietStart ? p.quietEnd : null;
  return out;
}

/** İstanbul yerel saatinde gün içi dakika (0..1439). */
const localMinutes = (ms) => { const d = new Date(ms + cfg.TZ_OFFSET_MIN * 60000); return d.getUTCHours() * 60 + d.getUTCMinutes(); };

/** `ms` anı kullanıcının sessiz saati içinde mi? (gece yarısını aşan aralık desteklenir: 23:00-08:00) */
function inQuiet(prefs, ms) {
  const p = normalize(prefs);
  if (!p.quietStart) return false;
  const s = minutesOf(p.quietStart), e = minutesOf(p.quietEnd), m = localMinutes(ms);
  return s < e ? m >= s && m < e : m >= s || m < e;
}

/** Kategori anahtarı açık mı? Tercihe bağlı olmayan kategoriler (announcement, alarm) her zaman açık. */
function categoryEnabled(prefs, category) {
  const key = CATEGORY_KEY[category];
  return key ? normalize(prefs)[key] : true;
}

/**
 * Karar: { send, reason } — reason: 'ok' | 'category' (kapalı) | 'quiet' (sessiz saat; gönderim ertelenebilir).
 * opts.eventMs: hatırlatma için seans zamanı (<=3 sa kala sessiz saatten muaf).
 */
function decide(prefs, category, nowMs, opts = {}) {
  if (!categoryEnabled(prefs, category)) return { send: false, reason: 'category' };
  if (QUIET_EXEMPT.has(category)) return { send: true, reason: 'ok' };
  if (category === 'reminder' && opts.eventMs != null && opts.eventMs - nowMs <= NEAR_REMINDER_MS) return { send: true, reason: 'ok' };
  if (inQuiet(prefs, nowMs)) return { send: false, reason: 'quiet' };
  return { send: true, reason: 'ok' };
}

/** shouldSend(prefs, category, now) -> boolean (ayrıntı için decide). */
const shouldSend = (prefs, category, nowMs, opts) => decide(prefs, category, nowMs, opts).send;

/** Önizleme: kategori bazlı "kapatan" sayıları (kişi listesi YOK). prefsList: tercih nesneleri (belge/alan yoksa undefined). */
function summarize(prefsList, category, nowMs) {
  const byCategory = { changes: 0, reminders: 0, thankYou: 0, newShows: 0, marketing: 0 };
  let withQuietHours = 0, quietNow = 0;
  for (const raw of prefsList) {
    const p = normalize(raw);
    for (const k of Object.keys(byCategory)) if (!p[k]) byCategory[k] += 1;
    if (p.quietStart) withQuietHours += 1;
    if (inQuiet(raw, nowMs)) quietNow += 1;
  }
  const key = CATEGORY_KEY[category];
  return {
    category: category || null, of: prefsList.length, byCategory, withQuietHours,
    optedOut: key ? byCategory[key] : 0, // seçili kategoriyi kapatan
    quietNow: QUIET_EXEMPT.has(category) ? 0 : quietNow, // şu an sessiz saatte olup gönderimi atlanacak
    willSend: prefsList.filter((p) => decide(p, category, nowMs).send).length,
  };
}

module.exports = { CATEGORY_KEY, DEFAULTS, QUIET_EXEMPT, normalize, inQuiet, categoryEnabled, decide, shouldSend, summarize, HHMM };

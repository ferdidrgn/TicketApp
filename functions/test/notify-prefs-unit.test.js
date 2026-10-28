'use strict';
// notify-prefs.js saf fonksiyonları (emülatör GEREKMEZ). docs/BILDIRIM-TERCIHLERI.md
const { test } = require('node:test');
const assert = require('node:assert/strict');
const P = require('../src/notify-prefs');
const { durationMin, isCancelled, slugify } = require('../src/notify');

// İstanbul (UTC+3) saatinden epoch: 2026-10-28 HH:MM
const at = (h, m = 0) => Date.UTC(2026, 9, 28, h, m) - 3 * 3600e3;

test('varsayılanlar: alan yok -> reminders/changes/thankYou açık; newShows/marketing/loudAlarm kapalı', () => {
  for (const p of [undefined, null, {}, 'x', [], 5]) {
    const n = P.normalize(p);
    assert.deepEqual([n.reminders, n.changes, n.thankYou, n.newShows, n.marketing, n.loudAlarm], [true, true, true, false, false, false]);
    assert.equal(n.quietStart, null);
  }
  assert.equal(P.shouldSend({}, 'reminder', at(12)), true);
  assert.equal(P.shouldSend({}, 'newShows', at(12)), false);
  assert.equal(P.shouldSend({}, 'marketing', at(12)), false);
  assert.equal(P.shouldSend({ newShows: true }, 'newShows', at(12)), true);
});

test('yanlış tipli değerler yok sayılır (savunmacı okuma)', () => {
  const n = P.normalize({ reminders: 'hayır', changes: 0, newShows: 'true', quietStart: '25:00', quietEnd: '08:00' });
  assert.equal(n.reminders, true); assert.equal(n.changes, true); assert.equal(n.newShows, false);
  assert.equal(n.quietStart, null); // geçersiz saat -> sessiz saat yok
  assert.equal(P.normalize({ quietStart: '22:00' }).quietStart, null); // tek başına geçersiz
  assert.equal(P.normalize({ quietStart: '22:00', quietEnd: '22:00' }).quietStart, null); // sıfır uzunluk
});

test('sessiz saat: gece yarısını aşan ve aşmayan aralıklar, sınır değerleri (başlangıç dahil, bitiş hariç)', () => {
  const night = { quietStart: '23:00', quietEnd: '08:00' };
  assert.equal(P.inQuiet(night, at(23, 0)), true);
  assert.equal(P.inQuiet(night, at(2, 30)), true);
  assert.equal(P.inQuiet(night, at(7, 59)), true);
  assert.equal(P.inQuiet(night, at(8, 0)), false);
  assert.equal(P.inQuiet(night, at(12)), false);
  assert.equal(P.inQuiet(night, at(22, 59)), false);
  const day = { quietStart: '13:00', quietEnd: '15:30' };
  assert.equal(P.inQuiet(day, at(14)), true);
  assert.equal(P.inQuiet(day, at(15, 30)), false);
  assert.equal(P.inQuiet(day, at(12, 59)), false);
  assert.equal(P.inQuiet({}, at(3)), false);
});

test('kategori kuralları: kapalı -> category; sessiz saatte işlemsel muaf, keşif/teşekkür/uzak hatırlatma ertelenir', () => {
  const q = { quietStart: '23:00', quietEnd: '08:00', newShows: true, marketing: true };
  const now = at(2);
  assert.deepEqual(P.decide({ changes: false }, 'change', now), { send: false, reason: 'category' });
  assert.deepEqual(P.decide(q, 'change', now), { send: true, reason: 'ok' }); // işlemsel
  assert.deepEqual(P.decide(q, 'announcement', now), { send: true, reason: 'ok' });
  assert.deepEqual(P.decide(q, 'alarm', now), { send: true, reason: 'ok' });
  assert.deepEqual(P.decide(q, 'thankYou', now), { send: false, reason: 'quiet' });
  assert.deepEqual(P.decide(q, 'newShows', now), { send: false, reason: 'quiet' });
  assert.deepEqual(P.decide(q, 'marketing', now), { send: false, reason: 'quiet' });
  assert.deepEqual(P.decide(q, 'reminder', now, { eventMs: now + 23 * 3600e3 }), { send: false, reason: 'quiet' }); // 24 sa hatırlatma
  assert.deepEqual(P.decide(q, 'reminder', now, { eventMs: now + 2 * 3600e3 }), { send: true, reason: 'ok' }); // 2 sa hatırlatma muaf
  assert.deepEqual(P.decide({ reminders: false }, 'reminder', now, { eventMs: now + 3600e3 }), { send: false, reason: 'category' }); // muaf olsa da kapalı kategori
  assert.deepEqual(P.decide(q, 'thankYou', at(9)), { send: true, reason: 'ok' });
  // 'announcement' ve 'alarm' kapatılamaz
  assert.equal(P.categoryEnabled({ reminders: false, changes: false, thankYou: false }, 'announcement'), true);
  assert.equal(P.categoryEnabled({ reminders: false, changes: false, thankYou: false }, 'alarm'), true);
});

test('summarize: kategori bazlı kapatanlar, kişi listesi/kimlik içermez', () => {
  const list = [undefined, { reminders: false }, { newShows: true, quietStart: '23:00', quietEnd: '08:00' }, { thankYou: false, changes: false }];
  const s = P.summarize(list, 'thankYou', at(2));
  assert.equal(s.of, 4); assert.equal(s.optedOut, 1); assert.equal(s.byCategory.reminders, 1); assert.equal(s.byCategory.changes, 1);
  assert.equal(s.byCategory.newShows, 3); assert.equal(s.withQuietHours, 1); assert.equal(s.quietNow, 1); assert.equal(s.willSend, 2);
  assert.equal(P.summarize(list, 'change', at(2)).quietNow, 0); // işlemsel: sessiz saat etkilemez
  assert.deepEqual(Object.keys(s).sort(), ['byCategory', 'category', 'of', 'optedOut', 'quietNow', 'willSend', 'withQuietHours']);
});

test('yardımcılar: durationMin, isCancelled, slugify', () => {
  assert.equal(durationMin('90 dk'), 90); assert.equal(durationMin('2 saat'), 120); assert.equal(durationMin('1,5 saat'), 90);
  assert.equal(durationMin(''), 120); assert.equal(durationMin('1 dk'), 120); assert.equal(durationMin(undefined), 120);
  assert.equal(isCancelled({ cancelled: true }), true); assert.equal(isCancelled({ cancelled: 'Evet' }), true); assert.equal(isCancelled({ status: 'cancelled' }), true);
  assert.equal(isCancelled({ cancelled: 'hayır' }), false); assert.equal(isCancelled({}), false); assert.equal(isCancelled(null), false);
  assert.equal(slugify('Şeker Portakalı'), 'seker-portakali');
});

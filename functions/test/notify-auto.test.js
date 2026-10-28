'use strict';
// N-1 + N-2: tercih süzme, sessiz saat, seans iptal/erteleme tetikleyicisi, seans sonrası teşekkür, alarm2h. (Firestore EMÜLATÖRÜ)
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, clearDb, makeAdmin, expectCode, clock } = H;
const { makeNotifier, seedUser, seedTicket, tok } = require('./notify-helpers');

beforeEach(async () => { await clearDb(); });

const HOUR = 3600e3;
// 2026-10-28 23:30 İstanbul -> "gece" (sessiz saat 23:00-08:00 içinde)
const NIGHT = Date.UTC(2026, 9, 28, 23, 30) - 3 * HOUR;
const NOON = Date.UTC(2026, 9, 28, 12, 0) - 3 * HOUR;
const QUIET = { quietStart: '23:00', quietEnd: '08:00' };
const fmt = (ms) => {
  const d = new Date(ms + 3 * HOUR); const p = (n) => String(n).padStart(2, '0');
  return `${p(d.getUTCDate())}.${p(d.getUTCMonth() + 1)}.${d.getUTCFullYear()},${p(d.getUTCHours())}:${p(d.getUTCMinutes())}`;
};
const notifs = async (filter) => (await db.collection('Notification').get()).docs.map((d) => ({ id: d.id, ...d.data() })).filter(filter || (() => true));
const tickets = async () => (await db.collection('Ticket').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

/** specs: [{u, token, prefs, status, usedAt}] */
async function scene({ evMs, specs = [], eventId = 'ev1', showId = 'show1', duration = '90 dk', extraEvent = {} } = {}) {
  await db.collection('Event').doc(eventId).set({ _id: eventId, showId, stageId: 'stage1', date: fmt(evMs), price: '100', seats: {}, ...extraEvent });
  await db.collection('Show').doc(showId).set({ name: 'Hamlet', duration });
  await db.collection('Stage').doc('stage1').set({ name: 'Büyük Sahne' });
  for (const sp of specs) {
    await seedUser(sp.u, { token: sp.token, prefs: sp.prefs });
    await seedTicket({ customerId: sp.u, eventId, showId, paymentStatus: sp.status || 'pay_at_venue', orderMethod: 'venue', usedAt: sp.usedAt });
  }
}

// ============================================================ N-2: admin gönderimi + önizleme
test('önizleme: kategori bazlı kapatanlar sayı olarak döner, kimlik/kişi listesi içermez', async () => {
  const admin = await makeAdmin();
  const { n } = makeNotifier({ now: clock(NOON) });
  await scene({ evMs: NOON + 2 * HOUR, specs: [
    { u: 'kisi_a', token: tok(1) }, { u: 'kisi_b', token: tok(2), prefs: { thankYou: false, reminders: false } },
    { u: 'kisi_c', token: tok(3), prefs: { newShows: true, ...QUIET } }, { u: 'kisi_d' },
  ] });
  const pv = await n.adminNotifyPreview(admin, { target: { type: 'event', id: 'ev1' }, template: 'genel', title: 'T', body: 'B', category: 'newShows' });
  assert.equal(pv.prefs.category, 'newShows'); assert.equal(pv.prefs.of, 4);
  assert.equal(pv.prefs.optedOut, 3); // newShows varsayılan KAPALI: yalnız kisi_c açtı
  assert.equal(pv.prefs.byCategory.thankYou, 1); assert.equal(pv.prefs.byCategory.reminders, 1); assert.equal(pv.prefs.withQuietHours, 1);
  assert.equal(pv.loudAlarm.of, 3);
  const text = JSON.stringify(pv);
  for (const u of ['kisi_a', 'kisi_b', 'kisi_c', 'kisi_d', 'fcm_token']) assert.ok(!text.includes(u), `${u} sızdı`);
  const all = await n.adminNotifyPreview(admin, { target: { type: 'all' } });
  assert.equal(all.prefs, null); // konu hedefi: tercih bilinemez
});

test('serbest mesaj newShows/marketing: yalnız açanlara (push + kutu); "Tüm kullanıcılar" hedefi reddedilir; geçersiz kategori reddedilir', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  await scene({ evMs: NOON + 5 * HOUR, specs: [
    { u: 'u1', token: tok(1), prefs: { newShows: true } }, { u: 'u2', token: tok(2) }, { u: 'u3', token: tok(3), prefs: { newShows: true, ...QUIET } },
  ] });
  const base = { target: { type: 'show', id: 'show1' }, template: 'genel', title: 'Yeni oyun', body: 'Geliyor', confirm: true, category: 'newShows' };
  await expectCode(n.adminSendNotification(admin, { ...base, target: { type: 'all' } }), 'failed-precondition');
  await expectCode(n.adminSendNotification(admin, { ...base, category: 'foo' }), 'invalid-argument');
  assert.equal(msg.multicasts.length + msg.topics.length, 0);
  const r = await n.adminSendNotification(admin, base);
  assert.equal(r.recipients, 3); assert.equal(r.inApp, 2); // u2 kapalı: kutuya da yazılmaz
  assert.deepEqual(r.suppressed, { category: 1, quiet: 0 }); // u3 = 12:00'de sessiz saatte değil
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens).sort(), [tok(1), tok(3)]);
  assert.deepEqual((await notifs()).map((d) => d.userId).sort(), ['u1', 'u3']);
  const log = (await db.collection('NotificationLog').doc(r.logId).get()).data();
  assert.equal(log.category, 'newShows'); assert.deepEqual(log.suppressed, { category: 1, quiet: 0 });
  assert.ok(!JSON.stringify(log).includes('u1'));
});

test('sessiz saatte newShows gönderilmez (suppressed.quiet), işlemsel iptal şablonu sessiz saatte de gider; changes=false ise push yok ama kutu var', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier({ now: clock(NIGHT) });
  await scene({ evMs: NIGHT + 5 * HOUR, specs: [
    { u: 'u1', token: tok(1), prefs: { newShows: true, ...QUIET } }, { u: 'u2', token: tok(2), prefs: { changes: false, ...QUIET } }, { u: 'u3', token: tok(3), prefs: QUIET },
  ] });
  const r1 = await n.adminSendNotification(admin, { target: { type: 'show', id: 'show1' }, template: 'genel', title: 'Yeni', body: 'x', confirm: true, category: 'newShows' });
  assert.deepEqual(r1.suppressed, { category: 2, quiet: 1 }); assert.equal(msg.multicasts.length, 0);
  const r2 = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'iptal', title: 'İptal', body: 'Seans iptal.', confirm: true });
  assert.deepEqual(r2.suppressed, { category: 1, quiet: 0 }); // u2 changes kapalı; u1 + u3 sessiz saatte ama muaf
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens).sort(), [tok(1), tok(3)]);
  assert.equal((await notifs((d) => d.title === 'İptal')).length, 3); // iptal kutuya HER ZAMAN yazılır
});

test('duyuru (genel) ve sahne şablonları tercihe bağlı değil: tüm kategoriler kapalı olsa da gider', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier({ now: clock(NIGHT) });
  const off = { reminders: false, changes: false, thankYou: false, newShows: false, marketing: false, ...QUIET };
  await scene({ evMs: NIGHT + HOUR, specs: [{ u: 'u1', token: tok(1), prefs: off }] });
  await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'basladi', confirm: true });
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'u1' }, title: 'Genel', body: 'Duyuru' });
  assert.equal(msg.multicasts.length, 2);
});

// ============================================================ N-1a: iptal / erteleme tetikleyici
test('eventChanged iptal: aktif bilet sahiplerine bildirim; iptal/gelmedi dışlanır; idempotent; kişisel veri sızmaz', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  const evMs = NOON + 30 * HOUR;
  await scene({ evMs, specs: [
    { u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2), status: 'cancelled' }, { u: 'u3', token: tok(3), status: 'no_show' }, { u: 'u4' },
    { u: 'u5', token: tok(5), prefs: { changes: false } }, { u: 'u6', token: tok(6), prefs: QUIET },
  ] });
  const before = { showId: 'show1', stageId: 'stage1', date: fmt(evMs) };
  const after = { ...before, cancelled: 'evet' };
  const r = await n.eventChanged('ev1', before, after);
  assert.equal(r.template, 'iptal'); assert.equal(r.recipients, 4); assert.equal(r.newlyNotified, 4);
  assert.deepEqual(r.suppressed, { category: 1, quiet: 0 });
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens).sort(), [tok(1), tok(6)]);
  const docs = await notifs();
  assert.deepEqual(docs.map((d) => d.id).sort(), ['chg_iptal_ev1_u1', 'chg_iptal_ev1_u4', 'chg_iptal_ev1_u5', 'chg_iptal_ev1_u6']);
  assert.match(docs[0].title, /Hamlet seansı iptal edildi/); assert.match(docs[0].body, /iptal edildi/); assert.equal(docs[0].eventId, 'ev1');
  // ikinci kez (tetikleyici yeniden denemesi): hiçbir yeni bildirim/push yok
  const again = await n.eventChanged('ev1', before, after);
  assert.equal(again.duplicate, true); assert.equal(msg.multicasts.length, 1); assert.equal((await notifs()).length, 4);
  // günlük: yalnız sayılar
  const log = (await db.collection('NotificationLog').doc('chg_iptal_ev1').get()).data();
  assert.equal(log.status, 'done'); assert.equal(log.auto, true); assert.equal(log.sentBy, 'system'); assert.equal(log.newlyNotified, 4);
  const lt = JSON.stringify(log);
  for (const x of ['u1', 'u4', 'fcm_token']) assert.ok(!lt.includes(x), `${x} günlüğe sızdı`);
  assert.ok(!('phoneNumber' in log) && !('customerId' in log));
});

test('eventChanged iptal: yarım kalmış (sending) günlük yeniden denenince tamamlanır, daha önce bildirilenler tekrar bildirilmez', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  const evMs = NOON + 30 * HOUR;
  await scene({ evMs, specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2) }] });
  await db.collection('NotificationLog').doc('chg_iptal_ev1').set({ status: 'sending' });
  await db.collection('Notification').doc('chg_iptal_ev1_u1').set({ userId: 'u1', title: 'x', body: 'y' }); // u1 daha önce bildirilmiş (çökme anı)
  const r = await n.eventChanged('ev1', { showId: 'show1', date: fmt(evMs) }, { showId: 'show1', date: fmt(evMs), status: 'cancelled' });
  assert.equal(r.newlyNotified, 1); assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens), [tok(2)]);
  assert.equal((await db.collection('NotificationLog').doc('chg_iptal_ev1').get()).data().status, 'done');
});

test('eventChanged erteleme: ileri tarihe saat değişimi bildirilir; yeni saat farklıysa yeniden; aynı saate dönüş çift bildirim üretmez; geçmiş/ilgisiz değişiklik sessiz', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  const e0 = NOON + 30 * HOUR, e1 = NOON + 50 * HOUR, e2 = NOON + 70 * HOUR;
  await scene({ evMs: e0, specs: [{ u: 'u1', token: tok(1) }] });
  const mk = (ms, extra = {}) => ({ showId: 'show1', stageId: 'stage1', date: fmt(ms), ...extra });
  const r = await n.eventChanged('ev1', mk(e0), mk(e1));
  assert.equal(r.template, 'ertelendi'); assert.equal(msg.multicasts.length, 1);
  const d1 = (await notifs())[0];
  assert.match(d1.title, /ertelendi/); assert.match(d1.body, /Yeni tarih ve saat: \d\d\.\d\d\.\d{4} \d\d:\d\d/); assert.match(d1.body, /önceki:/);
  assert.equal((await n.eventChanged('ev1', mk(e0), mk(e1))).duplicate, true); assert.equal(msg.multicasts.length, 1);
  assert.equal((await n.eventChanged('ev1', mk(e1), mk(e2))).newlyNotified, 1); assert.equal(msg.multicasts.length, 2);
  // ilgisiz alan değişikliği (fiyat), aynı tarih, geçmişten ileri taşıma, geçmişe taşıma: sessiz
  assert.equal((await n.eventChanged('ev1', mk(e1), mk(e1, { price: '200' }))).skipped, 'no-change');
  assert.equal((await n.eventChanged('ev1', mk(NOON - 5 * HOUR), mk(e1))).skipped, 'no-change');
  assert.equal((await n.eventChanged('ev1', mk(e1), mk(NOON - 2 * HOUR))).skipped, 'no-change');
  // iptal edilmişken tarih değişimi bildirilmez; iptali geri almak da bildirim üretmez
  assert.equal((await n.eventChanged('ev1', mk(e1, { cancelled: true }), mk(e2, { cancelled: true }))).skipped, 'no-change');
  assert.equal((await n.eventChanged('ev1', mk(e1, { cancelled: true }), mk(e1))).skipped, 'no-change');
  assert.equal(msg.multicasts.length, 2);
  assert.equal((await n.eventChanged('ev1', null, mk(e1))).skipped, 'no-data');
});

test('eventChanged: bilet sahibi yoksa günlük sıfır alıcıyla kapanır, push yok', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  await scene({ evMs: NOON + 30 * HOUR, specs: [] });
  const r = await n.eventChanged('ev1', { showId: 'show1', date: fmt(NOON + 30 * HOUR) }, { showId: 'show1', date: fmt(NOON + 30 * HOUR), cancelled: true });
  assert.equal(r.recipients, 0); assert.equal(msg.multicasts.length, 0);
});

// ============================================================ hatırlatma: tercih + iptal + alarm2h
test('eventReminders: reminders=false -> kutu/push yok ama bilet işaretlenir; sessiz saatte 24 sa hatırlatma ertelenir (bayrak yok), sabah gönderilir', async () => {
  const c = clock(NIGHT);
  const { n, msg } = makeNotifier({ now: c });
  await scene({ evMs: NIGHT + 23 * HOUR, specs: [
    { u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2), prefs: { reminders: false } }, { u: 'u3', token: tok(3), prefs: QUIET },
  ] });
  const r1 = await n.eventReminders();
  assert.equal(r1.sent24, 1); assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens), [tok(1)]);
  assert.deepEqual((await notifs()).map((d) => d.id), ['rem24_ev1_u1']);
  const flags = Object.fromEntries((await tickets()).map((t) => [t.customerId, !!t.remind24At]));
  assert.deepEqual(flags, { u1: true, u2: true, u3: false }); // u3 ertelendi
  c.advance(9 * HOUR); // 08:30 -> sessiz saat bitti; seansa 14 sa kala -> 24 sa penceresinde değil
  assert.equal((await n.eventReminders()).sent24, 0);
});

test('eventReminders: sessiz saatten çıkınca (pencere içinde) ertelenen 24 sa hatırlatma gider; 2 sa hatırlatma sessiz saatten muaf', async () => {
  // seans 08:15'te, şimdi 23:30'dan 8 saat sonra 07:30'da değil: 24 sa penceresi (22-24 sa) için şimdi 23:30, seans yarın 22:00 (22.5 sa kala)
  const c = clock(NIGHT);
  const { n, msg } = makeNotifier({ now: c });
  await scene({ evMs: NIGHT + 22.5 * HOUR, specs: [{ u: 'u3', token: tok(3), prefs: QUIET }] });
  assert.equal((await n.eventReminders()).sent24, 0);
  c.advance(0.5 * HOUR); // hâlâ 00:00, sessiz; seans 22 sa kala sınırında
  assert.equal((await n.eventReminders()).sent24, 0);
  // 2 saat kala (seans 01:00'da, şimdi 23:30 -> 1.5 sa): sessiz saatte de gider
  await clearDb();
  const c2 = clock(NIGHT);
  const m2 = makeNotifier({ now: c2 });
  await scene({ evMs: NIGHT + 1.5 * HOUR, specs: [{ u: 'u3', token: tok(3), prefs: QUIET }] });
  assert.equal((await m2.n.eventReminders()).sent2, 1); assert.equal(m2.msg.multicasts.length, 1);
  assert.equal(msg.multicasts.length, 0);
});

test('eventReminders: iptal edilmiş seansa hatırlatma gitmez', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  await scene({ evMs: NOON + 23 * HOUR, specs: [{ u: 'u1', token: tok(1) }], extraEvent: { cancelled: 'evet' } });
  assert.equal((await n.eventReminders()).sent24, 0); assert.equal(msg.multicasts.length, 0);
});

test('alarm2h: bayrak KAPALI (varsayılan) -> 2 sa hatırlatma normal; AÇIK -> loudAlarm açık olan alarm kanalına, diğerleri normal kanala; 24 sa hatırlatma etkilenmez', async () => {
  const mk = async (conf) => {
    await clearDb();
    const r = makeNotifier({ now: clock(NOON) });
    if (conf) await db.collection('Config').doc('bildirim').set(conf);
    await scene({ evMs: NOON + 1.5 * HOUR, specs: [{ u: 'u1', token: tok(1), prefs: { loudAlarm: true } }, { u: 'u2', token: tok(2) }] });
    return r;
  };
  let { n, msg } = await mk(null);
  assert.equal((await n.eventReminders()).sent2, 2);
  assert.equal(msg.multicasts.length, 1); assert.equal(msg.multicasts[0].data.kind, 'normal'); assert.equal(msg.multicasts[0].android.priority, 'normal');
  ({ n, msg } = await mk({ alarm2h: true }));
  const r = await n.eventReminders();
  assert.equal(r.sent2, 2); assert.equal(r.alarm2h, true);
  assert.equal(msg.multicasts.length, 2);
  const loud = msg.multicasts.find((m) => m.android.notification.channelId === 'tiyatrol_alarm');
  const norm = msg.multicasts.find((m) => m.android.notification.channelId === 'tiyatrol_default');
  assert.deepEqual(loud.tokens, [tok(1)]); assert.deepEqual(norm.tokens, [tok(2)]); assert.equal(loud.data.kind, 'alarm');
  assert.equal((await notifs())[0].type, 'reminder'); // kutu türü değişmez
  // 24 sa hatırlatma alarm2h'ten etkilenmez
  await clearDb();
  const m3 = makeNotifier({ now: clock(NOON) });
  await db.collection('Config').doc('bildirim').set({ alarm2h: true });
  await scene({ evMs: NOON + 23 * HOUR, specs: [{ u: 'u1', token: tok(1), prefs: { loudAlarm: true } }] });
  await m3.n.eventReminders();
  assert.equal(m3.msg.multicasts[0].data.kind, 'normal');
});

// ============================================================ N-1b: teşekkür
test('teşekkür: yalnız kapıdan geçenlere (usedAt), kilit belgesi + bilet bayrağı, ikinci çalışma boş; rota yorum=1; iptal/gelmedi dışlanır', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  const used = new Date(NOON - 3 * HOUR);
  await scene({ evMs: NOON - 3.5 * HOUR, duration: '90 dk', specs: [
    { u: 'u1', token: tok(1), usedAt: used }, { u: 'u2', token: tok(2) }, { u: 'u3', token: tok(3), usedAt: used, status: 'cancelled' },
    { u: 'u4', token: tok(4), usedAt: used, status: 'no_show' }, { u: 'u5', usedAt: used }, { u: 'u6', token: tok(6), usedAt: used, prefs: { thankYou: false } },
  ] });
  const r = await n.eventReminders();
  assert.equal(r.thanked, 2); assert.equal(r.thankEvents, 1); // u1 (+ token'sız u5 kutuya)
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens), [tok(1)]);
  assert.equal(msg.multicasts[0].data.route, '/show/hamlet-show1?yorum=1'); assert.equal(msg.multicasts[0].data.eventId, 'ev1');
  assert.match(msg.multicasts[0].notification.title, /Hamlet nasıldı\?/);
  assert.deepEqual((await notifs((d) => d.id.startsWith('thank_'))).map((d) => d.id).sort(), ['thank_ev1_u1', 'thank_ev1_u5']);
  const flagged = (await tickets()).filter((t) => t.thankedAt).map((t) => t.customerId).sort();
  assert.deepEqual(flagged, ['u1', 'u5', 'u6']); // u6 kapalı: işaretlenir ama bildirilmez
  assert.equal((await db.collection('System').doc('thankYou_ev1').get()).exists, true);
  const again = await n.eventReminders();
  assert.equal(again.thanked, 0); assert.equal(msg.multicasts.length, 1);
});

test('teşekkür: eşzamanlı iki çalışma tek bildirim üretir (create kilidi)', async () => {
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  await scene({ evMs: NOON - 3.5 * HOUR, specs: [{ u: 'u1', token: tok(1), usedAt: new Date() }] });
  await Promise.all([n.eventReminders(), n.eventReminders()]);
  assert.equal((await notifs((d) => d.id.startsWith('thank_'))).length, 1);
  assert.equal(msg.multicasts.flatMap((m) => m.tokens).length, 1);
});

test('teşekkür: zaman penceresi — bitişten <1 sa ya da >12 sa sonra gönderilmez; iptal edilmiş seans için gönderilmez; Config.thankYou=false kapatır', async () => {
  const usedAt = new Date();
  // bitiş = başlangıç + 90 dk
  for (const [label, startAgo, extra] of [['0.5 sa önce bitti', 2 * HOUR, {}], ['13 sa önce bitti', 14.5 * HOUR, {}], ['iptal', 3.5 * HOUR, { extraEvent: { status: 'cancelled' } }]]) {
    await clearDb();
    const { n, msg } = makeNotifier({ now: clock(NOON) });
    await scene({ evMs: NOON - startAgo, specs: [{ u: 'u1', token: tok(1), usedAt }], ...extra });
    assert.equal((await n.eventReminders()).thanked, 0, label); assert.equal(msg.multicasts.length, 0, label);
  }
  await clearDb();
  const { n, msg } = makeNotifier({ now: clock(NOON) });
  await db.collection('Config').doc('bildirim').set({ thankYou: false });
  await scene({ evMs: NOON - 3.5 * HOUR, specs: [{ u: 'u1', token: tok(1), usedAt }] });
  assert.equal((await n.eventReminders()).thanked, 0); assert.equal(msg.multicasts.length, 0);
});

test('teşekkür: sessiz saatteki kullanıcı ertelenir (kilit/bayrak/done yok), sabah gönderilir; usedAt olmayan geçerli bilet yalnız Config.thankYouAll=true ile', async () => {
  const c = clock(NIGHT);
  const { n, msg } = makeNotifier({ now: c });
  const usedAt = new Date();
  await scene({ evMs: NIGHT - 3.5 * HOUR, specs: [{ u: 'u1', token: tok(1), usedAt }, { u: 'u2', token: tok(2), usedAt, prefs: QUIET }, { u: 'u3', token: tok(3) }] });
  assert.equal((await n.eventReminders()).thanked, 1);
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens), [tok(1)]);
  assert.equal((await db.collection('System').doc('thankYou_ev1').get()).exists, false); // u2 bekliyor -> iş bitmedi
  assert.equal((await notifs((d) => d.userId === 'u2')).length, 0);
  c.advance(9 * HOUR); // 08:30; "bitti" yaşı 9.5 sa < 12 sa
  assert.equal((await n.eventReminders()).thanked, 1);
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens), [tok(1), tok(2)]);
  assert.equal((await db.collection('System').doc('thankYou_ev1').get()).exists, true);
  // thankYouAll
  await clearDb();
  const m2 = makeNotifier({ now: clock(NOON) });
  await db.collection('Config').doc('bildirim').set({ thankYouAll: true });
  await scene({ evMs: NOON - 3.5 * HOUR, specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2), status: 'no_show' }] });
  assert.equal((await m2.n.eventReminders()).thanked, 1); assert.deepEqual(m2.msg.multicasts.flatMap((m) => m.tokens), [tok(1)]);
});

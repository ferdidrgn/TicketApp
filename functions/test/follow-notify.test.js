'use strict';
// F-1: takip -> yeni oyun/seans bildirimi (Firestore EMÜLATÖRÜ)
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { FieldValue } = require('firebase-admin/firestore');
const H = require('./helpers');
const { db, clearDb, clock } = H;
const { makeNotifier, seedUser, tok } = require('./notify-helpers');
const { createFollowNotifier, composeMessage, FOLLOW } = require('../src/follow-notify');

beforeEach(async () => { await clearDb(); });

const HOUR = 3600e3;
const NOON = Date.UTC(2026, 9, 28, 12, 0) - 3 * HOUR; // 28.10.2026 12:00 İstanbul
const NIGHT = Date.UTC(2026, 9, 28, 23, 30) - 3 * HOUR;
const fmt = (ms) => {
  const d = new Date(ms + 3 * HOUR); const p = (n) => String(n).padStart(2, '0');
  return `${p(d.getUTCDate())}.${p(d.getUTCMonth() + 1)}.${d.getUTCFullYear()},${p(d.getUTCHours())}:${p(d.getUTCMinutes())}`;
};
const ON = { newShows: true };
const nlog = { error() {}, info() {}, warn() {} };
function make(nowMs = NOON, ignoreSwitch = true) {
  const { n, msg } = makeNotifier({ now: clock(nowMs) });
  const f = createFollowNotifier({ db, notifier: n, now: clock(nowMs), log: nlog, ignoreSwitch });
  return { f, msg };
}
const inbox = async () => (await db.collection('Notification').get()).docs.map((d) => ({ id: d.id, ...d.data() }));
const sent = (msg) => msg.multicasts.reduce((s, m) => s + m.tokens.length, 0);
const follows = (uid, data) => db.collection('User').doc(uid).update(data);

/** Oyun: kadro p1,p2 (eski kadro p9); topluluk t1; sahne s1. Seans ev1. */
// Emülatördeki GERÇEK tetikleyicileri susturur (testler işlemi doğrudan, ignoreSwitch ile çağırır); aksi hâlde veriyi yazarken yarışırlar.
const QUIET_TRIGGERS = () => db.collection('Config').doc('bildirim').set({ autoReminders: true, followNotify: false });
async function scene({ evMs = NOON + 48 * HOUR, eventId = 'ev1', showId = 'show1', extraEvent = {}, cast = ['p1', 'p2'] } = {}) {
  await QUIET_TRIGGERS();
  await db.collection('Player').doc('p1').set({ firstName: 'Ayşe', lastName: 'Kaya' });
  await db.collection('Player').doc('p2').set({ firstName: 'Can', lastName: 'Demir' });
  await db.collection('Team').doc('t1').set({ name: 'Kuzey Topluluğu' });
  await db.collection('Stage').doc('s1').set({ name: 'Büyük Sahne' });
  await db.collection('Show').doc(showId).set({ name: 'Hamlet', nowPlayersId: cast, oldPlayersId: ['p9'], teamId: 't1', eventsId: [eventId] });
  await db.collection('Event').doc(eventId).set({ _id: eventId, showId, stageId: 's1', date: fmt(evMs), price: '100', seats: {}, ...extraEvent });
}

test('takipçi eşleşmesi: oyuncu/sahne/topluluk takipçisi bildirim alır; takip etmeyen ve eski kadro takipçisi almaz', async () => {
  const { f, msg } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  await seedUser('b', { token: tok(2), prefs: ON }); await follows('b', { favoriteStages: ['s1'] });
  await seedUser('c', { token: tok(3), prefs: ON }); await follows('c', { favoriteTeams: ['t1'] });
  await seedUser('d', { token: tok(4), prefs: ON });
  await seedUser('e', { token: tok(5), prefs: ON }); await follows('e', { favoritePlayers: ['p9'] });
  const r = await f.processEvent('ev1');
  assert.equal(r.ok, true); assert.equal(r.matched, 3);
  const ib = await inbox();
  assert.deepEqual(ib.map((x) => x.userId).sort(), ['a', 'b', 'c']);
  assert.match(ib.find((x) => x.userId === 'a').title, /Ayşe Kaya yeni bir oyunda/);
  assert.match(ib.find((x) => x.userId === 'a').body, /Hamlet/);
  assert.match(ib.find((x) => x.userId === 'b').title, /Takip ettiğin sahnede yeni seans: Hamlet/);
  assert.match(ib.find((x) => x.userId === 'c').title, /Kuzey Topluluğu yeni bir oyunda/);
  assert.equal(msg.multicasts.length, 3);
  for (const m of msg.multicasts) { assert.equal(m.data.route, '/show/hamlet-show1'); assert.equal(m.data.kind, 'normal'); }
  assert.ok((await db.collection('Event').doc('ev1').get()).data().followNotified);
});

test('newShows kapalı / yok iken HİÇ gitmez (ne push ne kutu)', async () => {
  const { f, msg } = make(); await scene();
  await seedUser('a', { token: tok(1) }); await follows('a', { favoritePlayers: ['p1'] });
  await seedUser('b', { token: tok(2), prefs: { newShows: false } }); await follows('b', { favoritePlayers: ['p1'] });
  await seedUser('c', { token: tok(3), prefs: { reminders: true } }); await follows('c', { favoritePlayers: ['p1'] });
  const r = await f.processEvent('ev1');
  assert.equal(r.matched, 0); assert.equal((await inbox()).length, 0); assert.equal(msg.multicasts.length, 0);
});

test('tek kullanıcıya tek mesaj: oyuncu+topluluk+sahne kesişiminde oyuncu mesajı (oyuncu > topluluk > sahne)', async () => {
  const { f, msg } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p2', 'p1'], favoriteTeams: ['t1'], favoriteStages: ['s1'] });
  await seedUser('b', { token: tok(2), prefs: ON }); await follows('b', { favoriteTeams: ['t1'], favoriteStages: ['s1'] });
  const r = await f.processEvent('ev1');
  assert.equal(r.matched, 2);
  const ib = await inbox();
  assert.equal(ib.length, 2);
  assert.match(ib.find((x) => x.userId === 'a').title, /^Ayşe Kaya/); // kadro sırasında p1 önce
  assert.match(ib.find((x) => x.userId === 'b').title, /^Kuzey Topluluğu/);
  assert.equal(sent(msg), 2);
});

test('idempotent: ikinci / eşzamanlı çalıştırma ve silinmiş bayrak çift bildirim üretmez', async () => {
  const { f, msg } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  await Promise.all([f.processEvent('ev1'), f.processEvent('ev1')]);
  assert.equal((await inbox()).length, 1); assert.equal(sent(msg), 1);
  assert.equal((await f.processEvent('ev1')).skipped, 'already');
  await db.collection('Event').doc('ev1').update({ followNotified: FieldValue.delete() }); // admin formu belgeyi ezerse
  await f.processEvent('ev1');
  assert.equal((await inbox()).length, 1); assert.equal(sent(msg), 1);
});

test('günlük üst sınır: kullanıcı başına en çok 3 takip bildirimi/gün; ertesi gün sıfırlanır', async () => {
  const { f } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  for (let i = 1; i <= 5; i += 1) {
    await db.collection('Show').doc(`sh${i}`).set({ name: `Oyun ${i}`, nowPlayersId: ['p1'], teamId: 't1' });
    await db.collection('Event').doc(`e${i}`).set({ showId: `sh${i}`, stageId: 's1', date: fmt(NOON + (24 + i) * HOUR) });
    await f.processEvent(`e${i}`);
  }
  assert.equal((await inbox()).length, 3);
  assert.equal((await db.collection('UserLimits').doc('a').get()).data().followCount, 3);
  const { f: f2 } = make(NOON + 25 * HOUR);
  await db.collection('Event').doc('e6').set({ showId: 'sh1', stageId: 's1', date: fmt(NOON + 90 * HOUR) });
  assert.equal((await f2.processEvent('e6')).inbox, 1);
});

test('aynı oyuna 24 saat içinde eklenen ikinci seans aynı kişiye ikinci bildirim yapmaz', async () => {
  const { f } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  await db.collection('Event').doc('ev2').set({ showId: 'show1', stageId: 's1', date: fmt(NOON + 72 * HOUR) });
  await f.processEvent('ev1');
  const r2 = await f.processEvent('ev2');
  assert.equal(r2.dupShow, 1); assert.equal((await inbox()).length, 1);
});

test('iptal / geçmiş / tarihsiz seans için gönderilmez; showId yoksa Show.eventsId yedeği; oyun yoksa atlanır', async () => {
  const { f } = make();
  await scene({ extraEvent: { cancelled: true } });
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  assert.equal((await f.processEvent('ev1')).skipped, 'cancelled');
  await db.collection('Event').doc('past').set({ showId: 'show1', date: fmt(NOON - 5 * HOUR) });
  assert.equal((await f.processEvent('past')).skipped, 'past');
  await db.collection('Event').doc('nodate').set({ showId: 'show1' });
  assert.equal((await f.processEvent('nodate')).skipped, 'past');
  await db.collection('Event').doc('orphan').set({ stageId: 's1', date: fmt(NOON + 30 * HOUR) });
  assert.equal((await f.processEvent('orphan')).skipped, 'no-show');
  assert.equal((await inbox()).length, 0);
  await db.collection('Show').doc('show1').update({ eventsId: ['ev1', 'bagli'] });
  await db.collection('Event').doc('bagli').set({ stageId: 's1', date: fmt(NOON + 30 * HOUR) });
  assert.equal((await f.processEvent('bagli')).inbox, 1);
});

test('sessiz saat: kutuya yazılır, push gitmez; token yoksa yalnız kutu', async () => {
  const { f, msg } = make(NIGHT); await scene({ evMs: NIGHT + 48 * HOUR });
  await seedUser('a', { token: tok(1), prefs: { newShows: true, quietStart: '23:00', quietEnd: '08:00' } }); await follows('a', { favoritePlayers: ['p1'] });
  await seedUser('b', { prefs: ON }); await follows('b', { favoritePlayers: ['p1'] });
  const r = await f.processEvent('ev1');
  assert.equal(r.inbox, 2); assert.equal(r.suppressed.quiet, 1); assert.equal(msg.multicasts.length, 0);
});

test('kişisel veri sızıntısı yok: günlükte uid/token/e-posta yok; mesaj URL içermez', async () => {
  const { f, msg } = make(); await scene();
  await seedUser('gizli_kisi', { token: tok(1), prefs: ON }); await follows('gizli_kisi', { favoritePlayers: ['p1'], email: 'x@y.z' });
  await f.processEvent('ev1');
  const logs = JSON.stringify((await db.collection('NotificationLog').get()).docs.map((d) => d.data()));
  for (const s of ['gizli_kisi', 'fcm_token', 'x@y.z']) assert.ok(!logs.includes(s), `${s} günlüğe sızdı`);
  const m = msg.multicasts[0];
  assert.ok(!/https?:|www\./i.test(`${m.notification.title} ${m.notification.body}`));
  assert.ok(!/gizli_kisi|x@y.z/.test(JSON.stringify({ n: m.notification, d: m.data })));
  const logDoc = (await db.collection('NotificationLog').doc('fol_ev1').get()).data();
  assert.equal(logDoc.category, 'newShows'); assert.equal(typeof logDoc.recipients, 'number'); assert.equal(logDoc.status, 'done');
});

test('5.000 takipçi üst sınırı: fazlası taranmaz ve truncated işaretlenir', async () => {
  const { f } = make(); await scene({ cast: ['p1'] });
  const w = db.bulkWriter();
  for (let i = 0; i < FOLLOW.MAX_FOLLOWERS + 40; i += 1) w.set(db.collection('User').doc(`u${String(i).padStart(5, '0')}`), { role: 'user', favoritePlayers: ['p1'], notifPrefs: ON });
  await w.close();
  const r = await f.processEvent('ev1');
  assert.equal(r.truncated, true); assert.equal(r.considered, FOLLOW.MAX_FOLLOWERS); assert.equal(r.inbox, FOLLOW.MAX_FOLLOWERS);
});

test('tetikleyici yardımcıları: yeni Event, showId bağlanması ve Show.eventsId eklenmesi; ilgisiz güncelleme atlanır', async () => {
  const { f } = make(); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  assert.equal((await f.onEventWritten('ev1', { showId: 'show1', price: '1' }, { showId: 'show1', price: '2' })).skipped, 'not-new');
  assert.equal((await f.onEventWritten('ev1', null, null)).skipped, 'deleted');
  assert.equal((await f.onShowWritten('show1', { eventsId: ['ev1'] }, { eventsId: ['ev1'], name: 'x' })).skipped, 'no-new-events');
  assert.equal((await f.onEventWritten('ev1', { stageId: 's1' }, { stageId: 's1', showId: 'show1' })).inbox, 1);
  await db.collection('Event').doc('ev7').set({ showId: 'show1', stageId: 's1', date: fmt(NOON + 100 * HOUR) });
  assert.equal((await f.onShowWritten('show1', { eventsId: ['ev1'] }, { eventsId: ['ev1', 'ev7'] })).events, 1);
});

test('kapatma anahtarı: Config/bildirim.followNotify=false', async () => {
  const { f } = make(NOON, false); await scene();
  await seedUser('a', { token: tok(1), prefs: ON }); await follows('a', { favoritePlayers: ['p1'] });
  assert.equal((await f.processEvent('ev1')).skipped, 'disabled');
});

test('mesaj şablonu: kısa, URL yok, uzun adlar kırpılır', () => {
  const m = composeMessage('player', { oyuncu: 'A'.repeat(200), oyun: 'B'.repeat(300), sahne: 'S', ms: NOON });
  assert.ok(m.title.length <= 60 && m.body.length <= 240);
  assert.match(composeMessage('stage', { oyun: 'Hamlet', sahne: 'Büyük Sahne', ms: NOON }).title, /sahnede yeni seans/);
});

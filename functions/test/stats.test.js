'use strict';
// Görev 2: trackView (görüntülenme sayacı) + adminStats.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, clearDb, makeAdmin, expectCode, eventDate, clock, Timestamp } = H;
const { makeStats, seedTicket, seedUser } = require('./notify-helpers');
const { dayKey, monthKey } = require('../src/stats');

beforeEach(async () => { await clearDb(); });

const ORIGIN = 'https://tiyatrol-web.web.app';
const ALLOWED = [ORIGIN, 'https://tiyatrol.web.app'];
const UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1';
const req = (over = {}) => ({ method: 'POST', body: { k: 'show', id: 'show1' }, ip: '1.2.3.4', ua: UA, origin: ORIGIN, allowedOrigins: ALLOWED, ...over });
const dayDoc = async (t = Date.now()) => (await db.collection('Stats').doc('views').collection('days').doc(dayKey(t)).get()).data();
const monthDoc = async (t = Date.now()) => (await db.collection('Stats').doc('views').collection('months').doc(monthKey(t)).get()).data();

async function seedShows(...ids) { for (const id of ids) await db.collection('Show').doc(id).set({ name: `Oyun ${id}` }); }

// ------------------------------------------------------------------ trackView
test('trackView: geçerli istek gün + ay belgesine yazar (2 yazma), toplam + tür + kimlik alanları artar', async () => {
  const { s } = makeStats();
  await seedShows('show1');
  const r = await s.trackView(req());
  assert.equal(r.status, 204); assert.equal(r.writes, 2);
  await s.trackView(req());
  const d = await dayDoc(), m = await monthDoc();
  for (const x of [d, m]) { assert.equal(x.total, 2); assert.equal(x.show_total, 2); assert.equal(x.show_show1, 2); }
});

test('trackView: sayaç belgesinde yalnız sayılar var (IP/UA/çerez/kimlik SAKLANMAZ)', async () => {
  const { s } = makeStats();
  await seedShows('show1');
  await s.trackView(req({ ip: '9.9.9.9', ua: 'SecretAgent/1.0 (Mozilla)' }));
  const raw = JSON.stringify([await dayDoc(), await monthDoc()]);
  assert.ok(!raw.includes('9.9.9.9')); assert.ok(!raw.includes('SecretAgent'));
  for (const v of Object.values(await dayDoc())) assert.equal(typeof v, 'number');
});

test('trackView: 4 tür (show/player/stage/team) sayılır; geçersiz tür/kimlik 400; yöntem 405', async () => {
  const { s } = makeStats();
  await db.collection('Show').doc('s1').set({}); await db.collection('Player').doc('p1').set({});
  await db.collection('Stage').doc('g1').set({}); await db.collection('Team').doc('t1').set({});
  for (const [k, id] of [['show', 's1'], ['player', 'p1'], ['stage', 'g1'], ['team', 't1']]) assert.equal((await s.trackView(req({ body: { k, id } }))).writes, 2);
  const m = await monthDoc();
  assert.equal(m.total, 4); assert.equal(m.player_p1, 1); assert.equal(m.stage_total, 1);
  assert.equal((await s.trackView(req({ body: { k: 'order', id: 'x' } }))).status, 400);
  assert.equal((await s.trackView(req({ body: { k: 'show', id: 'a/b' } }))).status, 400);
  assert.equal((await s.trackView(req({ body: { k: 'show', id: 'x'.repeat(65) } }))).status, 400);
  assert.equal((await s.trackView(req({ body: { k: 'show', id: 'a.b' } }))).status, 400);
  assert.equal((await s.trackView(req({ body: { k: 'show' } }))).status, 400);
  assert.equal((await s.trackView(req({ body: '{bozuk' }))).status, 400);
  assert.equal((await s.trackView(req({ method: 'GET' }))).status, 405);
  assert.equal((await monthDoc()).total, 4);
});

test('trackView: text/plain (sendBeacon) gövdesi JSON dizgesi olarak kabul edilir', async () => {
  const { s } = makeStats();
  await seedShows('show1');
  assert.equal((await s.trackView(req({ body: JSON.stringify({ k: 'show', id: 'show1' }) }))).writes, 2);
});

test('trackView: bot UA, izinsiz/eksik origin, var olmayan kimlik sessizce yok sayılır (204, yazma yok)', async () => {
  const { s } = makeStats();
  await seedShows('show1');
  for (const ua of ['Googlebot/2.1', 'Mozilla/5.0 (compatible; bingbot/2.0)', 'curl/8.0', 'HeadlessChrome/120', 'python-requests/2.31', '']) {
    const r = await s.trackView(req({ ua })); assert.equal(r.status, 204); assert.equal(r.writes, undefined, ua);
  }
  assert.equal((await s.trackView(req({ origin: 'https://evil.example' }))).writes, undefined);
  assert.equal((await s.trackView(req({ origin: undefined }))).writes, undefined);
  assert.equal((await s.trackView(req({ body: { k: 'show', id: 'yok_boyle_oyun' } }))).writes, undefined);
  assert.equal(await monthDoc(), undefined);
});

test('trackView: IP hız sınırı (30/dk) ve aynı hedef sınırı (6/dk) aşılınca sessizce yok sayılır; dakika sonra açılır', async () => {
  const now = clock(Date.UTC(2026, 9, 26, 12, 0, 0));
  const { s } = makeStats({ now });
  await seedShows('hedef', ...Array.from({ length: 40 }, (_, i) => `o${i}`));
  const res = [];
  for (let i = 0; i < 8; i++) res.push((await s.trackView(req({ body: { k: 'show', id: 'hedef' } }))).writes);
  assert.deepEqual(res, [2, 2, 2, 2, 2, 2, undefined, undefined]);
  const s2 = makeStats({ now }).s;
  let counted = 0;
  for (let i = 0; i < 40; i++) if ((await s2.trackView(req({ ip: '7.7.7.7', body: { k: 'show', id: `o${i}` } }))).writes) counted += 1;
  assert.equal(counted, 30);
  assert.equal((await s2.trackView(req({ ip: '8.8.8.8', body: { k: 'show', id: 'o1' } }))).writes, 2); // başka IP etkilenmez
  now.advance(61e3);
  assert.equal((await s2.trackView(req({ ip: '7.7.7.7', body: { k: 'show', id: 'o2' } }))).writes, 2);
});

test('trackView: gün/ay anahtarı Europe/Istanbul\'a göre (UTC 21:30 = ertesi gün 00:30)', async () => {
  const t = Date.UTC(2026, 11, 31, 21, 30, 0);
  const { s } = makeStats({ now: () => t });
  await seedShows('show1');
  await s.trackView(req());
  assert.equal(dayKey(t), '2027-01-01'); assert.equal(monthKey(t), '2027-01');
  assert.equal((await dayDoc(t)).total, 1); assert.equal((await monthDoc(t)).total, 1);
});

// ------------------------------------------------------------------ adminStats
test('adminStats: yönetici değilse reddedilir; geçersiz ay reddedilir', async () => {
  const { s, assertAdmin } = makeStats();
  await seedUser('u1');
  await expectCode(s.adminStats(assertAdmin, 'u1', {}), 'permission-denied');
  await expectCode(s.adminStats(assertAdmin, 'yok', {}), 'permission-denied');
  const admin = await makeAdmin();
  await expectCode(s.adminStats(assertAdmin, admin, { month: '2026-13' }), 'invalid-argument');
  await expectCode(s.adminStats(assertAdmin, admin, { month: 'abc' }), 'invalid-argument');
});

test('adminStats: KPI, oyun tablosu, doluluk, mekân, trend ve dönüşüm değerleri', async () => {
  const { s, assertAdmin } = makeStats();
  const admin = await makeAdmin();
  await db.collection('Show').doc('A').set({ name: 'Oyun A' });
  await db.collection('Show').doc('B').set({ name: 'Oyun B' });
  await db.collection('Stage').doc('S1').set({ name: 'Sahne Bir' });
  await db.collection('Stage').doc('S2').set({ name: 'Sahne İki' });
  const seats = (sold, held, free, blocked = 0) => {
    const o = {}; let i = 0;
    for (let k = 0; k < sold; k++) o[`S${i++}`] = { status: 'sold', orderId: 'o' };
    for (let k = 0; k < held; k++) o[`S${i++}`] = { status: 'reserved', orderId: 'o' };
    for (let k = 0; k < free; k++) o[`S${i++}`] = { status: 'available' };
    for (let k = 0; k < blocked; k++) o[`S${i++}`] = { status: 'blocked' };
    return o;
  };
  await db.collection('Event').doc('e1').set({ showId: 'A', stageId: 'S1', date: eventDate(3 * 864e5), seats: seats(6, 1, 3, 2) }); // 6/10 (bloklu hariç)
  await db.collection('Event').doc('e2').set({ showId: 'A', stageId: 'S1', date: eventDate(-3 * 864e5), seats: seats(2, 0, 8) }); // geçmiş
  await db.collection('Event').doc('e3').set({ showId: 'B', stageId: 'S2', date: eventDate(5 * 864e5), seats: seats(0, 0, 4) });
  await db.collection('Show').doc('B').update({ eventsId: ['e3'] });
  // tohumlanmış biletler
  await seedTicket({ customerId: 'u1', eventId: 'e1', showId: 'A', orderMethod: 'venue', paymentStatus: 'pay_at_venue' });
  await seedTicket({ customerId: 'u2', eventId: 'e1', showId: 'A', orderMethod: 'venue', paymentStatus: 'paid', usedAt: Timestamp.now() });
  await seedTicket({ customerId: 'u3', eventId: 'e1', showId: 'A', orderMethod: 'venue', paymentStatus: 'cancelled' });
  await seedTicket({ customerId: 'u4', eventId: 'e1', showId: 'A', orderMethod: 'venue', paymentStatus: 'no_show' });
  await seedTicket({ customerId: 'u5', eventId: 'e3', showId: 'B', orderMethod: 'free', paymentStatus: 'free' });
  await seedTicket({ customerId: 'u6', eventId: 'e3', showId: 'B', orderMethod: 'free', paymentStatus: 'cancelled' });
  // görüntülenme (gerçek trackView ile)
  const { s: tv } = makeStats();
  for (let i = 0; i < 5; i++) await tv.trackView(req({ ip: `10.0.0.${i}`, body: { k: 'show', id: 'A' } }));
  for (let i = 0; i < 2; i++) await tv.trackView(req({ ip: `10.0.1.${i}`, body: { k: 'show', id: 'B' } }));
  await db.collection('Stage').doc('S1').set({ name: 'Sahne Bir' });
  await tv.trackView(req({ ip: '10.0.2.1', body: { k: 'stage', id: 'S1' } }));

  const r = await s.adminStats(assertAdmin, admin, {});
  assert.equal(r.month, monthKey(Date.now()));
  const k = r.kpi;
  assert.equal(k.viewsMonth, 8); assert.equal(k.showViewsMonth, 7);
  assert.equal(k.reservations.total, 3); // pay_at_venue, paid, no_show (iptal hariç)
  assert.equal(k.freeTickets.total, 1);
  assert.equal(k.ticketsAllTime, 6); assert.equal(k.cancelled, 2); assert.equal(k.ticketsActiveTotal, 4);
  assert.equal(k.cancelRate, 0.333); assert.equal(k.noShow, 1); assert.equal(k.noShowRate, 0.25);
  assert.equal(k.checkedIn, 1); assert.equal(k.checkInRate, 0.25);
  assert.equal(k.upcomingSessions, 2); assert.equal(k.activeShows, 2);
  const a = r.topShows.find((x) => x.showId === 'A');
  assert.equal(a.name, 'Oyun A'); assert.equal(a.views, 5); assert.equal(a.tickets, 3); // 4 bilet - 1 iptal
  assert.equal(a.sessions, 2); assert.equal(a.upcoming, 1);
  assert.equal(a.seatsSold, 8); assert.equal(a.seatsTotal, 10 + 10); assert.equal(a.occupancy, 0.4);
  assert.equal(r.topShows[0].showId, 'A'); // en çok görüntülenen başta
  const b = r.topShows.find((x) => x.showId === 'B'); // evShow yedek: e3.showId var
  assert.equal(b.tickets, 1);
  const e1 = r.sessions.find((x) => x.eventId === 'e1');
  assert.equal(e1.seatsSold, 6); assert.equal(e1.seatsHeld, 1); assert.equal(e1.seatsTotal, 10); assert.equal(e1.occupancy, 0.6); assert.equal(e1.show, 'Oyun A'); assert.equal(e1.stage, 'Sahne Bir');
  assert.equal(r.venues[0].stageId, 'S1');
  assert.equal(r.topStages[0].name, 'Sahne Bir');
  assert.equal(r.trend.months.length, 12); assert.equal(r.trend.months[11], r.month);
  assert.equal(r.trend.total[11], 8);
  assert.equal(r.trend.shows.find((x) => x.showId === 'A').values[11], 5);
  assert.equal(r.days.length, 1); assert.equal(r.days[0].views, 8);
  // dönüşüm: bu ay oluşan bilet / bu ay oyun görüntülenmesi (venue 4 + free 2 = 6 / 7)
  assert.equal(k.conversion, 0.857);
  assert.equal(a.conversion, 0.8); // A: 4 bilet (iptal dahil, bu ay) / 5 görüntülenme
});

test('adminStats: geçmiş ay seçimi o ayın sayaçlarını getirir', async () => {
  const { s, assertAdmin } = makeStats();
  const admin = await makeAdmin();
  await db.collection('Show').doc('A').set({ name: 'Oyun A' });
  await db.collection('Stats').doc('views').collection('months').doc('2026-03').set({ total: 40, show_total: 40, show_A: 40 });
  await db.collection('Stats').doc('views').collection('months').doc('2026-04').set({ total: 10, show_total: 10, show_A: 10 });
  await db.collection('Stats').doc('views').collection('days').doc('2026-03-05').set({ total: 15 });
  await db.collection('Stats').doc('views').collection('days').doc('2026-04-01').set({ total: 10 });
  const r = await s.adminStats(assertAdmin, admin, { month: '2026-03' });
  assert.equal(r.kpi.viewsMonth, 40); assert.deepEqual(r.days, [{ day: '2026-03-05', views: 15 }]);
  assert.equal(r.topShows[0].views, 40);
  const r4 = await s.adminStats(assertAdmin, admin, { month: '2026-04' });
  assert.equal(r4.kpi.viewsMonth, 10);
  assert.equal(r4.trend.shows[0].values[10], 40); assert.equal(r4.trend.shows[0].values[11], 10); // önceki ay trendde
});

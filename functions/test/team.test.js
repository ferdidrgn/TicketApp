'use strict';
// Ekip yöneticisi rolü (docs/EKIP-YONETICISI.md): kapsam, şablon/metin kuralları, limitler, kapı, istatistik, atama, hesap silme, sızıntı.
// Gerçek Firestore + Auth emülatörü; FCM sahte.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getAuth } = require('firebase-admin/auth');
const H = require('./helpers');
const { createTeam, freeTextProblem } = require('../src/team');
const { createAccountDeletion } = require('../src/accountDeletion');
const { fakeMessaging, makeNotifier, seedUser, seedTicket, tok } = require('./notify-helpers');
const { db, clearDb, makeAdmin, expectCode, eventDate, clock, Timestamp, TEST_SALT } = H;

const auth = getAuth();
const HOUR = 3600e3;
const silent = { error() {}, info() {}, warn() {} };

beforeEach(async () => { await clearDb(); });

function sut({ now, messaging } = {}) {
  const { n, msg } = makeNotifier({ now, messaging });
  const team = createTeam({ db, auth, notifier: n, now: now || Date.now, log: silent });
  return { team, msg, n };
}
const mkAuth = async (o) => { try { await auth.deleteUser(o.uid); } catch { /* yoktu */ } return auth.createUser(o); };
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };
const grant = (teamId, uid, status = 'active') => db.collection('TeamManager').doc(`${teamId}_${uid}`).set({ teamId, uid, status, addedBy: 'admin1', addedAt: Timestamp.now() });
let rid = 0;
const R = () => `req_${++rid}_${Math.random().toString(36).slice(2, 10)}`;
const send = (team, uid, extra) => team.teamSendNotification(uid, { confirm: true, requestId: R(), ...extra });

/** İki ekip, iki oyun, iki seans; A ekibinin seansında 3 bilet sahibi (tokenlı), B'nin seansında 1. mgrA/mgrB yönetici. */
async function world({ dateA = eventDate(HOUR), dateB = eventDate(HOUR) } = {}) {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' });
  await db.collection('Team').doc('tB').set({ name: 'Ekip B' });
  await db.collection('Stage').doc('st1').set({ name: 'Sahne 1' });
  await db.collection('Show').doc('sA').set({ name: 'Hamlet', teamId: 'tA', eventsId: ['eA'] });
  await db.collection('Show').doc('sB').set({ name: 'Macbeth', teamId: 'tB', eventsId: ['eB'] });
  await db.collection('Event').doc('eA').set({ _id: 'eA', showId: 'sA', stageId: 'st1', date: dateA, price: '100', seats: { A1: { status: 'sold', customerId: 'c1' }, A2: { status: 'sold', customerId: 'c2' }, A3: { status: 'reserved' }, A4: { status: 'available' }, A5: { status: 'blocked' } } });
  await db.collection('Event').doc('eB').set({ _id: 'eB', showId: 'sB', stageId: 'st1', date: dateB, price: '100', seats: { A1: { status: 'sold', customerId: 'c9' } } });
  await seedUser('mgrA', { name: 'Yonetici' }); await seedUser('mgrB', { name: 'Yonetici' });
  await grant('tA', 'mgrA'); await grant('tB', 'mgrB');
  const tickets = {};
  for (const [i, u] of ['c1', 'c2', 'c3'].entries()) {
    await seedUser(u, { token: tok(i + 1), name: 'Musteri' });
    tickets[u] = await seedTicket({ customerId: u, eventId: 'eA', showId: 'sA', paymentStatus: 'pay_at_venue' });
  }
  await seedUser('c9', { token: tok(9), name: 'Musteri' });
  tickets.c9 = await seedTicket({ customerId: 'c9', eventId: 'eB', showId: 'sB', paymentStatus: 'pay_at_venue' });
  await makeAdmin('admin1');
  return tickets;
}
const cevap = (e) => e.message;

// ------------------------------------------------------------------ POZİTİF
test('yönetici kendi seansına hazır şablon gönderir: yalnız o seansın aktif bilet sahipleri; log rol/ekip/oyun/seans taşır', async () => {
  await world();
  await seedUser('c4', { token: tok(4) }); await seedTicket({ customerId: 'c4', eventId: 'eA', showId: 'sA', paymentStatus: 'cancelled' }); // iptal -> alıcı değil
  const { team, msg } = sut();
  const r = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' });
  assert.equal(r.ok, true); assert.equal(r.recipients, 3); assert.equal(r.success, 3);
  assert.match(r.title, /Hamlet başladı/);
  const toks = msg.multicasts.flatMap((m) => m.tokens).sort();
  assert.deepEqual(toks, [tok(1), tok(2), tok(3)]);
  const log = await get('NotificationLog', r.logId);
  assert.equal(log.sentByRole, 'teamManager'); assert.equal(log.teamId, 'tA'); assert.equal(log.showId, 'sA'); assert.equal(log.eventId, 'eA'); assert.equal(log.sentBy, 'mgrA'); assert.equal(log.status, 'done');
  const inapp = (await db.collection('Notification').get()).docs.map((d) => d.data().userId).sort();
  assert.deepEqual(inapp, ['c1', 'c2', 'c3']);
});

test('sabit alarm şablonları (başlıyor / ara bitiyor) kind=alarm gider; metni sunucu üretir, istemci metni yok sayılır', async () => {
  await world();
  const { team, msg } = sut();
  const r = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'baslamak_uzere', params: { dk: 5 }, title: 'ISTEMCI', body: 'http://kotu.com' });
  assert.equal(r.kind, 'alarm'); assert.match(r.title, /5 dakika/); assert.ok(!/ISTEMCI|kotu/.test(r.body));
  assert.equal(msg.multicasts[0].data.kind, 'alarm');
  const r2 = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'ara_bitiyor' });
  assert.equal(r2.kind, 'alarm');
});

test('serbest metin (genel / iptal) normal olarak gider; oyun hedefi = oyunun yaklaşan seanslarının bilet sahipleri', async () => {
  await world();
  await db.collection('Event').doc('eA2').set({ _id: 'eA2', showId: 'sA', stageId: 'st1', date: eventDate(5 * 24 * HOUR), price: '100', seats: {} });
  await db.collection('Event').doc('eOld').set({ _id: 'eOld', showId: 'sA', stageId: 'st1', date: eventDate(-10 * 24 * HOUR), price: '100', seats: {} });
  await seedUser('c5', { token: tok(5) }); await seedTicket({ customerId: 'c5', eventId: 'eA2', showId: 'sA', paymentStatus: 'pay_at_venue' });
  await seedUser('c6', { token: tok(6) }); await seedTicket({ customerId: 'c6', eventId: 'eOld', showId: 'sA', paymentStatus: 'pay_at_venue' }); // geçmiş dönem -> kapsam dışı
  const { team, msg } = sut();
  const p = await team.teamNotifyPreview('mgrA', { target: { type: 'show', id: 'sA' }, template: 'genel', title: 'Duyuru', body: 'Kapılar 19:00da açılacak.' });
  assert.equal(p.recipients, 4); assert.equal(p.blocked, null);
  const r = await send(team, 'mgrA', { target: { type: 'show', id: 'sA' }, template: 'genel', title: 'Duyuru', body: 'Kapılar 19:00da açılacak.' });
  assert.equal(r.kind, 'normal'); assert.equal(r.recipients, 4);
  assert.deepEqual(msg.multicasts.flatMap((m) => m.tokens).sort(), [tok(1), tok(2), tok(3), tok(5)]);
  const r2 = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'iptal', body: 'Teknik nedenle seans iptal edildi.' });
  assert.match(r2.title, /iptal edildi/);
});

test('Event.showId boşsa Show.eventsId yedeği kullanılır (tek eşleşme)', async () => {
  await world();
  await db.collection('Event').doc('eA').update({ showId: '' });
  const { team } = sut();
  assert.equal(await team.resolveEventTeam('eA'), 'tA');
  const r = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' });
  assert.equal(r.recipients, 3);
});

test('aynı requestId ikinci kez gönderilmez (duplicate), push tekrarlanmaz', async () => {
  await world();
  const { team, msg } = sut();
  const id = R();
  const a = await team.teamSendNotification('mgrA', { confirm: true, requestId: id, target: { type: 'event', id: 'eA' }, template: 'basladi' });
  const b = await team.teamSendNotification('mgrA', { confirm: true, requestId: id, target: { type: 'event', id: 'eA' }, template: 'basladi' });
  assert.equal(a.duplicate, false); assert.equal(b.duplicate, true);
  assert.equal(msg.multicasts.length, 1);
});

test('getMyManagedTeams: yalnız yönetilen ekip/oyun/seanslar + doluluk; yetkisiz kullanıcıya boş liste; kişisel veri yok', async () => {
  await world();
  await seedUser('nobody');
  const { team } = sut();
  const r = await team.getMyManagedTeams('mgrA');
  assert.equal(r.teams.length, 1); assert.equal(r.teams[0].teamId, 'tA');
  assert.equal(r.teams[0].shows.length, 1); assert.equal(r.teams[0].shows[0].name, 'Hamlet');
  const ev = r.teams[0].shows[0].events[0];
  assert.equal(ev.eventId, 'eA'); assert.equal(ev.stage, 'Sahne 1'); assert.equal(ev.sold, 2); assert.equal(ev.held, 1); assert.equal(ev.total, 4); assert.equal(ev.inWindow, true);
  assert.ok(r.templates.every((t) => t.targets.every((x) => x === 'event' || x === 'show')));
  assert.deepEqual((await team.getMyManagedTeams('nobody')).teams, []);
  assert.ok(!JSON.stringify(r).includes('eB') && !JSON.stringify(r).includes('Macbeth'));
});

test('teamCheckIn: kendi seansının bileti geçer, ikinci kez "zaten"; müşteri adı/telefon/e-posta/uid DÖNMEZ; yanlış seans işaretlenmez', async () => {
  const t = await world();
  await db.collection('Event').doc('eA2').set({ _id: 'eA2', showId: 'sA', stageId: 'st1', date: eventDate(2 * HOUR), price: '100', seats: {} });
  const { team } = sut();
  const wrong = await team.teamCheckIn('mgrA', { ticketId: t.c1, eventId: 'eA2' });
  assert.equal(wrong.ok, false); assert.equal(wrong.wrongEvent, true);
  assert.equal((await get('Ticket', t.c1)).usedAt, undefined);
  const a = await team.teamCheckIn('mgrA', { ticketId: t.c1, eventId: 'eA' });
  assert.equal(a.ok, true); assert.equal(a.ticket.payAtVenue, true); assert.equal(a.ticket.code, t.c1);
  assert.ok((await get('Ticket', t.c1)).usedAt);
  const b = await team.teamCheckIn('mgrA', { ticketId: t.c1 });
  assert.equal(b.ok, false); assert.equal(b.already, true);
  const s = JSON.stringify([wrong, a, b]);
  for (const bad of ['c1', 'Musteri', 'firstName', 'customer', 'fcm_token', '@', '+90']) assert.ok(!s.includes(bad), `sızıntı: ${bad}`);
  await db.collection('Ticket').doc(t.c2).update({ paymentStatus: 'cancelled' });
  const c = await team.teamCheckIn('mgrA', { ticketId: t.c2 });
  assert.equal(c.ok, false); assert.equal(c.ticket.paymentStatus, 'cancelled');
});

test('teamStats: kendi oyun/seans sayıları (satılan/tutulan/doluluk/giriş); başka ekip istenemez', async () => {
  const t = await world();
  const { team } = sut();
  await team.teamCheckIn('mgrA', { ticketId: t.c1 });
  const r = await team.teamStats('mgrA', {});
  assert.equal(r.shows.length, 1);
  const e = r.shows[0].events[0];
  assert.deepEqual([e.sold, e.held, e.total, e.occupancy, e.activeTickets, e.checkedIn], [2, 1, 4, 50, 3, 1]);
  await expectCode(team.teamStats('mgrA', { teamId: 'tB' }), 'permission-denied');
  const s = JSON.stringify(r);
  for (const bad of ['c1', 'Musteri', 'Macbeth', 'eB']) assert.ok(!s.includes(bad), `sızıntı: ${bad}`);
});

// ------------------------------------------------------------------ NEGATİF: kapsam
test('başka ekibin seansı/oyunu: önizleme, gönderim, kapı, istatistik reddedilir; hiçbir push/log yok', async () => {
  const t = await world();
  const { team, msg } = sut();
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eB' }, template: 'basladi' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'show', id: 'sB' }, template: 'genel', title: 'a', body: 'b' }), 'permission-denied');
  await expectCode(team.teamNotifyPreview('mgrA', { target: { type: 'event', id: 'eB' } }), 'permission-denied');
  const e = await expectCode(team.teamCheckIn('mgrA', { ticketId: t.c9 }), 'not-found'); // başka ekibin bileti var/yok ayırt edilemez
  assert.match(e.message, /bulunamadı/);
  await expectCode(team.teamCheckIn('mgrA', { ticketId: 'olmayan_bilet_123' }), 'not-found');
  assert.equal(msg.multicasts.length, 0);
  assert.equal((await db.collection('NotificationLog').get()).size, 0);
  assert.equal((await get('Ticket', t.c9)).usedAt, undefined);
});

test('yetkisiz kullanıcı (hiç yönetici değil): her şey permission-denied, bilet var/yok sızmaz', async () => {
  const t = await world();
  await seedUser('nobody');
  const { team } = sut();
  await expectCode(send(team, 'nobody', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
  await expectCode(team.teamCheckIn('nobody', { ticketId: t.c1 }), 'permission-denied');
  await expectCode(team.teamCheckIn('nobody', { ticketId: 'yok_yok_yok_yok' }), 'permission-denied');
  await expectCode(team.teamStats('nobody', { teamId: 'tA' }), 'permission-denied');
  await expectCode(team.adminSetTeamManager('nobody', { teamId: 'tA', uid: 'nobody', action: 'add' }), 'permission-denied');
  await expectCode(team.adminSetTeamManager('mgrA', { teamId: 'tA', uid: 'nobody', action: 'add' }), 'permission-denied'); // yönetici kendi başına atama yapamaz
});

test('target all / user reddedilir', async () => {
  await world();
  const { team, msg } = sut();
  await expectCode(send(team, 'mgrA', { target: { type: 'all' }, template: 'genel', title: 'a', body: 'b' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'user', id: 'c1' }, template: 'genel', title: 'a', body: 'b' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'topic', id: 'x' }, template: 'genel', title: 'a', body: 'b' }), 'invalid-argument');
  await expectCode(send(team, 'mgrA', { target: {}, template: 'genel' }), 'invalid-argument');
  assert.equal(msg.topics.length + msg.multicasts.length, 0);
});

test('Show.teamId boş: yönetici reddedilir (fail-closed); admin yine yönetebilir', async () => {
  await world();
  await db.collection('Show').doc('sA').update({ teamId: '' });
  const { team } = sut();
  assert.equal(await team.resolveEventTeam('eA'), null);
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'show', id: 'sA' }, template: 'genel', title: 'a', body: 'b' }), 'permission-denied');
  const r = await send(team, 'admin1', { target: { type: 'event', id: 'eA' }, template: 'basladi' });
  assert.equal(r.recipients, 3);
  assert.equal((await get('NotificationLog', r.logId)).sentByRole, 'admin');
});

test('Event.showId ≠ Show.eventsId çakışması: Event.showId kazanır (B oyunun eventsId listesi A seansını içerse bile B yöneticisi giremez)', async () => {
  await world();
  await db.collection('Show').doc('sB').update({ eventsId: ['eB', 'eA'] });
  const { team } = sut();
  assert.equal(await team.resolveEventTeam('eA'), 'tA');
  await expectCode(send(team, 'mgrB', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
  await expectCode(team.teamCheckIn('mgrB', { ticketId: (await db.collection('Ticket').where('eventId', '==', 'eA').limit(1).get()).docs[0].id }), 'not-found');
  const r = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' });
  assert.equal(r.recipients, 3);
});

test('Event.showId boş + birden çok oyunun eventsId listesinde: belirsiz -> fail-closed', async () => {
  await world();
  await db.collection('Event').doc('eA').update({ showId: '' });
  await db.collection('Show').doc('sB').update({ eventsId: ['eB', 'eA'] });
  const { team } = sut();
  assert.equal(await team.resolveEventTeam('eA'), null);
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
  await expectCode(send(team, 'mgrB', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
});

test('istemci teamId göndermesi kapsamı değiştirmez (yok sayılır)', async () => {
  await world();
  const { team } = sut();
  await expectCode(send(team, 'mgrA', { teamId: 'tA', target: { type: 'event', id: 'eB', teamId: 'tA' }, template: 'basladi' }), 'permission-denied');
});

// ------------------------------------------------------------------ NEGATİF: şablon / metin
test('serbest alarm YOK: serbest metinli şablon kind=alarm reddedilir; alarm yalnız sabit şablonlarda', async () => {
  await world();
  const { team, msg } = sut();
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'Acil', body: 'Hemen gelin', kind: 'alarm' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'iptal', body: 'x', kind: 'alarm' }), 'permission-denied');
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, title: 'a', body: 'b' }), 'invalid-argument'); // şablonsuz serbest gönderim yok
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'yok_boyle' }), 'invalid-argument');
  assert.equal(msg.multicasts.length, 0);
  const p = await team.teamNotifyPreview('mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'a', body: 'b', kind: 'alarm' });
  assert.ok(p.blocked && !p.preview);
});

test('serbest metinde URL / wa.me / telefon / e-posta / @kullanıcı yasak; 60/240 sınırı', async () => {
  await world();
  const { team, msg } = sut();
  const bad = [
    'Detaylar http://x.com adresinde', 'Bak https://bit.ly/abc', 'www.biletsat.com a gelin', 'wa.me/905551112233', 'tiyatro.com a gel', 'Beni ara 0555 111 22 33', 'Ara: +90 (555) 111-22-33',
    '05551112233', 'bana yaz a@b.co', 'Insta @tiyatrolcom', 'hxxp://ok yok https://ok.io', 'tiyat​ro.com',
  ];
  for (const b of bad) {
    const e = await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'Duyuru', body: b }), 'invalid-argument');
    assert.ok(e.message.length > 5, b);
    const e2 = await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: b, body: 'ok' }), 'invalid-argument');
    assert.ok(e2.message.length > 5, b);
  }
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'x'.repeat(61), body: 'ok' }), 'invalid-argument');
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'ok', body: 'x'.repeat(241) }), 'invalid-argument');
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: '', body: '' }), 'invalid-argument');
  assert.equal(msg.multicasts.length, 0);
  // masum metinler geçer (saat, kısa sayılar, nokta)
  for (const ok of ['Kapılar 19.30da açılır. 2 kişilik yer ayrıldı.', 'Seans 20:00ye ertelendi, özür dileriz.', 'Sahne 3. kat, B blok']) {
    assert.equal(freeTextProblem(ok), null, ok);
  }
});

test('onay (confirm) ve requestId zorunlu', async () => {
  await world();
  const { team, msg } = sut();
  await expectCode(team.teamSendNotification('mgrA', { requestId: R(), target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'failed-precondition');
  await expectCode(team.teamSendNotification('mgrA', { confirm: true, target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'invalid-argument');
  await expectCode(team.teamSendNotification('mgrA', { confirm: true, requestId: 'kisa', target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'invalid-argument');
  assert.equal(msg.multicasts.length, 0);
});

test('±24 saat: seanstan uzaksa zamanlı şablon reddedilir (genel duyuru serbest); zamanlı şablon oyun hedefiyle olmaz', async () => {
  await world({ dateA: eventDate(3 * 24 * HOUR) });
  const { team } = sut();
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'failed-precondition');
  await expectCode(send(team, 'mgrA', { target: { type: 'show', id: 'sA' }, template: 'basladi' }), 'failed-precondition');
  const r = await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'Hatırlatma', body: 'Üç gün sonra görüşmek üzere.' });
  assert.equal(r.recipients, 3);
});

test('alıcı yoksa gönderilmez', async () => {
  await world();
  await db.collection('Event').doc('eEmpty').set({ _id: 'eEmpty', showId: 'sA', stageId: 'st1', date: eventDate(HOUR), price: '100', seats: {} });
  const { team } = sut();
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eEmpty' }, template: 'basladi' }), 'failed-precondition');
});

// ------------------------------------------------------------------ NEGATİF: limitler
test('limitler: aynı seansa 24 saatte 5; saatte 10; günde 30 (ayrı sayaç TeamLimits)', async () => {
  await world();
  const clk = clock(Date.now());
  const { team, msg } = sut({ now: clk });
  for (let i = 1; i <= 8; i++) {
    await db.collection('Event').doc(`x${i}`).set({ _id: `x${i}`, showId: 'sA', stageId: 'st1', date: eventDate(HOUR), price: '100', seats: {} });
    await seedTicket({ customerId: 'c1', eventId: `x${i}`, showId: 'sA', paymentStatus: 'pay_at_venue' });
  }
  const g = (id) => send(team, 'mgrA', { target: { type: 'event', id }, template: 'genel', title: 'Duyuru', body: `Mesaj ${rid}` });
  for (let i = 0; i < 5; i++) await g('eA');
  const e1 = await expectCode(g('eA'), 'resource-exhausted');
  assert.match(e1.message, /Aynı seansa/);
  for (let i = 0; i < 5; i++) await g('x1'); // saatte 10 doldu
  const e2 = await expectCode(g('x2'), 'resource-exhausted');
  assert.match(e2.message, /Saatlik/);
  const lim = await get('TeamLimits', 'mgrA');
  assert.equal(lim.hourCount, 10);
  assert.equal(msg.multicasts.length, 10);
  clk.advance(61 * 60e3);
  for (let i = 0; i < 5; i++) await g('x2'); for (let i = 0; i < 5; i++) await g('x3'); // 20
  clk.advance(61 * 60e3);
  for (let i = 0; i < 5; i++) await g('x4'); for (let i = 0; i < 5; i++) await g('x5'); // 30
  clk.advance(61 * 60e3);
  const e3 = await expectCode(g('x6'), 'resource-exhausted');
  assert.match(e3.message, /Günlük/);
  clk.advance(24 * HOUR);
  await g('x6'); // pencere açıldı
  // AYRI sayaç: başka yöneticinin limiti etkilenmez, admin sayacı (UserLimits) kullanılmaz
  assert.equal((await get('UserLimits', 'mgrA')), null);
  await db.collection('TeamManager').doc('tA_mgr2').set({ teamId: 'tA', uid: 'mgr2', status: 'active', addedBy: 'admin1' });
  await seedUser('mgr2');
  await send(team, 'mgr2', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'Duyuru', body: 'merhaba' });
});

test('yönetici gönderimi admin saatlik sayacını (UserLimits) ve admin gönderimlerini etkilemez; admin akışı bozulmaz', async () => {
  await world();
  const { team, n } = sut();
  await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' });
  const r = await n.adminSendNotification('admin1', { target: { type: 'event', id: 'eA' }, template: 'genel', title: 'Admin', body: 'mesaj', confirm: true });
  assert.equal(r.ok, true);
  const logs = (await db.collection('NotificationLog').get()).docs.map((d) => d.data());
  assert.equal(logs.length, 2);
  assert.equal(logs.filter((l) => l.sentByRole === 'teamManager').length, 1);
  assert.equal(logs.filter((l) => l.sentByRole === undefined).length, 1); // admin kayıtları eskisi gibi (rol alanı yok)
});

// ------------------------------------------------------------------ NEGATİF: iptal edilmiş / silinen hesap
test('revoked yönetici: tüm callable\'lar reddedilir, ekip listesi boş', async () => {
  const t = await world();
  const { team } = sut();
  await grant('tA', 'mgrA', 'revoked');
  await expectCode(send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }), 'permission-denied');
  await expectCode(team.teamNotifyPreview('mgrA', { target: { type: 'event', id: 'eA' } }), 'permission-denied');
  await expectCode(team.teamCheckIn('mgrA', { ticketId: t.c1 }), 'permission-denied');
  assert.deepEqual((await team.getMyManagedTeams('mgrA')).teams, []);
  assert.deepEqual((await team.teamStats('mgrA', {})).shows, []); // aktif ekip yok -> boş
});

test('hesap silme pending / deleting iken yönetici callable\'ları ACCOUNT_DELETION_PENDING ile reddedilir', async () => {
  const t = await world();
  const { team } = sut();
  for (const status of ['pending', 'deleting']) {
    await db.collection('AccountDeletion').doc('mgrA').set({ uid: 'mgrA', status, scheduledAt: Timestamp.fromMillis(Date.now() + 864e5) });
    const calls = [
      () => send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }),
      () => team.teamNotifyPreview('mgrA', { target: { type: 'event', id: 'eA' } }),
      () => team.getMyManagedTeams('mgrA'),
      () => team.teamCheckIn('mgrA', { ticketId: t.c1 }),
      () => team.teamStats('mgrA', {}),
    ];
    for (const f of calls) { const c = f(); const e = await expectCode(c, 'failed-precondition'); assert.equal(e.message, 'ACCOUNT_DELETION_PENDING'); }
  }
});

// ------------------------------------------------------------------ ADMİN ATAMA
test('adminSetTeamManager: e-postayla ekle (maskeli ipucu, telefon durumu), idempotent, geri al (silme yok), yeniden ekle; günlük tutulur', async () => {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' });
  await makeAdmin('admin1');
  const uid = 'newmgr1';
  await mkAuth({ uid, email: 'Yonetici.Biri@Example.com' });
  await db.collection('User').doc(uid).set({ role: 'user', firstName: 'Ayşe', lastName: 'Demir', isPhoneActive: true });
  const { team } = sut();
  const a = await team.adminSetTeamManager('admin1', { teamId: 'tA', email: ' yonetici.biri@example.com ', action: 'add' });
  assert.equal(a.status, 'active'); assert.equal(a.phoneActive, true); assert.equal(a.emailHint, 'y***@example.com'); assert.equal(a.already, false);
  const doc1 = await get('TeamManager', `tA_${uid}`);
  assert.equal(doc1.status, 'active'); assert.equal(doc1.addedBy, 'admin1'); assert.ok(doc1.addedAt);
  assert.equal((await get('User', uid)).role, 'user'); // role DEĞİŞMEZ
  assert.equal((await team.adminSetTeamManager('admin1', { teamId: 'tA', uid, action: 'add' })).already, true);
  const rv = await team.adminSetTeamManager('admin1', { teamId: 'tA', uid, action: 'revoke' });
  assert.equal(rv.status, 'revoked');
  const doc2 = await get('TeamManager', `tA_${uid}`);
  assert.equal(doc2.status, 'revoked'); assert.ok(doc2.revokedAt);
  assert.equal((await team.adminSetTeamManager('admin1', { teamId: 'tA', uid, action: 'revoke' })).already, true);
  await team.adminSetTeamManager('admin1', { teamId: 'tA', uid, action: 'add' });
  assert.equal((await get('TeamManager', `tA_${uid}`)).revokedAt, undefined);
  const logs = (await db.collection('TeamManagerLog').get()).docs.map((d) => d.data().action).sort();
  assert.deepEqual(logs, ['add', 'add', 'revoke']);
});

test('adminSetTeamManager: kayıtsız e-posta net hata; geçersiz e-posta/eylem; olmayan ekip; telefonsuz hesap da atanabilir (uyarılı)', async () => {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' });
  await makeAdmin('admin1');
  await mkAuth({ uid: 'nophone', email: 'team-nophone@example.com' });
  await db.collection('User').doc('nophone').set({ role: 'user', firstName: 'A', lastName: 'B' });
  const { team } = sut();
  const e = await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', email: 'yok.kimse@example.com', action: 'add' }), 'not-found');
  assert.match(e.message, /kayıtlı bir hesap yok/);
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', email: 'bozuk', action: 'add' }), 'invalid-argument');
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', email: 'team-nophone@example.com', action: 'sil' }), 'invalid-argument');
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', action: 'add' }), 'invalid-argument');
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tYok', email: 'team-nophone@example.com', action: 'add' }), 'not-found');
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', uid: 'nophone', action: 'revoke' }), 'not-found'); // hiç atanmamış
  const r = await team.adminSetTeamManager('admin1', { teamId: 'tA', email: 'team-nophone@example.com', action: 'add' });
  assert.equal(r.phoneActive, false); assert.equal(r.status, 'active');
  // silinme süreci bekleyen hesap atanamaz
  await mkAuth({ uid: 'leaving', email: 'leaving@example.com' });
  await db.collection('AccountDeletion').doc('leaving').set({ uid: 'leaving', status: 'pending', scheduledAt: Timestamp.fromMillis(Date.now() + 864e5) });
  await expectCode(team.adminSetTeamManager('admin1', { teamId: 'tA', uid: 'leaving', action: 'add' }), 'failed-precondition');
});

// ------------------------------------------------------------------ HESAP SİLME ENTEGRASYONU
test('yönetici hesabı silinince TeamManager belgeleri revoked + kişisel alanlar silinir; log/limit/NotificationLog takma adlanır', async () => {
  await db.collection('Team').doc('tA').set({ name: 'Ekip A' });
  await makeAdmin('admin1');
  await mkAuth({ uid: 'mgrDel', email: 'mgrdel@example.com' });
  await db.collection('User').doc('mgrDel').set({ role: 'user', firstName: 'Silinecek', lastName: 'Kişi', isPhoneActive: true });
  const { team } = sut();
  await team.adminSetTeamManager('admin1', { teamId: 'tA', email: 'mgrdel@example.com', action: 'add' });
  await db.collection('TeamLimits').doc('mgrDel').set({ hourCount: 2 });
  await db.collection('NotificationLog').doc('nl1').set({ sentBy: 'mgrDel', sentByName: 'Silinecek Kişi', sentByRole: 'teamManager', teamId: 'tA' });
  const del = createAccountDeletion({ db, auth, salt: TEST_SALT, log: silent, deleteProfileImage: async () => {} });
  await del.purge('mgrDel');
  const d = await get('TeamManager', 'tA_mgrDel');
  assert.equal(d.status, 'revoked'); assert.ok(d.revokedAt); assert.notEqual(d.uid, 'mgrDel');
  assert.equal(d.displayName, undefined); assert.equal(d.emailHint, undefined);
  assert.equal(await get('TeamLimits', 'mgrDel'), null);
  const nl = await get('NotificationLog', 'nl1');
  assert.equal(nl.sentByName, ''); assert.notEqual(nl.sentBy, 'mgrDel');
  const lg = (await db.collection('TeamManagerLog').get()).docs.map((x) => JSON.stringify(x.data()));
  assert.ok(lg.every((x) => !x.includes('mgrDel')));
  // admin silinirse addedBy takma adlanır
  await mkAuth({ uid: 'otherMgr', email: 'other@example.com' });
  await db.collection('User').doc('otherMgr').set({ role: 'user' });
  await team.adminSetTeamManager('admin1', { teamId: 'tA', uid: 'otherMgr', action: 'add' });
  await db.collection('User').doc('admin1').set({ role: 'user' }); // purge için gerekmez ama admin kaydı kalsın
  await del.purge('admin1');
  assert.notEqual((await get('TeamManager', 'tA_otherMgr')).addedBy, 'admin1');
});

// ------------------------------------------------------------------ SIZINTI: tüm yanıtlar
test('hiçbir yanıtta kişisel veri yok (ad, soyad, uid listesi, token, e-posta, telefon)', async () => {
  const t = await world();
  await db.collection('User').doc('c1').update({ eMail: 'musteri1@example.com', phoneNumber: '+905550000001' });
  const { team } = sut();
  const out = [];
  out.push(await team.getMyManagedTeams('mgrA'));
  out.push(await team.teamNotifyPreview('mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }));
  out.push(await team.teamNotifyPreview('mgrA', { target: { type: 'show', id: 'sA' }, template: 'genel', title: 'a', body: 'b' }));
  out.push(await send(team, 'mgrA', { target: { type: 'event', id: 'eA' }, template: 'basladi' }));
  out.push(await team.teamCheckIn('mgrA', { ticketId: t.c1 }));
  out.push(await team.teamStats('mgrA', {}));
  const s = JSON.stringify(out);
  for (const bad of ['c1"', 'c2"', 'c3"', 'c9', 'Musteri', 'musteri1', '+9055', 'fcm_token', 'customerId', 'firstName', 'lastName', 'mgrA', '"userIds"']) assert.ok(!s.includes(bad), `sızıntı: ${bad}`);
});

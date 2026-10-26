'use strict';
// Rezervasyon (ödeme sahnede) modu: Config/satis, confirmReservation, cancelTicket, yönetici işlevleri, kalp atışı.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, makeService, seedEvent, eventDate, uidN, expectCode, clock, clearDb, setSatis, makeAdmin } = H;

const REZ = { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 };
beforeEach(async () => { await clearDb(); });

const get = async (col, id) => (await db.collection(col).doc(id).get()).data();
const seatOf = async (ev, s) => (await get('Event', ev)).seats[s];
const lim = async (u) => (await get('UserLimits', u)) || {};

async function reserve(svc, u, ev, seatIds) {
  const h = await svc.holdSeats(u, { eventId: ev, seatIds });
  const r = await svc.confirmReservation(u, { orderId: h.orderId });
  return { ...h, ...r };
}

// ----------------------------------------------------------------- modlar
test('Config/satis yoksa varsayılan rezervasyon/3/24; startPayment reddedilir, rezervasyon çalışır', async () => {
  const { svc } = makeService({ satis: 'db' });
  const ev = await seedEvent({ price: '100' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  const e = await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' }), 'failed-precondition');
  assert.equal(e.message, 'Online ödeme şu anda çalışmıyor. Biletinizi rezervasyon olarak onaylayabilirsiniz.');
  const r = await svc.confirmReservation(u, { orderId: h.orderId });
  assert.deepEqual(r, { ticketIds: [h.orderId], status: 'rezervasyon' });
});

test('mod kapalı: startPayment ve confirmReservation reddedilir, yeni hold da alınamaz; Config her çağrıda okunur', async () => {
  const { svc } = makeService({ satis: 'db' });
  const ev = await seedEvent({ price: '100' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await setSatis({ ...REZ, mode: 'kapali' });
  await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' }), 'failed-precondition');
  await expectCode(svc.confirmReservation(u, { orderId: h.orderId }), 'failed-precondition');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A2'] }), 'failed-precondition');
  await setSatis(REZ); // yeniden açılınca aynı sipariş onaylanabilir
  assert.equal((await svc.confirmReservation(u, { orderId: h.orderId })).status, 'rezervasyon');
});

test('mod online: startPayment çalışır (iyzico kodu aynen), confirmReservation reddedilir', async () => {
  const { svc } = makeService({ satis: 'db' });
  await setSatis({ ...REZ, mode: 'online' });
  const ev = await seedEvent({ price: '100' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await expectCode(svc.confirmReservation(u, { orderId: h.orderId }), 'failed-precondition');
  const s = await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' });
  assert.equal(s.provider, 'iyzico'); assert.ok(s.token);
});

test('bozuk Config/satis değerleri varsayılana düşer', async () => {
  const { svc } = makeService({ satis: 'db' });
  await setSatis({ mode: 'bedava', rezervasyonLimit: 'x', iptalSaat: -5 });
  const ev = await seedEvent();
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' }), 'failed-precondition');
  assert.equal((await svc.confirmReservation(u, { orderId: h.orderId })).status, 'rezervasyon');
});

// ----------------------------------------------------------------- confirmReservation
test('confirmReservation: koltuk sold, tek bilet (id=orderId), sunucu tutarı, sayaç, bildirim; idempotent', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent({ price: '150' });
  const u = uidN();
  const r = await reserve(svc, u, ev, ['A1', 'A2']);
  const t = await get('Ticket', r.orderId);
  assert.equal(t.orderMethod, 'venue'); assert.equal(t.paymentStatus, 'pay_at_venue');
  assert.equal(t.orderPrice, '300.00'); assert.equal(t.customerId, u); assert.deepEqual(t.buySeats, ['A1', 'A2']);
  assert.equal((await seatOf(ev, 'A1')).status, 'sold'); assert.equal((await seatOf(ev, 'A1')).orderId, r.orderId);
  assert.equal((await lim(u)).reservations, 2);
  assert.equal((await get('Order', r.orderId)).status, 'reserved');
  const n = await get('Notification', `order_${r.orderId}`);
  assert.equal(n.userId, u); assert.match(n.title, /Rezervasyon/);
  // tekrar çağrı: yeni bilet/sayaç yok
  const again = await svc.confirmReservation(u, { orderId: r.orderId });
  assert.deepEqual(again, { ticketIds: [r.orderId], status: 'rezervasyon' });
  assert.equal((await lim(u)).reservations, 2);
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 1);
});

test('confirmReservation: ücretsiz / başkasının / süresi dolmuş / bırakılmış sipariş reddedilir', async () => {
  const now = clock();
  const { svc } = makeService({ now, satis: REZ });
  const free = await seedEvent({ price: '0' });
  const paid = await seedEvent({ price: '50', showId: 'show2' });
  const [a, b] = [uidN(), uidN()];
  const hf = await svc.holdSeats(a, { eventId: free, seatIds: ['A1'] });
  await expectCode(svc.confirmReservation(a, { orderId: hf.orderId }), 'invalid-argument');
  const hp = await svc.holdSeats(a, { eventId: paid, seatIds: ['A1'] });
  await expectCode(svc.confirmReservation(b, { orderId: hp.orderId }), 'permission-denied');
  await expectCode(svc.confirmReservation(a, { orderId: 'yok' }), 'not-found');
  await svc.releaseHold(a, { orderId: hp.orderId });
  await expectCode(svc.confirmReservation(a, { orderId: hp.orderId }), 'failed-precondition');
  const h2 = await svc.holdSeats(a, { eventId: paid, seatIds: ['A2'] });
  now.advance(11 * 60e3);
  await expectCode(svc.confirmReservation(a, { orderId: h2.orderId }), 'failed-precondition');
  assert.equal((await db.collection('Ticket').get()).size, 0);
});

test('rezervasyon limiti: tüm etkinliklerde toplam 3; 4. reddedilir (resource-exhausted)', async () => {
  const { svc } = makeService({ satis: REZ });
  const u = uidN();
  const evs = [];
  for (let i = 0; i < 4; i++) evs.push(await seedEvent({ showId: `s${i}` }));
  for (let i = 0; i < 3; i++) await reserve(svc, u, evs[i], ['A1']);
  const h = await svc.holdSeats(u, { eventId: evs[3], seatIds: ['A1'] });
  const e = await expectCode(svc.confirmReservation(u, { orderId: h.orderId }), 'resource-exhausted');
  assert.equal(e.message, 'Toplam en fazla 3 rezervasyon yapabilirsiniz.');
  assert.equal((await lim(u)).reservations, 3);
  assert.equal((await seatOf(evs[3], 'A1')).status, 'reserved'); // koltuk hâlâ yalnızca tutuluyor
  // iptal bir hak açar
  const t0 = (await db.collection('Ticket').where('customerId', '==', u).get()).docs[0].id;
  await svc.cancelTicket(u, { ticketId: t0 });
  assert.equal((await svc.confirmReservation(u, { orderId: h.orderId })).status, 'rezervasyon');
});

test('rezervasyonLimit Config\'den okunur (ör. 1)', async () => {
  const { svc } = makeService({ satis: { ...REZ, rezervasyonLimit: 1 } });
  const u = uidN();
  const [e1, e2] = [await seedEvent({ showId: 'x1' }), await seedEvent({ showId: 'x2' })];
  await reserve(svc, u, e1, ['A1']);
  const h = await svc.holdSeats(u, { eventId: e2, seatIds: ['A1'] });
  await expectCode(svc.confirmReservation(u, { orderId: h.orderId }), 'resource-exhausted');
});

test('eşzamanlı confirmReservation: limit aşılamaz', async () => {
  const { svc } = makeService({ satis: REZ });
  const u = uidN();
  const holds = [];
  for (let i = 0; i < 5; i++) holds.push(await svc.holdSeats(u, { eventId: await seedEvent({ showId: `c${i}` }), seatIds: ['A1'] }));
  const res = await Promise.allSettled(holds.map((h) => svc.confirmReservation(u, { orderId: h.orderId })));
  assert.equal(res.filter((r) => r.status === 'fulfilled').length, 3);
  assert.ok(res.filter((r) => r.status === 'rejected').every((r) => r.reason.code === 'resource-exhausted'));
  assert.equal((await lim(u)).reservations, 3);
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 3);
});

test('aynı siparişi eşzamanlı onaylamak tek bilet üretir', async () => {
  const { svc } = makeService({ satis: REZ });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: await seedEvent(), seatIds: ['A1', 'A2'] });
  const res = await Promise.allSettled([1, 2, 3].map(() => svc.confirmReservation(u, { orderId: h.orderId })));
  assert.ok(res.every((r) => r.status === 'fulfilled'));
  assert.equal((await lim(u)).reservations, 2);
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 1);
});

// ----------------------------------------------------------------- cancelTicket
test('cancelTicket: venue bilet iptali koltukları açar, sayacı düşürür; tekrar iptal idempotent', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent({ price: '100' });
  const [a, b] = [uidN(), uidN()];
  const r = await reserve(svc, a, ev, ['A1', 'A2']);
  assert.deepEqual(await svc.cancelTicket(a, { ticketId: r.orderId }), { ok: true });
  const t = await get('Ticket', r.orderId);
  assert.equal(t.paymentStatus, 'cancelled'); assert.ok(t.cancelledAt);
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
  assert.equal((await lim(a)).reservations, 0);
  assert.deepEqual(await svc.cancelTicket(a, { ticketId: r.orderId }), { ok: true });
  assert.equal((await lim(a)).reservations, 0, 'sayaç ikinci iptalde tekrar düşmez');
  // koltuk başkasına geçer; eski bilet artık o koltuğa dokunamaz
  const rb = await reserve(svc, b, ev, ['A1']);
  assert.equal((await seatOf(ev, 'A1')).orderId, rb.orderId);
  await svc.cancelTicket(a, { ticketId: r.orderId });
  assert.equal((await seatOf(ev, 'A1')).status, 'sold');
  assert.equal((await seatOf(ev, 'A1')).orderId, rb.orderId);
});

test('cancelTicket: iptal edilen biletin koltukları kullanıcının etkinlik koltuk limitine sayılmaz', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent({ seatNames: ['A1', 'A2', 'A3', 'A4', 'A5'] });
  const u = uidN();
  const r = await reserve(svc, u, ev, ['A1', 'A2', 'A3']);
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] }), 'resource-exhausted');
  await svc.cancelTicket(u, { ticketId: r.orderId });
  await svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] });
});

test('cancelTicket: iptal penceresi (iptalSaat) uygulanır ve Config\'den okunur', async () => {
  const ev = await seedEvent({ date: eventDate(10 * 3600e3) }); // 10 saat sonra
  const u = uidN();
  const { svc } = makeService({ satis: REZ });
  const r = await reserve(svc, u, ev, ['A1']);
  const e = await expectCode(svc.cancelTicket(u, { ticketId: r.orderId }), 'failed-precondition');
  assert.match(e.message, /24 saatten az/);
  assert.equal((await get('Ticket', r.orderId)).paymentStatus, 'pay_at_venue');
  assert.equal((await lim(u)).reservations, 1);
  const { svc: svc2 } = makeService({ satis: { ...REZ, iptalSaat: 2 } });
  assert.deepEqual(await svc2.cancelTicket(u, { ticketId: r.orderId }), { ok: true });
});

test('cancelTicket: ücretsiz bilet iptali freeTickets sayacını düşürür (limit açığı kapalı)', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent({ price: '0' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] });
  await svc.confirmFree(u, { orderId: h.orderId });
  assert.equal((await lim(u)).freeTickets, 3);
  assert.equal((await get('Ticket', h.orderId)).paymentStatus, 'free');
  const ev2 = await seedEvent({ price: '0', showId: 'f2' });
  await expectCode(svc.holdSeats(u, { eventId: ev2, seatIds: ['A1'] }), 'resource-exhausted');
  await svc.cancelTicket(u, { ticketId: h.orderId });
  assert.equal((await lim(u)).freeTickets, 0);
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
  const h2 = await svc.holdSeats(u, { eventId: ev2, seatIds: ['A1', 'A2', 'A3'] }); // yeniden hak
  await svc.confirmFree(u, { orderId: h2.orderId });
  assert.equal((await lim(u)).freeTickets, 3);
});

test('cancelTicket: başkasının bileti, bilinmeyen bilet, online ödenmiş bilet, kullanılmış bilet reddedilir', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent({ price: '100' });
  const [a, b] = [uidN(), uidN()];
  const r = await reserve(svc, a, ev, ['A1']);
  await expectCode(svc.cancelTicket(b, { ticketId: r.orderId }), 'permission-denied');
  await expectCode(svc.cancelTicket(a, { ticketId: 'yok' }), 'not-found');
  assert.equal((await get('Ticket', r.orderId)).paymentStatus, 'pay_at_venue');

  // online (kart) ile ödenmiş bilet
  const { svc: on, prov } = makeService({ satis: { mode: 'online' } });
  const ev2 = await seedEvent({ price: '100', showId: 'on' });
  const h = await on.holdSeats(a, { eventId: ev2, seatIds: ['A1'] });
  await on.startPayment(a, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' });
  prov.succeed(h.orderId, 100);
  assert.equal(await on.settle(h.orderId, await prov.retrieve({ token: `tok_${h.orderId}`, conversationId: h.orderId })), 'paid');
  assert.equal((await get('Ticket', h.orderId)).paymentStatus, 'paid');
  await expectCode(svc.cancelTicket(a, { ticketId: h.orderId }), 'failed-precondition');
  assert.equal((await seatOf(ev2, 'A1')).status, 'sold');

  // kapıdan geçmiş bilet
  const admin = await makeAdmin();
  await svc.adminCheckIn(admin, { ticketId: r.orderId });
  await expectCode(svc.cancelTicket(a, { ticketId: r.orderId }), 'failed-precondition');
});

// ----------------------------------------------------------------- admin
test('admin işlevleri admin olmayana ve tanımsız kullanıcıya kapalı', async () => {
  const { svc } = makeService({ satis: REZ });
  const ev = await seedEvent();
  const u = uidN();
  await db.collection('User').doc(u).set({ role: 'user' });
  const r = await reserve(svc, u, ev, ['A1']);
  for (const who of [u, 'hayalet']) {
    await expectCode(svc.adminSetTicketStatus(who, { ticketId: r.orderId, paymentStatus: 'paid' }), 'permission-denied');
    await expectCode(svc.adminCheckIn(who, { ticketId: r.orderId }), 'permission-denied');
    await expectCode(svc.adminHealth(who), 'permission-denied');
  }
  assert.equal((await get('Ticket', r.orderId)).paymentStatus, 'pay_at_venue');
  assert.equal((await get('Ticket', r.orderId)).usedAt, undefined);
});

test('adminSetTicketStatus: ödendi / gelmedi (sayaç düşer) / geri alma / iptal (koltuk açılır) / iptal yeniden açılmaz', async () => {
  const { svc } = makeService({ satis: REZ });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const u = uidN();
  const r = await reserve(svc, u, ev, ['A1', 'A2']);
  await expectCode(svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'bedava' }), 'invalid-argument');
  assert.deepEqual(await svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'paid' }), { ok: true, paymentStatus: 'paid' });
  assert.equal((await lim(u)).reservations, 2, 'ödendi hâlâ aktif rezervasyon');
  await svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'no_show' });
  assert.equal((await lim(u)).reservations, 0);
  await svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'pay_at_venue' });
  assert.equal((await lim(u)).reservations, 2);
  await svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'cancelled' });
  assert.equal((await lim(u)).reservations, 0);
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
  assert.ok((await get('Ticket', r.orderId)).cancelledAt);
  await expectCode(svc.adminSetTicketStatus(admin, { ticketId: r.orderId, paymentStatus: 'paid' }), 'failed-precondition');
  await expectCode(svc.adminSetTicketStatus(admin, { ticketId: 'yok', paymentStatus: 'paid' }), 'not-found');
});

test('adminSetTicketStatus: kart biletinde yalnızca gelmedi; ücretsiz biletin iptali freeTickets düşürür', async () => {
  const { svc, prov } = makeService({ satis: { mode: 'online' } });
  const admin = await makeAdmin();
  const u = uidN();
  const ev = await seedEvent({ price: '100' });
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' });
  prov.succeed(h.orderId, 100);
  await svc.settle(h.orderId, await prov.retrieve({ token: `tok_${h.orderId}`, conversationId: h.orderId }));
  await expectCode(svc.adminSetTicketStatus(admin, { ticketId: h.orderId, paymentStatus: 'cancelled' }), 'failed-precondition');
  await expectCode(svc.adminSetTicketStatus(admin, { ticketId: h.orderId, paymentStatus: 'pay_at_venue' }), 'failed-precondition');
  await svc.adminSetTicketStatus(admin, { ticketId: h.orderId, paymentStatus: 'no_show' });
  assert.equal((await get('Ticket', h.orderId)).paymentStatus, 'no_show');

  const fev = await seedEvent({ price: '0', showId: 'fr' });
  const fh = await svc.holdSeats(u, { eventId: fev, seatIds: ['A1', 'A2'] });
  await svc.confirmFree(u, { orderId: fh.orderId });
  assert.equal((await lim(u)).freeTickets, 2);
  await svc.adminSetTicketStatus(admin, { ticketId: fh.orderId, paymentStatus: 'cancelled' });
  assert.equal((await lim(u)).freeTickets, 0);
  assert.equal((await seatOf(fev, 'A1')).status, 'available');
});

test('adminCheckIn: ilk okuma geçerli, ikincisi already; iptal/gelmedi geçersiz; bilinmeyen not-found', async () => {
  const { svc } = makeService({ satis: REZ });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const u = uidN();
  await db.collection('User').doc(u).set({ role: 'user', firstName: 'Ayşe', lastName: 'Yılmaz' });
  const r = await reserve(svc, u, ev, ['A1', 'A2']);
  const c1 = await svc.adminCheckIn(admin, { ticketId: r.orderId });
  assert.equal(c1.ok, true); assert.equal(c1.already, undefined);
  assert.equal(c1.ticket.showName, 'Test Oyunu'); assert.equal(c1.ticket.stageName, 'Test Sahne');
  assert.deepEqual(c1.ticket.buySeats, ['A1', 'A2']); assert.equal(c1.ticket.paymentStatus, 'pay_at_venue');
  assert.equal(c1.ticket.customerName, 'Ayşe Yılmaz'); assert.ok(c1.ticket.usedAt);
  const c2 = await svc.adminCheckIn(admin, { ticketId: r.orderId });
  assert.equal(c2.ok, false); assert.equal(c2.already, true); assert.equal(c2.ticket.usedAt, c1.ticket.usedAt);

  const r2 = await reserve(svc, u, await seedEvent({ showId: 'k2' }), ['A1']);
  await svc.cancelTicket(u, { ticketId: r2.orderId });
  const c3 = await svc.adminCheckIn(admin, { ticketId: r2.orderId });
  assert.equal(c3.ok, false); assert.equal(c3.ticket.paymentStatus, 'cancelled');
  assert.equal((await get('Ticket', r2.orderId)).usedAt, undefined);
  await expectCode(svc.adminCheckIn(admin, { ticketId: 'yok' }), 'not-found');
});

test('eşzamanlı kapı okuması: yalnızca biri geçerli sayılır', async () => {
  const { svc } = makeService({ satis: REZ });
  const admin = await makeAdmin();
  const u = uidN();
  const r = await reserve(svc, u, await seedEvent(), ['A1']);
  const res = await Promise.all([1, 2, 3, 4].map(() => svc.adminCheckIn(admin, { ticketId: r.orderId })));
  assert.equal(res.filter((x) => x.ok).length, 1);
  assert.equal(res.filter((x) => x.already).length, 3);
});

// ----------------------------------------------------------------- kalp atışı + sağlık
test('expireHolds kalp atışı yazar; adminHealth takılı siparişleri, sayıları ve bayatlığı bildirir', async () => {
  const now = clock();
  const { svc } = makeService({ now, satis: REZ });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  let h0 = await svc.adminHealth(admin);
  assert.equal(h0.heartbeat.lastRunAt, null); assert.equal(h0.heartbeat.stale, true);

  await reserve(svc, a, ev, ['A1']);
  const free = await seedEvent({ price: '0', showId: 'fh' });
  const fh = await svc.holdSeats(a, { eventId: free, seatIds: ['A1'] });
  await svc.confirmFree(a, { orderId: fh.orderId });
  await svc.holdSeats(b, { eventId: ev, seatIds: ['A2', 'A3'] });
  now.advance(25 * 60e3); // hold 10 dk'da doldu, 15 dk'dır takılı
  let h = await svc.adminHealth(admin);
  assert.equal(h.stuck.held, 1); assert.equal(h.stuck.paying, 0);
  assert.equal(h.reservations.total, 1); assert.equal(h.freeTickets.total, 1);
  assert.equal(h.mode, 'rezervasyon');

  const r = await svc.expireHolds();
  assert.equal(r.expired, 1);
  const hb = await get('System', 'expireHolds');
  assert.equal(hb.lastRunAt.toMillis(), now()); assert.equal(hb.expiredOrders, 1); assert.equal(hb.releasedSeats, 2);
  h = await svc.adminHealth(admin);
  assert.equal(h.stuck.held, 0);
  assert.equal(h.heartbeat.stale, false); assert.equal(h.heartbeat.ageMinutes, 0);
  assert.equal(h.heartbeat.expiredOrders, 1); assert.equal(h.heartbeat.releasedSeats, 2);

  now.advance(16 * 60e3);
  h = await svc.adminHealth(admin);
  assert.equal(h.heartbeat.stale, true); assert.equal(h.heartbeat.ageMinutes, 16);
  await svc.expireHolds();
  assert.equal((await get('System', 'expireHolds')).expiredOrders, 0, 'her çalışmada o çalışmanın değeri yazılır');
});

test('adminHealth: iade gereken siparişleri listeler; bugünkü sayılar yalnızca bugünü kapsar', async () => {
  const { svc } = makeService({ satis: REZ });
  const admin = await makeAdmin();
  await db.collection('Order').doc('ref1').set({ userId: 'x', status: 'failed', refundRequired: true, total: 90, paymentId: 'pay_9' });
  await db.collection('Ticket').doc('old').set({ orderMethod: 'venue', customerId: 'x', _createdAt: '2020-01-01T10:00:00.000Z', paymentStatus: 'pay_at_venue' });
  const r = await reserve(svc, uidN(), await seedEvent(), ['A1']);
  const h = await svc.adminHealth(admin);
  assert.equal(h.refundRequired.count, 1);
  assert.deepEqual(h.refundRequired.orders, [{ orderId: 'ref1', total: 90, paymentId: 'pay_9' }]);
  assert.equal(h.reservations.total, 2); assert.equal(h.reservations.today, 1);
  assert.ok(r.orderId);
});

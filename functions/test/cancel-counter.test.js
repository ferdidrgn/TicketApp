'use strict';
// Görev 1: iptal edilen biletler "Rezervasyon" sayacına girmez; cancelled sayacı ayrıca verilir.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, makeService, seedEvent, uidN, clearDb, makeAdmin, setSatis, expectCode, Timestamp } = H;
const { seedTicket } = require('./notify-helpers');

beforeEach(async () => { await clearDb(); });

test('adminHealth: iptal edilen biletler reservations/freeTickets sayısına GİRMEZ, cancelled ayrı sayılır', async () => {
  const { svc } = makeService();
  const admin = await makeAdmin();
  const yesterday = new Date(Date.now() - 36 * 3600e3).toISOString();
  await seedTicket({ customerId: 'a', eventId: 'e', orderMethod: 'venue', paymentStatus: 'pay_at_venue' });
  await seedTicket({ customerId: 'b', eventId: 'e', orderMethod: 'venue', paymentStatus: 'cancelled', cancelledAt: Timestamp.fromMillis(Date.now()) });
  await seedTicket({ customerId: 'c', eventId: 'e', orderMethod: 'venue', paymentStatus: 'cancelled', createdAt: yesterday, cancelledAt: Timestamp.fromMillis(Date.now() - 30 * 3600e3) });
  await seedTicket({ customerId: 'd', eventId: 'e', orderMethod: 'venue', paymentStatus: 'no_show', createdAt: yesterday });
  await seedTicket({ customerId: 'e', eventId: 'e', orderMethod: 'free', paymentStatus: 'free' });
  await seedTicket({ customerId: 'f', eventId: 'e', orderMethod: 'free', paymentStatus: 'cancelled', cancelledAt: Timestamp.fromMillis(Date.now()) });
  const h = await svc.adminHealth(admin);
  assert.deepEqual(h.reservations, { today: 1, total: 2 }); // a (aktif) + d (gelmedi: iptal değil)
  assert.deepEqual(h.freeTickets, { today: 1, total: 1 });
  assert.equal(h.cancelled.total, 3);
  assert.equal(h.cancelled.today, 2); // b ve f bugün iptal; c dün iptal edildi
});

test('gerçek akış: rezervasyon onayla -> iptal et -> sayaç 0, iptal 1', async () => {
  await setSatis({ mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 1 });
  const { svc } = makeService({ satis: 'db' });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await svc.confirmReservation(u, { orderId: h.orderId });
  let r = await svc.adminHealth(admin);
  assert.equal(r.reservations.total, 1); assert.equal(r.cancelled.total, 0);
  await svc.cancelTicket(u, { ticketId: h.orderId });
  r = await svc.adminHealth(admin);
  assert.deepEqual(r.reservations, { today: 0, total: 0 });
  assert.equal(r.cancelled.total, 1); assert.equal(r.cancelled.today, 1);
});

test('adminHealth yönetici olmayana kapalı', async () => {
  const { svc } = makeService();
  await expectCode(svc.adminHealth(uidN()), 'permission-denied');
});

test('adminHealth: hatırlatma sağlığı (varsayılan açık; hiç çalışmadıysa stale; kapalıyken stale değil)', async () => {
  const { svc } = makeService();
  const admin = await makeAdmin();
  let h = await svc.adminHealth(admin);
  assert.equal(h.reminders.enabled, true); assert.equal(h.reminders.stale, true);
  await db.collection('System').doc('eventReminders').set({ lastRunAt: Timestamp.fromMillis(Date.now() - 60e3), sent24: 4, sent2: 2 });
  h = await svc.adminHealth(admin);
  assert.equal(h.reminders.stale, false); assert.equal(h.reminders.sent24, 4);
  await db.collection('Config').doc('bildirim').set({ autoReminders: false });
  await db.collection('System').doc('eventReminders').set({ lastRunAt: Timestamp.fromMillis(Date.now() - 5 * 3600e3) });
  h = await svc.adminHealth(admin);
  assert.equal(h.reminders.enabled, false); assert.equal(h.reminders.stale, false);
});

test('adminCancelled: iptal edilenler en yeni önce, kim/ne zaman/kim iptal etti; yönetici olmayana kapalı', async () => {
  const { s, assertAdmin } = require('./notify-helpers').makeStats();
  const admin = await makeAdmin();
  await db.collection('User').doc('c1').set({ role: 'user', firstName: 'Ayşe', lastName: 'Yılmaz' });
  const t1 = await seedTicket({ customerId: 'c1', eventId: 'e', orderMethod: 'venue', paymentStatus: 'cancelled', cancelledAt: Timestamp.fromMillis(1000), extra: { cancelledBy: 'customer' } });
  const t2 = await seedTicket({ customerId: 'c2', eventId: 'e', orderMethod: 'free', paymentStatus: 'cancelled', cancelledAt: Timestamp.fromMillis(5000), extra: { cancelledBy: 'admin' } });
  await seedTicket({ customerId: 'c3', eventId: 'e', orderMethod: 'venue', paymentStatus: 'pay_at_venue' });
  const r = await s.adminCancelled(assertAdmin, admin, {});
  assert.equal(r.total, 2); assert.deepEqual(r.tickets.map((x) => x.ticketId), [t2, t1]);
  assert.equal(r.tickets[1].customerName, 'Ayşe Yılmaz'); assert.equal(r.tickets[1].cancelledBy, 'customer'); assert.equal(r.tickets[0].cancelledBy, 'admin');
  assert.equal(r.tickets[0].customerName, ''); assert.equal(r.tickets[0].cancelledAt, 5000);
  await expectCode(s.adminCancelled(assertAdmin, 'c1', {}), 'permission-denied');
});

test('iptal eden kaydedilir: müşteri iptali cancelledBy=customer, yönetici iptali cancelledBy=admin + uid', async () => {
  await setSatis({ mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 1 });
  const { svc } = makeService({ satis: 'db' });
  const admin = await makeAdmin();
  const ev = await seedEvent();
  const [u1, u2] = [uidN(), uidN()];
  const h1 = await svc.holdSeats(u1, { eventId: ev, seatIds: ['A1'] }); await svc.confirmReservation(u1, { orderId: h1.orderId });
  const h2 = await svc.holdSeats(u2, { eventId: ev, seatIds: ['A2'] }); await svc.confirmReservation(u2, { orderId: h2.orderId });
  await svc.cancelTicket(u1, { ticketId: h1.orderId });
  await svc.adminSetTicketStatus(admin, { ticketId: h2.orderId, paymentStatus: 'cancelled' });
  const a = (await db.collection('Ticket').doc(h1.orderId).get()).data(), b = (await db.collection('Ticket').doc(h2.orderId).get()).data();
  assert.equal(a.cancelledBy, 'customer'); assert.equal(a.cancelledByUid, undefined);
  assert.equal(b.cancelledBy, 'admin'); assert.equal(b.cancelledByUid, admin);
});

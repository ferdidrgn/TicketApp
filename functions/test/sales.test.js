'use strict';
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, makeService, seedEvent, eventDate, uidN, expectCode, clock, clearDb } = H;

beforeEach(async () => { await clearDb(); });

const get = async (col, id) => (await db.collection(col).doc(id).get()).data();
const seatOf = async (ev, s) => (await get('Event', ev)).seats[s];

// ----------------------------------------------------------------- hold
test('istemci fiyatı/tutarı yok sayılır: toplam Event.price x koltuk', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '150' });
  const u = uidN();
  const r = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2'], price: 1, total: 1, amount: 0, free: true });
  assert.equal(r.total, 300);
  assert.equal(r.free, false);
  assert.equal(r.currency, 'TRY');
  assert.deepEqual(r.seats, [{ id: 'A1', price: 150 }, { id: 'A2', price: 150 }]);
  const o = await get('Order', r.orderId);
  assert.equal(o.total, 300); assert.equal(o.status, 'held'); assert.equal(o.userId, u);
  assert.equal((await seatOf(ev, 'A1')).status, 'reserved');
});

test('Türkçe/ondalıklı fiyat biçimleri doğru çözülür', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '1.250,50' });
  const r = await svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A1'] });
  assert.equal(r.total, 1250.5);
});

test('iki eşzamanlı hold: yalnızca biri başarılı, koltuk tek kişide', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const res = await Promise.allSettled([
    svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] }),
    svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] }),
  ]);
  const ok = res.filter((r) => r.status === 'fulfilled');
  const bad = res.filter((r) => r.status === 'rejected');
  assert.equal(ok.length, 1);
  assert.equal(bad.length, 1);
  assert.equal(bad[0].reason.code, 'failed-precondition');
  const winner = res[0].status === 'fulfilled' ? a : b;
  assert.equal((await seatOf(ev, 'A1')).customerId, winner);
});

test('kullanıcı başına etkinlikte en fazla 3 koltuk: 4. reddedilir', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const u = uidN();
  // aynı çağrıda 4 koltuk
  await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A1', 'A2', 'A3', 'A4'] }), 'resource-exhausted');
  // ödemesi başlamış (artık değiştirilemeyen) 3 koltuğun üstüne 4. koltuk
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] });
  await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/x' });
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] }), 'resource-exhausted');
  assert.equal((await seatOf(ev, 'A4')).status, 'available');
});

test('satılmış 3 koltuğu olan kullanıcı 4. koltuğu alamaz', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '0' });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] });
  await svc.confirmFree(u, { orderId: h.orderId });
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A4'] }), 'resource-exhausted');
});

test('yeniden seçim: kullanıcının bekleyen hold\'u yeni seçimle değiştirilir', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const u = uidN();
  const first = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] });
  const second = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A4'] });
  assert.equal((await get('Order', first.orderId)).status, 'cancelled');
  assert.equal((await seatOf(ev, 'A2')).status, 'available');
  assert.equal((await seatOf(ev, 'A1')).orderId, second.orderId);
});

test('geçersiz girdiler reddedilir', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const u = uidN();
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: [] }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: 'A1' }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: [1] }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A1'] }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['a.b'] }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: '', seatIds: ['A1'] }), 'invalid-argument');
  await expectCode(svc.holdSeats(u, { eventId: 'yok-boyle-bir-event', seatIds: ['A1'] }), 'not-found');
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['ZZ99'] }), 'invalid-argument');
});

test('geçmiş / başlamış seansa hold reddedilir', async () => {
  const { svc } = makeService();
  const past = await seedEvent({ date: eventDate(-2 * 3600e3) });
  await expectCode(svc.holdSeats(uidN(), { eventId: past, seatIds: ['A1'] }), 'failed-precondition');
  const soon = await seedEvent({ date: eventDate(-60e3) });
  await expectCode(svc.holdSeats(uidN(), { eventId: soon, seatIds: ['A1'] }), 'failed-precondition');
  assert.equal((await seatOf(past, 'A1')).status, 'available');
});

test('hız sınırı: dakikada en fazla 8 deneme', async () => {
  const { svc } = makeService();
  const u = uidN();
  for (let i = 0; i < 8; i++) await expectCode(svc.holdSeats(u, { eventId: 'yok', seatIds: ['A1'] }), 'not-found');
  await expectCode(svc.holdSeats(u, { eventId: 'yok', seatIds: ['A1'] }), 'resource-exhausted');
});

test('Event.seats boşsa sahne planından üretilir; kapalı koltuk satılamaz', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ seatNames: [] });
  await db.collection('Seats').doc('stage1').set({ seatsId: ['B1', 'B2', 'B3'], closedSeatsId: ['B3'] });
  const u = uidN();
  const r = await svc.holdSeats(u, { eventId: ev, seatIds: ['B1'] });
  assert.ok(r.orderId);
  assert.equal((await seatOf(ev, 'B3')).status, 'sold');
  await expectCode(svc.holdSeats(uidN(), { eventId: ev, seatIds: ['B3'] }), 'failed-precondition');
});

// ----------------------------------------------------------------- süre dolumu
test('süre dolunca expireHolds koltuğu serbest bırakır, sipariş expired olur', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent();
  const u = uidN();
  const r = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2'] });
  now.advance(9 * 60e3);
  assert.equal((await svc.expireHolds()).expired, 0);
  assert.equal((await seatOf(ev, 'A1')).status, 'reserved');
  now.advance(2 * 60e3); // 11 dk
  assert.equal((await svc.expireHolds()).expired, 1);
  assert.equal((await get('Order', r.orderId)).status, 'expired');
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
  assert.equal((await seatOf(ev, 'A1')).customerId, null);
  await expectCode(svc.startPayment(u, { orderId: r.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/x' }), 'failed-precondition');
});

test('süresi dolmuş tutma, expireHolds çalışmasa da başkası tarafından alınabilir; eski sahip onaylayamaz', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent({ price: '0' });
  const [a, b] = [uidN(), uidN()];
  const ra = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] });
  now.advance(11 * 60e3);
  await expectCode(svc.confirmFree(a, { orderId: ra.orderId }), 'failed-precondition');
  const rb = await svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] });
  assert.equal((await seatOf(ev, 'A1')).customerId, b);
  await svc.expireHolds(); // eski sipariş expired olur ama b'nin koltuğuna dokunmaz
  assert.equal((await get('Order', ra.orderId)).status, 'expired');
  assert.equal((await seatOf(ev, 'A1')).customerId, b);
  assert.equal((await seatOf(ev, 'A1')).orderId, rb.orderId);
});

// ----------------------------------------------------------------- sahiplik
test('başkasının siparişini serbest bırakma/ödeme/onay reddedilir', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const r = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] });
  await expectCode(svc.releaseHold(b, { orderId: r.orderId }), 'permission-denied');
  await expectCode(svc.startPayment(b, { orderId: r.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/x' }), 'permission-denied');
  await expectCode(svc.confirmFree(b, { orderId: r.orderId }), 'permission-denied');
  await expectCode(svc.releaseHold(b, { orderId: 'olmayan' }), 'not-found');
  assert.equal((await seatOf(ev, 'A1')).customerId, a);
  // sahibi serbest bırakabilir (idempotent)
  assert.deepEqual(await svc.releaseHold(a, { orderId: r.orderId }), { ok: true });
  assert.deepEqual(await svc.releaseHold(a, { orderId: r.orderId }), { ok: true });
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
});

// ----------------------------------------------------------------- ücretsiz
test('ücretsiz limit: 3 farklı etkinlikte toplam 3 bilet, 4. reddedilir', async () => {
  const { svc } = makeService();
  const u = uidN();
  const evs = [];
  for (let i = 0; i < 4; i++) evs.push(await seedEvent({ price: i % 2 ? '' : '0', showId: `s${i}` }));
  for (let i = 0; i < 3; i++) {
    const r = await svc.holdSeats(u, { eventId: evs[i], seatIds: ['A1'] });
    assert.equal(r.free, true); assert.equal(r.total, 0);
    const c = await svc.confirmFree(u, { orderId: r.orderId });
    assert.deepEqual(c.ticketIds, [r.orderId]);
    const t = await get('Ticket', r.orderId);
    assert.equal(t.customerId, u); assert.deepEqual(t.buySeats, ['A1']); assert.equal(t.orderMethod, 'free');
  }
  assert.equal((await get('UserLimits', u)).freeTickets, 3);
  await expectCode(svc.holdSeats(u, { eventId: evs[3], seatIds: ['A1'] }), 'resource-exhausted');
  // başka kullanıcı etkilenmez
  const r2 = await svc.holdSeats(uidN(), { eventId: evs[3], seatIds: ['A1'] });
  assert.ok(r2.orderId);
});

test('ücretsiz limit koltuk sayısına göre: 2 + 2 bilet 4. bileti engeller', async () => {
  const { svc } = makeService();
  const u = uidN();
  const [e1, e2] = [await seedEvent({ price: '0', showId: 'x1' }), await seedEvent({ price: '0', showId: 'x2' })];
  const r1 = await svc.holdSeats(u, { eventId: e1, seatIds: ['A1', 'A2'] });
  await svc.confirmFree(u, { orderId: r1.orderId });
  await expectCode(svc.holdSeats(u, { eventId: e2, seatIds: ['A1', 'A2'] }), 'resource-exhausted');
  const r2 = await svc.holdSeats(u, { eventId: e2, seatIds: ['A1'] });
  await svc.confirmFree(u, { orderId: r2.orderId });
  assert.equal((await get('UserLimits', u)).freeTickets, 3);
});

test('ücretsiz limit eşzamanlı onayda da aşılamaz', async () => {
  const { svc } = makeService();
  const u = uidN();
  const evs = [];
  for (let i = 0; i < 5; i++) evs.push(await seedEvent({ price: '0', showId: `c${i}` }));
  const orders = [];
  for (let i = 0; i < 3; i++) orders.push(await svc.holdSeats(u, { eventId: evs[i], seatIds: ['A1', 'A2'] }).catch(() => null));
  // ilk ikisi alınabilir (2 + ... ) ; üçüncüsü hold aşamasında 2+2>3 ile reddedilmiş olabilir
  const live = orders.filter(Boolean);
  const results = await Promise.allSettled(live.map((o) => svc.confirmFree(u, { orderId: o.orderId })));
  const total = (await get('UserLimits', u))?.freeTickets || 0;
  assert.ok(total <= 3, `freeTickets=${total}`);
  assert.ok(results.some((r) => r.status === 'fulfilled'));
});

test('ücretli sipariş confirmFree ile onaylanamaz', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '100' });
  const u = uidN();
  const r = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await expectCode(svc.confirmFree(u, { orderId: r.orderId }), 'invalid-argument');
  assert.equal(await db.collection('Ticket').doc(r.orderId).get().then((d) => d.exists), false);
});

// ----------------------------------------------------------------- ödeme
async function paidSetup(svc, prov, { price = '200', seats = ['A1', 'A2'] } = {}) {
  const ev = await seedEvent({ price });
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: seats });
  const p = await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/odeme' });
  return { ev, u, h, p };
}

test('startPayment: sağlayıcı oturumu döner, sipariş paying olur, tutar sunucudan', async () => {
  const { svc, prov } = makeService();
  const { h, p } = await paidSetup(svc, null);
  assert.equal(p.provider, 'iyzico');
  assert.equal(p.token, `tok_${h.orderId}`);
  assert.ok(p.paymentPageUrl);
  assert.equal(prov.initCalls[0].order.totalStr, '400.00');
  assert.equal(prov.initCalls[0].callbackUrl, 'https://cb.test/iyzicoCallback');
  const o = await get('Order', h.orderId);
  assert.equal(o.status, 'paying'); assert.equal(o.providerToken, p.token);
  // tekrar çağrı aynı oturumu döndürür (yeni ödeme açmaz)
  const again = await svc.startPayment(o.userId, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/odeme' });
  assert.equal(again.token, p.token);
  assert.equal(prov.initCalls.length, 1);
});

test('startPayment: kötü returnUrl / desteklenmeyen sağlayıcı reddedilir', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const u = uidN();
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://evil.example/x' }), 'invalid-argument');
  await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'javascript:alert(1)' }), 'invalid-argument');
  await expectCode(svc.startPayment(u, { orderId: h.orderId, provider: 'paypal', returnUrl: 'https://tiyatrol.web.app/x' }), 'invalid-argument');
  assert.equal((await get('Order', h.orderId)).status, 'held');
});

test('callback başarı + İDEMPOTENCY: aynı callback (ardışık ve eşzamanlı) tek bilet üretir', async () => {
  const { svc, prov } = makeService();
  const { ev, u, h, p } = await paidSetup(svc, null);
  prov.succeed(h.orderId, 400);
  const r1 = await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token });
  assert.deepEqual(r1, { ok: true, orderId: h.orderId });
  const rs = await Promise.all([1, 2, 3].map(() => svc.handleProviderCallback({ providerName: 'iyzico', token: p.token })));
  assert.ok(rs.every((r) => r.ok && r.orderId === h.orderId));

  const tickets = await db.collection('Ticket').where('customerId', '==', u).get();
  assert.equal(tickets.size, 1);
  const t = tickets.docs[0].data();
  assert.equal(t.orderId, h.orderId); assert.deepEqual(t.buySeats, ['A1', 'A2']);
  assert.equal(t.orderPrice, '400.00'); assert.equal(t.orderMethod, 'card'); assert.equal(t.isPast, false);
  assert.equal(t.showName, 'Test Oyunu'); assert.equal(t.stageName, 'Test Sahne');
  assert.equal(t.eventId, ev);
  const notes = await db.collection('Notification').where('userId', '==', u).get();
  assert.equal(notes.size, 1);
  assert.equal(notes.docs[0].data().type, 'bookingConfirmation');
  assert.equal((await get('Order', h.orderId)).status, 'paid');
  assert.equal((await seatOf(ev, 'A1')).status, 'sold');
  assert.equal((await seatOf(ev, 'A1')).customerId, u);
});

test('yanlış tutar (SUCCESS ama eksik ödeme) bilet ÜRETMEZ, iade işaretlenir, koltuk serbest kalır', async () => {
  const { svc, prov } = makeService();
  const { ev, u, h, p } = await paidSetup(svc, null);
  prov.succeed(h.orderId, 1); // 400 olmalıydı
  const r = await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token });
  assert.equal(r.ok, false);
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 0);
  assert.equal((await db.collection('Notification').where('userId', '==', u).get()).size, 0);
  const o = await get('Order', h.orderId);
  assert.equal(o.status, 'failed'); assert.equal(o.refundRequired, true);
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
});

test('başka siparişe ait sonuç (conversationId/basketId uyuşmaz) bilet ÜRETMEZ', async () => {
  const { svc, prov } = makeService();
  const { u, h, p } = await paidSetup(svc, null);
  prov.succeed(h.orderId, 400, { conversationId: 'baska', basketId: 'baska' });
  assert.equal((await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token })).ok, false);
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 0);
});

test('yanlış/uydurma token ile callback bilet üretmez ve siparişi değiştirmez', async () => {
  const { svc, prov } = makeService();
  const { u, h } = await paidSetup(svc, null);
  prov.succeed(h.orderId, 400);
  for (const token of ['uydurma-token-123', '', undefined, 42, `tok_${h.orderId}x`]) {
    const r = await svc.handleProviderCallback({ providerName: 'iyzico', token });
    assert.equal(r.ok, false);
  }
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 0);
  assert.equal((await get('Order', h.orderId)).status, 'paying');
  // doğru token ama başka sağlayıcı adıyla gelirse de reddedilir
  assert.equal((await svc.handleProviderCallback({ providerName: 'bkm', token: `tok_${h.orderId}` })).ok, false);
});

test('sağlayıcı başarısız derse koltuklar serbest kalır, bilet yok', async () => {
  const { svc, prov } = makeService();
  const { ev, u, h, p } = await paidSetup(svc, null);
  prov.fail(h.orderId);
  const r = await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token });
  assert.equal(r.ok, false);
  assert.equal((await get('Order', h.orderId)).status, 'failed');
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 0);
});

test('callback kaybolursa expireHolds sağlayıcıya sorup ödemeyi kurtarır', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const { u, h } = await paidSetup(svc, null);
  prov.succeed(h.orderId, 400);
  now.advance(31 * 60e3);
  const r = await svc.expireHolds();
  assert.equal(r.settledPaid, 1);
  assert.equal((await get('Order', h.orderId)).status, 'paid');
  assert.equal((await db.collection('Ticket').where('customerId', '==', u).get()).size, 1);
});

test('ödeme penceresi dolup ödeme yoksa sipariş expired olur', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const { ev, h } = await paidSetup(svc, null);
  now.advance(31 * 60e3);
  assert.equal((await svc.expireHolds()).expired, 1);
  assert.equal((await get('Order', h.orderId)).status, 'expired');
  assert.equal((await seatOf(ev, 'A1')).status, 'available');
});

test('ödeme başladıktan sonra serbest bırakma reddedilir', async () => {
  const { svc } = makeService();
  const { u, h } = await paidSetup(svc, null);
  await expectCode(svc.releaseHold(u, { orderId: h.orderId }), 'failed-precondition');
});

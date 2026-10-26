'use strict';
// Süre dolumu / çöken istemci / terk edilen ödeme senaryoları (gerçek Firestore emülatörü, enjekte saat).
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { db, makeService, seedEvent, uidN, expectCode, clock, clearDb } = require('./helpers');

beforeEach(async () => { await clearDb(); });

const get = async (col, id) => (await db.collection(col).doc(id).get()).data();
const seatOf = async (ev, s) => (await get('Event', ev)).seats[s];
const RU = 'https://tiyatrol.web.app/odeme';
const tickets = async (u) => (await db.collection('Ticket').where('customerId', '==', u).get()).size;

// ---------------------------------------------------------------- (a) lazy takeover
test('(a) tutma süresi dolunca başka kullanıcı koltuğu, istemci/expireHolds hiçbir şey yapmadan ALIR', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const ra = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1', 'A2'] });
  // süre dolmadan başkası alamaz
  now.advance(9 * 60e3);
  await expectCode(svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] }), 'failed-precondition');
  // süre doldu; expireHolds ÇALIŞMADI, A hiçbir şey yapmadı
  now.advance(2 * 60e3);
  const rb = await svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] });
  assert.equal((await seatOf(ev, 'A1')).orderId, rb.orderId);
  assert.equal((await seatOf(ev, 'A2')).orderId, ra.orderId, 'A2 henüz kimse almadı; eski kayıt duruyor');
  assert.equal((await get('Order', ra.orderId)).status, 'held', 'eski sipariş expireHolds gelene kadar held görünür');
  // eski sahip artık ücretsiz onaylayamaz / ödeme başlatamaz
  await expectCode(svc.startPayment(a, { orderId: ra.orderId, provider: 'iyzico', returnUrl: RU }), 'failed-precondition');
  await svc.expireHolds();
  assert.equal((await get('Order', ra.orderId)).status, 'expired');
  assert.equal((await seatOf(ev, 'A1')).orderId, rb.orderId, 'B korunur');
  assert.equal((await seatOf(ev, 'A2')).status, 'available');
});

test('(a) terk edilmiş ÖDEMEDEKİ (paying) süresi dolmuş koltuk da başkasınca alınabilir', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const ha = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] });
  await svc.startPayment(a, { orderId: ha.orderId, provider: 'iyzico', returnUrl: RU });
  now.advance(29 * 60e3);
  await expectCode(svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] }), 'failed-precondition');
  now.advance(2 * 60e3); // ödeme penceresi (30 dk) doldu
  const hb = await svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] });
  assert.equal((await seatOf(ev, 'A1')).orderId, hb.orderId);
});

// ---------------------------------------------------------------- (b) expireHolds
test('(b) expireHolds: süresi dolanları expired yapar, koltukları temizler, dolmayana dokunmaz, idempotent', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent();
  const [a, b, c] = [uidN(), uidN(), uidN()];
  const ra = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] });
  now.advance(6 * 60e3);
  const rb = await svc.holdSeats(b, { eventId: ev, seatIds: ['A2'] });
  now.advance(5 * 60e3); // A: 11 dk (doldu), B: 5 dk (dolmadı)
  const rc = await svc.holdSeats(c, { eventId: ev, seatIds: ['A3'] }); // taze
  assert.equal((await svc.expireHolds()).expired, 1);
  assert.equal((await get('Order', ra.orderId)).status, 'expired');
  assert.equal((await get('Order', rb.orderId)).status, 'held');
  assert.equal((await get('Order', rc.orderId)).status, 'held');
  assert.deepEqual(await seatOf(ev, 'A1'), { status: 'available' });
  assert.equal((await seatOf(ev, 'A2')).status, 'reserved');
  assert.equal((await svc.expireHolds()).expired, 0, 'ikinci çalıştırma yeni iş bulmaz');
  now.advance(60 * 60e3);
  assert.equal((await svc.expireHolds()).expired, 2);
  for (const s of ['A1', 'A2', 'A3']) assert.deepEqual(await seatOf(ev, s), { status: 'available' });
});

// ---------------------------------------------------------------- (d) sayfa kapat / aç
test('(d) kapanıp açılan istemci: held sipariş okunabilir, devam ettirilir (ücretsiz onay / ödeme) ya da bırakılır', async () => {
  const { svc } = makeService();
  const evFree = await seedEvent({ price: '0', showId: 'f1' });
  const evPaid = await seedEvent({ price: '90', showId: 'p1' });
  const u = uidN();
  const hf = await svc.holdSeats(u, { eventId: evFree, seatIds: ['A1'] });
  const hp = await svc.holdSeats(u, { eventId: evPaid, seatIds: ['A1', 'A2'] });
  // "yeni oturum": yalnızca kullanıcının Order sorgusu (web: where userId==uid) elde var
  const mine = await db.collection('Order').where('userId', '==', u).where('eventId', '==', evPaid).get();
  const held = mine.docs.filter((d) => d.data().status === 'held');
  assert.equal(held.length, 1);
  assert.deepEqual(held[0].data().seatIds, ['A1', 'A2']);
  // devam: ücretsiz onay ve ödeme başlatma eski orderId ile çalışır
  assert.deepEqual((await svc.confirmFree(u, { orderId: hf.orderId })).ticketIds, [hf.orderId]);
  const p = await svc.startPayment(u, { orderId: hp.orderId, provider: 'iyzico', returnUrl: RU });
  assert.ok(p.token);
  // ödeme başladıktan sonra tekrar açılırsa aynı oturum döner
  assert.equal((await svc.startPayment(u, { orderId: hp.orderId, provider: 'iyzico', returnUrl: RU })).token, p.token);
});

test('(d) kapanıp açılan istemci held siparişi bırakır; ya da aynı koltukları yeniden tutar (eskisi iptal)', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  const u = uidN();
  const h1 = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2'] });
  await svc.releaseHold(u, { orderId: h1.orderId });
  assert.deepEqual(await seatOf(ev, 'A1'), { status: 'available' });
  const h2 = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  const h3 = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2'] });
  assert.equal((await get('Order', h2.orderId)).status, 'cancelled');
  assert.equal((await seatOf(ev, 'A1')).orderId, h3.orderId);
  assert.equal((await seatOf(ev, 'A2')).orderId, h3.orderId);
});

// ---------------------------------------------------------------- (e) terk edilen ödeme / geç callback
async function payingSetup(svc, ev, u, seats = ['A1']) {
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: seats });
  const p = await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: RU });
  return { h, p };
}

test('(e) iyzico sayfası terk edildi: pencere dolunca expireHolds koltukları serbest bırakır, ödeme yok', async () => {
  const now = clock();
  const { svc } = makeService({ now });
  const ev = await seedEvent();
  const u = uidN();
  const { h } = await payingSetup(svc, ev, u);
  now.advance(31 * 60e3);
  const r = await svc.expireHolds();
  assert.deepEqual(r, { expired: 1, settledPaid: 0 });
  assert.equal((await get('Order', h.orderId)).status, 'expired');
  assert.equal((await get('Order', h.orderId)).refundRequired, undefined);
  assert.deepEqual(await seatOf(ev, 'A1'), { status: 'available' });
});

test('(e) GEÇ başarılı callback, koltuk BAŞKASINA geçtiyse: bilet yok, refundRequired:true, diğer kullanıcının koltuğu bozulmaz', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const { h, p } = await payingSetup(svc, ev, a);
  now.advance(31 * 60e3);
  const hb = await svc.holdSeats(b, { eventId: ev, seatIds: ['A1'] }); // lazy takeover
  prov.succeed(h.orderId, 100); // kullanıcı iyzico'da geç ödedi
  const r = await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token });
  assert.equal(r.ok, false);
  const o = await get('Order', h.orderId);
  assert.equal(o.status, 'failed');
  assert.equal(o.refundRequired, true);
  assert.equal(o.failureReason, 'paid_but_unfulfillable');
  assert.equal(o.paymentId, 'pay_1');
  assert.equal(await tickets(a), 0);
  const s = await seatOf(ev, 'A1');
  assert.equal(s.orderId, hb.orderId);
  assert.equal(s.status, 'reserved');
  // B hâlâ ödeyebilir
  const pb = await svc.startPayment(b, { orderId: hb.orderId, provider: 'iyzico', returnUrl: RU });
  prov.succeed(hb.orderId, 100, { paymentId: 'pay_b' });
  assert.equal((await svc.handleProviderCallback({ providerName: 'iyzico', token: pb.token })).ok, true);
  assert.equal(await tickets(b), 1);
});

test('(e) expireHolds de kaçan ödemeyi yakalar: koltuk başkasına geçtiyse refundRequired, geçmediyse bilet', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const ev = await seedEvent();
  const [a, b] = [uidN(), uidN()];
  const x = await payingSetup(svc, ev, a, ['A1']);
  const y = await payingSetup(svc, ev, b, ['A2']);
  prov.succeed(x.h.orderId, 100); prov.succeed(y.h.orderId, 100);
  now.advance(31 * 60e3);
  const c = uidN();
  await svc.holdSeats(c, { eventId: ev, seatIds: ['A1'] }); // A1 başkasına geçti, A2 boşta
  const r = await svc.expireHolds();
  assert.equal(r.settledPaid, 1);
  assert.equal((await get('Order', y.h.orderId)).status, 'paid');
  assert.equal(await tickets(b), 1);
  const ox = await get('Order', x.h.orderId);
  assert.equal(ox.status, 'failed'); assert.equal(ox.refundRequired, true);
  assert.equal(await tickets(a), 0);
});

test('(e) sipariş zaten expired iken gelen başarılı callback de refundRequired işaretler', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const ev = await seedEvent();
  const u = uidN();
  const { h, p } = await payingSetup(svc, ev, u);
  now.advance(31 * 60e3);
  await svc.expireHolds(); // ödeme yok -> expired
  assert.equal((await get('Order', h.orderId)).status, 'expired');
  prov.succeed(h.orderId, 100);
  await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token });
  const o = await get('Order', h.orderId);
  assert.equal(o.status, 'failed'); assert.equal(o.refundRequired, true);
  assert.equal(await tickets(u), 0);
});

test('fraudStatus=0 (iyzico inceleme): bilet verilmez, sipariş kapatılmaz, karar beklenir', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const ev = await seedEvent();
  const u = uidN();
  const { h, p } = await payingSetup(svc, ev, u);
  prov.succeed(h.orderId, 100, { paid: false, pending: true });
  assert.equal((await svc.handleProviderCallback({ providerName: 'iyzico', token: p.token })).ok, false);
  assert.equal((await get('Order', h.orderId)).status, 'paying');
  now.advance(31 * 60e3);
  assert.deepEqual(await svc.expireHolds(), { expired: 0, settledPaid: 0 });
  assert.equal((await get('Order', h.orderId)).status, 'paying');
  prov.succeed(h.orderId, 100); // inceleme onaylandı
  assert.equal((await svc.expireHolds()).settledPaid, 1);
  assert.equal(await tickets(u), 1);
});

// ---------------------------------------------------------------- gizlilik: herkese açık Event'te kimlik yok
test('GİZLİLİK: Event belgesinde hiçbir aşamada uid / customerId bulunmaz (hold, ödeme, satış, ücretsiz, iptal)', async () => {
  const now = clock();
  const { svc, prov } = makeService({ now });
  const ev = await seedEvent({ price: '100' });
  const evF = await seedEvent({ price: '0', showId: 'g1' });
  const [a, b, c] = [uidN(), uidN(), uidN()];
  const check = async (label) => {
    for (const id of [ev, evF]) {
      const raw = JSON.stringify(await get('Event', id));
      for (const u of [a, b, c]) assert.ok(!raw.includes(u), `${label}: uid sızdı`);
      assert.ok(!raw.includes('customerId'), `${label}: customerId alanı var`);
    }
  };
  const ha = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1'] }); await check('hold');
  const pa = await svc.startPayment(a, { orderId: ha.orderId, provider: 'iyzico', returnUrl: RU }); await check('paying');
  prov.succeed(ha.orderId, 100);
  await svc.handleProviderCallback({ providerName: 'iyzico', token: pa.token }); await check('sold');
  const hf = await svc.holdSeats(b, { eventId: evF, seatIds: ['A1'] });
  await svc.confirmFree(b, { orderId: hf.orderId }); await check('free sold');
  const hc = await svc.holdSeats(c, { eventId: ev, seatIds: ['A2'] });
  await svc.releaseHold(c, { orderId: hc.orderId }); await check('release');
  assert.deepEqual(Object.keys(await seatOf(ev, 'A1')).sort(), ['orderId', 'status']);
});

test('GİZLİLİK: eski biçimli (customerId içeren) koltuk, sonraki yazımda temizlenir; yönetici bloğu korunur', async () => {
  const { svc } = makeService();
  const ev = await seedEvent();
  await db.collection('Event').doc(ev).update({
    'seats.A1': { status: 'reserved', customerId: 'eski-uid', reservedAt: new Date(Date.now() - 3600e3) }, // eski, süresi dolmuş
    'seats.A2': { status: 'sold', customerId: '__ADMIN_BLOCKED__' }, // eski admin bloğu
  });
  const u = uidN();
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A2'] }), 'failed-precondition');
  await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] });
  const s = await seatOf(ev, 'A1');
  assert.equal('customerId' in s, false);
  assert.equal(s.status, 'reserved');
});

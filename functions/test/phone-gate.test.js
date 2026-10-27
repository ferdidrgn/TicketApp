'use strict';
// Telefon doğrulamalı kimlik: PHONE_REQUIRED kapısı, telefon anahtarlı ortak limit, geçiş, iade, syncPhoneVerification.
// Servis testleri doğrudan createService ile; "token" yerine ctx.phone verilir (index.js bunu token.phone_number'dan doldurur).
// Uçtan uca (gerçek index.js + Auth emülatörü SMS akışı) testleri en altta.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { createPhoneSync, phoneKeyOf } = require('../src/phone');
const { db, makeService, seedEvent, uidN, clearDb, makeAdmin, expectCode, phoneFor, keyFor, signInPhone, PROJECT } = H;

beforeEach(async () => { await clearDb(); });

const P1 = '+905551110001', P2 = '+905551110002';
const get = async (c, id) => { const s = await db.collection(c).doc(id).get(); return s.exists ? s.data() : null; };

async function freeBuy(svc, uid, phone, n, ev) {
  const e = ev || await seedEvent({ price: '0' });
  const h = await svc.holdSeats(uid, { eventId: e, seatIds: ['A1', 'A2', 'A3', 'A4', 'A5'].slice(0, n) }, { phone });
  const c = await svc.confirmFree(uid, { orderId: h.orderId }, { phone });
  return { e, h, c, ticketId: h.orderId };
}

test('telefonsuz bağlam: tüm satış metodları PHONE_REQUIRED (failed-precondition + details.code)', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '0' });
  const u = uidN();
  for (const ctx of [{ phone: null }, { phone: undefined }, { phone: '' }, { phone: '05551110001' }, { phone: '+90 555' }, { phone: 5551110001 }]) {
    const calls = [
      () => svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] }, ctx),
      () => svc.confirmFree(u, { orderId: 'x' }, ctx),
      () => svc.confirmReservation(u, { orderId: 'x' }, ctx),
      () => svc.startPayment(u, { orderId: 'x', provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/a' }, ctx),
    ];
    for (const c of calls) {
      const e = await expectCode(c(), 'failed-precondition');
      assert.equal(e.message, 'PHONE_REQUIRED');
      assert.equal(e.details && e.details.code, 'PHONE_REQUIRED');
    }
  }
  // hiçbir şey yazılmadı (koltuk tutulmadı, sipariş yok, limit belgesi yok)
  assert.equal((await db.collection('Order').get()).size, 0);
  assert.equal((await db.collection('UserLimits').get()).size, 0);
});

test('telefonlu bağlam: tutma + ücretsiz onay geçer; limit belgesi yalnızca HASH anahtarlı, düz numara hiçbir yerde yok (KVKK)', async () => {
  const { svc } = makeService();
  const u = uidN();
  const { ticketId } = await freeBuy(svc, u, P1, 2);
  const key = keyFor(P1);
  assert.match(key, /^ph_[0-9a-f]{64}$/);
  assert.equal((await get('UserLimits', key)).freeTickets, 2);
  const dump = JSON.stringify([
    (await db.collection('UserLimits').get()).docs.map((d) => [d.id, d.data()]),
    (await db.collection('Order').get()).docs.map((d) => d.data()),
    (await db.collection('Ticket').get()).docs.map((d) => d.data()),
    (await db.collection('Notification').get()).docs.map((d) => d.data()),
  ]);
  assert.ok(!dump.includes('5551110001'), 'düz telefon numarası sızdı');
  assert.equal((await get('Order', ticketId)).phoneKey, key);
});

test('iki farklı uid + aynı telefon -> ORTAK limit (toplam 3), yeni hesap hak yenilemez', async () => {
  const { svc } = makeService();
  const a = uidN(), b = uidN();
  await freeBuy(svc, a, P1, 3);
  const ev2 = await seedEvent({ price: '0' });
  const hb = svc.holdSeats(b, { eventId: ev2, seatIds: ['A1'] }, { phone: P1 });
  // tutma (hold) kontrolü de reddeder
  await expectCode(hb, 'resource-exhausted');
  // başka telefon -> kendi 3 hakkı
  await freeBuy(svc, b, P2, 3);
});

test('hesap silme + yeniden açma (yeni uid, aynı telefon): sayaç SIFIRLANMAZ', async () => {
  const { svc } = makeService();
  const old = uidN();
  await freeBuy(svc, old, P1, 2);
  // eski hesap tamamen silinir: User + uid-anahtarlı UserLimits (Auth silme sonrası istemci/Console temizliği)
  await db.collection('User').doc(old).delete();
  await db.collection('UserLimits').doc(old).delete();
  const fresh = uidN();
  const ev = await seedEvent({ price: '0' });
  await expectCode(svc.holdSeats(fresh, { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: P1 }), 'resource-exhausted'); // 2 + 2 > 3
  const h = await svc.holdSeats(fresh, { eventId: ev, seatIds: ['A1'] }, { phone: P1 }); // 2 + 1 = 3 serbest
  await svc.confirmFree(fresh, { orderId: h.orderId }, { phone: P1 });
  assert.equal((await get('UserLimits', keyFor(P1))).freeTickets, 3);
});

test('geçiş: eski uid-anahtarlı sayaç ilk telefonlu işlemde telefon sayacına taşınır; sonra yeni uid de görür', async () => {
  const { svc } = makeService();
  const u = uidN();
  await db.collection('UserLimits').doc(u).set({ freeTickets: 2, reservations: 1 }); // eski biçim
  const ev = await seedEvent({ price: '0' });
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: P1 }), 'resource-exhausted'); // 2+2>3
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] }, { phone: P1 });
  await svc.confirmFree(u, { orderId: h.orderId }, { phone: P1 });
  const ph = await get('UserLimits', keyFor(P1));
  assert.equal(ph.freeTickets, 3); assert.equal(ph.reservations, 1);
  const mirror = await get('UserLimits', u);
  assert.equal(mirror.phoneKey, keyFor(P1)); assert.equal(mirror.freeTickets, 3);
  // aynı telefonla yeni hesap: 3'ü dolu
  const ev2 = await seedEvent({ price: '0' });
  await expectCode(svc.holdSeats(uidN(), { eventId: ev2, seatIds: ['A1'] }, { phone: P1 }), 'resource-exhausted');
});

test('telefon DEĞİŞTİRME (aynı uid, yeni numara) limit kaçırmaz: önceki telefondaki sayaç taşınır', async () => {
  const { svc } = makeService();
  const u = uidN();
  await freeBuy(svc, u, P1, 3);
  const ev = await seedEvent({ price: '0' });
  await expectCode(svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] }, { phone: P2 }), 'resource-exhausted');
});

test('rezervasyon limiti de telefona bağlı (iki hesap, tek telefon, rezervasyonLimit=3)', async () => {
  const { svc } = makeService({ satis: { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 } });
  const a = uidN(), b = uidN();
  const ev = await seedEvent({ price: '100', seatNames: ['A1', 'A2', 'A3', 'A4', 'A5', 'B1'] });
  const h = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1', 'A2', 'A3'] }, { phone: P1 });
  await svc.confirmReservation(a, { orderId: h.orderId }, { phone: P1 });
  const ev2 = await seedEvent({ price: '100' });
  const hb = await svc.holdSeats(b, { eventId: ev2, seatIds: ['A1'] }, { phone: P1 });
  await expectCode(svc.confirmReservation(b, { orderId: hb.orderId }, { phone: P1 }), 'resource-exhausted');
  // confirm yolunda telefon yoksa da PHONE_REQUIRED
  await expectCode(svc.confirmReservation(b, { orderId: hb.orderId }, { phone: null }), 'failed-precondition');
});

test('iptal iadesi AYNI telefon anahtarına yapılır (cancelTicket: telefonsuz çağrı da çalışır, yeni uid hak geri kazanır)', async () => {
  const { svc } = makeService({ satis: 'db' });
  await H.setSatis({ mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 });
  const a = uidN();
  const { ticketId } = await freeBuy(svc, a, P1, 3);
  assert.equal((await get('UserLimits', keyFor(P1))).freeTickets, 3);
  await svc.cancelTicket(a, { ticketId }); // cancelTicket telefon istemez
  assert.equal((await get('UserLimits', keyFor(P1))).freeTickets, 0);
  assert.equal((await get('UserLimits', a)).freeTickets, 0); // ayna da düşer
  const b = uidN(); // yeni hesap, aynı telefon: 3 hak yeniden
  await freeBuy(svc, b, P1, 3);
});

test('yönetici iptali ve gelmedi (adminSetTicketStatus) telefon sayacını düzeltir', async () => {
  const { svc } = makeService({ satis: { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 } });
  const admin = await makeAdmin();
  const a = uidN();
  const { ticketId } = await freeBuy(svc, a, P1, 2);
  await svc.adminSetTicketStatus(admin, { ticketId, paymentStatus: 'cancelled' });
  assert.equal((await get('UserLimits', keyFor(P1))).freeTickets, 0);
  // rezervasyon -> gelmedi düşer, geri alınınca yeniden eklenir
  const ev = await seedEvent({ price: '100' });
  const h = await svc.holdSeats(a, { eventId: ev, seatIds: ['A1', 'A2'] }, { phone: P1 });
  await svc.confirmReservation(a, { orderId: h.orderId }, { phone: P1 });
  assert.equal((await get('UserLimits', keyFor(P1))).reservations, 2);
  await svc.adminSetTicketStatus(admin, { ticketId: h.orderId, paymentStatus: 'no_show' });
  assert.equal((await get('UserLimits', keyFor(P1))).reservations, 0);
  await svc.adminSetTicketStatus(admin, { ticketId: h.orderId, paymentStatus: 'pay_at_venue' });
  assert.equal((await get('UserLimits', keyFor(P1))).reservations, 2);
});

test('eski bilet (siparişte/aynada telefon anahtarı yok) iptali yalnızca eski uid sayacını düşürür, çökmez', async () => {
  const { svc } = makeService({ satis: { mode: 'rezervasyon', rezervasyonLimit: 3, iptalSaat: 24 } });
  const u = uidN();
  const ev = await seedEvent({ price: '0' });
  await db.collection('Ticket').doc('legacy1').set({
    _id: 'legacy1', customerId: u, eventId: ev, buySeats: ['A1'], orderMethod: 'free', paymentStatus: 'free', eventDate: '', showName: '',
  });
  await db.collection('UserLimits').doc(u).set({ freeTickets: 2 });
  await svc.cancelTicket(u, { ticketId: 'legacy1' });
  assert.equal((await get('UserLimits', u)).freeTickets, 1);
});

test('YARIŞ: aynı telefon, iki cihaz/uid eşzamanlı confirmFree -> toplam 3 aşılamaz', async () => {
  const { svc } = makeService();
  const a = uidN(), b = uidN();
  const ea = await seedEvent({ price: '0' }), eb = await seedEvent({ price: '0' });
  const ha = await svc.holdSeats(a, { eventId: ea, seatIds: ['A1', 'A2'] }, { phone: P1 });
  const hb = await svc.holdSeats(b, { eventId: eb, seatIds: ['A1', 'A2'] }, { phone: P1 }); // tutma aşamasında sayaç hâlâ 0
  const r = await Promise.allSettled([
    svc.confirmFree(a, { orderId: ha.orderId }, { phone: P1 }),
    svc.confirmFree(b, { orderId: hb.orderId }, { phone: P1 }),
  ]);
  assert.equal(r.filter((x) => x.status === 'fulfilled').length, 1);
  assert.equal(r.filter((x) => x.status === 'rejected' && x.reason.code === 'resource-exhausted').length, 1);
  assert.equal((await get('UserLimits', keyFor(P1))).freeTickets, 2);
});

test('hold hız sınırı telefona bağlı: yeni hesaplarla aşılamaz', async () => {
  const { svc } = makeService();
  const ev = await seedEvent({ price: '100' });
  let blocked = 0;
  for (let i = 0; i < 10; i++) {
    try { await svc.holdSeats(uidN(), { eventId: ev, seatIds: ['A5'] }, { phone: P1 }); } catch (e) { if (e.code === 'resource-exhausted') blocked += 1; }
  }
  assert.ok(blocked >= 1, 'her yeni uid ile hız sınırı sıfırlanmamalı');
});

test('startPayment: sağlayıcıya DOĞRULANMIŞ telefon (token) gsmNumber olarak gider, User.phoneNumber değil', async () => {
  const { svc, prov } = makeService();
  const u = uidN();
  await db.collection('User').doc(u).set({ firstName: 'A', lastName: 'B', phoneNumber: '+905999999999' });
  const ev = await seedEvent({ price: '100' });
  const h = await svc.holdSeats(u, { eventId: ev, seatIds: ['A1'] }, { phone: P1 });
  await svc.startPayment(u, { orderId: h.orderId, provider: 'iyzico', returnUrl: 'https://tiyatrol.web.app/odeme-sonuc' }, { phone: P1 });
  assert.equal(prov.initCalls[0].buyer.gsmNumber, P1);
});

// ------------------------------------------------------------------ syncPhoneVerification
test('syncPhoneVerification: telefon varsa User yazılır (role dokunulmaz); yoksa {isPhoneActive:false}, hata yok', async () => {
  const sync = createPhoneSync({ db, salt: H.TEST_SALT, log: { error() {} } });
  const u = uidN();
  await db.collection('User').doc(u).set({ role: 'admin', firstName: 'Ada', isPhoneActive: false, phoneNumber: '' });
  const r = await sync.syncPhoneVerification(u, { phone: P1 });
  assert.deepEqual(r, { isPhoneActive: true, phoneNumber: P1 });
  const d = await get('User', u);
  assert.equal(d.role, 'admin'); assert.equal(d.firstName, 'Ada');
  assert.equal(d.isPhoneActive, true); assert.equal(d.phoneNumber, P1);
  assert.equal(d.phoneKey, keyFor(P1)); assert.ok(d.phoneVerifiedAt);

  // belge yoksa minimal alanlarla oluşur, role YOK
  const n = uidN();
  await sync.syncPhoneVerification(n, { phone: P2 });
  const nd = await get('User', n);
  assert.equal(nd.isPhoneActive, true); assert.equal(nd.role, undefined);

  // telefonsuz: hata yok, belge yoksa oluşturulmaz
  const z = uidN();
  assert.deepEqual(await sync.syncPhoneVerification(z, { phone: undefined }), { isPhoneActive: false });
  assert.equal(await get('User', z), null);
  assert.deepEqual(await sync.syncPhoneVerification(z, { phone: 'bozuk' }), { isPhoneActive: false });
  // telefon sonradan kaldırıldıysa aktiflik düşer
  assert.deepEqual(await sync.syncPhoneVerification(n, {}), { isPhoneActive: false });
  assert.equal((await get('User', n)).isPhoneActive, false);
});

test('syncPhoneVerification: numarayı bırakan eski uid pasifleşir (aynı numara iki hesapta "aktif" kalmaz)', async () => {
  const sync = createPhoneSync({ db, salt: H.TEST_SALT, log: { error() {} } });
  const oldU = uidN(), newU = uidN();
  await sync.syncPhoneVerification(oldU, { phone: P1 });
  await sync.syncPhoneVerification(newU, { phone: P1 });
  assert.equal((await get('User', oldU)).isPhoneActive, false);
  assert.equal((await get('User', newU)).isPhoneActive, true);
});

test('phoneKeyOf: tuza bağlı, numaraya bağlı, deterministik', () => {
  assert.equal(phoneKeyOf(P1, 's'), phoneKeyOf(P1, 's'));
  assert.notEqual(phoneKeyOf(P1, 's'), phoneKeyOf(P1, 't'));
  assert.notEqual(phoneKeyOf(P1, 's'), phoneKeyOf(P2, 's'));
});

// ------------------------------------------------------------------ uçtan uca (gerçek index.js, Auth emülatörü SMS akışı)
const FN = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const url = (name) => `http://${FN}/${PROJECT}/europe-west1/${name}`;
async function call(name, data, token) {
  const r = await fetch(url(name), { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json().catch(() => ({})) };
}
async function emailSignUp(email) {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'Test1234!', returnSecureToken: true }),
  });
  const j = await r.json();
  return { token: j.idToken, uid: j.localId };
}

test('E2E: e-posta/Google (telefonsuz) token -> holdSeats/confirmFree/confirmReservation/startPayment PHONE_REQUIRED; cancelTicket/releaseHold etkilenmez', { timeout: 120000 }, async () => {
  const ev = await seedEvent({ price: '0' });
  const { token } = await emailSignUp('nophone@example.com');
  for (const [n, d] of [['holdSeats', { eventId: ev, seatIds: ['A1'] }], ['confirmFree', { orderId: 'o' }], ['confirmReservation', { orderId: 'o' }], ['startPayment', { orderId: 'o', provider: 'iyzico', returnUrl: 'https://tiyatrol-web.web.app/x' }]]) {
    const r = await call(n, d, token);
    assert.equal(r.status, 400, n);
    assert.equal(r.body.error.status, 'FAILED_PRECONDITION', n);
    assert.equal(r.body.error.message, 'PHONE_REQUIRED', n);
    assert.equal(r.body.error.details.code, 'PHONE_REQUIRED', n);
  }
  assert.equal((await call('releaseHold', { orderId: 'yok' }, token)).body.error.status, 'NOT_FOUND');
  assert.equal((await call('cancelTicket', { ticketId: 'yok' }, token)).body.error.status, 'NOT_FOUND');
  assert.equal((await db.collection('Order').get()).size, 0);
});

test('E2E: SMS doğrulanmış telefon bağlanınca (token tazelenir) satış geçer; syncPhoneVerification User\'ı sunucu yazar; limitler hash anahtarlı', { timeout: 120000 }, async () => {
  const ev = await seedEvent({ price: '0' });
  const em = await emailSignUp('withphone@example.com');
  // bağlamadan önce reddedilir
  assert.equal((await call('holdSeats', { eventId: ev, seatIds: ['A1'] }, em.token)).body.error.message, 'PHONE_REQUIRED');
  const s0 = await call('syncPhoneVerification', {}, em.token);
  assert.deepEqual(s0.body.result, { isPhoneActive: false });
  // SMS ile telefon bağla (yeni token'da phone_number claim'i)
  const ph = await signInPhone('+905553334455', em.token);
  assert.equal(ph.uid, em.uid);
  const s1 = await call('syncPhoneVerification', {}, ph.token);
  assert.deepEqual(s1.body.result, { isPhoneActive: true, phoneNumber: '+905553334455' });
  const u = await get('User', ph.uid);
  assert.equal(u.isPhoneActive, true); assert.ok(u.phoneVerifiedAt); assert.equal(u.role, undefined);
  const h = await call('holdSeats', { eventId: ev, seatIds: ['A1', 'A2'] }, ph.token);
  assert.equal(h.status, 200);
  const c = await call('confirmFree', { orderId: h.body.result.orderId }, ph.token);
  assert.equal(c.status, 200);
  const key = phoneKeyOf('+905553334455', `tiyatrol-phone-v1:${PROJECT}`);
  assert.equal((await get('UserLimits', key)).freeTickets, 2);
  // giriş yoksa sync de reddedilir
  assert.equal((await call('syncPhoneVerification', {})).body.error.status, 'UNAUTHENTICATED');
});

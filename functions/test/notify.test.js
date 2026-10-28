'use strict';
// Görev 3 (adminSendNotification / adminNotifyPreview) + Görev 4 (eventReminders).
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const H = require('./helpers');
const { db, clearDb, makeAdmin, expectCode, eventDate, clock, Timestamp } = H;
const { fakeMessaging, makeNotifier, seedUser, seedTicket, tok } = require('./notify-helpers');

beforeEach(async () => { await clearDb(); });

const HOUR = 3600e3;
const notifs = async (filter) => (await db.collection('Notification').get()).docs.map((d) => ({ id: d.id, ...d.data() })).filter(filter || (() => true));

/** Seans + oyun + sahne + (kullanıcı, bilet) kümesi. specs: [{u, token, status, method}] */
async function scene({ date = eventDate(HOUR), specs = [], eventId = 'ev1', showId = 'show1' } = {}) {
  await db.collection('Event').doc(eventId).set({ _id: eventId, showId, stageId: 'stage1', date, price: '100', seats: {} });
  await db.collection('Show').doc(showId).set({ name: 'Hamlet' });
  await db.collection('Stage').doc('stage1').set({ name: 'Büyük Sahne' });
  for (const sp of specs) {
    await seedUser(sp.u, { token: sp.token });
    await seedTicket({ customerId: sp.u, eventId, showId, paymentStatus: sp.status || 'pay_at_venue', orderMethod: sp.method || 'venue', usedAt: sp.usedAt });
  }
  return eventId;
}

// ------------------------------------------------------------------ yetki
test('adminSendNotification / adminNotifyPreview: yönetici değilse reddedilir, hiçbir şey gönderilmez', async () => {
  const { n, msg } = makeNotifier();
  await seedUser('u1', { token: tok(1) });
  await expectCode(n.adminSendNotification('u1', { target: { type: 'user', id: 'u1' }, title: 'a', body: 'b' }), 'permission-denied');
  await expectCode(n.adminNotifyPreview('u1', { target: { type: 'all' } }), 'permission-denied');
  await expectCode(n.adminSendNotification('hic_yok', { target: { type: 'all' }, title: 'a', body: 'b', confirm: true }), 'permission-denied');
  assert.equal(msg.multicasts.length + msg.topics.length, 0);
  assert.equal((await notifs()).length, 0);
});

// ------------------------------------------------------------------ hedefleme
test('seans hedefi: iptal/gelmedi biletliler dışlanır, token\'sız kullanıcı atlanır (uygulama içi yine yazılır), aynı kullanıcı tekil', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await scene({ specs: [
    { u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2), status: 'cancelled' }, { u: 'u3', token: tok(3), status: 'no_show' },
    { u: 'u4' }, { u: 'u5', token: tok(5), method: 'free', status: 'free' }, { u: 'u6', token: tok(6), status: 'paid', method: 'card' },
  ] });
  await seedTicket({ customerId: 'u1', eventId: 'ev1', paymentStatus: 'pay_at_venue' }); // u1'in ikinci bileti
  const pv = await n.adminNotifyPreview(admin, { target: { type: 'event', id: 'ev1' } });
  assert.equal(pv.recipients, 4); assert.equal(pv.withToken, 3); assert.equal(pv.event.show, 'Hamlet'); assert.ok(pv.templates.length >= 8);

  await expectCode(n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, title: 'Duyuru', body: 'Merhaba' }), 'failed-precondition'); // confirm yok
  assert.equal(msg.multicasts.length, 0);
  const r = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, title: 'Duyuru', body: 'Merhaba', confirm: true });
  assert.equal(r.recipients, 4); assert.equal(r.withToken, 3); assert.equal(r.success, 3); assert.equal(r.failure, 0);
  assert.equal(msg.multicasts.length, 1);
  assert.deepEqual([...msg.multicasts[0].tokens].sort(), [tok(1), tok(5), tok(6)]);
  const docs = await notifs();
  assert.deepEqual(docs.map((d) => d.userId).sort(), ['u1', 'u4', 'u5', 'u6']);
  const d = docs[0];
  assert.equal(d.isRead, false); assert.equal(d.type, 'announcement'); assert.equal(d.eventId, 'ev1'); assert.equal(d.title, 'Duyuru'); assert.ok(d.createdAt); assert.ok(typeof d._createdAt === 'string');
});

test('oyun hedefi: oyunun tüm seanslarındaki aktif biletliler', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1) }] });
  await db.collection('Event').doc('ev2').set({ showId: 'show1', stageId: 'stage1', date: eventDate(5 * 24 * HOUR), seats: {} });
  await seedUser('u2', { token: tok(2) }); await seedTicket({ customerId: 'u2', eventId: 'ev2', paymentStatus: 'free', orderMethod: 'free' });
  await seedUser('u3', { token: tok(3) }); await seedTicket({ customerId: 'u3', eventId: 'evX', showId: 'baska', paymentStatus: 'free', orderMethod: 'free' });
  const r = await n.adminSendNotification(admin, { target: { type: 'show', id: 'show1' }, title: 'Yeni oyun', body: 'Ek seans eklendi', confirm: true });
  assert.equal(r.recipients, 2);
  assert.deepEqual([...msg.multicasts[0].tokens].sort(), [tok(1), tok(2)]);
  assert.equal((await notifs())[0].showId, 'show1');
});

test('kişi hedefi: onay gerekmez, yalnız o kullanıcının token\'ı; token yoksa yalnız uygulama içi', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await seedUser('a', { token: tok(1) }); await seedUser('b');
  const r = await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'Selam', body: 'Sana özel' });
  assert.equal(r.success, 1); assert.deepEqual(msg.multicasts[0].tokens, [tok(1)]);
  const r2 = await n.adminSendNotification(admin, { target: { type: 'user', id: 'b' }, title: 'Selam', body: 'Sana özel' });
  assert.equal(r2.success, 0); assert.equal(r2.withToken, 0); assert.equal(msg.multicasts.length, 1);
  assert.equal((await notifs((x) => x.userId === 'b')).length, 1);
  await expectCode(n.adminSendNotification(admin, { target: { type: 'user', id: 'yok' }, title: 'a', body: 'b' }), 'not-found');
  await expectCode(n.adminSendNotification(admin, { target: { type: 'user', id: 'a/b' }, title: 'a', body: 'b' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: { type: 'xx' }, title: 'a', body: 'b' }), 'invalid-argument');
});

test('herkese: FCM konusu all_users + her kullanıcıya uygulama içi belge; confirm zorunlu', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  for (let i = 0; i < 5; i++) await seedUser(`u${i}`, { token: tok(i) });
  await expectCode(n.adminSendNotification(admin, { target: { type: 'all' }, title: 'a', body: 'b' }), 'failed-precondition');
  assert.equal(msg.topics.length, 0);
  const pv = await n.adminNotifyPreview(admin, { target: { type: 'all' } });
  assert.equal(pv.topic, true); assert.equal(pv.recipients, 6); assert.equal(pv.withToken, 5); // 5 kullanıcı + yönetici
  const r = await n.adminSendNotification(admin, { target: { type: 'all' }, title: 'Duyuru', body: 'Herkese', confirm: true });
  assert.equal(r.topic, true); assert.equal(msg.topics.length, 1); assert.equal(msg.topics[0].topic, 'all_users'); assert.equal(msg.multicasts.length, 0);
  assert.equal((await notifs()).length, 6);
});

test('500\'lük parçalama: 1200 token -> 3 çağrı (500+500+200); aynı cihaz token\'ı tekilleştirilir', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await db.collection('Event').doc('ev1').set({ showId: 'show1', stageId: 'stage1', date: eventDate(HOUR), seats: {} });
  await db.collection('Show').doc('show1').set({ name: 'Hamlet' });
  let batch = db.batch(), c = 0;
  const flush = async () => { await batch.commit(); batch = db.batch(); c = 0; };
  for (let i = 0; i < 1200; i++) {
    batch.set(db.collection('User').doc(`m${i}`), { role: 'user', fcmToken: i === 1199 ? tok(0) : tok(i) }); // son kullanıcı 0'ın cihazını paylaşıyor
    batch.set(db.collection('Ticket').doc(`mt${i}`), { customerId: `m${i}`, eventId: 'ev1', showId: 'show1', paymentStatus: 'pay_at_venue', orderMethod: 'venue' });
    c += 2; if (c >= 400) await flush();
  }
  await flush();
  const r = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, title: 'Test', body: 'Parça', confirm: true });
  assert.equal(r.recipients, 1200);
  assert.deepEqual(msg.multicasts.map((m) => m.tokens.length), [500, 500, 199]);
  assert.equal((await notifs()).length, 1200); // her kullanıcıya bir belge
  const log = (await db.collection('NotificationLog').doc(r.logId).get()).data();
  assert.equal(log.chunks, 3);
});

// ------------------------------------------------------------------ yük (alarm / normal)
test('alarm: Android yüksek öncelik + alarm kanalı + kısa TTL, iOS apns-priority 10 + time-sensitive, data alanları', async () => {
  const admin = await makeAdmin();
  const now = clock(Date.UTC(2026, 9, 26, 12, 0, 0));
  const { n, msg } = makeNotifier({ now });
  await seedUser('a', { token: tok(1), loud: true });
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'ALARM', body: 'Başlıyor', kind: 'alarm' });
  const m = msg.multicasts[0];
  assert.equal(m.android.priority, 'high'); assert.equal(m.android.notification.channelId, 'tiyatrol_alarm'); assert.equal(m.android.ttl, 120000);
  assert.equal(m.apns.headers['apns-priority'], '10'); assert.equal(m.apns.payload.aps['interruption-level'], 'time-sensitive'); assert.equal(m.apns.payload.aps.sound, 'default');
  assert.equal(m.data.kind, 'alarm'); assert.equal(m.data.route, '/notifications');
  assert.ok(Object.values(m.data).every((v) => typeof v === 'string'));
  assert.equal(m.notification.title, 'ALARM');
  assert.equal((await notifs())[0].type, 'alarm');
});

test('alarm + tercih YOK / kapalı: NORMAL kanal (tiyatrol_default), time-sensitive yok; içerik/öncelik/TTL aynı (sessiz modda sessiz)', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await seedUser('a', { token: tok(1) }); // tercih alanı hiç yok
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'ALARM', body: 'Başlıyor', kind: 'alarm' });
  await seedUser('b', { token: tok(2), loud: false });
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'b' }, title: 'ALARM', body: 'Başlıyor', kind: 'alarm' });
  await seedUser('c', { token: tok(3) });
  await db.collection('User').doc('c').update({ notifPrefs: { loudAlarm: 'true' } }); // bool değil -> izin sayılmaz
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'c' }, title: 'ALARM', body: 'Başlıyor', kind: 'alarm' });
  assert.equal(msg.multicasts.length, 3);
  for (const m of msg.multicasts) {
    assert.equal(m.android.notification.channelId, 'tiyatrol_default'); assert.equal(m.android.priority, 'high'); assert.equal(m.android.ttl, 120000);
    assert.equal(m.apns.payload.aps['interruption-level'], 'active'); assert.equal(m.data.kind, 'alarm'); assert.equal(m.notification.title, 'ALARM');
  }
});

test('alarm + karışık alıcılar: izinliler alarm kanalına, diğerleri normal kanala (iki multicast); log loudCount; önizleme X/Y', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2) }, { u: 'u3', token: tok(3) }, { u: 'u4' }] });
  await db.collection('User').doc('u1').update({ notifPrefs: { loudAlarm: true } });
  await db.collection('User').doc('u2').update({ notifPrefs: { loudAlarm: false } });
  const tgt = { type: 'event', id: 'ev1' };
  const pv = await n.adminNotifyPreview(admin, { target: tgt });
  assert.deepEqual(pv.loudAlarm, { optedIn: 1, of: 3 }); // token'sız u4 sayılmaz
  const r = await n.adminSendNotification(admin, { target: tgt, title: 'Acil', body: 'Gelin', kind: 'alarm', confirm: true });
  assert.equal(msg.multicasts.length, 2);
  const loud = msg.multicasts.find((m) => m.android.notification.channelId === 'tiyatrol_alarm');
  const quiet = msg.multicasts.find((m) => m.android.notification.channelId === 'tiyatrol_default');
  assert.deepEqual(loud.tokens, [tok(1)]); assert.deepEqual(quiet.tokens.sort(), [tok(2), tok(3)]);
  assert.equal(loud.apns.payload.aps['interruption-level'], 'time-sensitive');
  assert.equal(r.loudCount, 1); assert.equal(r.success, 3);
  const log = (await db.collection('NotificationLog').doc(r.logId).get()).data();
  assert.equal(log.loudCount, 1);
});

test('normal tür: tercihten etkilenmez (tek multicast, alarm kanalı yok); konu hedefli alarm NORMAL kanala gider', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await seedUser('a', { token: tok(1), loud: true });
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'Merhaba', body: 'Duyuru' });
  assert.equal(msg.multicasts.length, 1); assert.equal(msg.multicasts[0].android.notification, undefined);
  await n.adminSendNotification(admin, { target: { type: 'all' }, title: 'Herkese', body: 'Acil', kind: 'alarm', confirm: true });
  assert.equal(msg.topics.length, 1); assert.equal(msg.topics[0].android.notification.channelId, 'tiyatrol_default');
  assert.equal(msg.topics[0].apns.payload.aps['interruption-level'], 'active');
});

test('normal: alarm kanalı/öncelik/time-sensitive YOK', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await seedUser('a', { token: tok(1) });
  await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'Merhaba', body: 'Duyuru' });
  const m = msg.multicasts[0];
  assert.equal(m.android.priority, 'normal'); assert.equal(m.android.notification, undefined); assert.equal(m.data.kind, 'normal');
  assert.equal(m.apns.payload.aps['interruption-level'], undefined); assert.equal(m.apns.headers, undefined);
});

// ------------------------------------------------------------------ sınırlar
test('başlık 60 / mesaj 240 karakter sınırı; boş metin; geçersiz kind/şablon/istek kimliği', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await seedUser('a', { token: tok(1) });
  const t = { type: 'user', id: 'a' };
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'x'.repeat(61), body: 'b' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'a', body: 'x'.repeat(241) }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: '  ', body: 'b' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'a', body: '' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'a', body: 'b', kind: 'siren' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'a', body: 'b', template: 'yok' }), 'invalid-argument');
  await expectCode(n.adminSendNotification(admin, { target: t, title: 'a', body: 'b', requestId: 'kisa' }), 'invalid-argument');
  const ok = await n.adminSendNotification(admin, { target: t, title: 'x'.repeat(60), body: 'y'.repeat(240) });
  assert.equal(ok.success, 1); assert.equal(msg.multicasts.length, 1);
});

test('saatlik gönderim sınırı: yönetici başına 30; 31. reddedilir, başka yönetici etkilenmez, saat dolunca açılır', async () => {
  const a1 = await makeAdmin('adm1'), a2 = await makeAdmin('adm2');
  const now = clock(Date.UTC(2026, 9, 26, 12, 0, 0));
  const { n } = makeNotifier({ now });
  await seedUser('a', { token: tok(1) });
  const send = (admin, i) => n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'T', body: `m${i}`, requestId: `istek_${admin}_${i}_xxxx` });
  for (let i = 0; i < 30; i++) await send(a1, i);
  await expectCode(send(a1, 31), 'resource-exhausted');
  await send(a2, 1);
  now.advance(HOUR + 1000);
  await send(a1, 32);
});

test('şablonlar: sunucuda üretilir (istemci metni yok sayılır), değişkenler dolar; alarm şablonu alarm yollar', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1) }] });
  await db.collection('User').doc('u1').update({ notifPrefs: { loudAlarm: true } });
  const tgt = { type: 'event', id: 'ev1' };
  const r = await n.adminSendNotification(admin, { target: tgt, template: 'baslamak_uzere', params: { dk: 5 }, title: 'SAHTE', body: 'SAHTE', kind: 'normal', confirm: true });
  assert.equal(r.title, 'Hamlet 5 dakika sonra başlıyor'); assert.match(r.body, /Büyük Sahne/); assert.equal(r.kind, 'alarm');
  assert.equal(msg.multicasts[0].android.notification.channelId, 'tiyatrol_alarm');
  assert.equal(msg.multicasts[0].data.eventId, 'ev1');
  await expectCode(n.adminSendNotification(admin, { target: tgt, template: 'baslamak_uzere', params: { dk: 7 }, confirm: true }), 'invalid-argument');
  const r2 = await n.adminSendNotification(admin, { target: tgt, template: 'ara', params: { dk: 20 }, confirm: true });
  assert.equal(r2.body, 'Hamlet — 20 dakika ara.'); assert.equal(r2.kind, 'normal');
  const r3 = await n.adminSendNotification(admin, { target: tgt, template: 'ara_bitiyor', confirm: true });
  assert.equal(r3.kind, 'alarm');
  const r4 = await n.adminSendNotification(admin, { target: tgt, template: 'bitti', confirm: true });
  assert.match(r4.title, /Hamlet bitti/);
  const r5 = await n.adminSendNotification(admin, { target: tgt, template: 'basladi', confirm: true });
  assert.match(r5.body, /sessize/);
});

test('sahne şablonları yalnızca seansa ±24 saat kala; yalnız seans hedefiyle; ertelendi/iptal/genel zaman sınırsız (özel metin)', async () => {
  const admin = await makeAdmin();
  const { n } = makeNotifier();
  await scene({ date: eventDate(30 * HOUR), specs: [{ u: 'u1', token: tok(1) }] });
  await expectCode(n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'basladi', confirm: true }), 'failed-precondition');
  await expectCode(n.adminSendNotification(admin, { target: { type: 'show', id: 'show1' }, template: 'basladi', confirm: true }), 'failed-precondition');
  await expectCode(n.adminSendNotification(admin, { target: { type: 'all' }, template: 'basladi', confirm: true }), 'failed-precondition');
  const pv = await n.adminNotifyPreview(admin, { target: { type: 'event', id: 'ev1' }, template: 'basladi' });
  assert.match(pv.blocked, /±24/); assert.equal(pv.preview, null);
  await expectCode(n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'ertelendi', confirm: true }), 'invalid-argument'); // özel metin gerekli
  const ok = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'ertelendi', body: 'Yeni tarih yakında duyurulacak.', confirm: true });
  assert.equal(ok.title, 'Hamlet seansı ertelendi');
  const g = await n.adminSendNotification(admin, { target: { type: 'all' }, template: 'genel', title: 'Duyuru', body: 'Merhaba', confirm: true });
  assert.equal(g.topic, true);
  await db.collection('Event').doc('ev1').update({ date: eventDate(-20 * HOUR) }); // geçmiş ±24 içinde
  const past = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'bitti', confirm: true });
  assert.ok(past.title);
});

// ------------------------------------------------------------------ kayıt + idempotency + geçersiz token
test('NotificationLog: kim, hedef, şablon, alıcı/başarılı/başarısız sayıları, zaman', async () => {
  const admin = await makeAdmin();
  const { n } = makeNotifier({ messaging: fakeMessaging({ dead: [tok(2)] }) });
  await scene({ specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2) }] });
  const r = await n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, template: 'basladi', confirm: true });
  const log = (await db.collection('NotificationLog').doc(r.logId).get()).data();
  assert.equal(log.sentBy, admin); assert.equal(log.target.type, 'event'); assert.equal(log.target.id, 'ev1'); assert.equal(log.template, 'basladi');
  assert.equal(log.recipients, 2); assert.equal(log.withToken, 2); assert.equal(log.success, 1); assert.equal(log.failure, 1); assert.equal(log.status, 'done');
  assert.ok(log.createdAt.toMillis); assert.equal(log.kind, 'normal');
  assert.equal((await db.collection('User').doc('u2').get()).data().fcmToken, ''); // kalıcı geçersiz token temizlendi
  assert.equal((await db.collection('User').doc('u1').get()).data().fcmToken, tok(1));
});

test('FCM tümden başarısız: uygulama içi bildirim yine yazılır, failure sayılır, istek patlamaz', async () => {
  const admin = await makeAdmin();
  const { n } = makeNotifier({ messaging: fakeMessaging({ failAll: true }) });
  await seedUser('a', { token: tok(1) });
  const r = await n.adminSendNotification(admin, { target: { type: 'user', id: 'a' }, title: 'T', body: 'B' });
  assert.equal(r.success, 0); assert.equal(r.failure, 1); assert.equal((await notifs()).length, 1);
});

test('idempotency: aynı requestId ikinci kez -> duplicate, yeni push yok, Notification çoğalmaz', async () => {
  const admin = await makeAdmin();
  const { n, msg } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2) }] });
  const a = { target: { type: 'event', id: 'ev1' }, title: 'Duyuru', body: 'Merhaba', confirm: true, requestId: 'panel_istek_0001' };
  const r1 = await n.adminSendNotification(admin, a);
  const r2 = await n.adminSendNotification(admin, a);
  assert.equal(r1.duplicate, false); assert.equal(r2.duplicate, true); assert.equal(r2.recipients, 2);
  assert.equal(msg.multicasts.length, 1); assert.equal((await notifs()).length, 2);
  assert.equal((await db.collection('NotificationLog').get()).size, 1);
  // kimlik yok: aynı içerik 10 dk içinde tekrar -> yine tek gönderim
  const b = { target: { type: 'user', id: 'u1' }, title: 'X', body: 'Y' };
  await n.adminSendNotification(admin, b);
  assert.equal((await n.adminSendNotification(admin, b)).duplicate, true);
  assert.equal(msg.multicasts.length, 2);
  // farklı requestId -> yeni gönderim
  const r3 = await n.adminSendNotification(admin, { ...a, requestId: 'panel_istek_0002' });
  assert.equal(r3.duplicate, false);
});

test('hiç aktif bilet sahibi yoksa gönderilmez', async () => {
  const admin = await makeAdmin();
  const { n } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1), status: 'cancelled' }] });
  await expectCode(n.adminSendNotification(admin, { target: { type: 'event', id: 'ev1' }, title: 'a', body: 'b', confirm: true }), 'failed-precondition');
  await expectCode(n.adminSendNotification(admin, { target: { type: 'event', id: 'yok' }, title: 'a', body: 'b', confirm: true }), 'not-found');
});

// ------------------------------------------------------------------ eventReminders
test('eventReminders: ~24 saat kala bildirim + bayrak; ikinci çalışma hiçbir şey göndermez (idempotent)', async () => {
  const { n, msg } = makeNotifier();
  await scene({ date: eventDate(23 * HOUR), specs: [
    { u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2), status: 'cancelled' }, { u: 'u3', token: tok(3), status: 'no_show' }, { u: 'u4' },
  ] });
  const r = await n.eventReminders();
  assert.equal(r.enabled, true); assert.equal(r.sent24, 2); assert.equal(r.sent2, 0); assert.equal(r.events, 1);
  assert.deepEqual(msg.multicasts[0].tokens, [tok(1)]);
  const docs = await notifs();
  assert.deepEqual(docs.map((d) => d.id).sort(), ['rem24_ev1_u1', 'rem24_ev1_u4']);
  assert.equal(docs[0].type, 'reminder'); assert.match(docs.find((d) => d.userId === 'u1').body, /Hamlet, \d\d:\d\d, Büyük Sahne/);
  assert.match(docs[0].body, /^(Yarın|Bugün)/);
  const flagged = (await db.collection('Ticket').where('eventId', '==', 'ev1').get()).docs.filter((d) => d.data().remind24At);
  assert.equal(flagged.length, 2);
  const again = await n.eventReminders();
  assert.equal(again.sent24, 0); assert.equal(msg.multicasts.length, 1); assert.equal((await notifs()).length, 2);
  const hb = (await db.collection('System').doc('eventReminders').get()).data();
  assert.equal(hb.enabled, true); assert.ok(hb.lastRunAt.toMillis);
});

test('eventReminders: ~2 saat kala ayrı hatırlatma; 24 sa. bayrağı ve 2 sa. bayrağı birbirinden bağımsız', async () => {
  const { n, msg } = makeNotifier();
  await scene({ date: eventDate(90 * 60e3), specs: [{ u: 'u1', token: tok(1) }] });
  const r = await n.eventReminders();
  assert.equal(r.sent2, 1); assert.equal(r.sent24, 0);
  assert.equal(msg.multicasts[0].notification.title, 'Seansa 2 saat kaldı'); assert.match(msg.multicasts[0].notification.body, /^2 saat sonra Hamlet/);
  assert.equal(msg.multicasts[0].data.kind, 'normal');
  const t = (await db.collection('Ticket').where('eventId', '==', 'ev1').get()).docs[0].data();
  assert.ok(t.remind2At); assert.equal(t.remind24At, undefined);
  assert.equal((await n.eventReminders()).sent2, 0);
});

test('eventReminders: pencere dışı seanslar (3 sa, 30 sa, geçmiş) bildirilmez; kullanılmış bilet atlanır', async () => {
  const { n, msg } = makeNotifier();
  await scene({ date: eventDate(3 * HOUR), specs: [{ u: 'u1', token: tok(1) }] });
  await scene({ eventId: 'ev2', date: eventDate(30 * HOUR), specs: [{ u: 'u2', token: tok(2) }] });
  await scene({ eventId: 'ev3', date: eventDate(-2 * HOUR), specs: [{ u: 'u3', token: tok(3) }] });
  await scene({ eventId: 'ev4', date: eventDate(90 * 60e3), specs: [{ u: 'u4', token: tok(4), usedAt: Timestamp.now() }] });
  const r = await n.eventReminders();
  assert.equal(r.sent24 + r.sent2, 0); assert.equal(msg.multicasts.length, 0);
});

test('eventReminders: Config/bildirim.autoReminders=false iken gönderilmez (kalp atışı yazılır); varsayılan açık', async () => {
  const { n, msg } = makeNotifier();
  await scene({ date: eventDate(23 * HOUR), specs: [{ u: 'u1', token: tok(1) }] });
  await db.collection('Config').doc('bildirim').set({ autoReminders: false });
  const off = await n.eventReminders();
  assert.equal(off.enabled, false); assert.equal(msg.multicasts.length, 0); assert.equal((await notifs()).length, 0);
  assert.equal((await db.collection('System').doc('eventReminders').get()).data().enabled, false);
  await db.collection('Config').doc('bildirim').set({ autoReminders: true });
  assert.equal((await n.eventReminders()).sent24, 1);
});

test('eventReminders: eşzamanlı iki çalışma tek bildirim/push üretir (create kilidi)', async () => {
  const { n, msg } = makeNotifier();
  await scene({ date: eventDate(23 * HOUR), specs: [{ u: 'u1', token: tok(1) }, { u: 'u2', token: tok(2) }] });
  await Promise.all([n.eventReminders(), n.eventReminders()]);
  assert.equal((await notifs()).length, 2);
  assert.equal(msg.multicasts.reduce((a, m) => a + m.tokens.length, 0), 2);
});

test('eventReminders: Timestamp tipli Event.date de yakalanır', async () => {
  const { n, msg } = makeNotifier();
  await scene({ specs: [{ u: 'u1', token: tok(1) }] });
  await db.collection('Event').doc('ev1').update({ date: Timestamp.fromMillis(Date.now() + 23 * HOUR) });
  assert.equal((await n.eventReminders()).sent24, 1); assert.equal(msg.multicasts.length, 1);
});

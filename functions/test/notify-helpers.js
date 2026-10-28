'use strict';
// Bildirim/istatistik testleri için ortak yardımcılar (Firestore EMÜLATÖRÜ gerekir).
const H = require('./helpers');
const { createNotifier } = require('../src/notify');
const { createStats } = require('../src/stats');
const { makeAssertAdmin } = require('../src/util');

const { db } = H;

/** Sahte FCM: hiçbir ağ çağrısı yok; gönderilenleri kaydeder. `dead`: kalıcı geçersiz sayılacak token'lar. */
function fakeMessaging({ dead = [], failAll = false } = {}) {
  const m = { multicasts: [], topics: [] };
  m.sendEachForMulticast = async (msg) => {
    m.multicasts.push(msg);
    const responses = msg.tokens.map((t) => {
      if (failAll) return { success: false, error: { code: 'messaging/internal-error' } };
      if (dead.includes(t)) return { success: false, error: { code: 'messaging/registration-token-not-registered' } };
      return { success: true, messageId: 'm' };
    });
    const successCount = responses.filter((r) => r.success).length;
    return { successCount, failureCount: responses.length - successCount, responses };
  };
  m.send = async (msg) => { m.topics.push(msg); return 'proj/messages/1'; };
  return m;
}

function makeNotifier({ now, messaging } = {}) {
  const msg = messaging || fakeMessaging();
  const n = createNotifier({ db, messaging: msg, assertAdmin: makeAssertAdmin(db), now: now || Date.now, log: { error() {}, info() {}, warn() {} } });
  return { n, msg };
}

function makeStats({ now } = {}) {
  const assertAdmin = makeAssertAdmin(db);
  const s = createStats({ db, now: now || Date.now, log: { error() {}, info() {}, warn() {} } });
  return { s, assertAdmin };
}

const tok = (i) => `fcm_token_${String(i).padStart(6, '0')}_${'x'.repeat(24)}`;

/** Kullanıcı + (isteğe bağlı) token. */
async function seedUser(uid, { token, role = 'user', name = 'Test', loud, tokens } = {}) {
  await db.collection('User').doc(uid).set({ role, firstName: name, lastName: uid, ...(token ? { fcmToken: token } : {}), ...(tokens ? { fcmTokens: tokens } : {}), ...(loud === undefined ? {} : { notifPrefs: { loudAlarm: loud } }) });
}

let tseq = 0;
async function seedTicket({ customerId, eventId, showId = 'show1', paymentStatus, orderMethod = 'venue', usedAt, cancelledAt, createdAt, extra = {} }) {
  const id = `tk${++tseq}_${Date.now()}`;
  await db.collection('Ticket').doc(id).set({
    _id: id, customerId, eventId, showId, stageId: 'stage1', orderMethod, buySeats: ['A1'], orderPrice: '100.00',
    showName: 'Test Oyunu', stageName: 'Test Sahne', eventDate: '', _createdAt: createdAt || new Date().toISOString(),
    ...(paymentStatus ? { paymentStatus } : {}), ...(usedAt ? { usedAt } : {}), ...(cancelledAt ? { cancelledAt } : {}), ...extra,
  });
  return id;
}

module.exports = { fakeMessaging, makeNotifier, makeStats, seedUser, seedTicket, tok };

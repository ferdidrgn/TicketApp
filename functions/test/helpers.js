'use strict';
// Test yardımcıları — Firestore EMÜLATÖRÜ gerekir (npm run test:emulator).
const PROJECT = process.env.GCLOUD_PROJECT || 'ticketappflutter';
process.env.GCLOUD_PROJECT = PROJECT;
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('FIRESTORE_EMULATOR_HOST yok: testleri `npm run test:emulator` ile çalıştırın.');
}
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const crypto = require('crypto');
const { createService } = require('../src/orders');
const { phoneKeyOf } = require('../src/phone');

if (!getApps().length) initializeApp({ projectId: PROJECT });
const db = getFirestore();

async function clearDb() {
  const res = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  if (!res.ok) throw new Error('clearDb başarısız');
}

/** Ayarlanabilir saat. */
function clock(start = Date.now()) {
  let t = start;
  const fn = () => t;
  fn.advance = (ms) => { t += ms; };
  fn.set = (v) => { t = v; };
  return fn;
}

/** Sahte ödeme sağlayıcısı: HTTP yok, sonuçları test belirler. */
function fakeProvider() {
  const results = new Map();
  const p = {
    name: 'iyzico', initCalls: [], retrieveCalls: [],
    async initialize(args) {
      p.initCalls.push(args);
      return { token: `tok_${args.order.id}`, paymentPageUrl: `https://pay.test/${args.order.id}`, checkoutFormContent: '<script></script>' };
    },
    async retrieve({ token, conversationId }) {
      p.retrieveCalls.push({ token, conversationId });
      const r = results.get(token);
      if (!r) return { ok: true, paid: false, paidPrice: NaN, price: NaN, currency: null, conversationId, basketId: conversationId, paymentId: null, rawStatus: 'FAILURE' };
      return r;
    },
    /** Başarılı ödeme sonucu; override ile bozulabilir. */
    succeed(orderId, total, override = {}) {
      results.set(`tok_${orderId}`, { ok: true, paid: true, paidPrice: total, price: total, currency: 'TRY', conversationId: orderId, basketId: orderId, paymentId: 'pay_1', rawStatus: 'SUCCESS', ...override });
    },
    fail(orderId) { results.delete(`tok_${orderId}`); },
  };
  return p;
}

const silent = { error() {}, info() {}, warn() {} };

const TEST_SALT = 'test-salt';
/** Her uid için deterministik, geçerli E.164 sahte telefon (testlerde 'doğrulanmış token' yerine geçer). */
const phoneFor = (uid) => '+90555' + String(parseInt(crypto.createHash('md5').update(String(uid)).digest('hex').slice(0, 7), 16) % 10000000).padStart(7, '0');
const keyFor = (phone) => phoneKeyOf(phone, TEST_SALT);
const PHONE_METHODS = ['holdSeats', 'confirmFree', 'confirmReservation', 'startPayment'];
/** Servisi sarar: telefon bağlamı verilmezse uid'den türetilen sahte DOĞRULANMIŞ telefon eklenir. ctx içinde `phone` anahtarı varsa (null dahil) aynen geçer. */
function withDefaultPhone(raw) {
  const svc = { ...raw };
  for (const m of PHONE_METHODS) {
    svc[m] = (uid, data, ctx) => raw[m](uid, data, ctx && 'phone' in ctx ? ctx : { ...(ctx || {}), phone: phoneFor(uid) });
  }
  return svc;
}

/** `satis`: sabit Config/satis (varsayılan: online -> mevcut ödeme testleri değişmez). `satis:'db'` -> gerçek belgeyi okur. */
function makeService({ now, provider, satis = { mode: 'online' } } = {}) {
  const prov = provider || fakeProvider();
  const svc = createService({
    db, now: now || Date.now, getProvider: (n) => (n === 'iyzico' ? prov : null),
    callbackUrl: 'https://cb.test/iyzicoCallback', siteUrl: 'https://tiyatrol-web.web.app',
    allowedOrigins: ['https://tiyatrol.web.app'], log: silent, phoneSalt: TEST_SALT,
    ...(satis === 'db' ? {} : { settings: async () => satis }),
  });
  return { svc: withDefaultPhone(svc), raw: svc, prov };
}

/** İstanbul yerel "gg.aa.yyyy,ss:dd" biçimi: şimdiden `deltaMs` sonrası. */
function eventDate(deltaMs) {
  const d = new Date(Date.now() + deltaMs + 3 * 3600e3); // UTC alanlarıyla İstanbul saati
  const p = (n) => String(n).padStart(2, '0');
  return `${p(d.getUTCDate())}.${p(d.getUTCMonth() + 1)}.${d.getUTCFullYear()},${p(d.getUTCHours())}:${p(d.getUTCMinutes())}`;
}

let seq = 0;
async function seedEvent({ price = '100', date = eventDate(7 * 864e5), seatNames = ['A1', 'A2', 'A3', 'A4', 'A5'], id, showId = 'show1', stageId = 'stage1' } = {}) {
  const eventId = id || `ev${++seq}_${Date.now()}`;
  const seats = {};
  for (const s of seatNames) seats[s] = { status: 'available' };
  await db.collection('Event').doc(eventId).set({ _id: eventId, showId, stageId, date, price, seats });
  await db.collection('Show').doc(showId).set({ name: 'Test Oyunu', imageUrl: 'https://img.test/a.png' });
  await db.collection('Stage').doc(stageId).set({ name: 'Test Sahne' });
  return eventId;
}

const uidN = () => `u${++seq}_${Math.random().toString(36).slice(2, 8)}`;

async function expectCode(promise, code) {
  try { await promise; } catch (e) {
    if (e.code !== code && e.httpErrorCode?.status !== code) throw new Error(`beklenen ${code}, gelen ${e.code}: ${e.message}`);
    return e;
  }
  throw new Error(`beklenen ${code} hatası oluşmadı`);
}

async function setSatis(d) { await db.collection('Config').doc('satis').set(d); }
async function makeAdmin(uid = 'admin1') { await db.collection('User').doc(uid).set({ role: 'admin', firstName: 'Yön', lastName: 'Etici' }); return uid; }

const AUTH_HOST = () => process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
/** Auth emülatöründe SMS doğrulamasıyla telefonlu oturum açar (linkIdToken verilirse mevcut oturuma telefon bağlar). -> { token, uid } */
async function signInPhone(phone, linkIdToken) {
  const base = `http://${AUTH_HOST()}/identitytoolkit.googleapis.com/v1/accounts`;
  const post = async (path, body) => (await fetch(`${base}:${path}?key=fake`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) })).json();
  const sent = await post('sendVerificationCode', { phoneNumber: phone, recaptchaToken: 'fake' });
  const codes = await (await fetch(`http://${AUTH_HOST()}/emulator/v1/projects/${PROJECT}/verificationCodes`)).json();
  const code = codes.verificationCodes.filter((c) => c.sessionInfo === sent.sessionInfo).pop().code;
  const j = await post('signInWithPhoneNumber', { sessionInfo: sent.sessionInfo, code, ...(linkIdToken ? { idToken: linkIdToken } : {}) });
  if (!j.idToken) throw new Error('telefon girişi başarısız: ' + JSON.stringify(j));
  return { token: j.idToken, uid: j.localId };
}

module.exports = { signInPhone, phoneFor, keyFor, TEST_SALT, setSatis, makeAdmin, db, Timestamp, clearDb, clock, fakeProvider, makeService, seedEvent, eventDate, uidN, expectCode, PROJECT };

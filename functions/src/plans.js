'use strict';
/**
 * "Birlikte gidelim" planı (F-6, docs/ANKET-PLAN.md).
 *
 * Plan/{id}: { showId, eventId|null, showName, eventDate|null, counts:{gelirim,belki,gelemem}, responseCount, createdAt, expireAt }
 *   -> id tahmin edilemez (12 karakter rastgele), HERKESE okunur; oluşturanın kimliği/adı/telefonu BU belgede YOK.
 *   `expireAt` (7 gün) Firestore TTL alanıdır: Console > Firestore > TTL'de `Plan.expireAt` ve koleksiyon grubu `responses.expireAt` için politika açılmalı.
 * PlanOwner/{id}: { creatorUid } — yalnız sunucu (istemci okuyamaz).
 * Plan/{id}/responses/{responderKey}: { name (takma ad), choice, updatedAt, updates, expireAt } — istemciye KAPALI; yalnız plan sahibi getPlanResponses ile görür.
 *   responderKey = sha256(planId + ':' + cihaz anahtarı) (cihaz anahtarı tarayıcıda rastgele; kimlik değildir).
 * Yanıt (respondPlan) GİRİŞSİZDİR: IP/uid olmadığı için korumalar = günlük GLOBAL tavan + plan başına <=50 yanıt + yanıt başına <=10 güncelleme + metin süzgeci.
 */
const crypto = require('crypto');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, validateId, parseEventDateMs } = require('./util');
const { isBlocking, deletionPendingError } = require('./accountDeletion');
const { freeTextProblem } = require('./team');
const { checkText } = require('./moderation-words');

const P = cfg.PLAN;
const CHOICES = ['gelirim', 'belki', 'gelemem'];
const ID_RE = /^[A-Za-z0-9]{10,32}$/;
const KEY_RE = /^[A-Za-z0-9_-]{16,64}$/;
const msOf = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);
const dayKey = (ms) => new Date(ms + cfg.TZ_OFFSET_MIN * 60000).toISOString().slice(0, 10);
function newId() {
  const A = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const b = crypto.randomBytes(12);
  let s = ''; for (let i = 0; i < 12; i++) s += A[b[i] % A.length];
  return s;
}

function createPlans({ db, now = Date.now, log = console }) {
  const col = (n) => db.collection(n);

  async function rateLimit(uid) {
    const ref = col('PlanLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let hs = d.hourStart || 0, hc = d.hourCount || 0, ds = d.dayStart || 0, dc = d.dayCount || 0;
      if (t - hs >= 3600e3) { hs = t; hc = 0; }
      if (t - ds >= 86400e3) { ds = t; dc = 0; }
      if (hc + 1 > P.CREATE.perHour) throw err('resource-exhausted', 'Çok sık plan oluşturdun. Biraz sonra tekrar dene.');
      if (dc + 1 > P.CREATE.perDay) throw err('resource-exhausted', 'Günlük plan sınırına ulaştın. Yarın tekrar dene.');
      tx.set(ref, { hourStart: hs, hourCount: hc + 1, dayStart: ds, dayCount: dc + 1 });
    });
  }

  /** Günlük küresel tavan belgesi: PlanLimits/day_YYYY-MM-DD { plans, responses }. */
  const globalRef = () => col('PlanLimits').doc(`day_${dayKey(now())}`);

  // ---------------------------------------------------------------- oluştur (girişli)
  async function createPlan(uid, data, ctx = {}) {
    if (ctx.anonymous) throw err('permission-denied', 'Plan oluşturmak için giriş yapmalısın.');
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const showId = validateId(data.showId, 'oyun');
    const eventId = data.eventId == null || data.eventId === '' ? null : validateId(data.eventId, 'seans');
    const del = await col('AccountDeletion').doc(uid).get();
    if (del.exists && isBlocking(del.data())) throw deletionPendingError(msOf(del.data().scheduledAt));
    const show = await col('Show').doc(showId).get();
    if (!show.exists) throw err('not-found', 'Oyun bulunamadı.');
    let eventDate = null;
    if (eventId) {
      const ev = await col('Event').doc(eventId).get();
      if (!ev.exists) throw err('not-found', 'Seans bulunamadı.');
      const e = ev.data();
      // Event.showId doluysa TEK doğruluk kaynağı odur; dizi (Show.eventsId) yalnız o alan boşsa yedek.
      const belongs = e.showId ? e.showId === showId : (show.data().eventsId || []).includes(eventId);
      if (!belongs) throw err('invalid-argument', 'Seans bu oyuna ait değil.');
      const ms = parseEventDateMs(e.date);
      if (ms != null && ms < now()) throw err('failed-precondition', 'Bu seans geçmiş; plan oluşturulamaz.');
      if (ms != null) eventDate = Timestamp.fromMillis(ms);
    }
    await rateLimit(uid);
    const g = globalRef();
    const id = newId(), t = now();
    await db.runTransaction(async (tx) => {
      const gs = (await tx.get(g)).data() || {};
      if ((gs.plans || 0) >= P.GLOBAL_DAILY.plans) throw err('resource-exhausted', 'Bugün çok fazla plan oluşturuldu. Yarın tekrar dene.');
      tx.set(g, { plans: FieldValue.increment(1), expireAt: Timestamp.fromMillis(t + 3 * 864e5) }, { merge: true });
      tx.create(col('Plan').doc(id), {
        showId, eventId, showName: String(show.data().name || '').slice(0, 120), eventDate,
        counts: { gelirim: 0, belki: 0, gelemem: 0 }, responseCount: 0,
        createdAt: Timestamp.fromMillis(t), expireAt: Timestamp.fromMillis(t + P.TTL_MS),
      });
      tx.create(col('PlanOwner').doc(id), { creatorUid: uid, expireAt: Timestamp.fromMillis(t + P.TTL_MS) });
    });
    return { ok: true, id, path: `/plan/${id}`, expiresAt: new Date(t + P.TTL_MS).toISOString() };
  }

  // ---------------------------------------------------------------- yanıt (GİRİŞSİZ)
  function cleanName(raw) {
    const v = typeof raw === 'string' ? raw.normalize('NFKC').replace(/[\u0000-\u001f\u007f]/g, '').trim().replace(/\s+/g, ' ') : '';
    if (!v) throw err('invalid-argument', 'Bir takma ad yaz.');
    if (Array.from(v).length > P.NAME_MAX) throw err('invalid-argument', `Ad en fazla ${P.NAME_MAX} karakter olabilir.`);
    if (/[<>]/.test(v)) throw err('invalid-argument', 'Adda < veya > olamaz.');
    const pr = freeTextProblem(v);
    if (pr) throw err('invalid-argument', pr.replace('Mesajda', 'Adda'));
    if (/\d{4,}/.test(v.replace(/\s/g, ''))) throw err('invalid-argument', 'Adda sayı dizisi olamaz.');
    if (checkText(v).flagged) throw err('invalid-argument', 'Bu ad kullanılamaz.');
    return v;
  }

  async function respondPlan(data) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const planId = typeof data.planId === 'string' && ID_RE.test(data.planId) ? data.planId : null;
    if (!planId) throw err('invalid-argument', 'Geçersiz plan.');
    if (typeof data.clientKey !== 'string' || !KEY_RE.test(data.clientKey)) throw err('invalid-argument', 'Geçersiz istek.');
    if (!CHOICES.includes(data.choice)) throw err('invalid-argument', 'Geçersiz yanıt.');
    const name = cleanName(data.name);
    const key = crypto.createHash('sha256').update(`plan:${planId}:${data.clientKey}`).digest('hex').slice(0, 40);
    const pRef = col('Plan').doc(planId), rRef = pRef.collection('responses').doc(key), g = globalRef();
    return db.runTransaction(async (tx) => {
      const [ps, rs, gs] = await Promise.all([tx.get(pRef), tx.get(rRef), tx.get(g)]);
      if (!ps.exists) throw err('not-found', 'Bu plan bulunamadı ya da süresi doldu.');
      const p = ps.data(), t = now();
      if (msOf(p.expireAt) != null && msOf(p.expireAt) <= t) throw err('not-found', 'Bu plan bulunamadı ya da süresi doldu.');
      const gd = gs.data() || {};
      if ((gd.responses || 0) >= P.GLOBAL_DAILY.responses) throw err('resource-exhausted', 'Şu an çok yoğunuz. Biraz sonra tekrar dene.');
      const counts = {};
      const stamp = Timestamp.fromMillis(t);
      if (!rs.exists) {
        if ((p.responseCount || 0) >= P.MAX_RESPONSES) throw err('resource-exhausted', 'Bu plana en fazla ' + P.MAX_RESPONSES + ' yanıt verilebilir.');
        counts['counts.' + data.choice] = FieldValue.increment(1);
        tx.create(rRef, { name, choice: data.choice, updatedAt: stamp, updates: 0, expireAt: p.expireAt });
        tx.update(pRef, { ...counts, responseCount: FieldValue.increment(1) });
      } else {
        const r = rs.data();
        if ((r.updates || 0) >= P.UPDATES_MAX) throw err('resource-exhausted', 'Bu yanıtı çok kez değiştirdin.');
        if (r.choice !== data.choice) {
          counts['counts.' + data.choice] = FieldValue.increment(1);
          counts['counts.' + r.choice] = FieldValue.increment(-1);
          tx.update(pRef, counts);
        }
        tx.update(rRef, { name, choice: data.choice, updatedAt: stamp, updates: FieldValue.increment(1) });
      }
      tx.set(g, { responses: FieldValue.increment(1), expireAt: Timestamp.fromMillis(t + 3 * 864e5) }, { merge: true });
      return { ok: true, choice: data.choice, created: !rs.exists };
    });
  }

  // ---------------------------------------------------------------- sahip görünümü
  async function getPlanResponses(uid, data) {
    const planId = validateId(data && data.planId, 'plan');
    const o = await col('PlanOwner').doc(planId).get();
    if (!o.exists || o.data().creatorUid !== uid) throw err('permission-denied', 'Bu planın yanıtlarını göremezsin.');
    const s = await col('Plan').doc(planId).collection('responses').limit(P.MAX_RESPONSES + 5).get();
    const items = s.docs.map((d) => ({ name: d.data().name || '', choice: d.data().choice, at: msOf(d.data().updatedAt) }))
      .sort((a, b) => (b.at || 0) - (a.at || 0)).map((x) => ({ ...x, at: x.at ? new Date(x.at).toISOString() : null }));
    return { planId, items };
  }

  return { createPlan, respondPlan, getPlanResponses };
}

module.exports = { createPlans };

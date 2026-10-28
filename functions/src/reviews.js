'use strict';
/**
 * Doğrulanmış yorum + moderasyon (docs/UGC-KURALLARI.md, docs/IS-PLANI.md Q-1/M-1).
 *
 * Yorumu YALNIZCA bu callable'lar yazar (firestore.rules: Review istemci yazımına kapalı). Kimlik `${uid}_${showId}`.
 * Yorum hakkı: telefonu doğrulanmış (token phone_number) + hesap silme beklemede değil + o oyunun GEÇMİŞ seansı için
 * geçerli (iptal/gelmedi olmayan) bileti var. Seans->oyun eşlemesi: Event.showId tek doğruluk kaynağı (boşsa Show.eventsId yedeği).
 * `userName` sunucuda User'dan türetilir (ad + soyad baş harfi). Metin sunucuda süzülür: URL/telefon/e-posta reddedilir,
 * küfür/nefret şüphesi yorumu `status:'pending'` (hidden:true) ile yönetici kuyruğuna düşürür.
 *
 * Review durum alanları: hidden(bool, görünürlük), status('published'|'pending'|'hidden'), hiddenReason(null|'pending'|'reports'|'moderator'),
 * reportCount, reportBaseline (geri açılınca sıfırlama noktası), queue(bool: yönetici kuyruğunda), verified:true, attended(bool).
 */
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const cfg = require('./config');
const { err, parseEventDateMs, validateId } = require('./util');
const { isBlocking, deletionPendingError } = require('./accountDeletion');
const { normalizeE164, phoneRequired } = require('./phone');
const { freeTextProblem } = require('./team');
const { checkText } = require('./moderation-words');
const { recomputeShowRating } = require('./reviewStats');

const R = cfg.REVIEW;
const INACTIVE = new Set(['cancelled', 'no_show']);
const REASONS = ['spam', 'hakaret', 'nefret', 'uygunsuz', 'kisisel_bilgi', 'diger'];
const msOf = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);
const iso = (ms) => (ms == null ? null : new Date(ms).toISOString());

function notVerified() {
  return new HttpsError('failed-precondition', 'Yorum yazabilmek için bu oyunu izlemiş olman gerekir.', { code: 'NOT_VERIFIED_ATTENDEE' });
}
function locked() {
  return new HttpsError('failed-precondition', 'Bu yorum moderasyon incelemesinde; şu an düzenlenemez.', { code: 'REVIEW_LOCKED' });
}
const isLocked = (d) => d && (d.hiddenReason === 'reports' || d.hiddenReason === 'moderator');

/** Görünen ad: "Ayşe K." — taklit edilemez (istemciden gelmez). */
function publicName(u) {
  const clean = (s) => String(s || '').normalize('NFKC').replace(/[^\p{L}' -]/gu, '').trim().replace(/\s+/g, ' ');
  const first = clean(u && u.firstName).slice(0, 30);
  const last = clean(u && u.lastName);
  if (!first) return 'Seyirci';
  const ch = last ? Array.from(last)[0] : '';
  return ch ? `${first} ${ch.toLocaleUpperCase('tr-TR')}.` : first;
}

function createReviews({ db, team, now = Date.now, log = console }) {
  const col = (n) => db.collection(n);
  const reviewId = (uid, showId) => `${uid}_${showId}`;

  async function assertAccountActive(uid) {
    const s = await col('AccountDeletion').doc(uid).get();
    if (s.exists && isBlocking(s.data())) throw deletionPendingError(msOf(s.data().scheduledAt));
  }
  const phoneOk = (ctx) => !!normalizeE164(ctx && ctx.phone);
  async function isAdminUser(uid) {
    const u = await col('User').doc(uid).get();
    return u.exists && u.data().role === 'admin';
  }

  /** Kullanıcının o oyun için GEÇMİŞ ve geçerli bileti var mı? -> { ok, attended } */
  async function attendance(uid, showId) {
    const snap = await col('Ticket').where('customerId', '==', uid).limit(R.MAX_TICKETS_SCAN).get();
    const byEvent = new Map();
    for (const d of snap.docs) {
      const t = d.data();
      if (INACTIVE.has(t.paymentStatus) || typeof t.eventId !== 'string' || !t.eventId) continue;
      const cur = byEvent.get(t.eventId) || { used: false };
      if (t.usedAt) cur.used = true;
      byEvent.set(t.eventId, cur);
    }
    let ok = false, attended = false;
    for (const [eventId, info] of [...byEvent.entries()].slice(0, 300)) {
      const scope = await team.resolveEventScope(eventId);
      if (!scope || scope.showId !== showId) continue;
      const ms = parseEventDateMs(scope.event.date);
      if (ms == null || ms >= now()) continue; // yalnız GEÇMİŞ seans
      ok = true;
      if (info.used) attended = true;
    }
    return { ok, attended };
  }

  /** Saatlik/günlük sayaç (ReviewLimits/{uid}); `kind`: 'sub' | 'rep'. */
  async function rateLimit(uid, kind) {
    const L = R[kind === 'rep' ? 'REPORT' : 'SUBMIT'];
    const ref = col('ReviewLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let hs = d[kind + 'HourStart'] || 0, hc = d[kind + 'HourCount'] || 0, ds = d[kind + 'DayStart'] || 0, dc = d[kind + 'DayCount'] || 0;
      if (t - hs >= 3600e3) { hs = t; hc = 0; }
      if (t - ds >= 86400e3) { ds = t; dc = 0; }
      if (hc + 1 > L.perHour) throw err('resource-exhausted', 'Çok sık işlem yaptın. Biraz sonra tekrar dene.');
      if (dc + 1 > L.perDay) throw err('resource-exhausted', 'Günlük işlem sınırına ulaştın. Yarın tekrar dene.');
      tx.set(ref, { [kind + 'HourStart']: hs, [kind + 'HourCount']: hc + 1, [kind + 'DayStart']: ds, [kind + 'DayCount']: dc + 1 }, { merge: true });
    });
  }

  // ---------------------------------------------------------------- yorum hakkı + yazma
  async function canReview(uid, data, ctx) {
    const showId = validateId(data && data.showId, 'oyun');
    const ex = await col('Review').doc(reviewId(uid, showId)).get();
    const existing = ex.exists ? { rating: ex.data().rating, text: ex.data().text, status: ex.data().status || 'published', locked: !!isLocked(ex.data()) } : null;
    const s = await col('AccountDeletion').doc(uid).get();
    if (s.exists && isBlocking(s.data())) return { canReview: false, code: 'ACCOUNT_DELETION_PENDING', existing };
    if (!phoneOk(ctx)) return { canReview: false, code: 'PHONE_REQUIRED', existing };
    const a = await attendance(uid, showId);
    if (!a.ok) return { canReview: false, code: 'NOT_VERIFIED_ATTENDEE', existing };
    return { canReview: true, code: null, existing };
  }

  async function submitReview(uid, data, ctx) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const showId = validateId(data.showId, 'oyun');
    const rating = data.rating;
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) throw err('invalid-argument', 'Puan 1 ile 5 arasında olmalı.');
    const text = data.text == null ? '' : data.text;
    if (typeof text !== 'string') throw err('invalid-argument', 'Yorum metni geçersiz.');
    const clean = text.normalize('NFC').trim();
    if (Array.from(clean).length > R.TEXT_MAX) throw err('invalid-argument', `Yorum en fazla ${R.TEXT_MAX} karakter olabilir.`);

    await assertAccountActive(uid);
    if (!phoneOk(ctx)) throw phoneRequired();
    const show = await col('Show').doc(showId).get();
    if (!show.exists) throw err('not-found', 'Oyun bulunamadı.');
    const att = await attendance(uid, showId);
    if (!att.ok) throw notVerified();
    const problem = freeTextProblem(clean);
    if (problem) throw err('invalid-argument', problem.replace('Mesajda', 'Yorumda'));

    const ref = col('Review').doc(reviewId(uid, showId));
    const prev = await ref.get();
    if (prev.exists && isLocked(prev.data())) throw locked();
    await rateLimit(uid, 'sub');

    const u = await col('User').doc(uid).get();
    const flagged = checkText(clean).flagged;
    const t = Timestamp.fromMillis(now());
    const fields = {
      showId, userId: uid, userName: publicName(u.exists ? u.data() : null), userImage: '', rating, text: clean,
      hidden: flagged, status: flagged ? 'pending' : 'published', hiddenReason: flagged ? 'pending' : null,
      verified: true, attended: att.attended, updatedAt: t, queue: flagged,
    };
    if (prev.exists) await ref.set(fields, { merge: true });
    else await ref.set({ ...fields, createdAt: t, _createdAt: iso(now()), reportCount: 0, reportBaseline: 0 });
    await recomputeShowRating(db, showId);
    return { ok: true, status: fields.status, pending: flagged, updated: prev.exists };
  }

  async function deleteMyReview(uid, data) {
    const showId = validateId(data && data.showId, 'oyun');
    const ref = col('Review').doc(reviewId(uid, showId));
    const s = await ref.get();
    if (!s.exists) return { ok: true, already: true };
    if (isLocked(s.data())) throw locked();
    await ref.delete();
    await recomputeShowRating(db, showId);
    return { ok: true };
  }

  // ---------------------------------------------------------------- şikâyet + engel
  async function reportContent(uid, data, ctx) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    if (data.type !== 'review') throw err('invalid-argument', 'Bu içerik türü şu an şikâyet edilemiyor.');
    const id = validateId(data.id, 'yorum');
    if (!REASONS.includes(data.reason)) throw err('invalid-argument', 'Geçersiz şikâyet nedeni.');
    const detail = data.detail == null ? '' : data.detail;
    if (typeof detail !== 'string' || detail.length > R.DETAIL_MAX) throw err('invalid-argument', `Açıklama en fazla ${R.DETAIL_MAX} karakter olabilir.`);
    const ref = col('Review').doc(id);
    const pre = await ref.get();
    if (!pre.exists) throw err('not-found', 'Yorum bulunamadı.');
    if (pre.data().userId === uid) throw err('invalid-argument', 'Kendi yorumunu şikâyet edemezsin.');
    await rateLimit(uid, 'rep');
    const counted = phoneOk(ctx); // yalnız telefon doğrulamalı şikâyetler eşiğe sayılır
    const repRef = col('ReviewReport').doc(`${id}_${uid}`);
    const out = await db.runTransaction(async (tx) => {
      const [rep, rv] = await Promise.all([tx.get(repRef), tx.get(ref)]);
      if (!rv.exists) throw err('not-found', 'Yorum bulunamadı.');
      if (rep.exists) return { already: true, hidden: rv.data().hidden === true, changed: false, showId: rv.data().showId };
      const d = rv.data();
      const count = (d.reportCount || 0) + (counted ? 1 : 0);
      const upd = { reportCount: count, queue: true };
      let changed = false;
      if (counted && !d.hidden && count - (d.reportBaseline || 0) >= R.AUTO_HIDE_AT) {
        Object.assign(upd, { hidden: true, status: 'hidden', hiddenReason: 'reports', hiddenAt: Timestamp.fromMillis(now()) });
        changed = true;
      }
      tx.set(repRef, { reviewId: id, showId: d.showId, userId: uid, reason: data.reason, detail, counted, createdAt: Timestamp.fromMillis(now()) });
      tx.update(ref, upd);
      return { already: false, hidden: upd.hidden === true || d.hidden === true, changed, showId: d.showId };
    });
    if (out.changed) await recomputeShowRating(db, out.showId);
    return { ok: true, already: out.already, hidden: out.hidden };
  }

  async function blockUser(uid, data) {
    const target = validateId(data && data.uid, 'kullanıcı');
    if (target === uid) throw err('invalid-argument', 'Kendini engelleyemezsin.');
    const c = col('User').doc(uid).collection('blocks');
    const ref = c.doc(target);
    if (!(await ref.get()).exists) {
      const n = (await c.count().get()).data().count;
      if (n >= R.MAX_BLOCKS) throw err('resource-exhausted', `En fazla ${R.MAX_BLOCKS} kullanıcı engelleyebilirsin.`);
      await ref.set({ blockedAt: Timestamp.fromMillis(now()) });
    }
    return { ok: true };
  }
  async function unblockUser(uid, data) {
    const target = validateId(data && data.uid, 'kullanıcı');
    await col('User').doc(uid).collection('blocks').doc(target).delete();
    return { ok: true };
  }

  // ---------------------------------------------------------------- moderasyon
  const reasonOf = (v) => {
    const s = typeof v === 'string' ? v.trim() : '';
    if (s.length < 3 || s.length > 200) throw err('invalid-argument', 'Moderasyon sebebi 3-200 karakter olmalı.');
    return s;
  };

  /** Ortak çekirdek: `scopeFn(review)` yetkiyi doğrular ve rolü döner ('admin'|'teamManager'). */
  async function moderate(uid, data, { adminOnly }) {
    // Yetki ÖNCE (yetkisiz çağrıya doğrulama ayrıntısı sızdırılmaz)
    if (adminOnly && !(await isAdminUser(uid))) throw err('permission-denied', 'Bu işlem için yönetici yetkisi gerekir.');
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const id = validateId(data.reviewId, 'yorum');
    const action = data.action;
    if (!['hide', 'restore', 'delete'].includes(action)) throw err('invalid-argument', 'Geçersiz işlem.');
    const reason = reasonOf(data.reason);
    const ref = col('Review').doc(id);
    const snap = await ref.get();
    let role;
    if (adminOnly) {
      role = 'admin';
      if (!snap.exists) throw err('not-found', 'Yorum bulunamadı.');
    } else {
      if (action === 'delete') throw err('permission-denied', 'Ekip yöneticisi yorum silemez; gizleyebilir.');
      if (!snap.exists) { if (!(await isAdminUser(uid))) throw err('permission-denied', 'Bu işlem için yetkin yok.'); throw err('not-found', 'Yorum bulunamadı.'); }
      role = (await team.assertCanManageShow(uid, snap.data().showId)).role; // başka ekibin yorumu -> permission-denied
    }
    const d = snap.data();
    const t = Timestamp.fromMillis(now());
    if (action === 'delete') {
      await ref.delete();
      const reps = await col('ReviewReport').where('reviewId', '==', id).get();
      for (let i = 0; i < reps.docs.length; i += 400) {
        const b = db.batch(); reps.docs.slice(i, i + 400).forEach((x) => b.delete(x.ref)); await b.commit();
      }
    } else if (action === 'hide') {
      await ref.update({ hidden: true, status: 'hidden', hiddenReason: 'moderator', hiddenAt: t, queue: false, moderatedBy: role });
    } else {
      await ref.update({ hidden: false, status: 'published', hiddenReason: null, queue: false, reportBaseline: d.reportCount || 0, moderatedBy: role, restoredAt: t });
    }
    await col('ModerationLog').add({
      at: t, by: uid, byRole: role, action, reviewId: id, showId: d.showId, targetUid: d.userId, reason,
      rating: d.rating, textSnapshot: String(d.text || '').slice(0, 300), prevStatus: d.status || (d.hidden ? 'hidden' : 'published'),
    });
    await recomputeShowRating(db, d.showId);
    return { ok: true, action };
  }

  /** Ekip yöneticisi / admin: bir oyunun yorumları (tüm durumlar). Kişisel veri: uid DÖNMEZ. */
  async function teamReviews(uid, data) {
    const showId = validateId(data && data.showId, 'oyun');
    await team.assertCanManageShow(uid, showId);
    const s = await col('Review').where('showId', '==', showId).limit(300).get();
    const items = s.docs.map((x) => {
      const d = x.data();
      return {
        id: x.id, userName: d.userName || '', rating: d.rating, text: d.text || '', hidden: d.hidden === true, status: d.status || (d.hidden ? 'hidden' : 'published'),
        hiddenReason: d.hiddenReason || null, reportCount: d.reportCount || 0, createdAt: iso(msOf(d.createdAt)),
      };
    }).sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
    return { showId, items };
  }

  return {
    canReview, submitReview, deleteMyReview, reportContent, blockUser, unblockUser,
    adminModerate: (uid, data) => moderate(uid, data, { adminOnly: true }),
    teamModerate: (uid, data) => moderate(uid, data, { adminOnly: false }),
    teamReviews,
  };
}

module.exports = { createReviews, publicName };

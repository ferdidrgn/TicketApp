'use strict';
/**
 * Ekibe soru sor (Q-2, docs/SSS-BOTU.md) — ÖN ONAYLI Q&A.
 *
 * Soruyu YALNIZCA bu callable'lar yazar (firestore.rules: Question istemci yazımına kapalı). Soru `status:'pending'` doğar; ekip
 * yöneticisi (o oyunun) ya da admin YANITLAYINCA `status:'answered'` olur ve ancak o zaman herkese görünür (cevapsız soru yayınlanmaz).
 * GİZLİLİK: Question belgesinde uid YOKTUR (kamuya açık okunur). Sahiplik `QuestionOwner/{id}` ({uid, showId}, yalnız sunucu) belgesindedir;
 * sahibi kendi bekleyen sorularını `myQuestions` ile görür. `askerName` sunucuda türetilir ("Ayşe K."), `askerKey` uid'in tek yönlü
 * özetidir (engelleme için: blockUser({questionId}) blocks belgesine aynı özeti yazar; istemci o özetle soruları gizler).
 *
 * Durumlar: pending (onay bekliyor) | answered (yayında) | hidden (şikâyet eşiği ya da moderatör) | rejected (reddedildi).
 * Görünürlük: hidden:bool — yalnız answered iken false.
 */
const crypto = require('crypto');
const { Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, validateId } = require('./util');
const { isBlocking, deletionPendingError } = require('./accountDeletion');
const { normalizeE164, phoneRequired } = require('./phone');
const { freeTextProblem } = require('./team');
const { checkText } = require('./moderation-words');
const { publicName } = require('./reviews');

const Q = cfg.QUESTION;
const REASONS = ['spam', 'hakaret', 'nefret', 'uygunsuz', 'kisisel_bilgi', 'diger'];
const msOf = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);
const iso = (ms) => (ms == null ? null : new Date(ms).toISOString());
const askerKeyOf = (uid) => crypto.createHash('sha256').update('tq-asker-v1:' + uid).digest('hex').slice(0, 16);
// Cevapta yalnız bağlantı reddedilir (ekip e-posta/telefon verebilir; sorunun kendisi için tam süzgeç uygulanır).
const ANSWER_URL_RE = /(https?:|ftp:|www\.|\bwa\.me|\bt\.me|\bbit\.ly|tinyurl)/i;

function createQuestions({ db, team, now = Date.now }) {
  const col = (n) => db.collection(n);

  async function assertAccountActive(uid) {
    const s = await col('AccountDeletion').doc(uid).get();
    if (s.exists && isBlocking(s.data())) throw deletionPendingError(msOf(s.data().scheduledAt));
  }
  const phoneOk = (ctx) => !!normalizeE164(ctx && ctx.phone);

  /** Saatlik/günlük sayaç (QuestionLimits/{uid}); kind: 'ask' | 'rep'. */
  async function rateLimit(uid, kind) {
    const L = Q[kind === 'rep' ? 'REPORT' : 'ASK'];
    const ref = col('QuestionLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let hs = d[kind + 'HourStart'] || 0, hc = d[kind + 'HourCount'] || 0, ds = d[kind + 'DayStart'] || 0, dc = d[kind + 'DayCount'] || 0;
      if (t - hs >= 3600e3) { hs = t; hc = 0; }
      if (t - ds >= 86400e3) { ds = t; dc = 0; }
      if (hc + 1 > L.perHour) throw err('resource-exhausted', kind === 'ask' ? `Saatte en fazla ${L.perHour} soru sorabilirsin. Biraz sonra tekrar dene.` : 'Çok sık işlem yaptın. Biraz sonra tekrar dene.');
      if (dc + 1 > L.perDay) throw err('resource-exhausted', kind === 'ask' ? `Günde en fazla ${L.perDay} soru sorabilirsin. Yarın tekrar dene.` : 'Günlük işlem sınırına ulaştın. Yarın tekrar dene.');
      tx.set(ref, { [kind + 'HourStart']: hs, [kind + 'HourCount']: hc + 1, [kind + 'DayStart']: ds, [kind + 'DayCount']: dc + 1 }, { merge: true });
    });
  }

  const view = (id, d) => ({
    id, showId: d.showId, askerName: d.askerName || '', text: d.text || '', status: d.status, answer: d.answer || null,
    answeredBy: d.answeredBy || null, answeredAt: iso(msOf(d.answeredAt)), createdAt: iso(msOf(d.createdAt)),
    hidden: d.hidden === true, reportCount: d.reportCount || 0,
  });

  // ---------------------------------------------------------------- soru sor
  async function askQuestion(uid, data, ctx) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const showId = validateId(data.showId, 'oyun');
    if (typeof data.text !== 'string') throw err('invalid-argument', 'Soru metni geçersiz.');
    const clean = data.text.normalize('NFC').replace(/\s+/g, ' ').trim();
    const len = Array.from(clean).length;
    if (len < Q.TEXT_MIN) throw err('invalid-argument', `Soru en az ${Q.TEXT_MIN} karakter olmalı.`);
    if (len > Q.TEXT_MAX) throw err('invalid-argument', `Soru en fazla ${Q.TEXT_MAX} karakter olabilir.`);

    await assertAccountActive(uid);
    if (!phoneOk(ctx)) throw phoneRequired();
    const show = await col('Show').doc(showId).get();
    if (!show.exists) throw err('not-found', 'Oyun bulunamadı.');
    const problem = freeTextProblem(clean);
    if (problem) throw err('invalid-argument', problem.replace('Mesajda', 'Sorunda'));
    if (checkText(clean).flagged) throw err('invalid-argument', 'Sorunda uygunsuz bir ifade var. Lütfen nazik bir dille yeniden yaz.');
    await rateLimit(uid, 'ask');

    const u = await col('User').doc(uid).get();
    const ref = col('Question').doc();
    const t = Timestamp.fromMillis(now());
    await ref.set({
      showId, askerName: publicName(u.exists ? u.data() : null), askerKey: askerKeyOf(uid), text: clean,
      status: 'pending', hidden: true, answer: null, answeredBy: null, answeredAt: null,
      createdAt: t, _createdAt: iso(now()), reportCount: 0, reportBaseline: 0,
    });
    await col('QuestionOwner').doc(ref.id).set({ uid, showId, createdAt: t });
    return { ok: true, id: ref.id, status: 'pending' };
  }

  /** Kendi sorularım (bekleyen/yanıtlanan/reddedilen). uid dönmez. */
  async function myQuestions(uid, data) {
    const showId = data && data.showId != null ? validateId(data.showId, 'oyun') : null;
    let q = col('QuestionOwner').where('uid', '==', uid);
    if (showId) q = q.where('showId', '==', showId);
    const owned = await q.limit(100).get();
    const ids = owned.docs.map((d) => d.id);
    const items = [];
    if (ids.length) {
      const got = await db.getAll(...ids.map((i) => col('Question').doc(i)));
      got.forEach((g) => { if (g.exists) items.push(view(g.id, g.data())); });
    }
    items.sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
    return { items };
  }

  // ---------------------------------------------------------------- yetkili işlemler
  const reasonOf = (v) => {
    const s = typeof v === 'string' ? v.trim() : '';
    if (s.length < 3 || s.length > 200) throw err('invalid-argument', 'Sebep 3-200 karakter olmalı.');
    return s;
  };
  async function isAdminUser(uid) {
    const u = await col('User').doc(uid).get();
    return u.exists && u.data().role === 'admin';
  }
  async function loadForManage(uid, data) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const id = validateId(data.id, 'soru');
    const ref = col('Question').doc(id);
    const snap = await ref.get();
    if (!snap.exists) {
      // Var olmayan soruda yetkisiz kullanıcıya "bulunamadı" ayrıntısı verme
      const u = await col('User').doc(uid).get();
      if (!(u.exists && u.data().role === 'admin')) throw err('permission-denied', 'Bu işlem için yetkin yok.');
      throw err('not-found', 'Soru bulunamadı.');
    }
    const g = await team.assertCanManageShow(uid, snap.data().showId); // başka ekibin sorusu -> permission-denied
    return { id, ref, d: snap.data(), role: g.role, teamId: g.teamId };
  }
  async function logMod(uid, role, action, id, d, reason) {
    await col('ModerationLog').add({
      at: Timestamp.fromMillis(now()), by: uid, byRole: role, action: `question_${action}`, questionId: id, showId: d.showId,
      reason, textSnapshot: String(d.text || '').slice(0, 300), prevStatus: d.status,
    });
  }

  async function answerQuestion(uid, data) {
    const m = await loadForManage(uid, data);
    const answer = typeof data.answer === 'string' ? data.answer.normalize('NFC').trim() : '';
    if (answer.length < 2) throw err('invalid-argument', 'Cevap yazmalısın.');
    if (Array.from(answer).length > Q.ANSWER_MAX) throw err('invalid-argument', `Cevap en fazla ${Q.ANSWER_MAX} karakter olabilir.`);
    if (ANSWER_URL_RE.test(answer)) throw err('invalid-argument', 'Cevapta bağlantı (URL) olamaz.');
    if (checkText(answer).flagged) throw err('invalid-argument', 'Cevapta uygunsuz bir ifade var.');
    if (m.d.status === 'hidden' || m.d.status === 'rejected') throw err('failed-precondition', 'Bu soru gizli ya da reddedilmiş; önce geri açılmalı.');
    let by = m.role === 'admin' ? 'TiyatRol' : 'Ekip';
    if (m.teamId) { const tm = await col('Team').doc(m.teamId).get(); if (tm.exists && tm.data().name) by = String(tm.data().name).slice(0, 60); }
    const t = Timestamp.fromMillis(now());
    await m.ref.update({ status: 'answered', hidden: false, answer, answeredBy: by, answeredAt: t, answeredRole: m.role, hiddenReason: null });
    await logMod(uid, m.role, m.d.status === 'answered' ? 'reanswer' : 'answer', m.id, m.d, 'yanıtlandı');
    return { ok: true, status: 'answered' };
  }

  async function rejectQuestion(uid, data) {
    const m = await loadForManage(uid, data);
    const reason = reasonOf(data.reason);
    await m.ref.update({ status: 'rejected', hidden: true, hiddenReason: 'rejected', answer: null, rejectedAt: Timestamp.fromMillis(now()) });
    await logMod(uid, m.role, 'reject', m.id, m.d, reason);
    return { ok: true, status: 'rejected' };
  }

  /** Yayındaki soruyu gizler; `restore:true` geri açar (cevap varsa answered, yoksa pending). */
  async function hideQuestion(uid, data) {
    const m = await loadForManage(uid, data);
    const reason = reasonOf(data.reason);
    const t = Timestamp.fromMillis(now());
    if (data.restore === true) {
      if (m.d.status !== 'hidden') throw err('failed-precondition', 'Bu soru gizli değil.');
      const published = !!m.d.answer;
      await m.ref.update({ status: published ? 'answered' : 'pending', hidden: !published, hiddenReason: null, reportBaseline: m.d.reportCount || 0, restoredAt: t });
      await logMod(uid, m.role, 'restore', m.id, m.d, reason);
      return { ok: true, status: published ? 'answered' : 'pending' };
    }
    await m.ref.update({ status: 'hidden', hidden: true, hiddenReason: 'moderator', hiddenAt: t });
    await logMod(uid, m.role, 'hide', m.id, m.d, reason);
    return { ok: true, status: 'hidden' };
  }

  /** Ekip yöneticisi / admin: bir oyunun soruları (tüm durumlar). uid DÖNMEZ. */
  async function teamQuestions(uid, data) {
    const showId = validateId(data && data.showId, 'oyun');
    await team.assertCanManageShow(uid, showId);
    const s = await col('Question').where('showId', '==', showId).limit(300).get();
    const items = s.docs.map((x) => view(x.id, x.data())).sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
    return { showId, items };
  }

  // ---------------------------------------------------------------- şikâyet + engel
  async function reportQuestion(uid, data, ctx) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const id = validateId(data.id, 'soru');
    if (!REASONS.includes(data.reason)) throw err('invalid-argument', 'Geçersiz şikâyet nedeni.');
    const detail = data.detail == null ? '' : data.detail;
    if (typeof detail !== 'string' || detail.length > Q.DETAIL_MAX) throw err('invalid-argument', `Açıklama en fazla ${Q.DETAIL_MAX} karakter olabilir.`);
    const ref = col('Question').doc(id);
    const pre = await ref.get();
    if (!pre.exists || pre.data().status !== 'answered') throw err('not-found', 'Soru bulunamadı.');
    const own = await col('QuestionOwner').doc(id).get();
    if (own.exists && own.data().uid === uid) throw err('invalid-argument', 'Kendi sorunu şikâyet edemezsin.');
    await rateLimit(uid, 'rep');
    const counted = phoneOk(ctx);
    const repRef = col('QuestionReport').doc(`${id}_${uid}`);
    const out = await db.runTransaction(async (tx) => {
      const [rep, qs] = await Promise.all([tx.get(repRef), tx.get(ref)]);
      if (!qs.exists) throw err('not-found', 'Soru bulunamadı.');
      const d = qs.data();
      if (rep.exists) return { already: true, hidden: d.hidden === true };
      const count = (d.reportCount || 0) + (counted ? 1 : 0);
      const upd = { reportCount: count };
      if (counted && d.status === 'answered' && count - (d.reportBaseline || 0) >= Q.AUTO_HIDE_AT) {
        Object.assign(upd, { hidden: true, status: 'hidden', hiddenReason: 'reports', hiddenAt: Timestamp.fromMillis(now()) });
      }
      tx.set(repRef, { questionId: id, showId: d.showId, userId: uid, reason: data.reason, detail, counted, createdAt: Timestamp.fromMillis(now()) });
      tx.update(ref, upd);
      return { already: false, hidden: upd.hidden === true || d.hidden === true };
    });
    return { ok: true, already: out.already, hidden: out.hidden };
  }

  /** Soruyu soran kişiyi engelle: uid sunucuda çözülür (istemci görmez); blocks belgesine askerKey yazılır. */
  async function blockAskerOf(uid, questionId) {
    const id = validateId(questionId, 'soru');
    const own = await col('QuestionOwner').doc(id).get();
    if (!own.exists) throw err('not-found', 'Soru bulunamadı.');
    const target = own.data().uid;
    if (target === uid) throw err('invalid-argument', 'Kendini engelleyemezsin.');
    const c = col('User').doc(uid).collection('blocks');
    if (!(await c.doc(target).get()).exists) {
      const n = (await c.count().get()).data().count;
      if (n >= cfg.REVIEW.MAX_BLOCKS) throw err('resource-exhausted', `En fazla ${cfg.REVIEW.MAX_BLOCKS} kullanıcı engelleyebilirsin.`);
    }
    await c.doc(target).set({ blockedAt: Timestamp.fromMillis(now()), askerKey: askerKeyOf(target) });
    return { ok: true, askerKey: askerKeyOf(target) };
  }

  /** Soruyu KALICI siler — yalnız app admini (ekip yöneticisi silemez, yalnız gizleyebilir/reddedebilir).
   * Review'daki aynı desen (bkz. reviews.js `moderate`, action==='delete'): küfürlü/uygunsuz içerik yanlışlıkla
   * onaylanmış olabilir, silme yetkisi tek elde (admin) kalır — ekip yöneticisi her şeyi silebilir olmasın. */
  async function deleteQuestion(uid, data) {
    if (!(await isAdminUser(uid))) throw err('permission-denied', 'Bu işlem için yönetici yetkisi gerekir.');
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const id = validateId(data.id, 'soru');
    const reason = reasonOf(data.reason);
    const ref = col('Question').doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw err('not-found', 'Soru bulunamadı.');
    const d = snap.data();
    await ref.delete();
    await col('QuestionOwner').doc(id).delete().catch(() => {});
    const reps = await col('QuestionReport').where('questionId', '==', id).get();
    for (let i = 0; i < reps.docs.length; i += 400) {
      const b = db.batch(); reps.docs.slice(i, i + 400).forEach((x) => b.delete(x.ref)); await b.commit();
    }
    await logMod(uid, 'admin', 'delete', id, d, reason);
    return { ok: true };
  }

  return { askQuestion, myQuestions, answerQuestion, rejectQuestion, hideQuestion, teamQuestions, reportQuestion, blockAskerOf, deleteQuestion };
}

module.exports = { createQuestions, askerKeyOf };

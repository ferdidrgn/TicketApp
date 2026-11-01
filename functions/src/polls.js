'use strict';
/**
 * Anket / oylama (F-5, docs/ANKET-PLAN.md).
 *
 * Poll/{id}: { question, options:[{id,label,showId?}], startsAt, endsAt, status:'active'|'closed', counts:{[optionId]:n}, totalVotes, createdAt }
 *   -> HERKESE okunur, istemciye yazma KAPALI (firestore.rules). Oluşturma/kapatma yalnız admin callable'ları.
 * Poll/{id}/votes/{uid}      : { optionId, votedAt } — hesap başına tek oy; yalnız sahibi okur. Hesap silmede belge SİLİNİR, sayaç KALIR.
 * Poll/{id}/phoneVotes/{ph_} : { optionId, votedAt } — telefon özetine (phoneKey) bağlı TEKİL oy; uid TUTMAZ, istemciye kapalı.
 *   Yeni hesapla aynı telefondan ikinci oy sayılmaz (yalnız mevcut oy değiştirilir). Hesap silmede KASITLI kalır.
 * Oy yazımı YALNIZ votePoll: auth + doğrulanmış telefon + silme beklemede değil + hız sınırı + anket aktif + seçenek geçerli;
 * sayaç transaction'da (ilk oy: +1; değiştirme: eskisi -1, yenisi +1; aynı seçenek: no-op).
 */
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, validateId } = require('./util');
const { isBlocking, deletionPendingError } = require('./accountDeletion');
const { requirePhone } = require('./phone');
const { freeTextProblem } = require('./team');
const { checkText } = require('./moderation-words');

const P = cfg.POLL;
const msOf = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);

function createPolls({ db, salt, now = Date.now, log = console, assertAdmin }) {
  const col = (n) => db.collection(n);

  async function rateLimit(uid) {
    const ref = col('PollLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let hs = d.hourStart || 0, hc = d.hourCount || 0, ds = d.dayStart || 0, dc = d.dayCount || 0;
      if (t - hs >= 3600e3) { hs = t; hc = 0; }
      if (t - ds >= 86400e3) { ds = t; dc = 0; }
      if (hc + 1 > P.VOTE.perHour) throw err('resource-exhausted', 'Çok sık işlem yaptın. Biraz sonra tekrar dene.');
      if (dc + 1 > P.VOTE.perDay) throw err('resource-exhausted', 'Günlük işlem sınırına ulaştın. Yarın tekrar dene.');
      tx.set(ref, { hourStart: hs, hourCount: hc + 1, dayStart: ds, dayCount: dc + 1 });
    });
  }

  const isOpen = (p, t) => p.status === 'active' && (msOf(p.startsAt) == null || msOf(p.startsAt) <= t) && (msOf(p.endsAt) == null || t < msOf(p.endsAt));
  const closedError = () => err('failed-precondition', 'Bu anket şu an oy kabul etmiyor.');

  // ---------------------------------------------------------------- oy
  async function votePoll(uid, data, ctx) {
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const pollId = validateId(data.pollId, 'anket');
    const optionId = validateId(data.optionId, 'seçenek');
    const del = await col('AccountDeletion').doc(uid).get();
    if (del.exists && isBlocking(del.data())) throw deletionPendingError(msOf(del.data().scheduledAt));
    const { key } = requirePhone(ctx, salt); // telefon yok -> PHONE_REQUIRED; tuz yok -> fail-closed
    const pollRef = col('Poll').doc(pollId);
    const pre = await pollRef.get();
    if (!pre.exists) throw err('not-found', 'Anket bulunamadı.');
    if (!isOpen(pre.data(), now())) throw closedError();
    if (!(pre.data().options || []).some((o) => o.id === optionId)) throw err('invalid-argument', 'Geçersiz seçenek.');
    await rateLimit(uid);

    const uRef = pollRef.collection('votes').doc(uid), pRef = pollRef.collection('phoneVotes').doc(key);
    return db.runTransaction(async (tx) => {
      const [ps, us, ph] = await Promise.all([tx.get(pollRef), tx.get(uRef), tx.get(pRef)]);
      if (!ps.exists) throw err('not-found', 'Anket bulunamadı.');
      const p = ps.data(), t = now();
      if (!isOpen(p, t)) throw closedError(); // kapanış yarışı: işlem içinde yeniden doğrulanır
      if (!(p.options || []).some((o) => o.id === optionId)) throw err('invalid-argument', 'Geçersiz seçenek.');
      // Sayılan oyun sahibi telefon özetidir; yoksa (telefon değiştirmiş hesap) hesabın kendi eski oyu.
      const prev = ph.exists ? ph.data().optionId : us.exists ? us.data().optionId : null;
      const stamp = Timestamp.fromMillis(t);
      tx.set(uRef, { optionId, votedAt: stamp });
      tx.set(pRef, { optionId, votedAt: stamp });
      if (prev === optionId) return { ok: true, optionId, changed: false };
      const counts = { [optionId]: FieldValue.increment(1) };
      if (prev && prev !== optionId && (p.counts || {})[prev] > 0) counts[prev] = FieldValue.increment(-1);
      tx.set(pollRef, { counts, ...(prev ? {} : { totalVotes: FieldValue.increment(1) }) }, { merge: true });
      return { ok: true, optionId, changed: true, replaced: !!prev };
    });
  }

  /** Giriş yapmış kullanıcının bu ankette oyu (istemci `votes/{uid}` okuyabildiği için gerekmez; mobil/web ortak kolaylık). */
  async function myVote(uid, data) {
    const pollId = validateId(data && data.pollId, 'anket');
    const s = await col('Poll').doc(pollId).collection('votes').doc(uid).get();
    return { optionId: s.exists ? s.data().optionId : null };
  }

  // ---------------------------------------------------------------- admin
  function parseWhen(v, name) {
    const ms = typeof v === 'string' || typeof v === 'number' ? new Date(v).getTime() : NaN;
    if (!Number.isFinite(ms)) throw err('invalid-argument', `Geçersiz ${name} tarihi.`);
    return ms;
  }
  function clean(s, max, name) {
    const v = typeof s === 'string' ? s.normalize('NFC').trim().replace(/\s+/g, ' ') : '';
    if (!v) throw err('invalid-argument', `${name} boş olamaz.`);
    if (Array.from(v).length > max) throw err('invalid-argument', `${name} en fazla ${max} karakter olabilir.`);
    const pr = freeTextProblem(v);
    if (pr) throw err('invalid-argument', `${name}: ${pr.replace('Mesajda ', '')}`);
    if (checkText(v).flagged) throw err('invalid-argument', `${name} uygunsuz ifade içeriyor.`);
    return v;
  }

  async function adminCreatePoll(uid, data) {
    await assertAdmin(uid);
    if (!data || typeof data !== 'object') throw err('invalid-argument', 'Geçersiz istek.');
    const question = clean(data.question, P.QUESTION_MAX, 'Soru');
    if (!Array.isArray(data.options) || data.options.length < P.MIN_OPTIONS || data.options.length > P.MAX_OPTIONS) {
      throw err('invalid-argument', `${P.MIN_OPTIONS}-${P.MAX_OPTIONS} seçenek gerekir.`);
    }
    const options = [], seenLabels = new Set(), counts = {};
    for (let i = 0; i < data.options.length; i++) {
      const o = data.options[i];
      if (!o || typeof o !== 'object') throw err('invalid-argument', 'Geçersiz seçenek.');
      const label = clean(o.label, P.OPTION_MAX, `Seçenek ${i + 1}`);
      if (seenLabels.has(label.toLocaleLowerCase('tr-TR'))) throw err('invalid-argument', 'Aynı seçenek iki kez yazılamaz.');
      seenLabels.add(label.toLocaleLowerCase('tr-TR'));
      const opt = { id: `o${i + 1}`, label };
      if (o.showId != null && o.showId !== '') {
        const showId = validateId(o.showId, 'oyun');
        if (!(await col('Show').doc(showId).get()).exists) throw err('not-found', `Seçenek ${i + 1}: oyun bulunamadı.`);
        opt.showId = showId;
      }
      options.push(opt); counts[opt.id] = 0;
    }
    const t = now();
    const startsMs = data.startsAt == null || data.startsAt === '' ? t : parseWhen(data.startsAt, 'başlangıç');
    const endsMs = parseWhen(data.endsAt, 'bitiş');
    if (endsMs <= startsMs) throw err('invalid-argument', 'Bitiş, başlangıçtan sonra olmalı.');
    if (endsMs <= t) throw err('invalid-argument', 'Bitiş zamanı geçmişte olamaz.');
    if (endsMs - startsMs > P.MAX_DAYS * 864e5) throw err('invalid-argument', `Anket en fazla ${P.MAX_DAYS} gün sürebilir.`);
    const ref = col('Poll').doc();
    await ref.set({
      question, options, counts, totalVotes: 0, status: 'active',
      startsAt: Timestamp.fromMillis(startsMs), endsAt: Timestamp.fromMillis(endsMs), createdAt: Timestamp.fromMillis(t), _createdAt: new Date(t).toISOString(),
    });
    return { ok: true, id: ref.id };
  }

  async function adminClosePoll(uid, data) {
    await assertAdmin(uid);
    const id = validateId(data && data.pollId, 'anket');
    const ref = col('Poll').doc(id);
    const s = await ref.get();
    if (!s.exists) throw err('not-found', 'Anket bulunamadı.');
    const open = data.reopen === true;
    if (open) {
      const end = msOf(s.data().endsAt);
      if (end != null && end <= now()) throw err('failed-precondition', 'Süresi dolmuş anket yeniden açılamaz.');
    }
    await ref.update({ status: open ? 'active' : 'closed', closedAt: open ? FieldValue.delete() : Timestamp.fromMillis(now()) });
    return { ok: true, status: open ? 'active' : 'closed' };
  }

  return { votePoll, myVote, adminCreatePoll, adminClosePoll };
}

module.exports = { createPolls };

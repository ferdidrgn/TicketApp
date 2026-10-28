'use strict';
/**
 * 30 günlük bekleme süreli hesap silme (docs/HESAP-SILME.md).
 *
 * AccountDeletion/{uid}: { uid, status:'pending'|'deleting'|'deleted', requestedAt, scheduledAt, phoneKey?, attempts, postponedCount,
 *   claimedAt?, lastError? } — DÜZ telefon/e-posta YOK (KVKK). Yalnızca sunucu yazar; yalnız admin okur.
 * Yaşam döngüsü: (yok) -> pending -> deleting -> deleted (tombstone; scheduledAt kaldırılır -> zamanlayıcı sorgusundan çıkar).
 *             pending -> (iptal) -> (belge silinir).  deleting ASLA iptal edilemez.
 */
const crypto = require('crypto');
const { FieldPath, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const cfg = require('./config');
const { parseEventDateMs } = require('./util');
const { userDraft, phoneKeyOf, normalizeE164 } = require('./phone');

const CFG = cfg.ACCOUNT_DELETION;
// Eski/olası kişisel alanlar (şemada yok ama eski istemci kayıtlarında olabilir): anonimleştirmede silinir.
const PERSONAL_KEYS = ['customerName', 'customerEmail', 'customerPhone', 'buyerName', 'buyerEmail', 'buyerPhone', 'name', 'firstName', 'lastName', 'email', 'eMail', 'phone', 'phoneNumber', 'userName'];
const BLOCKING = new Set(['pending', 'deleting']);

const iso = (ms) => new Date(ms).toISOString();
const toMs = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);
const anonId = (uid) => 'deleted-' + crypto.createHash('sha256').update('acctdel:' + uid).digest('hex').slice(0, 16);

/** Satış kapısı hatası (orders.js de kullanır). */
function deletionPendingError(scheduledAtMs) {
  return new HttpsError('failed-precondition', 'ACCOUNT_DELETION_PENDING', {
    code: 'ACCOUNT_DELETION_PENDING', scheduledAt: scheduledAtMs ? iso(scheduledAtMs) : null,
  });
}

/** AccountDeletion belgesi satışı engelliyor mu? (pending | deleting) */
function isBlocking(data) { return !!data && BLOCKING.has(data.status); }

function inProgressError() {
  return new HttpsError('failed-precondition', 'DELETION_IN_PROGRESS', { code: 'DELETION_IN_PROGRESS' });
}

const trDate = (ms) => {
  const d = new Date(ms + cfg.TZ_OFFSET_MIN * 60000), p = (n) => String(n).padStart(2, '0');
  return `${p(d.getUTCDate())}.${p(d.getUTCMonth() + 1)}.${d.getUTCFullYear()} ${p(d.getUTCHours())}:${p(d.getUTCMinutes())}`;
};

/**
 * @param {object} o
 * @param {FirebaseFirestore.Firestore} o.db
 * @param {import('firebase-admin/auth').Auth} o.auth
 * @param {{releaseHold:Function}} [o.orderService]  held siparişleri bırakmak için
 * @param {(uid:string)=>Promise<void>} [o.deleteProfileImage]
 * @param {string|null} [o.salt]  telefon anahtarı için (yoksa User.phoneKey kullanılır)
 */
function createAccountDeletion({ db, auth, orderService = null, deleteProfileImage = async () => {}, salt = null, now = Date.now, log = console }) {
  const delRef = (uid) => db.collection('AccountDeletion').doc(uid);
  const userRef = (uid) => db.collection('User').doc(uid);

  // ---------------------------------------------------------------- yardımcılar
  /** Gelecek tarihli aktif bilet özeti. Etkinlik tarihi güncel Event belgesinden (yoksa bilet metninden) okunur. */
  async function upcomingTickets(uid) {
    const snap = await db.collection('Ticket').where('customerId', '==', uid).get();
    const t = now();
    const active = snap.docs.filter((d) => {
      const x = d.data();
      return x.paymentStatus !== 'cancelled' && x.paymentStatus !== 'no_show' && !x.usedAt;
    });
    const evIds = [...new Set(active.map((d) => d.data().eventId).filter(Boolean))];
    const evs = new Map();
    if (evIds.length) {
      const refs = evIds.map((id) => db.collection('Event').doc(id));
      for (let i = 0; i < refs.length; i += 100) {
        const got = await db.getAll(...refs.slice(i, i + 100));
        got.forEach((s) => { if (s.exists) evs.set(s.id, s.data()); });
      }
    }
    // GÜVENLİ TARAF: tarihi ayrıştırılamayan (ne Event.date ne bilet metni) aktif bilet "gelecek" SAYILIR. Sayılmasa kullanıcının geçerli
    // bileti sessizce anonimleşir (geri alınamaz veri kaybı + kural ihlali); sayılırsa en kötü ihtimalle silme ertelenir/reddedilir ve
    // yönetici adminSetTicketStatus ile bileti iptal/gelmedi yaparak (ya da tarihi düzelterek) çözer. Tarih bilinmediği için nextEventDate yok.
    const items = []; let unknown = 0;
    for (const d of active) {
      const x = d.data(), ev = evs.get(x.eventId);
      const ms = parseEventDateMs(ev ? ev.date : x.eventDate) ?? parseEventDateMs(x.eventDate);
      if (ms == null) unknown += 1;
      else if (ms > t) items.push({ ms, title: x.showName || '' });
    }
    items.sort((a, b) => a.ms - b.ms);
    return { count: items.length + unknown, unknown, next: items[0] || null, lastMs: items.length ? items[items.length - 1].ms : null };
  }

  async function hasPayingOrder(uid) {
    const s = await db.collection('Order').where('userId', '==', uid).where('status', '==', 'paying').limit(1).get();
    return !s.empty;
  }

  function upcomingError(u) {
    return new HttpsError('failed-precondition', 'UPCOMING_TICKETS', {
      code: 'UPCOMING_TICKETS', count: u.count, ...(u.next ? { nextEventDate: iso(u.next.ms) } : {}), ...(u.next && u.next.title ? { nextEventTitle: u.next.title } : {}),
    });
  }

  async function isAnonymous(uid) {
    try {
      const u = await auth.getUser(uid);
      return !u.email && !u.phoneNumber && (!u.providerData || u.providerData.length === 0);
    } catch { return false; }
  }

  async function phoneKeyFor(uid, ctx) {
    const phone = normalizeE164(ctx && ctx.phone);
    if (phone && salt != null) return phoneKeyOf(phone, salt);
    const u = await userRef(uid).get();
    return (u.exists && u.data().phoneKey) || null;
  }

  async function chunked(query, fn) {
    for (;;) {
      const s = await query.limit(CFG.DOC_BATCH).get();
      if (s.empty) return;
      const b = db.batch();
      s.docs.forEach((d) => fn(b, d));
      await b.commit();
      if (s.size < CFG.DOC_BATCH) return;
    }
  }

  // ---------------------------------------------------------------- talep
  async function requestAccountDeletion(uid, ctx = {}) {
    const ref = delRef(uid);
    const cur = await ref.get();
    if (cur.exists && cur.data().status === 'deleting') throw inProgressError();
    if (cur.exists && cur.data().status === 'pending') {
      const d = cur.data();
      return { status: 'pending', scheduledAt: iso(toMs(d.scheduledAt)), requestedAt: iso(toMs(d.requestedAt)), already: true };
    }
    const anon = await isAnonymous(uid);
    const pre = await upcomingTickets(uid);
    if (pre.count > 0) throw upcomingError(pre);

    const t = now();
    const scheduledAt = anon ? t : t + CFG.GRACE_MS;
    const phoneKey = anon ? null : await phoneKeyFor(uid, ctx);
    // 1) önce kapı kapanır (satış callable'ları artık reddeder), 2) sonra bilet yeniden sayılır: eşzamanlı onayı yakalar.
    await db.runTransaction(async (tx) => {
      const s = await tx.get(ref);
      if (s.exists && BLOCKING.has(s.data().status)) return;
      tx.set(ref, {
        uid, status: anon ? 'deleting' : 'pending', requestedAt: Timestamp.fromMillis(t), scheduledAt: Timestamp.fromMillis(scheduledAt),
        ...(phoneKey ? { phoneKey } : {}), attempts: 0, postponedCount: 0,
        ...(anon ? { claimedAt: Timestamp.fromMillis(t) } : {}),
      });
    });
    const post = await upcomingTickets(uid);
    if (post.count > 0) {
      await ref.delete();
      throw upcomingError(post);
    }
    if (anon) {
      await purge(uid);
      return { status: 'deleted' };
    }
    const fields = {
      deletionStatus: 'pending', deletionScheduledAt: Timestamp.fromMillis(scheduledAt), deletionRequestedAt: Timestamp.fromMillis(t),
    };
    const us = await userRef(uid).get();
    if (us.exists) await userRef(uid).update(fields);
    else await userRef(uid).create(userDraft(uid, fields)).catch(async (e) => {
      if (!(e && (e.code === 6 || e.code === 'already-exists'))) throw e;
      await userRef(uid).set(fields, { merge: true });
    });
    // askıdaki koltuk tutmaları serbest bırakılır (sayılmaz); hata talebi bozmaz (süre dolumu zaten bırakır)
    try {
      const held = await db.collection('Order').where('userId', '==', uid).where('status', '==', 'held').get();
      for (const d of held.docs) {
        try { if (orderService) await orderService.releaseHold(uid, { orderId: d.id }); } catch (e) { log.error('hesap silme: tutma bırakılamadı', { code: e && e.code }); }
      }
    } catch (e) { log.error('hesap silme: tutma sorgusu', { code: e && e.code }); }
    try { await auth.revokeRefreshTokens(uid); } catch (e) { log.error('hesap silme: token iptali', { code: e && e.code }); }
    return { status: 'pending', scheduledAt: iso(scheduledAt), requestedAt: iso(t), already: false };
  }

  // ---------------------------------------------------------------- vazgeç / durum
  async function cancelAccountDeletion(uid) {
    const ref = delRef(uid), uref = userRef(uid);
    return db.runTransaction(async (tx) => {
      const [s, u] = await Promise.all([tx.get(ref), tx.get(uref)]);
      if (s.exists && s.data().status === 'deleting') throw inProgressError();
      const was = s.exists && s.data().status === 'pending';
      if (was) tx.delete(ref);
      if (u.exists && (u.data().deletionStatus || u.data().deletionScheduledAt)) {
        tx.update(uref, { deletionStatus: FieldValue.delete(), deletionScheduledAt: FieldValue.delete(), deletionRequestedAt: FieldValue.delete() });
      }
      return { status: 'active', wasPending: was };
    });
  }

  async function getAccountDeletionStatus(uid) {
    const s = await delRef(uid).get();
    if (!s.exists || !BLOCKING.has(s.data().status)) return { status: 'active' };
    const d = s.data();
    return { status: d.status, scheduledAt: iso(toMs(d.scheduledAt)), requestedAt: iso(toMs(d.requestedAt)) };
  }

  // ---------------------------------------------------------------- silme (idempotent adımlar)
  // SIRA (kasıtlı): 1 Storage  2 eski Event.seats.customerId  3 Ticket/Order anonimleştirme  4 NotificationLog  5 Notification/Review/ReviewReport/UserLimits
  //                 6 Auth kullanıcısı  7 User/{uid}  8 mezar taşı. Her adım tekrar çalıştırılınca aynı sonucu verir; bir adım hata verirse
  //                 sonrakiler çalışmaz (User/Auth en sonda olduğundan kayıt kurtarılabilir kalır) ve ertesi çalışma kaldığı yerden devam eder.
  async function purge(uid) {
    const anon = anonId(uid);
    const anonAt = Timestamp.fromMillis(now());
    await deleteProfileImage(uid); // hata fırlatır -> Firestore verisine DOKUNULMAZ, yeniden denenir
    // eski biçim: Event.seats[*].customerId (yeni biçimde kimlik tutulmaz). Etkinlik listesi, anonimleştirmeden ÖNCE bilet/siparişten çıkarılır.
    const evIds = new Set();
    for (const [col, field] of [['Ticket', 'customerId'], ['Order', 'userId']]) {
      const s = await db.collection(col).where(field, '==', uid).get();
      s.docs.forEach((d) => { if (d.data().eventId) evIds.add(d.data().eventId); });
    }
    for (const id of evIds) {
      const ref = db.collection('Event').doc(id);
      await db.runTransaction(async (tx) => {
        const s = await tx.get(ref);
        if (!s.exists) return;
        const args = [];
        for (const [sid, v] of Object.entries(s.data().seats || {})) if (v && v.customerId === uid) args.push(new FieldPath('seats', sid, 'customerId'), FieldValue.delete());
        if (args.length) tx.update(ref, ...args);
      });
    }
    // yasal saklama: bilet/sipariş KALIR, kişisel bağlantı kopar (anonimleşenler sorguya bir daha girmez -> sayfalama idempotent)
    const drop = {}; for (const k of PERSONAL_KEYS) drop[k] = FieldValue.delete();
    await chunked(db.collection('Ticket').where('customerId', '==', uid), (b, d) => b.update(d.ref, { ...drop, customerId: anon, anonymizedAt: anonAt }));
    await chunked(db.collection('Order').where('userId', '==', uid), (b, d) => b.update(d.ref, { ...drop, userId: anon, phoneKey: FieldValue.delete(), anonymizedAt: anonAt }));
    // ekip yöneticisi ise yetki belgeleri 'revoked' (belge kalır = denetim izi; kişisel alanlar silinir, uid takma adlanır) + atama günlüğü + limit sayacı
    await chunked(db.collection('TeamManager').where('uid', '==', uid), (b, d) => b.update(d.ref, {
      status: 'revoked', revokedAt: anonAt, uid: anon, displayName: FieldValue.delete(), emailHint: FieldValue.delete(), phoneActive: FieldValue.delete(),
    }));
    await chunked(db.collection('TeamManager').where('addedBy', '==', uid), (b, d) => b.update(d.ref, { addedBy: anon }));
    await chunked(db.collection('TeamManager').where('revokedBy', '==', uid), (b, d) => b.update(d.ref, { revokedBy: anon }));
    await chunked(db.collection('TeamManagerLog').where('targetUid', '==', uid), (b, d) => b.update(d.ref, { targetUid: anon }));
    await chunked(db.collection('TeamManagerLog').where('by', '==', uid), (b, d) => b.update(d.ref, { by: anon }));
    await db.collection('TeamLimits').doc(uid).delete();
    // yönetici ise gönderim kayıtlarındaki adı
    await chunked(db.collection('NotificationLog').where('sentBy', '==', uid), (b, d) => b.update(d.ref, { sentBy: anon, sentByName: '' }));
    // kişisel koleksiyonlar silinir
    for (const [col, field] of [['Notification', 'userId'], ['Review', 'userId'], ['ReviewReport', 'userId']]) {
      await chunked(db.collection(col).where(field, '==', uid), (b, d) => b.delete(d.ref));
    }
    await db.collection('UserLimits').doc(uid).delete(); // yalnız uid aynası; ph_* sayacı KASITLI kalır
    // kimlik EN SON: Auth, sonra profil belgesi (Auth hatasında User hâlâ durur)
    try { await auth.deleteUser(uid); } catch (e) {
      if (!(e && (e.code === 'auth/user-not-found' || (e.errorInfo && e.errorInfo.code === 'auth/user-not-found')))) throw e; // yoksa zaten silinmiş = başarı
    }
    await userRef(uid).delete();
    // mezar taşı: kişisel veri yok (belge kimliği = silinmiş uid; Auth'ta karşılığı yok). scheduledAt kaldırılır -> zamanlayıcı sorgusundan çıkar.
    await delRef(uid).set({ status: 'deleted', deletedAt: Timestamp.fromMillis(now()) });
  }

  // ---------------------------------------------------------------- zamanlanmış işleme
  async function postpone(uid, rec, toMsAt, reason) {
    const nowMs = now();
    await db.runTransaction(async (tx) => {
      const us = await tx.get(userRef(uid));
      tx.update(delRef(uid), {
        status: 'pending', scheduledAt: Timestamp.fromMillis(toMsAt), postponedCount: (rec.postponedCount || 0) + 1,
        claimedAt: FieldValue.delete(), lastPostponeReason: reason,
      });
      if (us.exists) tx.update(userRef(uid), { deletionStatus: 'pending', deletionScheduledAt: Timestamp.fromMillis(toMsAt) });
      const id = `accdel_${uid}_${(rec.postponedCount || 0) + 1}`;
      tx.set(db.collection('Notification').doc(id), {
        _id: id, userId: uid, isRead: false, type: 'announcement', _createdAt: iso(nowMs), createdAt: Timestamp.fromMillis(nowMs),
        title: 'Hesap silme ertelendi',
        body: `Gelecek etkinlik biletiniz bulunduğu için hesap silme işleminiz ${trDate(toMsAt).slice(0, 10)} tarihine ertelendi. İsterseniz vazgeçebilirsiniz.`,
      });
    });
  }

  /** -> 'deleted' | 'postponed' | 'skipped' | 'cancelled' ; hata fırlatır (çağıran sayar) */
  async function processOne(uid) {
    const ref = delRef(uid);
    const nowMs = now();
    const claim = await db.runTransaction(async (tx) => {
      const s = await tx.get(ref);
      if (!s.exists) return null;
      const d = s.data();
      if (!BLOCKING.has(d.status)) return null;
      const due = toMs(d.scheduledAt);
      if (due == null || due > nowMs) return null;
      const claimed = toMs(d.claimedAt);
      if (d.status === 'deleting' && claimed != null && nowMs - claimed < CFG.CLAIM_MS) return null; // başka çalışma işliyor
      tx.update(ref, { status: 'deleting', claimedAt: Timestamp.fromMillis(nowMs), attempts: (d.attempts || 0) + 1 });
      return d;
    });
    if (!claim) return 'skipped';
    try {
      const up = await upcomingTickets(uid);
      // tarihi bilinmeyen bilet varsa (yönetici incelemesi gerekir) 30 gün sonrasına; aksi halde son etkinlik + 1 gün
      if (up.count > 0) { await postpone(uid, claim, up.unknown ? nowMs + CFG.GRACE_MS : up.lastMs + 864e5, up.unknown ? 'unparseable_ticket_date' : 'upcoming_tickets'); return 'postponed'; }
      if (await hasPayingOrder(uid)) { await postpone(uid, claim, nowMs + 864e5, 'paying_order'); return 'postponed'; }
      await purge(uid);
      return 'deleted';
    } catch (e) {
      await ref.set({ claimedAt: FieldValue.delete(), errorCount: FieldValue.increment(1), lastError: String((e && (e.code || e.name)) || 'error').replace(/[^A-Za-z0-9/_.:-]/g, '').slice(0, 60) }, { merge: true }).catch(() => {});
      throw e;
    }
  }

  async function processDue({ maxPerRun = CFG.MAX_PER_RUN, timeBudgetMs = CFG.TIME_BUDGET_MS } = {}) {
    const start = now();
    const r = { scanned: 0, processed: 0, deleted: 0, postponed: 0, failed: 0, remainingDue: 0 };
    let cursor = null;
    outer: for (;;) {
      let q = db.collection('AccountDeletion').where('scheduledAt', '<=', Timestamp.fromMillis(now())).orderBy('scheduledAt').limit(CFG.BATCH);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      if (snap.empty) break;
      for (const d of snap.docs) {
        if (r.scanned >= maxPerRun || now() - start > timeBudgetMs) break outer;
        r.scanned += 1;
        cursor = d;
        try {
          const o = await processOne(d.id);
          if (o === 'deleted') { r.deleted += 1; r.processed += 1; } else if (o === 'postponed') { r.postponed += 1; r.processed += 1; }
        } catch (e) {
          r.failed += 1;
          log.error('hesap silme hatası', { uidHash: anonId(d.id), code: e && e.code, name: e && e.name });
        }
      }
      if (snap.size < CFG.BATCH) break;
    }
    try {
      r.remainingDue = (await db.collection('AccountDeletion').where('scheduledAt', '<=', Timestamp.fromMillis(now())).count().get()).data().count;
    } catch { /* sayaç zorunlu değil */ }
    try {
      await db.collection('System').doc('processAccountDeletions').set({
        lastRunAt: Timestamp.fromMillis(now()), processed: r.processed, deleted: r.deleted, postponed: r.postponed, failed: r.failed,
      });
    } catch (e) { log.error('hesap silme kalp atışı yazılamadı', { code: e && e.code }); }
    return r;
  }

  return { requestAccountDeletion, cancelAccountDeletion, getAccountDeletionStatus, processDue, processOne, purge, upcomingTickets };
}

module.exports = { createAccountDeletion, deletionPendingError, isBlocking, anonId };

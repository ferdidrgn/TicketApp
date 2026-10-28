'use strict';
/**
 * Ekip yöneticisi rolü (docs/EKIP-YONETICISI.md).
 *
 * Yetki `TeamManager/{teamId}_{uid}` belgesidir ({teamId, uid, status:'active'|'revoked', addedBy, addedAt, revokedAt?}). `User.role` DEĞİŞMEZ.
 * Kapsam SUNUCUDA hesaplanır: seans -> (Event.showId, boşsa Show.eventsId yedeği) -> Show.teamId. İstemciden gelen teamId ASLA kabul edilmez
 * (yalnız admin atama çağrısında, o da admin yetkisiyle). Kapsam çözülemezse (boş showId/teamId, belirsiz eşleşme) FAIL-CLOSED reddedilir.
 * Yanıtlarda kişisel veri (ad, telefon, e-posta, uid listesi) DÖNMEZ; yalnız sayılar ve seans/oyun bilgisi.
 */
const crypto = require('crypto');
const { Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, parseEventDateMs, validateId } = require('./util');
const { isBlocking, deletionPendingError } = require('./accountDeletion');
const { TEMPLATES, templateList, buildMessage } = require('./notify');

const T = cfg.TEAM;
const N = cfg.NOTIFY;
const INACTIVE = new Set(['cancelled', 'no_show']);
const ID_SAFE = (s) => String(s).replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 100);
const EMAIL_RE = /^[^\s@]{1,64}@[^\s@]{1,190}\.[^\s@]{2,}$/;

// ---------------------------------------------------------------- serbest metin denetimi
const ZERO_WIDTH = /[​-‏‪-‮⁠﻿]/g;
const URL_RE = /(https?:|ftp:|www\.|\bwa\.me|\bt\.me|\bbit\.ly|tinyurl|\bgoo\.gl|[\p{L}\p{Nd}-]\.(com|net|org|tr|io|app|me|ly|co|link|xyz|info|top|site|online|shop|store|ru|cn|ws|cc|gl|page|dev|click|live)\b)/iu;
const PHONE_RE = /(?:\p{Nd}[\s().\-+]*){10,}/u; // 10+ rakam (araya boşluk/tire/parantez girse de)

/** Serbest metinde (ekip yöneticisi) yasak içerik var mı? -> hata iletisi | null */
function freeTextProblem(raw) {
  const s = String(raw == null ? '' : raw).replace(ZERO_WIDTH, '').normalize('NFKC');
  if (URL_RE.test(s)) return 'Mesajda bağlantı (URL) olamaz.';
  if (/\S@\S/.test(s) || /(^|\s)@\w/.test(s)) return 'Mesajda e-posta adresi veya @kullanıcı adı olamaz.';
  if (PHONE_RE.test(s)) return 'Mesajda telefon numarası olamaz.';
  return null;
}

/** Ekip yöneticisine gösterilen şablon listesi: hedefler yalnız event/show; serbest metin sadece custom şablonlarda. */
function teamTemplateList() {
  return templateList().map((t) => ({ ...t, targets: t.targets.filter((x) => x === 'event' || x === 'show') })).filter((t) => t.targets.length);
}

const msOf = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : null);
const iso = (ms) => new Date(ms).toISOString();
const ticketStatusOf = (t) => t.paymentStatus || (t.orderMethod === 'venue' ? 'pay_at_venue' : t.orderMethod === 'free' ? 'free' : 'paid');
const maskEmail = (e) => { const [a, d] = String(e || '').split('@'); return a && d ? `${a[0]}***@${d}` : ''; };

function seatTally(seats) {
  let total = 0, sold = 0, held = 0;
  for (const s of Object.values(seats || {})) {
    if (!s) continue;
    if (s.status === 'blocked' || (s.status === 'sold' && s.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID)) continue;
    total += 1;
    if (s.status === 'sold') sold += 1; else if (s.status === 'reserved') held += 1;
  }
  return { total, sold, held };
}

/**
 * @param {object} o
 * @param {FirebaseFirestore.Firestore} o.db
 * @param {import('firebase-admin/auth').Auth} o.auth  adminSetTeamManager için (e-postadan uid)
 * @param {{internals:object}} o.notifier  createNotifier() sonucu (hedef/şablon/gönderim çekirdeği)
 */
function createTeam({ db, auth, notifier, messaging, now = Date.now, log = console }) {
  const col = (n) => db.collection(n);
  const X = notifier.internals;
  const permDenied = () => err('permission-denied', 'Bu işlem için yetkin yok.');

  // ---------------------------------------------------------------- hesap / rol
  /** Hesap silme `pending`/`deleting` iken yönetici callable'ları reddedilir (satış kapısıyla aynı sözleşme). */
  async function assertAccountActive(uid) {
    const s = await col('AccountDeletion').doc(uid).get();
    if (s.exists && isBlocking(s.data())) throw deletionPendingError(msOf(s.data().scheduledAt));
  }
  async function isAdminUser(uid) {
    const u = await col('User').doc(uid).get();
    return u.exists && u.data().role === 'admin';
  }
  /** Kullanıcının AKTİF yönetici olduğu ekip kimlikleri. */
  async function managedTeamIds(uid) {
    const s = await col('TeamManager').where('uid', '==', uid).where('status', '==', 'active').get();
    return [...new Set(s.docs.map((d) => d.data()).filter((d) => typeof d.teamId === 'string' && d.teamId).map((d) => d.teamId))];
  }
  async function isActiveManager(uid, teamId) {
    if (!teamId) return false;
    const s = await col('TeamManager').doc(`${teamId}_${uid}`).get();
    const d = s.exists ? s.data() : null;
    return !!d && d.status === 'active' && d.uid === uid && d.teamId === teamId;
  }

  // ---------------------------------------------------------------- kapsam çözümleme
  /**
   * Seansın oyunu/ekibi. Event.showId doluysa TEK doğruluk kaynağıdır; yalnız boşsa Show.eventsId yedeği (tam 1 eşleşme şart).
   * -> { eventId, showId|null, teamId|null, event, show|null } ; seans yoksa null.
   */
  async function resolveEventScope(eventId) {
    const e = await col('Event').doc(eventId).get();
    if (!e.exists) return null;
    const event = e.data();
    let showId = typeof event.showId === 'string' && event.showId ? event.showId : null;
    if (!showId) {
      const q = await col('Show').where('eventsId', 'array-contains', eventId).select('teamId').limit(2).get();
      if (q.size === 1) showId = q.docs[0].id; // 0 (yetim) ya da >1 (belirsiz) -> null = fail-closed
    }
    let show = null, teamId = null;
    if (showId) {
      const s = await col('Show').doc(showId).get();
      if (s.exists) { show = s.data(); if (typeof show.teamId === 'string' && show.teamId) teamId = show.teamId; }
    }
    return { eventId, showId, teamId, event, show };
  }
  /** Spec: resolveEventTeam(eventId) -> teamId | null (null = çözülemedi, fail-closed). */
  async function resolveEventTeam(eventId) {
    const s = await resolveEventScope(eventId);
    return s ? s.teamId : null;
  }

  /** admin VEYA aktif TeamManager (kendi ekibinin seansı). Yetkisizde seans var/yok ayrımı sızdırılmaz. */
  async function assertCanManageEvent(uid, eventId) {
    const admin = await isAdminUser(uid);
    if (!admin && (await managedTeamIds(uid)).length === 0) throw permDenied();
    const scope = await resolveEventScope(eventId);
    if (admin) {
      if (!scope) throw err('not-found', 'Seans bulunamadı.');
      return { scope, role: 'admin' };
    }
    if (!scope || !(await isActiveManager(uid, scope.teamId))) throw permDenied();
    return { scope, role: 'teamManager' };
  }
  async function assertCanManageShow(uid, showId) {
    const admin = await isAdminUser(uid);
    if (!admin && (await managedTeamIds(uid)).length === 0) throw permDenied();
    const s = await col('Show').doc(showId).get();
    if (admin) {
      if (!s.exists) throw err('not-found', 'Oyun bulunamadı.');
      return { show: s.data(), showId, teamId: s.data().teamId || null, role: 'admin' };
    }
    const teamId = s.exists && typeof s.data().teamId === 'string' ? s.data().teamId : null;
    if (!teamId || !(await isActiveManager(uid, teamId))) throw permDenied();
    return { show: s.data(), showId, teamId, role: 'teamManager' };
  }

  /** Bir oyuna ait seanslar: Event.showId == oyun, ya da Show.eventsId'de olup showId'si BOŞ olanlar. -> [{id, ...alanlar}] */
  async function eventsOfShow(showId, showData, fields = ['showId', 'stageId', 'date', 'seats']) {
    const out = new Map();
    const s = await col('Event').where('showId', '==', showId).select(...fields).get();
    s.docs.forEach((d) => out.set(d.id, { id: d.id, ...d.data() }));
    const extra = (Array.isArray(showData && showData.eventsId) ? showData.eventsId : []).filter((x) => typeof x === 'string' && x && !x.includes('/') && !out.has(x)).slice(0, 200);
    for (let i = 0; i < extra.length; i += 100) {
      const got = await db.getAll(...extra.slice(i, i + 100).map((id) => col('Event').doc(id)), { fieldMask: fields });
      got.forEach((g) => { if (g.exists && !(typeof g.data().showId === 'string' && g.data().showId)) out.set(g.id, { id: g.id, ...g.data() }); });
    }
    return [...out.values()];
  }

  // ---------------------------------------------------------------- limitler (TeamLimits/{uid})
  async function rateLimit(uid, targetKey) {
    const ref = col('TeamLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let hs = d.hourStart || 0, hc = d.hourCount || 0, ds = d.dayStart || 0, dc = d.dayCount || 0;
      if (t - hs >= T.RATE_HOUR.windowMs) { hs = t; hc = 0; }
      if (t - ds >= T.RATE_DAY.windowMs) { ds = t; dc = 0; }
      const per = {};
      for (const [k, v] of Object.entries(d.perTarget || {})) if (v && t - v.start < T.PER_TARGET.windowMs) per[k] = v;
      const cur = per[targetKey] || { start: t, count: 0 };
      if (hc + 1 > T.RATE_HOUR.max) throw err('resource-exhausted', `Saatlik gönderim sınırına ulaşıldı (${T.RATE_HOUR.max}). Daha sonra tekrar dene.`);
      if (dc + 1 > T.RATE_DAY.max) throw err('resource-exhausted', `Günlük gönderim sınırına ulaşıldı (${T.RATE_DAY.max}). Yarın tekrar dene.`);
      if (cur.count + 1 > T.PER_TARGET.max) throw err('resource-exhausted', `Aynı seansa 24 saatte en fazla ${T.PER_TARGET.max} bildirim gönderilebilir.`);
      per[targetKey] = { start: cur.start, count: cur.count + 1 };
      tx.set(ref, { hourStart: hs, hourCount: hc + 1, dayStart: ds, dayCount: dc + 1, perTarget: per });
    });
  }
  async function quotaOf(uid, targetKey) {
    const d = (await col('TeamLimits').doc(uid).get()).data() || {};
    const t = now();
    const h = t - (d.hourStart || 0) >= T.RATE_HOUR.windowMs ? 0 : d.hourCount || 0;
    const dd = t - (d.dayStart || 0) >= T.RATE_DAY.windowMs ? 0 : d.dayCount || 0;
    const p = (d.perTarget || {})[targetKey];
    const pt = p && t - p.start < T.PER_TARGET.windowMs ? p.count : 0;
    return { hourLeft: Math.max(0, T.RATE_HOUR.max - h), dayLeft: Math.max(0, T.RATE_DAY.max - dd), targetLeft: Math.max(0, T.PER_TARGET.max - pt) };
  }

  // ---------------------------------------------------------------- hedef + mesaj
  /** Yetki kapsamı doğrulanmış hedef -> notify.js ile aynı biçimli {type,id,userIds,tickets,ctx,label} (+ teamId, role). */
  async function resolveScopedTarget(uid, target) {
    if (!target || typeof target !== 'object') throw err('invalid-argument', 'Hedef gerekli.');
    if (target.type === 'all' || target.type === 'user') throw err('permission-denied', 'Ekip yöneticisi yalnızca kendi seansının veya oyununun bilet sahiplerine bildirim gönderebilir.');
    if (target.type !== 'event' && target.type !== 'show') throw err('invalid-argument', 'Geçersiz hedef türü.');
    const id = validateId(target.id, 'hedef');
    if (target.type === 'event') {
      const { scope, role } = await assertCanManageEvent(uid, id);
      const tgt = await X.resolveTarget({ type: 'event', id });
      if (!tgt.ctx.oyun && scope.show) { tgt.ctx.oyun = scope.show.name || ''; tgt.label = `Seans: ${tgt.ctx.oyun}`; }
      return { ...tgt, teamId: scope.teamId || '', showId: scope.showId || '', role };
    }
    const g = await assertCanManageShow(uid, id);
    // Oyun hedefi = oyunun YAKLAŞAN seanslarının (±24 saat geçmiş dahil) aktif bilet sahipleri; eski dönem seanslar kapsam dışı.
    const evs = (await eventsOfShow(id, g.show, ['showId', 'date'])).filter((e) => { const ms = parseEventDateMs(e.date); return ms != null && ms >= now() - T.LIST_PAST_MS; });
    const uids = new Set(); let tickets = 0;
    for (const e of evs) { const a = await X.activeCustomers('eventId', e.id); a.ids.forEach((u) => uids.add(u)); tickets += a.tickets; }
    return { type: 'show', id, userIds: [...uids], tickets, ctx: { oyun: g.show.name || '', sahne: '', showId: id }, label: `Oyun: ${g.show.name || id}`, teamId: g.teamId || '', showId: id, role: g.role };
  }

  /** Şablon/metin denetimi (ekip kuralları) + notify.compose. Hata -> HttpsError. */
  function composeForTeam(data, tgt, lenient) {
    const tplId = data.template == null || data.template === '' ? null : String(data.template);
    if (!tplId) throw err('invalid-argument', 'Bir şablon seçmelisin.');
    const tpl = TEMPLATES[tplId];
    if (!tpl) throw err('invalid-argument', 'Bilinmeyen şablon.');
    if (data.kind != null && !['normal', 'alarm'].includes(data.kind)) throw err('invalid-argument', 'Geçersiz bildirim türü.');
    if (tpl.custom) {
      // Serbest metin: alarm YOK (alarm yalnız sabit şablonlarda), URL/telefon/e-posta yasak.
      if (data.kind === 'alarm') throw err('permission-denied', 'Serbest metinli bildirim alarm olarak gönderilemez.');
      for (const v of [data.title, data.body]) { const p = freeTextProblem(v); if (p) throw err('invalid-argument', p); }
    }
    const out = X.compose({ ...data, template: tplId, kind: tpl.custom ? 'normal' : undefined }, tgt, lenient);
    if (tpl.custom) { for (const v of [out.title, out.body]) { const p = freeTextProblem(v); if (p) throw err('invalid-argument', p); } }
    return out;
  }
  const targetKeyOf = (tgt) => `${tgt.type}_${ID_SAFE(tgt.id)}`;

  // ---------------------------------------------------------------- callable'lar
  /** Yönetilen ekipler + oyunlar + yaklaşan seanslar. Kişisel veri YOK. Yetkisiz kullanıcıya boş liste (hata değil: arayüz "yetkin yok" der). */
  async function getMyManagedTeams(uid) {
    await assertAccountActive(uid);
    const t = now();
    const teamIds = await managedTeamIds(uid);
    const teams = [];
    for (const teamId of teamIds) {
      const tm = await col('Team').doc(teamId).get();
      if (!tm.exists) continue;
      const shows = await col('Show').where('teamId', '==', teamId).limit(T.MAX_SHOWS_PER_TEAM).get();
      const outShows = [];
      for (const sh of shows.docs) {
        const evs = (await eventsOfShow(sh.id, sh.data())).map((e) => ({ ...e, ms: parseEventDateMs(e.date) }))
          .filter((e) => e.ms != null && e.ms >= t - T.LIST_PAST_MS && e.ms <= t + T.LIST_FUTURE_MS).sort((a, b) => a.ms - b.ms).slice(0, T.MAX_EVENTS_PER_SHOW);
        const stageIds = [...new Set(evs.map((e) => e.stageId).filter(Boolean))];
        const stageName = new Map();
        if (stageIds.length) (await db.getAll(...stageIds.map((i) => col('Stage').doc(i)), { fieldMask: ['name'] })).forEach((g) => { if (g.exists) stageName.set(g.id, g.data().name || ''); });
        outShows.push({
          showId: sh.id, name: sh.data().name || '',
          events: evs.map((e) => ({ eventId: e.id, ms: e.ms, dateText: typeof e.date === 'string' ? e.date : '', stage: stageName.get(e.stageId) || '', ...seatTally(e.seats), inWindow: Math.abs(e.ms - t) <= N.TIMED_WINDOW_MS })),
        });
      }
      teams.push({ teamId, name: tm.data().name || '', shows: outShows });
    }
    return { teams, now: t, templates: teamTemplateList(), limits: { hour: T.RATE_HOUR.max, day: T.RATE_DAY.max, perTarget: T.PER_TARGET.max } };
  }

  async function teamNotifyPreview(uid, data) {
    await assertAccountActive(uid);
    data = data || {};
    const tgt = await resolveScopedTarget(uid, data.target);
    const rc = await X.loadRecipients(tgt.userIds);
    let preview = null, blocked = null;
    if (data.template || data.title) {
      try { preview = composeForTeam(data, tgt, true); } catch (e) { blocked = e.message; }
    }
    return {
      target: { type: tgt.type, id: tgt.id, label: tgt.label }, recipients: tgt.userIds.length, withToken: rc.tokens.size,
      loudAlarm: { optedIn: rc.loud.size, of: rc.tokens.size }, tickets: tgt.tickets ?? null,
      event: tgt.type === 'event' ? { show: tgt.ctx.oyun, stage: tgt.ctx.sahne, ms: tgt.ctx.ms } : null,
      preview, blocked, templates: teamTemplateList(), quota: await quotaOf(uid, targetKeyOf(tgt)), now: now(),
    };
  }

  async function teamSendNotification(uid, data) {
    await assertAccountActive(uid);
    data = data || {};
    const tgt = await resolveScopedTarget(uid, data.target);
    const msgIn = composeForTeam(data, tgt, false);
    if (typeof data.requestId !== 'string' || !/^[A-Za-z0-9_-]{8,64}$/.test(data.requestId)) throw err('invalid-argument', 'Geçersiz istek kimliği.');
    const recipients = tgt.userIds.length;
    if (recipients === 0) throw err('failed-precondition', 'Bu hedefte bildirim alacak aktif bilet sahibi yok.');
    if (data.confirm !== true) throw err('failed-precondition', `${recipients} kişiye gönderilecek; onay gerekli (confirm: true).`);

    const key = crypto.createHash('sha256').update(`team:${uid}:${data.requestId}`).digest('hex').slice(0, 32);
    const logRef = col('NotificationLog').doc(key);
    const prev = await logRef.get();
    if (prev.exists) {
      const p = prev.data();
      return { ok: true, duplicate: true, logId: key, recipients: p.recipients, success: p.success ?? 0, failure: p.failure ?? 0, title: p.title, body: p.body, kind: p.kind };
    }
    await rateLimit(uid, targetKeyOf(tgt));
    const u = await col('User').doc(uid).get();
    const sentByName = u.exists ? `${u.data().firstName || ''} ${u.data().lastName || ''}`.trim() : '';
    try {
      await logRef.create({
        sentBy: uid, sentByName, sentByRole: tgt.role === 'admin' ? 'admin' : 'teamManager', teamId: tgt.teamId, showId: tgt.showId,
        ...(tgt.type === 'event' ? { eventId: tgt.id } : {}),
        target: { type: tgt.type, id: tgt.id }, targetLabel: tgt.label, template: msgIn.template, kind: msgIn.kind,
        title: msgIn.title, body: msgIn.body, recipients, status: 'sending', createdAt: Timestamp.fromMillis(now()),
      });
    } catch (e) {
      if (e && (e.code === 6 || String(e.code) === 'already-exists')) return { ok: true, duplicate: true, logId: key, recipients, success: 0, failure: 0, title: msgIn.title, body: msgIn.body, kind: msgIn.kind };
      throw e;
    }
    const eventId = tgt.type === 'event' ? tgt.id : undefined;
    const base = {
      title: msgIn.title, body: msgIn.body, type: msgIn.kind === 'alarm' ? 'alarm' : 'announcement',
      ...(eventId ? { eventId } : {}), ...(tgt.showId ? { showId: tgt.showId } : {}),
    };
    const build = (loud) => buildMessage({ title: msgIn.title, body: msgIn.body, kind: msgIn.kind, eventId, now: now(), loud });
    const inApp = await X.writeInApp(tgt.userIds, base, `ann_${key.slice(0, 16)}`);
    const rc = await X.loadRecipients(tgt.userIds);
    const result = await X.pushByPrefs(rc, build, msgIn.kind);
    await logRef.update({ status: 'done', inApp, withToken: rc.tokens.size, topic: false, success: result.success, failure: result.failure, chunks: result.chunks, loudCount: result.loud, finishedAt: Timestamp.fromMillis(now()) });
    return { ok: true, duplicate: false, logId: key, recipients, withToken: rc.tokens.size, inApp, loudCount: result.loud, success: result.success, failure: result.failure, title: msgIn.title, body: msgIn.body, kind: msgIn.kind };
  }

  /** Kapı kontrolü: yalnız kendi ekibinin seansına ait bilet. Müşteri adı/telefon/e-posta DÖNMEZ. */
  async function teamCheckIn(uid, data) {
    await assertAccountActive(uid);
    data = data || {};
    const ticketId = validateId(data.ticketId, 'bilet');
    const notFound = () => err('not-found', 'Bu kodla, yetkili olduğun bir seansa ait bilet bulunamadı.');
    // yetki ön denetimi: aktif yöneticisi olmayan biri bilet var/yok bilgisi alamaz
    if (!(await isAdminUser(uid)) && (await managedTeamIds(uid)).length === 0) throw permDenied();
    const ref = col('Ticket').doc(ticketId);
    const snap = await ref.get();
    if (!snap.exists) throw notFound();
    const t0 = snap.data();
    let scope;
    try { ({ scope } = await assertCanManageEvent(uid, String(t0.eventId || ''))); } catch (e) {
      if (e && e.code === 'permission-denied') throw notFound(); // başka ekibin bileti ile olmayan bilet ayırt edilemez
      throw e;
    }
    const ms = parseEventDateMs(scope.event.date);
    const summary = (t, cur) => ({
      code: ticketId, showName: t.showName || '', eventDate: t.eventDate || '', stageName: t.stageName || '', buySeats: t.buySeats || [], seatCount: (t.buySeats || []).length,
      paymentStatus: cur, payAtVenue: cur === 'pay_at_venue', usedAt: t.usedAt ? iso(msOf(t.usedAt) ?? now()) : null,
    });
    if (data.eventId != null && data.eventId !== t0.eventId) return { ok: false, wrongEvent: true, ticket: summary(t0, ticketStatusOf(t0)) };
    if (ms == null || Math.abs(ms - now()) > T.CHECKIN_WINDOW_MS) throw err('failed-precondition', 'Kapı kontrolü yalnızca seansa ±24 saat kala yapılabilir.');
    const r = await db.runTransaction(async (tx) => {
      const s = await tx.get(ref);
      const t = s.data();
      const cur = ticketStatusOf(t);
      if (cur === 'cancelled' || cur === 'no_show') return { t, cur, ok: false, already: false };
      if (t.usedAt) return { t, cur, ok: false, already: true };
      const usedAt = Timestamp.fromMillis(now());
      tx.update(ref, { usedAt, _updatedAt: new Date(now()).toISOString() });
      return { t: { ...t, usedAt }, cur, ok: true, already: false };
    });
    return { ok: r.ok, ...(r.already ? { already: true } : {}), ticket: summary(r.t, r.cur) };
  }

  /** Kendi oyun/seansları: satılan/tutulan/doluluk/giriş sayısı. Kişisel veri YOK. */
  async function teamStats(uid, data) {
    await assertAccountActive(uid);
    data = data || {};
    const t = now();
    let teamIds = await managedTeamIds(uid);
    if (data.teamId != null) { // istenen ekip YÖNETİLENLER arasında olmalı (kapsam sunucuda)
      const want = validateId(data.teamId, 'ekip');
      if (!teamIds.includes(want)) throw permDenied();
      teamIds = [want];
    }
    const out = [];
    let budget = 60; // tek çağrıda en çok bu kadar seans için bilet taraması
    for (const teamId of teamIds) {
      const shows = await col('Show').where('teamId', '==', teamId).limit(T.MAX_SHOWS_PER_TEAM).get();
      for (const sh of shows.docs) {
        const evs = (await eventsOfShow(sh.id, sh.data())).map((e) => ({ ...e, ms: parseEventDateMs(e.date) }))
          .filter((e) => e.ms != null && e.ms >= t - 30 * 864e5 && e.ms <= t + T.LIST_FUTURE_MS).sort((a, b) => a.ms - b.ms).slice(0, T.MAX_EVENTS_PER_SHOW);
        const events = [];
        for (const e of evs) {
          const seat = seatTally(e.seats);
          let activeTickets = 0, checkedIn = 0;
          if (budget > 0) {
            budget -= 1;
            const ts = await col('Ticket').where('eventId', '==', e.id).select('paymentStatus', 'orderMethod', 'usedAt').limit(N.MAX_TICKETS_SCAN).get();
            ts.docs.forEach((d) => { const x = d.data(); if (INACTIVE.has(ticketStatusOf(x))) return; activeTickets += 1; if (x.usedAt) checkedIn += 1; });
          }
          events.push({ eventId: e.id, ms: e.ms, ...seat, occupancy: seat.total ? Math.round((seat.sold / seat.total) * 100) : 0, activeTickets, checkedIn });
        }
        out.push({ teamId, showId: sh.id, name: sh.data().name || '', events, totals: events.reduce((a, e) => ({ sold: a.sold + e.sold, held: a.held + e.held, total: a.total + e.total, checkedIn: a.checkedIn + e.checkedIn }), { sold: 0, held: 0, total: 0, checkedIn: 0 }) });
      }
    }
    return { shows: out, now: t };
  }

  // ---------------------------------------------------------------- admin: atama / geri alma
  async function adminSetTeamManager(adminUid, data) {
    const admin = await isAdminUser(adminUid);
    if (!admin) throw err('permission-denied', 'Bu işlem için yönetici yetkisi gerekir.');
    data = data || {};
    if (!['add', 'revoke'].includes(data.action)) throw err('invalid-argument', 'Geçersiz işlem.');
    const teamId = validateId(data.teamId, 'ekip');
    const team = await col('Team').doc(teamId).get();
    if (!team.exists) throw err('not-found', 'Topluluk bulunamadı.');

    let uid = null;
    if (typeof data.uid === 'string' && data.uid) uid = validateId(data.uid, 'kullanıcı');
    else if (typeof data.email === 'string' && data.email.trim()) {
      const email = data.email.trim().toLowerCase();
      if (!EMAIL_RE.test(email)) throw err('invalid-argument', 'Geçerli bir e-posta adresi yaz.');
      try { uid = (await auth.getUserByEmail(email)).uid; } catch (e) {
        if (e && (e.code === 'auth/user-not-found' || (e.errorInfo && e.errorInfo.code === 'auth/user-not-found'))) {
          throw err('not-found', 'Bu e-postayla kayıtlı bir hesap yok. Kişi önce web sitesine ya da uygulamaya bu e-postayla giriş yapmalı.');
        }
        throw e;
      }
    } else throw err('invalid-argument', 'E-posta ya da kullanıcı no gerekli.');

    const ref = col('TeamManager').doc(`${teamId}_${uid}`);
    const logAct = async (action) => {
      await col('TeamManagerLog').add({ action, teamId, targetUid: uid, by: adminUid, at: Timestamp.fromMillis(now()) });
      log.info('TeamManager', { action, teamId });
    };
    const cur = await ref.get();
    if (data.action === 'revoke') {
      if (!cur.exists) throw err('not-found', 'Bu kişi bu topluluğun yöneticisi değil.');
      if (cur.data().status === 'revoked') return { ok: true, already: true, status: 'revoked' };
      await ref.update({ status: 'revoked', revokedAt: Timestamp.fromMillis(now()), revokedBy: adminUid });
      await logAct('revoke');
      return { ok: true, already: false, status: 'revoked' };
    }
    // add
    const del = await col('AccountDeletion').doc(uid).get();
    if (del.exists && isBlocking(del.data())) throw err('failed-precondition', 'Bu hesabın silinme işlemi sürüyor; yönetici atanamaz.');
    const u = await col('User').doc(uid).get();
    const ud = u.exists ? u.data() : {};
    if (cur.exists && cur.data().status === 'active') return { ok: true, already: true, status: 'active', phoneActive: ud.isPhoneActive === true };
    let email = '';
    try { email = (await auth.getUser(uid)).email || ''; } catch (e) {
      if (e && (e.code === 'auth/user-not-found' || (e.errorInfo && e.errorInfo.code === 'auth/user-not-found'))) throw err('not-found', 'Kullanıcı bulunamadı.');
      throw e;
    }
    await ref.set({
      teamId, uid, status: 'active', addedBy: adminUid, addedAt: Timestamp.fromMillis(now()),
      displayName: `${ud.firstName || ''} ${ud.lastName || ''}`.trim(), emailHint: maskEmail(email), phoneActive: ud.isPhoneActive === true,
    });
    await logAct('add');
    return { ok: true, already: false, status: 'active', phoneActive: ud.isPhoneActive === true, displayName: `${ud.firstName || ''} ${ud.lastName || ''}`.trim(), emailHint: maskEmail(email) };
  }

  return {
    getMyManagedTeams, teamNotifyPreview, teamSendNotification, teamCheckIn, teamStats, adminSetTeamManager,
    resolveEventTeam, resolveEventScope, assertCanManageEvent, assertCanManageShow,
  };
}

module.exports = { createTeam, freeTextProblem, teamTemplateList };

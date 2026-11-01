'use strict';
/**
 * F-1: TAKİP ET -> yeni oyun / seans bildirimi (docs/TAKIP-ET.md).
 * "Takip" = favori alanları (User.favoritePlayers / favoriteStages / favoriteTeams); yeni koleksiyon YOK.
 * Tetik: yeni Event (ya da Event.showId / Show.eventsId bağlanması). Zamanlanmış iş AÇILMAZ (Firestore tetikleyici).
 * Kategori `newShows`: kullanıcı notifPrefs.newShows === true ile AÇIKÇA açmadıkça ne push ne uygulama içi kutu.
 * Güvenceler: tek kullanıcıya tek mesaj (oyuncu > topluluk > sahne), günlük üst sınır, aynı oyun için 24 saatte tek,
 * event başına `followNotified` bayrağı + kullanıcı başına kilit belgesi `fol_<event>_<uid>`, geçmiş/iptal seansa gönderme yok.
 * Kişisel veri: günlükte yalnız sayılar; mesajda yalnız herkese açık adlar (oyuncu/oyun/sahne/topluluk), URL yok.
 */
const { Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { parseEventDateMs } = require('./util');
const prefsLib = require('./notify-prefs');
const { isCancelled, slugify, buildMessage } = require('./notify');

const FOLLOW = {
  MAX_FOLLOWERS: 5000, // bir seans için taranan benzersiz takipçi üst sınırı (okuma maliyeti sınırı)
  PAGE: 500, // sayfalı okuma
  DAILY_MAX: 3, // kullanıcı başına günlük takip bildirimi (bildirim yorgunluğu)
  SHOW_DEDUPE_MS: 24 * 3600e3, // aynı oyun için kullanıcıya 24 saatte en çok 1 (çok seans eklenince yığılma olmasın)
  MAX_CAST: 60, MAX_NEW_EVENTS_PER_SHOW_WRITE: 50, CONCURRENCY: 20,
};
const FIELD = { player: 'favoritePlayers', team: 'favoriteTeams', stage: 'favoriteStages' };
const PRIORITY = ['player', 'team', 'stage']; // tek mesaj önceliği
const isExists = (e) => e && (e.code === 6 || String(e.code) === 'already-exists');
const clip = (s, n) => (s.length > n ? `${s.slice(0, n - 1).trimEnd()}…` : s);
const ids = (a) => [...new Set((Array.isArray(a) ? a : []).filter((x) => typeof x === 'string' && x && !x.includes('/')))];
const hhmm = (ms) => { const d = new Date(ms + cfg.TZ_OFFSET_MIN * 60000); return `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`; };
const dayOf = (ms) => new Date(ms + cfg.TZ_OFFSET_MIN * 60000).toISOString().slice(0, 10);
const fmtWhen = (ms) => { const [y, m, d] = dayOf(ms).split('-'); return `${d}.${m}.${y} ${hhmm(ms)}`; };

/** Mesaj şablonu (sunucuda sabit). Metinde URL yok; yalnız herkese açık adlar. kind: 'player' | 'team' | 'stage'. */
function composeMessage(kind, { oyuncu = '', topluluk = '', sahne = '', oyun = '', ms }) {
  const N = cfg.NOTIFY, o = clip(oyun || 'Yeni oyun', 50), when = ms != null ? fmtWhen(ms) : '';
  const tail = [sahne, when].filter(Boolean).join(' · ');
  if (kind === 'player') return { title: clip(`${oyuncu || 'Takip ettiğin oyuncu'} yeni bir oyunda`, N.TITLE_MAX), body: clip(`${o}${tail ? ` — ${tail}` : ''}`, N.BODY_MAX) };
  if (kind === 'team') return { title: clip(`${topluluk || 'Takip ettiğin topluluk'} yeni bir oyunda`, N.TITLE_MAX), body: clip(`${o}${tail ? ` — ${tail}` : ''}`, N.BODY_MAX) };
  return { title: clip(`Takip ettiğin sahnede yeni seans: ${o}`, N.TITLE_MAX), body: clip([sahne, when].filter(Boolean).join(' · ') || o, N.BODY_MAX) };
}

/** `ignoreSwitch`: yalnız testler (emülatördeki gerçek tetikleyiciyi Config anahtarıyla susturup işlemi doğrudan çağırmak için). */
function createFollowNotifier({ db, notifier, now = Date.now, log = console, ignoreSwitch = false }) {
  const col = (n) => db.collection(n);
  const I = notifier.internals;

  /** Bir varlığın (oyuncu/sahne/ekip) takipçileri: uid -> {prefs, tokens}. Yalnız newShows === true olanlar. `room`: kalan kota. */
  async function followersOf(field, id, room, out) {
    if (room <= 0) return false;
    const sel = ['notifPrefs', 'fcmToken', 'fcmTokens', 'deletionStatus'];
    let filtered = true, last = null, truncated = false;
    for (;;) {
      const lim = Math.min(FOLLOW.PAGE, room);
      // Bileşik dizin (array-contains + notifPrefs.newShows) varsa kapalı olanlar hiç okunmaz; yoksa (dizin dağıtılmamış) tüm takipçiler okunup bellekte süzülür.
      let q = col('User').where(field, 'array-contains', id);
      if (filtered) q = q.where('notifPrefs.newShows', '==', true);
      q = q.select(...sel).limit(lim);
      if (last) q = q.startAfter(last);
      let s;
      try { s = await q.get(); } catch (e) {
        if (filtered && (e.code === 9 || /index/i.test(String(e.message)))) { filtered = false; log.warn && log.warn('follow: dizin yok, süzme bellekte', { field }); last = null; continue; }
        throw e;
      }
      for (const d of s.docs) {
        const u = d.data();
        if (u.deletionStatus || !u.notifPrefs || u.notifPrefs.newShows !== true) continue;
        if (!out.has(d.id)) {
          if (out.size >= FOLLOW.MAX_FOLLOWERS) { truncated = true; continue; }
          const list = [...(Array.isArray(u.fcmTokens) ? u.fcmTokens : []), u.fcmToken];
          out.set(d.id, { prefs: u.notifPrefs, tokens: [...new Set(list.filter((t) => typeof t === 'string' && t.length > 20))], via: [] });
        }
        out.get(d.id).via.push({ kind: Object.keys(FIELD).find((k) => FIELD[k] === field), id });
      }
      room -= s.size;
      if (s.size < lim) break;
      if (room <= 0) { truncated = true; break; }
      last = s.docs[s.docs.length - 1];
    }
    return truncated;
  }

  /** Günlük üst sınır + aynı oyun 24 saat tekilleştirme (tek işlem). 'ok' | 'retry' (aynı seans, kilit belgesi karar verir) | 'cap' | 'dup-show'. */
  async function claimUser(uid, showId, eventId, t) {
    const ref = col('UserLimits').doc(uid);
    return db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const day = dayOf(t);
      const rec = (Array.isArray(d.followShows) ? d.followShows : []).filter((x) => typeof x === 'string')
        .map((x) => { const [s, ms, ev] = x.split('|'); return { s, ms: Number(ms), ev }; })
        .filter((x) => t - x.ms < FOLLOW.SHOW_DEDUPE_MS);
      const prev = rec.find((x) => x.s === showId);
      if (prev) return prev.ev === eventId ? 'retry' : 'dup-show';
      const count = d.followDay === day ? d.followCount || 0 : 0;
      if (count >= FOLLOW.DAILY_MAX) return 'cap';
      rec.push({ s: showId, ms: t, ev: eventId });
      tx.set(ref, { followDay: day, followCount: count + 1, followShows: rec.map((x) => `${x.s}|${x.ms}|${x.ev}`) }, { merge: true });
      return 'ok';
    });
  }

  async function pool(items, fn) {
    let i = 0;
    await Promise.all(Array.from({ length: Math.min(FOLLOW.CONCURRENCY, items.length) }, async () => {
      while (i < items.length) { const k = i; i += 1; await fn(items[k]); }
    }));
  }

  /** Bir seans için takipçilere bildirim. İdempotent. */
  async function processEvent(eventId) {
    const t = now();
    const conf = (await col('Config').doc('bildirim').get()).data() || {};
    if (conf.followNotify === false && !ignoreSwitch) return { skipped: 'disabled' };
    const eref = col('Event').doc(eventId);
    const es = await eref.get();
    if (!es.exists) return { skipped: 'no-event' };
    const ev = es.data();
    if (ev.followNotified) return { skipped: 'already' };
    if (isCancelled(ev)) return { skipped: 'cancelled' };
    const ms = parseEventDateMs(ev.date);
    if (ms == null || ms <= t) return { skipped: 'past' };

    // Show: Event.showId tek doğruluk kaynağı; boşsa Show.eventsId yedeği (tam 1 eşleşme şart).
    let showSnap = null;
    if (typeof ev.showId === 'string' && ev.showId && !ev.showId.includes('/')) showSnap = await col('Show').doc(ev.showId).get();
    else {
      const q = await col('Show').where('eventsId', 'array-contains', eventId).limit(2).get();
      if (q.size === 1) showSnap = q.docs[0];
    }
    if (!showSnap || !showSnap.exists) return { skipped: 'no-show' };
    const show = showSnap.data(), showId = showSnap.id;
    const cast = ids(show.nowPlayersId).slice(0, FOLLOW.MAX_CAST);
    const stageId = typeof ev.stageId === 'string' && ev.stageId ? ev.stageId : '';
    const teamId = typeof show.teamId === 'string' && show.teamId ? show.teamId : '';

    const key = `fol_${eventId}`;
    const logRef = col('NotificationLog').doc(key);
    // Ön kontrol (yalnız okuma): bu seans için gönderim zaten tamamlandıysa tekrar etme.
    {
      const ls = await logRef.get();
      if (ls.exists && (ls.data() || {}).status === 'done') return { duplicate: true, logId: key };
    }

    // 1) takipçileri topla (benzersiz; üst sınır 5.000)
    const cands = new Map();
    let truncated = false;
    const targets = [...cast.map((id) => ['player', id]), ...(teamId ? [['team', teamId]] : []), ...(stageId ? [['stage', stageId]] : [])];
    for (const [kind, id] of targets) {
      if (await followersOf(FIELD[kind], id, FOLLOW.MAX_FOLLOWERS - cands.size + 1, cands)) truncated = true;
    }
    const considered = cands.size;

    // 2) her kullanıcı için TEK eşleşme: oyuncu (kadro sırası) > topluluk > sahne
    const pick = new Map();
    for (const [uid, c] of cands) {
      const best = PRIORITY.map((k) => c.via.find((v) => v.kind === k)).find(Boolean);
      if (best) pick.set(uid, best);
    }

    // Takip eden kimse yoksa HİÇBİR ŞEY yazma (günlük/kilit yok): boşuna yazma ve test/log kirliliği olmasın.
    if (!pick.size) return { skipped: 'no-followers', considered };
    try {
      await logRef.create({
        sentBy: 'system', sentByName: 'Otomatik', auto: true, target: { type: 'event', id: eventId }, targetLabel: `Takip: ${clip(show.name || '', 40)}`,
        template: 'takip_yeni_oyun', kind: 'normal', category: 'newShows', title: 'Takip edenlere yeni oyun/seans', body: '', recipients: 0, status: 'sending', createdAt: Timestamp.fromMillis(t),
      });
    } catch (e) {
      if (!isExists(e)) throw e;
      if ((await logRef.get()).data().status === 'done') return { duplicate: true, logId: key };
    }

    // 3) adlar (yalnız eşleşenler)
    const names = new Map();
    const need = [...new Set([...pick.values()].map((v) => `${v.kind}:${v.id}`))];
    await Promise.all(need.map(async (k) => {
      const [kind, id] = [k.slice(0, k.indexOf(':')), k.slice(k.indexOf(':') + 1)];
      const d = await col({ player: 'Player', team: 'Team', stage: 'Stage' }[kind]).doc(id).get();
      const x = d.exists ? d.data() : {};
      names.set(k, kind === 'player' ? `${x.firstName || ''} ${x.lastName || ''}`.trim() || x.name || '' : x.name || '');
    }));
    const sahneAd = ev.stageId ? (await col('Stage').doc(stageId).get()).data()?.name || '' : '';

    // 4) kilit + günlük sınır + kutu belgesi; yeni olanlara push
    const slug = `${slugify(show.name)}-${showId}`;
    const route = `/show/${slug}`; // mobil rota (PushRoutes._detail); web karşılığı /oyun/<slug>-<id>
    const stats = { considered, matched: pick.size, capped: 0, dupShow: 0, inbox: 0, withToken: 0, success: 0, failure: 0, suppressed: { category: 0, quiet: 0 }, truncated };
    const groups = new Map(); // mesaj anahtarı -> {msg, uids}
    const iso = new Date(t).toISOString();
    await pool([...pick], async ([uid, v]) => {
      const claim = await claimUser(uid, showId, eventId, t);
      if (claim === 'cap') { stats.capped += 1; return; }
      if (claim === 'dup-show') { stats.dupShow += 1; return; }
      const gk = `${v.kind}:${v.id}`, nm = names.get(gk) || '';
      const msg = composeMessage(v.kind, { oyuncu: nm, topluluk: nm, sahne: sahneAd || (v.kind === 'stage' ? nm : ''), oyun: show.name || '', ms });
      const id = `fol_${eventId}_${uid}`;
      try {
        await col('Notification').doc(id).create({ _id: id, userId: uid, title: msg.title, body: msg.body, type: 'announcement', eventId, showId, isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(t) });
      } catch (e) { if (isExists(e)) return; throw e; }
      stats.inbox += 1;
      if (!groups.has(gk)) groups.set(gk, { msg, uids: [] });
      groups.get(gk).uids.push(uid);
    });

    for (const { msg, uids } of groups.values()) {
      const rc = { tokens: new Map(), loud: new Set(), prefs: new Map() };
      for (const u of uids) { const c = cands.get(u); rc.prefs.set(u, c.prefs); if (c.tokens.length) rc.tokens.set(u, c.tokens); }
      const f = I.filterByPrefs(rc, 'newShows', t); // newShows açık (zaten süzüldü) + sessiz saat -> push yok (kutu yazıldı)
      stats.suppressed.category += f.suppressed.category; stats.suppressed.quiet += f.suppressed.quiet;
      stats.withToken += f.rc.tokens.size;
      const r = await I.pushByPrefs(f.rc, () => buildMessage({ title: msg.title, body: msg.body, kind: 'normal', eventId, now: t, route }), 'normal');
      stats.success += r.success; stats.failure += r.failure;
    }

    try { await eref.update({ followNotified: Timestamp.fromMillis(t) }); } catch (e) { log.error('followNotified bayrağı yazılamadı', { code: e && e.code }); }
    await logRef.update({ status: 'done', recipients: stats.matched, inApp: stats.inbox, withToken: stats.withToken, success: stats.success, failure: stats.failure, suppressed: stats.suppressed, capped: stats.capped, dupShow: stats.dupShow, truncated, finishedAt: Timestamp.fromMillis(t) });
    return { ok: true, logId: key, ...stats };
  }

  /** Event yazıldı (create | update): yeni seans ya da showId bağlandı. */
  async function onEventWritten(eventId, before, after) {
    if (!after) return { skipped: 'deleted' };
    const eligible = !before || (typeof after.showId === 'string' && after.showId && after.showId !== before.showId);
    if (!eligible) return { skipped: 'not-new' };
    return processEvent(eventId);
  }

  /** Show yazıldı: Show.eventsId'e eklenen seanslar (Event.showId boşsa bağlama bu yolla olur). */
  async function onShowWritten(showId, before, after) {
    if (!after) return { skipped: 'deleted' };
    const old = new Set(ids(before && before.eventsId));
    const added = ids(after.eventsId).filter((x) => !old.has(x)).slice(0, FOLLOW.MAX_NEW_EVENTS_PER_SHOW_WRITE);
    if (!added.length) return { skipped: 'no-new-events' };
    const out = [];
    for (const id of added) out.push({ eventId: id, ...(await processEvent(id)) });
    return { ok: true, events: out.length, results: out.map((r) => r.skipped || (r.duplicate ? 'duplicate' : 'sent')) };
  }

  return { processEvent, onEventWritten, onShowWritten };
}

module.exports = { createFollowNotifier, composeMessage, FOLLOW, FIELD };

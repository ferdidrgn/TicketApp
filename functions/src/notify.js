'use strict';
/**
 * Bildirim gönderme ("Sahne kumandası") ve otomatik hatırlatmalar.
 * Firebase Messaging enjekte edilir (testte sahte). FCM gönderimi ücretsizdir; maliyet Firestore okuma/yazmasındadır.
 * Kısıt: mobil tarafta kullanıcı başına TEK token (User.fcmToken) tutulur — çok cihazlı kullanıcıya yalnız son giriş yapılan cihaz ulaşır.
 */
const crypto = require('crypto');
const { FieldPath, Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, parseEventDateMs, validateId } = require('./util');

const N = cfg.NOTIFY;
const INACTIVE = new Set(['cancelled', 'no_show']);

/**
 * Sabit şablon listesi (sunucuda). `timed`: yalnızca bir SEANS hedefiyle ve seansa ±24 saat kala gönderilebilir.
 * `custom`: metni yönetici yazar. `kind`: normal | alarm (alarm şablonunda sabit).
 */
const TEMPLATES = {
  baslamak_uzere: { label: 'Oyun {dk} dk sonra başlıyor', kind: 'alarm', timed: true, param: { name: 'dk', allowed: [5, 10], def: 10 }, title: '{oyun} {dk} dakika sonra başlıyor', body: 'Lütfen yerlerinizi alın. ({sahne})' },
  basladi: { label: 'Oyun başladı — telefonlar sessize', kind: 'normal', timed: true, title: '{oyun} başladı', body: 'Lütfen telefonlarınızı sessize alın veya kapatın.' },
  ara: { label: 'Birinci perde bitti — ara', kind: 'normal', timed: true, param: { name: 'dk', min: 5, max: 30, def: 15 }, title: 'Birinci perde bitti', body: '{oyun} — {dk} dakika ara.' },
  ara_bitiyor: { label: 'Ara bitiyor — 5 dk', kind: 'alarm', timed: true, title: 'Ara bitiyor', body: '5 dakika içinde yerlerimizi alalım. ({oyun})' },
  bitti: { label: 'Oyun bitti — teşekkürler', kind: 'normal', timed: true, title: '{oyun} bitti — teşekkürler', body: 'İzlenimini yazarak diğer seyircilere yardımcı olabilirsin.' },
  ertelendi: { label: 'Seans ertelendi', kind: 'normal', custom: true, targets: ['event', 'show'], title: '{oyun} seansı ertelendi', body: '' },
  iptal: { label: 'Seans iptal edildi', kind: 'normal', custom: true, targets: ['event', 'show'], title: '{oyun} seansı iptal edildi', body: '' },
  genel: { label: 'Genel duyuru', kind: 'normal', custom: true, title: '', body: '' },
};

function templateList() {
  return Object.entries(TEMPLATES).map(([id, t]) => ({
    id, label: t.label, kind: t.kind, timed: !!t.timed, custom: !!t.custom,
    targets: t.timed ? ['event'] : t.targets || ['all', 'user', 'show', 'event'],
    ...(t.param ? { param: { name: t.param.name, allowed: t.param.allowed || null, min: t.param.min ?? null, max: t.param.max ?? null, def: t.param.def } } : {}),
    defaultTitle: t.title, defaultBody: t.body,
  }));
}

const clip = (s, n) => (s.length > n ? `${s.slice(0, n - 1).trimEnd()}…` : s);
const fill = (s, v) => s.replace(/\{(oyun|sahne|dk|saat)\}/g, (_, k) => (v[k] == null ? '' : String(v[k])));
const hhmm = (ms) => { const d = new Date(ms + cfg.TZ_OFFSET_MIN * 60000); return `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`; };
const dayOf = (ms) => new Date(ms + cfg.TZ_OFFSET_MIN * 60000).toISOString().slice(0, 10);
/** İstanbul gün öneki, Event.date biçimiyle ("gg.aa.yyyy,"). */
const datePrefix = (ms) => { const [y, m, d] = dayOf(ms).split('-'); return `${d}.${m}.${y},`; };

/**
 * FCM mesajı (hedef alanı hariç).
 * Alarm + `loud` (alıcı notifPrefs.loudAlarm === true ile AÇIKÇA izin verdi): yüksek öncelik + `tiyatrol_alarm` kanalı (Android ALARM ses akışı,
 * sessiz modda da duyulur) + kısa TTL + iOS time-sensitive.
 * Alarm + !loud (izin yok / tercih yok / konu hedefi): içerik ve aciliyet aynı (yüksek öncelik, kısa TTL) ama NORMAL kanal ve normal ses:
 * telefon sessizdeyse sessiz gelir; iOS'ta time-sensitive de verilmez (Odak/Rahatsız Etme'yi aşmak da izne bağlıdır).
 * Sunucu telefonun zil modunu değiştiremez; bu yalnız hangi kanala düşüleceğini seçer.
 */
function buildMessage({ title, body, kind, eventId, now, loud = false }) {
  const data = { kind, route: '/notifications' };
  if (eventId) data.eventId = String(eventId);
  if (kind === 'alarm' && !loud) {
    return {
      notification: { title, body }, data,
      android: { priority: 'high', ttl: N.ALARM_TTL_MS, notification: { channelId: N.DEFAULT_CHANNEL, sound: 'default', priority: 'high', visibility: 'public' } },
      apns: { headers: { 'apns-priority': '10', 'apns-push-type': 'alert', 'apns-expiration': String(Math.floor(now / 1000) + N.ALARM_TTL_MS / 1000) }, payload: { aps: { sound: 'default', 'interruption-level': 'active' } } },
    };
  }
  if (kind === 'alarm') {
    return {
      notification: { title, body }, data,
      android: { priority: 'high', ttl: N.ALARM_TTL_MS, notification: { channelId: N.ALARM_CHANNEL, sound: 'default', priority: 'max', defaultVibrateTimings: true, visibility: 'public' } },
      apns: { headers: { 'apns-priority': '10', 'apns-push-type': 'alert', 'apns-expiration': String(Math.floor(now / 1000) + N.ALARM_TTL_MS / 1000) }, payload: { aps: { sound: 'default', 'interruption-level': 'time-sensitive' } } },
    };
  }
  return { notification: { title, body }, data, android: { priority: 'normal' }, apns: { payload: { aps: { sound: 'default' } } } };
}

function createNotifier({ db, messaging, assertAdmin, now = Date.now, log = console }) {
  const col = (n) => db.collection(n);

  // ---------------------------------------------------------------- ortak
  /** uid -> token ve "sessizde sesli hatırlat" izni veren uid kümesi (yalnız notifPrefs.loudAlarm === true; başka her şey = izin yok). */
  async function loadRecipients(userIds) {
    const tokens = new Map(); // uid -> token
    const loud = new Set(); // izinli uid'ler (yalnız token'ı olanlar)
    for (let i = 0; i < userIds.length; i += 300) {
      const refs = userIds.slice(i, i + 300).map((u) => col('User').doc(u));
      const snaps = await db.getAll(...refs, { fieldMask: ['fcmToken', 'notifPrefs'] });
      snaps.forEach((s, j) => {
        const d = s.exists ? s.data() : {};
        const tk = d.fcmToken;
        if (typeof tk === 'string' && tk.length > 20) {
          tokens.set(userIds[i + j], tk);
          if (d.notifPrefs && d.notifPrefs.loudAlarm === true) loud.add(userIds[i + j]);
        }
      });
    }
    return { tokens, loud };
  }
  async function loadTokens(userIds) { return (await loadRecipients(userIds)).tokens; }

  /**
   * Token bazlı gönderim. Alarm türünde alıcılar tercihe göre ikiye bölünür (izinli -> alarm kanalı, diğerleri -> normal kanal):
   * iki ayrı multicast. Maliyet: FCM ücretsiz; çağrı sayısı en çok iki katına çıkar (500'lük parçalar her grup için ayrı).
   */
  async function pushByPrefs({ tokens: tokenMap, loud }, build, kind) {
    const group = (uids) => {
      const owners = new Map();
      for (const u of uids) { const tk = tokenMap.get(u); owners.set(tk, [...(owners.get(tk) || []), u]); }
      return owners;
    };
    const parts = kind === 'alarm'
      ? [[true, [...tokenMap.keys()].filter((u) => loud.has(u))], [false, [...tokenMap.keys()].filter((u) => !loud.has(u))]]
      : [[false, [...tokenMap.keys()]]];
    const total = { success: 0, failure: 0, chunks: 0, loud: 0 };
    for (const [isLoud, uids] of parts) {
      if (!uids.length) continue;
      const owners = group(uids);
      const r = await pushTokens([...owners.keys()], build(isLoud), owners);
      total.success += r.success; total.failure += r.failure; total.chunks += r.chunks;
      if (isLoud) total.loud += uids.length;
    }
    return total;
  }

  /** Token'ları 500'lük parçalarla gönderir; kalıcı geçersiz token'ları temizler. */
  async function pushTokens(tokens, msg, tokenOwner) {
    const uniq = [...new Set(tokens)];
    let success = 0, failure = 0, chunks = 0;
    for (let i = 0; i < uniq.length; i += N.MULTICAST_CHUNK) {
      const part = uniq.slice(i, i + N.MULTICAST_CHUNK);
      chunks += 1;
      try {
        const r = await messaging.sendEachForMulticast({ ...msg, tokens: part });
        success += r.successCount; failure += r.failureCount;
        const dead = [];
        (r.responses || []).forEach((x, j) => {
          const c = x && x.error && x.error.code;
          if (c === 'messaging/registration-token-not-registered' || c === 'messaging/invalid-registration-token') dead.push(part[j]);
        });
        for (const tk of dead) for (const uid of tokenOwner.get(tk) || []) {
          try { // yalnız hâlâ aynı token ise sil (kullanıcı arada yenilemiş olabilir)
            const ref = col('User').doc(uid);
            await db.runTransaction(async (tx) => { const d = await tx.get(ref); if (d.exists && d.data().fcmToken === tk) tx.update(ref, { fcmToken: '' }); });
          } catch { /* temizlik zorunlu değil */ }
        }
      } catch (e) {
        failure += part.length; log.error('multicast hata', { code: e && e.code });
      }
    }
    return { success, failure, chunks };
  }

  async function writeInApp(userIds, base, idPrefix) {
    let batch = db.batch(), n = 0, total = 0;
    const iso = new Date(now()).toISOString();
    for (const uid of userIds) {
      const id = `${idPrefix}_${uid}`;
      batch.set(col('Notification').doc(id), { _id: id, userId: uid, isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(now()), ...base });
      n += 1; total += 1;
      if (n >= 400) { await batch.commit(); batch = db.batch(); n = 0; }
    }
    if (n) await batch.commit();
    return total;
  }

  // ---------------------------------------------------------------- hedef çözümleme
  async function eventContext(eventId) {
    const e = await col('Event').doc(eventId).get();
    if (!e.exists) throw err('not-found', 'Seans bulunamadı.');
    const ev = e.data();
    const [sh, st] = await Promise.all([
      ev.showId ? col('Show').doc(ev.showId).get() : null, ev.stageId ? col('Stage').doc(ev.stageId).get() : null,
    ]);
    return { eventId, showId: ev.showId || '', oyun: (sh && sh.exists && sh.data().name) || '', sahne: (st && st.exists && st.data().name) || '', ms: parseEventDateMs(ev.date) };
  }

  async function activeCustomers(field, id) {
    const snap = await col('Ticket').where(field, '==', id).select('customerId', 'paymentStatus').limit(N.MAX_TICKETS_SCAN).get();
    const ids = new Set();
    snap.docs.forEach((d) => {
      const x = d.data();
      if (INACTIVE.has(x.paymentStatus) || typeof x.customerId !== 'string' || !x.customerId || x.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID) return;
      ids.add(x.customerId);
    });
    return { ids: [...ids], tickets: snap.size };
  }

  /** target -> {type, id, userIds, ctx, label}. `all` için userIds boştur (konu + kullanıcı sayısı ayrıca). */
  async function resolveTarget(target) {
    if (!target || typeof target !== 'object') throw err('invalid-argument', 'Hedef gerekli.');
    const type = target.type;
    if (!['all', 'user', 'show', 'event'].includes(type)) throw err('invalid-argument', 'Geçersiz hedef türü.');
    if (type === 'all') return { type, id: '', userIds: [], ctx: {}, label: 'Tüm kullanıcılar' };
    const id = validateId(target.id, 'hedef');
    if (type === 'user') {
      const u = await col('User').doc(id).get();
      if (!u.exists) throw err('not-found', 'Kullanıcı bulunamadı.');
      return { type, id, userIds: [id], ctx: {}, label: 'Tek kullanıcı' };
    }
    if (type === 'event') {
      const ctx = await eventContext(id);
      const a = await activeCustomers('eventId', id);
      return { type, id, userIds: a.ids, tickets: a.tickets, ctx, label: `Seans: ${ctx.oyun}` };
    }
    const sh = await col('Show').doc(id).get();
    if (!sh.exists) throw err('not-found', 'Oyun bulunamadı.');
    const a = await activeCustomers('showId', id);
    return { type, id, userIds: a.ids, tickets: a.tickets, ctx: { oyun: sh.data().name || '', sahne: '', showId: id }, label: `Oyun: ${sh.data().name || id}` };
  }

  /** Şablon/metin -> {title, body, kind, template}. Kuralları (±24 saat, hedef türü, uzunluk) burada denetler. */
  function compose(input, tgt, lenient = false) {
    const tplId = input.template == null || input.template === '' ? null : String(input.template);
    const tpl = tplId ? TEMPLATES[tplId] : null;
    if (tplId && !tpl) throw err('invalid-argument', 'Bilinmeyen şablon.');
    let dk;
    if (tpl && tpl.param) {
      const p = tpl.param, raw = input.params && input.params[p.name] != null ? Number(input.params[p.name]) : p.def;
      const okv = p.allowed ? p.allowed.includes(raw) : Number.isInteger(raw) && raw >= p.min && raw <= p.max;
      if (!okv) throw err('invalid-argument', `Geçersiz ${p.name} değeri.`);
      dk = raw;
    }
    if (tpl && tpl.timed) {
      if (tgt.type !== 'event') throw err('failed-precondition', 'Bu şablon yalnızca bir seansın biletlilerine gönderilir.');
      if (tgt.ctx.ms == null || Math.abs(tgt.ctx.ms - now()) > N.TIMED_WINDOW_MS) {
        throw err('failed-precondition', 'Bu şablon yalnızca seansa ±24 saat kala gönderilebilir.');
      }
    }
    if (tpl && tpl.targets && !tpl.timed && !tpl.targets.includes(tgt.type)) throw err('failed-precondition', 'Bu şablon bu hedef türüyle kullanılamaz.');
    const vars = { oyun: clip(tgt.ctx.oyun || '', 40), sahne: tgt.ctx.sahne || '', dk, saat: tgt.ctx.ms ? hhmm(tgt.ctx.ms) : '' };
    let title, body, kind;
    if (tpl && !tpl.custom) { // sabit şablon: metin SUNUCUDA üretilir, istemci metni yok sayılır
      title = clip(fill(tpl.title, vars).trim(), N.TITLE_MAX); body = clip(fill(tpl.body, vars).trim(), N.BODY_MAX); kind = tpl.kind;
    } else {
      const rawT = typeof input.title === 'string' && input.title.trim() ? input.title : tpl ? tpl.title : '';
      title = fill(String(rawT), vars).replace(/\s+/g, ' ').trim();
      body = fill(typeof input.body === 'string' ? input.body : '', vars).trim();
      kind = input.kind === 'alarm' ? 'alarm' : 'normal';
      if (!lenient && (!title || !body)) throw err('invalid-argument', 'Başlık ve mesaj gerekli.');
      if (title.length > N.TITLE_MAX) throw err('invalid-argument', `Başlık en fazla ${N.TITLE_MAX} karakter olabilir.`);
      if (body.length > N.BODY_MAX) throw err('invalid-argument', `Mesaj en fazla ${N.BODY_MAX} karakter olabilir.`);
    }
    if (input.kind != null && !['normal', 'alarm'].includes(input.kind)) throw err('invalid-argument', 'Geçersiz bildirim türü.');
    return { title, body, kind, template: tplId };
  }

  // ---------------------------------------------------------------- callable'lar
  /** Gönderimden ÖNCE: kaç kişiye ulaşılır + şablon listesi + üretilmiş metin önizlemesi. Veri maliyeti gönderimle aynı okumalar. */
  async function adminNotifyPreview(uid, data) {
    await assertAdmin(uid);
    data = data || {};
    const tgt = await resolveTarget(data.target);
    let recipients, withToken, topic = false, loudAlarm = null;
    if (tgt.type === 'all') {
      topic = true;
      const [users, tok] = await Promise.all([
        col('User').count().get(), col('User').where('fcmToken', '>', '').count().get(),
      ]);
      recipients = users.data().count; withToken = tok.data().count;
    } else {
      recipients = tgt.userIds.length;
      const rc = await loadRecipients(tgt.userIds);
      withToken = rc.tokens.size;
      loudAlarm = { optedIn: rc.loud.size, of: withToken }; // "X kişiden Y'si sessizde sesli hatırlatmayı açtı" (yalnız alarm türünde anlamlı)
    }
    let preview = null, blocked = null;
    if (data.template || data.title) {
      try { preview = compose(data, tgt, true); } catch (e) { blocked = e.message; }
    }
    return {
      target: { type: tgt.type, id: tgt.id, label: tgt.label }, recipients, withToken, loudAlarm, tickets: tgt.tickets ?? null, topic,
      event: tgt.type === 'event' ? { show: tgt.ctx.oyun, stage: tgt.ctx.sahne, ms: tgt.ctx.ms } : null,
      preview, blocked, templates: templateList(), now: now(),
    };
  }

  async function rateLimit(uid) {
    const ref = col('UserLimits').doc(uid);
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let start = d.notifyWindowStart || 0, count = d.notifyCount || 0;
      if (t - start >= N.RATE.windowMs) { start = t; count = 0; }
      if (count + 1 > N.RATE.max) throw err('resource-exhausted', `Saatlik bildirim sınırına ulaşıldı (${N.RATE.max}). Daha sonra tekrar deneyin.`);
      tx.set(ref, { notifyWindowStart: start, notifyCount: count + 1 }, { merge: true });
    });
  }

  async function adminSendNotification(uid, data) {
    await assertAdmin(uid);
    data = data || {};
    const tgt = await resolveTarget(data.target);
    const msgIn = compose(data, tgt);
    if (data.requestId != null && !/^[A-Za-z0-9_-]{8,64}$/.test(String(data.requestId))) throw err('invalid-argument', 'Geçersiz istek kimliği.');

    let recipients = tgt.userIds.length, tokenMap = null, allUsers = null;
    if (tgt.type === 'all') {
      allUsers = (await col('User').count().get()).data().count;
      recipients = allUsers;
    } else {
      if (recipients === 0) throw err('failed-precondition', 'Bu hedefte bildirim alacak aktif bilet sahibi yok.');
    }
    if ((tgt.type === 'all' || recipients > 1) && data.confirm !== true) {
      throw err('failed-precondition', `${recipients} kişiye gönderilecek; onay gerekli (confirm: true).`);
    }

    // Yinelenen gönderim koruması: istek kimliği (panel üretir) ya da aynı içerik + 10 dk dilimi.
    const key = crypto.createHash('sha256').update(data.requestId
      ? `rid:${uid}:${data.requestId}`
      : JSON.stringify([uid, tgt.type, tgt.id, msgIn.title, msgIn.body, msgIn.kind, Math.floor(now() / 600000)])).digest('hex').slice(0, 32);
    const logRef = col('NotificationLog').doc(key);
    const prev = await logRef.get();
    if (prev.exists) {
      const p = prev.data();
      return { ok: true, duplicate: true, logId: key, recipients: p.recipients, success: p.success ?? 0, failure: p.failure ?? 0, title: p.title, body: p.body, kind: p.kind };
    }
    await rateLimit(uid);
    const adminDoc = await col('User').doc(uid).get();
    const sentByName = adminDoc.exists ? `${adminDoc.data().firstName || ''} ${adminDoc.data().lastName || ''}`.trim() : '';
    try {
      await logRef.create({
        sentBy: uid, sentByName, target: { type: tgt.type, id: tgt.id }, targetLabel: tgt.label, template: msgIn.template, kind: msgIn.kind,
        title: msgIn.title, body: msgIn.body, recipients, status: 'sending', createdAt: Timestamp.fromMillis(now()),
      });
    } catch (e) {
      if (e && (e.code === 6 || String(e.code) === 'already-exists')) return { ok: true, duplicate: true, logId: key, recipients, success: 0, failure: 0, title: msgIn.title, body: msgIn.body, kind: msgIn.kind };
      throw e;
    }

    const eventId = tgt.type === 'event' ? tgt.id : undefined;
    const base = {
      title: msgIn.title, body: msgIn.body, type: msgIn.kind === 'alarm' ? 'alarm' : 'announcement',
      ...(eventId ? { eventId } : {}), ...(tgt.ctx.showId || (tgt.type === 'show' && tgt.id) ? { showId: tgt.ctx.showId || tgt.id } : {}),
    };
    const idPrefix = `ann_${key.slice(0, 16)}`;
    const build = (loud) => buildMessage({ title: msgIn.title, body: msgIn.body, kind: msgIn.kind, eventId, now: now(), loud });
    let result, inApp = 0, withToken = 0, topic = false, inAppSkipped = false, loudCount = 0;

    if (tgt.type === 'all') {
      topic = true;
      if (allUsers <= N.MAX_INAPP_ALL) { // uygulama içi kutu: tüm kullanıcılar
        let last = null;
        for (;;) {
          let q = col('User').orderBy(FieldPath.documentId()).select().limit(500);
          if (last) q = q.startAfter(last);
          const s = await q.get();
          inApp += await writeInApp(s.docs.map((d) => d.id), base, idPrefix);
          if (s.size < 500) break;
          last = s.docs[s.docs.length - 1];
        }
      } else inAppSkipped = true;
      // Konu hedefi tek mesajdır; alıcı tercihi bilinemez -> alarm bile NORMAL kanala gider (sessiz modda sessiz). Sesli alarm yalnız token bazlı hedeflerde.
      try { await messaging.send({ ...build(false), topic: N.TOPIC_ALL }); result = { success: 1, failure: 0, chunks: 1 }; } catch (e) { log.error('topic hata', { code: e && e.code }); result = { success: 0, failure: 1, chunks: 1 }; }
    } else {
      inApp = await writeInApp(tgt.userIds, base, idPrefix);
      const rc = await loadRecipients(tgt.userIds);
      tokenMap = rc.tokens;
      withToken = tokenMap.size;
      result = await pushByPrefs(rc, build, msgIn.kind);
      loudCount = result.loud;
    }
    await logRef.update({ status: 'done', inApp, withToken, topic, inAppSkipped, success: result.success, failure: result.failure, chunks: result.chunks, loudCount, finishedAt: Timestamp.fromMillis(now()) });
    return { ok: true, duplicate: false, logId: key, recipients, withToken, inApp, topic, loudCount, success: result.success, failure: result.failure, title: msgIn.title, body: msgIn.body, kind: msgIn.kind };
  }

  // ---------------------------------------------------------------- otomatik hatırlatma
  const REM = { 24: { minMs: 22 * 3600e3, maxMs: 24 * 3600e3, flag: 'remind24At' }, 2: { minMs: 3600e3, maxMs: 2 * 3600e3, flag: 'remind2At' } };

  async function eventReminders() {
    const t = now();
    const conf = (await col('Config').doc('bildirim').get()).data() || {};
    const enabled = conf.autoReminders !== false; // varsayılan açık
    const stats = { enabled, events: 0, sent24: 0, sent2: 0, failed: 0, users: 0 };
    if (enabled) {
      try {
        const seen = new Map();
        const prefixes = [...new Set([datePrefix(t), datePrefix(t + 24 * 3600e3)])];
        for (const p of prefixes) {
          const s = await col('Event').where('date', '>=', p).where('date', '<', `${p}`).select('showId', 'stageId', 'date').limit(300).get();
          s.docs.forEach((d) => seen.set(d.id, d.data()));
        }
        const ts = await col('Event').where('date', '>=', Timestamp.fromMillis(t)).where('date', '<=', Timestamp.fromMillis(t + 24 * 3600e3)).select('showId', 'stageId', 'date').limit(300).get();
        ts.docs.forEach((d) => seen.set(d.id, d.data()));
        const names = new Map();
        const nameOf = async (c, id) => {
          if (!id) return '';
          const k = `${c}:${id}`;
          if (!names.has(k)) { const d = await col(c).doc(id).get(); names.set(k, d.exists ? d.data().name || '' : ''); }
          return names.get(k);
        };
        for (const [eventId, ev] of seen) {
          const ms = parseEventDateMs(ev.date);
          if (ms == null) continue;
          const delta = ms - t;
          const which = delta > REM[24].minMs && delta <= REM[24].maxMs ? 24 : delta > REM[2].minMs && delta <= REM[2].maxMs ? 2 : null;
          if (!which) continue;
          stats.events += 1;
          try {
            const r = await remindEvent({ eventId, ev, ms, which, oyun: await nameOf('Show', ev.showId), sahne: await nameOf('Stage', ev.stageId), t });
            stats[`sent${which}`] += r.users; stats.users += r.users; stats.failed += r.failed;
          } catch (e) { stats.failed += 1; log.error('eventReminders hata', { eventId, code: e && e.code, message: e && e.message }); }
        }
      } catch (e) { stats.failed += 1; log.error('eventReminders tarama hatası', { code: e && e.code, message: e && e.message }); }
    }
    try {
      await col('System').doc('eventReminders').set({ lastRunAt: Timestamp.fromMillis(t), ...stats });
    } catch (e) { log.error('hatırlatma kalp atışı yazılamadı', { message: e && e.message }); }
    return stats;
  }

  async function remindEvent({ eventId, ev, ms, which, oyun, sahne, t }) {
    const flag = REM[which].flag;
    const snap = await col('Ticket').where('eventId', '==', eventId).select('customerId', 'paymentStatus', 'usedAt', 'remind24At', 'remind2At', 'showName', 'stageName').limit(N.MAX_TICKETS_SCAN).get();
    const byUser = new Map();
    for (const d of snap.docs) {
      const x = d.data();
      if (x[flag] || x.usedAt || INACTIVE.has(x.paymentStatus) || typeof x.customerId !== 'string' || !x.customerId || x.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID) continue;
      if (!byUser.has(x.customerId)) byUser.set(x.customerId, []);
      byUser.get(x.customerId).push(d.ref);
      if (!oyun && x.showName) oyun = x.showName;
      if (!sahne && x.stageName) sahne = x.stageName;
    }
    if (!byUser.size) return { users: 0, failed: 0 };
    const gun = which === 24 ? (dayOf(ms) === dayOf(t) ? 'Bugün' : 'Yarın') : '2 saat sonra';
    const title = which === 24 ? `${gun} seansın var` : 'Seansa 2 saat kaldı';
    const body = clip(`${gun} ${oyun || 'seans'}, ${hhmm(ms)}${sahne ? `, ${sahne}` : ''}.`, N.BODY_MAX);
    const fresh = []; // bildirimi bu çalışmada İLK kez oluşturulan kullanıcılar (create = kilit: eşzamanlı/yeniden çalışmada çift gönderim olmaz)
    const iso = new Date(t).toISOString();
    for (const uid of byUser.keys()) {
      const id = `rem${which}_${eventId}_${uid}`;
      try {
        await col('Notification').doc(id).create({ _id: id, userId: uid, title, body, type: 'reminder', eventId, isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(t) });
        fresh.push(uid);
      } catch (e) { if (!(e && (e.code === 6 || String(e.code) === 'already-exists'))) throw e; }
    }
    let failed = 0;
    if (fresh.length) {
      const tokenMap = await loadTokens(fresh);
      const owners = new Map();
      for (const [u, tk] of tokenMap) owners.set(tk, [...(owners.get(tk) || []), u]);
      const r = await pushTokens([...tokenMap.values()], buildMessage({ title, body, kind: 'normal', eventId, now: t }), owners);
      failed = r.failure;
    }
    // bayrak: bildirimi zaten oluşturulmuş olanlar dahil tüm uygun biletler işaretlenir -> bir sonraki çalışmada hiçbir iş kalmaz
    const refs = [...byUser.values()].flat();
    for (let i = 0; i < refs.length; i += 400) {
      const b = db.batch();
      refs.slice(i, i + 400).forEach((r) => b.update(r, { [flag]: Timestamp.fromMillis(t) }));
      await b.commit();
    }
    return { users: fresh.length, failed };
  }

  return { adminSendNotification, adminNotifyPreview, eventReminders };
}

module.exports = { createNotifier, TEMPLATES, templateList, buildMessage };

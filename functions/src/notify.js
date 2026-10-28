'use strict';
/**
 * Bildirim gönderme ("Sahne kumandası") ve otomatik hatırlatmalar.
 * Firebase Messaging enjekte edilir (testte sahte). FCM gönderimi ücretsizdir; maliyet Firestore okuma/yazmasındadır.
 * Çoklu cihaz: User.fcmTokens (dizi, en çok 5) + eski tekil User.fcmToken birlikte okunur (tekilleştirilir).
 */
const crypto = require('crypto');
const { FieldPath, Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, parseEventDateMs, validateId } = require('./util');
const prefsLib = require('./notify-prefs');

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
function buildMessage({ title, body, kind, eventId, now, loud = false, route }) {
  const data = { kind, route: route || '/notifications' };
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

/** Seans iptal mi? Event.cancelled === true | 'evet' | 'iptal' | 'true' (admin formu metin alanı) ya da Event.status === 'cancelled'. */
function isCancelled(ev) {
  if (!ev) return false;
  if (ev.status === 'cancelled') return true;
  const c = ev.cancelled;
  return c === true || (typeof c === 'string' && ['evet', 'iptal', 'true', 'cancelled'].includes(c.trim().toLowerCase()));
}
const TRMAP = { ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', Ç: 'c', Ğ: 'g', İ: 'i', I: 'i', Ö: 'o', Ş: 's', Ü: 'u' };
/** site/js/util.js slugify ile aynı. */
const slugify = (t) => String(t || '').replace(/[çğıöşüÇĞİIÖŞÜ]/g, (c) => TRMAP[c]).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'detay';
/** Show.duration ("90 dk", "1,5 saat", "2 saat") -> dakika; çözülemezse 120. */
function durationMin(v) {
  const m = /(\d+(?:[.,]\d+)?)/.exec(String(v || ''));
  if (!m) return 120;
  const n = parseFloat(m[1].replace(',', '.'));
  const mins = /saat|h/i.test(String(v)) ? n * 60 : n;
  return mins >= 15 && mins <= 480 ? Math.round(mins) : 120;
}
/** "gg.aa.yyyy ss:dd" (İstanbul). */
const fmtDateTime = (ms) => { const [y, m, d] = dayOf(ms).split('-'); return `${d}.${m}.${y} ${hhmm(ms)}`; };
/** Şablon/girdiden bildirim kategorisi (tercih süzgeci). Sahne kumandası şablonları 'alarm' (tercihe bağlı değil). */
function categoryOf(msgIn, data) {
  if (msgIn.template === 'iptal' || msgIn.template === 'ertelendi') return 'change';
  if (!msgIn.template || msgIn.template === 'genel') {
    const c = data && data.category;
    return c === 'newShows' || c === 'marketing' ? c : 'announcement';
  }
  return 'alarm';
}

function createNotifier({ db, messaging, assertAdmin, now = Date.now, log = console }) {
  const col = (n) => db.collection(n);

  // ---------------------------------------------------------------- ortak
  /** uid -> token ve "sessizde sesli hatırlat" izni veren uid kümesi (yalnız notifPrefs.loudAlarm === true; başka her şey = izin yok). */
  async function loadRecipients(userIds) {
    const tokens = new Map(); // uid -> token DİZİSİ (çoklu cihaz: User.fcmTokens + eski tekil User.fcmToken, tekilleştirilmiş)
    const loud = new Set(); // izinli uid'ler (yalnız token'ı olanlar)
    const prefs = new Map(); // uid -> ham notifPrefs (belge var ve alan map ise; token'sız kullanıcılar dahil)
    for (let i = 0; i < userIds.length; i += 300) {
      const refs = userIds.slice(i, i + 300).map((u) => col('User').doc(u));
      const snaps = await db.getAll(...refs, { fieldMask: ['fcmToken', 'fcmTokens', 'notifPrefs'] });
      snaps.forEach((s, j) => {
        const d = s.exists ? s.data() : {};
        if (d.notifPrefs && typeof d.notifPrefs === 'object') prefs.set(userIds[i + j], d.notifPrefs);
        const list = [...(Array.isArray(d.fcmTokens) ? d.fcmTokens : []), d.fcmToken];
        const tks = [...new Set(list.filter((t) => typeof t === 'string' && t.length > 20))];
        if (tks.length) {
          tokens.set(userIds[i + j], tks);
          if (d.notifPrefs && d.notifPrefs.loudAlarm === true) loud.add(userIds[i + j]);
        }
      });
    }
    return { tokens, loud, prefs };
  }

  /**
   * Tercih süzgeci (N-2). Token'lı alıcıları kategoriye göre eler: kapalı kategori -> 'category', sessiz saat -> 'quiet'.
   * Dönen `rc` aynı şekildedir (tokens/loud/prefs), yalnız gönderilecekler kalır. loudAlarm mantığına dokunmaz.
   */
  function filterByPrefs(rc, category, atMs, opts) {
    const tokens = new Map(), loud = new Set(), suppressed = { category: 0, quiet: 0 };
    for (const [uid, tks] of rc.tokens) {
      const d = prefsLib.decide(rc.prefs.get(uid), category, atMs, opts);
      if (!d.send) { suppressed[d.reason] += 1; continue; }
      tokens.set(uid, tks);
      if (rc.loud.has(uid)) loud.add(uid);
    }
    return { rc: { tokens, loud, prefs: rc.prefs }, suppressed };
  }

  /** Uygulama içi kutu alıcıları: kapalı kategori kutuya da yazılmaz — işlemsel `change` hariç (iptal/erteleme kutuda hep görünür). */
  function inboxUsers(userIds, rc, category) {
    if (category === 'change') return userIds;
    return userIds.filter((u) => prefsLib.categoryEnabled(rc.prefs.get(u), category));
  }

  /** Önizleme özeti: kişi listesi YOK, yalnız kategori bazlı sayılar. */
  function prefsSummary(userIds, rc, category) {
    return prefsLib.summarize(userIds.map((u) => rc.prefs.get(u)), category, now());
  }
  async function loadTokens(userIds) { return (await loadRecipients(userIds)).tokens; }

  /**
   * Token bazlı gönderim. Alarm türünde alıcılar tercihe göre ikiye bölünür (izinli -> alarm kanalı, diğerleri -> normal kanal):
   * iki ayrı multicast. Maliyet: FCM ücretsiz; çağrı sayısı en çok iki katına çıkar (500'lük parçalar her grup için ayrı).
   */
  async function pushByPrefs({ tokens: tokenMap, loud }, build, kind) {
    const group = (uids) => {
      const owners = new Map();
      for (const u of uids) for (const tk of tokenMap.get(u)) owners.set(tk, [...(owners.get(tk) || []), u]);
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
            await db.runTransaction(async (tx) => {
              const d = await tx.get(ref);
              if (!d.exists) return;
              const u = d.data(), patch = {};
              if (u.fcmToken === tk) patch.fcmToken = '';
              if (Array.isArray(u.fcmTokens) && u.fcmTokens.includes(tk)) patch.fcmTokens = u.fcmTokens.filter((x) => x !== tk);
              if (Object.keys(patch).length) tx.update(ref, patch);
            });
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
  /** Şablon henüz seçilmediyse isteğin kategorisi (serbest mesaj: announcement | newShows | marketing). */
  function requestedCategory(data) {
    const t = data && data.template;
    if (t === 'iptal' || t === 'ertelendi') return 'change';
    if (t && t !== 'genel') return 'alarm';
    return categoryOf({ template: t || null }, data);
  }

  /** Gönderimden ÖNCE: kaç kişiye ulaşılır + şablon listesi + üretilmiş metin önizlemesi. Veri maliyeti gönderimle aynı okumalar. */
  async function adminNotifyPreview(uid, data) {
    await assertAdmin(uid);
    data = data || {};
    const tgt = await resolveTarget(data.target);
    let recipients, withToken, topic = false, loudAlarm = null, prefs = null, rcPrev = null;
    if (tgt.type === 'all') {
      topic = true;
      const [users, tok] = await Promise.all([
        col('User').count().get(), col('User').where('fcmToken', '>', '').count().get(),
      ]);
      recipients = users.data().count; withToken = tok.data().count;
    } else {
      recipients = tgt.userIds.length;
      const rc = await loadRecipients(tgt.userIds);
      rcPrev = rc;
      withToken = rc.tokens.size;
      loudAlarm = { optedIn: rc.loud.size, of: withToken }; // "X kişiden Y'si sessizde sesli hatırlatmayı açtı" (yalnız alarm türünde anlamlı)
      prefs = prefsSummary(tgt.userIds, rc, requestedCategory(data)); // "X kişiden Y'si bu kategoriyi kapattı" (kişi listesi YOK)
    }
    let preview = null, blocked = null;
    if (data.template || data.title) {
      try { preview = compose(data, tgt, true); if (rcPrev) prefs = prefsSummary(tgt.userIds, rcPrev, categoryOf(preview, data)); } catch (e) { blocked = e.message; }
    }
    return {
      target: { type: tgt.type, id: tgt.id, label: tgt.label }, recipients, withToken, loudAlarm, prefs, tickets: tgt.tickets ?? null, topic,
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
    if (data.category != null && !['announcement', 'newShows', 'marketing'].includes(data.category)) throw err('invalid-argument', 'Geçersiz bildirim kategorisi.');
    const category = categoryOf(msgIn, data);
    if (tgt.type === 'all' && (category === 'newShows' || category === 'marketing')) {
      throw err('failed-precondition', 'Yeni oyun / pazarlama bildirimleri kullanıcı tercihine bağlıdır; "Tüm kullanıcılar" (konu) hedefiyle gönderilemez. Bir oyun ya da seans hedefi seçin.');
    }

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
    let result, inApp = 0, withToken = 0, topic = false, inAppSkipped = false, loudCount = 0, suppressed = { category: 0, quiet: 0 };

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
      const rc0 = await loadRecipients(tgt.userIds);
      inApp = await writeInApp(inboxUsers(tgt.userIds, rc0, category), base, idPrefix);
      const f = filterByPrefs(rc0, category, now()); // kapalı kategori / sessiz saat: push gitmez (sahne kumandası ve duyurular muaf)
      suppressed = f.suppressed;
      tokenMap = f.rc.tokens;
      withToken = tokenMap.size;
      result = await pushByPrefs(f.rc, build, msgIn.kind);
      loudCount = result.loud;
    }
    await logRef.update({ status: 'done', category, inApp, withToken, topic, inAppSkipped, success: result.success, failure: result.failure, chunks: result.chunks, loudCount, suppressed, finishedAt: Timestamp.fromMillis(now()) });
    return { ok: true, duplicate: false, logId: key, recipients, withToken, inApp, topic, loudCount, suppressed, success: result.success, failure: result.failure, title: msgIn.title, body: msgIn.body, kind: msgIn.kind };
  }

  // ---------------------------------------------------------------- otomatik hatırlatma + teşekkür
  const REM = { 24: { minMs: 22 * 3600e3, maxMs: 24 * 3600e3, flag: 'remind24At' }, 2: { minMs: 3600e3, maxMs: 2 * 3600e3, flag: 'remind2At' } };
  const EV_FIELDS = ['showId', 'stageId', 'date', 'cancelled', 'status'];
  const isExists = (e) => e && (e.code === 6 || String(e.code) === 'already-exists');

  /** Belirtilen aralıkta (İstanbul gün önekleri + Timestamp aralığı) başlayan seanslar: id -> veri. */
  async function eventsBetween(fromMs, toMs) {
    const seen = new Map();
    const prefixes = [...new Set([datePrefix(fromMs), datePrefix(toMs)])];
    for (const p of prefixes) {
      const s = await col('Event').where('date', '>=', p).where('date', '<', `${p}`).select(...EV_FIELDS).limit(300).get();
      s.docs.forEach((d) => seen.set(d.id, d.data()));
    }
    const ts = await col('Event').where('date', '>=', Timestamp.fromMillis(fromMs)).where('date', '<=', Timestamp.fromMillis(toMs)).select(...EV_FIELDS).limit(300).get();
    ts.docs.forEach((d) => seen.set(d.id, d.data()));
    return seen;
  }

  async function eventReminders() {
    const t = now();
    const conf = (await col('Config').doc('bildirim').get()).data() || {};
    const enabled = conf.autoReminders !== false; // varsayılan açık
    const stats = { enabled, events: 0, sent24: 0, sent2: 0, failed: 0, users: 0, thanked: 0, thankEvents: 0, alarm2h: conf.alarm2h === true };
    const names = new Map();
    const nameOf = async (c, id) => {
      if (!id) return '';
      const k = `${c}:${id}`;
      if (!names.has(k)) { const d = await col(c).doc(id).get(); names.set(k, d.exists ? d.data().name || '' : ''); }
      return names.get(k);
    };
    if (enabled) {
      try {
        const seen = await eventsBetween(t, t + 24 * 3600e3);
        for (const [eventId, ev] of seen) {
          if (isCancelled(ev)) continue; // iptal edilmiş seansa hatırlatma gitmez
          const ms = parseEventDateMs(ev.date);
          if (ms == null) continue;
          const delta = ms - t;
          const which = delta > REM[24].minMs && delta <= REM[24].maxMs ? 24 : delta > REM[2].minMs && delta <= REM[2].maxMs ? 2 : null;
          if (!which) continue;
          stats.events += 1;
          try {
            const r = await remindEvent({ eventId, ev, ms, which, oyun: await nameOf('Show', ev.showId), sahne: await nameOf('Stage', ev.stageId), t, conf });
            stats[`sent${which}`] += r.users; stats.users += r.users; stats.failed += r.failed;
          } catch (e) { stats.failed += 1; log.error('eventReminders hata', { eventId, code: e && e.code, message: e && e.message }); }
        }
      } catch (e) { stats.failed += 1; log.error('eventReminders tarama hatası', { code: e && e.code, message: e && e.message }); }
    }
    // N-1b: seans sonrası teşekkür + yorum daveti (yeni zamanlanmış iş AÇILMAZ; bu çalışmaya eklidir). Hatırlatma anahtarından bağımsız: Config/bildirim.thankYou=false ile kapanır.
    if (conf.thankYou !== false) {
      try {
        const r = await thankYouRun(t, conf);
        stats.thanked = r.sent; stats.thankEvents = r.events; stats.failed += r.failed;
      } catch (e) { stats.failed += 1; log.error('thankYouRun hatası', { code: e && e.code, message: e && e.message }); }
    }
    try {
      await col('System').doc('eventReminders').set({ lastRunAt: Timestamp.fromMillis(t), ...stats });
    } catch (e) { log.error('hatırlatma kalp atışı yazılamadı', { message: e && e.message }); }
    return stats;
  }

  async function remindEvent({ eventId, ev, ms, which, oyun, sahne, t, conf = {} }) {
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
    const rc = await loadRecipients([...byUser.keys()]);
    const fresh = []; // bildirimi bu çalışmada İLK kez oluşturulan kullanıcılar (create = kilit: eşzamanlı/yeniden çalışmada çift gönderim olmaz)
    const deferred = new Set(); // sessiz saatteki kullanıcılar: kilit/bayrak YOK -> bir sonraki çalışma (15 dk sonra) yeniden dener
    const iso = new Date(t).toISOString();
    for (const uid of byUser.keys()) {
      const d = prefsLib.decide(rc.prefs.get(uid), 'reminder', t, { eventMs: ms });
      if (d.reason === 'quiet') { deferred.add(uid); continue; }
      if (d.reason === 'category') continue; // hatırlatmayı kapatmış: kutu + push yok; bilet yine işaretlenir (yeniden değerlendirilmez)
      const id = `rem${which}_${eventId}_${uid}`;
      try {
        await col('Notification').doc(id).create({ _id: id, userId: uid, title, body, type: 'reminder', eventId, isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(t) });
        fresh.push(uid);
      } catch (e) { if (!isExists(e)) throw e; }
    }
    let failed = 0;
    if (fresh.length) {
      // N-1c: 2 saatlik hatırlatma Config/bildirim.alarm2h=true iken `alarm` türünde gider: loudAlarm açık olanlar alarm kanalından, diğerleri normal kanaldan.
      const kind = which === 2 && conf.alarm2h === true ? 'alarm' : 'normal';
      const sub = { tokens: new Map(), loud: new Set(), prefs: rc.prefs };
      for (const u of fresh) if (rc.tokens.has(u)) { sub.tokens.set(u, rc.tokens.get(u)); if (rc.loud.has(u)) sub.loud.add(u); }
      const r = await pushByPrefs(sub, (loud) => buildMessage({ title, body, kind, eventId, now: t, loud }), kind);
      failed = r.failure;
    }
    // bayrak: bildirimi zaten oluşturulmuş olanlar dahil tüm uygun biletler işaretlenir (sessiz saatte ertelenenler HARİÇ) -> bir sonraki çalışmada iş kalmaz
    const refs = [...byUser].filter(([u]) => !deferred.has(u)).flatMap(([, r]) => r);
    for (let i = 0; i < refs.length; i += 400) {
      const b = db.batch();
      refs.slice(i, i + 400).forEach((r) => b.update(r, { [flag]: Timestamp.fromMillis(t) }));
      await b.commit();
    }
    return { users: fresh.length, failed };
  }

  // ---------------------------------------------------------------- N-1b: seans sonrası teşekkür + yorum daveti
  const THANK = { MIN_AFTER_MS: 3600e3, MAX_AFTER_MS: 12 * 3600e3 };

  async function thankYouRun(t, conf = {}) {
    const out = { events: 0, sent: 0, failed: 0 };
    const seen = await eventsBetween(t - 24 * 3600e3, t);
    for (const [eventId, ev] of seen) {
      if (isCancelled(ev)) continue;
      const ms = parseEventDateMs(ev.date);
      if (ms == null || !ev.showId) continue;
      const sh = await col('Show').doc(ev.showId).get();
      if (!sh.exists) continue;
      const age = t - (ms + durationMin(sh.data().duration) * 60000);
      if (age < THANK.MIN_AFTER_MS || age > THANK.MAX_AFTER_MS) continue; // yalnız "bitti" yaşı 1–12 saat olan seanslar
      const doneRef = col('System').doc(`thankYou_${eventId}`);
      if ((await doneRef.get()).exists) continue;
      out.events += 1;
      try {
        const r = await thankEvent({ eventId, showId: ev.showId, oyun: sh.data().name || '', t, conf, doneRef });
        out.sent += r.users; out.failed += r.failed;
      } catch (e) { out.failed += 1; log.error('thankYou hata', { eventId, code: e && e.code, message: e && e.message }); }
    }
    return out;
  }

  async function thankEvent({ eventId, showId, oyun, t, conf, doneRef }) {
    const snap = await col('Ticket').where('eventId', '==', eventId).select('customerId', 'paymentStatus', 'usedAt', 'thankedAt').limit(N.MAX_TICKETS_SCAN).get();
    const byUser = new Map();
    for (const d of snap.docs) {
      const x = d.data();
      if (x.thankedAt || INACTIVE.has(x.paymentStatus) || typeof x.customerId !== 'string' || !x.customerId || x.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID) continue;
      if (!x.usedAt && conf.thankYouAll !== true) continue; // varsayılan: YALNIZ kapıdan geçmiş (usedAt dolu); thankYouAll=true -> geçerli rezervasyonlar da
      if (!byUser.has(x.customerId)) byUser.set(x.customerId, []);
      byUser.get(x.customerId).push(d.ref);
    }
    const finish = async () => { await doneRef.set({ eventId, at: Timestamp.fromMillis(t) }); };
    if (!byUser.size) { await finish(); return { users: 0, failed: 0 }; }
    const rc = await loadRecipients([...byUser.keys()]);
    const title = clip(`${oyun || 'Oyun'} nasıldı?`, N.TITLE_MAX);
    const body = 'İzlenimini yazarak diğer seyircilere yardımcı olabilirsin.';
    const route = `/show/${slugify(oyun)}-${showId}?yorum=1`; // mobil rota (push_payload.dart beyaz listesi); web karşılığı /oyun/<slug>-<id>?yorum=1
    const fresh = [], deferred = new Set();
    const iso = new Date(t).toISOString();
    for (const uid of byUser.keys()) {
      const d = prefsLib.decide(rc.prefs.get(uid), 'thankYou', t);
      if (d.reason === 'quiet') { deferred.add(uid); continue; } // sessiz saat: bayrak/kilit yok, 15 dk sonra yeniden denenir (en çok 12 saat)
      if (d.reason === 'category') continue;
      const id = `thank_${eventId}_${uid}`;
      try {
        await col('Notification').doc(id).create({ _id: id, userId: uid, title, body, type: 'announcement', eventId, showId, isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(t) });
        fresh.push(uid);
      } catch (e) { if (!isExists(e)) throw e; }
    }
    let failed = 0;
    if (fresh.length) {
      const sub = { tokens: new Map(), loud: new Set(), prefs: rc.prefs };
      for (const u of fresh) if (rc.tokens.has(u)) sub.tokens.set(u, rc.tokens.get(u));
      const r = await pushByPrefs(sub, () => buildMessage({ title, body, kind: 'normal', eventId, now: t, route }), 'normal');
      failed = r.failure;
    }
    const refs = [...byUser].filter(([u]) => !deferred.has(u)).flatMap(([, r]) => r);
    for (let i = 0; i < refs.length; i += 400) {
      const b = db.batch();
      refs.slice(i, i + 400).forEach((r) => b.update(r, { thankedAt: Timestamp.fromMillis(t) }));
      await b.commit();
    }
    if (!deferred.size) await finish();
    return { users: fresh.length, failed };
  }

  // ---------------------------------------------------------------- N-1a: seans iptal / erteleme (Firestore tetikleyici: onDocumentUpdated('Event/{id}'))
  /**
   * Event değişti. İptal (cancelled/status) ya da ileri tarihe saat/gün değişikliği olduysa o seansın AKTİF bilet sahiplerine bildirim.
   * İdempotent: kullanıcı başına `chg_iptal_<event>_<uid>` / `chg_move_<event>_<yeniMs>_<uid>` kutu belgesi create() kilidi + tek `NotificationLog` belgesi.
   * Tetikleyici iki kez çalışsa / yeniden denense bile kimse iki kez bildirim almaz. Kişisel veri sızmaz (günlükte yalnız sayılar).
   */
  async function eventChanged(eventId, before, after) {
    if (!before || !after) return { skipped: 'no-data' };
    const t = now();
    const wasC = isCancelled(before), isC = isCancelled(after);
    const b = parseEventDateMs(before.date), a = parseEventDateMs(after.date);
    let tpl = null, suffix = '';
    if (!wasC && isC) { tpl = 'iptal'; suffix = 'iptal'; } else if (!isC && b != null && a != null && a !== b && b > t - 3600e3 && a > t) { tpl = 'ertelendi'; suffix = `move_${a}`; }
    if (!tpl) return { skipped: 'no-change' };

    const ctx = await eventContext(eventId);
    const a2 = await activeCustomers('eventId', eventId);
    const key = `chg_${suffix}_${eventId}`;
    const logRef = col('NotificationLog').doc(key);
    try {
      await logRef.create({
        sentBy: 'system', sentByName: 'Otomatik', auto: true, target: { type: 'event', id: eventId }, targetLabel: `Seans: ${ctx.oyun}`, template: tpl, kind: 'normal', category: 'change',
        title: `${ctx.oyun || 'Seans'} ${tpl === 'iptal' ? 'iptal edildi' : 'ertelendi'}`, body: '', recipients: a2.ids.length, status: 'sending', createdAt: Timestamp.fromMillis(t),
      });
    } catch (e) {
      if (!isExists(e)) throw e;
      if ((await logRef.get()).data().status === 'done') return { duplicate: true, logId: key };
    }
    const when = ctx.ms != null ? fmtDateTime(ctx.ms) : '';
    const oyun = clip(ctx.oyun || 'Seans', 40);
    const title = clip(tpl === 'iptal' ? `${oyun} seansı iptal edildi` : `${oyun} seansı ertelendi`, N.TITLE_MAX);
    const body = clip(tpl === 'iptal'
      ? `${when ? `${when} tarihli ` : ''}seans iptal edildi${ctx.sahne ? ` (${ctx.sahne})` : ''}. Ayrıntı için bizimle iletişime geçebilirsin.`
      : `Yeni tarih ve saat: ${fmtDateTime(a)}${ctx.sahne ? ` · ${ctx.sahne}` : ''}${b != null ? ` (önceki: ${fmtDateTime(b)})` : ''}.`, N.BODY_MAX);
    const iso = new Date(t).toISOString();
    const fresh = [];
    for (const uid of a2.ids) {
      const id = `chg_${suffix}_${eventId}_${uid}`;
      try {
        await col('Notification').doc(id).create({ _id: id, userId: uid, title, body, type: 'announcement', eventId, ...(ctx.showId ? { showId: ctx.showId } : {}), isRead: false, _createdAt: iso, createdAt: Timestamp.fromMillis(t) });
        fresh.push(uid);
      } catch (e) { if (!isExists(e)) throw e; }
    }
    let result = { success: 0, failure: 0, chunks: 0, loud: 0 }, withToken = 0, suppressed = { category: 0, quiet: 0 };
    if (fresh.length) {
      const f = filterByPrefs(await loadRecipients(fresh), 'change', t); // `changes` kapalıysa push yok (kutu yazıldı); sessiz saatten MUAF
      suppressed = f.suppressed; withToken = f.rc.tokens.size;
      result = await pushByPrefs(f.rc, () => buildMessage({ title, body, kind: 'normal', eventId, now: t }), 'normal');
    }
    await logRef.update({ status: 'done', body, recipients: a2.ids.length, newlyNotified: fresh.length, inApp: fresh.length, withToken, success: result.success, failure: result.failure, chunks: result.chunks, suppressed, finishedAt: Timestamp.fromMillis(t) });
    return { ok: true, template: tpl, logId: key, recipients: a2.ids.length, newlyNotified: fresh.length, withToken, success: result.success, failure: result.failure, suppressed };
  }

  // Ekip yöneticisi akışı (src/team.js) aynı hedef/şablon/gönderim mantığını yeniden kullanır; yetki kapsamı ORADA denetlenir.
  const internals = { resolveTarget, compose, activeCustomers, loadRecipients, pushByPrefs, writeInApp, filterByPrefs, inboxUsers, prefsSummary, categoryOf };
  return { adminSendNotification, adminNotifyPreview, eventReminders, eventChanged, internals };
}

module.exports = { createNotifier, TEMPLATES, templateList, buildMessage, isCancelled, categoryOf, durationMin, slugify };

'use strict';
/**
 * Görüntülenme sayacı (trackView) ve yönetim istatistikleri (adminStats).
 * Gizlilik: IP/UA/çerez SAKLANMAZ; yalnız toplu sayaç (Stats/views/{days,months}/{tarih}). Maliyet: docs/BILDIRIM-ISTATISTIK.md
 */
const { FieldValue, FieldPath, Timestamp } = require('firebase-admin/firestore');
const cfg = require('./config');
const { err, parseEventDateMs } = require('./util');

const KINDS = { show: 'Show', player: 'Player', stage: 'Stage', team: 'Team' };
const ID_RE = /^[A-Za-z0-9_-]{1,64}$/;
const BOT_RE = /bot|crawl|spider|slurp|facebookexternalhit|preview|headless|lighthouse|pingdom|uptime|monitor|curl|wget|python-requests|httpclient|axios|go-http|java\/|node-fetch|scrapy|ahrefs|semrush|mj12|bytespider|gptbot|claudebot|petalbot|yandex|baidu|duckduck/i;
const MONTH_RE = /^\d{4}-(0[1-9]|1[0-2])$/;

const ist = (ms) => new Date(ms + cfg.TZ_OFFSET_MIN * 60000); // UTC alanlarıyla İstanbul saati
const dayKey = (ms) => ist(ms).toISOString().slice(0, 10);
const monthKey = (ms) => ist(ms).toISOString().slice(0, 7);
/** 'yyyy-MM' -> o ayın İstanbul başlangıcı (epoch ms). */
const monthStartMs = (mk) => Date.UTC(+mk.slice(0, 4), +mk.slice(5, 7) - 1, 1) - cfg.TZ_OFFSET_MIN * 60000;
const addMonths = (mk, n) => { const d = new Date(Date.UTC(+mk.slice(0, 4), +mk.slice(5, 7) - 1 + n, 1)); return d.toISOString().slice(0, 7); };
const isoOf = (ms) => new Date(ms).toISOString();

function createStats({ db, now = Date.now, log = console }) {
  // ---------------------------------------------------------------- trackView
  const RATE = { windowMs: 60 * 1000, ip: 30, target: 6, targetAll: 120, all: 600 };
  const rate = new Map(); // instance belleği: anahtar -> {start,count}
  const known = new Map(); // `${kind}:${id}` -> {ok, until}
  function hit(key, max) {
    const t = now();
    if (rate.size > 5000) { for (const [k, v] of rate) if (t - v.start >= RATE.windowMs) rate.delete(k); if (rate.size > 5000) rate.clear(); }
    let e = rate.get(key);
    if (!e || t - e.start >= RATE.windowMs) { e = { start: t, count: 0 }; rate.set(key, e); }
    e.count += 1;
    return e.count <= max;
  }
  const grate = new Map(); // IP'den bağımsız tavanlar (ayrı harita: ip döndürerek şişirilip sıfırlanamaz)
  function ghit(key, max) {
    const t = now();
    let e = grate.get(key);
    if (!e || t - e.start >= RATE.windowMs) { e = { start: t, count: 0 }; grate.set(key, e); }
    e.count += 1;
    return e.count <= max;
  }
  async function exists(kind, id) {
    const key = `${kind}:${id}`, t = now(), c = known.get(key);
    if (c && c.until > t) return c.ok;
    if (known.size > 5000) known.clear();
    const ok = (await db.collection(KINDS[kind]).doc(id).get()).exists;
    known.set(key, { ok, until: t + (ok ? 3600e3 : 300e3) });
    return ok;
  }

  /**
   * @returns {{status:number, writes?:number}} 204 = sessizce yok sayıldı/sayıldı (yanıt gövdesi yok), 400/405 = istemci hatası.
   * Çerez/IP/UA saklanmaz. Sayaç: gün + ay belgesi (tek batch, 2 yazma).
   */
  async function trackView({ method, body, ip, ua, origin, allowedOrigins = [] }) {
    if (method !== 'POST') return { status: 405 };
    let b = Buffer.isBuffer(body) ? body.toString('utf8') : body;
    if (typeof b === 'string') { try { b = JSON.parse(b); } catch { return { status: 400 }; } }
    if (!b || typeof b !== 'object' || Array.isArray(b)) return { status: 400 };
    const kind = b.k, id = b.id;
    if (typeof kind !== 'string' || !Object.prototype.hasOwnProperty.call(KINDS, kind) || typeof id !== 'string' || !ID_RE.test(id)) return { status: 400 };
    // Sessiz ret (204): hangi kuralın tetiklendiği sızdırılmaz.
    if (!origin || !allowedOrigins.some((o) => (o instanceof RegExp ? o.test(origin) : o === origin))) return { status: 204, ignored: 'origin' };
    if (!ua || BOT_RE.test(String(ua).slice(0, 300))) return { status: 204, ignored: 'bot' };
    const who = String(ip || 'unknown');
    if (!hit(`ip:${who}`, RATE.ip) || !hit(`t:${who}:${kind}:${id}`, RATE.target)) return { status: 204, ignored: 'rate' };
    if (!(await exists(kind, id))) return { status: 204, ignored: 'unknown' };
    // S-1: X-Forwarded-For istemci tarafından döndürülebilir (req.ip sahtelenebilir; IP döndürerek yukarıdaki sınırlar aşılır) ->
    // IP'den BAĞIMSIZ sert tavanlar: hedef başına ve instance başına dakikalık toplam. Yalnız VAR OLAN hedefler için sayılır
    // (anahtar sayısı belge sayısıyla sınırlı). Normal trafik (küçük tiyatro sitesi) bunların çok altındadır.
    if (!ghit(`${kind}:${id}`, RATE.targetAll) || !ghit('*', RATE.all)) return { status: 204, ignored: 'rate' };
    const t = now();
    const inc = { total: FieldValue.increment(1), [`${kind}_total`]: FieldValue.increment(1), [`${kind}_${id}`]: FieldValue.increment(1) };
    const batch = db.batch();
    batch.set(db.collection('Stats').doc('views').collection('days').doc(dayKey(t)), inc, { merge: true });
    batch.set(db.collection('Stats').doc('views').collection('months').doc(monthKey(t)), inc, { merge: true });
    await batch.commit();
    return { status: 204, writes: 2 };
  }

  // ---------------------------------------------------------------- adminStats
  const cnt = async (q) => (await q.count().get()).data().count;
  const T = () => db.collection('Ticket');

  /** Tüm koleksiyonu sayfalayarak oku (üst sınırlı). */
  async function readAll(col, fields, cap) {
    const out = [];
    let last = null;
    while (out.length < cap) {
      let q = db.collection(col).orderBy(FieldPath.documentId()).limit(300);
      if (fields) q = q.select(...fields);
      if (last) q = q.startAfter(last);
      const s = await q.get();
      s.docs.forEach((d) => out.push({ id: d.id, ...d.data() }));
      if (s.size < 300) break;
      last = s.docs[s.docs.length - 1];
    }
    return out.slice(0, cap);
  }

  function seatTally(seats) {
    let total = 0, sold = 0, held = 0, blocked = 0;
    for (const s of Object.values(seats || {})) {
      if (!s) continue;
      if (s.status === 'blocked' || (s.status === 'sold' && s.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID)) { blocked += 1; continue; }
      total += 1;
      if (s.status === 'sold') sold += 1; else if (s.status === 'reserved') held += 1;
    }
    return { total, sold, held, blocked };
  }

  async function adminStats(assertAdmin, uid, data) {
    await assertAdmin(uid);
    const t = now();
    const month = data && data.month != null ? data.month : monthKey(t);
    if (typeof month !== 'string' || !MONTH_RE.test(month)) throw err('invalid-argument', 'Geçersiz ay.');
    const m0 = monthStartMs(month), m1 = monthStartMs(addMonths(month, 1));
    const months = Array.from({ length: 12 }, (_, i) => addMonths(month, i - 11));
    const vcol = db.collection('Stats').doc('views');

    // --- görüntülenme belgeleri: 12 ay + seçili ayın günleri
    const [monthSnaps, daySnap] = await Promise.all([
      db.getAll(...months.map((mk) => vcol.collection('months').doc(mk))),
      vcol.collection('days').where(FieldPath.documentId(), '>=', `${month}-01`).where(FieldPath.documentId(), '<=', `${month}-31`).get(),
    ]);
    const monthData = monthSnaps.map((s) => (s.exists ? s.data() : {}));
    const cur = monthData[11];
    const pick = (obj, kind) => Object.entries(obj).filter(([k]) => k.startsWith(`${kind}_`) && k !== `${kind}_total`).map(([k, v]) => [k.slice(kind.length + 1), v]);
    const days = daySnap.docs.map((d) => ({ day: d.id, views: d.data().total || 0 })).sort((a, b) => (a.day < b.day ? -1 : 1));

    // --- içerik: oyunlar, sahneler, seanslar
    const [shows, stages, events] = await Promise.all([
      readAll('Show', ['name', 'eventsId'], 1000), readAll('Stage', ['name', 'capacity'], 1000), readAll('Event', ['showId', 'stageId', 'date', 'seats'], 2000),
    ]);
    const showName = new Map(shows.map((s) => [s.id, s.name || s.id]));
    const stageName = new Map(stages.map((s) => [s.id, s.name || s.id]));
    const evShow = new Map(); // Event.showId tek doğruluk kaynağı; boşsa Show.eventsId yedek
    for (const s of shows) for (const e of s.eventsId || []) if (!evShow.has(e)) evShow.set(e, s.id);

    const perShow = new Map(), perStage = new Map();
    const bump = (map, id) => { if (!map.has(id)) map.set(id, { id, upcoming: 0, sessions: 0, seatsSold: 0, seatsTotal: 0 }); return map.get(id); };
    let upcoming = 0;
    const upcomingList = [];
    const activeShowIds = new Set();
    for (const e of events) {
      const ms = parseEventDateMs(e.date);
      const showId = e.showId || evShow.get(e.id) || '';
      const tally = seatTally(e.seats);
      const isUp = ms != null && ms >= t;
      if (isUp) { upcoming += 1; if (showId) activeShowIds.add(showId); }
      for (const [map, id] of [[perShow, showId], [perStage, e.stageId || '']]) {
        if (!id) continue;
        const r = bump(map, id);
        r.sessions += 1; r.seatsSold += tally.sold; r.seatsTotal += tally.total; if (isUp) r.upcoming += 1;
      }
      if (isUp || (ms != null && ms >= t - 7 * 864e5)) {
        upcomingList.push({
          eventId: e.id, showId, show: showName.get(showId) || '', stageId: e.stageId || '', stage: stageName.get(e.stageId) || '',
          date: e.date && e.date.toDate ? e.date.toDate().toISOString() : String(e.date || ''), ms,
          seatsSold: tally.sold, seatsHeld: tally.held, seatsTotal: tally.total,
          occupancy: tally.total > 0 ? Math.round((tally.sold / tally.total) * 1000) / 1000 : null,
        });
      }
    }
    upcomingList.sort((a, b) => (a.ms || 0) - (b.ms || 0));

    // --- bilet sayaçları (count aggregation; iptaller HARİÇ aktif sayılar)
    const monthFrom = isoOf(m0), monthTo = isoOf(m1);
    const method = (m) => T().where('orderMethod', '==', m);
    const [venueMonth, venueMonthCx, venueTot, venueTotCx, freeMonth, freeMonthCx, freeTot, freeTotCx, cardTot, allTickets, cancelledAll, noShowAll, checkedIn] = await Promise.all([
      cnt(method('venue').where('_createdAt', '>=', monthFrom).where('_createdAt', '<', monthTo)),
      cnt(method('venue').where('paymentStatus', '==', 'cancelled').where('_createdAt', '>=', monthFrom).where('_createdAt', '<', monthTo)),
      cnt(method('venue')), cnt(method('venue').where('paymentStatus', '==', 'cancelled')),
      cnt(method('free').where('_createdAt', '>=', monthFrom).where('_createdAt', '<', monthTo)),
      cnt(method('free').where('paymentStatus', '==', 'cancelled').where('_createdAt', '>=', monthFrom).where('_createdAt', '<', monthTo)),
      cnt(method('free')), cnt(method('free').where('paymentStatus', '==', 'cancelled')),
      cnt(method('card')), cnt(T()),
      cnt(T().where('paymentStatus', '==', 'cancelled')), cnt(T().where('paymentStatus', '==', 'no_show')),
      cnt(T().where('usedAt', '>=', Timestamp.fromMillis(0))),
    ]);
    const activeAll = Math.max(0, allTickets - cancelledAll);
    const ratio = (a, b) => (b > 0 ? Math.round((a / b) * 1000) / 1000 : null);

    // --- oyun tablosu: görüntülenme + bilet (en çok görüntülenen/yaklaşan ilk 20 oyun için count sorguları)
    const viewsByShow = new Map(pick(cur, 'show'));
    const showIds = new Set([...viewsByShow.keys(), ...perShow.keys()]);
    const ranked = [...showIds].map((id) => ({ id, views: viewsByShow.get(id) || 0, ...(perShow.get(id) || { upcoming: 0, sessions: 0, seatsSold: 0, seatsTotal: 0 }) }))
      .sort((a, b) => b.views - a.views || b.upcoming - a.upcoming || b.seatsSold - a.seatsSold);
    const top = ranked.slice(0, 20);
    await Promise.all(top.map(async (r) => {
      const [tot, cx, mo] = await Promise.all([
        cnt(T().where('showId', '==', r.id)), cnt(T().where('showId', '==', r.id).where('paymentStatus', '==', 'cancelled')),
        cnt(T().where('showId', '==', r.id).where('_createdAt', '>=', monthFrom).where('_createdAt', '<', monthTo)),
      ]);
      r.tickets = Math.max(0, tot - cx); r.ticketsMonth = mo;
    }));
    const showRows = top.map((r) => ({
      showId: r.id, name: showName.get(r.id) || r.id, views: r.views, tickets: r.tickets, ticketsMonth: r.ticketsMonth,
      conversion: ratio(r.ticketsMonth, r.views), sessions: r.sessions, upcoming: r.upcoming,
      seatsSold: r.seatsSold, seatsTotal: r.seatsTotal, occupancy: ratio(r.seatsSold, r.seatsTotal),
    }));

    // --- aylık trend: toplam + oyun başına (en çok görüntülenen ilk 12 oyun; tamamı için 12 ay)
    const seriesIds = new Map();
    monthData.forEach((d) => pick(d, 'show').forEach(([id, v]) => seriesIds.set(id, (seriesIds.get(id) || 0) + v)));
    const topSeries = [...seriesIds.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12).map(([id]) => id);
    const trend = {
      months,
      total: monthData.map((d) => d.total || 0),
      shows: topSeries.map((id) => ({ showId: id, name: showName.get(id) || id, values: monthData.map((d) => d[`show_${id}`] || 0) })),
    };
    const viewsTotal = cur.total || 0, showViews = cur.show_total || 0;

    const venueRows = [...perStage.values()].map((r) => ({
      stageId: r.id, name: stageName.get(r.id) || r.id, views: (pick(cur, 'stage').find(([id]) => id === r.id) || [0, 0])[1],
      sessions: r.sessions, upcoming: r.upcoming, seatsSold: r.seatsSold, seatsTotal: r.seatsTotal, occupancy: ratio(r.seatsSold, r.seatsTotal),
    })).sort((a, b) => (b.seatsSold - a.seatsSold) || (b.views - a.views)).slice(0, 20);
    const named = (kind, names) => pick(cur, kind).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([id, v]) => ({ id, name: names.get(id) || id, views: v }));

    return {
      generatedAt: t, month,
      kpi: {
        viewsMonth: viewsTotal, showViewsMonth: showViews,
        reservations: { month: Math.max(0, venueMonth - venueMonthCx), total: Math.max(0, venueTot - venueTotCx) },
        freeTickets: { month: Math.max(0, freeMonth - freeMonthCx), total: Math.max(0, freeTot - freeTotCx) },
        cardTickets: { total: cardTot },
        ticketsActiveTotal: activeAll, ticketsAllTime: allTickets,
        upcomingSessions: upcoming, activeShows: activeShowIds.size,
        cancelled: cancelledAll, cancelRate: ratio(cancelledAll, allTickets),
        noShow: noShowAll, noShowRate: ratio(noShowAll, activeAll),
        checkedIn, checkInRate: ratio(checkedIn, activeAll),
        // Dönüşüm: bu ay oluşturulan bilet / bu ay oyun sayfası görüntülenmesi
        conversion: ratio(venueMonth + freeMonth, showViews),
      },
      days, trend,
      topShows: showRows,
      topPlayers: named('player', new Map()), topStages: named('stage', stageName), topTeams: named('team', new Map()),
      sessions: upcomingList.slice(0, 60),
      venues: venueRows,
      limits: { events: events.length, shows: shows.length, showRowsCapped: ranked.length > top.length },
    };
  }

  /**
   * İptal edilen biletler (en yeni önce): kim (ad + kullanıcı no), ne zaman, kim iptal etti (müşteri/yönetici).
   * Maliyet: en çok `limit` bilet okuması + en çok `limit` kullanıcı okuması (alan maskesi: ad/soyad).
   */
  async function adminCancelled(assertAdmin, uid, data) {
    await assertAdmin(uid);
    const lim = Math.min(200, Math.max(1, Number.isInteger(data && data.limit) ? data.limit : 100));
    const [snap, total] = await Promise.all([
      T().where('cancelledAt', '>', Timestamp.fromMillis(0)).orderBy('cancelledAt', 'desc').limit(lim).get(),
      cnt(T().where('paymentStatus', '==', 'cancelled')),
    ]);
    const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const uids = [...new Set(rows.map((r) => r.customerId).filter((x) => typeof x === 'string' && x))];
    const names = new Map();
    for (let i = 0; i < uids.length; i += 300) {
      const snaps = await db.getAll(...uids.slice(i, i + 300).map((u) => db.collection('User').doc(u)), { fieldMask: ['firstName', 'lastName'] });
      snaps.forEach((u) => { if (u.exists) names.set(u.id, `${u.data().firstName || ''} ${u.data().lastName || ''}`.trim()); });
    }
    return {
      total, shown: rows.length,
      tickets: rows.map((r) => ({
        ticketId: r.id, showName: r.showName || '', stageName: r.stageName || '', eventDate: r.eventDate || '', eventId: r.eventId || '',
        seats: r.buySeats || [], orderMethod: r.orderMethod || '', price: r.orderPrice ?? '',
        customerId: r.customerId || '', customerName: names.get(r.customerId) || '',
        cancelledAt: r.cancelledAt && r.cancelledAt.toMillis ? r.cancelledAt.toMillis() : null,
        cancelledBy: r.cancelledBy || null, // 'customer' | 'admin' | null (eski kayıt)
        createdAt: r._createdAt || '',
      })),
    };
  }

  return { trackView, adminStats, adminCancelled };
}

module.exports = { createStats, dayKey, monthKey, KINDS, MONTH_RE };

'use strict';
/**
 * Bilet satış çekirdeği. Firebase'e bağımlılıkları (db, sağlayıcı, saat) enjekte edilir; böylece
 * testler emülatörde gerçek Firestore ile, sahte ödeme sağlayıcısıyla çalışır.
 *
 * Koltuk modeli (Event.seats[seatId]) — Event HERKESE AÇIK okunur, bu yüzden hiçbir kullanıcı kimliği yazılmaz:
 *   { status:'available' }
 *   { status:'reserved', orderId(opak), holdExpiresAt(ms), reservedAt }
 *   { status:'sold',     orderId(opak) }
 *   { status:'blocked' }   (yönetici kapattı; eski biçim: sold + customerId '__ADMIN_BLOCKED__')
 * Sahiplik sunucuda `orderId` + Order.userId ile denetlenir. Eski kayıtlardaki `customerId` her yazımda silinir.
 * Fiyat SADECE Event.price'tan, sunucuda hesaplanır. İstemciden tutar/fiyat alınmaz.
 */
const { FieldPath, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const cfg = require('./config');
const { requirePhone } = require('./phone');
const { deletionPendingError, isBlocking } = require('./accountDeletion');
const { err, parsePriceKurus, parseEventDateMs, kurusToTl, kurusStr, validateId, validateSeatIds } = require('./util');

const seatPath = (sid, k) => new FieldPath('seats', sid, k);

function seatHoldExpiry(seat) {
  if (typeof seat.holdExpiresAt === 'number') return seat.holdExpiresAt;
  if (seat.reservedAt && typeof seat.reservedAt.toMillis === 'function') return seat.reservedAt.toMillis() + cfg.HOLD_MS;
  return 0; // eski/bozuk kayıt: süresi dolmuş say
}

const DEL = () => FieldValue.delete();

function releaseArgs(sid) {
  return [
    seatPath(sid, 'status'), 'available',
    seatPath(sid, 'customerId'), DEL(),
    seatPath(sid, 'reservedAt'), DEL(),
    seatPath(sid, 'orderId'), DEL(),
    seatPath(sid, 'holdExpiresAt'), DEL(),
    seatPath(sid, 'soldAt'), DEL(),
  ];
}

function reserveArgs(sid, orderId, expiresAtMs) {
  return [
    seatPath(sid, 'status'), 'reserved',
    seatPath(sid, 'customerId'), DEL(),
    seatPath(sid, 'orderId'), orderId,
    seatPath(sid, 'holdExpiresAt'), expiresAtMs,
    seatPath(sid, 'reservedAt'), FieldValue.serverTimestamp(),
    seatPath(sid, 'soldAt'), DEL(),
  ];
}

function soldArgs(sid, orderId) {
  return [
    seatPath(sid, 'status'), 'sold',
    seatPath(sid, 'customerId'), DEL(),
    seatPath(sid, 'orderId'), orderId,
    seatPath(sid, 'reservedAt'), DEL(),
    seatPath(sid, 'holdExpiresAt'), DEL(),
    seatPath(sid, 'soldAt'), DEL(),
  ];
}

/** Koltuk bu siparişe mi ait? Opak orderId üzerinden; kullanıcı kimliği koltukta tutulmaz. */
const ownsSeat = (seat, orderId) => !!seat && seat.status === 'reserved' && seat.orderId === orderId;

/** Yönetici bloğu: yeni biçim 'blocked'; eski biçim sold + özel işaret (mobil admin henüz taşınmadı). */
const isBlocked = (s) => !!s && (s.status === 'blocked' || (s.status === 'sold' && s.customerId === cfg.ADMIN_BLOCK_CUSTOMER_ID));

function toIso(v) {
  if (!v) return '';
  if (typeof v.toDate === 'function') return v.toDate().toISOString();
  return String(v);
}

/** Config/satis -> güvenli, normalize edilmiş ayarlar. Eksik/bozuk alan -> varsayılan. */
function normalizeSatis(d) {
  d = d || {};
  const mode = cfg.SATIS_MODES.includes(d.mode) ? d.mode : cfg.SATIS_DEFAULT.mode;
  const lim = Number.isInteger(d.rezervasyonLimit) && d.rezervasyonLimit >= 0 && d.rezervasyonLimit <= 50 ? d.rezervasyonLimit : cfg.SATIS_DEFAULT.rezervasyonLimit;
  const iptal = typeof d.iptalSaat === 'number' && Number.isFinite(d.iptalSaat) && d.iptalSaat >= 0 && d.iptalSaat <= 24 * 90 ? d.iptalSaat : cfg.SATIS_DEFAULT.iptalSaat;
  // Etkinlik başına limit (telefon bazlı): tamsayı 1-20; eksik/bozuk -> 3.
  const evLim = Number.isInteger(d.etkinlikBasinaLimit) && d.etkinlikBasinaLimit >= cfg.EVENT_LIMIT_MIN && d.etkinlikBasinaLimit <= cfg.EVENT_LIMIT_MAX
    ? d.etkinlikBasinaLimit : cfg.SATIS_DEFAULT.etkinlikBasinaLimit;
  // Ücretsiz global toplam: 0 = KAPALI (yalnız etkinlik başına limit geçerli); 1-50 = tüm ücretsiz etkinliklerde toplam; eksik/bozuk -> 3 (mevcut davranış).
  const frLim = Number.isInteger(d.ucretsizToplamLimit) && d.ucretsizToplamLimit >= 0 && d.ucretsizToplamLimit <= 50
    ? d.ucretsizToplamLimit : cfg.SATIS_DEFAULT.ucretsizToplamLimit;
  // rezervasyonLimit: 0 = global rezervasyon toplam limiti KAPALI (eskiden 0 = kimse rezervasyon yapamaz; bunun için mode kullanılır).
  return { mode, rezervasyonLimit: lim, iptalSaat: iptal, etkinlikBasinaLimit: evLim, ucretsizToplamLimit: frLim };
}

/** Etkinlik başına limit hatası: details.code='EVENT_LIMIT' (istemci buna göre mesaj/yönlendirme yapar). */
function eventLimitError({ limit, used, eventId }) {
  const remaining = Math.max(0, limit - used);
  return new HttpsError('resource-exhausted',
    `Bu etkinlik için en fazla ${limit} bilet alabilirsin. Şu an ${used} biletin var; ${remaining} bilet daha alabilirsin.`,
    { code: 'EVENT_LIMIT', limit, used, remaining, eventId });
}

/** Bilet fiilen "aktif rezervasyon" sayılır mı? (iptal ve gelmedi sayaçtan düşer) */
const INACTIVE_RES = new Set(['cancelled', 'no_show']);
const ticketStatusOf = (t) => t.paymentStatus || (t.orderMethod === 'venue' ? 'pay_at_venue' : t.orderMethod === 'free' ? 'free' : 'paid');

function createService({ db, getProvider, now = Date.now, callbackUrl, siteUrl, allowedOrigins = [], log = console, settings = null, phoneSalt = null }) {
  const orders = () => db.collection('Order');
  const satisRef = () => db.collection('Config').doc('satis');
  /** Sunucu her çağrıda Config/satis'i okur. `settings` yalnızca testlerde sabitlemek içindir. */
  async function readSatis(tx) {
    if (settings) return normalizeSatis(await settings());
    const snap = tx ? await tx.get(satisRef()) : await satisRef().get();
    return normalizeSatis(snap.exists ? snap.data() : null);
  }
  // ---- Hesap silme kapısı (docs/HESAP-SILME.md): pending/deleting kullanıcı satış yapamaz; cancelTicket/releaseHold serbest.
  const delRef = (uid) => db.collection('AccountDeletion').doc(uid);
  function checkDeletion(snap) {
    if (snap && snap.exists && isBlocking(snap.data())) {
      const sa = snap.data().scheduledAt;
      throw deletionPendingError(sa && typeof sa.toMillis === 'function' ? sa.toMillis() : null);
    }
  }
  async function assertNotDeleting(uid) { checkDeletion(await delRef(uid).get()); }
  async function assertAdmin(uid) {
    const u = await db.collection('User').doc(uid).get();
    if (!u.exists || u.data().role !== 'admin') throw err('permission-denied', 'Bu işlem için yönetici yetkisi gerekir.');
  }

  // ------------------------------------------------------------------ yardımcılar
  // ---- Telefon anahtarlı limitler (docs/ODEME-GUVENLIK.md "Telefon doğrulamalı kimlik")
  // UserLimits/ph_<hash>  : YETKİLİ sayaç (freeTickets, reservations, hold hız sınırı). Hesap silinip yeniden açılsa da aynı telefon -> aynı belge.
  // UserLimits/<uid>      : eski sayaçlar + son kullanılan telefonun AYNASI ({phoneKey, freeTickets, reservations}). Telefon anahtarı
  //                         farklıysa (ilk geçiş ya da telefon değişimi) aynadaki değer telefon sayacına bir kez "taşınır" (max).
  const limDoc = (id) => db.collection('UserLimits').doc(id);
  const who = (ctx) => requirePhone(ctx, phoneSalt);
  async function loadLimits(tx, uid, key) {
    const [u, p] = await Promise.all([tx.get(limDoc(uid)), key ? tx.get(limDoc(key)) : Promise.resolve(null)]);
    const uidL = u.data() || {}, phL = (p && p.data()) || {};
    const carry = !key || uidL.phoneKey !== key; // uid aynasındaki sayaç bu telefona henüz yansıtılmadı
    const eff = (f) => Math.max(phL[f] || 0, carry ? uidL[f] || 0 : 0);
    return { uid, key, uidRef: limDoc(uid), phRef: key ? limDoc(key) : null, uidL, phL, carry, freeTickets: eff('freeTickets'), reservations: eff('reservations') };
  }
  /** Sayaç artışı (transaction içinde, okumalar bitmiş): telefon belgesi + uid aynası. */
  function incLimits(tx, L, { free = 0, res = 0 }) {
    const nf = L.freeTickets + free, nr = L.reservations + res;
    tx.set(L.phRef, { freeTickets: nf, reservations: nr }, { merge: true });
    tx.set(L.uidRef, { phoneKey: L.key, freeTickets: nf, reservations: nr }, { merge: true });
  }
  /** Sayaç değişimi (iptal iadesi / gelmedi): anahtar biliniyorsa telefon belgesi (+ aynası), bilinmiyorsa yalnızca eski uid sayacı. */
  function addLimits(tx, L, field, delta) {
    const bump = (cur) => Math.max(0, (cur || 0) + delta);
    if (L.phRef) {
      tx.set(L.phRef, { [field]: bump(L.phL[field]) }, { merge: true });
      if (L.uidL.phoneKey === L.key) tx.set(L.uidRef, { [field]: bump(L.uidL[field]) }, { merge: true });
    } else {
      tx.set(L.uidRef, { [field]: bump(L.uidL[field]) }, { merge: true });
    }
  }
  /** İptal/yönetici yolları: telefon anahtarı Order belgesinden (id = bilet id), yoksa uid aynasından. */
  async function loadLimitsForTicket(tx, uid, orderSnap) {
    const uSnap = await tx.get(limDoc(uid));
    const key = (orderSnap && orderSnap.exists && orderSnap.data().phoneKey) || (uSnap.data() || {}).phoneKey || null;
    if (!key) return { uid, key: null, uidRef: limDoc(uid), phRef: null, uidL: uSnap.data() || {}, phL: {} };
    const pSnap = await tx.get(limDoc(key));
    return { uid, key, uidRef: limDoc(uid), phRef: limDoc(key), uidL: uSnap.data() || {}, phL: pSnap.data() || {} };
  }

  async function checkRate(key, rate = cfg.HOLD_RATE, fStart = 'holdWindowStart', fCount = 'holdCount') {
    const ref = limDoc(key); // hız sınırı telefona bağlı: yeni hesapla dolaşılamaz
    await db.runTransaction(async (tx) => {
      const d = (await tx.get(ref)).data() || {};
      const t = now();
      let start = d[fStart] || 0, count = d[fCount] || 0;
      if (t - start >= rate.windowMs) { start = t; count = 0; }
      count += 1;
      if (count > rate.max) throw err('resource-exhausted', 'Çok fazla deneme yaptınız. Lütfen bir dakika sonra tekrar deneyin.');
      tx.set(ref, { [fStart]: start, [fCount]: count }, { merge: true });
    });
  }

  // ---- Etkinlik başına limit (docs/ODEME-GUVENLIK.md "Etkinlik başına limit (telefon bazlı)")
  // Kişi = doğrulanmış telefon özeti (phoneKey). Kaynak: o etkinliğe ait Order/Ticket kayıtları (uid yedeği: eski kayıtlar).
  // Yarış: kişi+etkinlik başına KİLİT belgesi (UserLimits/evq_<eventId>_<phoneKey>) her hold/confirm transaction'ında okunup yazılır;
  // aynı kişinin eşzamanlı iki işlemi çakışıp yeniden denenir -> toplam limit aşılamaz.
  const quotaLock = (eventId, key) => limDoc(`evq_${eventId}_${key}`);
  const DONE_ORDER = new Set(['paid', 'reserved', 'free_confirmed']);
  const DEAD_TICKET = new Set(['cancelled', 'no_show']);
  /**
   * Transaction içinde (YAZIMDAN ÖNCE) kişinin bu etkinlikteki aktif koltuk sayısı.
   * Aktif: satılmış/rezerve/ücretsiz bilet, ödemesi süren sipariş, süresi dolmamış tutma. İptal/gelmedi/süresi dolmuş/başarısız HARİÇ.
   * excludeOrderId: sayıma girmeyecek sipariş (onaylanan kendisi). replaceOwnHeld: bu uid'in 'held' siparişleri yeni seçimle değişecek -> usedAll'a girmez.
   */
  async function eventUsage(tx, { uid, key, eventId, t, excludeOrderId = null, replaceOwnHeld = false, legacySeats = null }) {
    const O = orders(), T = db.collection('Ticket');
    const [oKey, oUid, tKey, tUid] = await Promise.all([
      tx.get(O.where('phoneKey', '==', key).where('eventId', '==', eventId)),
      tx.get(O.where('userId', '==', uid).where('eventId', '==', eventId)),
      tx.get(T.where('phoneKey', '==', key).where('eventId', '==', eventId)),
      tx.get(T.where('customerId', '==', uid).where('eventId', '==', eventId)),
    ]);
    const ord = new Map(), tick = new Map();
    for (const d of [...oKey.docs, ...oUid.docs]) ord.set(d.id, d.data());
    for (const d of [...tKey.docs, ...tUid.docs]) tick.set(d.id, d.data());
    // Biten siparişin bileti sorgularda yoksa kimliğinden (bilet id = sipariş id) getir.
    const need = [...ord].filter(([id, o]) => DONE_ORDER.has(o.status) && !tick.has(id)).map(([id]) => T.doc(id));
    if (need.length) for (const sn of await tx.getAll(...need)) if (sn.exists) tick.set(sn.id, sn.data());

    const u = { sold: 0, reserved: 0, free: 0, paying: 0, held: 0, heldOther: 0 };
    for (const [id, o] of ord) {
      if (id === excludeOrderId) continue;
      const n = (o.seatIds || []).length;
      if (o.status === 'held') {
        if (!o.expiresAt || o.expiresAt.toMillis() <= t) continue;
        u.held += n;
        if (!(replaceOwnHeld && o.userId === uid)) u.heldOther += n;
      } else if (o.status === 'paying') {
        u.paying += n;
      } else if (DONE_ORDER.has(o.status)) {
        const tk = tick.get(id);
        if (tk && DEAD_TICKET.has(ticketStatusOf(tk))) continue;
        const cnt = tk ? (tk.buySeats || []).length : n;
        if (o.status === 'reserved') u.reserved += cnt; else if (o.status === 'free_confirmed') u.free += cnt; else u.sold += cnt;
      }
    }
    for (const [id, tk] of tick) { // siparişsiz (eski/mobil doğrudan yazılmış) biletler
      if (ord.has(id) || id === excludeOrderId || DEAD_TICKET.has(ticketStatusOf(tk))) continue;
      const cnt = (tk.buySeats || []).length;
      if (tk.orderMethod === 'venue') u.reserved += cnt; else if (tk.orderMethod === 'free') u.free += cnt; else u.sold += cnt;
    }
    if (legacySeats) { // eski biçim: sahipli, siparişsiz 'reserved' koltuklar
      for (const s of Object.values(legacySeats)) {
        if (s && s.customerId === uid && s.status === 'reserved' && !s.orderId && seatHoldExpiry(s) > t) u.sold += 1;
      }
    }
    u.used = u.sold + u.reserved + u.free + u.paying; // onaylı + ödemesi süren
    u.usedAll = u.used + u.heldOther;                 // başkasının/başka cihazın tutmaları dahil (limit denetimi bunu kullanır)
    return u;
  }

  async function seatsFromStage(tx, stageId) {
    // Event.seats henüz oluşmamışsa sahne planından üret (mobil initializeAndGetEventSeats ile aynı).
    if (!stageId) return null;
    const snap = await tx.get(db.collection('Seats').doc(stageId));
    if (!snap.exists) return null;
    const d = snap.data();
    const closed = new Set(Array.isArray(d.closedSeatsId) ? d.closedSeatsId : []);
    const meta = new Set(['closedSeatsId', '_id', '_createdAt', '_updatedAt']);
    const ids = [];
    if (Array.isArray(d.seatsId)) ids.push(...d.seatsId);
    else for (const [k, v] of Object.entries(d)) if (!meta.has(k) && Array.isArray(v)) ids.push(...v);
    const out = {};
    for (const s of ids) {
      if (typeof s !== 'string') continue;
      out[s] = closed.has(s) ? { status: 'blocked' } : { status: 'available' };
    }
    return Object.keys(out).length ? out : null;
  }

  // ------------------------------------------------------------------ holdSeats
  async function holdSeats(uid, data, ctx) {
    await assertNotDeleting(uid);
    const { key } = who(ctx);
    const eventId = validateId(data && data.eventId, 'etkinlik');
    const seatIds = validateSeatIds(data && data.seatIds);
    const satisH = await readSatis();
    if (satisH.mode === 'kapali') throw err('failed-precondition', 'Bilet satışı şu anda kapalı.');
    await checkRate(key);

    const eventRef = db.collection('Event').doc(eventId);
    const orderRef = orders().doc();

    return db.runTransaction(async (tx) => {
      const t = now();
      const [evSnap, L, myOrdersSnap, delSnap] = await Promise.all([
        tx.get(eventRef),
        loadLimits(tx, uid, key),
        tx.get(orders().where('userId', '==', uid).where('eventId', '==', eventId)),
        tx.get(delRef(uid)),
        tx.get(quotaLock(eventId, key)), // kişi+etkinlik kilidi (yarış): okunur, aşağıda yazılır
      ]);
      checkDeletion(delSnap);
      const heldDocs = myOrdersSnap.docs.filter((d) => d.data().status === 'held');
      if (!evSnap.exists) throw err('not-found', 'Etkinlik bulunamadı.');
      const ev = evSnap.data();

      const dateMs = parseEventDateMs(ev.date);
      if (dateMs == null) throw err('failed-precondition', 'Bu seansın tarihi geçersiz, bilet satışı yapılamıyor.');
      if (dateMs <= t) throw err('failed-precondition', 'Bu seans başladı ya da geçti, bilet alınamaz.');

      const priceKurus = parsePriceKurus(ev.price);
      if (priceKurus == null) throw err('failed-precondition', 'Bu seansın fiyatı tanımlı değil, bilet satışı yapılamıyor.');
      const free = priceKurus === 0;

      let showId = ev.showId || null;
      if (!showId) {
        const sq = await tx.get(db.collection('Show').where('eventsId', 'array-contains', eventId).limit(1));
        if (!sq.empty) showId = sq.docs[0].id;
      }

      let seats = ev.seats && typeof ev.seats === 'object' ? { ...ev.seats } : {};
      let initialized = false;
      if (Object.keys(seats).length === 0) {
        const gen = await seatsFromStage(tx, ev.stageId);
        if (!gen) throw err('failed-precondition', 'Bu seans için koltuk planı hazır değil.');
        seats = gen;
        initialized = true;
      }

      if (free && satisH.ucretsizToplamLimit > 0 && L.freeTickets + seatIds.length > satisH.ucretsizToplamLimit) {
        throw new HttpsError('resource-exhausted', `Ücretsiz etkinliklerde toplam en fazla ${satisH.ucretsizToplamLimit} bilet alabilirsiniz.`, { code: 'FREE_LIMIT', limit: satisH.ucretsizToplamLimit });
      }

      // Kullanıcının bu etkinlikteki kendi bekleyen (held) tutmaları yeni seçimle değiştirilir.
      const updates = []; // [[args...]]
      const orderUpdates = [];
      for (const d of heldDocs) {
        const o = d.data();
        for (const sid of o.seatIds || []) {
          const s = seats[sid];
          if (s && s.status === 'reserved' && s.orderId === d.id) {
            seats[sid] = { status: 'available' };
            updates.push(releaseArgs(sid));
          }
        }
        orderUpdates.push(d.ref);
      }

      for (const sid of seatIds) {
        const s = seats[sid];
        if (!s || typeof s !== 'object') throw err('invalid-argument', `Koltuk bulunamadı: ${sid}`);
        const takeable = s.status === 'available' || (s.status === 'reserved' && seatHoldExpiry(s) <= t);
        if (!takeable) throw err('failed-precondition', isBlocked(s) ? `Koltuk satışa kapalı: ${sid}` : `Koltuk artık müsait değil: ${sid}`);
      }

      // Etkinlik başına limit (telefon bazlı): aktif biletler + ödemesi süren + başkasının tutmaları; kendi eski tutmaları değişeceği için sayılmaz.
      // Kimlik koltukta tutulmadığından kaynak Ticket/Order'dır (ikisi de yalnızca sahibince okunur).
      const usage = await eventUsage(tx, { uid, key, eventId, t, replaceOwnHeld: true, legacySeats: seats });
      if (usage.usedAll + seatIds.length > satisH.etkinlikBasinaLimit) {
        throw eventLimitError({ limit: satisH.etkinlikBasinaLimit, used: usage.usedAll, eventId });
      }
      tx.set(quotaLock(eventId, key), { at: FieldValue.serverTimestamp() });

      // ---- yazımlar (tüm okumalar bitti)
      const expiresAtMs = t + cfg.HOLD_MS;
      if (initialized) {
        const full = { ...seats };
        for (const sid of seatIds) {
          full[sid] = { status: 'reserved', orderId: orderRef.id, holdExpiresAt: expiresAtMs, reservedAt: Timestamp.fromMillis(t) };
        }
        tx.update(eventRef, 'seats', full);
      } else {
        // Önce eski bekleyen tutmaların bırakılması, sonra yeni tutma (sıralı yazımlar; son yazım geçerli).
        for (const u of updates) tx.update(eventRef, ...u);
        tx.update(eventRef, ...seatIds.flatMap((sid) => reserveArgs(sid, orderRef.id, expiresAtMs)));
      }
      for (const ref of orderUpdates) tx.update(ref, { status: 'cancelled', updatedAt: FieldValue.serverTimestamp() });

      const totalKurus = priceKurus * seatIds.length;
      tx.set(orderRef, {
        userId: uid, phoneKey: key, eventId, showId, stageId: ev.stageId || null, seatIds,
        total: kurusToTl(totalKurus), totalKurus, unitPriceKurus: priceKurus, currency: cfg.CURRENCY, free,
        status: 'held', expiresAt: Timestamp.fromMillis(expiresAtMs),
        provider: null, providerToken: null, conversationId: orderRef.id,
        createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        orderId: orderRef.id, expiresAt: expiresAtMs, total: kurusToTl(totalKurus), currency: cfg.CURRENCY, free,
        seats: seatIds.map((id) => ({ id, price: kurusToTl(priceKurus) })),
      };
    });
  }

  // ------------------------------------------------------------------ ön sorgulama
  /** UI'ın alıcıyı koltuk seçmeden ÖNCE uyarması için (sunucu otoritesi). Kişisel veri dönmez; yalnızca sayılar. */
  async function getEventQuota(uid, data, ctx) {
    await assertNotDeleting(uid);
    const { key } = who(ctx);
    const eventId = validateId(data && data.eventId, 'etkinlik');
    await checkRate(key, cfg.QUOTA_RATE, 'quotaWindowStart', 'quotaCount');
    const satis = await readSatis();
    return db.runTransaction(async (tx) => {
      const [evSnap, L] = await Promise.all([tx.get(db.collection('Event').doc(eventId)), loadLimits(tx, uid, key)]);
      if (!evSnap.exists) throw err('not-found', 'Etkinlik bulunamadı.');
      const u = await eventUsage(tx, { uid, key, eventId, t: now(), replaceOwnHeld: true });
      const limit = satis.etkinlikBasinaLimit;
      return {
        eventId, limit, used: u.usedAll, remaining: Math.max(0, limit - u.usedAll),
        held: u.held, sold: u.sold, reserved: u.reserved, free: u.free, paying: u.paying,
        global: {
          freeLimit: satis.ucretsizToplamLimit, freeUsed: L.freeTickets,
          reservationLimit: satis.rezervasyonLimit, reservationUsed: L.reservations,
        },
      };
    });
  }

  // ------------------------------------------------------------------ bırakma / süre dolumu
  /**
   * Siparişin kendi koltuklarını serbest bırakıp durumunu newStatus yapar.
   * `guard(order, t)` false dönerse hiçbir şey yapmaz ve null döner.
   */
  async function closeOrder(orderId, newStatus, guard, extra = {}) {
    const orderRef = orders().doc(orderId);
    return db.runTransaction(async (tx) => {
      const oSnap = await tx.get(orderRef);
      if (!oSnap.exists) return null;
      const o = oSnap.data();
      const g = guard(o, now());
      if (!g) return null;
      const evRef = db.collection('Event').doc(o.eventId);
      const evSnap = await tx.get(evRef);
      const seats = (evSnap.exists && evSnap.data().seats) || {};
      const args = [];
      for (const sid of o.seatIds || []) {
        const s = seats[sid];
        if (s && s.status === 'reserved' && s.orderId === orderId) args.push(...releaseArgs(sid));
      }
      if (args.length) tx.update(evRef, ...args);
      tx.update(orderRef, { status: newStatus, updatedAt: FieldValue.serverTimestamp(), ...extra });
      return { previous: o.status, released: args.length / 12 };
    });
  }

  async function releaseHold(uid, data) {
    const orderId = validateId(data && data.orderId, 'sipariş');
    const snap = await orders().doc(orderId).get();
    if (!snap.exists) throw err('not-found', 'Sipariş bulunamadı.');
    const o = snap.data();
    if (o.userId !== uid) throw err('permission-denied', 'Bu siparişe erişim izniniz yok.');
    if (['cancelled', 'expired', 'failed'].includes(o.status)) return { ok: true };
    if (o.status !== 'held') throw err('failed-precondition', 'Bu sipariş artık bırakılamaz (ödeme başladı ya da tamamlandı).');
    await closeOrder(orderId, 'cancelled', (cur) => cur.status === 'held' && cur.userId === uid);
    return { ok: true };
  }

  async function expireOne(orderId) {
    return closeOrder(orderId, 'expired', (o, t) =>
      (o.status === 'held' || o.status === 'paying') && o.expiresAt && o.expiresAt.toMillis() <= t);
  }

  async function expireHolds() {
    const t = Timestamp.fromMillis(now());
    let expired = 0, settledPaid = 0, releasedSeats = 0;
    for (const status of ['held', 'paying']) {
      const snap = await orders().where('status', '==', status).where('expiresAt', '<=', t).limit(cfg.EXPIRE_BATCH).get();
      for (const d of snap.docs) {
        const o = d.data();
        try {
          if (status === 'paying' && o.providerToken) {
            // Süre dolmadan önce sağlayıcıya sor: callback kaybolmuş ama ödeme alınmış olabilir.
            const provider = getProvider && getProvider(o.provider);
            if (provider) {
              const det = await provider.retrieve({ token: o.providerToken, conversationId: d.id });
              if (det && det.pending) continue; // inceleme sürüyor: kararı bekle, siparişi kapatma
              if (det && det.paid) {
                const r = await settle(d.id, det);
                if (r === 'paid') settledPaid += 1;
                continue;
              }
            }
          }
          const r = await expireOne(d.id);
          if (r) { expired += 1; releasedSeats += r.released || 0; }
        } catch (e) {
          log.error('expireHolds hata', { orderId: d.id, code: e && e.code, message: e && e.message });
        }
      }
    }
    // Kalp atışı: sistem sağlığı panosu bu belgeye bakar. Yazım hatası süre dolumunu bozmaz.
    try {
      await db.collection('System').doc('expireHolds').set({
        lastRunAt: Timestamp.fromMillis(now()), expiredOrders: expired, settledPaid, releasedSeats,
      });
    } catch (e) { log.error('heartbeat yazılamadı', { message: e && e.message }); }
    return { expired, settledPaid };
  }

  // ------------------------------------------------------------------ bilet üretimi (ortak)
  /** Transaction içinde çağrılır; TÜM okumalar (order/event/show/stage/limits) önceden yapılmış olmalı. */
  function writeFulfillment(tx, { orderRef, orderId, order, evRef, ev, show, stage, L, method, status, extraOrder, notifTitle, notifNote }) {
    const args = [];
    for (const sid of order.seatIds) args.push(...soldArgs(sid, orderId));
    tx.update(evRef, ...args);

    const iso = new Date(now()).toISOString();
    const eventDate = toIso(ev.date);
    const ticketRef = db.collection('Ticket').doc(orderId); // deterministik id -> yinelenen bilet imkânsız
    tx.create(ticketRef, {
      _id: orderId, _createdAt: iso, _updatedAt: iso,
      customerId: order.userId, showId: order.showId || '', stageId: order.stageId || '', eventId: order.eventId,
      // phoneKey: yalnızca ÖZET (düz telefon yok). Etkinlik başına limit sayımı için (hesap silmede anonimleşirken silinir).
      ...(((L && L.key) || order.phoneKey) ? { phoneKey: (L && L.key) || order.phoneKey } : {}),
      orderPrice: kurusStr(order.totalKurus), orderMethod: method,
      buySeats: order.seatIds, isPast: false,
      showName: (show && show.name) || '', showImageUrl: (show && show.imageUrl) || '',
      stageName: (stage && stage.name) || '', eventDate, orderId,
      paymentStatus: method === 'venue' ? 'pay_at_venue' : method === 'free' ? 'free' : 'paid',
    });
    tx.set(db.collection('Notification').doc(`order_${orderId}`), {
      _id: `order_${orderId}`, userId: order.userId,
      title: notifTitle || 'Biletin Onaylandı!',
      body: `${(show && show.name) || 'Gösteri'}${eventDate ? ' — ' + eventDate : ''} — Koltuklar: ${order.seatIds.join(', ')} ${notifNote || 'için biletin onaylandı.'}`,
      type: 'bookingConfirmation', showId: order.showId || '', showName: (show && show.name) || '',
      eventDate, seats: order.seatIds, isRead: false, _createdAt: iso,
    });
    if ((order.free || method === 'venue') && L && L.phRef) {
      incLimits(tx, L, { free: order.free ? order.seatIds.length : 0, res: method === 'venue' ? order.seatIds.length : 0 });
    }
    tx.update(orderRef, { ...(L && L.key ? { phoneKey: L.key } : {}), status, ticketIds: [orderId], paidAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), ...extraOrder });
  }

  async function readFulfillCtx(tx, orderRef, orderId, key = null) {
    const oSnap = await tx.get(orderRef);
    if (!oSnap.exists) return null;
    const order = oSnap.data();
    const evRef = db.collection('Event').doc(order.eventId);
    const [evSnap, showSnap, stageSnap, L] = await Promise.all([
      tx.get(evRef),
      order.showId ? tx.get(db.collection('Show').doc(order.showId)) : Promise.resolve(null),
      order.stageId ? tx.get(db.collection('Stage').doc(order.stageId)) : Promise.resolve(null),
      loadLimits(tx, order.userId, key),
    ]);
    return {
      orderRef, orderId, order, evRef, L,
      ev: evSnap.exists ? evSnap.data() : null,
      show: showSnap && showSnap.exists ? showSnap.data() : null,
      stage: stageSnap && stageSnap.exists ? stageSnap.data() : null,
    };
  }

  /** confirm* anında etkinlik başına limit: kendi siparişi hariç aktif + tutulan; kilit belgesi yazılır (yarış). */
  async function guardEventLimit(tx, { uid, key, c, satis }) {
    const t = now();
    await tx.get(quotaLock(c.order.eventId, key));
    const usage = await eventUsage(tx, { uid, key, eventId: c.order.eventId, t, excludeOrderId: c.orderId });
    if (usage.usedAll + c.order.seatIds.length > satis.etkinlikBasinaLimit) {
      throw eventLimitError({ limit: satis.etkinlikBasinaLimit, used: usage.usedAll, eventId: c.order.eventId });
    }
    tx.set(quotaLock(c.order.eventId, key), { at: FieldValue.serverTimestamp() });
  }

  const seatsOwned = (c) => !!c.ev && (c.order.seatIds || []).every((sid) => ownsSeat((c.ev.seats || {})[sid], c.orderId));

  // ------------------------------------------------------------------ ücretsiz onay
  async function confirmFree(uid, data, ctx) {
    await assertNotDeleting(uid);
    const { key } = who(ctx);
    const orderId = validateId(data && data.orderId, 'sipariş');
    const orderRef = orders().doc(orderId);
    return db.runTransaction(async (tx) => {
      checkDeletion(await tx.get(delRef(uid)));
      const satis = await readSatis(tx);
      const c = await readFulfillCtx(tx, orderRef, orderId, key);
      if (!c) throw err('not-found', 'Sipariş bulunamadı.');
      if (c.order.userId !== uid) throw err('permission-denied', 'Bu siparişe erişim izniniz yok.');
      if (!c.order.free) throw err('invalid-argument', 'Bu sipariş ücretli; ödeme gerekiyor.');
      if (c.order.status === 'free_confirmed') return { ticketIds: c.order.ticketIds || [orderId] }; // idempotent
      if (c.order.status !== 'held') throw err('failed-precondition', 'Bu siparişin süresi doldu ya da iptal edildi.');
      if (!c.order.expiresAt || c.order.expiresAt.toMillis() <= now()) throw err('failed-precondition', 'Koltuk tutma süreniz doldu. Lütfen yeniden seçin.');
      if (!seatsOwned(c)) throw err('failed-precondition', 'Koltuklar artık size ait değil. Lütfen yeniden seçin.');
      const dateMs = parseEventDateMs(c.ev.date);
      if (dateMs == null || dateMs <= now()) throw err('failed-precondition', 'Bu seans başladı ya da geçti.');
      if (satis.ucretsizToplamLimit > 0 && c.L.freeTickets + c.order.seatIds.length > satis.ucretsizToplamLimit) {
        throw new HttpsError('resource-exhausted', `Ücretsiz etkinliklerde toplam en fazla ${satis.ucretsizToplamLimit} bilet alabilirsiniz.`, { code: 'FREE_LIMIT', limit: satis.ucretsizToplamLimit });
      }
      await guardEventLimit(tx, { uid, key, c, satis });
      writeFulfillment(tx, { ...c, method: 'free', status: 'free_confirmed' });
      return { ticketIds: [orderId] };
    });
  }

  // ------------------------------------------------------------------ rezervasyon (ödeme sahnede)
  async function confirmReservation(uid, data, ctx) {
    await assertNotDeleting(uid);
    const { key } = who(ctx);
    const orderId = validateId(data && data.orderId, 'sipariş');
    const orderRef = orders().doc(orderId);
    return db.runTransaction(async (tx) => {
      checkDeletion(await tx.get(delRef(uid)));
      const satis = await readSatis(tx);
      const c = await readFulfillCtx(tx, orderRef, orderId, key);
      if (!c) throw err('not-found', 'Sipariş bulunamadı.');
      if (c.order.userId !== uid) throw err('permission-denied', 'Bu siparişe erişim izniniz yok.');
      if (c.order.free) throw err('invalid-argument', 'Ücretsiz sipariş için rezervasyon gerekmez; doğrudan onaylayın.');
      if (c.order.status === 'reserved') return { ticketIds: c.order.ticketIds || [orderId], status: 'rezervasyon' }; // idempotent
      if (satis.mode !== 'rezervasyon') throw err('failed-precondition', 'Rezervasyon şu anda kapalı.');
      if (c.order.status !== 'held') throw err('failed-precondition', 'Bu siparişin süresi doldu ya da iptal edildi.');
      if (!c.order.expiresAt || c.order.expiresAt.toMillis() <= now()) throw err('failed-precondition', 'Koltuk tutma süreniz doldu. Lütfen yeniden seçin.');
      if (!seatsOwned(c)) throw err('failed-precondition', 'Koltuklar artık size ait değil. Lütfen yeniden seçin.');
      const dateMs = parseEventDateMs(c.ev.date);
      if (dateMs == null || dateMs <= now()) throw err('failed-precondition', 'Bu seans başladı ya da geçti.');
      if (satis.rezervasyonLimit > 0 && c.L.reservations + c.order.seatIds.length > satis.rezervasyonLimit) {
        throw new HttpsError('resource-exhausted', `Toplam en fazla ${satis.rezervasyonLimit} rezervasyon yapabilirsiniz.`, { code: 'RESERVATION_LIMIT', limit: satis.rezervasyonLimit });
      }
      await guardEventLimit(tx, { uid, key, c, satis });
      writeFulfillment(tx, {
        ...c, method: 'venue', status: 'reserved',
        notifTitle: 'Rezervasyonun Onaylandı!', notifNote: 'için rezervasyonun onaylandı. Ödemeyi etkinlik gününde sahnede yapacaksın.',
      });
      return { ticketIds: [orderId], status: 'rezervasyon' };
    });
  }

  /** Bileti iptal edip koltukları bırakır, sayacı düşürür. Transaction içinde, okumalar bitmiş olmalı. */
  function applyCancel(tx, { ticketRef, ticketId, t, evRef, ev, L, counterField, orderSnap, dec, by = 'customer', byUid = null }) {
    const seats = (ev && ev.seats) || {};
    const args = [];
    for (const sid of t.buySeats || []) {
      const s = seats[sid];
      if (s && s.status === 'sold' && s.orderId === ticketId) args.push(...releaseArgs(sid));
    }
    if (args.length) tx.update(evRef, ...args);
    tx.update(ticketRef, { paymentStatus: 'cancelled', cancelledAt: Timestamp.fromMillis(now()), cancelledBy: by, ...(byUid ? { cancelledByUid: byUid } : {}), _updatedAt: new Date(now()).toISOString() });
    if (counterField && dec > 0) addLimits(tx, L, counterField, -dec);
    if (orderSnap && orderSnap.exists) tx.update(orderSnap.ref, { status: 'ticket_cancelled', updatedAt: FieldValue.serverTimestamp() });
  }

  async function cancelTicket(uid, data) {
    const ticketId = validateId(data && data.ticketId, 'bilet');
    const ticketRef = db.collection('Ticket').doc(ticketId);
    return db.runTransaction(async (tx) => {
      const satis = await readSatis(tx);
      const tSnap = await tx.get(ticketRef);
      if (!tSnap.exists) throw err('not-found', 'Bilet bulunamadı.');
      const t = tSnap.data();
      if (t.customerId !== uid) throw err('permission-denied', 'Bu bilete erişim izniniz yok.');
      if (t.paymentStatus === 'cancelled') return { ok: true }; // idempotent
      const evRef = db.collection('Event').doc(t.eventId);
      const [evSnap, orderSnap] = await Promise.all([tx.get(evRef), tx.get(orders().doc(ticketId))]);
      const L = await loadLimitsForTicket(tx, uid, orderSnap);
      const cur = ticketStatusOf(t);
      if (t.orderMethod === 'card' || cur === 'paid') {
        throw err('failed-precondition', 'Online ödenmiş biletler uygulamadan iptal edilemez. İade için bizimle iletişime geçin.');
      }
      if (!['pay_at_venue', 'free'].includes(cur)) throw err('failed-precondition', 'Bu bilet iptal edilemez.');
      if (t.usedAt) throw err('failed-precondition', 'Kullanılmış bilet iptal edilemez.');
      const ev = evSnap.exists ? evSnap.data() : null;
      const dateMs = parseEventDateMs(ev ? ev.date : t.eventDate);
      if (dateMs == null) throw err('failed-precondition', 'Bu biletin seans tarihi okunamadı; iptal için iletişime geçin.');
      if (dateMs - now() < satis.iptalSaat * 3600e3) {
        throw err('failed-precondition', `Seansa ${satis.iptalSaat} saatten az kaldığı için bilet iptal edilemez.`);
      }
      applyCancel(tx, {
        ticketRef, ticketId, t, evRef, ev, L, orderSnap,
        counterField: t.orderMethod === 'free' ? 'freeTickets' : 'reservations', dec: (t.buySeats || []).length,
      });
      return { ok: true };
    });
  }

  // ------------------------------------------------------------------ yönetici işlemleri
  async function adminSetTicketStatus(uid, data) {
    await assertAdmin(uid);
    const ticketId = validateId(data && data.ticketId, 'bilet');
    const target = data && data.paymentStatus;
    if (!['paid', 'pay_at_venue', 'no_show', 'cancelled'].includes(target)) throw err('invalid-argument', 'Geçersiz bilet durumu.');
    const ticketRef = db.collection('Ticket').doc(ticketId);
    return db.runTransaction(async (tx) => {
      const tSnap = await tx.get(ticketRef);
      if (!tSnap.exists) throw err('not-found', 'Bilet bulunamadı.');
      const t = tSnap.data();
      const cur = ticketStatusOf(t);
      if (cur === target) return { ok: true, paymentStatus: cur };
      if (cur === 'cancelled') throw err('failed-precondition', 'İptal edilmiş bilet yeniden açılamaz.');
      const method = t.orderMethod;
      const allowed = method === 'venue' ? ['paid', 'pay_at_venue', 'no_show', 'cancelled']
        : method === 'free' ? ['no_show', 'cancelled'] : ['no_show'];
      if (!allowed.includes(target)) {
        throw err('failed-precondition', method === 'card'
          ? 'Online ödenmiş biletlerde yalnızca "gelmedi" işaretlenebilir; iade ödeme panelinden yapılır.'
          : 'Bu bilet türü için bu durum geçersiz.');
      }
      const evRef = db.collection('Event').doc(t.eventId);
      const [evSnap, orderSnap] = await Promise.all([tx.get(evRef), tx.get(orders().doc(ticketId))]);
      const L = await loadLimitsForTicket(tx, t.customerId, orderSnap);
      const n = (t.buySeats || []).length;
      if (target === 'cancelled') {
        applyCancel(tx, {
          ticketRef, ticketId, t, evRef, ev: evSnap.exists ? evSnap.data() : null, L, orderSnap: null,
          counterField: method === 'free' ? 'freeTickets' : method === 'venue' ? 'reservations' : null, dec: n, by: 'admin', byUid: uid,
        });
        return { ok: true, paymentStatus: 'cancelled' };
      }
      if (method === 'venue') { // aktif rezervasyon sayacı: gelmedi düşer, geri alınırsa yeniden eklenir
        const was = !INACTIVE_RES.has(cur), will = !INACTIVE_RES.has(target);
        if (was !== will) {
          addLimits(tx, L, 'reservations', will ? n : -n);
        }
      }
      tx.update(ticketRef, { paymentStatus: target, _updatedAt: new Date(now()).toISOString() });
      return { ok: true, paymentStatus: target };
    });
  }

  async function adminCheckIn(uid, data) {
    await assertAdmin(uid);
    const ticketId = validateId(data && data.ticketId, 'bilet');
    const ticketRef = db.collection('Ticket').doc(ticketId);
    const r = await db.runTransaction(async (tx) => {
      const tSnap = await tx.get(ticketRef);
      if (!tSnap.exists) throw err('not-found', 'Bilet bulunamadı.');
      const t = tSnap.data();
      const cur = ticketStatusOf(t);
      if (cur === 'cancelled' || cur === 'no_show') return { t, cur, ok: false, already: false };
      if (t.usedAt) return { t, cur, ok: false, already: true };
      const usedAt = Timestamp.fromMillis(now());
      tx.update(ticketRef, { usedAt, _updatedAt: new Date(now()).toISOString() });
      return { t: { ...t, usedAt }, cur, ok: true, already: false };
    });
    let customerName;
    try {
      const u = await db.collection('User').doc(r.t.customerId).get();
      if (u.exists) customerName = `${u.data().firstName || ''} ${u.data().lastName || ''}`.trim() || undefined;
    } catch { /* ad zorunlu değil */ }
    return {
      ok: r.ok, ...(r.already ? { already: true } : {}),
      ticket: {
        showName: r.t.showName || '', eventDate: r.t.eventDate || '', stageName: r.t.stageName || '',
        buySeats: r.t.buySeats || [], paymentStatus: r.cur, usedAt: r.t.usedAt ? toIso(r.t.usedAt) : null,
        ...(customerName ? { customerName } : {}),
      },
    };
  }

  /** Hesap silme sağlığı (docs/HESAP-SILME.md): bekleyen/vadesi geçmiş sayısı + zamanlanmış işin kalp atışı. Hata paneli bozmaz. */
  async function deletionHealth(t) {
    const AD = cfg.ACCOUNT_DELETION, col = () => db.collection('AccountDeletion');
    try {
      const [hb, pending, deleting, overdue, failing] = await Promise.all([
        db.collection('System').doc('processAccountDeletions').get(),
        col().where('status', '==', 'pending').count().get(),
        col().where('status', '==', 'deleting').count().get(),
        col().where('scheduledAt', '<=', Timestamp.fromMillis(t)).count().get(),
        col().where('errorCount', '>=', AD.FAILING_AT).count().get(),
      ]);
      const h = hb.exists ? hb.data() : null;
      const last = h && h.lastRunAt && typeof h.lastRunAt.toMillis === 'function' ? h.lastRunAt.toMillis() : null;
      const od = overdue.data().count;
      return {
        pending: pending.data().count, deleting: deleting.data().count, overdue: od, failing: failing.data().count,
        lastRunAt: last, ageMinutes: last == null ? null : Math.max(0, Math.round((t - last) / 60000)),
        processed: h ? h.processed || 0 : 0, deleted: h ? h.deleted || 0 : 0, postponed: h ? h.postponed || 0 : 0, failed: h ? h.failed || 0 : 0,
        stale: last == null ? od > 0 : t - last > AD.STALE_MS && od > 0,
      };
    } catch (e) {
      log.error('deletionHealth', { code: e && e.code });
      return null;
    }
  }

  async function adminHealth(uid) {
    await assertAdmin(uid);
    const t = now();
    const grace = Timestamp.fromMillis(t - cfg.STUCK_GRACE_MS);
    const hb = await db.collection('System').doc('expireHolds').get();
    const hbd = hb.exists ? hb.data() : null;
    const lastRunAt = hbd && hbd.lastRunAt && typeof hbd.lastRunAt.toMillis === 'function' ? hbd.lastRunAt.toMillis() : null;
    const stuck = async (status) => (await orders().where('status', '==', status).where('expiresAt', '<=', grace).count().get()).data().count;
    const dayStart = new Date(Math.floor((t + cfg.TZ_OFFSET_MIN * 60000) / 864e5) * 864e5 - cfg.TZ_OFFSET_MIN * 60000).toISOString();
    // İptal edilenler SAYILMAZ: aktif = oluşturulan - iptal edilen (aynı yöntem). Bugünkü "iptal edilen" sorgusu
    // (orderMethod, paymentStatus, _createdAt) bileşik dizinini ister (firestore.indexes.json).
    const base = (method) => db.collection('Ticket').where('orderMethod', '==', method);
    const active = async (method, today) => {
      const mk = (q) => (today ? q.where('_createdAt', '>=', dayStart) : q);
      const [made, cx] = await Promise.all([
        mk(base(method)).count().get(), mk(base(method).where('paymentStatus', '==', 'cancelled')).count().get(),
      ]);
      return Math.max(0, made.data().count - cx.data().count);
    };
    const cancelledTotal = async () => (await db.collection('Ticket').where('paymentStatus', '==', 'cancelled').count().get()).data().count;
    // "Bugün iptal edilen" = iptal ANI bugün olan biletler (cancelledAt tek alan aralığı; yalnız iptal edilmişlerde bulunur).
    const cancelledToday = async () => (await db.collection('Ticket').where('cancelledAt', '>=', Timestamp.fromMillis(Date.parse(dayStart))).count().get()).data().count;
    const [held, paying, resToday, resTotal, freeToday, freeTotal, cxToday, cxTotal, refundSnap, satis, remHb, remConf] = await Promise.all([
      stuck('held'), stuck('paying'), active('venue', true), active('venue', false), active('free', true), active('free', false),
      cancelledToday(), cancelledTotal(),
      orders().where('refundRequired', '==', true).limit(50).get(), readSatis(),
      db.collection('System').doc('eventReminders').get(), db.collection('Config').doc('bildirim').get(),
    ]);
    const accountDeletion = await deletionHealth(t);
    const rh = remHb.exists ? remHb.data() : null;
    const rLast = rh && rh.lastRunAt && typeof rh.lastRunAt.toMillis === 'function' ? rh.lastRunAt.toMillis() : null;
    const rEnabled = !(remConf.exists && remConf.data().autoReminders === false);
    return {
      now: t, mode: satis.mode,
      heartbeat: {
        lastRunAt, ageMinutes: lastRunAt == null ? null : Math.max(0, Math.round((t - lastRunAt) / 60000)),
        expiredOrders: hbd ? hbd.expiredOrders || 0 : 0, releasedSeats: hbd ? hbd.releasedSeats || 0 : 0,
        stale: lastRunAt == null || t - lastRunAt > cfg.HEARTBEAT_STALE_MS,
      },
      stuck: { held, paying },
      reservations: { today: resToday, total: resTotal },
      freeTickets: { today: freeToday, total: freeTotal },
      cancelled: { today: cxToday, total: cxTotal },
      reminders: {
        enabled: rEnabled, lastRunAt: rLast, ageMinutes: rLast == null ? null : Math.max(0, Math.round((t - rLast) / 60000)),
        sent24: rh ? rh.sent24 || 0 : 0, sent2: rh ? rh.sent2 || 0 : 0,
        stale: rEnabled && (rLast == null || t - rLast > cfg.NOTIFY.REMINDER_STALE_MS),
      },
      accountDeletion,
      refundRequired: {
        count: refundSnap.size,
        orders: refundSnap.docs.map((d) => ({ orderId: d.id, total: d.data().total ?? null, paymentId: d.data().paymentId || null })),
      },
    };
  }

  // ------------------------------------------------------------------ ödeme başlatma
  function checkReturnUrl(u) {
    if (typeof u !== 'string' || u.length > 500) throw err('invalid-argument', 'Geçersiz dönüş adresi.');
    let origin;
    try { origin = new URL(u).origin; } catch { throw err('invalid-argument', 'Geçersiz dönüş adresi.'); }
    const ok = new Set([...allowedOrigins, siteUrl ? new URL(siteUrl).origin : null].filter(Boolean));
    if (!ok.has(origin)) throw err('invalid-argument', 'Dönüş adresine izin verilmiyor.');
    return u;
  }

  async function startPayment(uid, data, ctx = {}) {
    await assertNotDeleting(uid);
    const { phone } = who(ctx);
    const orderId = validateId(data && data.orderId, 'sipariş');
    if ((await readSatis()).mode !== 'online') {
      throw err('failed-precondition', 'Online ödeme şu anda çalışmıyor. Biletinizi rezervasyon olarak onaylayabilirsiniz.');
    }
    const providerName = data && data.provider;
    if (typeof providerName !== 'string') throw err('invalid-argument', 'Ödeme sağlayıcısı geçersiz.');
    const returnUrl = checkReturnUrl(data.returnUrl);
    const provider = getProvider(providerName);
    if (!provider) throw err('invalid-argument', 'Ödeme sağlayıcısı desteklenmiyor.');

    const orderRef = orders().doc(orderId);
    const t = now();
    // 1) held -> paying (atomik); koltuk tutma süresi ödeme penceresine uzatılır.
    const prep = await db.runTransaction(async (tx) => {
      checkDeletion(await tx.get(delRef(uid)));
      const oSnap = await tx.get(orderRef);
      if (!oSnap.exists) throw err('not-found', 'Sipariş bulunamadı.');
      const o = oSnap.data();
      if (o.userId !== uid) throw err('permission-denied', 'Bu siparişe erişim izniniz yok.');
      if (o.free) throw err('invalid-argument', 'Ücretsiz sipariş için ödeme gerekmez; onaylayın.');
      if (o.status === 'paying' && o.providerToken && o.provider === providerName && o.paymentSession) {
        return { resume: o.paymentSession, order: o };
      }
      if (o.status !== 'held') throw err('failed-precondition', 'Bu siparişin süresi doldu ya da ödeme alındı.');
      if (!o.expiresAt || o.expiresAt.toMillis() <= t) throw err('failed-precondition', 'Koltuk tutma süreniz doldu. Lütfen yeniden seçin.');
      const evRef = db.collection('Event').doc(o.eventId);
      const [evSnap, userSnap] = await Promise.all([tx.get(evRef), tx.get(db.collection('User').doc(uid))]);
      const ev = evSnap.exists ? evSnap.data() : null;
      const dateMs = ev && parseEventDateMs(ev.date);
      if (!ev || dateMs == null || dateMs <= t) throw err('failed-precondition', 'Bu seans başladı ya da geçti.');
      const seats = ev.seats || {};
      if (!o.seatIds.every((sid) => ownsSeat(seats[sid], orderId))) {
        throw err('failed-precondition', 'Koltuklar artık size ait değil. Lütfen yeniden seçin.');
      }
      const newExp = t + cfg.PAYMENT_WINDOW_MS;
      const args = [];
      for (const sid of o.seatIds) args.push(seatPath(sid, 'holdExpiresAt'), newExp);
      tx.update(evRef, ...args);
      tx.update(orderRef, {
        status: 'paying', provider: providerName, returnUrl, expiresAt: Timestamp.fromMillis(newExp),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { order: o, user: userSnap.exists ? userSnap.data() : {} };
    });
    if (prep.resume) {
      return { provider: providerName, ...prep.resume };
    }

    // 2) sağlayıcı oturumu (ağ çağrısı transaction DIŞINDA)
    const o = prep.order, u = prep.user || {};
    const fullName = `${u.firstName || ''} ${u.lastName || ''}`.trim();
    const [name, ...rest] = (fullName || 'Tiyatrol Kullanıcısı').split(/\s+/);
    const city = u.city || 'Istanbul';
    let session;
    try {
      session = await provider.initialize({
        order: { id: orderId, totalStr: kurusStr(o.totalKurus), itemName: 'Tiyatro bileti' },
        buyer: {
          id: uid, name, surname: rest.join(' ') || '-', email: ctx.email || 'noreply@tiyatrol.invalid',
          identityNumber: cfg.IYZICO_PLACEHOLDER_IDENTITY, registrationAddress: 'Dijital ürün',
          ip: ctx.ip || '85.34.78.112', city, country: 'Turkey',
          gsmNumber: phone, // doğrulanmış numara (token)
        },
        address: { contactName: fullName || 'Tiyatrol Kullanıcısı', city, country: 'Turkey', address: 'Dijital ürün (teslimat yok)' },
        callbackUrl,
      });
    } catch (e) {
      log.error('startPayment sağlayıcı hatası', { orderId, provider: providerName, message: e && e.message });
      await closeOrder(orderId, 'failed', (cur) => cur.status === 'paying', { failureReason: 'provider_init_failed' }).catch(() => {});
      throw err('unavailable', 'Ödeme sağlayıcısına şu an ulaşılamıyor. Lütfen tekrar deneyin.');
    }
    const out = { token: session.token, paymentPageUrl: session.paymentPageUrl || null, checkoutFormContent: session.checkoutFormContent || null };
    await orderRef.update({ providerToken: session.token, conversationId: orderId, paymentSession: out, updatedAt: FieldValue.serverTimestamp() });
    return { provider: providerName, ...out };
  }

  // ------------------------------------------------------------------ doğrulama + sonuçlandırma
  /** Saf: sağlayıcıdan gelen normalize sonuç siparişle uyuşuyor mu? */
  function verify(order, orderId, token, det) {
    const reasons = [];
    if (!det || !det.paid) return { paid: false, valid: false, reasons: ['not_paid'] };
    if (!order.providerToken || order.providerToken !== token) reasons.push('token');
    if (!Number.isFinite(det.paidPrice) || Math.round(det.paidPrice * 100) !== order.totalKurus) reasons.push('paidPrice');
    if (Number.isFinite(det.price) && Math.round(det.price * 100) !== order.totalKurus) reasons.push('price');
    if (det.currency !== cfg.CURRENCY) reasons.push('currency');
    if (det.conversationId !== orderId) reasons.push('conversationId');
    if (det.basketId !== orderId) reasons.push('basketId');
    if (order.free) reasons.push('free_order');
    return { paid: true, valid: reasons.length === 0, reasons };
  }

  /** Sonucu tek transaction'da uygular. İdempotent. -> 'paid' | 'already' | 'failed' | 'anomaly' | 'ignored' */
  async function settle(orderId, det) {
    const orderRef = orders().doc(orderId);
    let outcome;
    await db.runTransaction(async (tx) => {
      const c = await readFulfillCtx(tx, orderRef, orderId);
      if (!c) { outcome = 'ignored'; return; }
      const { order } = c;
      if (order.status === 'paid') { outcome = 'already'; return; }
      if (det && det.pending && !det.paid) { outcome = 'ignored'; return; } // sahtecilik incelemesi (fraudStatus 0): karar beklenir
      const v = verify(order, orderId, order.providerToken, det);
      const releaseOwn = () => {
        const a = [];
        for (const sid of order.seatIds || []) if (c.ev && ((c.ev.seats || {})[sid] || {}).orderId === orderId && c.ev.seats[sid].status === 'reserved') a.push(...releaseArgs(sid));
        if (a.length) tx.update(c.evRef, ...a);
      };
      if (!v.paid) {
        if (order.status === 'paying') {
          releaseOwn();
          tx.update(orderRef, { status: 'failed', failureReason: 'payment_failed', updatedAt: FieldValue.serverTimestamp() });
          outcome = 'failed';
        } else outcome = 'ignored';
        return;
      }
      if (v.valid && order.status === 'paying' && seatsOwned(c)) {
        writeFulfillment(tx, { ...c, method: 'card', status: 'paid', extraOrder: { paymentId: det.paymentId || null } });
        outcome = 'paid';
        return;
      }
      // Ödeme alınmış görünüyor ama bilet ÜRETİLEMEZ (tutar uyuşmaz / sipariş artık geçerli değil / koltuk kaybı).
      releaseOwn();
      tx.update(orderRef, {
        status: 'failed', failureReason: 'paid_but_unfulfillable', refundRequired: true,
        anomaly: v.valid ? [`status:${order.status}`] : v.reasons, paymentId: det.paymentId || null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      outcome = 'anomaly';
    });
    if (outcome === 'anomaly') log.error('ÖDEME ANOMALİSİ: manuel inceleme/iade gerekli', { orderId });
    return outcome;
  }

  /** iyzico (veya başka sağlayıcı) dönüş çağrısı. -> { ok, orderId|null } */
  async function handleProviderCallback({ providerName, token }) {
    if (typeof token !== 'string' || token.length < 8 || token.length > 256) return { ok: false, orderId: null };
    const q = await orders().where('providerToken', '==', token).limit(2).get();
    if (q.size !== 1) return { ok: false, orderId: null };
    const d = q.docs[0], orderId = d.id, o = d.data();
    if (o.provider !== providerName) return { ok: false, orderId };
    if (o.status === 'paid') return { ok: true, orderId };
    const provider = getProvider(providerName);
    if (!provider) return { ok: false, orderId };
    let det;
    try {
      det = await provider.retrieve({ token, conversationId: orderId });
    } catch (e) {
      log.error('callback doğrulama hatası', { orderId, message: e && e.message });
      return { ok: false, orderId }; // sipariş 'paying' kalır; expireHolds sağlayıcıya yeniden sorar
    }
    const r = await settle(orderId, det);
    return { ok: r === 'paid' || r === 'already', orderId };
  }

  return {
    holdSeats, getEventQuota, releaseHold, startPayment, confirmFree, confirmReservation, cancelTicket,
    adminSetTicketStatus, adminCheckIn, adminHealth,
    handleProviderCallback, expireHolds, settle, verify,
  };
}

module.exports = { createService, normalizeSatis, eventLimitError };

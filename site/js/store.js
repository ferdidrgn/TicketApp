// Veri katmanı: Firestore koleksiyonlarını okur, normalize eder, türetilmiş
// alanları (sıradaki seans, yaşam döngüsü, fiyat aralığı) hesaplar.
// Mobil uygulamayla aynı kurallar: Event.showId tek doğruluk kaynağıdır,
// Show.eventsId yalnızca yedektir; tarihi geçen kayıtlar silinmez, "bitti" sayılır.
import { db, collection, getDocs, EMU } from './firebase.js';
import { tarihAyristir, sayi, gunBasi } from './util.js';
import { ilBul } from './iller.js';

let cache = null;
// ---------- Ham veri: sessionStorage önbelleği ----------
// İlk ziyarette Firestore'dan okunur; sonraki sayfa geçişlerinde önbellekten ANINDA açılır, arka planda tazelenir.
// Koltuk planı (Event.seats) siteye gerekmediği için önbelleğe/belleğe alınmaz.
const ONBELLEK = EMU ? 'tiyatrol.ham.emu' : 'tiyatrol.ham.v3', OMUR = 45 * 60 * 1000;
const KOLEKSIYONLAR = ['Show', 'Event', 'Stage', 'Team', 'Player', 'Campaign', 'Review'];
// Doluluk: Event.seats'ten YALNIZCA sayı türetilir (kimlik yok, koltuk planı önbelleğe girmez).
// Kapalı/engelli koltuk kapasiteden düşer; süresi dolmuş tutma boş sayılır. Plan boşsa (hiç başlatılmamış) null.
const zMs = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : typeof v === 'number' ? v : v && v.seconds ? v.seconds * 1000 : 0);
function dolulukHesapla(seats) {
  if (!seats || typeof seats !== 'object') return null;
  let toplam = 0, dolu = 0;
  for (const m of Object.values(seats)) {
    if (!m || typeof m !== 'object' || m.status === 'blocked' || m.customerId === '__ADMIN_BLOCKED__') continue;
    toplam++;
    if (m.status === 'sold') dolu++;
    else if (m.status === 'reserved') { const b = typeof m.holdExpiresAt === 'number' ? m.holdExpiresAt : zMs(m.holdExpiresAt) || (zMs(m.reservedAt) ? zMs(m.reservedAt) + 15 * 60000 : 0); if (!b || b + 60000 > Date.now()) dolu++; }
  }
  return toplam ? { toplam, dolu } : null;
}
async function tazele() {
  const sonuc = await Promise.all(KOLEKSIYONLAR.map((a) => oku(a).catch(() => [])));
  const ham = Object.fromEntries(KOLEKSIYONLAR.map((a, i) => [a, sonuc[i]]));
  ham.Event = ham.Event.map(({ seats, ...e }) => ({ ...e, _dl: dolulukHesapla(seats) }));
  try { sessionStorage.setItem(ONBELLEK, JSON.stringify({ t: Date.now(), ham })); } catch {}
  return ham;
}
async function hamAl() {
  try {
    const c = JSON.parse(sessionStorage.getItem(ONBELLEK) || 'null');
    if (c && Date.now() - c.t < OMUR) { tazele().catch(() => {}); return c.ham; }
  } catch {}
  return tazele();
}


const list = (v) => (Array.isArray(v) ? v.map(String) : []);
async function oku(ad) {
  const snap = await getDocs(collection(db, ad));
  return snap.docs.map((d) => ({ ...d.data(), docId: d.id, id: d.data()._id || d.id }));
}

export function temizle() { cache = null; }

export async function yukle() {
  if (cache) return cache;
  cache = (async () => {
    const ham = await hamAl();
    const { Show: shows, Event: events, Stage: stages, Team: teams, Player: players, Campaign: campaigns, Review: reviews } = ham;
    const now = new Date();
    const stageById = new Map(stages.map((s) => [s.id, s]));
    const teamById = new Map(teams.map((t) => [t.id, t]));
    const playerById = new Map(players.map((p) => [p.id, p]));
    const showById = new Map();

    const ev = events.map((e) => ({ ...e, when: tarihAyristir(e.date), priceNum: sayi(e.price), doluluk: e._dl ? { ...e._dl, kalan: Math.max(0, e._dl.toplam - e._dl.dolu), oran: Math.min(1, e._dl.dolu / e._dl.toplam) } : null })).filter((e) => e.when);

    for (const s of shows) {
      s.cat = (s.category || 'Diğer').trim();
      s.accessKodlari = list(s.access).map((x) => x.toUpperCase().trim()).filter(Boolean);
      s.oneCikan = /^(evet|true|1|e)$/i.test(String(s.featured || '').trim());
      if (typeof s.description === 'string') s.description = s.description.replace(/\\n/g, '\n'); // veride sızan "\n" metinleri satır sonuna çevir
      s.sessions = [];
      s.nowPlayers = list(s.nowPlayersId);
      s.oldPlayers = list(s.oldPlayersId);
      s.photos = list(s.photosShowId);
      showById.set(s.id, s);
    }
    for (const e of ev) {
      const sid = e.showId || shows.find((s) => list(s.eventsId).includes(e.id))?.id;
      const s = showById.get(sid);
      e.show = s || null;
      e.stage = stageById.get(e.stageId) || stages.find((x) => x.name === e.stageId) || null;
      if (s) s.sessions.push(e);
    }
    for (const s of shows) {
      s.sessions.sort((a, b) => a.when - b.when);
      s.upcoming = s.sessions.filter((e) => e.when >= now);
      s.next = s.upcoming[0] || null;
      const prices = s.upcoming.map((e) => e.priceNum).filter((p) => p != null);
      s.minPrice = prices.length ? Math.min(...prices) : null;
      s.maxPrice = prices.length ? Math.max(...prices) : null;
      s.team = teamById.get(s.teamId) || null;
      s.external = !!(s.externalTicketUrl && String(s.externalTicketUrl).trim());
      // aktif: yaklaşan seansı var; bitti: seansları var ama hepsi geçmiş; vitrin: harici link + seans yok
      s.state = s.upcoming.length ? 'aktif' : s.sessions.length ? 'bitti' : s.external ? 'vitrin' : 'taslak';
      s.venues = [...new Set(s.upcoming.map((e) => e.stage?.name).filter(Boolean))];
    }
    for (const p of players) {
      p.fullName = `${p.firstName || ''} ${p.lastName || ''}`.trim();
      p.name = p.fullName;
      p.nowShows = list(p.nowShowsId).map((id) => showById.get(id)).filter(Boolean);
      p.oldShows = list(p.oldShowsId).map((id) => showById.get(id)).filter(Boolean);
    }
    for (const s of shows) {
      s.cast = s.nowPlayers.map((id) => playerById.get(id)).filter(Boolean);
      s.pastCast = s.oldPlayers.map((id) => playerById.get(id)).filter(Boolean);
    }
    for (const st of stages) {
      st.lat = sayi(st.lat ?? st.locationLat);
      st.lng = sayi(st.long ?? st.locationLng);
      st.upcoming = ev.filter((e) => e.stage === st && e.when >= now).sort((a, b) => a.when - b.when);
      const ids = new Set([...list(st.showsId), ...ev.filter((e) => e.stage === st).map((e) => e.showId)]);
      st.shows = [...ids].map((id) => showById.get(id)).filter(Boolean);
    }
    for (const t of teams) {
      t.shows = shows.filter((s) => s.teamId === t.id || list(t.showsId).includes(s.id));
      t.photos = list(t.photosId);
    }
    // Yorumlar: gizli olmayanlar; oyun başına ortalama ve dağılım
    for (const s of shows) { s.reviews = []; }
    for (const r of reviews) { if (r.hidden) continue; const s = showById.get(r.showId); if (s) s.reviews.push({ ...r, rating: Math.min(5, Math.max(1, Math.round(+r.rating || 0))), tarih: tarihAyristir(r.createdAt) }); }
    for (const s of shows) {
      s.reviews.sort((a, b) => (b.tarih || 0) - (a.tarih || 0));
      s.ratingCount = s.reviews.length;
      s.ratingAvg = s.ratingCount ? s.reviews.reduce((t, r) => t + r.rating, 0) / s.ratingCount : 0;
      s.ratingDist = [5, 4, 3, 2, 1].map((n) => s.reviews.filter((r) => r.rating === n).length);
    }
    // İl bilgisi: Stage.city (varsa) > adres > koordinat. Harici (başka platform) oyunlar kendi mekânından.
    for (const st of stages) st.il = ilBul({ city: st.city, address: st.address, lat: st.lat, lng: st.lng });
    for (const s of shows) {
      s.extLat = sayi(s.externalLat); s.extLng = sayi(s.externalLng);
      s.extIl = s.external || s.externalVenueName || s.externalVenueAddress ? ilBul({ address: s.externalVenueAddress, lat: s.extLat, lng: s.extLng }) : '';
      s.iller = [...new Set([...s.upcoming.map((e) => e.stage?.il), s.extIl].filter(Boolean))];
    }
    const aktif = shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
    const bugun = gunBasi(now);
    const tumKamp = campaigns.map((c) => {
      const b = tarihAyristir(c.startDate), e = tarihAyristir(c.endDate);
      const kalanGun = e ? Math.ceil((e - bugun) / 864e5) : null;
      const durum = e && e < bugun ? 'bitti' : b && b > now ? 'yakinda' : kalanGun !== null && kalanGun <= 7 ? 'son' : 'aktif';
      return { ...c, bas: b, bit: e, kalanGun, durum };
    }).sort((a, b) => ({ son: 0, aktif: 1, yakinda: 2, bitti: 3 }[a.durum] - { son: 0, aktif: 1, yakinda: 2, bitti: 3 }[b.durum]));
    const camp = campaigns.filter((c) => {
      const b = tarihAyristir(c.startDate), e = tarihAyristir(c.endDate);
      return (!b || b <= now) && (!e || e >= bugun);
    });
    return {
      shows, events: ev, stages, teams, players, campaigns: camp, tumKampanyalar: tumKamp, aktif,
      showById, stageById, teamById, playerById,
      ilSayilari: (() => { const m = new Map(); shows.filter((x) => x.state === 'aktif' || x.state === 'vitrin').forEach((x) => x.iller.forEach((i) => m.set(i, (m.get(i) || 0) + 1))); return m; })(),
      kategoriler: [...new Set(aktif.map((s) => s.cat))].sort((a, b) => a.localeCompare(b, 'tr')),
    };
  })();
  try { const r = await cache; document.dispatchEvent(new Event('veri-hazir')); return r; } catch (e) { cache = null; throw e; }
}

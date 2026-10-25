// Veri katmanı: Firestore koleksiyonlarını okur, normalize eder, türetilmiş
// alanları (sıradaki seans, yaşam döngüsü, fiyat aralığı) hesaplar.
// Mobil uygulamayla aynı kurallar: Event.showId tek doğruluk kaynağıdır,
// Show.eventsId yalnızca yedektir; tarihi geçen kayıtlar silinmez, "bitti" sayılır.
import { db, collection, getDocs } from './firebase.js';
import { tarihAyristir, sayi, gunBasi } from './util.js';
import { ilBul } from './iller.js';

let cache = null;

const list = (v) => (Array.isArray(v) ? v.map(String) : []);
async function oku(ad) {
  const snap = await getDocs(collection(db, ad));
  return snap.docs.map((d) => ({ ...d.data(), docId: d.id, id: d.data()._id || d.id }));
}

export function temizle() { cache = null; }

export async function yukle() {
  if (cache) return cache;
  cache = (async () => {
    const [shows, events, stages, teams, players, campaigns] = await Promise.all([
      oku('Show'), oku('Event'), oku('Stage'), oku('Team'), oku('Player'), oku('Campaign').catch(() => []),
    ]);
    const now = new Date();
    const stageById = new Map(stages.map((s) => [s.id, s]));
    const teamById = new Map(teams.map((t) => [t.id, t]));
    const playerById = new Map(players.map((p) => [p.id, p]));
    const showById = new Map();

    const ev = events.map((e) => ({ ...e, when: tarihAyristir(e.date), priceNum: sayi(e.price) })).filter((e) => e.when);

    for (const s of shows) {
      s.cat = (s.category || 'Diğer').trim();
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
    // İl bilgisi: Stage.city (varsa) > adres > koordinat. Harici (başka platform) oyunlar kendi mekânından.
    for (const st of stages) st.il = ilBul({ city: st.city, address: st.address, lat: st.lat, lng: st.lng });
    for (const s of shows) {
      s.extLat = sayi(s.externalLat); s.extLng = sayi(s.externalLng);
      s.extIl = s.external || s.externalVenueName || s.externalVenueAddress ? ilBul({ address: s.externalVenueAddress, lat: s.extLat, lng: s.extLng }) : '';
      s.iller = [...new Set([...s.upcoming.map((e) => e.stage?.il), s.extIl].filter(Boolean))];
    }
    const aktif = shows.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
    const bugun = gunBasi(now);
    const camp = campaigns.filter((c) => {
      const b = tarihAyristir(c.startDate), e = tarihAyristir(c.endDate);
      return (!b || b <= now) && (!e || e >= bugun);
    });
    return {
      shows, events: ev, stages, teams, players, campaigns: camp, aktif,
      showById, stageById, teamById, playerById,
      ilSayilari: (() => { const m = new Map(); shows.filter((x) => x.state === 'aktif' || x.state === 'vitrin').forEach((x) => x.iller.forEach((i) => m.set(i, (m.get(i) || 0) + 1))); return m; })(),
      kategoriler: [...new Set(aktif.map((s) => s.cat))].sort((a, b) => a.localeCompare(b, 'tr')),
    };
  })();
  try { return await cache; } catch (e) { cache = null; throw e; }
}

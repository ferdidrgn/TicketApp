/* ═══════════════ TİYATROL — ekip tanıtım ana sayfası (/) ═══════════════
   Veri: mobil uygulama ve site/ ile AYNI Firestore (hafif REST okuma, tek
   seferlik — ağır SDK yok). Yazma YOK. Sahte/uydurma içerik YOK: bir bölümün
   gerçek verisi yoksa bölüm gizlenir (bkz. hideSection). */
import { slugify } from './js/util.js';

const FIREBASE_PROJECT_ID = 'ticketappflutter';
const FIREBASE_API_KEY = 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k'; // herkese açık istemci anahtarı; güvenlik Firestore Rules'ta
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;
const CONTACT_MAIL = 'ferdidurgun34@gmail.com';
const FOUNDING_YEAR = 2018;

const REDUCED = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ───────────────────────── Firestore REST ───────────────────────── */
function unwrapValue(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return Number(v.doubleValue);
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(unwrapValue);
  if ('mapValue' in v) return unwrapFields(v.mapValue.fields || {});
  return null;
}
function unwrapFields(fields) {
  const out = {};
  for (const k of Object.keys(fields || {})) out[k] = unwrapValue(fields[k]);
  return out;
}
async function fetchCollection(name, max = 300) {
  try {
    const res = await fetch(`${FIRESTORE_BASE}/${name}?key=${FIREBASE_API_KEY}&pageSize=${max}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    return (json.documents || []).map((d) => ({ id: d.name.split('/').pop(), ...unwrapFields(d.fields || {}) }));
  } catch (err) {
    console.warn(`Firestore okuma hatası (${name}):`, err);
    return [];
  }
}

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const cssUrl = (u) => `url("${String(u).replace(/["\\\n]/g, (c) => encodeURIComponent(c))}")`;
const $ = (id) => document.getElementById(id);

/* Site içi gerçek sayfalar (firebase.site.json): /oyun, /oyuncu, /sahne */
const showHref = (s) => `/oyun/${slugify(s.name)}-${s.id}`;
const playerHref = (p) => `/oyuncu/${slugify(`${p.firstName ?? ''} ${p.lastName ?? ''}`)}-${p.id}`;
const stageHref = (st) => `/sahne/${slugify(st.name)}-${encodeURIComponent(st.id)}`;
const mapsHref = (st) => (st.lat && st.long ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${st.lat},${st.long}`)}` : '');

/* ───────────────────────── Tarih ───────────────────────── */
const MONTHS_TR = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN', 'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'];
const cap = (m) => m[0] + m.slice(1).toLocaleLowerCase('tr');
const pad2 = (n) => String(n).padStart(2, '0');
function parseEventDate(raw) {
  if (!raw) return null;
  const m = String(raw).trim().replace(/,\s*/, ' ').match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})$/);
  if (!m) return null;
  const [d, mo, y, h, mi] = m.slice(1).map(Number);
  const date = new Date(y, mo - 1, d, h, mi);
  return Number.isNaN(date.getTime()) ? null : date;
}
const timeOf = (d) => `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
const formatDateTr = (d) => `${d.getDate()} ${cap(MONTHS_TR[d.getMonth()])} ${d.getFullYear()}, ${timeOf(d)}`;
const priceLabel = (p) => (p === '0' || p === 0 ? 'Ücretsiz' : p ? `${p} ₺` : '');

/* ───────────────────────── Veri türetme ───────────────────────── */
/** Event.showId tek doğruluk kaynağıdır; yalnızca boşsa Show.eventsId yedek. */
function buildModel(shows, players, stages, events) {
  const showById = Object.fromEntries(shows.map((s) => [s.id, s]));
  const stageById = Object.fromEntries(stages.map((s) => [s.id, s]));
  const byEventId = {};
  shows.forEach((s) => (s.eventsId || []).forEach((id) => { if (id) byEventId[id] = s; }));
  const now = new Date();
  const evs = events.map((e) => ({
    ...e,
    _date: parseEventDate(e.date),
    _show: (e.showId && showById[e.showId]) || byEventId[e.id] || null,
    _stage: stageById[e.stageId] || null,
  })).filter((e) => e._date).sort((a, b) => a._date - b._date);
  const upcoming = evs.filter((e) => e._date >= now);
  const perShow = {};
  evs.forEach((e) => {
    if (!e._show) return;
    const o = (perShow[e.showId || e._show.id] ||= { upcoming: [], past: [] });
    (e._date >= now ? o.upcoming : o.past).push(e);
  });
  return { shows, players, stages, events: evs, upcoming, perShow, showById, stageById, now };
}

/** Küratör sıralaması (sahibinin kararı): Metafor > Göz Kap Vaz Yap > Kurtar Beni Doktor > diğerleri > Kadınlık (en sonda). */
function sortRepertoire(shows) {
  const order = ['metafor', 'göz', 'doktor'];
  const rank = (s) => {
    const n = (s.name || '').toLowerCase();
    if (n.includes('kadınlık')) return 999;
    for (let i = 0; i < order.length; i++) if (n.includes(order[i])) return i;
    return order.length;
  };
  return [...shows].sort((a, b) => rank(a) - rank(b));
}

const castIds = (show) => new Set([...(show?.nowPlayersId || []), ...(show?.oldPlayersId || [])].filter(Boolean));
const storagePath = (url) => { try { return new URL(url).pathname; } catch { return url; } };
const playerName = (p) => `${p.firstName ?? ''} ${p.lastName ?? ''}`.trim() || 'İsimsiz Sanatçı';
/** bio kısa bir unvan ise ("Yönetmen - Oyuncu") rol olarak gösterilir; uzun biyografi kartta yer almaz. */
const roleOf = (p) => { const b = String(p.bio || '').trim(); return b && b.length <= 42 && !/\d{3,}/.test(b) ? b : ''; };
function parseList(v) {
  if (Array.isArray(v)) return v;
  if (typeof v === 'string' && v.trim().startsWith('[')) { try { const j = JSON.parse(v); return Array.isArray(j) ? j : []; } catch { return []; } }
  return [];
}

/* Elle düzenlenebilir içerik — veri eklendikçe bölüm kendiliğinden belirir, boşken GİZLİ kalır. */
const PRESS_MENTIONS = [
  // { outlet: 'Yayın adı', quote: 'Kısa alıntı…', url: 'https://…' },
];
const BLOG_POSTS = [
  // { title: 'Yazı başlığı', excerpt: 'Kısa özet…', date: '12 Eylül 2026', url: '#' },
];
const WORKSHOPS = [
  // { title: 'Atölye adı', date: '20 Ekim 2026', desc: 'Kısa açıklama', url: '#' },
];
const AWARDS = [
  // { title: 'Ödül / festival adı', year: '2026', note: 'Kısa açıklama' },
];
/** Bilinen eserlerin yazarları (doğrulanmış) — "Yazan:" notu. */
const SHOW_PLAYWRIGHTS = { 'kadınlık': 'Yılmaz Erdoğan', 'gözlerimi': 'Haldun Taner' };
const playwrightOf = (show) => {
  const key = Object.keys(SHOW_PLAYWRIGHTS).find((k) => (show?.name || '').toLowerCase().includes(k));
  return key ? SHOW_PLAYWRIGHTS[key] : '';
};
/** Kaynağı doğrulanmış gerçek replikler (uydurma değil). */
const SHOW_THEME_NOTES = {
  'kadınlık': [
    'Hepiniz bir ara iyi bir çocuktunuz, en azından iyi bir çocuğa benziyordunuz.',
    'Biz kadınlar artık hiçbirinizin bizi sevmesini istemiyoruz — siz insan gibi sevmeyi öğreninceye kadar.',
  ],
  'gözlerimi': [
    'Gözlerimi kaparım, vazifemi yaparım.',
    'Benim adım Nilüfer. Nasıl tanıdınız beni o kadar mektup arasında?',
  ],
};

function hideSection(id) {
  $(id)?.remove();
  document.querySelectorAll(`a[href="#${id}"]`).forEach((a) => a.remove());
}

/* ───────────────────────── Açılış ───────────────────────── */
/* Sahibinin kuralı: bu sayfada YALNIZCA bu ekiplerin oyunları görünür (ad üzerinden, harf/aksan duyarsız;
 * id'ler yalnız yedek). Süzme TEK yerde yapılır; oyuncu/seans/sahne/galeri hep süzülmüş oyunlardan türer. */
const IZINLI_EKIP_ADLARI = ['tiyatrol', 'atasehir tiyatro toplulugu'];
const IZINLI_EKIP_IDLERI = new Set(['FvAxpQCb0DQz5xLOM3KC', 'MvUOZ5VpWfK5BCJjQhki']);
const normAd = (s) => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/\s+/g, ' ').trim();

function filterAllowed(showsRaw, teams, players, stages, events) {
  const okTeams = new Set(teams.filter((t) => IZINLI_EKIP_ADLARI.includes(normAd(t.name))).map((t) => t.id));
  IZINLI_EKIP_IDLERI.forEach((id) => { if (!teams.length || teams.some((t) => t.id === id)) okTeams.add(id); });
  const shows = showsRaw.filter((s) => s.teamId && okTeams.has(s.teamId));
  const showIds = new Set(shows.map((s) => s.id));
  const evIds = new Set(shows.flatMap((s) => s.eventsId || []));
  const evs = events.filter((e) => (e.showId ? showIds.has(e.showId) : evIds.has(e.id)));
  const cast = new Set(shows.flatMap((s) => [...(s.nowPlayersId || []), ...(s.oldPlayersId || [])]).filter(Boolean));
  const pl = players.filter((p) => cast.has(p.id));
  const stageIds = new Set(evs.map((e) => e.stageId).filter(Boolean));
  stages.forEach((st) => { if ((st.showsId || []).some((id) => showIds.has(id))) stageIds.add(st.id); });
  return { shows, players: pl, stages: stages.filter((st) => st.name && stageIds.has(st.id)), events: evs };
}

/** "Önerdiğimiz oyun": ekip dışı bir oyunun oyuncu listesinde, izinli ekiplerin oyunlarında oynayan bir oyuncu varsa
 * (oyuncu id'siyle eşleşir) o oyunun seansları YALNIZ takvim ve kronolojide görünür. Başka hiçbir yerde sayılmaz. */
function buildSuggested(showsRaw, F, playersRaw, stagesRaw, eventsRaw) {
  const ours = new Set(F.shows.map((s) => s.id));
  const castOurs = new Set(F.players.map((p) => p.id));
  const playerById = Object.fromEntries(playersRaw.map((p) => [p.id, p]));
  const stageById = Object.fromEntries(stagesRaw.map((st) => [st.id, st]));
  const out = [];
  showsRaw.filter((s) => !ours.has(s.id)).forEach((show) => {
    const who = [...new Set([...(show.nowPlayersId || []), ...(show.oldPlayersId || [])].filter((id) => id && castOurs.has(id)))]
      .map((id) => playerName(playerById[id] || {})).filter(Boolean);
    if (!who.length) return;
    const evIds = new Set((show.eventsId || []).filter(Boolean));
    eventsRaw.filter((e) => (e.showId ? e.showId === show.id : evIds.has(e.id))).forEach((e) => {
      const d = parseEventDate(e.date);
      if (d) out.push({ ...e, _date: d, _show: show, _stage: stageById[e.stageId] || null, _suggested: true, _who: who });
    });
  });
  return out;
}

async function boot() {
  const [showsRaw, playersRaw, stagesRaw, eventsRaw, teams] = await Promise.all([
    fetchCollection('Show'), fetchCollection('Player'), fetchCollection('Stage'), fetchCollection('Event'), fetchCollection('Team'),
  ]);
  const F = filterAllowed(showsRaw, teams, playersRaw, stagesRaw, eventsRaw);
  const M = buildModel(sortRepertoire(F.shows), F.players, F.stages, F.events);
  // Takvim + kronoloji: bizim seanslar ve önerilenler tarih sırasına göre karışık
  M.calEvents = [...M.events, ...buildSuggested(showsRaw, F, playersRaw, stagesRaw, eventsRaw)].sort((a, b) => a._date - b._date);
  M.calUpcoming = M.calEvents.filter((e) => e._date >= M.now);

  renderHero(M);
  renderMarquee(M);
  renderAbout(M);
  renderStats(M);
  renderRepertoire(M);
  renderTeam(M);
  renderCalendar(M);
  renderTimeline(M);
  renderNotes(M);
  renderGallery(M);
  renderMediaStage(M);
  renderVenues(M);
  renderPress(M);
  renderAwards(M);
  renderQuote(M);
  renderNextUp(M);
  renderWorkshops();
  renderBlog();
  renderInstagram(M);

  initReveal();
  initInteractions();
}

/* ───────────────────────── Bölümler ───────────────────────── */
function renderHero(M) {
  const el = $('heroStatus');
  const next = M.upcoming[0];
  if (next) {
    const parts = [`${next._show?.name || 'Yaklaşan gösteri'} — ${formatDateTr(next._date)}`];
    if (next._stage?.name) parts.push(next._stage.name);
    const text = esc(parts.join(' · '));
    el.innerHTML = next._show ? `<a href="${showHref(next._show)}" data-cursor-hover>${text} →</a>` : text;
  } else if (M.shows.length) {
    el.textContent = `Repertuarımızda ${M.shows.length} oyun var — yeni seanslar yakında.`;
  } else {
    el.textContent = 'Yeni sezonun perdesi yakında açılıyor.';
  }
}

function renderMarquee(M) {
  const names = M.shows.map((s) => s.name).filter(Boolean);
  const list = names.length ? names : ['TiyatRol Sahne Sanatları'];
  const html = list.map((n) => `<span class="marquee__item">${esc(n)} <span>✦</span></span>`).join('');
  // Kesintisiz döngü için içerik, genişlik ekranı aşana dek çoğaltılır (yarısı kadar kayar).
  $('marqueeRow').innerHTML = html.repeat(Math.max(2, Math.ceil(8 / list.length)) * 2);
}

function renderAbout(M) {
  const art = $('aboutArt');
  const lead = M.shows.find((s) => s.imageUrl) || M.shows[0];
  const img1 = lead?.imageUrl;
  const p1 = img1 ? storagePath(img1) : '';
  const ids = castIds(lead);
  const castPhoto = M.players.find((p) => ids.has(p.id) && p.imageUrl && storagePath(p.imageUrl) !== p1)?.imageUrl;
  const pool = M.shows.flatMap((s) => [s.imageUrl, ...(s.photosShowId || [])]).filter(Boolean);
  const img2 = castPhoto || (lead?.photosShowId || []).find((u) => u && storagePath(u) !== p1) || pool.find((u) => storagePath(u) !== p1);
  if (img1) art.style.setProperty('--about-img-1', cssUrl(img1));
  if (img2) { art.style.setProperty('--about-img-2', cssUrl(img2)); art.classList.remove('about__art--single'); }
  else art.classList.add('about__art--single');
  if (!img1 && !img2) art.style.display = 'none';

  // Künye (program kitapçığı) — yalnızca doğrulanabilir alanlar.
  const rows = [
    ['Kuruluş', String(FOUNDING_YEAR)],
    ['Merkez', 'Ataşehir, İstanbul'],
  ];
  if (M.shows.length) rows.push(['Repertuar', M.shows.map((s) => s.name).filter(Boolean).join(' · ')]);
  if (M.stages.length) rows.push(['Sahneler', M.stages.map((s) => s.name).join(' · ')]);
  if (M.players.length) rows.push(['Kadro', `${M.players.length} sanatçı`]);
  $('kunyeList').innerHTML = rows.map(([k, v]) => `<div class="kunye__row"><dt>${esc(k)}</dt><dd>${esc(v)}</dd></div>`).join('');
}

function renderStats(M) {
  const vals = [M.shows.length, M.upcoming.length, M.stages.length, M.players.length, new Date().getFullYear() - FOUNDING_YEAR];
  const nums = document.querySelectorAll('.stat__num');
  vals.forEach((v, i) => { if (nums[i]) { nums[i].dataset.target = v; if (REDUCED) nums[i].textContent = v; } });
}

/** Her oyun için "durum" etiketi: yaklaşan seans → tarih; hepsi geçmişse → "Sezon tamamlandı". */
function showStatus(M, s) {
  const o = M.perShow[s.id];
  if (o?.upcoming.length) {
    const d = o.upcoming[0]._date;
    return { text: `${d.getDate()} ${cap(MONTHS_TR[d.getMonth()])}`, live: true, count: o.upcoming.length };
  }
  if (o?.past.length) return { text: 'Seanslar tamamlandı', live: false, count: 0 };
  return null;
}

function renderRepertoire(M) {
  const grid = $('repertoireGrid');
  if (!M.shows.length) { grid.innerHTML = `<div class="empty">Repertuar yakında burada.</div>`; return; }
  grid.innerHTML = M.shows.map((s) => {
    const name = esc(s.name || 'İsimsiz Oyun');
    const desc = esc((s.description || '').trim());
    const playwright = esc(playwrightOf(s));
    const gallery = (s.photosShowId || []).filter(Boolean);
    const shot = gallery.length ? gallery[Math.floor(Math.random() * gallery.length)] : '';
    const primary = s.imageUrl || shot || '';
    const secondary = shot && shot !== primary ? shot : '';
    const st = showStatus(M, s);
    return `<a class="show reveal" href="${showHref(s)}" data-swap aria-label="${name} oyununun sayfası">
      ${primary ? `<img class="show__img show__img--primary" src="${esc(primary)}" alt="" loading="lazy" />` : `<div class="show__img show__img--ph">${name}</div>`}
      ${secondary ? `<img class="show__img show__img--secondary" src="${esc(secondary)}" alt="" loading="lazy" />` : ''}
      <div class="show__shade"></div>
      <span class="show__cat">${esc(s.category || 'Tiyatro')}</span>
      ${st ? `<span class="show__when${st.live ? ' is-live' : ''}">${esc(st.text)}</span>` : ''}
      <div class="show__body">
        <p class="show__name">${name}</p>
        ${playwright ? `<p class="show__author">Yazan: ${playwright}</p>` : ''}
        ${desc ? `<p class="show__desc">${desc}</p>` : ''}
        <div class="show__meta">${s.duration ? `<span>${esc(s.duration)}</span>` : ''}${s.ageLimit ? `<span>${esc(s.ageLimit)}+</span>` : ''}</div>
      </div>
    </a>`;
  }).join('');
}

/* ── Kadro: oyuna göre sekme + kaydırmalı şerit ── */
let TEAM = { M: null, tab: 'all' };
function renderTeam(M) {
  const tabs = $('teamTabs');
  const rail = $('teamRail');
  if (!M.players.length) { hideSection('ekip'); return; }
  TEAM.M = M;
  const withCast = M.shows.filter((s) => M.players.some((p) => castIds(s).has(p.id)));
  const lead = M.upcoming[0]?._show || withCast[0];
  TEAM.tab = lead && withCast.includes(lead) ? lead.id : 'all';
  tabs.innerHTML = [...withCast.map((s) => ({ id: s.id, label: s.name })), { id: 'all', label: 'Tüm Kadro' }]
    .map((t) => `<button type="button" role="tab" class="mtab mtab--light" data-t="${esc(t.id)}" aria-selected="${t.id === TEAM.tab}">${esc(t.label)}</button>`).join('');
  tabs.querySelectorAll('.mtab').forEach((btn) => btn.addEventListener('click', () => {
    TEAM.tab = btn.dataset.t;
    tabs.querySelectorAll('.mtab').forEach((b) => b.setAttribute('aria-selected', String(b === btn)));
    drawTeam();
  }));
  $('teamPrev').addEventListener('click', () => railScroll(rail, -1));
  $('teamNext').addEventListener('click', () => railScroll(rail, 1));
  rail.addEventListener('scroll', () => railEnds(rail, 'teamPrev', 'teamNext'), { passive: true });
  rail.addEventListener('keydown', (e) => { if (e.key === 'ArrowRight') railScroll(rail, 1); if (e.key === 'ArrowLeft') railScroll(rail, -1); });
  drawTeam();
}
function drawTeam() {
  const { M, tab } = TEAM;
  const rail = $('teamRail');
  const show = M.showById[tab];
  const ids = show ? castIds(show) : null;
  const list = ids ? M.players.filter((p) => ids.has(p.id)) : M.players;
  $('teamSub').textContent = show ? `"${show.name}" oyununun kadrosu — ${list.length} sanatçı` : `TiyatRol sahnesinde yer alan ${list.length} sanatçı`;
  rail.scrollLeft = 0;
  rail.innerHTML = list.map((p, i) => {
    const name = esc(playerName(p));
    const role = esc(roleOf(p));
    const quote = p.quote && p.quote.trim() ? esc(p.quote.trim()) : '';
    const img = p.imageUrl
      ? `<img class="player__img" src="${esc(p.imageUrl)}" alt="" loading="lazy" referrerpolicy="no-referrer" />`
      : `<div class="player__img player__img--ph">${esc((p.firstName || '?')[0])}</div>`;
    return `<a class="player reveal" href="${playerHref(p)}" style="--i:${Math.min(i, 8)}" aria-label="${name}, sanatçı sayfası">
      <div class="player__ring">${img}</div>
      <p class="player__name">${name}</p>
      ${role ? `<p class="player__role">${role}</p>` : ''}
      ${quote ? `<p class="player__quote">"${quote}"</p>` : ''}
    </a>`;
  }).join('');
  // Süresi dolmuş/bozuk dış görsel bağlantısı → baş harfli yer tutucu
  rail.querySelectorAll('img.player__img').forEach((img, k) => img.addEventListener('error', () => {
    const ph = document.createElement('div');
    ph.className = 'player__img player__img--ph';
    ph.textContent = (list[k]?.firstName || '?')[0];
    img.replaceWith(ph);
  }, { once: true }));
  observeReveals(rail);
  initSpotlight(rail);
  railEnds(rail, 'teamPrev', 'teamNext');
}
function railScroll(el, dir) {
  el.scrollBy({ left: dir * Math.max(240, el.clientWidth * 0.8), behavior: REDUCED ? 'auto' : 'smooth' });
}
function railEnds(el, prevId, nextId) {
  const max = el.scrollWidth - el.clientWidth - 2;
  const prev = $(prevId), next = $(nextId);
  if (prev) prev.disabled = el.scrollLeft <= 2;
  if (next) next.disabled = el.scrollLeft >= max;
  prev?.parentElement?.classList.toggle('is-idle', max <= 0);
}

/* ── Takvim (12 aylık kayan pencere) + kronoloji ── */
let CAL = { M: null, key: '' };
function renderCalendar(M) {
  CAL.M = M;
  const base = new Date(M.now.getFullYear(), M.now.getMonth(), 1);
  const months = Array.from({ length: 12 }, (_, i) => new Date(base.getFullYear(), base.getMonth() + i, 1));
  const first = M.calUpcoming[0]?._date || M.now;
  CAL.key = `${first.getFullYear()}-${first.getMonth()}`;
  const keyOf = (d) => `${d.getFullYear()}-${d.getMonth()}`;
  const has = new Set(M.calEvents.map((e) => keyOf(e._date)));
  const wrap = $('calTabs');
  wrap.innerHTML = months.map((d) => {
    const k = keyOf(d);
    const yr = d.getFullYear() !== M.now.getFullYear() ? ` ${d.getFullYear()}` : '';
    return `<button type="button" class="mtab${k === CAL.key ? ' is-active' : ''}${has.has(k) ? ' has-ev' : ''}" data-k="${k}" aria-pressed="${k === CAL.key}">${MONTHS_TR[d.getMonth()]}${yr}</button>`;
  }).join('');
  wrap.querySelectorAll('.mtab').forEach((btn) => btn.addEventListener('click', () => {
    CAL.key = btn.dataset.k;
    wrap.querySelectorAll('.mtab').forEach((b) => { b.classList.toggle('is-active', b === btn); b.setAttribute('aria-pressed', String(b === btn)); });
    drawCalendar();
  }));
  drawCalendar();
  // Sayfayı kaydırma: yalnız ay sekmelerinin kendi yatay kaydırmasında aktif ayı ortala.
  const act = wrap.querySelector('.is-active');
  if (act) wrap.scrollLeft += act.getBoundingClientRect().left - wrap.getBoundingClientRect().left - (wrap.clientWidth - act.offsetWidth) / 2;
}
function drawCalendar() {
  const { M, key } = CAL;
  const [y, mo] = key.split('-').map(Number);
  $('calMonth').textContent = `${MONTHS_TR[mo]} ${y}`;
  const row = $('calRow');
  const list = M.calEvents.filter((e) => e._date.getFullYear() === y && e._date.getMonth() === mo);
  if (!list.length) { row.innerHTML = `<div class="empty">Bu ayda planlanmış bir seans yok.</div>`; return; }
  row.innerHTML = list.map((e) => {
    const s = e._show;
    const name = esc(s?.name || 'Gösteri');
    const img = s?.imageUrl ? `<img class="ticket__img" src="${esc(s.imageUrl)}" alt="" loading="lazy" />` : `<div class="ticket__img--ph">${name}</div>`;
    const past = e._date < M.now;
    const price = priceLabel(e.price);
    const tag = s ? 'a' : 'div';
    return `<${tag} class="ticket reveal${past ? ' is-past' : ''}${e._suggested ? ' is-suggested' : ''}"${s ? ` href="${showHref(s)}" aria-label="${name}, ${esc(formatDateTr(e._date))}" data-cursor-hover` : ''}>
      ${img}
      <div class="ticket__notch"></div>
      <div class="ticket__body">
        <div class="ticket__date"><span class="ticket__day">${e._date.getDate()}</span><span class="ticket__rest">${MONTHS_TR[e._date.getMonth()]}<br>${timeOf(e._date)}</span></div>
        ${e._suggested ? `<span class="sug-badge">Önerdiğimiz oyun</span>` : ''}
        <p class="ticket__name">${name}</p>
        ${e._suggested ? `<p class="sug-note">${esc(suggestNote(e))}</p>` : ''}
        ${e._stage?.name ? `<p class="ticket__stage">${esc(e._stage.name)}</p>` : ''}
        ${past ? `<span class="ticket__tag">Oynandı</span>` : price ? `<span class="ticket__tag ticket__tag--price">${esc(price)}</span>` : ''}
      </div>
    </${tag}>`;
  }).join('');
  observeReveals(row);
}

const suggestNote = (e) => `Ekibimizden ${e._who.join(', ')} sahnede — ekibimiz dışında bir yapım, gitmenizi öneririz.`;

function renderTimeline(M) {
  const rail = $('timelineRail');
  const list = M.calUpcoming.slice(0, 10);
  if (!list.length) { hideSection('kronoloji'); return; }
  rail.innerHTML = list.map((e) => {
    const s = e._show;
    const name = esc(s?.name || 'Gösteri');
    const img = s?.imageUrl ? `<img class="timeline__img" src="${esc(s.imageUrl)}" alt="" loading="lazy" />` : `<div class="timeline__img--ph">${name}</div>`;
    const meta = [s?.category, e._stage?.name, priceLabel(e.price)].filter(Boolean).join(' · ');
    const tag = s ? 'a' : 'div';
    return `<div class="timeline__item reveal${e._suggested ? ' is-suggested' : ''}">
      <span class="timeline__dot"></span>
      <div class="timeline__date">${esc(formatDateTr(e._date))}</div>
      <${tag} class="timeline__card"${s ? ` href="${showHref(s)}" data-cursor-hover` : ''}>
        ${img}
        <div class="timeline__body">${e._suggested ? `<span class="sug-badge">Önerdiğimiz oyun</span>` : ''}<p class="timeline__name">${name}</p>${e._suggested ? `<p class="sug-note">${esc(suggestNote(e))}</p>` : ''}${meta ? `<p class="timeline__meta">${esc(meta)}</p>` : ''}</div>
      </${tag}>
    </div>`;
  }).join('');
}

function renderNotes(M) {
  const items = [];
  M.shows.forEach((s) => {
    const key = Object.keys(SHOW_THEME_NOTES).find((k) => (s.name || '').toLowerCase().includes(k));
    if (key) SHOW_THEME_NOTES[key].forEach((note) => items.push(`${note} — “${s.name}”`));
  });
  if (!items.length) { hideSection('notlar'); return; }
  $('notesBoard').innerHTML = items.map((text, i) => `<div class="note reveal" style="--r:${((i % 5) - 2) * 3.2}deg"><p>${esc(text)}</p></div>`).join('');
}

/* ── Galeri: karusel (oyunlar arası dönüşümlü, tekrarsız) ── */
function renderGallery(M) {
  const groups = M.shows.map((s) => (s.photosShowId || []).filter(Boolean).map((url) => ({ url, name: s.name })));
  const seen = new Set();
  const photos = [];
  for (let i = 0; photos.length < 18; i++) {
    let any = false;
    for (const g of groups) {
      if (i >= g.length) continue;
      any = true;
      const k = storagePath(g[i].url);
      if (!seen.has(k) && photos.length < 18) { seen.add(k); photos.push(g[i]); }
    }
    if (!any) break;
  }
  if (!photos.length) { hideSection('galeri'); return; }
  const track = $('galleryTrack');
  track.innerHTML = photos.map((p, i) => `<figure class="slide" aria-roledescription="slayt" aria-label="${i + 1} / ${photos.length}">
      <img src="${esc(p.url)}" alt="${esc(p.name || 'TiyatRol')} oyunundan bir sahne" loading="${i < 2 ? 'eager' : 'lazy'}" decoding="async" />
      <figcaption>${esc(p.name || '')}</figcaption>
    </figure>`).join('');
  const count = $('galCount');
  const slides = [...track.children];
  const update = () => {
    const step = slides.length > 1 ? slides[1].offsetLeft - slides[0].offsetLeft : track.clientWidth;
    const i = Math.min(slides.length - 1, Math.max(0, Math.round(track.scrollLeft / Math.max(1, step))));
    count.textContent = `${pad2(i + 1)} / ${pad2(slides.length)}`;
    railEnds(track, 'galPrev', 'galNext');
  };
  let raf = 0;
  track.addEventListener('scroll', () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(update); }, { passive: true });
  const go = (dir) => {
    const step = slides.length > 1 ? slides[1].offsetLeft - slides[0].offsetLeft : track.clientWidth;
    track.scrollBy({ left: dir * step, behavior: REDUCED ? 'auto' : 'smooth' });
  };
  $('galPrev').addEventListener('click', () => go(-1));
  $('galNext').addEventListener('click', () => go(1));
  track.addEventListener('keydown', (e) => { if (e.key === 'ArrowRight') { e.preventDefault(); go(1); } if (e.key === 'ArrowLeft') { e.preventDefault(); go(-1); } });
  window.addEventListener('resize', update);
  update();
}

function renderVenues(M) {
  const grid = $('venuesGrid');
  if (!M.stages.length) { hideSection('sahneler'); return; }
  grid.innerHTML = M.stages.map((s) => {
    const name = esc(s.name);
    const cap_ = Number(String(s.capacity || '').replace(/\D/g, '')) || 0;
    const map = mapsHref(s);
    const n = M.upcoming.filter((e) => e.stageId === s.id).length;
    const img = s.imageUrl ? `<img class="venue__img" src="${esc(s.imageUrl)}" alt="" loading="lazy" />` : `<div class="venue__img venue__img--ph">${name}</div>`;
    return `<article class="venue reveal">
      ${img}
      <div class="venue__shade"></div>
      <div class="venue__body">
        <p class="venue__name"><a href="${stageHref(s)}" data-cursor-hover>${name}</a></p>
        ${s.address ? `<p class="venue__addr">${esc(s.address)}</p>` : ''}
        <p class="venue__cap">${[cap_ ? `${cap_} kişilik salon` : '', n ? `${n} yaklaşan seans` : ''].filter(Boolean).map(esc).join(' · ')}</p>
        ${map ? `<a class="venue__map" href="${map}" target="_blank" rel="noopener" aria-label="${name} için yol tarifi (yeni sekmede açılır)" data-cursor-hover>Yol tarifi ↗</a>` : ''}
      </div>
    </article>`;
  }).join('');
}

function renderQuote(M) {
  // Yalnızca "Gürkan Candan"ın sözü (Player.quote; her dolu satır ayrı söz). Boşsa bölüm gizlenir, başkasına düşülmez.
  const p = M.players.find((x) => normAd(playerName(x)) === 'gurkan candan') || M.players.find((x) => x.id === '98rYtDcYcoWTex8JTetm');
  const quotes = String(p?.quote || '').split(/\r?\n/).map((q) => q.trim()).filter(Boolean);
  const panel = document.querySelector('.duo__panel--quote');
  if (!quotes.length) { panel?.remove(); $('siradaki')?.classList.add('duo--solo'); return; }
  const text = $('quoteText'), attr = $('quoteAttr');
  attr.textContent = `— ${playerName(p)}`;
  let i = Math.floor(Math.random() * quotes.length);
  text.textContent = `"${quotes[i]}"`;
  if (quotes.length > 1 && !REDUCED) {
    setInterval(() => {
      text.classList.add('is-fading');
      setTimeout(() => { i = (i + 1) % quotes.length; text.textContent = `"${quotes[i]}"`; text.classList.remove('is-fading'); }, 600);
    }, 8000);
  }
}

/** "Sıradaki perde": bilet koçanı biçiminde, canlı veriden en yakın seans. */
function renderNextUp(M) {
  const el = $('nextUp');
  const e = M.upcoming[0];
  if (!e) {
    el.innerHTML = `<p class="eyebrow">SIRADAKİ PERDE</p><h2 class="h2">Yeni seanslar <em>yakında.</em></h2>
      <p class="p">Takvim açıldığında ilk siz haber alın — bizi Instagram'dan takip edin.</p>
      <a class="btn btn--fill" href="https://www.instagram.com/tiyatrol_/" target="_blank" rel="noopener" data-cursor-hover>@tiyatrol_</a>`;
    return;
  }
  const s = e._show;
  const d = e._date;
  const price = priceLabel(e.price);
  el.innerHTML = `<p class="eyebrow">SIRADAKİ PERDE</p>
    <div class="stub">
      <div class="stub__main">
        ${s?.imageUrl ? `<img class="stub__img" src="${esc(s.imageUrl)}" alt="" loading="lazy" />` : ''}
        <div class="stub__info">
          <p class="stub__name">${esc(s?.name || 'Gösteri')}</p>
          ${e._stage?.name ? `<p class="stub__stage">${esc(e._stage.name)}</p>` : ''}
          ${price ? `<p class="stub__price">${esc(price)}</p>` : ''}
        </div>
      </div>
      <div class="stub__tear" aria-hidden="true"></div>
      <div class="stub__date"><span class="stub__day">${d.getDate()}</span><span>${esc(MONTHS_TR[d.getMonth()])}<br>${timeOf(d)}</span></div>
    </div>
    <div class="stub__actions">
      <a class="btn btn--fill" href="${s ? showHref(s) : '/vitrin'}" data-cursor-hover>Bilet Al</a>
      ${s ? `<a class="link-arrow" href="${showHref(s)}" data-cursor-hover>Oyunu incele</a>` : ''}
    </div>`;
}

/* ── Prömiyer arşivi: mediaLinks dolu her oyun bir sekme ── */
const mediaLinksOf = (show) => (Array.isArray(show?.mediaLinks) ? show.mediaLinks.filter((l) => l && l.url) : []);
const youtubeIdFromUrl = (url) => { const m = String(url || '').match(/(?:youtu\.be\/|[?&]v=|\/embed\/|\/shorts\/)([a-zA-Z0-9_-]{6,})/); return m ? m[1] : null; };
let CURRENT_AUDIO = null;
const fmtTime = (s) => (Number.isFinite(s) ? `${Math.floor(s / 60)}:${pad2(Math.floor(s % 60))}` : '0:00');
const ICO_PLAY = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M8 5v14l11-7z" fill="currentColor"/></svg>';
const ICO_PAUSE = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M7 5h4v14H7zM13 5h4v14h-4z" fill="currentColor"/></svg>';
/** Aynı anda tek ses/video: panelde açık ne varsa durdurulur, iframe'ler kaldırılır, posterler geri gelir. */
function stopAllMedia(panel) {
  if (CURRENT_AUDIO) { CURRENT_AUDIO.pause(); CURRENT_AUDIO = null; }
  panel.querySelectorAll('.mediashow.is-playing').forEach((w) => {
    w.querySelector('iframe, video')?.remove();
    w.classList.remove('is-playing');
    w.querySelector('.mediashow__btn')?.removeAttribute('hidden');
  });
}
function renderMediaStage(M) {
  const tabsEl = $('mediaTabs'), panelEl = $('mediaPanel');
  const entries = M.shows.map((show) => ({ show, links: mediaLinksOf(show) })).filter((e) => e.links.length);
  if (!entries.length) { hideSection('mediaarsivi'); return; }
  const isVideo = (l) => l.type === 'youtube' || youtubeIdFromUrl(l.url) || /\.(mp4|webm)(\?|$)/i.test(l.url || '');
  const metaFor = (links) => [links.some(isVideo) ? '▶ Video' : null, links.some((l) => l.type === 'audio') ? '♪ Ses' : null].filter(Boolean).join(' · ');

  function showPanel(i) {
    stopAllMedia(panelEl);
    const { show, links } = entries[i];
    panelEl.style.setProperty('--stage-bg', show.imageUrl ? cssUrl(show.imageUrl) : 'none');
    const cards = links.map((link) => {
      const title = esc(link.title || (link.type === 'audio' ? 'Sahne Sesi' : 'Video'));
      if (link.type === 'audio') {
        return `<div class="mediaplayer" data-src="${esc(link.url)}">
          <button type="button" class="mediaplayer__play" aria-label="Oynat: ${title}" aria-pressed="false">${ICO_PLAY}</button>
          <div class="mediaplayer__info">
            <p class="mediaplayer__title">${title}</p>
            <div class="mediaplayer__bars" aria-hidden="true"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="mediaplayer__track" aria-hidden="true"><i></i></div>
            <p class="mediaplayer__time" role="status"><span class="mp-state">Hazır</span><span class="mp-clock">0:00 / --:--</span></p>
          </div>
        </div>`;
      }
      const yt = youtubeIdFromUrl(link.url);
      const mp4 = /\.(mp4|webm)(\?|$)/i.test(link.url || '');
      if (yt || mp4) {
        const thumb = yt ? `background-image:url('https://img.youtube.com/vi/${yt}/hqdefault.jpg')` : '';
        return `<div class="mediashow" ${yt ? `data-yt="${esc(yt)}"` : `data-src="${esc(link.url)}"`} data-title="${title}">
          <button type="button" class="mediashow__btn" aria-label="Videoyu burada oynat: ${title}" data-cursor-hover>
            <span class="mediashow__thumb" style="${thumb}"></span>
            <span class="mediashow__play"><svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true"><path d="M8 5v14l11-7z" fill="currentColor"/></svg></span>
            <span class="mediashow__title">${title}</span>
          </button>
        </div>`;
      }
      // YouTube/mp4 olmayan kaynaklar (Vimeo, Instagram…) için yalnızca dış bağlantı
      return `<a class="mediashow mediashow--link" href="${esc(link.url)}" target="_blank" rel="noopener" data-cursor-hover>
        <span class="mediashow__title">${title} — Kaynakta aç ↗</span></a>`;
    }).join('');
    panelEl.innerHTML = `<div class="mediastage__head"><span class="mediastage__pill">${esc(show.name || '')}</span></div><div class="mediastage__cards">${cards}</div>`;

    // Video: yalnızca tıklayınca, aynı çerçevede (youtube-nocookie) — sayfa açılışında iframe yüklenmez.
    panelEl.querySelectorAll('.mediashow[data-yt], .mediashow[data-src]').forEach((wrap) => {
      wrap.querySelector('.mediashow__btn').addEventListener('click', (ev) => {
        stopAllMedia(panelEl);
        const title = wrap.dataset.title;
        const el = document.createElement(wrap.dataset.yt ? 'iframe' : 'video');
        if (wrap.dataset.yt) {
          el.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(wrap.dataset.yt)}?autoplay=1&rel=0&playsinline=1`;
          el.title = title.replace(/&[^;]+;/g, '');
          el.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
          el.allowFullscreen = true;
          el.loading = 'lazy';
          el.referrerPolicy = 'strict-origin-when-cross-origin';
        } else {
          el.src = wrap.dataset.src; el.controls = true; el.autoplay = true; el.playsInline = true;
        }
        el.className = 'mediashow__frame';
        wrap.append(el);
        wrap.classList.add('is-playing');
        ev.currentTarget.hidden = true;
        el.focus?.();
      });
    });

    // Ses
    panelEl.querySelectorAll('.mediaplayer').forEach((el) => {
      const audio = new Audio();
      audio.preload = 'none';
      audio.src = el.dataset.src;
      const btn = el.querySelector('.mediaplayer__play');
      const fill = el.querySelector('.mediaplayer__track i');
      const state = el.querySelector('.mp-state'), clock = el.querySelector('.mp-clock');
      const label = el.querySelector('.mediaplayer__title').textContent;
      const set = (cls, text, playing) => {
        el.classList.remove('is-playing', 'is-loading', 'is-error');
        if (cls) el.classList.add(cls);
        state.textContent = text;
        btn.innerHTML = playing ? ICO_PAUSE : ICO_PLAY;
        btn.setAttribute('aria-pressed', String(!!playing));
        btn.setAttribute('aria-label', `${playing ? 'Duraklat' : 'Oynat'}: ${label}`);
      };
      const tick = () => {
        const d = audio.duration;
        clock.textContent = `${fmtTime(audio.currentTime)} / ${Number.isFinite(d) ? fmtTime(d) : '--:--'}`;
        fill.style.transform = `scaleX(${Number.isFinite(d) && d > 0 ? audio.currentTime / d : 0})`;
      };
      btn.addEventListener('click', () => {
        if (el.classList.contains('is-error')) { audio.load(); }
        if (audio.paused) {
          stopAllMedia(panelEl);
          CURRENT_AUDIO = audio;
          set('is-loading', 'Yükleniyor…', true);
          audio.play().catch(() => set('is-error', 'Yüklenemedi', false));
        } else audio.pause();
      });
      audio.addEventListener('playing', () => set('is-playing', 'Çalıyor', true));
      audio.addEventListener('waiting', () => set('is-loading', 'Yükleniyor…', true));
      audio.addEventListener('pause', () => { if (!audio.ended && !el.classList.contains('is-error')) set('', 'Duraklatıldı', false); });
      audio.addEventListener('ended', () => { set('', 'Bitti', false); audio.currentTime = 0; tick(); });
      audio.addEventListener('error', () => set('is-error', 'Yüklenemedi', false));
      audio.addEventListener('timeupdate', tick);
      audio.addEventListener('loadedmetadata', tick);
    });
  }
  tabsEl.innerHTML = entries.map((e, i) => {
    const thumb = e.show.imageUrl ? `<img class="mediatab__thumb" src="${esc(e.show.imageUrl)}" alt="" />` : `<div class="mediatab__thumb mediatab__thumb--ph">${esc((e.show.name || '?')[0])}</div>`;
    return `<button type="button" class="mediatab${i === 0 ? ' is-active' : ''}" data-i="${i}">${thumb}<div class="mediatab__info"><p class="mediatab__name">${esc(e.show.name || '')}</p><p class="mediatab__meta">${metaFor(e.links)}</p></div></button>`;
  }).join('');
  tabsEl.querySelectorAll('.mediatab').forEach((btn) => btn.addEventListener('click', () => {
    tabsEl.querySelectorAll('.mediatab').forEach((b) => b.classList.toggle('is-active', b === btn));
    showPanel(Number(btn.dataset.i));
  }));
  showPanel(0);
}

/* ── Basın: alıntı yoksa uydurmak yerine "basın kiti" (gerçek logo, afiş, iletişim) ── */
function renderPress(M) {
  const grid = $('pressGrid');
  if (PRESS_MENTIONS.length) {
    $('pressTitle').textContent = 'Basında Biz';
    grid.innerHTML = PRESS_MENTIONS.map((p) => `<a class="press__card reveal" href="${esc(p.url || '#')}" target="_blank" rel="noopener" data-cursor-hover>
      <span class="press__outlet">${esc(p.outlet || '')}</span><p class="press__quote">"${esc(p.quote || '')}"</p></a>`).join('');
  } else grid.remove();
  const posters = M.shows.filter((s) => s.imageUrl).slice(0, 6);
  $('presskit').innerHTML = `
    <div class="presskit__logo"><img src="logo-mark.png" alt="TiyatRol logosu" width="96" height="96" loading="lazy" /></div>
    <div class="presskit__copy">
      <h3>Haber, röportaj ve tanıtım için</h3>
      <p>Logomuzu ve oyun afişlerimizi yayınlarınızda kullanabilirsiniz. Yüksek çözünürlüklü görsel, oyuncu röportajı ve prömiyer daveti için bize yazın.</p>
      <div class="presskit__actions">
        <a class="btn btn--fill" href="mailto:${CONTACT_MAIL}?subject=${encodeURIComponent('[Basın] TiyatRol')}" data-cursor-hover>Basın İletişimi</a>
        <a class="link-arrow" href="logo-mark.png" download="tiyatrol-logo.png" data-cursor-hover>Logoyu indir</a>
      </div>
    </div>
    ${posters.length ? `<ul class="presskit__posters" aria-label="Oyun afişleri">${posters.map((s) => `<li><a href="${esc(s.imageUrl)}" target="_blank" rel="noopener" aria-label="${esc(s.name)} afişi (yeni sekmede açılır)" data-cursor-hover><img src="${esc(s.imageUrl)}" alt="${esc(s.name)} afişi" loading="lazy" /></a></li>`).join('')}</ul>` : ''}`;
}

/* ── Ödüller: yalnızca Player.achievements'taki gerçek kayıtlar (+ elle eklenenler) ── */
function renderAwards(M) {
  const items = [...AWARDS];
  M.players.forEach((p) => parseList(p.achievements).forEach((a) => {
    if (a && (a.title || a.detail)) items.push({ year: a.year, title: a.title || a.detail, note: a.title ? a.detail : '', who: playerName(p) });
  }));
  if (!items.length) { hideSection('oduller'); return; }
  items.sort((a, b) => Number(b.year || 0) - Number(a.year || 0));
  $('awardsList').innerHTML = items.map((a) => `<div class="awards__item reveal">
    <span class="awards__year">${esc(a.year || '★')}</span>
    <div><p class="awards__title">${esc(a.title)}</p>${a.note ? `<p class="awards__note">${esc(a.note)}</p>` : ''}${a.who ? `<p class="awards__who">${esc(a.who)}</p>` : ''}</div>
  </div>`).join('');
}

function renderBlog() {
  if (!BLOG_POSTS.length) { hideSection('blog'); return; }
  $('blogGrid').innerHTML = BLOG_POSTS.map((post) => `<a class="blog__card reveal" href="${esc(post.url || '#')}" data-cursor-hover>
    <span class="blog__date">${esc(post.date || '')}</span><h3 class="blog__title">${esc(post.title || '')}</h3>
    <p class="blog__excerpt">${esc(post.excerpt || '')}</p><span class="link-arrow">Devamını Oku</span></a>`).join('');
}
function renderWorkshops() {
  if (!WORKSHOPS.length) { hideSection('atolyeler'); return; }
  $('workshopsGrid').innerHTML = WORKSHOPS.map((w) => `<a class="workshop__card reveal" href="${esc(w.url || '#')}" data-cursor-hover>
    <span class="workshop__date">${esc(w.date || '')}</span><h3 class="workshop__title">${esc(w.title || '')}</h3>${w.desc ? `<p class="workshop__desc">${esc(w.desc)}</p>` : ''}</a>`).join('');
}

/* Instagram'dan otomatik çekim YOK (kullanım şartları); galerideki gerçek fotoğraflar gerçek profile bağlanır. */
const HEART = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M12 20.5s-7.5-4.6-9.8-9.2C.6 7.8 2.3 4.5 5.6 4c2-.3 3.7.6 4.9 2.3L12 8l1.5-1.7c1.2-1.7 2.9-2.6 4.9-2.3 3.3.5 5 3.8 3.4 7.3-2.3 4.6-9.8 9.2-9.8 9.2z"/></svg>';
function renderInstagram(M) {
  const photos = M.shows.flatMap((s) => (s.photosShowId || []).filter(Boolean).map((url) => ({ url, name: s.name })));
  if (!photos.length) { hideSection('instagram'); return; }
  const step = Math.max(1, Math.floor(photos.length / 8));
  const pick = Array.from({ length: Math.min(8, photos.length) }, (_, i) => photos[(i * step + 3) % photos.length]);
  $('instaGrid').innerHTML = pick.map(({ url, name }) => `<a class="insta__card reveal" href="https://www.instagram.com/tiyatrol_/" target="_blank" rel="noopener" aria-label="Instagram profilimiz (yeni sekmede açılır)" data-cursor-hover>
      <div class="insta__head"><img class="insta__avatar" src="logo-mark.png" alt="" /><span class="insta__handle">tiyatrol_</span></div>
      <div class="insta__photo"><img src="${esc(url)}" alt="" loading="lazy" /></div>
      <div class="insta__foot"><span class="insta__ico">${HEART}</span><span class="insta__cap">#${esc((name || 'tiyatrol').toLowerCase().replace(/[^a-z0-9ğüşıöç]+/g, ''))}</span></div>
    </a>`).join('');
}

/* ───────────────────────── Sayfa iskeleti ───────────────────────── */
function initChrome() {
  $('year').textContent = new Date().getFullYear();
  const fine = window.matchMedia('(hover:hover) and (pointer:fine)').matches;

  // Özel imleç: yalnızca ince imleçlerde ve sadece hareket ederken çizilir (boşta döngü yok).
  if (fine && !REDUCED) {
    const dot = document.querySelector('.cursor-dot'), ring = document.querySelector('.cursor-ring');
    let mx = -100, my = -100, rx = -100, ry = -100, running = false;
    const loop = () => {
      rx += (mx - rx) * 0.2; ry += (my - ry) * 0.2;
      ring.style.transform = `translate(${rx}px, ${ry}px) translate(-50%,-50%)`;
      if (Math.abs(mx - rx) + Math.abs(my - ry) > 0.5) requestAnimationFrame(loop); else running = false;
    };
    window.addEventListener('pointermove', (e) => {
      mx = e.clientX; my = e.clientY;
      dot.style.transform = `translate(${mx}px, ${my}px) translate(-50%,-50%)`;
      if (!running) { running = true; requestAnimationFrame(loop); }
    }, { passive: true });
    document.body.addEventListener('mouseover', (e) => ring.classList.toggle('is-hover', !!e.target.closest('[data-cursor-hover]')));
  }

  const bar = $('progressBar'), nav = $('nav');
  let ticking = false;
  const onScroll = () => {
    ticking = false;
    const h = document.documentElement;
    const max = h.scrollHeight - h.clientHeight;
    bar.style.transform = `scaleX(${max > 0 ? h.scrollTop / max : 0})`;
    nav.classList.toggle('is-scrolled', h.scrollTop > 30);
  };
  window.addEventListener('scroll', () => { if (!ticking) { ticking = true; requestAnimationFrame(onScroll); } }, { passive: true });
  onScroll();

  const burger = $('burger'), mnav = $('mnav');
  const setMenu = (open) => {
    mnav.classList.toggle('is-open', open);
    mnav.inert = !open;
    burger.setAttribute('aria-expanded', String(open));
    burger.setAttribute('aria-label', open ? 'Menüyü kapat' : 'Menüyü aç');
    document.body.classList.toggle('is-locked', open);
  };
  burger.addEventListener('click', () => setMenu(!mnav.classList.contains('is-open')));
  mnav.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => setMenu(false)));
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && mnav.classList.contains('is-open')) { setMenu(false); burger.focus(); } });

  // Form yalnızca kullanıcının e-posta uygulamasını açar — sitede veri saklanmaz/gönderilmez.
  $('contactForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const f = e.target;
    const body = `Gönderen: ${f.name.value.trim()} (${f.email.value.trim()})\n\n${f.message.value.trim()}`;
    window.location.href = `mailto:${CONTACT_MAIL}?subject=${encodeURIComponent(`[${f.subject.value}] ${f.name.value.trim()}`)}&body=${encodeURIComponent(body)}`;
  });

  // Hareket azaltma: hero videosu durur.
  if (REDUCED) { const v = $('heroVideo'); if (v) { v.removeAttribute('autoplay'); v.pause(); } }

  // Sayaç
  const stats = document.querySelector('.stats');
  if (stats && !REDUCED) {
    const io = new IntersectionObserver((entries) => {
      if (!entries.some((x) => x.isIntersecting)) return;
      io.disconnect();
      document.querySelectorAll('.stat__num').forEach((el) => {
        const target = Number(el.dataset.target || 0);
        const t0 = performance.now();
        (function tick(now) {
          const t = Math.min(1, (now - t0) / 1300);
          el.textContent = Math.round((1 - Math.pow(1 - t, 3)) * target);
          if (t < 1) requestAnimationFrame(tick);
        })(t0);
      });
    }, { threshold: 0.4 });
    io.observe(stats);
  } else document.querySelectorAll('.stat__num').forEach((el) => { el.textContent = el.dataset.target; });
}

/* ── Reveal: render sonrası eklenen kartlar için yeniden gözlenebilir ── */
let REVEAL_IO = null;
function observeReveals(root = document) {
  const els = root.querySelectorAll('.reveal:not(.in), .wipe:not(.in)');
  if (REDUCED || !('IntersectionObserver' in window)) { els.forEach((el) => el.classList.add('in')); return; }
  REVEAL_IO ||= new IntersectionObserver((entries) => {
    entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add('in'); REVEAL_IO.unobserve(en.target); } });
  }, { threshold: 0.12 });
  els.forEach((el) => REVEAL_IO.observe(el));
}
function initReveal() {
  observeReveals(document);
  // Güvence: hızlı kaydırma/anchor atlamasında gözlemcinin kaçırdığı, ekranın üstünde kalmış öğeleri de aç.
  let t = 0;
  window.addEventListener('scroll', () => {
    clearTimeout(t);
    t = setTimeout(() => {
      document.querySelectorAll('.reveal:not(.in), .wipe:not(.in)').forEach((el) => {
        if (el.getBoundingClientRect().top < window.innerHeight * 0.9) { el.classList.add('in'); REVEAL_IO?.unobserve(el); }
      });
    }, 150);
  }, { passive: true });
}

/* ── Mikro-etkileşimler ── */
function initSpotlight(root = document) {
  if (!window.matchMedia('(hover:hover)').matches) return;
  root.querySelectorAll('.show, .player__ring').forEach((el) => {
    if (el.dataset.spot) return;
    el.dataset.spot = '1';
    el.addEventListener('pointermove', (e) => {
      const r = el.getBoundingClientRect();
      el.style.setProperty('--mx', `${((e.clientX - r.left) / r.width) * 100}%`);
      el.style.setProperty('--my', `${((e.clientY - r.top) / r.height) * 100}%`);
    });
  });
}
function initInteractions() {
  initSpotlight();
  // Afiş <-> galeri karesi: dokunmatikte basılı tutarken gösterilir (masaüstünde CSS :hover).
  document.querySelectorAll('.show[data-swap]').forEach((el) => {
    const on = () => el.classList.add('is-active'), off = () => el.classList.remove('is-active');
    el.addEventListener('pointerdown', on); el.addEventListener('pointerup', off); el.addEventListener('pointerleave', off); el.addEventListener('pointercancel', off);
  });
  if (!REDUCED && window.matchMedia('(hover:hover) and (pointer:fine)').matches) {
    document.querySelectorAll('.btn').forEach((el) => {
      el.addEventListener('pointermove', (e) => {
        const r = el.getBoundingClientRect();
        el.style.transform = `translate(${((e.clientX - (r.left + r.width / 2)) * 0.2).toFixed(1)}px, ${((e.clientY - (r.top + r.height / 2)) * 0.2).toFixed(1)}px)`;
      });
      el.addEventListener('pointerleave', () => { el.style.transform = ''; });
    });
  }
}

initChrome();
boot().catch((err) => console.error('Ana sayfa yüklenemedi:', err));

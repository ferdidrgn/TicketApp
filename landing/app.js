/* ═══════════════ FIREBASE — hafif REST okuma (Flutter web ile aynı proje)
   Tek seferlik okuma yaptığımız için ağır Firestore JS SDK'sı yerine
   doğrudan Firestore REST API'sine HTTPS GET atıyoruz. API key herkese
   açık, istemci tarafı bir anahtardır (Flutter uygulamasında da aynısı
   kullanılıyor); gerçek güvenlik Firestore Security Rules ile sağlanır. */
const FIREBASE_PROJECT_ID = 'ticketappflutter';
const FIREBASE_API_KEY = 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;

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

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[c]));

/* Flutter uygulamasındaki StringSlug.toSlug() ile birebir aynı mantık —
 * oyun/oyuncu kartları /app içindeki gerçek detay sayfasına gitsin diye. */
function toSlugTr(str) {
  return String(str ?? '')
    .toLowerCase()
    .replaceAll(' ', '-')
    .replaceAll('ş', 's').replaceAll('ı', 'i').replaceAll('ç', 'c')
    .replaceAll('ö', 'o').replaceAll('ü', 'u').replaceAll('ğ', 'g')
    .replace(/[^a-z0-9-]/g, '');
}
const showHref = (s) => `/app/show/${toSlugTr(s.name)}-${s.id}`;
const playerHref = (p) => `/app/player/${toSlugTr(`${p.firstName ?? ''} ${p.lastName ?? ''}`)}-${p.id}`;

async function fetchCollection(name, max = 300) {
  try {
    const url = `${FIRESTORE_BASE}/${name}?key=${FIREBASE_API_KEY}&pageSize=${max}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    return (json.documents || []).map((d) => ({ id: d.name.split('/').pop(), ...unwrapFields(d.fields || {}) }));
  } catch (err) {
    console.error(`Firestore okuma hatası (${name}):`, err);
    return [];
  }
}

/* ── Tarih ayrıştırma: "dd.MM.yyyy, HH:mm" — Flutter'daki DateFormatter
 * ile aynı normalize mantığı (virgül sonrası boşluk olsun/olmasın). ── */
function parseEventDate(raw) {
  if (!raw) return null;
  const norm = raw.trim().replace(/,\s*/, ' ');
  const m = norm.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})$/);
  if (!m) return null;
  const [d, mo, y, h, mi] = m.slice(1).map(Number);
  const date = new Date(y, mo - 1, d, h, mi);
  return Number.isNaN(date.getTime()) ? null : date;
}

const MONTHS_TR = ['OCAK','ŞUBAT','MART','NİSAN','MAYIS','HAZİRAN','TEMMUZ','AĞUSTOS','EYLÜL','EKİM','KASIM','ARALIK'];

function formatDateTr(date) {
  const time = `${String(date.getHours()).padStart(2,'0')}:${String(date.getMinutes()).padStart(2,'0')}`;
  const m = MONTHS_TR[date.getMonth()];
  return `${date.getDate()} ${m[0]}${m.slice(1).toLowerCase()} ${date.getFullYear()}, ${time}`;
}

function upcomingEvents(events) {
  const now = new Date();
  return events
    .map((e) => ({ ...e, _date: parseEventDate(e.date) }))
    .filter((e) => e._date && e._date >= now)
    .sort((a, b) => a._date - b._date);
}

/** Küratör kararı: kadro bölümünde sahnede olan (repertuardaki ilk) oyunun
 * kadrosu gösterilir. Eşleşen oyuncu yoksa tüm kadroya düşülür. */
function curatedCast(shows, players) {
  const lead = shows[0];
  if (!lead) return players;
  const ids = new Set([...(lead.nowPlayersId || []), ...(lead.oldPlayersId || [])].filter(Boolean));
  if (!ids.size) return players;
  const filtered = players.filter((p) => ids.has(p.id));
  return filtered.length ? filtered : players;
}

/** Repertuar sıralaması: Metafor > Göz Kap Vaz Yap > Kurtar Beni Doktor >
 * diğerleri > Kadınlık Bizde Kalsın (prömiyer, en sonda vitrin). */
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

/** Firestore'daki Event dokümanlarında showId alanı YOK — ilişki tersten:
 * her Show kendi etkinlik ID'lerini eventsId dizisinde tutuyor. Bu yüzden
 * eventId -> show eşlemesini Show.eventsId üzerinden kuruyoruz. */
function showByEventIdMap(shows) {
  const map = {};
  shows.forEach((s) => (s.eventsId || []).forEach((eventId) => { map[eventId] = s; }));
  return map;
}

const FOUNDING_YEAR = 2018;

async function boot() {
  const [showsRaw, players, stages, events] = await Promise.all([
    fetchCollection('Show'),
    fetchCollection('Player'),
    fetchCollection('Stage'),
    fetchCollection('Event'),
  ]);
  const shows = sortRepertoire(showsRaw);

  setStat(0, shows.length);
  setStat(1, players.length);
  setStat(2, stages.length);
  setStat(3, new Date().getFullYear() - FOUNDING_YEAR);

  renderHero(shows, events, stages);
  renderMarquee(shows);
  renderAbout(shows, players);
  renderPitchNoop();
  renderRepertoire(shows);
  renderTeam(curatedCast(shows, players), shows);
  renderCalendar(events, shows);
  renderGallery(shows);
  renderVenues(stages);
  renderPremiere(shows);
  renderQuote(players);
  initChrome();
  initReveal();
  initCalendarTabs(events, shows);
  initInteractions();
}

function setStat(i, v) {
  const el = document.querySelectorAll('.stat__num')[i];
  if (el) el.dataset.target = v;
}

function renderHero(shows, events, stages) {
  const el = document.getElementById('heroStatus');
  const next = upcomingEvents(events)[0];
  if (next) {
    const show = showByEventIdMap(shows)[next.id];
    const stage = stages.find((st) => st.id === next.stageId);
    const parts = [`${show?.name || 'Yaklaşan gösteri'} — ${formatDateTr(next._date)}`];
    if (stage?.name) parts.push(stage.name);
    el.textContent = parts.join(' · ');
  } else if (shows.length) {
    el.textContent = `Repertuarda ${shows.length} oyun sahneleniyor.`;
  } else {
    el.textContent = 'Yeni sezon hazırlanıyor.';
  }
}

function renderMarquee(shows) {
  const row = document.getElementById('marqueeRow');
  const names = shows.length ? shows.map((s) => s.name).filter(Boolean) : ['TiyatRol Sahne Sanatları'];
  const html = names.map((n) => `<span class="marquee__item">${esc(n)} <span>✦</span></span>`).join('');
  row.innerHTML = html + html;
}

function renderAbout(shows, players) {
  const art = document.getElementById('aboutArt');
  const img1 = shows.find((s) => s.imageUrl)?.imageUrl;
  const img2 = players.find((p) => p.imageUrl)?.imageUrl;
  if (img1) art.style.setProperty('--about-img-1', `url("${img1}")`);
  if (img2) art.style.setProperty('--about-img-2', `url("${img2}")`);
  if (!img1 && !img2) art.style.display = 'none';
}

function renderPitchNoop() { /* Pitch bölümü statik (sabit) metin içerir — uydurma veri değil, marka konumlandırması. */ }

/** Varsayılan görsel: afiş (imageUrl) — fare/parmak geldiğinde galeriden
 * RASTGELE seçilmiş gerçek bir sahne fotoğrafına geçilir ve özet alttan
 * yukarı kayar. Galeri boşsa tek katman (afiş) gösterilir. */
function renderRepertoire(shows) {
  const grid = document.getElementById('repertoireGrid');
  if (!shows.length) { grid.innerHTML = `<div class="empty">Repertuar yakında burada.</div>`; return; }
  grid.innerHTML = shows.map((s) => {
    const name = esc(s.name || 'İsimsiz Oyun');
    const desc = esc(s.description || '');
    const cat = esc(s.category || 'Tiyatro');
    const duration = esc(s.duration || '');
    const age = esc(s.ageLimit || '');
    const gallery = (s.photosShowId || []).filter(Boolean);
    const randomShot = gallery.length ? gallery[Math.floor(Math.random() * gallery.length)] : '';
    const primary = s.imageUrl || randomShot || '';
    const secondary = randomShot && randomShot !== primary ? randomShot : '';

    const imgLayers = primary
      ? `<img class="show__img show__img--primary" src="${esc(primary)}" alt="${name}" loading="lazy" />`
      : `<div class="show__img show__img--ph">${name}</div>`;
    const secondaryLayer = secondary
      ? `<img class="show__img show__img--secondary" src="${esc(secondary)}" alt="${name}" loading="lazy" />`
      : '';

    return `<a class="show reveal" href="${showHref(s)}" data-swap>
      ${imgLayers}
      ${secondaryLayer}
      <div class="show__shade"></div>
      <span class="show__cat">${cat}</span>
      <div class="show__body">
        <p class="show__name">${name}</p>
        ${desc ? `<p class="show__desc">${desc}</p>` : ''}
        <div class="show__meta">${duration ? `<span>${duration}</span>` : ''}${age ? `<span>${age}+</span>` : ''}</div>
      </div>
    </a>`;
  }).join('');
}

function renderTeam(players, shows) {
  const rail = document.getElementById('teamRail');
  const sub = document.getElementById('teamSub');
  if (shows[0]?.name) sub.textContent = `Şu an sahnede olan "${shows[0].name}" oyununun kadrosuyla tanışın.`;
  if (!players.length) { rail.innerHTML = `<div class="empty empty--light">Kadro bilgileri yakında burada.</div>`; return; }
  rail.innerHTML = players.map((p) => {
    const name = esc(`${p.firstName ?? ''} ${p.lastName ?? ''}`.trim() || 'İsimsiz Sanatçı');
    const quote = p.quote ? esc(p.quote) : '';
    const img = p.imageUrl
      ? `<img class="player__img" src="${esc(p.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="player__img player__img--ph">${esc((p.firstName || '?')[0] || '?')}</div>`;
    return `<a class="player reveal" href="${playerHref(p)}">
      <div class="player__ring">${img}</div>
      <p class="player__name">${name}</p>
      ${quote ? `<p class="player__quote">"${quote}"</p>` : ''}
    </a>`;
  }).join('');
}

let CAL_EVENTS = [];
let CAL_SHOWS = [];
let CAL_SHOW_MAP = {};
let CAL_MONTH = new Date().getMonth();
let CAL_YEAR = new Date().getFullYear();

function renderCalendar(events, shows) {
  CAL_EVENTS = events;
  CAL_SHOWS = shows;
  CAL_SHOW_MAP = showByEventIdMap(shows);
  renderCalendarRow();
}

function initCalendarTabs() {
  const wrap = document.getElementById('calTabs');
  wrap.innerHTML = MONTHS_TR.map((m, i) => `<button type="button" class="mtab${i === CAL_MONTH ? ' is-active' : ''}" data-m="${i}">${m}</button>`).join('');
  wrap.querySelectorAll('.mtab').forEach((btn) => btn.addEventListener('click', () => {
    CAL_MONTH = Number(btn.dataset.m);
    wrap.querySelectorAll('.mtab').forEach((b) => b.classList.toggle('is-active', b === btn));
    renderCalendarRow();
  }));
}

function renderCalendarRow() {
  const row = document.getElementById('calRow');
  const monthTitle = document.getElementById('calMonth');
  monthTitle.textContent = `${MONTHS_TR[CAL_MONTH]} ${CAL_YEAR}`;

  const inMonth = CAL_EVENTS
    .map((e) => ({ ...e, _date: parseEventDate(e.date) }))
    .filter((e) => e._date && e._date.getMonth() === CAL_MONTH && e._date.getFullYear() === CAL_YEAR)
    .sort((a, b) => a._date - b._date);

  if (!inMonth.length) { row.innerHTML = `<div class="empty">Bu ayda planlanmış bir etkinlik yok.</div>`; return; }

  row.innerHTML = inMonth.map((e) => {
    const show = CAL_SHOW_MAP[e.id];
    const name = esc(show?.name || 'Gösteri');
    const img = show?.imageUrl
      ? `<img class="ticket__img" src="${esc(show.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="ticket__img--ph">${name}</div>`;
    const time = `${String(e._date.getHours()).padStart(2,'0')}:${String(e._date.getMinutes()).padStart(2,'0')}`;
    return `<div class="ticket">
      ${img}
      <div class="ticket__notch"></div>
      <div class="ticket__body">
        <div class="ticket__date"><span class="ticket__day">${e._date.getDate()}</span><span class="ticket__rest">${MONTHS_TR[e._date.getMonth()]}<br>${time}</span></div>
        <p class="ticket__name">${name}</p>
      </div>
    </div>`;
  }).join('');
}

function renderGallery(shows) {
  const wall = document.getElementById('galleryWall');
  const photos = [];
  shows.forEach((s) => (s.photosShowId || []).forEach((url) => { if (url) photos.push({ url, name: s.name }); }));
  if (!photos.length) { wall.innerHTML = `<div class="empty">Galeri yakında burada.</div>`; return; }
  const shuffled = photos.map((p, i) => ({ p, sort: Math.sin(i * 999) })).sort((a, b) => a.sort - b.sort).map((x) => x.p).slice(0, 24);
  wall.innerHTML = shuffled.map((p) => `<div class="gallery__item reveal"><img src="${esc(p.url)}" alt="${esc(p.name || '')}" loading="lazy" /></div>`).join('');
}

function renderVenues(stages) {
  const grid = document.getElementById('venuesGrid');
  if (!stages.length) { grid.innerHTML = `<div class="empty empty--light">Sahne bilgileri yakında burada.</div>`; return; }
  grid.innerHTML = stages.map((s) => {
    const name = esc(s.name || 'İsimsiz Sahne');
    const addr = esc(s.address || '');
    const cap = esc(s.capacity || '');
    const img = s.imageUrl
      ? `<img class="venue__img" src="${esc(s.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="venue__img venue__img--ph">${name}</div>`;
    return `<div class="venue reveal">
      ${img}
      <div class="venue__shade"></div>
      <div class="venue__body">
        <p class="venue__name">${name}</p>
        ${addr ? `<p class="venue__addr">${addr}</p>` : ''}
        ${cap ? `<p class="venue__cap">${cap} Kişi Kapasiteli</p>` : ''}
      </div>
    </div>`;
  }).join('');
}

const KADINLIK_YT_ID = 'joEK2NmpwuM';
const KADINLIK_YT_URL = `https://www.youtube.com/watch?v=${KADINLIK_YT_ID}&t=699s`;
const KADINLIK_AUDIO_URL = 'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/voices%2Fgoz_kap_vaz_yap_bakirkoyde_hastane.mp3?alt=media&token=deb93736-6fd8-45eb-8c8b-8a8f298e5b14';

/** Prömiyer bölümü: "Kadınlık Bizde Kalsın" gerçek Show kaydı varsa afişi ve
 * tanıtımı ondan çeker; YouTube fragmanı ve ses kaydı sabit medya olarak
 * eklenir (ikisi de gerçek, verdiğiniz linkler). */
function renderPremiere(shows) {
  const section = document.getElementById('premiere');
  if (!section) return;
  const show = shows.find((s) => (s.name || '').toLowerCase().includes('kadınlık'));
  const poster = document.getElementById('premierePoster');
  const title = document.getElementById('premiereTitle');
  const desc = document.getElementById('premiereDesc');

  title.textContent = show?.name || 'Kadınlık Bizde Kalsın';
  desc.textContent = show?.description || 'Prömiyer öncesi tanıtım fragmanımızı izleyin ve sahne sesimizi dinleyin.';
  if (show?.imageUrl) poster.style.setProperty('--premiere-img', `url("${esc(show.imageUrl)}")`);

  const ytThumb = document.getElementById('premiereYtThumb');
  if (ytThumb) ytThumb.style.backgroundImage = `url("https://img.youtube.com/vi/${KADINLIK_YT_ID}/hqdefault.jpg")`;
  const ytLink = document.getElementById('premiereYtLink');
  if (ytLink) ytLink.href = KADINLIK_YT_URL;
  const audio = document.getElementById('premiereAudio');
  if (audio) audio.src = KADINLIK_AUDIO_URL;
}

function renderQuote(players) {
  const withQuote = players.filter((p) => p.quote && p.quote.trim());
  if (!withQuote.length) return;
  const p = withQuote[Math.floor(Math.random() * withQuote.length)];
  document.getElementById('quoteText').textContent = `"${p.quote.trim()}"`;
  document.getElementById('quoteAttr').textContent = `— ${p.firstName ?? ''} ${p.lastName ?? ''}`.trim();
}

/* ── Sayfa iskeleti: nav, scroll progress, mobil menü, sayaç, yıl, form ── */
function initChrome() {
  document.getElementById('year').textContent = new Date().getFullYear();

  // Özel imleç (dokunmatik cihazlarda CSS ile gizleniyor)
  const cursorDot = document.querySelector('.cursor-dot');
  const cursorRing = document.querySelector('.cursor-ring');
  let mouseX = -100, mouseY = -100, ringX = -100, ringY = -100;
  window.addEventListener('pointermove', (e) => {
    mouseX = e.clientX; mouseY = e.clientY;
    cursorDot.style.transform = `translate(${mouseX}px, ${mouseY}px) translate(-50%,-50%)`;
  });
  (function animateRing() {
    ringX += (mouseX - ringX) * 0.18;
    ringY += (mouseY - ringY) * 0.18;
    cursorRing.style.transform = `translate(${ringX}px, ${ringY}px) translate(-50%,-50%)`;
    requestAnimationFrame(animateRing);
  })();
  document.body.addEventListener('mouseover', (e) => {
    cursorRing.classList.toggle('is-hover', !!e.target.closest('[data-cursor-hover]'));
  });

  const bar = document.getElementById('progressBar');
  const nav = document.getElementById('nav');
  window.addEventListener('scroll', () => {
    const h = document.documentElement;
    bar.style.width = `${(h.scrollTop / (h.scrollHeight - h.clientHeight)) * 100}%`;
    nav.classList.toggle('is-scrolled', h.scrollTop > 30);
  }, { passive: true });

  const burger = document.getElementById('burger');
  const mnav = document.getElementById('mnav');
  burger.addEventListener('click', () => mnav.classList.toggle('is-open'));
  mnav.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => mnav.classList.remove('is-open')));

  document.getElementById('contactForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const f = e.target;
    const body = `Gönderen: ${f.name.value.trim()} (${f.email.value.trim()})\n\n${f.message.value.trim()}`;
    // Not: Kurumsal e-posta alınana kadar geçici olarak buraya düşüyor —
    // adres kullanıcıya görünür metin olarak gösterilmiyor, sadece mailto
    // bağlantısının arkasında (form gönderildiğinde açılan e-posta istemcisinde).
    window.location.href = `mailto:ferdidurgun34@gmail.com?subject=${encodeURIComponent(`[${f.subject.value}] ${f.name.value.trim()}`)}&body=${encodeURIComponent(body)}`;
  });

  const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      document.querySelectorAll('.stat__num').forEach((el) => {
        const target = Number(el.dataset.target || 0);
        const start = performance.now();
        const dur = 1300;
        (function tick(now) {
          const t = Math.min(1, (now - start) / dur);
          el.textContent = Math.round((1 - Math.pow(1 - t, 3)) * target);
          if (t < 1) requestAnimationFrame(tick);
        })(start);
      });
      statsObserver.unobserve(entry.target);
    });
  }, { threshold: .4 });
  const statsSection = document.querySelector('.stats');
  if (statsSection) statsObserver.observe(statsSection);

  (function grain() {
    const canvas = document.getElementById('fx');
    const ctx = canvas.getContext('2d');
    function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
    resize();
    window.addEventListener('resize', resize);
    function draw() {
      const imageData = ctx.createImageData(canvas.width, canvas.height);
      const buf = new Uint32Array(imageData.data.buffer);
      for (let i = 0; i < buf.length; i++) if (Math.random() < .5) buf[i] = 0xff000000 | (Math.random() * 0xffffff);
      ctx.putImageData(imageData, 0, 0);
    }
    draw();
    setInterval(draw, 100);
  })();
}

/* ── Yeni DOM'a eklenen kartlar innerHTML ile SONRADAN geldiği için,
 * reveal gözlemcisini veri render edildikten sonra kurup mevcut
 * .reveal elemanlarını tarıyoruz (ilk yüklemede boş kalmasın diye). ── */
function initReveal() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) { entry.target.classList.add('in'); observer.unobserve(entry.target); }
    });
  }, { threshold: .12 });
  document.querySelectorAll('.reveal').forEach((el) => observer.observe(el));
}

/* ── Mikro-etkileşimler: kartlar innerHTML ile SONRADAN render edildiği
 * için veriler ekrana bastıktan sonra çağrılır. ── */
function applySpotlight(el) {
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect();
    el.style.setProperty('--mx', `${((e.clientX - r.left) / r.width) * 100}%`);
    el.style.setProperty('--my', `${((e.clientY - r.top) / r.height) * 100}%`);
  });
}

function applyMagnetic(el, strength = 0.28) {
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect();
    const dx = (e.clientX - (r.left + r.width / 2)) * strength;
    const dy = (e.clientY - (r.top + r.height / 2)) * strength;
    el.style.transition = 'transform .12s linear';
    el.style.transform = `translate(${dx.toFixed(1)}px, ${dy.toFixed(1)}px)`;
  });
  el.addEventListener('pointerleave', () => {
    el.style.transition = 'transform .5s var(--ease)';
    el.style.transform = 'translate(0,0)';
  });
}

function initInteractions() {
  document.querySelectorAll('.show, .player__ring').forEach((el) => applySpotlight(el));
  document.querySelectorAll('.btn').forEach((el) => applyMagnetic(el));

  // Afiş <-> ilk galeri görseli geçişi: masaüstünde CSS :hover, dokunmatikte
  // basılı tutulduğu sürece .is-active — Flutter uygulamasındaki oyun kartı
  // davranışıyla aynı (bas -> afiş+özet görünür, bırak -> detay sayfasına git).
  document.querySelectorAll('.show[data-swap]').forEach((el) => {
    const on = () => el.classList.add('is-active');
    const off = () => el.classList.remove('is-active');
    el.addEventListener('pointerdown', on);
    el.addEventListener('pointerup', off);
    el.addEventListener('pointerleave', off);
  });
}

boot();

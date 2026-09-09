/* ═══════════════ FIREBASE — hafif REST okuma (Flutter web ile aynı proje)
   Sadece TEK SEFERLİK okuma yapıyoruz (canlı dinleme yok), bu yüzden ağır
   Firestore JS SDK'sını (WebChannel/streaming) yüklemek yerine doğrudan
   Firestore REST API'sine düz bir HTTPS GET atıyoruz — daha hafif, daha
   hızlı ve kurumsal ağlar/proxy'ler arkasında da (streaming bağlantılar
   engellenebildiği için) çok daha güvenilir. API key zaten herkese açık,
   istemci tarafı bir anahtardır (Flutter uygulamasında da aynısı kullanılıyor);
   gerçek güvenlik Firestore Security Rules ile sağlanıyor. ═══════════════ */
const FIREBASE_PROJECT_ID = 'ticketappflutter';
const FIREBASE_API_KEY = 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;

/** Firestore REST'in tipli alan formatını ({stringValue:'x'} vb.) düz JS değerine çevirir. */
function unwrapFirestoreValue(value) {
  if (value == null) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(unwrapFirestoreValue);
  if ('mapValue' in value) return unwrapFirestoreFields(value.mapValue.fields || {});
  return null;
}
function unwrapFirestoreFields(fields) {
  const out = {};
  for (const key of Object.keys(fields || {})) out[key] = unwrapFirestoreValue(fields[key]);
  return out;
}

/* ═══════════════ GÜVENLİ METİN YARDIMCISI (XSS'e karşı) ═══════════════ */
const esc = (str) => String(str ?? '').replace(/[&<>"']/g, (c) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[c]));

/* ═══════════════ ÖZEL İMLEÇ ═══════════════ */
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
document.querySelectorAll('[data-cursor-hover]').forEach((el) => {
  el.addEventListener('mouseenter', () => cursorRing.classList.add('is-hover'));
  el.addEventListener('mouseleave', () => cursorRing.classList.remove('is-hover'));
});

/* ═══════════════ GRAIN DOKUSU (canvas, hafif) ═══════════════ */
(function grain() {
  const canvas = document.getElementById('grain');
  const ctx = canvas.getContext('2d');
  function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
  resize();
  window.addEventListener('resize', resize);
  function draw() {
    const w = canvas.width, h = canvas.height;
    const imageData = ctx.createImageData(w, h);
    const buffer = new Uint32Array(imageData.data.buffer);
    for (let i = 0; i < buffer.length; i++) {
      if (Math.random() < 0.5) buffer[i] = 0xff000000 | (Math.random() * 0xffffff);
    }
    ctx.putImageData(imageData, 0, 0);
  }
  draw();
  setInterval(draw, 90);
})();

/* ═══════════════ SCROLL PROGRESS + NAV ═══════════════ */
const progressFill = document.querySelector('.scroll-progress__fill');
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  const h = document.documentElement;
  const scrolled = (h.scrollTop) / (h.scrollHeight - h.clientHeight) * 100;
  progressFill.style.width = `${scrolled}%`;
  nav.classList.toggle('is-scrolled', h.scrollTop > 40);
}, { passive: true });

/* ═══════════════ MOBİL MENÜ ═══════════════ */
const burger = document.getElementById('burger');
const mobileMenu = document.getElementById('mobileMenu');
burger.addEventListener('click', () => mobileMenu.classList.toggle('is-open'));
mobileMenu.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => mobileMenu.classList.remove('is-open')));

/* ═══════════════ HERO GİRİŞ ANİMASYONU ═══════════════ */
requestAnimationFrame(() => requestAnimationFrame(() => {
  document.querySelector('.hero').classList.add('is-ready');
}));

/* ═══════════════ SEZON ETİKETİ ═══════════════ */
(function seasonLabel() {
  const now = new Date();
  const startYear = now.getMonth() >= 7 ? now.getFullYear() : now.getFullYear() - 1; // ay 0-index: Ağustos=7
  document.getElementById('seasonLabel').textContent = `${startYear}-${startYear + 1} SEZONU AÇILDI`;
})();
document.getElementById('year').textContent = new Date().getFullYear();

/* ═══════════════ SCROLL-REVEAL (IntersectionObserver) ═══════════════ */
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('in-view');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });
document.querySelectorAll('section:not(.hero)').forEach((el) => revealObserver.observe(el));

/* ═══════════════ SAYAÇ (count-up) ═══════════════ */
function animateCount(el, target, suffix) {
  const duration = 1400;
  const start = performance.now();
  function tick(now) {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3);
    el.textContent = Math.round(eased * target) + suffix;
    if (t < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
}
const statsObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    entry.target.querySelectorAll('.stat').forEach((stat) => {
      const numEl = stat.querySelector('.stat__num');
      const target = Number(numEl.dataset.target || 0);
      animateCount(numEl, target, stat.dataset.suffix || '');
    });
    statsObserver.unobserve(entry.target);
  });
}, { threshold: 0.4 });
statsObserver.observe(document.getElementById('stats'));

/* ═══════════════ GERÇEK VERİ: Firestore'dan çek ═══════════════ */
const FOUNDING_YEAR = 2018;

async function fetchCollection(name, max = 300) {
  try {
    const url = `${FIRESTORE_BASE}/${name}?key=${FIREBASE_API_KEY}&pageSize=${max}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    return (json.documents || []).map((docSnap) => {
      const id = docSnap.name.split('/').pop();
      return { id, ...unwrapFirestoreFields(docSnap.fields || {}) };
    });
  } catch (err) {
    console.error(`Firestore okuma hatası (${name}):`, err);
    return [];
  }
}

function setStatTarget(index, value) {
  const stat = document.querySelectorAll('.stat__num')[index];
  if (stat) stat.dataset.target = value;
}

/** Küratör kararı: kadro bölümünde sadece "Metafor" oyununun kadrosu
 * gösterilir (Flutter uygulamasındaki aynı kürasyon kuralıyla birebir).
 * Metafor bulunamazsa ya da eşleşen oyuncu yoksa tüm kadroya düşer —
 * bölüm asla boş kalmaz. */
function metaforPlayers(shows, players) {
  const metafor = shows.find((s) => (s.name || '').toLowerCase().includes('metafor'));
  if (!metafor) return players;
  const ids = new Set([...(metafor.nowPlayersId || []), ...(metafor.oldPlayersId || [])].filter(Boolean));
  if (!ids.size) return players;
  const filtered = players.filter((p) => ids.has(p.id));
  return filtered.length ? filtered : players;
}

async function boot() {
  const [shows, players, stages] = await Promise.all([
    fetchCollection('Show'),
    fetchCollection('Player'),
    fetchCollection('Stage'),
  ]);

  // İstatistikler (uydurma yok — gerçek sayılar, TÜM kadro üzerinden)
  setStatTarget(0, shows.length);
  setStatTarget(1, players.length);
  setStatTarget(2, stages.length);
  setStatTarget(3, new Date().getFullYear() - FOUNDING_YEAR);

  renderMarquee(shows);
  renderTeam(metaforPlayers(shows, players));
  renderRepertoire(shows);
  renderGallery(shows);
  renderVenues(stages);
  initInteractions();
}

/* ── Marquee: gerçek oyun adları ────────────────────────────── */
function renderMarquee(shows) {
  const track = document.getElementById('marqueeTrack');
  const names = shows.length
    ? shows.map((s) => s.name).filter(Boolean)
    : ['TiyatRol Sahne Sanatları Topluluğu'];
  const itemsHtml = names.map((n) => `<span class="hero__marquee-item">${esc(n)} <span class="dot">✦</span></span>`).join('');
  // Kesintisiz döngü için içerik iki kez tekrarlanır
  track.innerHTML = itemsHtml + itemsHtml;
}

/* ── Ekip ────────────────────────────────────────────────────── */
function renderTeam(players) {
  const rail = document.getElementById('teamRail');
  if (!players.length) {
    rail.innerHTML = `<div class="empty-note">Ekip kadromuz yakında burada — küratör sanatçı profillerini ekledikçe bu bölüm otomatik zenginleşecek.</div>`;
    return;
  }
  rail.innerHTML = players.map((p) => {
    const name = esc(`${p.firstName ?? ''} ${p.lastName ?? ''}`.trim() || 'İsimsiz Sanatçı');
    const quote = p.quote ? esc(p.quote) : '';
    const img = p.imageUrl
      ? `<img class="player-card__img" src="${esc(p.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="player-card__img player-card__img--placeholder">${esc((p.firstName || '?')[0] || '?')}</div>`;
    return `
      <div class="player-card">
        <div class="player-card__inner">
          ${img}
          <div class="player-card__shade"></div>
          <div class="player-card__info">
            <p class="player-card__name">${name}</p>
            ${quote ? `<p class="player-card__quote">"${quote}"</p>` : ''}
          </div>
        </div>
      </div>`;
  }).join('');
}

/* ── Repertuar ───────────────────────────────────────────────── */
function renderRepertoire(shows) {
  const grid = document.getElementById('repertoireGrid');
  if (!shows.length) {
    grid.innerHTML = `<div class="empty-note">Sezon repertuarı yakında burada — küratör oyun eklediğinde bu bölüm otomatik dolacak.</div>`;
    return;
  }
  grid.innerHTML = shows.map((s, i) => {
    const name = esc(s.name || 'İsimsiz Oyun');
    const desc = esc(s.description || '');
    const cat = esc(s.category || 'Tiyatro');
    const duration = esc(s.duration || '');
    const age = esc(s.ageLimit || '');
    const img = s.imageUrl
      ? `<img class="show-card__img" src="${esc(s.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="show-card__img show-card__img--placeholder">${name}</div>`;
    return `
      <div class="show-card${i === 0 ? ' show-card--featured' : ''}">
        ${img}
        <div class="show-card__shade"></div>
        <span class="show-card__cat">${cat}</span>
        <div class="show-card__body">
          <p class="show-card__name">${name}</p>
          ${desc ? `<p class="show-card__desc">${desc}</p>` : ''}
          <div class="show-card__meta">
            ${duration ? `<span>${duration}</span>` : ''}
            ${age ? `<span>${age}+</span>` : ''}
          </div>
        </div>
      </div>`;
  }).join('');
}

/* ── Galeri (tüm oyunların gerçek fotoğrafları) ─────────────────── */
function renderGallery(shows) {
  const wall = document.getElementById('galleryWall');
  const photos = [];
  shows.forEach((s) => (s.photosShowId || []).forEach((url) => { if (url) photos.push({ url, name: s.name }); }));
  if (!photos.length) {
    wall.innerHTML = `<div class="empty-note">Sahne arkası galerisi yakında burada — küratör gösterilere fotoğraf ekledikçe bu duvar otomatik zenginleşecek.</div>`;
    return;
  }
  // Sabit karıştırma: her yenilemede aynı sıra
  const shuffled = photos
    .map((p, i) => ({ p, sort: Math.sin(i * 999) }))
    .sort((a, b) => a.sort - b.sort)
    .map((x) => x.p)
    .slice(0, 24);
  wall.innerHTML = shuffled.map((p) => `
    <div class="gallery__item"><img src="${esc(p.url)}" alt="${esc(p.name || '')}" loading="lazy" /></div>
  `).join('');
}

/* ── Sahneler ────────────────────────────────────────────────── */
function renderVenues(stages) {
  const grid = document.getElementById('venuesGrid');
  if (!stages.length) {
    grid.innerHTML = `<div class="empty-note">Sahne/mekan bilgileri yakında burada.</div>`;
    return;
  }
  grid.innerHTML = stages.map((s) => {
    const name = esc(s.name || 'İsimsiz Sahne');
    const addr = esc(s.address || '');
    const cap = esc(s.capacity || '');
    const img = s.imageUrl
      ? `<img class="venue-card__img" src="${esc(s.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="venue-card__img"></div>`;
    return `
      <div class="venue-card">
        ${img}
        <div>
          <p class="venue-card__name">${name}</p>
          ${addr ? `<p class="venue-card__addr">${addr}</p>` : ''}
          ${cap ? `<p class="venue-card__cap">${cap} Kişi Kapasiteli</p>` : ''}
        </div>
      </div>`;
  }).join('');
}

/* ═══════════════ MODERN MİKRO-ETKİLEŞİMLER ═══════════════
   Veriler ekrana bastıktan SONRA çağrılır (initInteractions), çünkü
   kartlar dinamik olarak innerHTML ile o an oluşuyor. */

/** İmleci takip eden "spotlight" kenarlık parıltısı — kart üstünde
 * fare hareket ettikçe ışık kaynağı fareyi takip eder. */
function applySpotlight(el) {
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect();
    el.style.setProperty('--mx', `${((e.clientX - r.left) / r.width) * 100}%`);
    el.style.setProperty('--my', `${((e.clientY - r.top) / r.height) * 100}%`);
  });
}

/** Gerçek 3B perspektif eğimi (tilt) — fare kart üzerindeyken kart,
 * fareye doğru hafifçe döner; ayrılınca yumuşakça düzleşir. */
function applyTilt(el, max = 10) {
  const inner = el.querySelector('.player-card__inner') || el;
  el.addEventListener('pointermove', (e) => {
    const r = el.getBoundingClientRect();
    const px = (e.clientX - r.left) / r.width - 0.5;
    const py = (e.clientY - r.top) / r.height - 0.5;
    inner.style.transition = 'transform .08s linear';
    inner.style.transform = `perspective(900px) rotateX(${(-py * max).toFixed(2)}deg) rotateY(${(px * max).toFixed(2)}deg) scale3d(1.03,1.03,1.03)`;
  });
  el.addEventListener('pointerleave', () => {
    inner.style.transition = 'transform .6s var(--ease)';
    inner.style.transform = 'perspective(900px) rotateX(0) rotateY(0) scale3d(1,1,1)';
  });
}

/** Manyetik düğme — fare düğmenin yakınına geldiğinde düğme hafifçe
 * fareye doğru kayar (Awwwards tarzı premium mikro-etkileşim). */
function applyMagnetic(el, strength = 0.32) {
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

/** Hero'da scroll ile hafif paralaks — spot ışığı ve perdeler scroll
 * ettikçe derinlik hissi vermek için farklı hızlarda kayar. */
function initHeroParallax() {
  const hero = document.querySelector('.hero');
  const spotlight = document.querySelector('.hero__spotlight');
  const curtainL = document.querySelector('.hero__curtain--left');
  const curtainR = document.querySelector('.hero__curtain--right');
  if (!hero) return;
  window.addEventListener('scroll', () => {
    const y = window.scrollY;
    if (y > hero.offsetHeight) return;
    const p = y / hero.offsetHeight;
    if (spotlight) spotlight.style.transform = `translate(-50%, ${y * 0.35}px)`;
    if (curtainL) curtainL.style.transform = `translateX(${-p * 40}px)`;
    if (curtainR) curtainR.style.transform = `translateX(${p * 40}px)`;
  }, { passive: true });
}

function initInteractions() {
  document.querySelectorAll('.show-card, .venue-card').forEach((el) => applySpotlight(el));
  document.querySelectorAll('.player-card').forEach((el) => { applySpotlight(el); applyTilt(el); });
  document.querySelectorAll('.btn, .nav__cta').forEach((el) => applyMagnetic(el));
  initHeroParallax();
}

boot();

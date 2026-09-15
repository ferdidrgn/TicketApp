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

/* ── Show.mediaLinks — Firestore'da her oyunun kendi medya linklerini
 * tuttuğu alan. Eleman formatı: { type, title, url, featured }
 * type: "youtube" | "audio" | "instagram" | "other". featured:true olan
 * kayıt anasayfada (prömiyer/video bölümlerinde) öne çıkarılır. ── */
function mediaLinksOf(show) {
  return Array.isArray(show?.mediaLinks) ? show.mediaLinks.filter((l) => l && l.url) : [];
}
function youtubeIdFromUrl(url) {
  if (!url) return null;
  const m = String(url).match(/(?:youtu\.be\/|[?&]v=|\/embed\/|\/shorts\/)([a-zA-Z0-9_-]{6,})/);
  return m ? m[1] : null;
}

/* ── Elle düzenlenebilir içerik alanları — gerçek veri geldikçe ilgili
 * bölüm otomatik dolar, boşken "yakında" mesajı gösterilir. ── */
const PRESS_MENTIONS = [
  // { outlet: 'Yayın adı', quote: 'Kısa alıntı…', url: 'https://…' },
];
const BLOG_POSTS = [
  // { title: 'Yazı başlığı', excerpt: 'Kısa özet…', date: '12 Eylül 2026', url: '#' },
];
const AWARDS = [
  // { title: 'Ödül / festival adı', year: '2026', note: 'Kısa açıklama' },
];
const WORKSHOPS = [
  // { title: 'Atölye adı', date: '20 Ekim 2026', desc: 'Kısa açıklama', url: '#' },
];
/** Bazı oyunlarımız Türk tiyatrosunun bilinen eserleri — yazarını doğru
 * anmak hem izleyiciye hem esere karşı bir saygı borcu. İsim eşleşmesine
 * göre (doğrulanmış kaynaklardan) küçük bir "Yazan:" notu ekleniyor. */
const SHOW_PLAYWRIGHTS = {
  'kadınlık': 'Yılmaz Erdoğan',
  'gözlerimi': 'Haldun Taner',
};
function playwrightOf(show) {
  const key = Object.keys(SHOW_PLAYWRIGHTS).find((k) => (show?.name || '').toLowerCase().includes(k));
  return key ? SHOW_PLAYWRIGHTS[key] : '';
}

/* ── Kulisten Notlar — birebir replik değil, oyunların gerçek temalarından
 * (doğrulanmış kaynaklardan) esinlenen kısa yansımalar + topluluk ruhunu
 * anlatan genel notlar. Yapışkan not / pano hissi veren bir bölümde. ── */
const STAGE_NOTES = [
  'Her gece aynı repliği söylüyoruz, hiçbir gece aynı hissetmiyoruz.',
  'Alkış bittiğinde asıl hikâye kulis kapısının ardında başlar.',
  'Bir oyunu izlemek, birinin en cesur hâlini görmektir.',
  'Sahne, ışıklar sönünce de içimizde kalır.',
  'Prova bir alışkanlık değil, her seferinde yeniden âşık olmaktır.',
  'Seyirci gülerken biz nefesimizi tutarız.',
];
const SHOW_THEME_NOTES = {
  'kadınlık': 'Tarih boyunca gölgede kalmış kadınlara bir kahkaha, bir başkaldırı.',
  'gözlerimi': 'Vicdani ile Efruz’un aynı yüzyılda, hiç aynı olmayan hayatları.',
};

const FAQ_ITEMS = [
  { q: 'Bilet iadesi yapabilir miyim?', a: 'İade ve değişim koşulları etkinlik tarihine göre değişebilir. Güncel bilgi için iletişim formumuzdan bize ulaşabilirsiniz.' },
  { q: 'Salona geç kalırsam ne olur?', a: 'Sahnedeki performansı bölmemek adına geç kalan seyirciler ilk uygun ara/sahne geçişine kadar bekletilebilir.' },
  { q: 'Yaş sınırı olan oyunlar var mı?', a: 'Bazı oyunlarımız içerik itibarıyla belirli bir yaş sınırına sahip olabilir; ilgili bilgi oyunun repertuar kartında belirtilir.' },
  { q: 'Bilet aldıktan sonra koltuğumu değiştirebilir miyim?', a: 'Koltuk değişikliği talepleriniz için etkinlik öncesinde bizimle iletişime geçebilirsiniz, uygunluğa göre yardımcı oluruz.' },
];

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
  renderAbout(shows);
  renderPitchNoop();
  renderRepertoire(shows);
  renderTeam(curatedCast(shows, players), shows);
  renderCalendar(events, shows);
  renderNotes(shows);
  renderGallery(shows);
  renderVenues(stages);
  renderPremiere(shows);
  renderVideoInterviews(shows);
  renderPress();
  renderAwards();
  renderQuote(players);
  renderWorkshops();
  renderBlog();
  renderFAQ();
  renderInstagram(shows);
  initChrome();
  initNewsletterForm();
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
    el.textContent = `Bu sezon sahnede ${shows.length} oyun var, seni bekliyoruz.`;
  } else {
    el.textContent = 'Yeni sezonun perdesi yakında açılıyor.';
  }
}

function renderMarquee(shows) {
  const row = document.getElementById('marqueeRow');
  const names = shows.length ? shows.map((s) => s.name).filter(Boolean) : ['TiyatRol Sahne Sanatları'];
  const html = names.map((n) => `<span class="marquee__item">${esc(n)} <span>✦</span></span>`).join('');
  row.innerHTML = html + html;
}

/** Her iki blob görseli de öne çıkan oyunla ilgili olsun diye — ikinci
 * (üstteki, küçük) görsel artık rastgele bir oyuncu yüzü değil, aynı
 * oyunun kendi galerisinden gerçek bir sahne fotoğrafı. */
function renderAbout(shows) {
  const art = document.getElementById('aboutArt');
  const lead = shows.find((s) => s.imageUrl) || shows[0];
  const img1 = lead?.imageUrl || shows.find((s) => s.imageUrl)?.imageUrl;
  const gallery = (lead?.photosShowId || []).filter(Boolean);
  const img2 = gallery.find((url) => url !== img1)
    || shows.find((s) => s.imageUrl && s.imageUrl !== img1)?.imageUrl;
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
    const playwright = esc(playwrightOf(s));
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
        ${playwright ? `<p class="show__author">Yazan: ${playwright}</p>` : ''}
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
  rail.innerHTML = players.map((p, i) => {
    const name = esc(`${p.firstName ?? ''} ${p.lastName ?? ''}`.trim() || 'İsimsiz Sanatçı');
    const quote = p.quote ? esc(p.quote) : '';
    const img = p.imageUrl
      ? `<img class="player__img" src="${esc(p.imageUrl)}" alt="${name}" loading="lazy" />`
      : `<div class="player__img player__img--ph">${esc((p.firstName || '?')[0] || '?')}</div>`;
    return `<a class="player reveal" href="${playerHref(p)}" style="--i:${i}">
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
    const tag = show ? 'a' : 'div';
    const hrefAttr = show ? ` href="${showHref(show)}?scrollTo=etkinlikler" data-cursor-hover` : '';
    return `<${tag} class="ticket"${hrefAttr}>
      ${img}
      <div class="ticket__notch"></div>
      <div class="ticket__body">
        <div class="ticket__date"><span class="ticket__day">${e._date.getDate()}</span><span class="ticket__rest">${MONTHS_TR[e._date.getMonth()]}<br>${time}</span></div>
        <p class="ticket__name">${name}</p>
      </div>
    </${tag}>`;
  }).join('');
}

/** "Kulisten Notlar" — yapışkan not panosu. Topluluk ruhunu anlatan genel
 * notlarla, Firestore'daki oyun adlarıyla eşleşen doğrulanmış tema
 * notlarını birleştirip rastgele hafif döndürülmüş kartlar olarak basar. */
function renderNotes(shows) {
  const board = document.getElementById('notesBoard');
  if (!board) return;
  const items = [...STAGE_NOTES];
  shows.forEach((s) => {
    const key = Object.keys(SHOW_THEME_NOTES).find((k) => (s.name || '').toLowerCase().includes(k));
    if (key) items.push(`${SHOW_THEME_NOTES[key]} — “${s.name}”`);
  });
  board.innerHTML = items.map((text, i) => {
    const angle = ((i % 5) - 2) * 3.2;
    return `<div class="note reveal" style="--r:${angle}deg"><p>${esc(text)}</p></div>`;
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
 * tanıtımı ondan çeker. YouTube videosu oyunun ilk gösterim (prömiyer)
 * kaydıdır — fragman değildir. Ses kaydı ise "Göz Kap Vaz Yap" oyununa
 * aittir, Kadınlık Bizde Kalsın'a değil. */
function renderPremiere(shows) {
  const section = document.getElementById('premiere');
  if (!section) return;
  const show = shows.find((s) => (s.name || '').toLowerCase().includes('kadınlık'));
  const poster = document.getElementById('premierePoster');
  const title = document.getElementById('premiereTitle');
  const desc = document.getElementById('premiereDesc');

  title.textContent = show?.name || 'Kadınlık Bizde Kalsın';
  desc.textContent = show?.description || 'Prömiyerimizin ilk gösterim kaydını izleyin ve Göz Kap Vaz Yap oyunumuzdan bir sahne sesi dinleyin.';
  if (show?.imageUrl) poster.style.setProperty('--premiere-img', `url("${esc(show.imageUrl)}")`);

  // mediaLinks alanı doldurulduysa oradan çekilir; yoksa mevcut sabit
  // (Kadınlık Bizde Kalsın prömiyeri / Göz Kap Vaz Yap sesi) linklere düşülür.
  const links = mediaLinksOf(show);
  const ytLink_ = links.find((l) => l.type === 'youtube' && l.featured) || links.find((l) => l.type === 'youtube');
  const audioLink_ = links.find((l) => l.type === 'audio' && l.featured) || links.find((l) => l.type === 'audio');
  const ytId = (ytLink_ && youtubeIdFromUrl(ytLink_.url)) || KADINLIK_YT_ID;
  const ytUrl = ytLink_?.url || KADINLIK_YT_URL;
  const audioUrl = audioLink_?.url || KADINLIK_AUDIO_URL;
  const audioLabel = audioLink_?.title || 'Göz Kap Vaz Yap — Sahne Sesi';

  const ytThumb = document.getElementById('premiereYtThumb');
  if (ytThumb) ytThumb.style.backgroundImage = `url("https://img.youtube.com/vi/${ytId}/hqdefault.jpg")`;
  const ytLink = document.getElementById('premiereYtLink');
  if (ytLink) ytLink.href = ytUrl;
  const audio = document.getElementById('premiereAudio');
  if (audio) audio.src = audioUrl;
  const audioLabelEl = document.getElementById('premiereAudioLabel');
  if (audioLabelEl) audioLabelEl.textContent = audioLabel;
}

function renderQuote(players) {
  const withQuote = players.filter((p) => p.quote && p.quote.trim());
  if (!withQuote.length) return;
  const p = withQuote[Math.floor(Math.random() * withQuote.length)];
  document.getElementById('quoteText').textContent = `"${p.quote.trim()}"`;
  document.getElementById('quoteAttr').textContent = `— ${p.firstName ?? ''} ${p.lastName ?? ''}`.trim();
}

/** Tüm oyunların mediaLinks alanındaki YouTube kayıtlarını (röportaj,
 * sahne arkası vb.) tek bir video ızgarasında toplar. Oyunlara link
 * eklendikçe bu bölüm otomatik büyür. */
function renderVideoInterviews(shows) {
  const section = document.getElementById('interviews');
  const grid = document.getElementById('interviewsGrid');
  if (!section || !grid) return;
  const videos = [];
  const audios = [];
  shows.forEach((s) => mediaLinksOf(s).forEach((l) => {
    if (l.type === 'youtube' && l.url) videos.push({ show: s, link: l });
    else if (l.type === 'audio' && l.url) audios.push({ show: s, link: l });
  }));
  if (!videos.length && !audios.length) { grid.innerHTML = `<div class="empty empty--light">Video röportajlarımız ve sahne seslerimiz yakında burada.</div>`; return; }

  const videoCards = videos.map(({ show, link }) => {
    const id = youtubeIdFromUrl(link.url);
    const thumb = id ? `background-image:url('https://img.youtube.com/vi/${id}/hqdefault.jpg')` : '';
    const title = esc(link.title || show.name || 'Video');
    return `<a class="ivcard reveal" href="${esc(link.url)}" target="_blank" rel="noopener" data-cursor-hover>
      <div class="ivcard__thumb" style="${thumb}"></div>
      <div class="ivcard__play"><svg viewBox="0 0 24 24" width="20" height="20"><path d="M8 5v14l11-7z" fill="currentColor"/></svg></div>
      <p class="ivcard__title">${title}</p>
    </a>`;
  }).join('');

  const audioCards = audios.map(({ show, link }) => {
    const title = esc(link.title || show.name || 'Sahne Sesi');
    const showName = esc(show.name || '');
    return `<div class="ivcard ivcard--audio reveal">
      <span class="ivcard__audioLabel">${showName ? `${showName} — ` : ''}${title}</span>
      <audio controls preload="none" src="${esc(link.url)}"></audio>
    </div>`;
  }).join('');

  grid.innerHTML = videoCards + audioCards;
}

function renderPress() {
  const grid = document.getElementById('pressGrid');
  if (!grid) return;
  if (!PRESS_MENTIONS.length) { grid.innerHTML = `<div class="empty">Basın bültenlerimiz ve röportajlarımız yakında burada.</div>`; return; }
  grid.innerHTML = PRESS_MENTIONS.map((p) => `<a class="press__card reveal" href="${esc(p.url || '#')}" target="_blank" rel="noopener" data-cursor-hover>
    <span class="press__outlet">${esc(p.outlet || '')}</span>
    <p class="press__quote">"${esc(p.quote || '')}"</p>
  </a>`).join('');
}

function renderAwards() {
  const list = document.getElementById('awardsList');
  if (!list) return;
  if (!AWARDS.length) { list.innerHTML = `<div class="empty empty--light">Ödüllerimiz ve katıldığımız festivaller yakında burada.</div>`; return; }
  list.innerHTML = AWARDS.map((a) => `<div class="awards__item reveal">
    <span class="awards__year">${esc(a.year || '')}</span>
    <div><p class="awards__title">${esc(a.title || '')}</p>${a.note ? `<p class="awards__note">${esc(a.note)}</p>` : ''}</div>
  </div>`).join('');
}

function renderBlog() {
  const grid = document.getElementById('blogGrid');
  if (!grid) return;
  if (!BLOG_POSTS.length) { grid.innerHTML = `<div class="empty empty--light">Yazılarımız yakında burada.</div>`; return; }
  grid.innerHTML = BLOG_POSTS.map((post) => `<a class="blog__card reveal" href="${esc(post.url || '#')}" data-cursor-hover>
    <span class="blog__date">${esc(post.date || '')}</span>
    <h3 class="blog__title">${esc(post.title || '')}</h3>
    <p class="blog__excerpt">${esc(post.excerpt || '')}</p>
    <span class="link-arrow">Devamını Oku</span>
  </a>`).join('');
}

function renderWorkshops() {
  const grid = document.getElementById('workshopsGrid');
  if (!grid) return;
  if (!WORKSHOPS.length) { grid.innerHTML = `<div class="empty">Atölye ve eğitim duyurularımız yakında burada.</div>`; return; }
  grid.innerHTML = WORKSHOPS.map((w) => `<a class="workshop__card reveal" href="${esc(w.url || '#')}" data-cursor-hover>
    <span class="workshop__date">${esc(w.date || '')}</span>
    <h3 class="workshop__title">${esc(w.title || '')}</h3>
    ${w.desc ? `<p class="workshop__desc">${esc(w.desc)}</p>` : ''}
  </a>`).join('');
}

function renderFAQ() {
  const list = document.getElementById('faqList');
  if (!list) return;
  list.innerHTML = FAQ_ITEMS.map((item, i) => `
    <div class="faq__item reveal">
      <button type="button" class="faq__q" data-i="${i}">
        <span>${esc(item.q)}</span>
        <span class="faq__plus">+</span>
      </button>
      <div class="faq__a"><p>${esc(item.a)}</p></div>
    </div>`).join('');
  list.querySelectorAll('.faq__q').forEach((btn) => btn.addEventListener('click', () => {
    btn.closest('.faq__item').classList.toggle('is-open');
  }));
}

const IG_ICON = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.2" cy="6.8" r="1"/></svg>';

/** Gerçek Instagram API/oEmbed anahtarı olmadığı için "canlı besleme"
 * yerine, galerideki gerçek sahne fotoğraflarını Instagram-vari bir
 * ızgarada gösterip gerçek profile yönlendiriyoruz. */
function renderInstagram(shows) {
  const grid = document.getElementById('instaGrid');
  if (!grid) return;
  const photos = [];
  shows.forEach((s) => (s.photosShowId || []).forEach((url) => { if (url) photos.push(url); }));
  if (!photos.length) { grid.innerHTML = `<div class="empty">Instagram galerimiz yakında burada.</div>`; return; }
  const shuffled = photos.map((p, i) => ({ p, sort: Math.sin(i * 555) })).sort((a, b) => a.sort - b.sort).map((x) => x.p).slice(0, 8);
  grid.innerHTML = shuffled.map((url) => `<a class="insta__item" href="https://www.instagram.com/tiyatrol_/" target="_blank" rel="noopener" data-cursor-hover>
    <img src="${esc(url)}" alt="TiyatRol Instagram" loading="lazy" />
    <span class="insta__icon">${IG_ICON}</span>
  </a>`).join('');
}

function initNewsletterForm() {
  const form = document.getElementById('newsletterForm');
  if (!form) return;
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const email = form.email.value.trim();
    window.location.href = `mailto:ferdidurgun34@gmail.com?subject=${encodeURIComponent('Bülten Aboneliği')}&body=${encodeURIComponent(`Abone olmak isteyen e-posta: ${email}`)}`;
    const note = document.getElementById('newsletterNote');
    if (note) note.textContent = 'Teşekkürler! E-posta istemcin açıldı, göndermeyi unutma.';
  });
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

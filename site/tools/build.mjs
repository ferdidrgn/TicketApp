// Yayın öncesi derleme: site/ klasörünü site-dist/ içine kopyalar ve Firestore'daki
// her oyun, sahne, oyuncu ve topluluk için İÇERİĞİ HTML'de bulunan sayfa üretir
// (başlık, açıklama, Open Graph, JSON-LD, metin, iç bağlantılar) + sitemap.xml + robots.txt.
// Böylece Google JavaScript çalıştırmadan da içeriği görür; tarayıcıda site.js yine
// sayfayı canlı veriyle yeniden çizer. Firestore okuması herkese açık REST ile yapılır.
//
// Kullanım:  node site/tools/build.mjs        (SITE_URL=https://tiyatrol.com ile alan adı verilebilir)
import { cp, mkdir, readFile, writeFile, rm, readdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ilBul } from '../js/iller.js';

const KOK = join(dirname(fileURLToPath(import.meta.url)), '..');
const CIKTI = join(KOK, '..', 'site-dist');
const SITE = (process.env.SITE_URL || 'https://tiyatrol.com').replace(/\/$/, '');
const PROJE = 'ticketappflutter';

// ---------- Firestore REST ----------
const cozdur = (v) => {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(cozdur);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, cozdur(x)]));
  return null;
};
async function oku(koleksiyon) {
  const out = [];
  let token = '';
  do {
    const u = `https://firestore.googleapis.com/v1/projects/${PROJE}/databases/(default)/documents/${koleksiyon}?pageSize=300${token ? `&pageToken=${token}` : ''}`;
    const r = await fetch(u);
    if (!r.ok) throw new Error(`${koleksiyon}: HTTP ${r.status}`);
    const j = await r.json();
    for (const d of j.documents || []) {
      const o = Object.fromEntries(Object.entries(d.fields || {}).map(([k, v]) => [k, cozdur(v)]));
      o.docId = d.name.split('/').pop();
      o.id = o._id || o.docId;
      out.push(o);
    }
    token = j.nextPageToken || '';
  } while (token);
  return out;
}

// ---------- yardımcılar (site/js/util.js ile aynı mantık) ----------
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const TR = { ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', Ç: 'c', Ğ: 'g', İ: 'i', I: 'i', Ö: 'o', Ş: 's', Ü: 'u' };
const slug = (t) => String(t || '').replace(/[çğıöşüÇĞİIÖŞÜ]/g, (c) => TR[c]).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'detay';
const yol = (tur, x, ad) => `/${tur}/${slug(ad)}-${x.id}`;
const kisalt = (t, n = 155) => { t = String(t || '').replace(/\s+/g, ' ').trim(); return t.length > n ? t.slice(0, n - 1).trimEnd() + '…' : t; };
const AYLAR = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
function tarih(v) {
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})[,\s]+(\d{1,2}):(\d{2})/.exec(String(v || '').trim());
  if (m) return { y: +m[3], mo: +m[2], d: +m[1], h: +m[4], mi: +m[5], dt: new Date(Date.UTC(+m[3], +m[2] - 1, +m[1], +m[4] - 3, +m[5])) };
  const d = new Date(v); if (isNaN(d)) return null;
  return { y: d.getFullYear(), mo: d.getMonth() + 1, d: d.getDate(), h: d.getHours(), mi: d.getMinutes(), dt: d };
}
const yaz = (t) => t ? `${t.d} ${AYLAR[t.mo - 1]} ${t.y}, ${String(t.h).padStart(2, '0')}:${String(t.mi).padStart(2, '0')}` : '';
const isoTR = (t) => `${t.y}-${String(t.mo).padStart(2, '0')}-${String(t.d).padStart(2, '0')}T${String(t.h).padStart(2, '0')}:${String(t.mi).padStart(2, '0')}:00+03:00`;
const liste = (v) => (Array.isArray(v) ? v.map(String) : []);

// ---------- şablon ----------
function sayfa(sablon, { baslik, aciklama, adres, gorsel, govde, jsonld }) {
  let h = sablon;
  h = h.replace(/<title>[\s\S]*?<\/title>/, `<title>${esc(baslik)}</title>`);
  h = h.replace(/<meta name="description" content="[^"]*">/, `<meta name="description" content="${esc(kisalt(aciklama))}">`);
  h = h.replace(/<meta property="og:title" content="[^"]*">/, `<meta property="og:title" content="${esc(baslik)}">`);
  h = h.replace(/<meta property="og:image" content="[^"]*">/, `<meta property="og:image" content="${esc(gorsel || SITE + '/img/logo.png')}">`);
  const ek = `<link rel="canonical" href="${SITE}${adres}">\n<meta property="og:url" content="${SITE}${adres}">\n<meta property="og:locale" content="tr_TR">\n<meta name="twitter:card" content="summary_large_image">` + (jsonld ? `\n<script type="application/ld+json">${JSON.stringify(jsonld).replace(/</g, '\\u003c')}</script>` : '');
  h = h.replace('</head>', `${ek}\n</head>`);
  // #icerik / #home yer tutucusunu gerçek içerikle doldur (site.js tarayıcıda yeniden çizer)
  h = h.replace(/<div id="icerik">([\s\S]*?)<\/div>\s*<\/main>/, (m, ic) => { const sk = (ic.match(/<div class="sk-sayfa"[\s\S]*$/) || [''])[0]; return `<div id="icerik">${sk}<div class="onyuz">${govde}</div></div></main>`; });
  h = h.replace(/(<div class="wrap" id="home">)([\s\S]*?)(<\/div>\s*<\/main>)/, (m, a, ic, z) => `${a}${(ic.match(/<div class="sk-sat"[\s\S]*$/) || [''])[0]}<div class="onyuz">${govde}</div>${z}`);
  h = h.replace('<div id="hdr"></div>', `<div id="hdr"><nav aria-label="Ana menü"><a href="/">Vitrin</a> <a href="/kesfet">Tüm oyunlar</a> <a href="/kesfet?tur=sahneler">Sahneler</a> <a href="/kesfet?tur=topluluklar">Topluluklar</a> <a href="/yardim">Yardım</a></nav></div>`);
  return h;
}
const link = (u, t) => `<a href="${u}">${esc(t)}</a>`;
const gorselTag = (u, alt) => (u ? `<img src="${esc(u)}" alt="${esc(alt)}" width="320" loading="lazy">` : '');

async function yazDosya(yolu, icerik) {
  const p = join(CIKTI, yolu);
  await mkdir(dirname(p), { recursive: true });
  await writeFile(p, icerik, 'utf8');
}

// ---------- ana akış ----------
console.log('Firestore okunuyor…');
const [shows, events, stages, teams, players] = await Promise.all(['Show', 'Event', 'Stage', 'Team', 'Player'].map(oku));
console.log(`  Oyun ${shows.length}, seans ${events.length}, sahne ${stages.length}, topluluk ${teams.length}, oyuncu ${players.length}`);

// Klasörün kendisini silme (başka bir program — sunucu, emülatör — içinde duruyor olabilir, Windows EBUSY verir); içindekileri temizle.
await mkdir(CIKTI, { recursive: true });
for (const ad of await readdir(CIKTI)) await rm(join(CIKTI, ad), { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
await cp(KOK, CIKTI, { recursive: true, filter: (s) => !s.includes('tools') });

const sh = new Map(shows.map((s) => [s.id, s])), sg = new Map(stages.map((s) => [s.id, s])), tm = new Map(teams.map((t) => [t.id, t])), pl = new Map(players.map((p) => [p.id, p]));
const stageOf = (e) => sg.get(e.stageId) || stages.find((x) => x.name === e.stageId) || null;
const simdi = Date.now();
const adresler = [{ u: '/', p: 1 }, { u: '/kesfet', p: 0.9 }, { u: '/harita', p: 0.8 }, { u: '/kampanyalar', p: 0.5 }, { u: '/takvim', p: 0.7 }, { u: '/favoriler', p: 0.3 }, { u: '/yardim', p: 0.4 }, { u: '/uygulama', p: 0.4 }, { u: '/gizlilik', p: 0.2 }, { u: '/sartlar', p: 0.2 }];
const sablon = async (ad) => readFile(join(KOK, ad), 'utf8');
const oyunT = await sablon('oyun.html'), oyuncuT = await sablon('oyuncu.html'), sahneT = await sablon('sahne.html'), toplulukT = await sablon('topluluk.html'), anaT = await sablon('index.html'), kesfetT = await sablon('kesfet.html');

for (const s of shows) {
  const ev = events.filter((e) => (e.showId || shows.find((x) => (x.eventsId || []).includes(e.id))?.id) === s.id).map((e) => ({ ...e, t: tarih(e.date) })).filter((e) => e.t).sort((a, b) => a.t.dt - b.t.dt);
  const gelecek = ev.filter((e) => e.t.dt.getTime() >= simdi);
  const ilk = gelecek[0];
  const kadro = liste(s.nowPlayersId).map((id) => pl.get(id)).filter(Boolean);
  const takim = tm.get(s.teamId);
  const u = yol('oyun', s, s.name);
  const aciklama = s.description || `${s.name} — ${s.category || 'Tiyatro'} oyunu. Seans saatleri, sahne ve kadro bilgileri TiyatRol'de.`;
  const fiyatlar = gelecek.map((e) => parseFloat(String(e.price).replace(',', '.'))).filter((n) => !isNaN(n) && n > 0);
  const govde = `<article><h1>${esc(s.name)}</h1><p>${esc([s.category, s.duration, s.ageLimit && `Yaş sınırı ${s.ageLimit}`].filter(Boolean).join(' · '))}</p>${gorselTag(s.imageUrl, s.name)}
    <h2>Hikâye</h2><p>${esc(s.description || '')}</p>
    ${takim ? `<p>Topluluk: ${link(yol('topluluk', takim, takim.name), takim.name)}</p>` : ''}
    ${kadro.length ? `<h2>Kadro</h2><ul>${kadro.map((p) => `<li>${link(yol('oyuncu', p, `${p.firstName} ${p.lastName}`), `${p.firstName} ${p.lastName}`)}</li>`).join('')}</ul>` : ''}
    ${ev.length ? `<h2>Seanslar</h2><ul>${ev.map((e) => { const g = stageOf(e); return `<li>${esc(yaz(e.t))} — ${g ? link(yol('sahne', g, g.name), g.name) : esc(e.stageId || '')}${e.price ? ` — ${esc(e.price)} ₺` : ''}</li>`; }).join('')}</ul>` : ''}</article>`;
  const jsonld = ilk ? {
    '@context': 'https://schema.org', '@type': 'TheaterEvent', name: s.name, description: kisalt(s.description, 300), image: s.imageUrl || undefined,
    startDate: isoTR(ilk.t), eventAttendanceMode: 'https://schema.org/OfflineEventAttendanceMode', eventStatus: 'https://schema.org/EventScheduled',
    location: { '@type': 'Place', name: stageOf(ilk)?.name || s.externalVenueName || '', address: stageOf(ilk)?.address || s.externalVenueAddress || '' },
    offers: fiyatlar.length ? { '@type': 'Offer', price: Math.min(...fiyatlar), priceCurrency: 'TRY', url: s.externalTicketUrl || `${SITE}${u}`, availability: 'https://schema.org/InStock' } : undefined,
  } : { '@context': 'https://schema.org', '@type': 'CreativeWork', name: s.name, description: kisalt(s.description, 300), image: s.imageUrl || undefined };
  await yazDosya(`${u}/index.html`, sayfa(oyunT, { baslik: `${s.name} — TiyatRol`, aciklama, adres: u, gorsel: s.imageUrl, govde, jsonld }));
  adresler.push({ u, p: ilk ? 0.8 : 0.5, son: s.updatedAt });
}
for (const p of players) {
  const ad = `${p.firstName || ''} ${p.lastName || ''}`.trim(); if (!ad) continue;
  const u = yol('oyuncu', p, ad);
  const simdiki = liste(p.nowShowsId).map((id) => sh.get(id)).filter(Boolean);
  const govde = `<article><h1>${esc(ad)}</h1>${gorselTag(p.imageUrl, ad)}<p>${esc(p.bio || '')}</p>${p.quote ? `<blockquote>${esc(p.quote)}</blockquote>` : ''}${simdiki.length ? `<h2>Sahnede</h2><ul>${simdiki.map((s) => `<li>${link(yol('oyun', s, s.name), s.name)}</li>`).join('')}</ul>` : ''}</article>`;
  await yazDosya(`${u}/index.html`, sayfa(oyuncuT, { baslik: `${ad} — TiyatRol`, aciklama: p.bio || `${ad} — tiyatro oyuncusu. Sahnedeki ve geçmiş oyunları TiyatRol'de.`, adres: u, gorsel: p.imageUrl, govde, jsonld: { '@context': 'https://schema.org', '@type': 'Person', name: ad, image: p.imageUrl || undefined, description: kisalt(p.bio, 300), jobTitle: 'Tiyatro oyuncusu' } }));
  adresler.push({ u, p: 0.5 });
}
for (const g of stages) {
  const u = yol('sahne', g, g.name);
  const oyn = events.filter((e) => stageOf(e) === g).map((e) => sh.get(e.showId)).filter(Boolean);
  const tekil = [...new Map(oyn.map((s) => [s.id, s])).values()];
  const govde = `<article><h1>${esc(g.name)}</h1><p>${esc(g.address || '')}</p>${gorselTag(g.imageUrl, g.name)}<p>${esc(g.description || '')}</p>${g.capacity ? `<p>Kapasite: ${esc(g.capacity)}</p>` : ''}${tekil.length ? `<h2>Bu sahnede oynayanlar</h2><ul>${tekil.map((s) => `<li>${link(yol('oyun', s, s.name), s.name)}</li>`).join('')}</ul>` : ''}</article>`;
  const lat = parseFloat(String(g.lat ?? g.locationLat ?? '').replace(',', '.')), lng = parseFloat(String(g.long ?? g.locationLng ?? '').replace(',', '.'));
  await yazDosya(`${u}/index.html`, sayfa(sahneT, { baslik: `${g.name} — TiyatRol`, aciklama: g.description || `${g.name} — ${g.address || 'tiyatro sahnesi'}. Yaklaşan seanslar ve oyunlar TiyatRol'de.`, adres: u, gorsel: g.imageUrl, govde, jsonld: { '@context': 'https://schema.org', '@type': 'PerformingArtsTheater', name: g.name, image: g.imageUrl || undefined, address: g.address || undefined, geo: !isNaN(lat) && !isNaN(lng) && lat ? { '@type': 'GeoCoordinates', latitude: lat, longitude: lng } : undefined } }));
  adresler.push({ u, p: 0.6 });
}
for (const t of teams) {
  const u = yol('topluluk', t, t.name);
  const oyn = shows.filter((s) => s.teamId === t.id || liste(t.showsId).includes(s.id));
  const govde = `<article><h1>${esc(t.name)}</h1>${gorselTag(t.imageUrl, t.name)}<p>${esc(t.description || '')}</p>${oyn.length ? `<h2>Oyunlar</h2><ul>${oyn.map((s) => `<li>${link(yol('oyun', s, s.name), s.name)}</li>`).join('')}</ul>` : ''}</article>`;
  await yazDosya(`${u}/index.html`, sayfa(toplulukT, { baslik: `${t.name} — TiyatRol`, aciklama: t.description || `${t.name} tiyatro topluluğunun oyunları TiyatRol'de.`, adres: u, gorsel: t.imageUrl, govde, jsonld: { '@context': 'https://schema.org', '@type': 'TheaterGroup', name: t.name, image: t.imageUrl || undefined, description: kisalt(t.description, 300) } }));
  adresler.push({ u, p: 0.5 });
}

// Ana sayfa ve Keşfet: tüm oyunlara iç bağlantı listesi
const oyunListesi = `<section><h1>TiyatRol — tiyatro oyunları, sahneler ve seanslar</h1><p>Tiyatro oyunlarını, sahneleri, oyuncuları ve toplulukları keşfet; seans saatlerini ve bilet bilgilerini gör.</p><h2>Oyunlar</h2><ul>${shows.map((s) => `<li>${link(yol('oyun', s, s.name), s.name)}${s.category ? ` — ${esc(s.category)}` : ''}</li>`).join('')}</ul><h2>Sahneler</h2><ul>${stages.map((g) => `<li>${link(yol('sahne', g, g.name), g.name)}</li>`).join('')}</ul><h2>Topluluklar</h2><ul>${teams.map((t) => `<li>${link(yol('topluluk', t, t.name), t.name)}</li>`).join('')}</ul></section>`;
const siteLd = { '@context': 'https://schema.org', '@type': 'WebSite', name: 'TiyatRol', url: SITE, potentialAction: { '@type': 'SearchAction', target: `${SITE}/kesfet?q={q}`, 'query-input': 'required name=q' } };
await writeFile(join(CIKTI, 'index.html'), sayfa(anaT, { baslik: 'TiyatRol — Tiyatro oyunları, sahneler ve seanslar', aciklama: "Bu hafta hangi tiyatro oyunu var? Oyunları, sahneleri, oyuncuları ve seans saatlerini tek yerde keşfet.", adres: '/', govde: oyunListesi, jsonld: siteLd }), 'utf8');
await writeFile(join(CIKTI, 'kesfet.html'), sayfa(kesfetT, { baslik: 'Tüm oyunlar — TiyatRol', aciklama: 'Tiyatro oyunlarını türe, tarihe ve bütçeye göre süz; oyuncuları, sahneleri ve toplulukları keşfet.', adres: '/kesfet', govde: oyunListesi, jsonld: null }), 'utf8');

// ---------- İl sayfaları: /il/<il> (içerikli, JSON-LD ItemList) ----------
const sayiOf = (v) => { const n = parseFloat(String(v ?? '').replace(',', '.')); return isNaN(n) ? null : n; };
const ilStage = new Map(stages.map((g) => [g.id, ilBul({ city: g.city, address: g.address, lat: sayiOf(g.lat ?? g.locationLat), lng: sayiOf(g.long ?? g.locationLng) })]));
const ilShows = new Map();
for (const e of events) {
  const g = sg.get(e.stageId) || stages.find((x) => x.name === e.stageId); const il = g && ilStage.get(g.id);
  const s = sh.get(e.showId); const t = tarih(e.date);
  if (il && s && t && t.dt.getTime() >= simdi) (ilShows.get(il) || ilShows.set(il, new Map()).get(il)).set(s.id, s);
}
for (const s of shows) {
  if (!s.externalTicketUrl) continue;
  const il = ilBul({ address: s.externalVenueAddress, lat: sayiOf(s.externalLat), lng: sayiOf(s.externalLng) });
  if (il) (ilShows.get(il) || ilShows.set(il, new Map()).get(il)).set(s.id, s);
}
for (const [il, mp] of ilShows) {
  const liste = [...mp.values()]; const u = `/il/${slug(il)}`;
  const govde = `<article><h1>${esc(il)} tiyatro oyunları</h1><p>${esc(il)} ilinde yaklaşan ${liste.length} tiyatro oyunu, sahneleri ve seans saatleri.</p><ul>${liste.map((s) => `<li>${link(yol('oyun', s, s.name), s.name)}${s.category ? ` — ${esc(s.category)}` : ''}</li>`).join('')}</ul></article>`;
  const html = sayfa(kesfetT, { baslik: `${il} tiyatro oyunları ve seansları — TiyatRol`, aciklama: `${il} ilinde yaklaşan tiyatro oyunları, sahneler ve seans saatleri. Programa göz at.`, adres: u, govde, jsonld: { '@context': 'https://schema.org', '@type': 'ItemList', name: `${il} tiyatro oyunları`, itemListElement: liste.slice(0, 50).map((s, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE + yol('oyun', s, s.name), name: s.name })) } })
    .replace('<link rel="stylesheet" href="/css/theme.css">', `<script>try{localStorage.setItem('tiyatrol.il.v1',${JSON.stringify(il)})}catch(e){}</script>\n<link rel="stylesheet" href="/css/theme.css">`);
  await yazDosya(`${u}/index.html`, html);
  adresler.push({ u, p: 0.7 });
}

// ---------- Takvim aboneliği (.ics): tüm yaklaşan seanslar ----------
{
  const z = (t) => String(t ?? '').replace(/([,;\\])/g, '\\$1').replace(/\n/g, '\\n'), p2 = (n) => String(n).padStart(2, '0');
  const ic = (t) => `${t.y}${p2(t.mo)}${p2(t.d)}T${p2(t.h)}${p2(t.mi)}00`;
  const olay = events.map((e) => ({ e, t: tarih(e.date), s: sh.get(e.showId), g: sg.get(e.stageId) || stages.find((x) => x.name === e.stageId) })).filter((o) => o.t && o.s && o.t.dt.getTime() >= simdi).sort((a, b) => a.t.dt - b.t.dt)
    .map(({ e, t, s, g }) => { const dk = parseInt(String(s.duration || '').replace(/\D/g, ''), 10); const bit = new Date(t.dt.getTime() + (dk >= 20 && dk < 400 ? dk : 90) * 60000 + 3 * 3600000); const bt = { y: bit.getUTCFullYear(), mo: bit.getUTCMonth() + 1, d: bit.getUTCDate(), h: bit.getUTCHours(), mi: bit.getUTCMinutes() };
      return `BEGIN:VEVENT\r\nUID:${e.docId || slug(e.id)}@tiyatrol.com\r\nDTSTAMP:${ic({ y: 2026, mo: 1, d: 1, h: 0, mi: 0 })}\r\nDTSTART;TZID=Europe/Istanbul:${ic(t)}\r\nDTEND;TZID=Europe/Istanbul:${ic(bt)}\r\nSUMMARY:${z(s.name)}\r\nLOCATION:${z([g?.name, g?.address].filter(Boolean).join(', '))}\r\nURL:${SITE}${yol('oyun', s, s.name)}\r\nEND:VEVENT`; }).join('\r\n');
  await writeFile(join(CIKTI, 'takvim.ics'), `BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//TiyatRol//TR\r\nX-WR-CALNAME:TiyatRol Tiyatro Programı\r\nX-WR-TIMEZONE:Europe/Istanbul\r\nREFRESH-INTERVAL;VALUE=DURATION:PT12H\r\n${olay}\r\nEND:VCALENDAR\r\n`, 'utf8');
}

// sitemap + robots
const bugun = new Date().toISOString().slice(0, 10);
await writeFile(join(CIKTI, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${adresler.map((a) => `  <url><loc>${SITE}${esc(a.u)}</loc><lastmod>${bugun}</lastmod><priority>${a.p}</priority></url>`).join('\n')}\n</urlset>\n`, 'utf8');
await writeFile(join(CIKTI, 'robots.txt'), `User-agent: *\nAllow: /\nDisallow: /yonetim\nDisallow: /*?q=\nDisallow: /*?al=\nDisallow: /ayarlar\n\nSitemap: ${SITE}/sitemap.xml\n`, 'utf8');
console.log(`Bitti: ${adresler.length} sayfa → ${CIKTI}`);

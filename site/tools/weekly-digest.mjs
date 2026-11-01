#!/usr/bin/env node
// TiyatRol haftalık özet — bağımlılıksız (yalnız Node 20+ yerleşikleri). Yalnız TOPLU sayılar; kişisel veri yok.
//
//   node site/tools/weekly-digest.mjs            gerçek çalışma
//   node site/tools/weekly-digest.mjs --dry-run  SAHTE yanıtlarla sınar; ağa ÇIKMAZ, sır gerekmez
//
// Ortam (hepsi isteğe bağlı):
//   FIREBASE_SERVICE_ACCOUNT  servis hesabı JSON'u (ham); Cloud Datastore Viewer yeter (salt okuma)
//   TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID  — yoksa özet yalnız log'a yazılır (hata değildir)
//
// Okunanlar (hepsi Firestore REST, salt okuma):
//   Stats/views/days/{yyyy-MM-dd}   son 7 gün + önceki 7 gün (karşılaştırma)  — `total`, `show_<id>` sayaçları
//   Stats/views/months/{yyyy-MM}    bu ayın toplamı
//   Event                           yaklaşan seanslar ve doluluk (Event.seats'ten YALNIZ sayı; kimlik okunmaz/yazılmaz)
//   Show/{id}                       en çok görüntülenen 3 oyunun adı
// Yeni favori sayısı: User belgelerinde favori tarihi tutulmadığı için "yeni" sayısı hesaplanamaz; özete konmaz.
//
// Çıkış kodu: 0 (sır yoksa da). 1 yalnızca servis hesabı bozuksa / jeton alınamıyorsa (yanlış yapılandırma görünür olsun).
import { generateKeyPairSync } from 'node:crypto';
import { zamanAsimiliFetch, erisimJetonu, telegramGonder } from './health-check.mjs';

const PROJE = 'ticketappflutter';
const BAZ = `https://firestore.googleapis.com/v1/projects/${PROJE}/databases/(default)/documents`;
const GUN = 864e5;

// ---------- Firestore REST yardımcıları ----------
export function cozdur(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return Date.parse(v.timestampValue);
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(cozdur);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, cozdur(x)]));
  return null;
}
const alanlar = (doc) => Object.fromEntries(Object.entries((doc && doc.fields) || {}).map(([k, x]) => [k, cozdur(x)]));

/** Tek belge; 404 -> null; diğer hata -> fırlatır. */
async function belgeOku(fetchFn, jeton, yol) {
  const r = await zamanAsimiliFetch(fetchFn, `${BAZ}/${yol}`, { headers: { authorization: `Bearer ${jeton}` } });
  if (r.status === 404) return null;
  if (r.status !== 200) throw new Error(`${yol.split('/')[0]}: HTTP ${r.status}${r.status === 403 ? ' (Cloud Datastore Viewer rolü?)' : ''}`);
  return alanlar(await r.json());
}
/** Koleksiyon (sayfalı). `maske`: yalnız bu alanlar gelir. */
async function koleksiyonOku(fetchFn, jeton, ad, maske) {
  const cikti = []; let sayfa = '';
  do {
    const q = new URLSearchParams({ pageSize: '300' });
    if (sayfa) q.set('pageToken', sayfa);
    const url = `${BAZ}/${ad}?${q}${maske.map((m) => `&mask.fieldPaths=${encodeURIComponent(m)}`).join('')}`;
    const r = await zamanAsimiliFetch(fetchFn, url, { headers: { authorization: `Bearer ${jeton}` } });
    if (r.status !== 200) throw new Error(`${ad}: HTTP ${r.status}${r.status === 403 ? ' (Cloud Datastore Viewer rolü?)' : ''}`);
    const j = await r.json();
    for (const d of j.documents || []) cikti.push(alanlar(d));
    sayfa = j.nextPageToken || '';
  } while (sayfa);
  return cikti;
}

// ---------- Saf hesaplar (test edilebilir) ----------
/** Europe/Istanbul gün anahtarı yyyy-MM-dd. */
export function istanbulGun(ms) {
  const p = Object.fromEntries(new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Istanbul', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(ms)).map((x) => [x.type, x.value]));
  return `${p.year}-${p.month}-${p.day}`;
}
/** Dünden geriye n gün anahtarı (bugün eksik gün olduğu için dahil değil), eskiden yeniye. */
export function sonGunler(simdiMs, n, atla = 0) {
  return Array.from({ length: n }, (_, i) => istanbulGun(simdiMs - (atla + n - i) * GUN));
}
const toplam = (liste) => liste.reduce((t, g) => t + (g?.total || 0), 0);
export function haftaOzeti(buHafta, oncekiHafta) {
  const bu = toplam(buHafta), once = toplam(oncekiHafta);
  const sayac = new Map();
  for (const g of buHafta) for (const [k, v] of Object.entries(g || {})) if (/^show_/.test(k) && k !== 'show_total' && typeof v === 'number') sayac.set(k.slice(5), (sayac.get(k.slice(5)) || 0) + v);
  const enCok = [...sayac.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3);
  const enGun = buHafta.map((g, i) => [i, g?.total || 0]).sort((a, b) => b[1] - a[1])[0];
  return { bu, once, degisim: once ? Math.round(((bu - once) / once) * 100) : null, enCok, enGunIndeks: enGun && enGun[1] > 0 ? enGun[0] : null, enGunDeger: enGun ? enGun[1] : 0 };
}
/** Event.seats -> { toplam, dolu } | null (store.js dolulukHesapla ile aynı kural; kimlik okunmaz). */
export function dolulukSay(seats, simdiMs) {
  if (!seats || typeof seats !== 'object') return null;
  let top = 0, dolu = 0;
  for (const m of Object.values(seats)) {
    if (!m || typeof m !== 'object' || m.status === 'blocked' || m.customerId === '__ADMIN_BLOCKED__') continue;
    top++;
    if (m.status === 'sold') dolu++;
    else if (m.status === 'reserved') { const b = typeof m.holdExpiresAt === 'number' ? m.holdExpiresAt : 0; if (!b || b + 60000 > simdiMs) dolu++; }
  }
  return top ? { toplam: top, dolu } : null;
}
/** Event.date ("15.11.2026,22:00" | ISO | timestamp ms) -> ms | null. Saat dilimi: Istanbul (+03:00) varsayılır. */
export function etkinlikZamani(v) {
  if (typeof v === 'number') return v;
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})[,\s]+(\d{1,2}):(\d{2})/.exec(String(v || '').trim());
  if (m) return Date.UTC(+m[3], +m[2] - 1, +m[1], +m[4] - 3, +m[5]);
  const t = Date.parse(v); return Number.isNaN(t) ? null : t;
}
export function seansOzeti(olaylar, simdiMs) {
  const gelecek = olaylar.map((e) => ({ ...e, ms: etkinlikZamani(e.date) })).filter((e) => e.ms && e.ms >= simdiMs);
  const hafta = gelecek.filter((e) => e.ms < simdiMs + 7 * GUN);
  let kapasite = 0, dolu = 0, planli = 0, tukenen = 0, dolan = 0;
  for (const e of hafta) {
    const d = dolulukSay(e.seats, simdiMs); if (!d) continue;
    planli++; kapasite += d.toplam; dolu += d.dolu;
    if (d.dolu >= d.toplam) tukenen++; else if (d.dolu / d.toplam >= 0.85) dolan++;
  }
  return { gelecek: gelecek.length, hafta: hafta.length, planli, kapasite, dolu, oran: kapasite ? Math.round((dolu / kapasite) * 100) : null, tukenen, dolan };
}

const AY = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
const kisaTarih = (anahtar) => { const [, a, g] = anahtar.split('-'); return `${+g} ${AY[+a - 1]}`; };
const sayiYaz = (n) => new Intl.NumberFormat('tr-TR').format(n);

export function metinUret({ gunler, hafta, ay, ayAnahtar, adlar, seans, uyarilar }) {
  const satirlar = [`TiyatRol haftalık özet (${kisaTarih(gunler[0])} – ${kisaTarih(gunler.at(-1))})`, ''];
  satirlar.push(`Görüntülenme: ${sayiYaz(hafta.bu)}${hafta.degisim == null ? '' : ` (önceki hafta ${sayiYaz(hafta.once)}, ${hafta.degisim >= 0 ? '+' : ''}${hafta.degisim}%)`}`);
  if (hafta.enGunIndeks != null) satirlar.push(`En yoğun gün: ${kisaTarih(gunler[hafta.enGunIndeks])} (${sayiYaz(hafta.enGunDeger)})`);
  if (ay != null) satirlar.push(`${ayAnahtar} ayı toplamı şu ana kadar: ${sayiYaz(ay)}`);
  if (hafta.enCok.length) satirlar.push('', 'En çok görüntülenen oyunlar:', ...hafta.enCok.map(([id, n], i) => `${i + 1}. ${adlar.get(id) || 'Oyun (' + id.slice(0, 6) + '…)'} — ${sayiYaz(n)}`));
  satirlar.push('', `Yaklaşan seans: ${seans.gelecek} (önümüzdeki 7 günde ${seans.hafta})`);
  if (seans.planli) satirlar.push(`Önümüzdeki 7 gün doluluk: %${seans.oran} (${sayiYaz(seans.dolu)}/${sayiYaz(seans.kapasite)} koltuk, ${seans.planli} planlı seans)${seans.tukenen ? `, ${seans.tukenen} tükendi` : ''}${seans.dolan ? `, ${seans.dolan} seans %85 üstü` : ''}`);
  else if (seans.hafta) satirlar.push('Bu haftaki seansların koltuk planı kurulmadığından doluluk hesaplanamadı.');
  if (uyarilar.length) satirlar.push('', 'Okunamayanlar:', ...uyarilar.map((u) => `- ${u}`));
  return satirlar.join('\n');
}

/** Tüm akış. `fetchFn`/`ortam`/`simdiMs` dışarıdan verilebilir (test). Dönüş: { metin, gonderildi }. */
export async function calistir({ fetchFn = fetch, ortam = process.env, simdiMs = Date.now(), log = console.log, dryRun = false } = {}) {
  const saHam = ortam.FIREBASE_SERVICE_ACCOUNT;
  if (!saHam) { log('[bilgi] FIREBASE_SERVICE_ACCOUNT yok — haftalık özet atlandı.'); return { metin: '', gonderildi: false, atlandi: true }; }
  let sa;
  try { sa = JSON.parse(saHam); } catch { throw new Error('FIREBASE_SERVICE_ACCOUNT geçerli JSON değil.'); }
  if (!sa.client_email || !sa.private_key) throw new Error('FIREBASE_SERVICE_ACCOUNT içinde client_email/private_key yok.');
  const jeton = await erisimJetonu(fetchFn, sa);

  const uyarilar = [];
  const dene = async (ad, f, yedek) => { try { return await f(); } catch (e) { uyarilar.push(`${ad}: ${(e && e.message) || 'hata'}`); return yedek; } };
  const gunler = sonGunler(simdiMs, 7), onceki = sonGunler(simdiMs, 7, 7);
  const gunOku = (g) => belgeOku(fetchFn, jeton, `Stats/views/days/${g}`).then((x) => x || {});
  const buHafta = await dene('Günlük görüntülenme', () => Promise.all(gunler.map(gunOku)), gunler.map(() => ({})));
  const oncekiHafta = await dene('Önceki hafta', () => Promise.all(onceki.map(gunOku)), onceki.map(() => ({})));
  const hafta = haftaOzeti(buHafta, oncekiHafta);
  const ayAnahtar = istanbulGun(simdiMs - GUN).slice(0, 7);
  const ay = await dene('Aylık görüntülenme', async () => (await belgeOku(fetchFn, jeton, `Stats/views/months/${ayAnahtar}`))?.total ?? 0, null);
  const adlar = new Map();
  for (const [id] of hafta.enCok) {
    const s = await dene('Oyun adı', () => belgeOku(fetchFn, jeton, `Show/${encodeURIComponent(id)}`), null);
    if (s?.name) adlar.set(id, String(s.name).slice(0, 60));
  }
  const olaylar = await dene('Seanslar', () => koleksiyonOku(fetchFn, jeton, 'Event', ['date', 'seats']), []);
  const seans = seansOzeti(olaylar, simdiMs);

  const metin = metinUret({ gunler, hafta, ay, ayAnahtar, adlar, seans, uyarilar });
  log(metin);
  let gonderildi = false;
  if (dryRun) log('[dry-run] Telegram gönderilmez.');
  else if (!ortam.TELEGRAM_BOT_TOKEN || !ortam.TELEGRAM_CHAT_ID) log('[bilgi] TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID yok — özet yalnız log\'a yazıldı.');
  else {
    try { await telegramGonder(fetchFn, ortam.TELEGRAM_BOT_TOKEN, ortam.TELEGRAM_CHAT_ID, metin); gonderildi = true; log('[bilgi] Telegram mesajı gönderildi.'); }
    catch (e) { log(`[bilgi] Telegram gönderilemedi: ${(e && e.message) || 'hata'}`); }
  }
  return { metin, gonderildi, hafta, seans, uyarilar };
}

// ── --dry-run: sahte yanıtlarla kendini sınar ────────────────────────────────────────────────
async function dryRun() {
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const sa = { client_email: 'sahte@ticketappflutter.iam.gserviceaccount.com', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }), token_uri: 'https://oauth2.googleapis.com/token' };
  const simdi = Date.parse('2026-10-28T09:00:00Z');
  let hata = 0;
  const kontrol = (ad, kosul) => { console.log(`${kosul ? 'OK  ' : 'FAIL'} ${ad}`); if (!kosul) hata++; };
  const yanit = (status, govde) => ({ status, text: async () => JSON.stringify(govde), json: async () => govde });
  const sayi = (n) => ({ integerValue: String(n) });
  const gunler = sonGunler(simdi, 7), onceki = sonGunler(simdi, 7, 7);
  kontrol('gün anahtarları: 7 adet, dünden geriye', gunler.length === 7 && gunler.at(-1) === '2026-10-27' && gunler[0] === '2026-10-21');
  kontrol('önceki hafta bitişik ve çakışmıyor', onceki.at(-1) === '2026-10-20');
  const koltuk = (durum, ekstra = {}) => ({ mapValue: { fields: { status: { stringValue: durum }, ...ekstra } } });
  const gelecekTarih = '29.10.2026,20:00'; // Istanbul; simdi'den ~14 saat sonra
  const seatsDolu = { mapValue: { fields: { a1: koltuk('sold'), a2: koltuk('sold'), a3: koltuk('available'), a4: koltuk('blocked') } } };
  const sahte = async (url) => {
    url = String(url);
    if (url === 'https://oauth2.googleapis.com/token') return yanit(200, { access_token: 'sahte-jeton' });
    let m = url.match(/Stats\/views\/days\/(\d{4}-\d{2}-\d{2})$/);
    if (m) {
      if (onceki.includes(m[1])) return yanit(200, { fields: { total: sayi(10) } });
      if (m[1] === '2026-10-24') return yanit(404, {});
      return yanit(200, { fields: { total: sayi(30), show_total: sayi(30), show_A: sayi(20), show_B: sayi(10) } });
    }
    if (/Stats\/views\/months\//.test(url)) return yanit(200, { fields: { total: sayi(1234) } });
    m = url.match(/\/Show\/(\w+)$/);
    if (m) return yanit(200, { fields: { name: { stringValue: m[1] === 'A' ? 'Hamlet' : 'Cimri' } } });
    if (/\/Event\?/.test(url)) return yanit(200, { documents: [{ fields: { date: { stringValue: gelecekTarih }, seats: seatsDolu } }, { fields: { date: { stringValue: '01.01.2020,20:00' } } }, { fields: { date: { stringValue: '30.12.2026,20:00' } } }] });
    return yanit(404, {});
  };
  const sessiz = () => {};
  const r = await calistir({ fetchFn: sahte, ortam: { FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa) }, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('görüntülenme: 6 gün x 30 = 180 (1 gün 404 = 0)', r.hafta.bu === 180);
  kontrol('önceki hafta 70, değişim +157%', r.hafta.once === 70 && r.hafta.degisim === 157);
  kontrol('en çok oyun A=120, B=60', r.hafta.enCok[0][0] === 'A' && r.hafta.enCok[0][1] === 120 && r.hafta.enCok[1][1] === 60);
  kontrol('yaklaşan seans 2 (geçmiş sayılmaz), hafta içi 1', r.seans.gelecek === 2 && r.seans.hafta === 1);
  kontrol('doluluk: engelli koltuk düşer, 2/3 = %67', r.seans.kapasite === 3 && r.seans.dolu === 2 && r.seans.oran === 67);
  kontrol('metinde oyun adı ve aylık toplam var', r.metin.includes('Hamlet') && r.metin.includes('1.234'));
  kontrol('metinde kişisel veri/kimlik yok (customerId vb.)', !/customer|uid|@/i.test(r.metin));
  kontrol('Telegram sırrı yokken gönderilmez, hata yok', r.gonderildi === false);

  const r2 = await calistir({ fetchFn: sahte, ortam: {}, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('servis hesabı yoksa atlanır (hata değil)', r2.atlandi === true);

  const bozuk = async (url) => (String(url).includes('oauth2') ? yanit(200, { access_token: 'x' }) : yanit(403, {}));
  const r3 = await calistir({ fetchFn: bozuk, ortam: { FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa) }, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('403 durumunda çökmez; uyarı listesi dolu, metin yine üretilir', r3.uyarilar.length > 0 && r3.metin.includes('Okunamayanlar'));

  console.log(hata ? `\n${hata} sınama BAŞARISIZ` : '\nTüm sahte-yanıt sınamaları geçti.');
  process.exit(hata ? 1 : 0);
}

if (process.argv[1] && process.argv[1].endsWith('weekly-digest.mjs')) {
  if (process.argv.includes('--dry-run')) await dryRun();
  else {
    try { await calistir(); } catch (e) { console.error(`[HATA] ${(e && e.message) || e}`); process.exit(1); }
  }
}

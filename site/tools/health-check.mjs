#!/usr/bin/env node
// TiyatRol sağlık denetimi — bağımlılıksız (yalnız Node 20+ yerleşikleri).
//
//   node site/tools/health-check.mjs            gerçek çalışma (ortam değişkenleri aşağıda)
//   node site/tools/health-check.mjs --dry-run  SAHTE yanıtlarla kendi kendini sınar; ağa ÇIKMAZ, sır gerekmez
//
// Ortam (hepsi isteğe bağlı; yoksa ilgili adım atlanır, "bilgi" olarak yazılır):
//   SITE_URL                  varsayılan https://tiyatrol.web.app
//   FIREBASE_SERVICE_ACCOUNT  servis hesabı JSON'u (ham) — Firestore System/* kalp atışları için (datastore kapsamı)
//   TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID  — sorun varsa Telegram mesajı
//
// Çıkış kodu: 0 = sorun yok (bilgi notları sayılmaz), 1 = en az bir SORUN (GitHub'ın başarısız-iş e-postası yedek uyarıdır).
// Sırlar asla log'a yazılmaz.
import { createSign, generateKeyPairSync, createVerify } from 'node:crypto';

const PROJE = 'ticketappflutter';
const SITE = (process.env.SITE_URL || 'https://tiyatrol.web.app').replace(/\/+$/, '');
const ZAMAN_ASIMI_MS = 15000;

// Kalp atışı eşikleri (dakika). Zamanlayıcılar: expireHolds 5 dk, eventReminders sık (eşikte pay bırakıldı), processAccountDeletions günlük 03:00.
export const ESIKLER = [
  { doc: 'expireHolds', dakika: 20, ad: 'Süre dolumu (expireHolds)' },
  { doc: 'eventReminders', dakika: 45, ad: 'Seans hatırlatma (eventReminders)' },
  { doc: 'processAccountDeletions', dakika: 36 * 60, ad: 'Hesap silme (processAccountDeletions)' },
];

const SITE_KONTROLLERI = [
  { yol: '/', icerir: 'TiyatRol' },
  { yol: '/vitrin', icerir: 'TiyatRol' },
  { yol: '/kesfet', icerir: 'TiyatRol' },
  { yol: '/.well-known/assetlinks.json', icerir: 'android_app' },
];

const b64url = (b) => Buffer.from(b).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

/** Servis hesabı JSON'undan RS256 imzalı JWT üretir (OAuth2 jwt-bearer akışı). */
export function jwtUret(sa, simdiSn = Math.floor(Date.now() / 1000), kapsam = 'https://www.googleapis.com/auth/datastore') {
  const baslik = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const talep = b64url(JSON.stringify({
    iss: sa.client_email, scope: kapsam, aud: sa.token_uri || 'https://oauth2.googleapis.com/token',
    iat: simdiSn, exp: simdiSn + 3000,
  }));
  const imza = createSign('RSA-SHA256').update(`${baslik}.${talep}`).sign(sa.private_key);
  return `${baslik}.${talep}.${b64url(imza)}`;
}

export async function zamanAsimiliFetch(fetchFn, url, secenek = {}) {
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), ZAMAN_ASIMI_MS);
  try { return await fetchFn(url, { ...secenek, signal: ac.signal, redirect: 'follow' }); } finally { clearTimeout(t); }
}

/** Canlı site denetimi. Dönüş: sorun mesajları dizisi. */
export async function siteKontrol(fetchFn, site = SITE) {
  const sorunlar = [];
  for (const k of SITE_KONTROLLERI) {
    try {
      const r = await zamanAsimiliFetch(fetchFn, site + k.yol);
      const govde = await r.text();
      if (r.status !== 200) sorunlar.push(`Site ${k.yol}: HTTP ${r.status}`);
      else if (!govde.includes(k.icerir)) sorunlar.push(`Site ${k.yol}: 200 ama beklenen içerik ("${k.icerir}") yok`);
    } catch (e) {
      sorunlar.push(`Site ${k.yol}: erişilemedi (${e && e.name === 'AbortError' ? 'zaman aşımı' : (e && e.message) || 'hata'})`);
    }
  }
  return sorunlar;
}

export async function erisimJetonu(fetchFn, sa) {
  const r = await zamanAsimiliFetch(fetchFn, sa.token_uri || 'https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwtUret(sa) }).toString(),
  });
  if (r.status !== 200) throw new Error(`jeton alınamadı: HTTP ${r.status}`); // gövde basılmaz
  const j = await r.json();
  if (!j.access_token) throw new Error('jeton yanıtında access_token yok');
  return j.access_token;
}

/** Firestore System/* kalp atışları. Dönüş: { sorunlar, bilgiler }. Belge yok (404) = henüz kurulmadı: BİLGİ. */
export async function kalpAtisiKontrol(fetchFn, jeton, simdiMs = Date.now()) {
  const sorunlar = []; const bilgiler = [];
  for (const e of ESIKLER) {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJE}/databases/(default)/documents/System/${e.doc}`;
    try {
      const r = await zamanAsimiliFetch(fetchFn, url, { headers: { authorization: `Bearer ${jeton}` } });
      if (r.status === 404) { bilgiler.push(`${e.ad}: System/${e.doc} belgesi yok — zamanlayıcı henüz hiç çalışmamış (deploy öncesi olabilir), uyarı yok.`); continue; }
      if (r.status !== 200) { sorunlar.push(`${e.ad}: Firestore okuma HTTP ${r.status}${r.status === 403 ? ' (servis hesabında Cloud Datastore Viewer yok?)' : ''}`); continue; }
      const j = await r.json();
      const ts = j.fields && j.fields.lastRunAt && j.fields.lastRunAt.timestampValue;
      if (!ts) { bilgiler.push(`${e.ad}: belgede lastRunAt yok — henüz çalışmamış sayıldı.`); continue; }
      const yas = Math.max(0, Math.round((simdiMs - Date.parse(ts)) / 60000));
      if (yas > e.dakika) sorunlar.push(`${e.ad}: son çalışma ${yas} dk önce (eşik ${e.dakika} dk) — Cloud Scheduler/Blaze/fonksiyon günlüklerine bak.`);
      else bilgiler.push(`${e.ad}: ${yas} dk önce çalıştı (eşik ${e.dakika}).`);
    } catch (err) {
      sorunlar.push(`${e.ad}: okunamadı (${(err && err.message) || 'hata'})`);
    }
  }
  return { sorunlar, bilgiler };
}

export async function telegramGonder(fetchFn, token, chatId, metin) {
  const r = await zamanAsimiliFetch(fetchFn, `https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text: metin.slice(0, 3900), disable_web_page_preview: true }),
  });
  if (r.status !== 200) throw new Error(`Telegram HTTP ${r.status}`); // URL (token) basılmaz
}

/** Tüm denetim. `ortam` ve `fetchFn` dışarıdan verilebilir (test). */
export async function calistir({ fetchFn = fetch, ortam = process.env, simdiMs = Date.now(), log = console.log, dryRun = false } = {}) {
  const sorunlar = []; const bilgiler = [];
  sorunlar.push(...await siteKontrol(fetchFn, (ortam.SITE_URL || SITE).replace(/\/+$/, '')));

  const saHam = ortam.FIREBASE_SERVICE_ACCOUNT;
  if (!saHam) bilgiler.push('FIREBASE_SERVICE_ACCOUNT yok — kalp atışı denetimi atlandı.');
  else {
    let sa = null;
    try { sa = JSON.parse(saHam); } catch { sorunlar.push('FIREBASE_SERVICE_ACCOUNT geçerli JSON değil.'); }
    if (sa && (!sa.client_email || !sa.private_key)) { sorunlar.push('FIREBASE_SERVICE_ACCOUNT içinde client_email/private_key yok.'); sa = null; }
    if (sa) {
      try {
        const jeton = await erisimJetonu(fetchFn, sa);
        const k = await kalpAtisiKontrol(fetchFn, jeton, simdiMs);
        sorunlar.push(...k.sorunlar); bilgiler.push(...k.bilgiler);
      } catch (e) { sorunlar.push(`Firestore kimlik doğrulama: ${(e && e.message) || 'hata'}`); }
    }
  }

  for (const b of bilgiler) log(`[bilgi] ${b}`);
  for (const s of sorunlar) log(`[SORUN] ${s}`);
  if (!sorunlar.length) log('Sağlık denetimi: sorun yok.');

  if (sorunlar.length) {
    const metin = `TiyatRol sağlık uyarısı (${sorunlar.length})\n\n- ${sorunlar.join('\n- ')}`;
    if (dryRun) log(`[dry-run] Telegram'a şu gönderilirdi:\n${metin}`);
    else if (!ortam.TELEGRAM_BOT_TOKEN || !ortam.TELEGRAM_CHAT_ID) log('[bilgi] TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID yok — Telegram atlandı (iş akışı yine de başarısız olur, GitHub e-postası yedek).');
    else {
      try { await telegramGonder(fetchFn, ortam.TELEGRAM_BOT_TOKEN, ortam.TELEGRAM_CHAT_ID, metin); log('[bilgi] Telegram mesajı gönderildi.'); }
      catch (e) { log(`[bilgi] Telegram gönderilemedi: ${(e && e.message) || 'hata'}`); }
    }
  }
  return { sorunlar, bilgiler };
}

// ── --dry-run: sahte yanıtlarla kendini sınar ────────────────────────────────────────────────
async function dryRun() {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });
  const sa = { client_email: 'sahte@ticketappflutter.iam.gserviceaccount.com', private_key: pem, token_uri: 'https://oauth2.googleapis.com/token' };
  const simdi = Date.parse('2026-10-28T12:00:00Z');
  let hata = 0;
  const kontrol = (ad, kosul) => { console.log(`${kosul ? 'OK  ' : 'FAIL'} ${ad}`); if (!kosul) hata++; };

  // JWT imzası doğrulanabilir mi?
  const jwt = jwtUret(sa, 1000);
  const [h, p, s] = jwt.split('.');
  const dogru = createVerify('RSA-SHA256').update(`${h}.${p}`).verify(publicKey, Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64'));
  kontrol('JWT RS256 imzası doğrulanıyor', dogru);
  kontrol('JWT kapsamı datastore', JSON.parse(Buffer.from(p, 'base64url')).scope.endsWith('/datastore'));

  const dkOnce = (dk) => new Date(simdi - dk * 60000).toISOString();
  const yanit = (status, govde) => ({ status, text: async () => (typeof govde === 'string' ? govde : JSON.stringify(govde)), json: async () => (typeof govde === 'string' ? JSON.parse(govde) : govde) });
  const sahteFetch = (senaryo) => async (url) => {
    url = String(url);
    if (url.startsWith('https://tiyatrol.test')) {
      if (senaryo.siteDown && url.endsWith('/kesfet')) return yanit(500, 'hata');
      if (url.includes('assetlinks')) return yanit(200, '[{"target":{"namespace":"android_app"}}]');
      return yanit(200, '<title>TiyatRol</title>');
    }
    if (url === 'https://oauth2.googleapis.com/token') return yanit(200, { access_token: 'sahte-jeton' });
    const m = url.match(/System\/(\w+)$/);
    if (m) {
      const v = senaryo.hb[m[1]];
      if (v === undefined) return yanit(404, { error: { status: 'NOT_FOUND' } });
      return yanit(200, { fields: { lastRunAt: { timestampValue: dkOnce(v) } } });
    }
    return yanit(404, 'bilinmeyen');
  };
  const ortam = { SITE_URL: 'https://tiyatrol.test', FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa) };
  const sessiz = () => {};

  let r = await calistir({ fetchFn: sahteFetch({ hb: { expireHolds: 3, eventReminders: 10, processAccountDeletions: 600 } }), ortam, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('sağlıklı senaryo: sorun yok', r.sorunlar.length === 0);

  r = await calistir({ fetchFn: sahteFetch({ hb: {} }), ortam, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('belgeler yok (deploy öncesi): sorun YOK, 3 bilgi', r.sorunlar.length === 0 && r.bilgiler.length === 3);

  r = await calistir({ fetchFn: sahteFetch({ hb: { expireHolds: 25, eventReminders: 50, processAccountDeletions: 37 * 60 } }), ortam, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('3 kalp atışı eşiği aşıldı: 3 sorun', r.sorunlar.length === 3);

  r = await calistir({ fetchFn: sahteFetch({ hb: { expireHolds: 19, eventReminders: 44, processAccountDeletions: 35 * 60 } }), ortam, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('eşiğin hemen altı: sorun yok', r.sorunlar.length === 0);

  r = await calistir({ fetchFn: sahteFetch({ hb: { expireHolds: 1, eventReminders: 1, processAccountDeletions: 1 }, siteDown: true }), ortam, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('/kesfet 500: 1 site sorunu', r.sorunlar.length === 1 && r.sorunlar[0].includes('/kesfet'));

  r = await calistir({ fetchFn: sahteFetch({ hb: {} }), ortam: { SITE_URL: 'https://tiyatrol.test' }, simdiMs: simdi, log: sessiz, dryRun: true });
  kontrol('servis hesabı yoksa kalp atışı atlanır, hata değil', r.sorunlar.length === 0);

  r = await calistir({ fetchFn: sahteFetch({ hb: { expireHolds: 99 } }), ortam, simdiMs: simdi, log: console.log, dryRun: true });
  kontrol('dry-run: Telegram gönderilmez ama mesaj gösterilir (üstte)', r.sorunlar.length === 1);

  console.log(hata ? `\n${hata} sınama BAŞARISIZ` : '\nTüm sahte-yanıt sınamaları geçti.');
  process.exit(hata ? 1 : 0);
}

if (process.argv[1] && process.argv[1].endsWith('health-check.mjs')) {
  if (process.argv.includes('--dry-run')) await dryRun();
  else {
    const { sorunlar } = await calistir();
    process.exit(sorunlar.length ? 1 : 0);
  }
}

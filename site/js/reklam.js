// Web reklamı (Google AdSense) — VARSAYILAN KAPALI. Ayrıntı ve kurallar: docs/REKLAM-POLITIKASI.md
// Anahtar: /reklam.json  { "mod": "kapali" | "test" | "acik" }  (dosyayı değiştirip main'e pushlamak = deploy)
//   kapali : hiçbir betik yüklenmez, hiçbir istek atılmaz.
//   test   : yalnız adrese ?reklam=test eklenerek açan kişide (sahip) yüklenir; ziyaretçiler etkilenmez.
//   acik   : herkese açık içerik sayfalarında yüklenir (kendi reklamına tıklama/yenileme YASAK).
// Geçersiz trafik önlemi: yönetim/ekip/koltuk/ödeme/giriş/hesap sayfaları, yerel ortam ve otomasyon tarayıcıları hariç tutulur.
const YAYINCI = 'ca-pub-5779807348211992';
const YASAK = /^\/(yonetim|ekip|koltuk|odeme-sonuc|biletlerim|pasaport|plan|ayarlar|favoriler|giris|hesap)(\/|$)/;

const hassasMi = () => YASAK.test(location.pathname);
const botMu = () => navigator.webdriver || /HeadlessChrome|Lighthouse|PhantomJS|bot|crawl|spider/i.test(navigator.userAgent || '');
const yerelMi = () => ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname) || /\.(localhost|test)$/.test(location.hostname);

async function baslat() {
  if (hassasMi() || botMu() || yerelMi()) return;
  let mod = 'kapali';
  try {
    const r = await fetch('/reklam.json', { cache: 'no-store' });
    if (r.ok) mod = String((await r.json()).mod || 'kapali');
  } catch { return; }
  if (mod === 'test') {
    try {
      if (new URLSearchParams(location.search).get('reklam') === 'test') sessionStorage.setItem('reklamTest', '1');
      if (sessionStorage.getItem('reklamTest') !== '1') return;
    } catch { return; }
  } else if (mod !== 'acik') return;
  if (document.querySelector('script[data-reklam]')) return;
  const s = document.createElement('script');
  s.async = true; s.crossOrigin = 'anonymous'; s.dataset.reklam = mod;
  s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${YAYINCI}`;
  document.head.append(s);
}
baslat();

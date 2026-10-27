// TiyatRol servis çalışanı: sayfalar ağdan (çevrimdışıyken son kopya), statik dosyalar önbellekten.
const SURUM = 'tiyatrol-v3';
const TEMEL = ['/vitrin', '/kesfet', '/harita', '/takvim', '/favoriler', '/css/theme.css', '/css/site.css', '/img/logo.png'];
self.addEventListener('install', (e) => { e.waitUntil(caches.open(SURUM).then((c) => c.addAll(TEMEL).catch(() => {}))); self.skipWaiting(); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((k) => Promise.all(k.filter((x) => x !== SURUM).map((x) => caches.delete(x)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  const r = e.request;
  if (r.method !== 'GET' || !r.url.startsWith(self.location.origin) || r.url.includes('/yonetim')) return;
  e.respondWith(fetch(r).then((res) => { const k = res.clone(); if (res.ok) caches.open(SURUM).then((c) => c.put(r, k)); return res; }).catch(() => caches.match(r).then((m) => m || caches.match('/vitrin'))));
});

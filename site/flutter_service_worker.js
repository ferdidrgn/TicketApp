// Eski Flutter web sürümünün servis çalışanı bu adreste kayıtlıydı ve ziyaretçilerin tarayıcısında
// eski sayfayı (önbellekten) göstermeye devam edebiliyor. Bu dosya onu devre dışı bırakır:
// tüm önbellekleri siler, kendini kaldırır ve açık sekmeleri yeniler. Silme — yeni site bunu bekliyor.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    try { for (const k of await caches.keys()) await caches.delete(k); } catch (_) {}
    try { await self.registration.unregister(); } catch (_) {}
    try { for (const c of await self.clients.matchAll({ type: 'window' })) c.navigate(c.url); } catch (_) {}
  })());
});
self.addEventListener('fetch', () => {});

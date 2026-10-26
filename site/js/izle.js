// Sayfa görüntüleme sayacı: çerezsiz, kimliksiz, yalnızca (tür, id) bazında ARTIRILAN anonim sayaç.
// - Oturum başına aynı sayfa bir kez sayılır (sessionStorage).
// - "Do Not Track" açıksa ya da yerel geliştirme sunucusundaysa (emülatör bayrağı yoksa) GÖNDERİLMEZ.
// - Sunucu: Cloud Function `trackView` (bkz. docs/BILDIRIM-ISTATISTIK.md). IP/UA saklanmaz.
const TUR = { oyun: 'show', oyuncu: 'player', sahne: 'stage', topluluk: 'team' };

(function () {
  try {
    if (navigator.doNotTrack === '1' || window.doNotTrack === '1') return;
    const p = location.pathname.split('/').filter(Boolean);
    const k = TUR[p[0]]; if (!k || p.length < 2) return;
    const id = decodeURIComponent(p[p.length - 1]).split('-').pop();
    if (!/^[A-Za-z0-9_]{3,40}$/.test(id)) return;
    const yerel = ['localhost', '127.0.0.1'].includes(location.hostname);
    const emu = localStorage.getItem('tiyatrol.emu') === '1';
    if (yerel && !emu) return;
    const anahtar = `izle.${k}.${id}`;
    if (sessionStorage.getItem(anahtar)) return;
    sessionStorage.setItem(anahtar, '1');
    const url = emu && yerel ? 'http://127.0.0.1:5001/ticketappflutter/europe-west1/trackView' : 'https://europe-west1-ticketappflutter.cloudfunctions.net/trackView';
    setTimeout(() => fetch(url, { method: 'POST', keepalive: true, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ k, id }) }).catch(() => {}), 1500);
  } catch (e) { /* sayaç hiçbir zaman sayfayı bozmamalı */ }
})();

import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, oyunKarti, kisi, hataKutusu, iskelet } from '../ui.js';
import { favListe } from '../fav.js';
import { $, $$, esc, linkOf } from '../util.js';
import { baslikYaz } from '../detay.js';

kabukCiz('');
baslikYaz('Favorilerim', 'Favori oyunların, sahnelerin ve sanatçıların.');
const ic = $('#icerik');
let sekme = 'oyun';
yukle().then(ciz).catch((e) => { ic.innerHTML = hataKutusu(e.message); });
document.addEventListener('fav-degisti', () => yukle().then(ciz));

function ciz(d) {
  const ids = new Set(favListe());
  const oyunlar = d.shows.filter((s) => ids.has(s.id));
  const sahneler = d.stages.filter((s) => ids.has(s.id));
  const sanatcilar = d.players.filter((s) => ids.has(s.id));
  const topluluklar = d.teams.filter((s) => ids.has(s.id));
  const sahnede = oyunlar.filter((s) => s.state === 'aktif' || s.state === 'vitrin');
  const kapanan = oyunlar.filter((s) => s.state === 'bitti' || s.state === 'taslak');
  const toplam = oyunlar.length + sahneler.length + sanatcilar.length + topluluklar.length;
  const sek = [['oyun', 'Oyunlar', oyunlar.length], ['sahne', 'Sahneler', sahneler.length], ['sanatci', 'Sanatçılar', sanatcilar.length], ['topluluk', 'Topluluklar', topluluklar.length]];
  ic.innerHTML = `<div class="pg-ust"><h1>Favorilerim</h1><p>Bu liste bu tarayıcıda saklanır; giriş gerekmez. Uygulamadaki favorilerin hesabına bağlı olduğundan ayrıdır.</p></div>
    <div class="fav-sek">${sek.map(([k, a, n]) => `<button class="chip ${sekme === k ? 'on' : ''}" data-k="${k}">${a} (${n})</button>`).join('')}</div><div id="fav-icerik"></div>`;
  $$('.fav-sek .chip').forEach((b) => b.addEventListener('click', () => { sekme = b.dataset.k; ciz(d); }));
  const bos = (m) => `<div class="empty"><h3>${m}</h3><p>Kartlardaki kalbe dokunarak favori ekleyebilirsin.</p><p style="margin-top:16px"><a class="btn btn-primary" href="/kesfet">Oyunlara göz at</a></p></div>`;
  const k = $('#fav-icerik');
  if (!toplam) { k.innerHTML = bos('Henüz favorin yok'); return; }
  if (sekme === 'oyun') {
    k.innerHTML = oyunlar.length ? `${sahnede.length ? `<div class="fav-grup"><h2>Sahnede</h2><div class="grid">${sahnede.map((s) => oyunKarti(s)).join('')}</div></div>` : ''}${kapanan.length ? `<div class="fav-grup"><h2>Perdesi kapananlar</h2><div class="grid">${kapanan.map((s) => oyunKarti(s)).join('')}</div></div>` : ''}` : bos('Favori oyunun yok');
  } else if (sekme === 'sahne') {
    k.innerHTML = sahneler.length ? `<div class="venues">${sahneler.map((s) => `<a class="venue" href="${linkOf('sahne', s)}">${s.imageUrl ? `<img src="${esc(s.imageUrl)}" alt="" loading="lazy">` : ''}<div><h3>${esc(s.name)}</h3><small>${s.upcoming.length} yaklaşan seans</small></div></a>`).join('')}</div>` : bos('Favori sahnen yok');
  } else if (sekme === 'sanatci') {
    k.innerHTML = sanatcilar.length ? `<div class="people" style="flex-wrap:wrap">${sanatcilar.map(kisi).join('')}</div>` : bos('Favori sanatçın yok');
  } else {
    k.innerHTML = topluluklar.length ? `<div class="people" style="flex-wrap:wrap">${topluluklar.map((t) => `<a class="person" href="${linkOf('topluluk', t)}"><div class="flower">${t.imageUrl ? `<img src="${esc(t.imageUrl)}" alt="" loading="lazy">` : esc(t.name[0])}</div><b>${esc(t.name)}</b></a>`).join('')}</div>` : bos('Favori topluluğun yok');
  }
}

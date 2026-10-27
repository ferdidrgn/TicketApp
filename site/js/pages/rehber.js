// Rehber: /rehber (liste) ve /rehber/<slug> (makale). Veri: /rehber/makaleler.js
import '../theme.js';
import { kabukCiz } from '../ui.js';
import { MAKALELER } from '../rehber-data.js';
import { baslikYaz } from '../detay.js';
import { $, esc } from '../util.js';

kabukCiz('');
const ic = $('#icerik');
const slug = location.pathname.replace(/\/+$/, '').split('/').filter(Boolean)[1];
const m = MAKALELER.find((x) => x.slug === slug);
if (!slug || !m) {
  baslikYaz('Tiyatro rehberi', 'Tiyatroya ilk kez gidenler, aileler ve izleyiciler için özgün rehber yazıları.');
  ic.innerHTML = `<div class="pg-ust"><h1>Tiyatro rehberi</h1><p>İlk kez gidenler, aileler ve tiyatro severler için kısa, uygulanabilir yazılar.</p></div>
    <div class="rehber-izgara">${MAKALELER.map((x, i) => `<a class="rehber-kart" href="/rehber/${x.slug}" style="--i:${i}"><span class="durum aktif">${esc(x.etiket)}</span><h2>${esc(x.baslik)}</h2><p>${esc(x.ozet)}</p><small>${x.dk} dk okuma →</small></a>`).join('')}</div>`;
} else {
  baslikYaz(m.baslik, m.ozet);
  const diger = MAKALELER.filter((x) => x.slug !== m.slug).slice(0, 3);
  ic.innerHTML = `<article class="makale"><div class="crumbs"><a href="/vitrin">Vitrin</a> / <a href="/rehber">Rehber</a></div><span class="durum aktif">${esc(m.etiket)}</span><h1>${esc(m.baslik)}</h1><p class="makale-ozet">${esc(m.ozet)}</p><div class="makale-govde">${m.govde}</div>
    <div class="makale-alt"><a class="btn btn-primary" href="/kesfet">Oyunlara göz at</a><a class="btn btn-ghost" href="/harita">Haritada gör</a></div></article>
    <section class="sec"><h2 style="font-size:28px;margin-bottom:16px">Diğer yazılar</h2><div class="rehber-izgara">${diger.map((x) => `<a class="rehber-kart" href="/rehber/${x.slug}"><span class="durum aktif">${esc(x.etiket)}</span><h2>${esc(x.baslik)}</h2><p>${esc(x.ozet)}</p><small>${x.dk} dk okuma →</small></a>`).join('')}</div></section>`;
}

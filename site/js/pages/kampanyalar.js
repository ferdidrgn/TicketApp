import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, hataKutusu } from '../ui.js';
import { paylas, bildir } from '../fav.js';
import { $, $$, esc, AYLAR } from '../util.js';
import { baslikYaz } from '../detay.js';

kabukCiz('');
baslikYaz('Kampanyalar', 'Tiyatro biletlerinde güncel kampanya ve fırsatlar.');
const ic = $('#icerik');
let sec = 'hepsi';
yukle().then(ciz).catch((e) => { ic.innerHTML = hataKutusu(e.message); });

const ETIKET = { son: 'Son günler', aktif: 'Devam ediyor', yakinda: 'Yakında', bitti: 'Süresi doldu' };
const tarih = (d) => (d ? `${d.getDate()} ${AYLAR[d.getMonth()]} ${d.getFullYear()}` : '');

function ciz(d) {
  const l = d.tumKampanyalar.filter((c) => sec === 'hepsi' || (sec === 'aktif' ? c.durum !== 'bitti' : c.durum === 'bitti'));
  ic.innerHTML = `<div class="pg-ust"><h1>Kampanyalar</h1><p>Organizatörlerin ve TiyatRol'ün güncel fırsatları. Bilet satın alma uygulamada ya da kampanyanın bağlantısındaki platformda yapılır.</p></div>
    <div class="fav-sek">${[['hepsi', 'Tümü'], ['aktif', 'Geçerli olanlar'], ['bitti', 'Süresi dolanlar']].map(([k, a]) => `<button class="chip ${sec === k ? 'on' : ''}" data-k="${k}">${a}</button>`).join('')}</div>
    ${l.length ? `<div class="kupon-izgara">${l.map((c, i) => `<article class="kupon ${c.durum === 'bitti' ? 'bitti' : ''}"><div class="g"><span class="durum ${c.durum}">${ETIKET[c.durum]}</span>${c.imageUrl ? `<img src="${esc(c.imageUrl)}" alt="" loading="lazy">` : ''}<h3>${esc(c.title || 'Kampanya')}</h3>
      <small>${c.bit ? (c.durum === 'bitti' ? `Bitti: ${tarih(c.bit)}` : c.kalanGun === 0 ? 'Bugün son gün' : `Son ${c.kalanGun} gün · ${tarih(c.bit)}`) : 'Süresiz'}</small>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:6px">${c.url && c.durum !== 'bitti' ? `<a class="btn btn-primary btn-sm" target="_blank" rel="noopener sponsored" href="${esc(c.url)}">Kampanyayı incele</a>` : ''}<button class="btn btn-ghost btn-sm" data-p="${i}" style="border-color:rgba(29,20,16,.3);color:var(--paper-ink)">Paylaş</button></div></div>
      <div class="k"><div>${esc(String(c.title || '').match(/%\s?\d+|\d+\s?%|1 alana 1/i)?.[0] || 'FIRSAT')}<span>KUPON</span></div></div></article>`).join('')}</div>` : '<div class="empty"><h3>Kampanya yok</h3><p>Yeni fırsatlar eklendiğinde burada görünür.</p></div>'}`;
  $$('.fav-sek .chip').forEach((b) => b.addEventListener('click', () => { sec = b.dataset.k; ciz(d); }));
  $$('[data-p]').forEach((b) => b.addEventListener('click', async () => { const c = l[+b.dataset.p]; if (c.url) { try { await navigator.clipboard.writeText(c.url); bildir('Kampanya bağlantısı kopyalandı'); } catch { paylas(c.title); } } else paylas(c.title); }));
}

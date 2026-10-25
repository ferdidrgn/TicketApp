import '../theme.js';
import { yukle } from '../store.js';
import { kabukCiz, hataKutusu } from '../ui.js';
import { ilOku } from '../iller.js';
import { $, $$, esc, linkOf, tl, saat, gunBasi, ayniGun, AYLAR, GUN_KISA, tarihUzun } from '../util.js';
import { baslikYaz } from '../detay.js';

kabukCiz('takvim');
baslikYaz('Tiyatro takvimi', 'Aylık tiyatro takvimi: hangi gün hangi oyun, hangi sahnede.');
const ic = $('#icerik');
const bugun = gunBasi(new Date());
let ay = new Date(bugun.getFullYear(), bugun.getMonth(), 1), sec = null;
yukle().then(ciz).catch((e) => { ic.innerHTML = hataKutusu(e.message); });
document.addEventListener('il-degisti', () => location.reload());

function ciz(d) {
  const il = ilOku();
  const ev = d.events.filter((e) => e.show && e.show.state !== 'taslak' && (!il || e.stage?.il === il));
  const gunBy = new Map();
  ev.forEach((e) => { const k = gunBasi(e.when).getTime(); (gunBy.get(k) || gunBy.set(k, []).get(k)).push(e); });
  const ilk = new Date(ay), basGun = (ilk.getDay() + 6) % 7, gunSay = new Date(ay.getFullYear(), ay.getMonth() + 1, 0).getDate();
  const hucre = [];
  for (let i = 0; i < basGun; i++) hucre.push('<div class="tk-h bos"></div>');
  for (let g = 1; g <= gunSay; g++) {
    const t = new Date(ay.getFullYear(), ay.getMonth(), g), l = gunBy.get(t.getTime()) || [];
    hucre.push(`<button class="tk-h ${l.length ? 'var' : ''} ${ayniGun(t, bugun) ? 'bugun' : ''} ${sec && ayniGun(t, sec) ? 'sec' : ''}" data-t="${t.getTime()}" ${l.length ? '' : 'tabindex="-1"'} aria-label="${g} ${AYLAR[ay.getMonth()]}, ${l.length} seans"><b>${g}</b>${l.length ? `<span class="n">${l.length} seans</span><span class="an">${l.slice(0, 6).map(() => '<i></i>').join('')}</span>` : ''}</button>`);
  }
  const webcal = `webcal://${location.host}/takvim.ics`;
  const toplam = [...gunBy.entries()].filter(([k]) => new Date(+k).getMonth() === ay.getMonth() && new Date(+k).getFullYear() === ay.getFullYear()).reduce((t, [, l]) => t + l.length, 0);
  ic.innerHTML = `<div class="pg-ust"><h1>Tiyatro takvimi</h1><p>${il ? `${esc(il)} için ` : ''}aylık program. Bir güne dokun, o günün seanslarını gör.</p></div>
    <div class="tk-ust"><div style="display:flex;align-items:center;gap:10px"><button class="icon-btn" id="onc" aria-label="Önceki ay">‹</button><h2>${AYLAR[ay.getMonth()]} ${ay.getFullYear()}</h2><button class="icon-btn" id="son" aria-label="Sonraki ay">›</button><button class="chip" id="bugun-b">Bugün</button></div>
      <div style="display:flex;gap:8px;flex-wrap:wrap"><span class="tiny" style="align-self:center">Bu ay ${toplam} seans</span><a class="btn btn-ghost btn-sm" href="${webcal}">Takvimine abone ol</a><a class="btn btn-ghost btn-sm" target="_blank" rel="noopener" href="https://calendar.google.com/calendar/r?cid=${encodeURIComponent(webcal)}">Google Takvim</a></div></div>
    <div class="tk-gun-adlari">${GUN_KISA.map((g) => `<span>${g}</span>`).join('')}</div><div class="tk-izgara">${hucre.join('')}</div><div class="tk-liste" id="tk-liste"></div>`;
  $('#onc').addEventListener('click', () => { ay = new Date(ay.getFullYear(), ay.getMonth() - 1, 1); sec = null; ciz(d); });
  $('#son').addEventListener('click', () => { ay = new Date(ay.getFullYear(), ay.getMonth() + 1, 1); sec = null; ciz(d); });
  $('#bugun-b').addEventListener('click', () => { ay = new Date(bugun.getFullYear(), bugun.getMonth(), 1); sec = bugun; ciz(d); });
  $$('.tk-h.var').forEach((b) => b.addEventListener('click', () => { sec = new Date(+b.dataset.t); ciz(d); $('#tk-liste').scrollIntoView({ behavior: 'smooth', block: 'nearest' }); }));
  const kutu = $('#tk-liste');
  if (sec) {
    const l = (gunBy.get(sec.getTime()) || []).sort((a, b) => a.when - b.when);
    kutu.innerHTML = `<h3 style="font-size:22px">${tarihUzun(sec)}</h3>${l.map((e) => `<a class="sess" href="${linkOf('oyun', e.show)}" style="grid-template-columns:70px 1fr auto auto"><div class="d"><b>${saat(e.when)}</b></div><div><b>${esc(e.show.name)}</b><br><span class="muted">${esc(e.stage?.name || '')}</span></div><div class="pr"><b>${e.priceNum ? tl(e.priceNum) : e.priceNum === 0 ? 'Ücretsiz' : ''}</b></div><span class="btn btn-ghost btn-sm">Detay</span></a>`).join('') || '<div class="empty">Bu gün seans yok.</div>'}`;
  } else {
    const yak = [...gunBy.entries()].filter(([k]) => +k >= bugun.getTime()).sort((a, b) => a[0] - b[0])[0];
    kutu.innerHTML = yak ? `<p class="muted">En yakın seans günü: <button class="chip" data-t="${yak[0]}">${tarihUzun(new Date(+yak[0]))}</button></p>` : '<div class="empty"><h3>Yaklaşan seans yok</h3></div>';
    kutu.querySelector('[data-t]')?.addEventListener('click', (e) => { sec = new Date(+e.currentTarget.dataset.t); ay = new Date(sec.getFullYear(), sec.getMonth(), 1); ciz(d); });
  }
}

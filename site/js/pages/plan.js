// /plan/<id>: "Birlikte gidelim" planı. Giriş GEREKTİRMEZ; yanıt = takma ad + gelirim/belki/gelemem (sunucu: respondPlan).
// Gizlilik: oluşturanın adı/telefonu yok ("Bir arkadaşın seni davet etti"). Plan sahibi (girişliyse) yanıtları getPlanResponses ile görür.
import '../theme.js';
import { kabukCiz } from '../ui.js';
import { db, doc, getDoc, fonksiyon } from '../firebase.js';
import { oturumDinle } from '../auth.js';
import { apiHata } from '../bilet-api.js';
import { $, $$, esc, linkOf, tarihUzun, saat } from '../util.js';

kabukCiz('');
const kok = $('#icerik');
const ID = (location.pathname.match(/^\/plan\/([A-Za-z0-9]{10,32})\/?$/) || [])[1] || '';
const yaz = (h) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = h; };
const ETIKET = { gelirim: 'Gelirim', belki: 'Belki', gelemem: 'Gelemem' };
const depo = { oku(k) { try { return localStorage.getItem(k); } catch { return null; } }, yaz(k, v) { try { localStorage.setItem(k, v); } catch { /* özel pencere */ } } };
function cihazAnahtari() {
  let k = depo.oku('tiyatrol.plan.key');
  if (!k || !/^[A-Za-z0-9_-]{16,64}$/.test(k)) {
    const b = crypto.getRandomValues(new Uint8Array(18));
    k = 'k' + [...b].map((x) => x.toString(36).padStart(2, '0')).join('').slice(0, 30);
    depo.yaz('tiyatrol.plan.key', k);
  }
  return k;
}
const bos = (b, m) => yaz(`<section class="plan-kart"><h1>${esc(b)}</h1><p class="muted">${esc(m)}</p><p><a class="btn btn-primary" href="/">Ana sayfaya git</a></p></section>`);

async function ac() {
  if (!ID) return bos('Plan bulunamadı', 'Bağlantı eksik ya da hatalı görünüyor.');
  let p;
  try { const s = await getDoc(doc(db, 'Plan', ID)); p = s.exists() ? s.data() : null; } catch { return bos('Plan açılamadı', 'Bağlantını kontrol edip tekrar dene.'); }
  if (!p || (p.expireAt?.toMillis && p.expireAt.toMillis() <= Date.now())) return bos('Bu planın süresi dolmuş', 'Plan bağlantıları 7 gün geçerlidir.');
  document.title = `${p.showName} — Birlikte gidelim · TiyatRol`;
  const when = p.eventDate?.toDate ? p.eventDate.toDate() : null;
  const oyun = linkOf('oyun', { name: p.showName, id: p.showId });
  const bilet = p.eventId ? `/koltuk/${encodeURIComponent(p.eventId)}` : oyun;
  const onceki = depo.oku('tiyatrol.plan.' + ID);
  const c = p.counts || {};
  yaz(`<section class="plan-kart">
    <p class="plan-davet">Bir arkadaşın seni davet etti</p>
    <h1>${esc(p.showName)}</h1>
    <p class="plan-ne">${when ? `${esc(tarihUzun(when))} · ${esc(saat(when))}` : 'Tarih için oyun sayfasına bak'}</p>
    <div class="plan-say" aria-live="polite">${['gelirim', 'belki', 'gelemem'].map((k) => `<div><b>${c[k] || 0}</b><small>${ETIKET[k]}</small></div>`).join('')}</div>
    <form id="plan-form" class="plan-form" novalidate>
      <label for="plan-ad">Takma adın</label>
      <input id="plan-ad" maxlength="30" autocomplete="nickname" placeholder="Örn. Deniz" required>
      <div class="plan-sec" role="group" aria-label="Katılım durumun">${['gelirim', 'belki', 'gelemem'].map((k) => `<button type="button" class="btn ${onceki === k ? 'btn-primary' : 'btn-ghost'}" data-c="${k}" aria-pressed="${onceki === k}">${ETIKET[k]}</button>`).join('')}</div>
      <p class="tiny" id="plan-durum" role="status"></p>
      <p class="tiny">Yalnızca yazdığın takma ad ve yanıtın kaydedilir; giriş gerekmez. Bağlantıyı bilen herkes yanıt verebilir.</p>
    </form>
    <p><a class="btn btn-primary" href="${esc(bilet)}">Bilet al</a> <a class="btn btn-ghost" href="${esc(oyun)}">Oyunu gör</a></p>
    <div id="plan-sahip"></div>
  </section>`);
  $('#plan-ad').value = depo.oku('tiyatrol.plan.ad') || '';
  $$('#plan-form [data-c]').forEach((b) => b.addEventListener('click', async () => {
    const ad = $('#plan-ad').value.trim(), d = $('#plan-durum');
    if (!ad) { d.textContent = 'Önce bir takma ad yaz.'; $('#plan-ad').focus(); return; }
    $$('#plan-form [data-c]').forEach((x) => { x.disabled = true; });
    d.textContent = 'Kaydediliyor…';
    try {
      await (await fonksiyon('respondPlan'))({ planId: ID, name: ad, choice: b.dataset.c, clientKey: cihazAnahtari() });
      depo.yaz('tiyatrol.plan.' + ID, b.dataset.c); depo.yaz('tiyatrol.plan.ad', ad);
      d.textContent = 'Yanıtın kaydedildi. Fikrin değişirse tekrar dokunabilirsin.';
      $$('#plan-form [data-c]').forEach((x) => { const on = x === b; x.className = `btn ${on ? 'btn-primary' : 'btn-ghost'}`; x.setAttribute('aria-pressed', String(on)); });
      const s = await getDoc(doc(db, 'Plan', ID)); const cc = s.data()?.counts || {};
      $$('.plan-say b').forEach((el, i) => { el.textContent = cc[['gelirim', 'belki', 'gelemem'][i]] || 0; });
    } catch (e) { d.textContent = apiHata(e).message; }
    $$('#plan-form [data-c]').forEach((x) => { x.disabled = false; });
  }));
  oturumDinle(async (u) => {
    const k = $('#plan-sahip'); if (!k || !u) return;
    try {
      const r = (await (await fonksiyon('getPlanResponses'))({ planId: ID })).data;
      k.innerHTML = `<h2>Yanıtlar</h2>${r.items.length ? `<ul class="plan-liste">${r.items.map((i) => `<li><b>${esc(i.name)}</b> <span class="tag">${esc(ETIKET[i.choice] || i.choice)}</span></li>`).join('')}</ul>` : '<p class="muted">Henüz yanıt yok.</p>'}`;
    } catch { /* plan sahibi değil: bölüm gösterilmez */ }
  });
}
ac();

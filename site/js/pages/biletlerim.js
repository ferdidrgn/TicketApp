// Biletlerim: Ticket where customerId == uid (canlı). Yaklaşan / Geçmiş, QR, takvime ekle, yol tarifi.
import { kabukCiz, hataKutusu } from '../ui.js';
import { girisGerekli, oturumDinle } from '../auth.js';
import { biletleriDinle, biletKarti, biletlerBagla, gecmisMi } from '../bilet-ortak.js';
import { $, esc } from '../util.js';

kabukCiz('');
const kok = $('#icerik');
const yaz = (h) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = h; };
let abone = null, liste = null, sekme = 'yaklasan', hataVar = false;

function girisEkrani() {
  yaz(`<section class="b-sayfa"><h1>Biletlerim</h1>
    <div class="empty" style="margin-top:28px"><h3>Biletlerini görmek için giriş yap</h3><p>Aldığın biletler hesabında saklanır; QR kodunla girişte gösterebilirsin.</p>
    <p style="margin-top:16px"><button type="button" class="btn btn-primary" id="giris">Giriş yap</button></p></div></section>`);
  $('#giris').addEventListener('click', () => girisGerekli('Biletlerini görmek için giriş yap.'));
}

function ciz() {
  if (hataVar) return yaz(`<section class="b-sayfa"><h1>Biletlerim</h1><div style="margin-top:24px">${hataKutusu('Biletlerin yüklenemedi. Bağlantını kontrol edip sayfayı yenile.')}</div></section>`);
  if (!liste) return yaz('<section class="b-sayfa"><h1>Biletlerim</h1><div class="b-liste" style="margin-top:36px"><div class="skel" style="height:190px"></div><div class="skel" style="height:190px"></div></div></section>');
  const yak = liste.filter((b) => !gecmisMi(b)).sort((a, b) => (a.when || 0) - (b.when || 0));
  const gec = liste.filter(gecmisMi).sort((a, b) => b.when - a.when);
  const goster = sekme === 'yaklasan' ? yak : gec;
  const bos = sekme === 'yaklasan'
    ? '<div class="empty"><h3>Yaklaşan biletin yok</h3><p>Bir oyun seçip koltuğunu ayırtabilirsin.</p><p style="margin-top:16px"><a class="btn btn-primary" href="/kesfet">Oyunlara göz at</a></p></div>'
    : '<div class="empty"><h3>Geçmiş biletin yok</h3><p>İzlediğin oyunların biletleri burada birikir.</p></div>';
  yaz(`<section class="b-sayfa"><h1>Biletlerim</h1>
    <p class="muted">${liste.length ? `${liste.length} bilet` : 'Henüz biletin yok.'}</p>
    <div class="b-sekmeler" role="tablist" aria-label="Bilet listesi">
      <button type="button" role="tab" class="chip ${sekme === 'yaklasan' ? 'on' : ''}" aria-selected="${sekme === 'yaklasan'}" data-s="yaklasan">Yaklaşan (${yak.length})</button>
      <button type="button" role="tab" class="chip ${sekme === 'gecmis' ? 'on' : ''}" aria-selected="${sekme === 'gecmis'}" data-s="gecmis">Geçmiş (${gec.length})</button></div>
    ${goster.length ? `<div class="b-liste" role="tabpanel">${goster.map((b, i) => biletKarti(b, i)).join('')}</div>` : bos}</section>`);
  kok.querySelectorAll('[data-s]').forEach((b) => b.addEventListener('click', () => { sekme = b.dataset.s; ciz(); }));
  biletlerBagla(kok, liste);
}

oturumDinle((u) => {
  abone?.(); abone = null; liste = null; hataVar = false;
  if (!u) return girisEkrani();
  ciz();
  abone = biletleriDinle(u.uid, (l) => { liste = l; hataVar = false; ciz(); }, (e) => { console.warn('Ticket dinlenemedi', e?.code); hataVar = true; ciz(); });
});
void esc;

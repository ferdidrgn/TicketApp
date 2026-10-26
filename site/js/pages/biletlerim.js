// Biletlerim: Ticket where customerId == uid (canlı). Yaklaşan / Geçmiş, QR, takvime ekle, yol tarifi.
import { kabukCiz, hataKutusu } from '../ui.js';
import { girisGerekli, oturumDinle } from '../auth.js';
import { biletleriDinle, biletKarti, biletlerBagla, gecmisMi, ayarla, iptalSaati } from '../bilet-ortak.js';
import { biletIptal, satisAyari } from '../bilet-api.js';
import { tarihUzun, saat } from '../util.js';
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
  const aktif = liste.filter((b) => !b.iptalEdildi);
  const yak = aktif.filter((b) => !gecmisMi(b)).sort((a, b) => (a.when || 0) - (b.when || 0));
  const gec = aktif.filter(gecmisMi).sort((a, b) => b.when - a.when);
  const ipt = liste.filter((b) => b.iptalEdildi).sort((a, b) => (b.when || 0) - (a.when || 0));
  const goster = sekme === 'yaklasan' ? yak : sekme === 'gecmis' ? gec : ipt;
  const bos = sekme === 'yaklasan'
    ? '<div class="empty"><h3>Yaklaşan biletin yok</h3><p>Bir oyun seçip koltuğunu ayırtabilirsin.</p><p style="margin-top:16px"><a class="btn btn-primary" href="/kesfet">Oyunlara göz at</a></p></div>'
    : sekme === 'iptal' ? '<div class="empty"><h3>İptal ettiğin bilet yok</h3><p>İptal edilen biletler burada görünür.</p></div>'
    : '<div class="empty"><h3>Geçmiş biletin yok</h3><p>İzlediğin oyunların biletleri burada birikir.</p></div>';
  yaz(`<section class="b-sayfa"><h1>Biletlerim</h1>
    <p class="muted">${liste.length ? `${liste.length} bilet` : 'Henüz biletin yok.'}</p>
    <div class="b-sekmeler" role="tablist" aria-label="Bilet listesi">
      <button type="button" role="tab" class="chip ${sekme === 'yaklasan' ? 'on' : ''}" aria-selected="${sekme === 'yaklasan'}" data-s="yaklasan">Yaklaşan (${yak.length})</button>
      <button type="button" role="tab" class="chip ${sekme === 'gecmis' ? 'on' : ''}" aria-selected="${sekme === 'gecmis'}" data-s="gecmis">Geçmiş (${gec.length})</button>
      ${ipt.length || sekme === 'iptal' ? `<button type="button" role="tab" class="chip ${sekme === 'iptal' ? 'on' : ''}" aria-selected="${sekme === 'iptal'}" data-s="iptal">İptal (${ipt.length})</button>` : ''}</div>
    ${goster.length ? `<div class="b-liste" role="tabpanel">${goster.map((b, i) => biletKarti(b, i)).join('')}</div>` : bos}</section>`);
  kok.querySelectorAll('[data-s]').forEach((b) => b.addEventListener('click', () => { sekme = b.dataset.s; ciz(); }));
  biletlerBagla(kok, liste, iptalSor);
}

// ---------- İptal onay penceresi ----------
function iptalSor(b, tetik) {
  const onceki = document.activeElement;
  const bg = document.createElement('div');
  bg.className = 'iptal-bg';
  bg.innerHTML = `<div class="iptal-kutu" role="dialog" aria-modal="true" aria-labelledby="ip-b" aria-describedby="ip-m">
    <h2 id="ip-b">Bileti iptal et?</h2>
    <p id="ip-m"><b>${esc(b.ad)}</b>${b.when ? ` · ${tarihUzun(b.when)} ${saat(b.when)}` : ''}<br>Koltuk: ${esc(b.koltuklar.join(', '))}. İptal edince koltuklar yeniden satışa açılır; bu işlem geri alınamaz. Etkinlikten ${iptalSaati()} saat öncesine kadar iptal edebilirsin.</p>
    <div class="mesaj" role="alert" id="ip-h"></div>
    <div class="iptal-btnlar"><button type="button" class="btn btn-ghost" data-vaz>Vazgeç</button><button type="button" class="btn btn-primary" data-onay>Evet, iptal et</button></div></div>`;
  document.body.append(bg);
  const kutu = bg.firstElementChild, vaz = bg.querySelector('[data-vaz]'), onay = bg.querySelector('[data-onay]');
  const kapat = () => { document.removeEventListener('keydown', tus, true); bg.remove(); (tetik?.isConnected ? tetik : onceki)?.focus?.(); };
  const tus = (e) => {
    if (e.key === 'Escape') { e.preventDefault(); if (!onay.disabled) kapat(); return; }
    if (e.key !== 'Tab') return;
    const o = [...kutu.querySelectorAll('button:not([disabled])')]; if (!o.length) return;
    const ilk = o[0], son = o[o.length - 1];
    if (e.shiftKey && document.activeElement === ilk) { e.preventDefault(); son.focus(); }
    else if (!e.shiftKey && document.activeElement === son) { e.preventDefault(); ilk.focus(); }
  };
  document.addEventListener('keydown', tus, true);
  bg.addEventListener('mousedown', (e) => { if (e.target === bg && !onay.disabled) kapat(); });
  vaz.addEventListener('click', kapat);
  onay.addEventListener('click', async () => {
    onay.disabled = vaz.disabled = true; onay.textContent = 'İptal ediliyor…'; bg.querySelector('#ip-h').textContent = '';
    try { await biletIptal(b.id); kapat(); } // liste canlı dinlendiği için kendiliğinden yenilenir
    catch (e) { onay.disabled = vaz.disabled = false; onay.textContent = 'Evet, iptal et'; bg.querySelector('#ip-h').textContent = e.message; }
  });
  vaz.focus();
}

oturumDinle((u) => {
  abone?.(); abone = null; liste = null; hataVar = false;
  if (!u) return girisEkrani();
  ciz();
  satisAyari().then((a) => { ayarla(a); if (liste) ciz(); });
  abone = biletleriDinle(u.uid, (l) => { liste = l; hataVar = false; ciz(); }, (e) => { console.warn('Ticket dinlenemedi', e?.code); hataVar = true; ciz(); });
});
void esc;

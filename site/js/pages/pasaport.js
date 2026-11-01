// Tiyatro Pasaportu: yalnız oturum sahibinin biletlerinden (Ticket.customerId == uid) istemcide hesaplanır; hiçbir şey yazılmaz.
import { kabukCiz, hataKutusu } from '../ui.js';
import { girisGerekli, oturumDinle } from '../auth.js';
import { biletleriDinle } from '../bilet-ortak.js';
import { pasaportHesapla, paylasimMetni } from '../pasaport-cekirdek.js';
import { $, esc } from '../util.js';

kabukCiz('');
const kok = $('#icerik');
const yaz = (h) => { kok.setAttribute('aria-busy', 'false'); kok.innerHTML = h; };
let abone = null, liste = null, hataVar = false, son = null;
const BASLIK = '<h1>Tiyatro pasaportum</h1>';
const tarihGG = (d) => d ? `${String(d.getDate()).padStart(2, '0')}.${String(d.getMonth() + 1).padStart(2, '0')}.${d.getFullYear()}` : '';

function girisEkrani() {
  yaz(`<section class="ps-sayfa">${BASLIK}<div class="empty"><h3>Pasaportunu görmek için giriş yap</h3><p>Pasaport yalnız sana görünür; biletlerinden hesaplanır.</p>
    <p style="margin-top:16px"><button type="button" class="btn btn-primary" id="giris">Giriş yap</button></p></div></section>`);
  $('#giris').addEventListener('click', () => girisGerekli('Pasaportunu görmek için giriş yap.'));
}

/** Biletlerim normalleştirmesinden pasaport girdisi. */
const girdiye = (b) => ({
  id: b.id, eventId: b.eventId, showId: b.showId, showName: b.ad, stageId: b.stageId, stageName: b.sahne, resim: b.resim,
  iptal: b.iptalEdildi, odeme: b.odeme, usedAt: b.usedAtHam, tarih: b.eventDateHam || b.when,
});

function ciz() {
  if (hataVar) return yaz(`<section class="ps-sayfa">${BASLIK}${hataKutusu('Pasaportun yüklenemedi. Bağlantını kontrol edip sayfayı yenile.')}</section>`);
  if (!liste) return yaz(`<section class="ps-sayfa">${BASLIK}<div class="skel" style="height:220px"></div></section>`);
  const p = son = pasaportHesapla(liste.map(girdiye), new Date());
  const kazanilan = p.rozetler.filter((r) => r.kazanildi);
  yaz(`<section class="ps-sayfa">${BASLIK}
    <div class="ps-kapak" role="group" aria-label="Pasaport özeti: ${p.oyunSayisi} oyun, ${p.sahneSayisi} sahne, bu yıl ${p.buYil} oyun">
      <div><small>TİYATROL</small><h2>Tiyatro Pasaportu</h2></div>
      <div class="ps-sayilar"><div><b>${p.oyunSayisi}</b><span>oyun</span></div><div><b>${p.sahneSayisi}</b><span>sahne</span></div><div><b>${p.buYil}</b><span>bu yıl</span></div></div>
      <div class="ps-kazanilan">${kazanilan.length ? esc(kazanilan.map((r) => r.ad).join(' · ')) : 'İlk perde seni bekliyor.'}</div>
    </div>
    <div class="ps-eylem"><button type="button" class="btn btn-primary" id="ps-indir">Görsel kartı indir</button></div>
    ${p.bos ? `<div class="empty"><h3>Pasaportun henüz boş</h3><p>Bir oyunu izlediğinde (seansı geçmiş ya da biletin kapıdan geçmiş olsun) sahnenin damgası buraya düşer.</p><p style="margin-top:16px"><a class="btn btn-primary" href="/kesfet">Oyunlara göz at</a></p></div>` : `
    <section class="ps-bolum"><h2>Sahne damgaları</h2><div class="ps-damgalar">${p.damgalar.map((d, i) => `<div class="ps-damga" style="--egim:${(i % 2 ? 1 : -1) * (3 + (i % 3))}deg;--gec:${Math.min(i * 90, 540)}ms" role="img" aria-label="${esc(d.ad)} damgası, ${d.sayi} oyun"><b>${esc(d.ad)}</b><small>${esc(tarihGG(d.ilk))}</small><i>×${d.sayi}</i></div>`).join('')}</div></section>
    <section class="ps-bolum"><h2>İzlediğin oyunlar</h2><div class="ps-liste">${p.izlenenler.map((x) => `<div class="ps-oyun">${x.resim ? `<img src="${esc(x.resim)}" alt="" loading="lazy" onerror="this.replaceWith(Object.assign(document.createElement('div'),{className:'ph'}))">` : '<div class="ph"></div>'}<div><b>${esc(x.ad)}</b><span>${esc([tarihGG(x.tarih), x.sahne].filter(Boolean).join(' · '))}</span></div></div>`).join('')}</div></section>`}
    <section class="ps-bolum"><h2>Rozetler</h2><div class="ps-rozetler">${p.rozetler.map((r) => r.kazanildi
      ? `<div class="ps-rozet acik"><span class="ik" aria-hidden="true">★</span><div><b>${esc(r.ad)}</b></div><span class="oran">Kazanıldı</span></div>`
      : `<div class="ps-rozet"><span class="ik" aria-hidden="true">🔒</span><div style="flex:1;min-width:0"><b>${esc(r.ad)}</b><p>${esc(r.nasil)}</p><progress max="${r.hedef}" value="${r.simdiki}" aria-label="${esc(r.ad)} ilerlemesi"></progress></div><span class="oran">${r.simdiki}/${r.hedef}</span></div>`).join('')}</div></section>
    <p class="ps-not">Pasaport yalnız sana görünür; biletlerinden tarayıcıda hesaplanır. İptal edilen ve gelinmeyen biletler sayılmaz.</p></section>`);
  $('#ps-indir')?.addEventListener('click', () => kartIndir(p));
}

// ---------- Görsel kart: canvas -> PNG. Afiş/uzak görsel YOK (CORS), kişisel veri YOK ----------
function kartIndir(p) {
  const cs = getComputedStyle(document.documentElement);
  const renk = (ad, y) => cs.getPropertyValue(ad).trim() || y;
  const accent = renk('--accent', '#c50337'), ink = renk('--accent-ink', '#ffffff');
  const W = 1080, H = 1350, c = document.createElement('canvas'); c.width = W; c.height = H;
  const x = c.getContext('2d');
  const g = x.createLinearGradient(0, 0, W, H); g.addColorStop(0, accent); g.addColorStop(1, '#14060b');
  x.fillStyle = g; x.fillRect(0, 0, W, H);
  x.fillStyle = ink; x.textBaseline = 'alphabetic';
  x.globalAlpha = .8; x.font = '700 30px Inter, sans-serif'; x.fillText('T İ Y A T R O L', 80, 120);
  x.globalAlpha = 1; x.font = '800 84px "Playfair Display", Georgia, serif'; x.fillText('Tiyatro Pasaportu', 80, 230);
  [[p.oyunSayisi, 'oyun'], [p.sahneSayisi, 'sahne'], [p.buYil, 'bu yıl']].forEach(([n, e], i) => {
    x.font = '800 150px "Playfair Display", Georgia, serif'; x.fillText(String(n), 80 + i * 330, 440);
    x.globalAlpha = .8; x.font = '600 36px Inter, sans-serif'; x.fillText(e, 84 + i * 330, 495); x.globalAlpha = 1;
  });
  // damgalar (en çok 8)
  p.damgalar.slice(0, 8).forEach((d, i) => {
    const cx = 190 + (i % 4) * 233, cy = 720 + Math.floor(i / 4) * 250;
    x.save(); x.translate(cx, cy); x.rotate(((i % 2 ? 1 : -1) * (3 + (i % 3)) * Math.PI) / 180);
    x.strokeStyle = ink; x.lineWidth = 6; x.beginPath(); x.arc(0, 0, 100, 0, Math.PI * 2); x.stroke();
    x.textAlign = 'center'; x.font = '800 24px Inter, sans-serif';
    const kelimeler = d.ad.split(/\s+/); let satir = '', y = -8; const satirlar = [];
    for (const k of kelimeler) { if (x.measureText(`${satir} ${k}`.trim()).width > 150 && satir) { satirlar.push(satir); satir = k; } else satir = `${satir} ${k}`.trim(); }
    satirlar.push(satir); satirlar.slice(0, 2).forEach((s, j) => x.fillText(s.length > 16 ? s.slice(0, 15) + '…' : s, 0, y + j * 28 - (satirlar.length > 1 ? 10 : 0)));
    x.font = '700 22px Inter, sans-serif'; x.fillText(`×${d.sayi}`, 0, 55);
    x.restore();
  });
  if (!p.damgalar.length) { x.font = '600 40px Inter, sans-serif'; x.fillText('İlk perde seni bekliyor.', 80, 760); }
  const kz = p.rozetler.filter((r) => r.kazanildi).map((r) => r.ad).join(' · ');
  x.textAlign = 'left'; x.font = '700 38px Inter, sans-serif'; x.fillText(kz || 'Rozetler seni bekliyor', 80, 1220);
  x.globalAlpha = .7; x.font = '600 28px Inter, sans-serif'; x.fillText('tiyatrol.com', 80, 1280);
  c.toBlob((blob) => {
    if (!blob) return;
    const u = URL.createObjectURL(blob), a = document.createElement('a');
    a.href = u; a.download = 'tiyatrol-pasaport.png'; document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(u), 4000);
  }, 'image/png');
  void paylasimMetni;
}

oturumDinle((u) => {
  abone?.(); abone = null; liste = null; hataVar = false;
  if (!u) return girisEkrani();
  ciz();
  abone = biletleriDinle(u.uid, (l) => { liste = l; hataVar = false; ciz(); }, (e) => { console.warn('Ticket dinlenemedi', e?.code); hataVar = true; ciz(); });
});
window.__pasaport = () => son; // test/hata ayıklama: son hesaplanan özet

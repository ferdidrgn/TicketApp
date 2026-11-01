import '../theme.js';
import { kabukCiz } from '../ui.js';
import { temaOku, temaYaz, temaSecenekleri } from '../theme.js';
import { erisimOku, erisimYaz, pwaKurulabilir, pwaKur } from '../ozellik.js';
import { favListe, bildir } from '../fav.js';
import { ilOku, ilYaz } from '../iller.js';
import { $, $$, esc } from '../util.js';
import { baslikYaz } from '../detay.js';
import { oturumDinle, mevcut } from '../auth.js';
import { tercihOku, tercihYaz, tercihNormal, tercihKartiHtml, tercihBagla } from '../bildirim-tercih.js';
import { silmeModaliAc, silmeyiIptalEt, silmeDurumu, silmeBekliyor, tarihTR } from '../hesap-sil.js';

kabukCiz('');
baslikYaz('Ayarlar', 'Görünüm, erişilebilirlik ve veri ayarları.');
const ic = $('#icerik');
ciz();
document.addEventListener('pwa-hazir', ciz);
let sonUid;
let np = null; // bildirim tercihleri (giriş yapmış kullanıcı için yüklenir)
oturumDinle((u) => { if ((u?.uid || '') !== sonUid) { sonUid = u?.uid || ''; np = null; ciz(); } });
document.addEventListener('silme-durumu', ciz);

function hesapKarti() {
  if (!mevcut()) return '';
  if (silmeBekliyor()) {
    const t = silmeDurumu().tarih;
    return `<section class="ay-kart"><h2>Hesap</h2><p><b>Silinmek üzere${t ? ` — ${esc(tarihTR(t))}` : ''}</b><br>Hesabın bu tarihte kalıcı olarak silinecek. O güne kadar vazgeçebilirsin.</p>
      <div><button class="btn btn-primary btn-sm" id="sil-iptal">Silmeyi iptal et</button></div></section>`;
  }
  return `<section class="ay-kart"><h2>Hesap</h2><p>Hesabını silersen 30 günlük bekleme süresi başlar; bu sürede giriş yapıp vazgeçebilirsin.</p>
    <div><button class="btn btn-ghost btn-sm btn-tehlike" id="sil-ac" aria-haspopup="dialog">Hesabımı sil</button></div></section>`;
}

function ciz() {
  const t = temaOku(), e = erisimOku();
  const fav = favListe();
  ic.innerHTML = `<div class="pg-ust"><h1>Ayarlar</h1><p>Seçimlerin bu tarayıcıda saklanır; hesap gerekmez.</p></div>
  <div class="ay-izgara">
    <section class="ay-kart"><h2>Görünüm</h2><p>Mod ve renk paleti tüm sitede geçerli olur.</p>
      <div class="seg">${[['sistem', 'Sistem'], ['gunduz', 'Gündüz'], ['gece', 'Gece']].map(([k, a]) => `<button data-mod="${k}" class="${t.mod === k ? 'on' : ''}">${a}</button>`).join('')}</div>
      <div class="onizleme">${temaSecenekleri.map((p) => `<button data-pal="${p.id}" class="${t.palet === p.id ? 'on' : ''}"><i style="background:${p.renk}"></i>${p.ad.replace(' (Material)', '')}</button>`).join('')}<button data-pal="ozel" class="${t.palet === 'ozel' ? 'on' : ''}"><i style="background:${t.ozel}"></i>Özel renk</button></div>
      ${t.palet === 'ozel' ? `<input type="color" id="ozel" value="${t.ozel}" style="width:100%;height:48px;border-radius:12px;border:1px solid var(--line);background:var(--bg)">` : ''}</section>
    <section class="ay-kart"><h2>Erişilebilirlik</h2><p>Okumayı ve gezinmeyi kolaylaştıran seçenekler.</p>
      <div class="ay-sat"><span>Yazı boyutu <b id="yz">${e.yazi}%</b></span><input type="range" id="yazi" min="90" max="150" step="5" value="${e.yazi}" style="accent-color:var(--accent);width:55%" aria-label="Yazı boyutu"></div>
      ${[['kontrast', 'Yüksek kontrast', e.kontrast], ['sade', 'Hareketi azalt (animasyonsuz)', e.sade], ['okuma', 'Okuma kolaylığı (geniş satır aralığı)', e.okuma]].map(([k, a, v]) => `<div class="ay-sat"><span>${a}</span><button class="anahtar" data-e="${k}" aria-pressed="${!!v}" aria-label="${a}"></button></div>`).join('')}</section>
    <section class="ay-kart"><h2>Konum</h2><p>Seçili il: <b>${esc(ilOku() || 'Tüm Türkiye')}</b>. İli başlıktaki konum düğmesinden değiştirebilirsin.</p><button class="btn btn-ghost btn-sm" id="il-sil">İl seçimini temizle</button></section>
    <section class="ay-kart"><h2>Favoriler ve veri</h2><p>${fav.length} favorin var. Giriş yaptıysan favorilerin hesabında saklanır ve her cihazda aynıdır; girişsizken yalnız bu tarayıcıda durur.</p>
      <div style="display:flex;gap:8px;flex-wrap:wrap"><button class="btn btn-primary btn-sm" id="yedek">Yedek bağlantısı kopyala</button><button class="btn btn-ghost btn-sm" id="ice">Yedek bağlantısı yapıştır</button><button class="btn btn-ghost btn-sm" id="temizle">Tüm yerel verimi sil</button></div></section>
    <section class="ay-kart"><h2>Uygulama gibi kullan</h2><p>Siteyi ana ekrana ekle; çevrimdışıyken son baktığın sayfalar açılır.</p>
      ${pwaKurulabilir() ? '<button class="btn btn-primary btn-sm" id="kur">Ana ekrana ekle</button>' : '<p class="tiny">Tarayıcı menüsünden “Ana ekrana ekle / Uygulamayı yükle” seçeneğini kullanabilirsin.</p>'}</section>
    ${mevcut() ? (np ? tercihKartiHtml(np) : '<section class="ay-kart" id="np-kart"><h2>Bildirimler</h2><p>Yükleniyor…</p></section>') : ''}
    ${hesapKarti()}
    <section class="ay-kart"><h2>Klavye kısayolları</h2><p>Sayfada <kbd>?</kbd> tuşuna basarak tüm kısayolları görebilirsin: <kbd>/</kbd> ara, <kbd>g</kbd> <kbd>h</kbd> vitrin, <kbd>g</kbd> <kbd>k</kbd> oyunlar.</p></section>
  </div>`;
  $$('[data-mod]').forEach((b) => b.addEventListener('click', () => { temaYaz({ mod: b.dataset.mod }); ciz(); }));
  $$('[data-pal]').forEach((b) => b.addEventListener('click', () => { temaYaz({ palet: b.dataset.pal }); ciz(); }));
  $('#ozel')?.addEventListener('input', (ev) => temaYaz({ palet: 'ozel', ozel: ev.target.value }));
  $('#yazi').addEventListener('input', (ev) => { $('#yz').textContent = ev.target.value + '%'; erisimYaz({ yazi: +ev.target.value }); });
  $$('[data-e]').forEach((b) => b.addEventListener('click', () => { erisimYaz({ [b.dataset.e]: b.getAttribute('aria-pressed') !== 'true' }); ciz(); }));
  $('#il-sil').addEventListener('click', () => { ilYaz(''); ciz(); });
  $('#yedek').addEventListener('click', async () => { const u = `${location.origin}/favoriler?al=${btoa(unescape(encodeURIComponent(JSON.stringify(favListe()))))}`; try { await navigator.clipboard.writeText(u); bildir('Yedek bağlantısı kopyalandı'); } catch { prompt('Bağlantıyı kopyala:', u); } });
  $('#ice').addEventListener('click', () => { const u = prompt('Yedek bağlantısını yapıştır:'); if (!u) return; try { location.href = new URL(u).pathname + new URL(u).search; } catch { bildir('Geçersiz bağlantı'); } });
  $('#temizle').addEventListener('click', () => { if (confirm('Favoriler, tema, il ve diğer yerel verilerin silinsin mi?')) { try { localStorage.clear(); sessionStorage.clear(); } catch {} location.reload(); } });
  if (mevcut() && !np) { const uid = mevcut().uid; tercihOku(uid).then((t) => { if (mevcut()?.uid === uid) { np = t; ciz(); } }).catch(() => { np = tercihNormal(null); ciz(); }); }
  else if (np && $('#np-kart')) { const uid = mevcut().uid; tercihBagla($('#np-kart'), np, (y) => tercihYaz(uid, y)); $('#np-kart').addEventListener('np-degisti', ciz); }
  $('#sil-ac')?.addEventListener('click', () => silmeModaliAc());
  $('#sil-iptal')?.addEventListener('click', async (ev) => { ev.currentTarget.disabled = true; await silmeyiIptalEt(); });
  $('#kur')?.addEventListener('click', async () => { if (await pwaKur()) bildir('Eklendi'); ciz(); });
}

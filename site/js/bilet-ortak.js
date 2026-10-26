// Bilet gösterimi için ortak parçalar (Biletlerim + ödeme sonucu): normalleştirme, kart, QR, takvim, yol tarifi.
// Biletler yalnızca sahibi tarafından okunur (Firestore kuralı: customerId == uid); burada hiçbir şey yazılmaz.
import { db, collection, query, where, onSnapshot } from './firebase.js';
import { yukle } from './store.js';
import { qrSvg } from './qr.js';
import { takvimMenusu, dakikaOku } from './detay.js';
import { esc, tl, sayi, tarihAyristir, tarihUzun, saat, linkOf, $$ } from './util.js';

/** Kullanıcının biletlerini canlı dinler. cb(liste) normalleştirilmiş ve zenginleştirilmiş biletlerle çağrılır. */
export function biletleriDinle(uid, cb, hataCb) {
  const q = query(collection(db, 'Ticket'), where('customerId', '==', uid));
  return onSnapshot(q, async (snap) => {
    let veri = null; try { veri = await yukle(); } catch {}
    cb(snap.docs.map((d) => normallestir({ ...d.data(), id: d.id }, veri)));
  }, (e) => hataCb?.(e));
}

export function normallestir(t, veri) {
  const ev = veri?.events.find((e) => e.docId === t.eventId || e.id === t.eventId);
  const show = ev?.show || veri?.showById.get(t.showId) || null;
  const stage = ev?.stage || veri?.stageById.get(t.stageId) || null;
  const when = tarihAyristir(t.eventDate) || ev?.when || null;
  const koltuklar = Array.isArray(t.buySeats) ? t.buySeats.map(String) : [];
  return {
    id: String(t.id), eventId: t.eventId || '', orderId: t.orderId || '',
    ad: t.showName || show?.name || 'Tiyatro oyunu',
    resim: t.showImageUrl || show?.imageUrl || '',
    sahne: t.stageName || stage?.name || '',
    adres: stage?.address || '', lat: stage?.lat ?? null, lng: stage?.lng ?? null,
    when, koltuklar, tutar: sayi(t.orderPrice), show, dakika: dakikaOku(show?.duration),
    yontem: t.orderMethod || '', odeme: t.paymentStatus || '',
    kullanildi: !!t.usedAt, iptalEdildi: !!t.cancelledAt || t.paymentStatus === 'cancelled',
  };
}

export const gecmisMi = (b) => !!b.when && b.when.getTime() < Date.now() - 3 * 3600e3;

// Satış ayarı (Config/satis) sayfalarca bir kez okunup buraya verilir; iptal penceresi için kullanılır.
const AYAR = { iptalSaat: 24 };
export const ayarla = (a) => { if (a && Number.isFinite(a.iptalSaat)) AYAR.iptalSaat = a.iptalSaat; };

/** Durum rozeti: { ad, sinif } ya da null. */
export function durumRozeti(b) {
  if (b.iptalEdildi) return { ad: 'İptal', sinif: 'iptal' };
  if (b.odeme === 'no_show') return { ad: 'Gelmedi', sinif: 'gelmedi' };
  if (b.odeme === 'paid') return { ad: 'Ödendi', sinif: 'ok' };
  if (b.odeme === 'pay_at_venue' || b.yontem === 'venue') return { ad: 'Rezervasyon · ödeme sahnede', sinif: 'rez' };
  if (b.yontem === 'free' || b.tutar === 0) return { ad: 'Ücretsiz', sinif: 'ok' };
  return null;
}
/** İptal düğmesi yalnızca sunucunun izin vereceği biletlerde gösterilir (asıl denetim sunucuda). */
export function iptalEdilebilir(b) {
  if (b.iptalEdildi || b.kullanildi || !b.when) return false;
  if (!['venue', 'free'].includes(b.yontem)) return false;
  if (['paid', 'no_show', 'cancelled'].includes(b.odeme)) return false;
  return b.when.getTime() - Date.now() >= AYAR.iptalSaat * 3600e3;
}
export const iptalSaati = () => AYAR.iptalSaat;

export function yolTarifi(b) {
  const hedef = b.lat && b.lng ? `${b.lat},${b.lng}` : encodeURIComponent([b.sahne, b.adres].filter(Boolean).join(' '));
  return hedef ? `https://www.google.com/maps/dir/?api=1&destination=${hedef}` : '';
}

/** QR içeriği: yalnızca bilet kimliği (sır değil; kapıda sunucu tarafında doğrulanır). */
export const qrIcerik = (b) => `TIYATROL:${b.id}`;

export function biletKarti(b, i = 0) {
  const gecmis = gecmisMi(b);
  const yol = yolTarifi(b);
  const tutar = b.tutar === 0 ? 'Ücretsiz' : b.tutar != null ? tl(b.tutar) : '';
  const link = b.show ? linkOf('oyun', b.show) : '';
  const rz = durumRozeti(b);
  const sahnede = rz?.sinif === 'rez' && b.tutar > 0;
  return `<article class="bilet-k ${gecmis ? 'gecmis' : ''} ${b.iptalEdildi ? 'iptal' : ''}" style="animation-delay:${Math.min(i * 60, 360)}ms" data-bilet="${esc(b.id)}">
    <div class="bk-sol">${b.resim ? `<img src="${esc(b.resim)}" alt="" loading="lazy" onerror="this.replaceWith(Object.assign(document.createElement('div'),{className:'ph',textContent:this.dataset.ad}))" data-ad="${esc(b.ad)}">` : `<div class="ph">${esc(b.ad)}</div>`}
      <div class="bk-g">${rz ? `<span class="durum-rozet ${rz.sinif}">${esc(rz.ad)}</span>` : ''}<h3>${link ? `<a href="${link}">${esc(b.ad)}</a>` : esc(b.ad)}</h3>
        <div class="sat">${b.when ? `${tarihUzun(b.when)} · ${saat(b.when)}` : 'Tarih bilgisi yok'}</div>
        <div class="sat">${esc(b.sahne || 'Sahne belirtilmedi')}</div>
        <div class="koltuklar" aria-label="Koltuklar">${b.koltuklar.map((k) => `<span>${esc(k)}</span>`).join('')}${tutar ? `<span style="background:transparent;padding-left:4px">${esc(tutar)}</span>` : ''}</div>
        ${sahnede && !b.iptalEdildi ? `<div class="odeme-not">Ödeme etkinlik günü sahnede: ${esc(tutar)}</div>` : ''}
        <div class="bk-act">${b.when && !gecmis && !b.iptalEdildi ? `<button type="button" class="btn btn-ghost" data-takvim="${esc(b.id)}">Takvime ekle</button>` : ''}${iptalEdilebilir(b) && !gecmis ? `<button type="button" class="btn btn-ghost tehlike" data-iptal="${esc(b.id)}" aria-label="${esc(b.ad)} biletini iptal et">İptal et</button>` : ''}${yol ? `<a class="btn btn-ghost" target="_blank" rel="noopener" href="${yol}">Yol tarifi</a>` : ''}</div>
      </div></div>
    <div class="bk-sag">${b.iptalEdildi ? '<small>İptal edildi</small>' : gecmis ? '<small>Geçmiş bilet</small>' : qrSvg(qrIcerik(b), { piksel: 132, etiket: `${b.ad} giriş QR kodu` })}<small>${b.iptalEdildi || gecmis ? esc(b.koltuklar.join(' · ')) : 'Girişte göster'}</small><code>${esc(b.id.slice(0, 10))}</code></div>
  </article>`;
}

/** Kart düğmelerini bağlar (takvime ekle). */
export function biletlerBagla(kok, liste, onIptal) {
  $$('[data-iptal]', kok).forEach((btn) => {
    if (btn.dataset.bagli) return; btn.dataset.bagli = '1';
    btn.addEventListener('click', () => { const b = liste.find((x) => x.id === btn.dataset.iptal); if (b && onIptal) onIptal(b, btn); });
  });
  $$('[data-takvim]', kok).forEach((btn) => {
    if (btn.dataset.bagli) return; btn.dataset.bagli = '1';
    btn.addEventListener('click', () => {
      const b = liste.find((x) => x.id === btn.dataset.takvim); if (!b?.when) return;
      takvimMenusu(btn, { baslik: b.ad, bas: b.when, dakika: b.dakika, yer: [b.sahne, b.adres].filter(Boolean).join(', '), aciklama: `Koltuk: ${b.koltuklar.join(', ')}`, url: b.show ? location.origin + linkOf('oyun', b.show) : location.origin });
    });
  });
}

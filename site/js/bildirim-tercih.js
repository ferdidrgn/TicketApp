// Bildirim tercihleri (web /ayarlar): User/{uid}.notifPrefs — sözleşme: docs/BILDIRIM-TERCIHLERI.md.
// Yalnız giriş yapmış kullanıcıya gösterilir. Yazım: tüm harita tek updateDoc (kurallar bilinmeyen anahtarı reddeder; sessiz saat iki alan birlikte).
import { db, doc, getDoc, updateDoc } from './firebase.js';
import { esc } from './util.js';
import { bildir } from './fav.js';

const VARSAYILAN = { loudAlarm: false, reminders: true, changes: true, thankYou: true, newShows: false, marketing: false };
const IZINLI = [...Object.keys(VARSAYILAN), 'quietStart', 'quietEnd'];
const SAAT = /^([01]\d|2[0-3]):[0-5]\d$/;

export const KATEGORILER = [
  ['reminders', 'Seans hatırlatmaları', 'Seansa yaklaşık 24 saat ve 2 saat kala.'],
  ['changes', 'İptal ve değişiklikler', 'Seans iptal, erteleme ve saat değişikliği. Önemli: açık bırakman önerilir.'],
  ['thankYou', 'Teşekkür ve yorum daveti', 'İzlediğin seanstan sonra "Nasıldı?" bildirimi.'],
  ['newShows', 'Yeni oyunlar ve seanslar', 'Yeni oyun ya da seans eklendiğinde (varsayılan kapalı).'],
  ['marketing', 'Kampanya ve duyurular', 'İndirim ve kampanya haberleri (varsayılan kapalı).'],
];

/** Ham haritadan güvenli tercih nesnesi (eksik/yanlış tür -> varsayılan). */
export function tercihNormal(ham) {
  const h = ham && typeof ham === 'object' && !Array.isArray(ham) ? ham : {};
  const o = {};
  for (const k of Object.keys(VARSAYILAN)) o[k] = typeof h[k] === 'boolean' ? h[k] : VARSAYILAN[k];
  const ok = SAAT.test(h.quietStart || '') && SAAT.test(h.quietEnd || '') && h.quietStart !== h.quietEnd;
  o.quietStart = ok ? h.quietStart : ''; o.quietEnd = ok ? h.quietEnd : '';
  return o;
}

/** Firestore'a yazılacak harita: yalnız izinli anahtarlar; sessiz saat yoksa iki alan da yok. */
export function tercihYazilacak(t) {
  const o = {};
  for (const k of Object.keys(VARSAYILAN)) o[k] = !!t[k];
  if (SAAT.test(t.quietStart || '') && SAAT.test(t.quietEnd || '') && t.quietStart !== t.quietEnd) { o.quietStart = t.quietStart; o.quietEnd = t.quietEnd; }
  return o;
}

export function tercihKartiHtml(t) {
  const sat = KATEGORILER.map(([k, ad, aciklama]) => `<div class="ay-sat"><span>${esc(ad)}<br><small class="tiny">${esc(aciklama)}</small></span>
      <button class="anahtar" data-np="${k}" aria-pressed="${!!t[k]}" aria-label="${esc(ad)}"></button></div>`).join('');
  const sessiz = !!t.quietStart;
  return `<section class="ay-kart" id="np-kart"><h2>Bildirimler</h2>
    <p>Hangi bildirimleri alacağını sen seçersin. Tercihlerin hesabında saklanır ve tüm cihazlarında geçerli olur.</p>
    ${sat}
    <div class="ay-sat"><span>Sessiz saatler<br><small class="tiny">Bu saatlerde teşekkür, yeni oyun ve kampanya bildirimi gelmez. İptal/değişiklik ve seansa 2 saat kala hatırlatma yine gelir.</small></span>
      <button class="anahtar" data-np="sessiz" aria-pressed="${sessiz}" aria-label="Sessiz saatler"></button></div>
    ${sessiz ? `<div class="ay-sat"><span>Saat aralığı</span><span style="display:flex;gap:8px;align-items:center">
      <input type="time" id="np-bas" value="${esc(t.quietStart)}" aria-label="Sessiz saat başlangıcı"> – <input type="time" id="np-bit" value="${esc(t.quietEnd)}" aria-label="Sessiz saat bitişi"></span></div>` : ''}
    <p class="tiny" id="np-durum" aria-live="polite"></p></section>`;
}

/** Karta olay bağlar. `al()` güncel tercihi, `yaz(yeni)` kaydı yapar (başarısızsa reddeder). */
export function tercihBagla(kok, t, yaz) {
  const durum = kok.querySelector('#np-durum');
  const kaydet = async (yeni) => {
    try { await yaz(yeni); Object.assign(t, yeni); if (durum) durum.textContent = 'Kaydedildi.'; bildir('Bildirim tercihin kaydedildi'); } catch { if (durum) durum.textContent = 'Kaydedilemedi, tekrar dene.'; bildir('Tercih kaydedilemedi'); }
  };
  kok.querySelectorAll('[data-np]').forEach((b) => b.addEventListener('click', async () => {
    const k = b.dataset.np;
    if (k === 'sessiz') {
      const ac = !t.quietStart;
      await kaydet(ac ? { ...t, quietStart: '23:00', quietEnd: '08:00' } : { ...t, quietStart: '', quietEnd: '' });
    } else await kaydet({ ...t, [k]: !t[k] });
    kok.dispatchEvent(new CustomEvent('np-degisti', { bubbles: true }));
  }));
  const saat = () => {
    const bas = kok.querySelector('#np-bas')?.value, bit = kok.querySelector('#np-bit')?.value;
    if (SAAT.test(bas || '') && SAAT.test(bit || '') && bas !== bit) kaydet({ ...t, quietStart: bas, quietEnd: bit });
    else if (durum) durum.textContent = 'Başlangıç ve bitiş saati farklı olmalı.';
  };
  kok.querySelector('#np-bas')?.addEventListener('change', saat);
  kok.querySelector('#np-bit')?.addEventListener('change', saat);
}

/** Hesaptan okur / hesaba yazar (giriş yapmış kullanıcı için). */
export async function tercihOku(uid) {
  const s = await getDoc(doc(db, 'User', uid));
  return tercihNormal(s.exists() ? s.data().notifPrefs : null);
}
export const tercihYaz = (uid, t) => updateDoc(doc(db, 'User', uid), { notifPrefs: tercihYazilacak(t) });

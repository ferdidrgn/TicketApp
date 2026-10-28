// Hesap silme (web): 30 gün bekleme süreli, geri alınabilir silme. Asıl kural ve güvenlik SUNUCUDADIR
// (Cloud Functions: requestAccountDeletion / cancelAccountDeletion / getAccountDeletionStatus; sözleşme: docs/HESAP-SILME.md; dryRun YOK -> önce açık onay, sonra çağrı).
//  - Gelecek tarihli aktif bileti olan hesap silinemez: sunucu failed-precondition + details.code 'UPCOMING_TICKETS' {count, nextEventDate, nextEventTitle?} döner.
//  - Bekleme süresinde User/{uid}.deletionStatus === 'pending' ve deletionScheduledAt dolu; yeni satın alma ACCOUNT_DELETION_PENDING ile reddedilir.
// İstemci yalnızca ÖNGÖSTERİM yapar (gelecek bileti varsa onay ekranına hiç gitmeden bilgilendirir); karar sunucunundur.
// Telefon / e-posta log'lanmaz; tarihler tr-TR.
import { auth, db, doc, getDoc, getDocs, collection, query, where, fonksiyon } from './firebase.js';
import { oturumDinle, mevcut, cikis } from './auth.js';
import { bildir } from './fav.js';
import { tarihAyristir } from './util.js';
import { $, esc } from './util.js';

// ---------- Yardımcılar ----------
/** Sunucudan / Firestore'dan gelen çeşitli zaman biçimlerini Date'e çevirir (ISO, ms, Timestamp, {_seconds}). */
export function tarihCoz(v) {
  if (v == null || v === '') return null;
  if (typeof v === 'number') return new Date(v < 1e12 ? v * 1000 : v);
  if (typeof v === 'object' && v._seconds != null) return new Date(v._seconds * 1000);
  const d = tarihAyristir(v);
  return d && !isNaN(d) ? d : null;
}
export const tarihTR = (d) => (d ? d.toLocaleDateString('tr-TR', { timeZone: 'Europe/Istanbul', day: 'numeric', month: 'long', year: 'numeric' }) : '');
const tarihSaatTR = (d) => (d ? `${tarihTR(d)}, ${d.toLocaleTimeString('tr-TR', { timeZone: 'Europe/Istanbul', hour: '2-digit', minute: '2-digit' })}` : '');
const BEKLEME_GUN = 30;

// ---------- Durum (pending mi?) ----------
let durum = { uid: '', bekliyor: false, tarih: null };
const bayat = () => durum.uid !== (mevcut()?.uid || '');
export const silmeDurumu = () => ({ ...durum });
export const silmeBekliyor = () => !bayat() && durum.bekliyor;
function durumYaz(d) {
  durum = { uid: mevcut()?.uid || '', bekliyor: !!d.bekliyor, tarih: d.tarih || null };
  document.dispatchEvent(new CustomEvent('silme-durumu', { detail: silmeDurumu() }));
}
async function durumOku(u) {
  if (!u) { durum = { uid: '', bekliyor: false, tarih: null }; return; }
  try {
    const s = await getDoc(doc(db, 'User', u.uid));
    const d = s.exists() ? s.data() : {};
    if (auth.currentUser?.uid !== u.uid) return;
    durum = { uid: u.uid, bekliyor: d.deletionStatus === 'pending', tarih: tarihCoz(d.deletionScheduledAt) };
  } catch { durum = { uid: u.uid, bekliyor: false, tarih: null }; }
  document.dispatchEvent(new CustomEvent('silme-durumu', { detail: silmeDurumu() }));
}

// ---------- Sunucu çağrıları ----------
function silHata(e) {
  const kod = String(e?.code || '').replace('functions/', '');
  const ayrinti = e?.details && typeof e.details === 'object' ? e.details : {};
  const dk = ayrinti.code || (typeof e?.details === 'string' ? e.details : '');
  if (kod === 'failed-precondition' && dk === 'UPCOMING_TICKETS') {
    return { tur: 'bilet', sayi: Number(ayrinti.count) || 0, tarih: tarihCoz(ayrinti.nextEventDate), baslik: String(ayrinti.nextEventTitle || '') };
  }
  if (kod === 'failed-precondition' && dk === 'ACCOUNT_DELETION_PENDING') return { tur: 'zatenBekliyor', tarih: tarihCoz(ayrinti.scheduledAt) };
  if (kod === 'failed-precondition' && dk === 'DELETION_IN_PROGRESS') return { tur: 'hata', mesaj: 'Hesabınızın silinme işlemi başladı, artık vazgeçilemez.' };
  const t = {
    unauthenticated: 'Oturumun kapanmış. Giriş yapıp tekrar dene.',
    'permission-denied': 'Bu işlem için yetkin yok.',
    'resource-exhausted': 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
    unavailable: 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.',
    'not-found': 'Silinmek üzere bir hesap kaydı bulunamadı.',
  }[kod];
  return { tur: 'hata', mesaj: t || 'İşlem şu an tamamlanamadı. Biraz sonra tekrar dene.' };
}
async function cagir(ad, veri = {}) {
  const f = await fonksiyon(ad);
  return (await f(veri)).data || {};
}

/** Silme isteğini sunucuya gönderir. Başarıda { tarih }, kural ihlalinde { tur:'bilet'|... } fırlatır. */
async function silmeIste() {
  try {
    const r = await cagir('requestAccountDeletion', {});
    const tarih = tarihCoz(r.scheduledAt ?? r.deletionScheduledAt) || new Date(Date.now() + BEKLEME_GUN * 864e5);
    return { tarih };
  } catch (e) { throw silHata(e); }
}

/** Bekleyen silmeyi iptal eder; durumu günceller. Başarıda true. Hata durumunda kullanıcıya bildirir ve false döner. */
let iptalDevam = false;
export async function silmeyiIptalEt() {
  if (iptalDevam) return false;
  iptalDevam = true;
  try {
    await cagir('cancelAccountDeletion', {});
    durumYaz({ bekliyor: false, tarih: null });
    bildir('Silme talebiniz iptal edildi. Hesabınız aktif.');
    return true;
  } catch (e) {
    const h = silHata(e);
    bildir(h.mesaj || 'Silme iptal edilemedi. Biraz sonra tekrar dene.');
    return false;
  } finally { iptalDevam = false; }
}

// ---------- Kalıcı banner (tüm sayfalar) ----------
let bannerKuruldu = false;
export function silmeBannerKur() {
  if (bannerKuruldu) return;
  bannerKuruldu = true;
  let el = null;
  const ciz = () => {
    const goster = silmeBekliyor();
    if (!goster) { el?.remove(); el = null; document.body.classList.remove('sil-banner-var'); return; }
    if (!el) {
      el = document.createElement('div');
      el.className = 'sil-banner';
      el.setAttribute('role', 'region');
      el.setAttribute('aria-label', 'Hesap silme durumu');
      document.body.prepend(el);
      el.addEventListener('click', async (e) => {
        const b = e.target.closest('[data-sil-iptal]'); if (!b || b.disabled) return;
        b.disabled = true; b.textContent = 'İptal ediliyor…';
        const ok = await silmeyiIptalEt();
        if (!ok && el) { b.disabled = false; b.textContent = 'Silmeyi iptal et'; }
      });
    }
    const t = durum.tarih;
    el.innerHTML = `<p><b>Silinmek üzere${t ? ` — ${esc(tarihTR(t))}` : ''}</b><span> Hesabınız ${t ? 'bu tarihte' : 'yakında'} kalıcı olarak silinecek; o güne kadar vazgeçebilirsin.</span></p><button type="button" class="btn btn-sm" data-sil-iptal>Silmeyi iptal et</button>`;
    document.body.classList.add('sil-banner-var');
  };
  oturumDinle(async (u) => { durum = { uid: u?.uid || '', bekliyor: false, tarih: null }; ciz(); await durumOku(u); });
  document.addEventListener('silme-durumu', ciz);
}

// ---------- Önizleme: gelecek tarihli bilet var mı? (yalnız UX; karar sunucunun) ----------
async function gelecekBiletler(uid) {
  const { normallestir } = await import('./bilet-ortak.js');
  let veri = null; try { const { yukle } = await import('./store.js'); veri = await yukle(); } catch {}
  const s = await getDocs(query(collection(db, 'Ticket'), where('customerId', '==', uid)));
  const simdi = Date.now();
  const l = s.docs.map((d) => normallestir({ ...d.data(), id: d.id }, veri))
    .filter((b) => !b.iptalEdildi && b.when && b.when.getTime() > simdi)
    .sort((a, b) => a.when - b.when);
  // sunucu `count` = bilet belgesi sayısı (koltuk değil); önizleme ile red ekranı tutarlı olsun
  return { sayi: l.length, tarih: l[0]?.when || null, baslik: l[0]?.ad || '' };
}

// ---------- Modal ----------
let acik = false;
/** "Hesabımı sil" akışı. Bitince (kapanınca) hesap silinmeye alındıysa true döner. */
export function silmeModaliAc() {
  const u = mevcut();
  if (!u || acik) return Promise.resolve(false);
  acik = true;
  const onceki = document.activeElement;
  const st = { adim: 'yukle', sayi: 0, tarih: null, baslik: '', son: null, hata: '', bekliyor: false, tamam: false };
  const bg = document.createElement('div');
  bg.className = 'auth-bg';
  bg.innerHTML = '<div class="auth-modal sil-modal" role="alertdialog" aria-modal="true" aria-labelledby="sil-b" aria-describedby="sil-m" tabindex="-1"></div>';
  document.body.append(bg);
  document.body.classList.add('modal-acik');
  const kutu = $('.sil-modal', bg);
  let coz; const sonuc = new Promise((r) => { coz = r; });

  const kapat = () => {
    if (st.bekliyor) return;
    document.removeEventListener('keydown', tus, true);
    document.body.classList.remove('modal-acik');
    bg.classList.add('kapaniyor');
    setTimeout(() => bg.remove(), 160);
    acik = false;
    if (st.tamam) { location.href = '/vitrin'; } else { try { onceki?.focus?.(); } catch {} }
    coz(st.tamam);
  };
  const tus = (e) => {
    if (e.key === 'Escape') { e.preventDefault(); kapat(); return; }
    if (e.key !== 'Tab') return;
    const f = [...kutu.querySelectorAll('button:not([disabled]), input, a[href]')].filter((x) => x.offsetParent !== null);
    if (!f.length) { e.preventDefault(); kutu.focus(); return; }
    const ilk = f[0], son = f[f.length - 1];
    if (e.shiftKey && (document.activeElement === ilk || document.activeElement === kutu)) { e.preventDefault(); son.focus(); }
    else if (!e.shiftKey && document.activeElement === son) { e.preventDefault(); ilk.focus(); }
  };
  document.addEventListener('keydown', tus, true);
  bg.addEventListener('mousedown', (e) => { if (e.target === bg) kapat(); });

  const bitisTarihi = () => new Date(Date.now() + BEKLEME_GUN * 864e5);
  const ciz = () => {
    let baslik, govde, alt;
    if (st.adim === 'yukle') {
      baslik = 'Hesabını sil'; govde = '<p id="sil-m" class="muted">Hesabının durumu kontrol ediliyor…</p><div class="skel" style="height:44px"></div>'; alt = '';
    } else if (st.adim === 'red') {
      const nesne = st.baslik ? `<b>${esc(st.baslik)}</b>${st.tarih ? ` · ${esc(tarihSaatTR(st.tarih))}` : ''}` : (st.tarih ? esc(tarihSaatTR(st.tarih)) : '');
      baslik = 'Şimdilik silinemiyor';
      govde = `<p id="sil-m"><b>Gelecek etkinlik biletiniz var.</b> ${st.sayi ? `Gelecek tarihli ${st.sayi} biletin` : 'Gelecek tarihli biletin'} bulunduğu sürece hesabın silinemez.</p>
        ${nesne ? `<p class="sil-not">En yakın etkinlik: ${nesne}</p>` : ''}
        <p class="muted">Hesabını silebilmek için etkinlikten sonra tekrar dene ya da biletlerini iptal et. Online ödenmiş biletler uygulamadan iptal edilemez; iptal için bizimle iletişime geç.</p>`;
      alt = '<a class="btn btn-primary" href="/biletlerim">Biletlerim\'e git</a><button type="button" class="btn btn-ghost" data-kapat>Kapat</button>';
    } else if (st.adim === 'onay') {
      baslik = 'Hesabını silmek istiyor musun?';
      govde = `<p id="sil-m">Hesabınız 30 gün sonra, <b>${esc(tarihTR(bitisTarihi()))}</b> tarihinde kalıcı olarak silinecek. Bu süre içinde giriş yapıp vazgeçebilirsiniz.</p>
        <ul class="sil-liste"><li>Bekleme süresinde yeni bilet alamazsın.</li><li>Süre dolunca profilin, favorilerin ve yorumların kalıcı olarak silinir; bilet kayıtları yasal saklama gereği kişisel bilgiler olmadan tutulur.</li><li>Şimdi oturumun kapanır.</li></ul>
        <label class="sil-onay"><span>Onaylamak için <b>SİL</b> yaz</span><input id="sil-inp" name="onay" type="text" autocomplete="off" autocapitalize="characters" spellcheck="false" aria-describedby="sil-h" ${st.bekliyor ? 'disabled' : ''}></label>
        <div class="auth-mesaj" id="sil-h" role="alert" aria-live="assertive">${esc(st.hata)}</div>`;
      alt = `<button type="button" class="btn btn-ghost" data-kapat ${st.bekliyor ? 'disabled' : ''}>Vazgeç</button><button type="button" class="btn btn-tehlike" id="sil-onay" disabled>${st.bekliyor ? 'Bekle…' : 'Hesabımı sil'}</button>`;
    } else {
      baslik = 'Hesabın silinmeye alındı';
      govde = `<p id="sil-m">Hesabınız <b>${esc(tarihTR(st.son))}</b> tarihinde silinecek.</p><p class="muted">Bu tarihe kadar tekrar giriş yapıp silmeyi iptal edebilirsin. Güvenlik için oturumun kapatıldı.</p>`;
      alt = '<button type="button" class="btn btn-primary" data-kapat>Ana sayfaya dön</button>';
    }
    kutu.innerHTML = `${st.adim === 'son' ? '' : '<button type="button" class="auth-x" aria-label="Kapat" data-kapat>×</button>'}
      <div class="auth-baslik"><span class="auth-kicker">Hesap</span><h2 id="sil-b">${baslik}</h2></div>
      <div class="sil-govde" aria-live="polite">${govde}</div>
      ${alt ? `<div class="sil-btnlar">${alt}</div>` : ''}`;
  };
  const odak = (sel) => (kutu.querySelector(sel) || kutu.querySelector('button, a'))?.focus();
  const onayGecerli = () => { const v = String($('#sil-inp', kutu)?.value || '').trim().toLocaleUpperCase('tr').replace(/İ/g, 'I'); return v === 'SIL'; };

  const gonder = async () => {
    if (st.bekliyor || !onayGecerli()) return;
    st.bekliyor = true; st.hata = ''; ciz(); odak('#sil-inp');
    try {
      const r = await silmeIste();
      st.son = r.tarih;
      await bitir();
    } catch (h) {
      st.bekliyor = false;
      if (h.tur === 'bilet') { st.adim = 'red'; st.sayi = h.sayi || st.sayi; st.tarih = h.tarih || st.tarih; st.baslik = h.baslik || st.baslik; }
      else if (h.tur === 'zatenBekliyor') { st.son = h.tarih || bitisTarihi(); await bitir(); return; }
      else st.hata = h.mesaj || 'İşlem tamamlanamadı. Biraz sonra tekrar dene.';
      ciz(); odak(st.adim === 'red' ? 'a' : '#sil-inp');
    }
  };
  const bitir = async () => {
    st.bekliyor = false; st.tamam = true; st.adim = 'son';
    durumYaz({ bekliyor: true, tarih: st.son });
    try { await cikis(); } catch {}
    ciz(); odak('button');
  };

  kutu.addEventListener('click', (e) => {
    if (e.target.closest('[data-kapat]')) return kapat();
    if (e.target.closest('#sil-onay')) gonder();
  });
  kutu.addEventListener('input', (e) => {
    if (e.target.id !== 'sil-inp') return;
    const b = $('#sil-onay', kutu); if (b) b.disabled = !onayGecerli();
  });
  kutu.addEventListener('keydown', (e) => { if (e.key === 'Enter' && e.target.id === 'sil-inp') { e.preventDefault(); gonder(); } });

  ciz(); requestAnimationFrame(() => { if (!kutu.contains(document.activeElement)) kutu.focus(); });
  (async () => {
    try {
      const g = await gelecekBiletler(u.uid);
      if (g.sayi) { Object.assign(st, g, { adim: 'red' }); } else st.adim = 'onay';
    } catch { st.adim = 'onay'; } // okunamazsa sunucu yine denetler
    if (!acik) return;
    ciz(); odak(st.adim === 'onay' ? '#sil-inp' : 'a');
  })();
  return sonuc;
}

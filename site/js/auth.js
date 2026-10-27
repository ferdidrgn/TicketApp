// Oturum: Firebase Auth (Google + telefon/SMS — mobil uygulamayla aynı yöntemler), giriş/kayıt modalı, ilk girişte User/{uid} oluşturma,
// başlıktaki hesap menüsü. Giriş yalnızca satın alma / koltuk / Biletlerim adımında istenir; site genelinde zorunlu değil.
// Güvenlik: şifre hiçbir yerde saklanmaz/loglanmaz; hata mesajları Türkçe ve teknik ayrıntı sızdırmaz.
import {
  auth, db, onAuthStateChanged, signInWithEmailAndPassword, createUserWithEmailAndPassword, signInWithPopup,
  GoogleAuthProvider, signOut, sendPasswordResetEmail, updateProfile, doc, getDoc, setDoc,
} from './firebase.js';
import { $, esc } from './util.js';

let kullanici = null;
let hazir = false;
const bekleyen = [];
const dinleyiciler = new Set();

onAuthStateChanged(auth, (u) => {
  kullanici = u;
  if (!hazir) { hazir = true; bekleyen.splice(0).forEach((f) => f(u)); }
  dinleyiciler.forEach((f) => { try { f(u); } catch (e) { console.error(e); } });
  document.dispatchEvent(new CustomEvent('oturum-degisti', { detail: u }));
});

export const mevcut = () => kullanici;
/** İlk oturum durumu çözülene kadar bekler; sonra kullanıcıyı (ya da null) döner. */
export const oturumBekle = () => (hazir ? Promise.resolve(kullanici) : new Promise((r) => bekleyen.push(r)));
export const oturumDinle = (f) => { dinleyiciler.add(f); if (hazir) f(kullanici); return () => dinleyiciler.delete(f); };

export function hataMetni(e) {
  const k = String(e?.code || '');
  const t = {
    'auth/invalid-email': 'E-posta adresi geçersiz görünüyor.',
    'auth/missing-email': 'E-posta adresini yaz.',
    'auth/user-not-found': 'E-posta veya şifre hatalı.',
    'auth/wrong-password': 'E-posta veya şifre hatalı.',
    'auth/invalid-credential': 'E-posta veya şifre hatalı.',
    'auth/invalid-login-credentials': 'E-posta veya şifre hatalı.',
    'auth/email-already-in-use': 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.',
    'auth/weak-password': 'Şifre en az 6 karakter olmalı.',
    'auth/too-many-requests': 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
    'auth/network-request-failed': 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
    'auth/popup-closed-by-user': 'Google penceresi kapatıldı.',
    'auth/cancelled-popup-request': 'Google penceresi kapatıldı.',
    'auth/popup-blocked': 'Tarayıcı Google penceresini engelledi. Açılır pencerelere izin ver.',
    'auth/unauthorized-domain': 'Bu adres Firebase Authentication yetkili alanlarına eklenmemiş. Yönetici: Authentication > Ayarlar > Yetkili alanlar.',
    'auth/invalid-phone-number': 'Telefon numarası geçersiz. Örnek: 5xx xxx xx xx',
    'auth/missing-phone-number': 'Telefon numaranı yaz.',
    'auth/invalid-verification-code': 'Kod hatalı. Tekrar dene.',
    'auth/code-expired': 'Kodun süresi doldu. Yeni kod iste.',
    'auth/quota-exceeded': 'SMS kotası doldu. Biraz sonra tekrar dene veya Google ile gir.',
    'auth/captcha-check-failed': 'Güvenlik doğrulaması başarısız. Sayfayı yenileyip tekrar dene.',
    'auth/user-disabled': 'Bu hesap devre dışı bırakılmış.',
    'auth/operation-not-allowed': 'Bu giriş yöntemi şu an kapalı.',
  }[k];
  return t || 'İşlem tamamlanamadı. Biraz sonra tekrar dene.';
}

// Web'de ilk girişte User/{uid} yoksa oluşturur (rules: yalnızca kendi uid'siyle create). role daima 'user'.
async function kullaniciBelgesi(u, ad = '') {
  try {
    const r = doc(db, 'User', u.uid);
    const s = await getDoc(r);
    if (s.exists()) return;
    const parca = String(ad || u.displayName || '').trim().split(/\s+/).filter(Boolean);
    const simdi = new Date().toISOString();
    await setDoc(r, {
      _id: u.uid, _createdAt: simdi, _updatedAt: simdi,
      firstName: parca[0] || '', lastName: parca.slice(1).join(' '),
      imageUrl: u.photoURL || '', phoneNumber: u.phoneNumber || '', eMail: u.email || '', city: '',
      isPhoneActive: false, fcmToken: '', role: 'user',
      favoriteShows: [], favoriteStages: [], favoritePlayers: [], ticketsId: [],
    });
  } catch (e) { console.warn('User belgesi oluşturulamadı', e?.code || ''); }
}

export const cikis = () => signOut(auth);

// ---------- Modal ----------
let acik = null;
const IKON_G = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path fill="#4285F4" d="M22 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.6a4.8 4.8 0 0 1-2.1 3.1v2.6h3.4c2-1.8 3.1-4.5 3.1-7.5Z"/><path fill="#34A853" d="M12 22c2.8 0 5.2-.9 6.9-2.5l-3.4-2.6c-.9.6-2.1 1-3.5 1-2.7 0-5-1.8-5.8-4.3H2.7v2.7A10 10 0 0 0 12 22Z"/><path fill="#FBBC05" d="M6.2 13.6a6 6 0 0 1 0-3.8V7.1H2.7a10 10 0 0 0 0 9.2l3.5-2.7Z"/><path fill="#EA4335" d="M12 6c1.5 0 2.9.5 4 1.6l3-3A10 10 0 0 0 2.7 7.1l3.5 2.7C7 7.800 9.300 6 12 6Z"/></svg>';

/** Türkiye numarasını E.164'e çevirir: "0532 123 45 67" / "532…" / "+90…" -> "+905321234567"; geçersizse ''. */
export function telefonE164(v) {
  let d = String(v || '').replace(/[^\d+]/g, '');
  if (d.startsWith('+')) return /^\+\d{10,14}$/.test(d) ? d : '';
  d = d.replace(/^00/, '');
  if (d.startsWith('90') && d.length === 12) d = d.slice(2);
  if (d.startsWith('0')) d = d.slice(1);
  return /^5\d{9}$/.test(d) ? `+90${d}` : '';
}

/**
 * Oturum yoksa giriş modalını açar (Google veya telefon + SMS kodu — mobil uygulamayla aynı yöntemler).
 * Giriş olursa kullanıcıyı, vazgeçilirse null döner.
 * neden: modalda gösterilen kısa açıklama (ör. "Koltuk seçmek için giriş yap").
 */
export async function girisGerekli(neden = 'Devam etmek için giriş yap.') {
  await oturumBekle();
  if (kullanici) return kullanici;
  if (acik) return acik.promise;
  let coz;
  const promise = new Promise((r) => { coz = r; });
  const onceki = document.activeElement;
  const st = { mod: 'giris', mesaj: '', yukleniyor: false, tel: '', ad: '' };
  let onay = null, recaptcha = null;
  const bg = document.createElement('div');
  bg.className = 'auth-bg';
  bg.innerHTML = '<div class="auth-modal" role="dialog" aria-modal="true" aria-labelledby="auth-b" tabindex="-1"></div>';
  document.body.append(bg);
  document.body.classList.add('modal-acik');
  const kutu = $('.auth-modal', bg);

  const bitir = (u) => {
    bg.classList.add('kapaniyor');
    document.removeEventListener('keydown', tus, true);
    document.body.classList.remove('modal-acik');
    try { recaptcha?.clear(); } catch {}
    setTimeout(() => bg.remove(), 160);
    acik = null;
    try { onceki?.focus?.(); } catch {}
    coz(u || null);
  };
  const tus = (e) => {
    if (e.key === 'Escape') { e.preventDefault(); bitir(null); return; }
    if (e.key !== 'Tab') return;
    const f = [...kutu.querySelectorAll('button:not([disabled]), input, a[href]')].filter((x) => x.offsetParent !== null);
    if (!f.length) return;
    const ilk = f[0], son = f[f.length - 1];
    if (e.shiftKey && document.activeElement === ilk) { e.preventDefault(); son.focus(); }
    else if (!e.shiftKey && document.activeElement === son) { e.preventDefault(); ilk.focus(); }
  };
  document.addEventListener('keydown', tus, true);
  bg.addEventListener('mousedown', (e) => { if (e.target === bg) bitir(null); });

  const ciz = () => {
    const kod = st.mod === 'kod';
    kutu.innerHTML = `
      <button type="button" class="auth-x" aria-label="Kapat" data-x>×</button>
      <div class="auth-baslik"><span class="auth-kicker">TiyatRol</span>
        <h2 id="auth-b">${kod ? 'Doğrulama kodu' : 'Giriş yap'}</h2>
        <p class="muted">${kod ? esc(`${st.tel} numarasına 6 haneli bir kod gönderdik.`) : esc(neden)}</p></div>
      ${kod ? '' : `<button type="button" class="btn btn-ghost auth-google" data-g ${st.yukleniyor ? 'disabled' : ''}>${IKON_G}<span>Google ile devam et</span></button>
        <div class="auth-ayrac"><span>ya da telefon numarası ile</span></div>`}
      <form novalidate data-f>
        ${kod
          ? '<label>SMS kodu<input name="kod" type="text" inputmode="numeric" autocomplete="one-time-code" maxlength="6" pattern="[0-9]*" required></label>'
          : `<label>Telefon<input name="tel" type="tel" inputmode="tel" autocomplete="tel" placeholder="5xx xxx xx xx" maxlength="20" value="${esc(st.tel)}" required></label>
             <label>Ad soyad <small class="muted">(ilk kez giriyorsan)</small><input name="ad" type="text" autocomplete="name" maxlength="80" value="${esc(st.ad)}"></label>`}
        <div class="auth-mesaj ${st.mesajTur || ''}" role="status" aria-live="polite">${esc(st.mesaj)}</div>
        <div id="auth-recaptcha"></div>
        <button class="btn btn-primary auth-gonder" type="submit" ${st.yukleniyor ? 'disabled' : ''}>${st.yukleniyor ? 'Bekle…' : kod ? 'Doğrula ve gir' : 'SMS kodu gönder'}</button>
      </form>
      ${kod ? '<div class="auth-alt"><button type="button" class="link-btn" data-mod="giris">Numarayı değiştir</button></div>'
            : '<p class="tiny auth-not">Devam ederek <a href="/sartlar" target="_blank" rel="noopener">kullanım şartlarını</a> ve <a href="/gizlilik" target="_blank" rel="noopener">gizlilik politikasını</a> kabul etmiş olursun.</p>'}`;
  };
  const odak = () => (kutu.querySelector('input') || kutu.querySelector('button'))?.focus();
  ciz(); requestAnimationFrame(odak);

  const mesaj = (m, tur = 'hata') => { st.mesaj = m; st.mesajTur = tur; };
  const basari = async (u, ad) => { await kullaniciBelgesi(u, ad); bitir(u); };

  kutu.addEventListener('click', async (e) => {
    if (e.target.closest('[data-x]')) return bitir(null);
    const m = e.target.closest('[data-mod]');
    if (m) { st.mod = m.dataset.mod; st.mesaj = ''; onay = null; ciz(); return odak(); }
    if (e.target.closest('[data-g]')) {
      st.yukleniyor = true; mesaj(''); ciz();
      try {
        const r = await signInWithPopup(auth, new GoogleAuthProvider());
        return await basari(r.user);
      } catch (err) { st.yukleniyor = false; mesaj(hataMetni(err)); ciz(); }
    }
  });
  kutu.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (st.yukleniyor) return;
    const f = new FormData(e.target);
    if (st.mod === 'kod') {
      const kod = String(f.get('kod') || '').replace(/\D/g, '');
      if (kod.length !== 6) { mesaj('6 haneli kodu yaz.'); ciz(); return kutu.querySelector('[name=kod]')?.focus(); }
      st.yukleniyor = true; mesaj(''); ciz();
      try {
        const r = await onay.confirm(kod);
        return await basari(r.user, st.ad);
      } catch (err) { st.yukleniyor = false; mesaj(hataMetni(err)); ciz(); kutu.querySelector('[name=kod]')?.focus(); }
      return;
    }
    const tel = telefonE164(f.get('tel'));
    st.ad = String(f.get('ad') || '').trim();
    if (!tel) { st.tel = String(f.get('tel') || ''); mesaj('Geçerli bir telefon numarası yaz. Örnek: 5xx xxx xx xx'); ciz(); return kutu.querySelector('[name=tel]')?.focus(); }
    st.tel = tel; st.yukleniyor = true; mesaj(''); ciz();
    try {
      try { recaptcha?.clear(); } catch {}
      recaptcha = new RecaptchaVerifier(auth, 'auth-recaptcha', { size: 'invisible' });
      onay = await signInWithPhoneNumber(auth, tel, recaptcha);
      st.mod = 'kod'; st.yukleniyor = false; mesaj(''); ciz(); odak();
    } catch (err) {
      try { recaptcha?.clear(); } catch {}
      recaptcha = null; st.yukleniyor = false; mesaj(hataMetni(err)); ciz(); kutu.querySelector('[name=tel]')?.focus();
    }
  });
  acik = { promise };
  return promise;
}

// ---------- Başlık: hesap düğmesi ve menüsü ----------
const IKON_K = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4.5-6 8-6s7 2 8 6"/></svg>';
export function hesapDugmesi(kap) {
  if (!kap) return;
  kap.classList.add('hesap-kap');
  kap.innerHTML = `<button type="button" class="icon-btn hesap-btn" id="hesap-btn" aria-haspopup="menu" aria-expanded="false" aria-label="Hesap">${IKON_K}</button><div class="hesap-menu" id="hesap-menu" role="menu" hidden></div>`;
  const btn = $('#hesap-btn', kap), menu = $('#hesap-menu', kap);
  const kapat = () => { menu.hidden = true; btn.setAttribute('aria-expanded', 'false'); };
  const guncelle = (u) => {
    btn.classList.toggle('girisli', !!u);
    const bas = u ? String(u.displayName || u.email || u.phoneNumber || '?').trim()[0]?.toUpperCase() : '';
    btn.innerHTML = u ? `<span class="hesap-bas" aria-hidden="true">${esc(bas)}</span>` : IKON_K;
    btn.setAttribute('aria-label', u ? `Hesabım: ${u.displayName || u.email}` : 'Giriş yap');
    menu.innerHTML = u
      ? `<div class="hesap-ust"><b>${esc(u.displayName || 'Hesabım')}</b><small>${esc(u.email || u.phoneNumber || '')}</small></div>
         <a role="menuitem" href="/biletlerim">Biletlerim</a><a role="menuitem" href="/favoriler">Favorilerim</a>
         <button type="button" role="menuitem" data-cikis>Çıkış yap</button>`
      : '';
  };
  oturumDinle(guncelle);
  btn.addEventListener('click', async () => {
    if (!kullanici) { await girisGerekli('Biletlerini görmek ve bilet almak için giriş yap.'); return; }
    menu.hidden = !menu.hidden; btn.setAttribute('aria-expanded', String(!menu.hidden));
    if (!menu.hidden) menu.querySelector('a')?.focus();
  });
  menu.addEventListener('click', async (e) => { if (e.target.closest('[data-cikis]')) { kapat(); await cikis(); if (/^\/(biletlerim|koltuk|odeme-sonuc)/.test(location.pathname)) location.href = '/app'; } });
  document.addEventListener('click', (e) => { if (!kap.contains(e.target)) kapat(); });
  kap.addEventListener('keydown', (e) => { if (e.key === 'Escape') { kapat(); btn.focus(); } });
}

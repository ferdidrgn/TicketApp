// Firebase (web SDK, CDN modülleri). Proje: ticketappflutter. Bu anahtarlar
// tarayıcıya zaten açıktır (Flutter web'de de aynı); güvenlik Firestore
// kurallarıyla sağlanır — bkz. firestore.rules.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getFirestore, collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc,
  serverTimestamp, query, where, limit, orderBy, arrayUnion, arrayRemove, getCountFromServer,
  onSnapshot, connectFirestoreEmulator,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup,
  GoogleAuthProvider, signOut, sendPasswordResetEmail,
  createUserWithEmailAndPassword, updateProfile, connectAuthEmulator,
  RecaptchaVerifier, signInWithPhoneNumber, linkWithPhoneNumber, PhoneAuthProvider,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import {
  getStorage, ref as sRef, uploadBytes, getDownloadURL,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-storage.js';

const app = initializeApp({
  apiKey: 'AIzaSyDTszWHMEMHY1Ed2ZftOcNUlvXl03S7g-k',
  appId: '1:823869540671:web:e642e9658a82b982feeb8a',
  messagingSenderId: '823869540671',
  projectId: 'ticketappflutter',
  authDomain: 'ticketappflutter.firebaseapp.com',
  storageBucket: 'ticketappflutter.appspot.com',
});

// App Check (reCAPTCHA v3). Site key'i SAHİBİ üretir (Firebase Console > App Check > Web > reCAPTCHA v3; docs/GUVENLIK-DENETIMI.md).
// BOŞKEN hiçbir şey yapılmaz ve hata vermez (şimdiki davranış). Anahtar herkese açık bir değerdir (secret DEĞİL).
// Geliştirme: localhost'ta konsolda çıkan debug token'ı Console > App Check > Apps > Manage debug tokens'a ekleyin.
const APPCHECK_SITE_KEY = '';
if (APPCHECK_SITE_KEY) {
  try {
    if (['localhost', '127.0.0.1'].includes(location.hostname)) self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;
    const ac = await import('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-check.js');
    ac.initializeAppCheck(app, { provider: new ac.ReCaptchaV3Provider(APPCHECK_SITE_KEY), isTokenAutoRefreshEnabled: true });
  } catch (e) { console.warn('[TiyatRol] App Check başlatılamadı (devam ediliyor):', e && e.code); }
}

export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);

// Emülatör: YALNIZCA localhost/127.0.0.1 üzerinde ve localStorage['tiyatrol.emu']==='1' iken.
// Varsayılan kapalı — üretim verisine yanlışlıkla yazmayı önler.
export const EMU = (() => {
  try {
    return ['localhost', '127.0.0.1'].includes(location.hostname) && localStorage.getItem('tiyatrol.emu') === '1';
  } catch { return false; }
})();
if (EMU) {
  const EP = (k, v) => { try { return Number(localStorage.getItem('tiyatrol.emu.' + k)) || v; } catch { return v; } }; // yalnız test: alternatif port
  connectAuthEmulator(auth, `http://127.0.0.1:${EP('auth', 9099)}`, { disableWarnings: true });
  auth.settings.appVerificationDisabledForTesting = true; // yalnız emülatör: reCAPTCHA yerine sahte doğrulayıcı (gerçek SMS yok)
  connectFirestoreEmulator(db, '127.0.0.1', EP('fs', 8080));
  console.warn('[TiyatRol] Emülatör modu AÇIK (auth 9099, firestore 8080, functions 5001).');
}
// Cloud Functions (europe-west1) yalnızca gerektiğinde yüklenir.
let fnModul = null;
export async function fonksiyon(ad) {
  if (!fnModul) {
    const m = await import('https://www.gstatic.com/firebasejs/10.14.1/firebase-functions.js');
    const f = m.getFunctions(app, 'europe-west1');
    if (EMU) m.connectFunctionsEmulator(f, '127.0.0.1', Number(localStorage.getItem('tiyatrol.emu.fn')) || 5001);
    fnModul = { m, f };
  }
  return fnModul.m.httpsCallable(fnModul.f, ad);
}
export {
  collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc, serverTimestamp, query, where, limit, orderBy, arrayUnion, arrayRemove, getCountFromServer,
  onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut,
  sendPasswordResetEmail, createUserWithEmailAndPassword, updateProfile, RecaptchaVerifier, signInWithPhoneNumber, linkWithPhoneNumber, PhoneAuthProvider, onSnapshot, sRef, uploadBytes, getDownloadURL,
};

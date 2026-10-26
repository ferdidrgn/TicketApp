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
  RecaptchaVerifier, signInWithPhoneNumber,
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
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  console.warn('[TiyatRol] Emülatör modu AÇIK (auth 9099, firestore 8080, functions 5001).');
}
// Cloud Functions (europe-west1) yalnızca gerektiğinde yüklenir.
let fnModul = null;
export async function fonksiyon(ad) {
  if (!fnModul) {
    const m = await import('https://www.gstatic.com/firebasejs/10.14.1/firebase-functions.js');
    const f = m.getFunctions(app, 'europe-west1');
    if (EMU) m.connectFunctionsEmulator(f, '127.0.0.1', 5001);
    fnModul = { m, f };
  }
  return fnModul.m.httpsCallable(fnModul.f, ad);
}
export {
  collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc, serverTimestamp, query, where, limit, orderBy, arrayUnion, arrayRemove, getCountFromServer,
  onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut,
  sendPasswordResetEmail, createUserWithEmailAndPassword, updateProfile, RecaptchaVerifier, signInWithPhoneNumber, onSnapshot, sRef, uploadBytes, getDownloadURL,
};

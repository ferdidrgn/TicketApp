// Firebase (web SDK, CDN modülleri). Proje: ticketappflutter. Bu anahtarlar
// tarayıcıya zaten açıktır (Flutter web'de de aynı); güvenlik Firestore
// kurallarıyla sağlanır — bkz. firestore.rules.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getFirestore, collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc,
  serverTimestamp, query, where, limit, arrayUnion, arrayRemove, getCountFromServer,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup,
  GoogleAuthProvider, signOut, sendPasswordResetEmail,
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
export {
  collection, getDocs, getDoc, doc, setDoc, updateDoc, deleteDoc, serverTimestamp, query, where, limit, arrayUnion, arrayRemove, getCountFromServer,
  onAuthStateChanged, signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, signOut,
  sendPasswordResetEmail, sRef, uploadBytes, getDownloadURL,
};

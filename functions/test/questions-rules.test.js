'use strict';
// Question kuralları (Q-2): istemci yazamaz; herkes yalnız YAYINLANMIŞ (answered + hidden==false) soruları sorgulayabilir; admin hepsini okur.
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } = require('firebase/firestore');

let env;
const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'question-rules-test', firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8') } });
});
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'User/admin1'), { role: 'admin' });
    await setDoc(doc(d, 'User/alice'), { role: 'user' });
    await setDoc(doc(d, 'Question/pub'), { showId: 's1', text: 'Kaç dk?', askerName: 'Ayşe K.', status: 'answered', hidden: false, answer: '90 dk' });
    await setDoc(doc(d, 'Question/pend'), { showId: 's1', text: 'Bekleyen', askerName: 'Ali V.', status: 'pending', hidden: true });
    await setDoc(doc(d, 'Question/hid'), { showId: 's1', text: 'Gizli', askerName: 'Veli', status: 'hidden', hidden: true, answer: 'x' });
    await setDoc(doc(d, 'QuestionOwner/pend'), { uid: 'alice', showId: 's1' });
    await setDoc(doc(d, 'QuestionReport/r1'), { questionId: 'pub', userId: 'alice' });
    await setDoc(doc(d, 'QuestionLimits/alice'), { askHourCount: 1 });
  });
});
const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

test('okuma: yayınlanmış soru herkese açık; bekleyen/gizli yalnız admin; sahibi bile belgeden okuyamaz (callable kullanır)', async () => {
  for (const db of [anon(), as('alice')]) {
    await assertSucceeds(getDoc(doc(db, 'Question/pub')));
    await assertFails(getDoc(doc(db, 'Question/pend')));
    await assertFails(getDoc(doc(db, 'Question/hid')));
  }
  await assertSucceeds(getDoc(doc(as('admin1'), 'Question/pend')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'Question/hid')));
});

test('sorgu: status==answered && hidden==false kısıtlı sorgu çalışır; kısıtsız reddedilir; admin kısıtsız çalışır', async () => {
  const q = query(collection(anon(), 'Question'), where('showId', '==', 's1'), where('status', '==', 'answered'), where('hidden', '==', false));
  const s = await assertSucceeds(getDocs(q));
  assert.equal(s.size, 1);
  await assertFails(getDocs(query(collection(anon(), 'Question'), where('showId', '==', 's1'))));
  await assertFails(getDocs(query(collection(anon(), 'Question'), where('showId', '==', 's1'), where('hidden', '==', false))));
  await assertSucceeds(getDocs(query(collection(as('admin1'), 'Question'), where('status', '==', 'pending'))));
});

test('yazma: kimse (admin dahil) Question/QuestionOwner/QuestionReport/QuestionLimits yazamaz-silemez; yan koleksiyonlar okunamaz', async () => {
  for (const db of [anon(), as('alice'), as('admin1')]) {
    await assertFails(setDoc(doc(db, 'Question/yeni'), { showId: 's1', text: 'x', status: 'answered', hidden: false }));
    await assertFails(updateDoc(doc(db, 'Question/pend'), { status: 'answered', hidden: false, answer: 'kendi cevabım' }));
    await assertFails(deleteDoc(doc(db, 'Question/pub')));
    await assertFails(setDoc(doc(db, 'QuestionOwner/x'), { uid: 'alice' }));
    await assertFails(setDoc(doc(db, 'QuestionReport/x'), { userId: 'alice' }));
    await assertFails(setDoc(doc(db, 'QuestionLimits/alice'), { askHourCount: 0 }));
  }
  for (const db of [anon(), as('alice'), as('admin1')]) { await assertFails(getDoc(doc(db, 'QuestionOwner/pend'))); await assertFails(getDoc(doc(db, 'QuestionLimits/alice'))); }
  await assertFails(getDoc(doc(as('alice'), 'QuestionReport/r1')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'QuestionReport/r1')));
});

// Pasaport çekirdeği testi: node site/tools/pasaport-test.mjs
// Vektörler docs/PASAPORT.md ve test/passport/passport_test.dart ile BİREBİR aynıdır.
import assert from 'node:assert/strict';
import { izlendiMi, pasaportHesapla, paylasimMetni } from '../js/pasaport-cekirdek.js';

const simdi = new Date(2026, 9, 28, 12, 0);
const t = (tarih, o = {}) => ({ id: 't', eventId: '', showId: '', stageId: '', showName: 'Oyun', stageName: '', tarih, usedAt: '', odeme: '', iptal: false, ...o });
let say = 0;
const dene = (ad, f) => { f(); say++; console.log('ok', ad); };

const V = [
  ['V1 geçmiş seans', t('15.10.2026,20:00', { odeme: 'paid' }), true],
  ['V2 gelecek seans', t('15.11.2026,20:00', { odeme: 'pay_at_venue' }), false],
  ['V3 gelecek ama usedAt dolu', t('15.11.2026,20:00', { usedAt: '2026-10-28T10:00:00Z' }), true],
  ['V4 geçmiş + cancelled', t('15.10.2026,20:00', { odeme: 'cancelled' }), false],
  ['V5 geçmiş + no_show', t('15.10.2026,20:00', { odeme: 'no_show' }), false],
  ['V6 geçmiş + iptal işareti', t('15.10.2026,20:00', { iptal: true }), false],
  ['V7 usedAt dolu + no_show', t('15.10.2026,20:00', { usedAt: '2026-10-15T20:00:00Z', odeme: 'no_show' }), false],
  ['V8 ayrıştırılamayan tarih', t('yakında'), false],
  ['V9 boş tarih', t(''), false],
  ['V10 ISO geçmiş', t('2026-09-01T18:00:00Z'), true],
  ['V11 taşan tarih 31.02', t('31.02.2026,20:00'), false],
  ['V12 yalnız gün, dün', t('27.10.2026'), true],
  ['V13 yalnız gün, bugün (gün sonu)', t('28.10.2026'), false],
  ['V14 bir dakika önce', t('28.10.2026,11:59'), true],
  ['V15 tam şimdi', t('28.10.2026,12:00'), false],
];
for (const [ad, b, bek] of V) dene(ad, () => assert.equal(izlendiMi(b, simdi), bek));

dene('S1 karışık biletler', () => {
  const p = pasaportHesapla([
    t('10.01.2026,20:00', { id: 'a', eventId: 'e1', showId: 'A', stageId: 'X', stageName: 'Sahne X' }),
    t('10.01.2026,20:00', { id: 'b', eventId: 'e1', showId: 'A', stageId: 'X', stageName: 'Sahne X' }),
    t('10.03.2026,20:00', { id: 'c', eventId: 'e2', showId: 'A', stageId: 'X', stageName: 'Sahne X' }),
    t('05.05.2025,20:00', { id: 'd', eventId: 'e3', showId: 'B', stageId: 'Y', stageName: 'Sahne Y' }),
    t('15.12.2026,20:00', { id: 'e', eventId: 'e4', showId: 'C', stageId: 'X' }),
    t('01.02.2026,20:00', { id: 'f', eventId: 'e5', showId: 'D', stageId: 'Z', iptal: true }),
  ], simdi);
  assert.equal(p.izlenenler.length, 3);
  assert.equal(p.oyunSayisi, 2); assert.equal(p.sahneSayisi, 2); assert.equal(p.buYil, 1);
  assert.equal(p.damgalar[0].ad, 'Sahne X'); assert.equal(p.damgalar[0].sayi, 2);
  assert.equal(p.izlenenler[0].id, 'c');
  const b = Object.fromEntries(p.rozetler.map((x) => [x.id, x]));
  assert.equal(b['ilk-perde'].kazanildi, true);
  assert.equal(b['sahne-gezgini'].kazanildi, false); assert.equal(b['sahne-gezgini'].simdiki, 2);
  assert.equal(b['sadik-seyirci'].kazanildi, false); assert.equal(b['sadik-seyirci'].simdiki, 2);
  assert.equal(b['sezon-yildizi'].simdiki, 1); assert.equal(b['on-perde'].simdiki, 2);
  assert.equal(p.rozetler.filter((x) => x.kazanildi).length, 1);
});
dene('S2 boş durum', () => {
  const p = pasaportHesapla([], simdi);
  assert.equal(p.bos, true); assert.equal(p.oyunSayisi, 0);
  assert.ok(p.rozetler.every((x) => !x.kazanildi));
  assert.match(paylasimMetni(p), /ilk perdeyi bekliyorum/);
});
dene('S3 sadık seyirci', () => {
  const p = pasaportHesapla([1, 2, 3].map((i) => t(`0${i}.02.2026,20:00`, { id: `x${i}`, eventId: `e${i}`, showId: `S${i}`, stageId: 'X' })), simdi);
  const b = Object.fromEntries(p.rozetler.map((x) => [x.id, x]));
  assert.equal(b['sadik-seyirci'].kazanildi, true); assert.equal(b['ilk-perde'].kazanildi, true); assert.equal(p.sahneSayisi, 1);
});
dene('S4 beş sahne + beş oyun bu yıl -> 3 rozet', () => {
  const p = pasaportHesapla([1, 2, 3, 4, 5].map((i) => t(`0${i}.03.2026,20:00`, { id: `y${i}`, eventId: `e${i}`, showId: `S${i}`, stageId: `St${i}` })), simdi);
  const b = Object.fromEntries(p.rozetler.map((x) => [x.id, x]));
  assert.equal(b['sahne-gezgini'].kazanildi, true); assert.equal(b['sezon-yildizi'].kazanildi, true); assert.equal(b['on-perde'].kazanildi, false);
  assert.equal(p.rozetler.filter((x) => x.kazanildi).length, 3);
});
dene('S5 oyun adı yoksa sayılmaz; paylaşım metni kişisel veri içermez', () => {
  const p = pasaportHesapla([t('01.01.2026,20:00', { id: 'z', showName: '' }), t('01.02.2026,20:00', { id: 'w', eventId: 'ew', showId: 'W', stageId: 'X', showName: 'Hamlet' })], simdi);
  assert.equal(p.oyunSayisi, 1);
  assert.equal(paylasimMetni(p), 'TiyatRol Tiyatro Pasaportum: 1 oyun, 1 sahne, bu yıl 1 oyun, 1 rozet.');
});
console.log(`\n${say} test geçti`);

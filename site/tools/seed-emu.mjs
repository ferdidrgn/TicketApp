// SADECE TEST: Firestore emülatörüne SENTETİK veri yükler (üretim verisi kopyalanmaz).
//   node site/tools/seed-emu.mjs                 -> sahne, koltuk düzeni, 2 oyun, 3 seans (ücretli, ücretsiz, geçmiş)
//   node site/tools/seed-emu.mjs --uid <uid>     -> ayrıca o kullanıcı için 1 yaklaşan + 1 geçmiş sentetik bilet
import { yaz, sil, listele } from './emu-rest.mjs';

const gun = (n, saat = 20, dk = 30) => { const d = new Date(Date.now() + n * 864e5); const p = (x) => String(x).padStart(2, '0'); return `${p(d.getDate())}.${p(d.getMonth() + 1)}.${d.getFullYear()},${p(saat)}:${p(dk)}`; };
const sira = (harf, adet) => Array.from({ length: adet }, (_, i) => `${harf}${i + 1}`);

const duzen = { A: sira('A', 10), B: sira('B', 12), C: sira('C', 12), D: sira('D', 12), E: sira('E', 14), closedSeatsId: ['E1', 'E2', 'E13', 'E14'] };
const tumu = Object.entries(duzen).filter(([k]) => k !== 'closedSeatsId').flatMap(([, l]) => l);
const koltuklar = () => Object.fromEntries(tumu.map((id) => [id, duzen.closedSeatsId.includes(id) ? { status: 'blocked' } : { status: 'available' }]));

const temizle = async () => { for (const k of ['Show', 'Event', 'Stage', 'Seats', 'Ticket', 'Order']) for (const d of await listele(k)) await sil(`${k}/${d.id}`); };
await temizle();

await yaz('Stage/stage-test', { _id: 'stage-test', name: 'Test Sahnesi', address: 'Çankaya, Ankara', city: 'Ankara', lat: 39.92, long: 32.85, imageUrl: '' });
await yaz('Seats/stage-test', duzen);

const oyun = (id, ad, ev) => yaz(`Show/${id}`, { _id: id, name: ad, description: 'Sentetik test oyunu. Gerçek veri değildir.', category: 'Komedi', imageUrl: '', duration: '90 dk', eventsId: ev, featured: 'hayır', photosShowId: [], nowPlayersId: [], oldPlayersId: [] });
await oyun('showpaid', 'Sentetik Oyun (Ücretli)', ['ev-paid', 'ev-past']);
await oyun('showfree', 'Sentetik Oyun (Ücretsiz)', ['ev-free']);

const seans = (id, showId, tarih, fiyat, ozel = {}) => {
  const k = koltuklar();
  Object.assign(k, ozel);
  return yaz(`Event/${id}`, { _id: id, showId, stageId: 'stage-test', date: tarih, price: fiyat, seats: k });
};
await seans('ev-paid', 'showpaid', gun(9), '250', {
  // Herkese açık Event'te kullanıcı kimliği YOKTUR: yalnızca durum + opak orderId (+ tutma bitişi).
  A3: { status: 'sold', orderId: 'sentetik-siparis-1' }, A4: { status: 'sold', orderId: 'sentetik-siparis-1' },
  B5: { status: 'reserved', orderId: 'sentetik-siparis-2', holdExpiresAt: Date.now() + 3600e3 }, B6: { status: 'reserved', orderId: 'sentetik-siparis-2', holdExpiresAt: Date.now() + 3600e3 },
});
await seans('ev-free', 'showfree', gun(5), '0', { C5: { status: 'sold', orderId: 'sentetik-siparis-3' } });
await seans('ev-past', 'showpaid', gun(-20), '250');

const uidAt = process.argv.indexOf('--uid');
if (uidAt > 0) {
  const uid = process.argv[uidAt + 1];
  const bilet = (id, ev, tarih, koltuk, fiyat) => yaz(`Ticket/${id}`, {
    _id: id, customerId: uid, showId: 'showpaid', stageId: 'stage-test', eventId: ev, showName: 'Sentetik Oyun (Ücretli)', showImageUrl: '', stageName: 'Test Sahnesi',
    eventDate: tarih, buySeats: koltuk, orderPrice: fiyat, orderMethod: 'web', isPast: false,
  });
  await bilet('tk-yaklasan', 'ev-paid', gun(9), ['D5', 'D6'], '500');
  await bilet('tk-gecmis', 'ev-past', gun(-20), ['C3'], '250');
  // Rezervasyon modu durumları (SENTETİK): sahnede ödenecek / ödendi / gelmedi / iptal / ücretsiz / iptal süresi geçmiş
  const durumlu = (id, ev, tarih, koltuk, fiyat, ekstra) => yaz(`Ticket/${id}`, {
    _id: id, customerId: uid, showId: 'showpaid', stageId: 'stage-test', eventId: ev, showName: 'Sentetik Oyun (Ücretli)', showImageUrl: '', stageName: 'Test Sahnesi',
    eventDate: tarih, buySeats: koltuk, orderPrice: fiyat, isPast: false, ...ekstra,
  });
  const yakin = (() => { const d = new Date(Date.now() + 10 * 3600e3); return gun((d - Date.now()) / 864e5, d.getHours(), d.getMinutes()); })();
  await durumlu('tk-rez', 'ev-paid', gun(9), ['D8'], '250', { orderMethod: 'venue', paymentStatus: 'pay_at_venue' });
  await durumlu('tk-rez-yakin', 'ev-paid', yakin, ['D9'], '250', { orderMethod: 'venue', paymentStatus: 'pay_at_venue' });
  await durumlu('tk-odendi', 'ev-paid', gun(12), ['D10'], '250', { orderMethod: 'card', paymentStatus: 'paid' });
  await durumlu('tk-gelmedi', 'ev-past', gun(-20), ['C4'], '250', { orderMethod: 'venue', paymentStatus: 'no_show' });
  await durumlu('tk-iptal', 'ev-paid', gun(9), ['D11'], '250', { orderMethod: 'venue', paymentStatus: 'cancelled', cancelledAt: Date.now() });
  await durumlu('tk-ucretsiz', 'ev-free', gun(5), ['C6'], '0', { orderMethod: 'free' });
  console.log('Sentetik biletler yazıldı:', uid);
}
console.log('Emülatör tohumlandı (sahne, düzen, 2 oyun, 3 seans).');

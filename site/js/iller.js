// 81 il + yaklaşık merkez koordinatları. Sahnenin ilini bulmak için: önce Stage.city, sonra adresteki il/ilçe adı,
// son olarak koordinata en yakın il (120 km içinde).
export const ILLER = [
  ['Adana', 37.0, 35.32], ['Adıyaman', 37.76, 38.28], ['Afyonkarahisar', 38.75, 30.54], ['Ağrı', 39.72, 43.05], ['Aksaray', 38.37, 34.03],
  ['Amasya', 40.65, 35.83], ['Ankara', 39.93, 32.86], ['Antalya', 36.9, 30.7], ['Ardahan', 41.11, 42.7], ['Artvin', 41.18, 41.82],
  ['Aydın', 37.85, 27.84], ['Balıkesir', 39.65, 27.89], ['Bartın', 41.64, 32.34], ['Batman', 37.88, 41.13], ['Bayburt', 40.26, 40.23],
  ['Bilecik', 40.14, 29.98], ['Bingöl', 38.88, 40.5], ['Bitlis', 38.4, 42.11], ['Bolu', 40.73, 31.61], ['Burdur', 37.72, 30.29],
  ['Bursa', 40.19, 29.06], ['Çanakkale', 40.15, 26.41], ['Çankırı', 40.6, 33.62], ['Çorum', 40.55, 34.95], ['Denizli', 37.78, 29.09],
  ['Diyarbakır', 37.91, 40.24], ['Düzce', 40.84, 31.16], ['Edirne', 41.68, 26.56], ['Elazığ', 38.67, 39.22], ['Erzincan', 39.75, 39.5],
  ['Erzurum', 39.9, 41.27], ['Eskişehir', 39.77, 30.52], ['Gaziantep', 37.07, 37.38], ['Giresun', 40.91, 38.39], ['Gümüşhane', 40.46, 39.48],
  ['Hakkari', 37.57, 43.74], ['Hatay', 36.4, 36.35], ['Iğdır', 39.92, 44.04], ['Isparta', 37.76, 30.55], ['İstanbul', 41.01, 28.98],
  ['İzmir', 38.42, 27.14], ['Kahramanmaraş', 37.58, 36.94], ['Karabük', 41.2, 32.63], ['Karaman', 37.18, 33.22], ['Kars', 40.6, 43.1],
  ['Kastamonu', 41.38, 33.78], ['Kayseri', 38.73, 35.49], ['Kırıkkale', 39.85, 33.51], ['Kırklareli', 41.74, 27.22], ['Kırşehir', 39.15, 34.16],
  ['Kilis', 36.72, 37.12], ['Kocaeli', 40.77, 29.94], ['Konya', 37.87, 32.48], ['Kütahya', 39.42, 29.98], ['Malatya', 38.35, 38.31],
  ['Manisa', 38.61, 27.43], ['Mardin', 37.31, 40.74], ['Mersin', 36.8, 34.64], ['Muğla', 37.22, 28.36], ['Muş', 38.74, 41.51],
  ['Nevşehir', 38.62, 34.71], ['Niğde', 37.97, 34.68], ['Ordu', 40.98, 37.88], ['Osmaniye', 37.07, 36.25], ['Rize', 41.02, 40.52],
  ['Sakarya', 40.69, 30.4], ['Samsun', 41.29, 36.33], ['Siirt', 37.93, 41.94], ['Sinop', 42.03, 35.15], ['Sivas', 39.75, 37.02],
  ['Şanlıurfa', 37.16, 38.79], ['Şırnak', 37.52, 42.46], ['Tekirdağ', 40.98, 27.51], ['Tokat', 40.31, 36.55], ['Trabzon', 41.0, 39.72],
  ['Tunceli', 39.11, 39.55], ['Uşak', 38.68, 29.41], ['Van', 38.5, 43.37], ['Yalova', 40.65, 29.27], ['Yozgat', 39.82, 34.81], ['Zonguldak', 41.45, 31.79],
].map(([ad, lat, lng]) => ({ ad, lat, lng }));

// Büyük şehirlerin sık geçen ilçeleri (adreste il yazmıyorsa ipucu)
const ILCE = {
  İstanbul: ['kadıköy', 'beşiktaş', 'şişli', 'beyoğlu', 'üsküdar', 'ataşehir', 'maltepe', 'kartal', 'pendik', 'bakırköy', 'fatih', 'sarıyer', 'bahçelievler', 'esenyurt', 'beylikdüzü', 'zeytinburnu', 'avcılar', 'başakşehir', 'sultanbeyli', 'ümraniye', 'çekmeköy', 'sancaktepe', 'kağıthane', 'eyüpsultan', 'caddebostan', 'moda', 'taksim'],
  Ankara: ['çankaya', 'keçiören', 'yenimahalle', 'mamak', 'etimesgut', 'sincan', 'altındağ', 'kızılay', 'çayyolu', 'ulus'],
  İzmir: ['konak', 'karşıyaka', 'bornova', 'buca', 'alsancak', 'çiğli', 'bayraklı', 'balçova', 'narlıdere'],
};
const nor = (t) => String(t || '').toLocaleLowerCase('tr').replace(/i̇/g, 'i');

function uzaklik(a, b, c, d) {
  const r = Math.PI / 180, x = (d - b) * r * Math.cos(((a + c) / 2) * r), y = (c - a) * r;
  return Math.sqrt(x * x + y * y) * 6371;
}
export function enYakinIl(lat, lng, azami = 120) {
  let en = null, mn = 1e9;
  for (const i of ILLER) { const u = uzaklik(lat, lng, i.lat, i.lng); if (u < mn) { mn = u; en = i; } }
  return mn <= azami ? { ...en, km: mn } : null;
}
export function ilBul({ city, address, lat, lng } = {}) {
  if (city) { const k = ILLER.find((i) => nor(i.ad) === nor(city)); if (k) return k.ad; }
  const t = nor(address);
  if (t) {
    for (const [il, liste] of Object.entries(ILCE)) if (liste.some((x) => t.includes(x)) && t.includes(nor(il).slice(0, 4))) return il;
    const bulunan = ILLER.find((i) => new RegExp(`(^|[^a-zçğıöşü])${nor(i.ad)}([^a-zçğıöşü]|$)`).test(t));
    if (bulunan) return bulunan.ad;
    for (const [il, liste] of Object.entries(ILCE)) if (liste.some((x) => t.includes(x))) return il;
  }
  if (typeof lat === 'number' && typeof lng === 'number' && lat && lng) return enYakinIl(lat, lng)?.ad || '';
  return '';
}

// Seçili il (tarayıcıda saklanır). '' = tüm Türkiye
const KEY = 'tiyatrol.il.v1';
export const ilOku = () => { try { return localStorage.getItem(KEY) || ''; } catch { return ''; } };
export function ilYaz(il) {
  try { localStorage.setItem(KEY, il || ''); } catch {}
  document.dispatchEvent(new CustomEvent('il-degisti', { detail: { il } }));
}

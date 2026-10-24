// Küçük yardımcılar: kaçış, slug, tarih/fiyat biçimleri, DOM kısayolları.
export const $ = (s, r = document) => r.querySelector(s);
export const $$ = (s, r = document) => [...r.querySelectorAll(s)];
export const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const TR = { ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', Ç: 'c', Ğ: 'g', İ: 'i', I: 'i', Ö: 'o', Ş: 's', Ü: 'u' };
export const slugify = (t) => String(t || '').replace(/[çğıöşüÇĞİIÖŞÜ]/g, (c) => TR[c]).toLowerCase()
  .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'detay';
// kind: oyun | oyuncu | sahne | topluluk — Firestore doküman id'si adresin son parçasıdır.
export const linkOf = (kind, item) => `/${kind}/${slugify(item.name || item.fullName)}-${item.id}`;
export const idFromPath = () => decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() || '').split('-').pop();

export const GUNLER = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
export const GUN_KISA = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
export const AYLAR = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
export const AY_KISA = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
export const gunAdi = (d) => GUNLER[(d.getDay() + 6) % 7];
export const gunKisa = (d) => GUN_KISA[(d.getDay() + 6) % 7];
export const saat = (d) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
export const tarihUzun = (d) => `${d.getDate()} ${AYLAR[d.getMonth()]} ${gunAdi(d)}`;
export const ayniGun = (a, b) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
export const gunBasi = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
export const tl = (n) => (n == null || isNaN(n) ? '' : `${Math.round(n).toLocaleString('tr-TR')} ₺`);
export const sayi = (v) => { const n = parseFloat(String(v ?? '').replace(',', '.')); return isNaN(n) ? null : n; };
export const kisalt = (t, n = 160) => { t = String(t || '').replace(/\s+/g, ' ').trim(); return t.length > n ? t.slice(0, n - 1).trimEnd() + '…' : t; };
export const debounce = (fn, ms = 200) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
export function tarihAyristir(v) {
  if (!v) return null;
  if (typeof v.toDate === 'function') return v.toDate();
  // Uygulamanın yazdığı biçim: "15.11.2026,22:00" (gg.aa.yyyy,ss:dd)
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})[,\s]+(\d{1,2}):(\d{2})/.exec(String(v).trim());
  if (m) return new Date(+m[3], +m[2] - 1, +m[1], +m[4], +m[5]);
  const d = new Date(v);
  return isNaN(d) ? null : d;
}
export const baslangic = (n) => String(n || '?').trim().split(/\s+/).slice(0, 2).map((p) => p[0]).join('').toUpperCase();

// Tema modülü: asıl iş /js/theme-core.js (head'de klasik betik) içinde. Burası modüllere ince bir kapı.
// Çekirdek yüklenmediyse (nadir) yedek olarak aynı dosya dinamik yüklenir.
const T = window.TiyatTema;
if (!T) throw new Error('theme-core.js yüklenmedi: sayfanın <head> bölümüne <script src="/js/theme-core.js"></script> ekle.');
export const temaSecenekleri = T.PRESETS;
export const temaOku = () => T.oku();
export const temaYaz = (p) => T.yaz(p);
export const temaUygula = (s) => T.uygula(s);
export const temaHesapla = (s) => T.hesapla(s);

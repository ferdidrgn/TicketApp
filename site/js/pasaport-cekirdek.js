// Tiyatro Pasaportu çekirdeği: SAF mantık (DOM/Firebase yok), tarayıcıda ve node testinde aynı çalışır.
// Mobil karşılığı: lib/features/passport/domain/passport.dart — tanım ve test vektörleri docs/PASAPORT.md'de.
// Hiçbir şey sunucuya yazılmaz; her şey kullanıcının kendi biletlerinden istemcide hesaplanır.

const RAKAM = /^(\d{1,2})\.(\d{1,2})\.(\d{4})(?:[,\s]+(\d{1,2}):(\d{2}))?$/;

/** Tarih ayrıştırıcı. "15.11.2026,22:00" | "15.11.2026 22:00" | "15.11.2026" (gün sonu) | ISO | Date | Timestamp. Çözülemezse null. */
export function tarihOku(v) {
  if (v == null || v === '') return null;
  if (v instanceof Date) return isNaN(v) ? null : v;
  if (typeof v.toDate === 'function') { const d = v.toDate(); return isNaN(d) ? null : d; }
  if (typeof v === 'object' && v.seconds != null) return new Date(v.seconds * 1000);
  const s = String(v).trim();
  const m = RAKAM.exec(s);
  if (m) {
    const g = +m[1], a = +m[2], y = +m[3], tamSaat = m[4] != null;
    const sa = tamSaat ? +m[4] : 23, dk = tamSaat ? +m[5] : 59;
    const d = new Date(y, a - 1, g, sa, dk);
    // 31.02.2026 gibi taşan tarihleri reddet
    return d.getFullYear() === y && d.getMonth() === a - 1 && d.getDate() === g && sa < 24 && dk < 60 ? d : null;
  }
  if (!/^\d{4}-\d{2}-\d{2}/.test(s)) return null;
  const d = new Date(s);
  return isNaN(d) ? null : d;
}

/**
 * 'İZLENDİ' tanımı (tek kaynak). b: { iptal:bool, odeme:string, usedAt:any, tarih:any }.
 * - iptal edilmiş ya da 'no_show' -> izlenmedi
 * - usedAt dolu (kapıdan geçti) -> izlendi
 * - değilse seans tarihi ayrıştırılabilir VE şu andan önce -> izlendi
 * - ayrıştırılamayan tarih -> izlendi SAYILMAZ
 */
export function izlendiMi(b, simdi = new Date()) {
  if (b.iptal || b.odeme === 'cancelled' || b.odeme === 'no_show') return false;
  if (b.usedAt != null && b.usedAt !== false && String(b.usedAt).trim() !== '') return true;
  const d = tarihOku(b.tarih);
  return !!d && d.getTime() < simdi.getTime();
}

const anahtar = (s) => String(s || '').trim().toLocaleLowerCase('tr');

/**
 * Biletlerden pasaport özeti. girdi: [{ id, eventId, showId, showName, stageId, stageName, resim, iptal, odeme, usedAt, tarih }]
 * Dönüş: { izlenenler(etkinlik başına, yeniden eskiye), oyunSayisi, sahneSayisi, buYil, damgalar, rozetler, bos }
 */
export function pasaportHesapla(girdi, simdi = new Date()) {
  const goruldu = new Set(), izlenenler = [];
  for (const b of girdi || []) {
    if (!izlendiMi(b, simdi)) continue;
    const oyun = anahtar(b.showId) || anahtar(b.showName);
    if (!oyun) continue;
    const tarih = tarihOku(b.tarih) || tarihOku(b.usedAt);
    // Aynı seans için birden çok bilet tek izleme sayılır
    const k = anahtar(b.eventId) || `${oyun}|${tarih ? tarih.getTime() : b.id}`;
    if (goruldu.has(k)) continue;
    goruldu.add(k);
    izlenenler.push({ id: String(b.id), oyun, ad: b.showName || 'Tiyatro oyunu', sahne: b.stageName || '', sahneKey: anahtar(b.stageId) || anahtar(b.stageName), resim: b.resim || '', tarih });
  }
  izlenenler.sort((a, b) => (b.tarih?.getTime() || 0) - (a.tarih?.getTime() || 0));

  const oyunlar = new Set(izlenenler.map((x) => x.oyun));
  const buYil = new Set(izlenenler.filter((x) => x.tarih && x.tarih.getFullYear() === simdi.getFullYear()).map((x) => x.oyun)).size;

  const damgaMap = new Map();
  for (const x of izlenenler) {
    if (!x.sahneKey) continue;
    const d = damgaMap.get(x.sahneKey) || { key: x.sahneKey, ad: x.sahne || 'Sahne', sayi: 0, ilk: null };
    d.sayi += 1;
    if (x.sahne) d.ad = x.sahne;
    if (x.tarih && (!d.ilk || x.tarih < d.ilk)) d.ilk = x.tarih;
    damgaMap.set(x.sahneKey, d);
  }
  const damgalar = [...damgaMap.values()].sort((a, b) => b.sayi - a.sayi || a.ad.localeCompare(b.ad, 'tr'));
  const enCokAyniSahne = damgalar.reduce((m, d) => Math.max(m, d.sayi), 0);

  const r = (id, ad, nasil, simdiki, hedef) => ({ id, ad, nasil, simdiki: Math.min(simdiki, hedef), hedef, kazanildi: simdiki >= hedef });
  const rozetler = [
    r('ilk-perde', 'İlk perde', 'Bir oyun izle (bileti kapıdan geçmiş ya da seansı geçmiş olsun).', oyunlar.size, 1),
    r('sahne-gezgini', '5 farklı sahne', '5 farklı sahnede oyun izle.', damgalar.length, 5),
    r('sadik-seyirci', 'Sadık seyirci', 'Aynı sahnede 3 ayrı seans izle.', enCokAyniSahne, 3),
    r('sezon-yildizi', 'Sezon yıldızı', `${simdi.getFullYear()} yılında 5 farklı oyun izle.`, buYil, 5),
    r('on-perde', 'On perde', 'Toplam 10 farklı oyun izle.', oyunlar.size, 10),
  ];
  return { izlenenler, oyunSayisi: oyunlar.size, sahneSayisi: damgalar.length, buYil, damgalar, rozetler, bos: izlenenler.length === 0 };
}

/** Paylaşım metni: kişisel veri (ad, telefon, e-posta) İÇERMEZ. */
export function paylasimMetni(p) {
  if (p.bos) return 'TiyatRol Tiyatro Pasaportum: ilk perdeyi bekliyorum.';
  const kz = p.rozetler.filter((x) => x.kazanildi).length;
  return `TiyatRol Tiyatro Pasaportum: ${p.oyunSayisi} oyun, ${p.sahneSayisi} sahne, bu yıl ${p.buYil} oyun, ${kz} rozet.`;
}

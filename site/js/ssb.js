// Kural tabanlı SSS botu (Q-2, docs/SSS-BOTU.md). YAPAY ZEKA YOK: Türkçe normalizasyon + anahtar sözcük (kök) eşleşmesi.
// Cevap YALNIZ oyunun gerçek alanlarından ya da sabit politika cümlesinden üretilir; alan yoksa cevap null (uydurma yok).
// Aynı kural tablosu mobilde lib/features/shows/domain/faq_bot.dart içinde (soru formundaki "Cevap burada
// olabilir" önizlemesi için); ortak test vektörleri docs/ssb-vectors.json. Mobildeki ayrı sohbet balonu
// (lib/features/chatbot/.../show_faq_matcher.dart) BAŞKA, daha zengin bir uygulama — bu iki Dart dosyası
// birbirinden bağımsız, kasıtlı olarak ayrı tutuldu. Bu dosyayı değiştirirsen faq_bot.dart'ı ve
// docs/SSS-BOTU.md tablosunu BİRLİKTE güncelle.

/** Türkçe normalizasyon: küçük harf, ı/ğ/ş/ü/ö/ç -> i/g/s/u/o/c, harf-rakam dışı -> boşluk. */
export function norm(s) {
  let o = '';
  for (const ch of String(s == null ? '' : s)) {
    o += ch === 'İ' || ch === 'I' || ch === 'ı' ? 'i' : ch;
  }
  return o.toLowerCase().replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ş/g, 's').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[^a-z0-9]+/g, ' ').trim();
}

/** Anahtar sözcük: sözcük BAŞINDA eşleşir (ek-siz kök: "dakika" -> "dakikadir"). Sonu "$" ise tam sözcük. */
function eslesir(metin, kw) {
  const tam = kw.endsWith('$');
  const k = tam ? kw.slice(0, -1) : kw;
  const s = ` ${metin} `;
  return tam ? s.includes(` ${k} `) : s.includes(` ${k}`);
}

export const NIYETLER = [
  { id: 'sure', kw: ['sure', 'suruyor', 'surer', 'kac dakika', 'kac saat', 'kac dk', 'uzun', 'ne zaman biter', 'kacta biter', 'dakika'] },
  { id: 'cocuk', kw: ['cocu', 'bebek', 'minik', 'ilkokul', 'ortaokul', 'anaokul'] },
  { id: 'yas', kw: ['yas$', 'yasi$', 'yasinda', 'yas sinir', 'kac yas', 'yas kisit', 'yetiskin'] },
  { id: 'ara', kw: ['ara$', 'araya', 'ara var', 'antrakt', 'intermission', 'kac ara'] },
  { id: 'gec', kw: ['gec kal', 'gec gel', 'gec gir', 'gec kald', 'geciktim', 'gecik', 'salona al', 'sonradan gir', 'basladiktan sonra'] },
  { id: 'iade', kw: ['iade', 'iptal', 'geri ver', 'para iade', 'bileti degis', 'vazgec', 'bileti ver'] },
  { id: 'bilet', kw: ['nasil bilet', 'bilet al', 'biletini nereden', 'bilet nereden', 'bilet nerden', 'nereden al', 'nerden al', 'satin al', 'rezervasyon', 'bilet nasil', 'nasil alirim', 'nasil alabilir', 'nasil satin'] },
  { id: 'erisim', kw: ['engelli', 'erisil', 'tekerlek', 'rampa', 'asansor', 'sesli betimleme', 'isaret dili', 'altyazi', 'isitme', 'gorme', 'kolay erisim'] },
  { id: 'ulasim', kw: ['park', 'otopark', 'ulasim', 'metro', 'otobus', 'nasil gid', 'nasil gel', 'yol tarif', 'adres', 'nerede$', 'nerde$', 'konum', 'mekan'] },
  { id: 'uyari', kw: ['icerik uyari', 'uyari', 'siddet', 'kufur', 'argo', 'korku', 'cinsel', 'strobo', 'isik efekt', 'yuksek ses', 'silah', 'kan$'] },
  { id: 'kadro', kw: ['kim oynuyor', 'kimler oynuyor', 'kim oynar', 'oyuncu', 'oyuncular', 'kadro', 'ekip kim', 'oyun ekibi', 'kim var$', 'kimler var$', 'kim rol'] },
  { id: 'fiyat', kw: ['fiyat', 'ucret', 'kac para', 'bilet fiyat', 'ne kadar tutuyor', 'kaca'] },
  { id: 'tarih', kw: ['ne zaman oynuyor', 'ne zaman var', 'hangi tarih', 'sonraki seans', 'bir sonraki seans', 'yaklasan seans', 'bugun var mi', 'bu hafta var mi'] },
  { id: 'konu', kw: ['konu', 'ozet', 'ne anlatiyor', 'hikayesi ne', 'nedir bu oyun', 'ne hakkinda'] },
];

export const YOK = 'Bu konuda bilgi yok, ekibe sorabilirsin.';
const GUNLER = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
const AYLAR = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
/** Bağımsız (import'suz) tarih biçimi: "15 Kasım Pazar saat 20:00" — site/js/util.js'teki tarihUzun/saat ile aynı mantık. */
function tarihSaat(d) {
  const gun = GUNLER[(d.getDay() + 6) % 7];
  return `${d.getDate()} ${AYLAR[d.getMonth()]} ${gun} saat ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}
const ERIS_AD = { AD: 'Sesli betimleme', CAP: 'Altyazılı', BSL: 'İşaret dili', R: 'Rahat gösterim', TS: 'İşaret dili' };
const nokta = (s) => (/[.!?]$/.test(s) ? s : `${s}.`);
const dolu = (v) => typeof v === 'string' && v.trim() !== '';

/**
 * facts: { name, duration, ageLimit, interval, contentNotes, accessCodes[], venueName, venueAddress, transit, accessNotes,
 *          external(bool), externalHost, ended(bool), saleMode('rezervasyon'|'online'|'kapali') }
 * -> { intent: string (''=anlaşılmadı), answer: string|null }
 */
export function sor(soru, facts) {
  const f = facts || {};
  const m = norm(soru);
  let en = null, enPuan = 0;
  for (const n of NIYETLER) {
    const p = n.kw.reduce((a, k) => a + (eslesir(m, k) ? 1 : 0), 0);
    if (p > enPuan) { en = n; enPuan = p; }
  }
  if (!en) return { intent: '', answer: null };
  return { intent: en.id, answer: cevap(en.id, f) };
}

function cevap(id, f) {
  const notlar = dolu(f.contentNotes) ? ` İçerik uyarısı: ${nokta(f.contentNotes.trim())}` : '';
  switch (id) {
    case 'sure':
      if (!dolu(f.duration)) return null;
      return `Oyunun süresi ${f.duration.trim()}${dolu(f.interval) ? `; ${f.interval.trim()}` : ''}.`;
    case 'yas':
      if (!dolu(f.ageLimit)) return null;
      return `Önerilen yaş: ${f.ageLimit.trim()}.${notlar}`;
    case 'cocuk':
      if (!dolu(f.ageLimit) && !dolu(f.contentNotes)) return null;
      return `${dolu(f.ageLimit) ? `Önerilen yaş: ${f.ageLimit.trim()}.` : ''}${notlar} Küçük çocuklarla gelmeden önce yaş önerisine ve içerik uyarısına bakmanı öneririz.`.trim();
    case 'ara':
      return dolu(f.interval) ? `Ara bilgisi: ${nokta(f.interval.trim())}` : null;
    case 'gec':
      return 'Geç kalanların salona alınıp alınmayacağı ve hangi arada alınacağı salona ve organizatöre göre değişir; garanti verilemez. Seanstan 20-30 dakika önce yerinde olmanı öneririz.';
    case 'iade':
      if (f.external) return `Bilet bu sitede değil ${dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesinde'} satıldığı için iade ve iptal koşullarını satış yapılan platformdan öğrenmelisin.`;
      return f.saleMode === 'rezervasyon'
        ? 'Şu an biletler rezervasyon olarak veriliyor; etkinlikten (varsayılan) 24 saat öncesine kadar Biletlerim sayfasından iptal edebilirsin. Ayrıntılar İade ve İptal Koşulları sayfasında.'
        : 'İptal ve iade koşulları satış moduna ve etkinliğe göre değişir; güncel koşullar İade ve İptal Koşulları sayfasında yer alır. Organizatör etkinliği iptal ederse bilet bedelinin tamamı iade edilir.';
    case 'bilet':
      if (f.ended) return null;
      return f.external
        ? `Biletler ${dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesi'} üzerinden satılıyor; TiyatRol seni doğru sayfaya yönlendirir.`
        : 'Bu sayfada bir seans seçip Bilet al diyerek koltuğunu seçebilirsin; biletlerin hesabındaki Biletlerim sayfasında ve uygulamada görünür.';
    case 'erisim': {
      const kodlar = [...new Set((f.accessCodes || []).map((k) => ERIS_AD[String(k).toUpperCase()]).filter(Boolean))];
      const p = [];
      if (kodlar.length) p.push(`Erişilebilir gösterim etiketleri: ${kodlar.join(', ')}.`);
      if (dolu(f.accessNotes)) p.push(`Mekân notu: ${nokta(f.accessNotes.trim())}`);
      return p.length ? p.join(' ') : null;
    }
    case 'ulasim': {
      const p = [];
      if (dolu(f.venueName)) p.push(`Mekân: ${f.venueName.trim()}${dolu(f.venueAddress) ? `, ${f.venueAddress.trim()}` : ''}.`);
      if (dolu(f.transit)) p.push(`Ulaşım: ${nokta(f.transit.trim())}`);
      return p.length ? p.join(' ') : null;
    }
    case 'uyari':
      return dolu(f.contentNotes) ? `İçerik uyarısı: ${nokta(f.contentNotes.trim())}` : null;
    case 'kadro': {
      const isimler = (f.castNames || []).filter(dolu);
      if (!isimler.length) return null;
      const takim = dolu(f.teamName) ? ` Oyunu sahneleyen topluluk: ${f.teamName.trim()}.` : '';
      return `Kadroda: ${isimler.join(', ')}.${takim}`;
    }
    case 'fiyat':
      if (f.ended) return null;
      if (f.external) return `Bilet fiyatını ${dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesinde'} görebilirsin.`;
      if (f.price == null) return null;
      return f.price > 0 ? `En yakın seans için bilet fiyatı: ${Math.round(f.price)} ₺.` : 'En yakın seans ücretsiz.';
    case 'tarih':
      if (!dolu(f.nextDate)) return f.ended ? 'Bu oyunun planlanmış, tarihi geçmemiş bir seansı görünmüyor.' : null;
      return `En yakın seans: ${f.nextDate.trim()}${dolu(f.venueName) ? `, ${f.venueName.trim()}` : ''}.`;
    case 'konu':
      return dolu(f.description) ? f.description.trim() : null;
    default:
      return null;
  }
}

/** Oyun nesnesinden (site store.js biçimi) facts üretir. */
export function factsOf(s, yer, { alan = '', mod = 'rezervasyon' } = {}) {
  return {
    name: s.name || '', duration: s.duration || '', ageLimit: s.ageLimit || '', interval: s.interval || '', contentNotes: s.contentNotes || '',
    accessCodes: s.accessKodlari || [], venueName: (yer && yer.name) || s.externalVenueName || '', venueAddress: (yer && yer.address) || s.externalVenueAddress || '',
    transit: (yer && yer.transit) || '', accessNotes: (yer && yer.accessNotes) || '', external: !!s.external, externalHost: alan, ended: s.state === 'bitti', saleMode: mod,
    castNames: (s.cast || []).map((p) => p.fullName).filter(Boolean), teamName: (s.team && s.team.name) || '',
    price: s.next && s.next.priceNum != null ? s.next.priceNum : null,
    nextDate: s.next ? tarihSaat(s.next.when) : '', description: s.description || '',
  };
}

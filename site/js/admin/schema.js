// Yönetim paneli şeması: her koleksiyonun alanları, tabloda görünen sütunlar,
// ilişkiler. Alan adları mobil uygulamanın modelleriyle BİREBİR aynıdır
// (lib/features/*/data/models/*_model.dart) — uygulama ve site aynı veriyi okur.
// tip: text | onay (tek onay kutusu) | secenekler (çoklu onay kutusu) | area | img | sel (tek ilişki) | multi (çoklu ilişki) | lines (satır satır liste) | dt (tarih-saat) | day (gün) | num
// 'secenekler' tipi: kutular işaretlenir; veri yine kod dizisi olarak saklanır (mobil uygulamayla aynı).
export const ERISIM_SECENEKLERI = [
  { kod: 'AD', ad: 'Sesli betimleme (AD)', acik: 'Görme engelliler için sahnede olanı anlatan sesli betimleme' },
  { kod: 'CAP', ad: 'Altyazılı / üstyazılı (CAP)', acik: 'Konuşmalar ekranda yazı olarak gösterilir; işitme engelliler için' },
  { kod: 'BSL', ad: 'İşaret dili tercümanlı (BSL/TİD)', acik: 'Sahnede işaret dili tercümanı bulunur' },
  { kod: 'R', ad: 'Rahat gösterim (R)', acik: 'Sakin ortam: ışık ve ses kısılır, salonda gezinmek ve ses çıkarmak serbesttir' },
];
export const KOLEKSIYONLAR = {
  Show: {
    ad: 'Oyunlar', tek: 'Oyun', ikon: '🎭', baslik: (x) => x.name,
    sutunlar: ['imageUrl', 'name', 'category', 'type'],
    alanlar: [
      { k: 'name', e: 'Oyun adı', t: 'text', zorunlu: true, tam: true },
      { k: 'category', e: 'Tür', t: 'text', liste: 'turler', ipucu: 'Örn. Komedi, Dram, Çocuk' },
      { k: 'type', e: 'Çeşit', t: 'text', ipucu: 'Örn. Oyun, Müzikal, Stand-up' },
      { k: 'duration', e: 'Süre', t: 'text', ipucu: 'Örn. 90 dk' },
      { k: 'ageLimit', e: 'Yaş sınırı', t: 'text', ipucu: 'Örn. 7+ ya da 18+' },
      { k: 'teamId', e: 'Topluluk', t: 'sel', kaynak: 'Team', ipucu: 'Oyunu sahneleyen tiyatro topluluğu' },
      { k: 'imageUrl', e: 'Afiş', t: 'img', tam: true },
      { k: 'description', e: 'Açıklama', t: 'area', tam: true },
      { k: 'nowPlayersId', e: 'Kadro (şu an)', t: 'multi', kaynak: 'Player', tam: true, ipucu: 'Şu an oyunda oynayan oyuncular' },
      { k: 'oldPlayersId', e: 'Eski kadro', t: 'multi', kaynak: 'Player', tam: true, ipucu: 'Daha önce oynamış, artık oynamayan oyuncular' },
      { k: 'photosShowId', e: 'Galeri (her satıra bir görsel adresi)', t: 'lines', tam: true, ipucu: 'Görsel adreslerini alt alta yaz; boş satırlar yok sayılır.' },
      { k: 'externalTicketUrl', e: 'Harici bilet bağlantısı', t: 'text', tam: true, ipucu: 'Bilet başka sitede satılıyorsa' },
      { k: 'externalVenueName', e: 'Harici mekân adı', t: 'text', ipucu: 'Sahne kaydı yoksa gösterilecek mekân adı' },
      { k: 'externalVenueAddress', e: 'Harici mekân adresi', t: 'text', ipucu: 'Sahne kaydı yoksa gösterilecek adres' },
      { k: 'externalLat', e: 'Harici mekân enlemi', t: 'num', ipucu: 'Harita konumu için, örn. 41.0082' },
      { k: 'externalLng', e: 'Harici mekân boylamı', t: 'num', ipucu: 'Harita konumu için, örn. 28.9784' },
      { k: 'eventRule', e: 'Giriş kuralları', t: 'text', tam: true, ipucu: 'Örn. Oyun başladıktan sonra salona girilemez' },
      { k: 'access', e: 'Erişilebilir performans', t: 'secenekler', tam: true, ipucu: 'Bu oyunun seanslarında sunulan erişilebilirlik hizmetlerini işaretle.', secenekler: ERISIM_SECENEKLERI },
      { k: 'contentNotes', e: 'İçerik uyarısı', t: 'text', tam: true, ipucu: 'Örn. şiddet, küfür, yanıp sönen ışık' },
      { k: 'interval', e: 'Ara', t: 'text', ipucu: 'Örn. 15 dk ara var' },
      { k: 'featured', e: 'Haftanın oyunu', t: 'onay', onayDeger: 'evet', onayMetin: 'Bu oyunu ana sayfa vitrininde öne çıkar', ipucu: 'Aynı anda birkaç oyun işaretlenebilir; vitrin en uygununu seçer.' },
    ],
  },
  Event: {
    ad: 'Seanslar', tek: 'Seans', ikon: '🗓️', baslik: (x) => x.date,
    sutunlar: ['showId', 'stageId', 'date', 'price'],
    alanlar: [
      { k: 'showId', e: 'Oyun', t: 'sel', kaynak: 'Show', zorunlu: true, tam: true },
      { k: 'stageId', e: 'Sahne', t: 'sel', kaynak: 'Stage', zorunlu: true, tam: true },
      { k: 'date', e: 'Tarih ve saat', t: 'dt', zorunlu: true },
      { k: 'price', e: 'Bilet fiyatı (₺)', t: 'text', ipucu: '0 = ücretsiz' },
      { k: 'cancelled', e: 'Seans iptal edildi — iptal için "evet" yaz (bilet sahiplerine otomatik bildirim gider; tarihi değiştirirsen "ertelendi" bildirimi gider)', t: 'text', tam: true },
    ],
  },
  Stage: {
    ad: 'Sahneler', tek: 'Sahne', ikon: '🏛️', baslik: (x) => x.name,
    sutunlar: ['imageUrl', 'name', 'address', 'capacity'],
    alanlar: [
      { k: 'name', e: 'Sahne adı', t: 'text', zorunlu: true, tam: true },
      { k: 'imageUrl', e: 'Fotoğraf', t: 'img', tam: true },
      { k: 'capacity', e: 'Kapasite', t: 'text' },
      { k: 'communication', e: 'İletişim', t: 'text', ipucu: 'Telefon veya e-posta' },
      { k: 'address', e: 'Adres', t: 'text', tam: true },
      { k: 'city', e: 'İl', t: 'text', ipucu: 'Boş bırakılırsa adresten bulunur' },
      { k: 'transit', e: 'Ulaşım', t: 'text', tam: true, ipucu: 'Metro, otobüs, otopark bilgisi' },
      { k: 'accessNotes', e: 'Erişilebilirlik notları', t: 'text', tam: true, ipucu: 'Rampa, asansör, engelli girişi gibi' },
      { k: 'lat', e: 'Enlem', t: 'text', ipucu: 'Harita konumu için, örn. 41.0082' },
      { k: 'long', e: 'Boylam', t: 'text', ipucu: 'Harita konumu için, örn. 28.9784' },
      { k: 'description', e: 'Açıklama', t: 'area', tam: true },
    ],
  },
  Team: {
    ad: 'Topluluklar', tek: 'Topluluk', ikon: '👥', baslik: (x) => x.name,
    sutunlar: ['imageUrl', 'name'],
    alanlar: [
      { k: 'name', e: 'Topluluk adı', t: 'text', zorunlu: true, tam: true },
      { k: 'imageUrl', e: 'Görsel', t: 'img', tam: true },
      { k: 'description', e: 'Açıklama', t: 'area', tam: true },
      { k: 'photosId', e: 'Galeri (her satıra bir görsel adresi)', t: 'lines', tam: true },
    ],
  },
  Player: {
    ad: 'Oyuncular', tek: 'Oyuncu', ikon: '🎤', baslik: (x) => `${x.firstName || ''} ${x.lastName || ''}`.trim(),
    sutunlar: ['imageUrl', 'firstName', 'lastName'],
    alanlar: [
      { k: 'firstName', e: 'Ad', t: 'text', zorunlu: true },
      { k: 'lastName', e: 'Soyad', t: 'text', zorunlu: true },
      { k: 'imageUrl', e: 'Fotoğraf', t: 'img', tam: true },
      { k: 'quote', e: 'Sözü', t: 'text', tam: true, ipucu: 'Oyuncunun profilinde görünen kısa söz' },
      { k: 'bio', e: 'Biyografi', t: 'area', tam: true },
      { k: 'achievements', e: 'Ödüller — her satıra: Yıl | Başlık | Detay', t: 'odul', tam: true },
      { k: 'collaborations', e: 'İş birlikleri', t: 'lines', tam: true, ipucu: 'Her satıra bir tane yaz' },
      { k: 'nowShowsId', e: 'Şu an oynadığı oyunlar', t: 'multi', kaynak: 'Show', tam: true },
      { k: 'oldShowsId', e: 'Eski oyunları', t: 'multi', kaynak: 'Show', tam: true },
    ],
  },
  Campaign: {
    ad: 'Kampanyalar', tek: 'Kampanya', ikon: '🏷️', baslik: (x) => x.title,
    sutunlar: ['imageUrl', 'title', 'startDate', 'endDate'],
    alanlar: [
      { k: 'title', e: 'Başlık', t: 'text', zorunlu: true, tam: true },
      { k: 'imageUrl', e: 'Görsel', t: 'img', tam: true },
      { k: 'url', e: 'Bağlantı', t: 'text', tam: true, ipucu: 'Kampanyaya tıklayınca açılacak adres' },
      { k: 'startDate', e: 'Başlangıç', t: 'day' },
      { k: 'endDate', e: 'Bitiş', t: 'day' },
    ],
  },
};

export const SUTUN_ADI = {
  imageUrl: '', name: 'Ad', category: 'Tür', type: 'Çeşit', showId: 'Oyun', stageId: 'Sahne', date: 'Tarih', price: 'Fiyat',
  address: 'Adres', capacity: 'Kapasite', firstName: 'Ad', lastName: 'Soyad', title: 'Başlık', startDate: 'Başlangıç', endDate: 'Bitiş',
};

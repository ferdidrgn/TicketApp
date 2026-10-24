// Yönetim paneli şeması: her koleksiyonun alanları, tabloda görünen sütunlar,
// ilişkiler. Alan adları mobil uygulamanın modelleriyle BİREBİR aynıdır
// (lib/features/*/data/models/*_model.dart) — uygulama ve site aynı veriyi okur.
// tip: text | area | img | sel (tek ilişki) | multi (çoklu ilişki) | lines (satır satır liste) | dt (tarih-saat) | day (gün) | num
export const KOLEKSIYONLAR = {
  Show: {
    ad: 'Oyunlar', tek: 'Oyun', ikon: '🎭', baslik: (x) => x.name,
    sutunlar: ['imageUrl', 'name', 'category', 'type'],
    alanlar: [
      { k: 'name', e: 'Oyun adı', t: 'text', zorunlu: true, tam: true },
      { k: 'category', e: 'Tür', t: 'text', liste: 'turler', ipucu: 'Örn. Komedi, Dram, Çocuk' },
      { k: 'type', e: 'Çeşit', t: 'text' },
      { k: 'duration', e: 'Süre', t: 'text', ipucu: 'Örn. 90 dk' },
      { k: 'ageLimit', e: 'Yaş sınırı', t: 'text' },
      { k: 'teamId', e: 'Topluluk', t: 'sel', kaynak: 'Team' },
      { k: 'imageUrl', e: 'Afiş', t: 'img', tam: true },
      { k: 'description', e: 'Açıklama', t: 'area', tam: true },
      { k: 'nowPlayersId', e: 'Kadro (şu an)', t: 'multi', kaynak: 'Player', tam: true },
      { k: 'oldPlayersId', e: 'Eski kadro', t: 'multi', kaynak: 'Player', tam: true },
      { k: 'photosShowId', e: 'Galeri (her satıra bir görsel adresi)', t: 'lines', tam: true },
      { k: 'externalTicketUrl', e: 'Harici bilet bağlantısı', t: 'text', tam: true, ipucu: 'Bilet başka sitede satılıyorsa' },
      { k: 'externalVenueName', e: 'Harici mekân adı', t: 'text' },
      { k: 'externalVenueAddress', e: 'Harici mekân adresi', t: 'text' },
      { k: 'externalLat', e: 'Enlem', t: 'num' },
      { k: 'externalLng', e: 'Boylam', t: 'num' },
      { k: 'eventRule', e: 'Etkinlik kuralı', t: 'text', tam: true },
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
    ],
  },
  Stage: {
    ad: 'Sahneler', tek: 'Sahne', ikon: '🏛️', baslik: (x) => x.name,
    sutunlar: ['imageUrl', 'name', 'address', 'capacity'],
    alanlar: [
      { k: 'name', e: 'Sahne adı', t: 'text', zorunlu: true, tam: true },
      { k: 'imageUrl', e: 'Fotoğraf', t: 'img', tam: true },
      { k: 'capacity', e: 'Kapasite', t: 'text' },
      { k: 'communication', e: 'İletişim (telefon / e-posta)', t: 'text' },
      { k: 'address', e: 'Adres', t: 'text', tam: true },
      { k: 'lat', e: 'Enlem', t: 'text' },
      { k: 'long', e: 'Boylam', t: 'text' },
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
      { k: 'quote', e: 'Sözü', t: 'text', tam: true },
      { k: 'bio', e: 'Biyografi', t: 'area', tam: true },
      { k: 'achievements', e: 'Ödüller (her satıra bir tane)', t: 'lines', tam: true },
      { k: 'collaborations', e: 'İş birlikleri (her satıra bir tane)', t: 'lines', tam: true },
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
      { k: 'url', e: 'Bağlantı', t: 'text', tam: true },
      { k: 'startDate', e: 'Başlangıç', t: 'day' },
      { k: 'endDate', e: 'Bitiş', t: 'day' },
    ],
  },
};

export const SUTUN_ADI = {
  imageUrl: '', name: 'Ad', category: 'Tür', type: 'Çeşit', showId: 'Oyun', stageId: 'Sahne', date: 'Tarih', price: 'Fiyat',
  address: 'Adres', capacity: 'Kapasite', firstName: 'Ad', lastName: 'Soyad', title: 'Başlık', startDate: 'Başlangıç', endDate: 'Bitiş',
};

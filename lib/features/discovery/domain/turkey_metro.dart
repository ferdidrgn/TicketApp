import '../../../../core/services/location_service.dart';

/// Türkiye'de büyük şehir metropol alanları — ücretsiz, çevrimdışı.
///
/// Kullanıcı konumuna en yakın metropol seçilir; "içinde" halkası ve
/// haritada gösterilecek üst mesafe buna göre ayarlanır.
///
/// Harici bilet (Bubilet vb.): şehir URL path slug'ından okunur
/// (`/istanbul/etkinlik/...` → İstanbul). Tur Yozgat'a kayınca admin
/// linki günceller; ayrı bir "şehir" alanı tutulmaz.
class TrMetro {
  final String name;
  final double lat;
  final double lng;

  /// "Yakın" halkası (km) — UI vurgusu.
  final double softRadiusKm;

  /// Haritada gösterilecek üst sınır (km).
  final double hardRadiusKm;

  const TrMetro({
    required this.name,
    required this.lat,
    required this.lng,
    required this.softRadiusKm,
    required this.hardRadiusKm,
  });
}

abstract final class TrMetroAreas {
  TrMetroAreas._();

  static const TrMetro fallback = TrMetro(
    name: 'Türkiye',
    lat: 39.0,
    lng: 35.0,
    softRadiusKm: 50,
    hardRadiusKm: 100,
  );

  /// Büyük şehir merkezleri (yaklaşık) — kullanıcı metropol çözümü.
  static const List<TrMetro> all = [
    TrMetro(
        name: 'İstanbul',
        lat: 41.0082,
        lng: 28.9784,
        softRadiusKm: 50,
        hardRadiusKm: 90),
    TrMetro(
        name: 'Ankara',
        lat: 39.9334,
        lng: 32.8597,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    TrMetro(
        name: 'İzmir',
        lat: 38.4237,
        lng: 27.1428,
        softRadiusKm: 45,
        hardRadiusKm: 80),
    TrMetro(
        name: 'Bursa',
        lat: 40.1885,
        lng: 29.0610,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    TrMetro(
        name: 'Antalya',
        lat: 36.8969,
        lng: 30.7133,
        softRadiusKm: 40,
        hardRadiusKm: 75),
    TrMetro(
        name: 'Adana',
        lat: 37.0000,
        lng: 35.3213,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    TrMetro(
        name: 'Konya',
        lat: 37.8746,
        lng: 32.4932,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    TrMetro(
        name: 'Gaziantep',
        lat: 37.0662,
        lng: 37.3833,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    TrMetro(
        name: 'Kayseri',
        lat: 38.7312,
        lng: 35.4787,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    TrMetro(
        name: 'Eskişehir',
        lat: 39.7767,
        lng: 30.5206,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    TrMetro(
        name: 'Trabzon',
        lat: 41.0027,
        lng: 39.7168,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    TrMetro(
        name: 'Mersin',
        lat: 36.8121,
        lng: 34.6415,
        softRadiusKm: 40,
        hardRadiusKm: 70),
  ];

  /// Bubilet / benzeri path slug → şehir merkezi (pin için).
  /// Metropol listesinde olmayan iller de burada (ör. Yozgat).
  static const Map<String, TrMetro> _bySlug = {
    'istanbul': TrMetro(
        name: 'İstanbul',
        lat: 41.0082,
        lng: 28.9784,
        softRadiusKm: 50,
        hardRadiusKm: 90),
    'ankara': TrMetro(
        name: 'Ankara',
        lat: 39.9334,
        lng: 32.8597,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'izmir': TrMetro(
        name: 'İzmir',
        lat: 38.4237,
        lng: 27.1428,
        softRadiusKm: 45,
        hardRadiusKm: 80),
    'bursa': TrMetro(
        name: 'Bursa',
        lat: 40.1885,
        lng: 29.0610,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'antalya': TrMetro(
        name: 'Antalya',
        lat: 36.8969,
        lng: 30.7133,
        softRadiusKm: 40,
        hardRadiusKm: 75),
    'adana': TrMetro(
        name: 'Adana',
        lat: 37.0000,
        lng: 35.3213,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'konya': TrMetro(
        name: 'Konya',
        lat: 37.8746,
        lng: 32.4932,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'gaziantep': TrMetro(
        name: 'Gaziantep',
        lat: 37.0662,
        lng: 37.3833,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'kayseri': TrMetro(
        name: 'Kayseri',
        lat: 38.7312,
        lng: 35.4787,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'eskisehir': TrMetro(
        name: 'Eskişehir',
        lat: 39.7767,
        lng: 30.5206,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'trabzon': TrMetro(
        name: 'Trabzon',
        lat: 41.0027,
        lng: 39.7168,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'mersin': TrMetro(
        name: 'Mersin',
        lat: 36.8121,
        lng: 34.6415,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'yozgat': TrMetro(
        name: 'Yozgat',
        lat: 39.8200,
        lng: 34.8044,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'samsun': TrMetro(
        name: 'Samsun',
        lat: 41.2867,
        lng: 36.3300,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'kocaeli': TrMetro(
        name: 'Kocaeli',
        lat: 40.7654,
        lng: 29.9408,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'sakarya': TrMetro(
        name: 'Sakarya',
        lat: 40.7731,
        lng: 30.3948,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'tekirdag': TrMetro(
        name: 'Tekirdağ',
        lat: 40.9781,
        lng: 27.5110,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'balikesir': TrMetro(
        name: 'Balıkesir',
        lat: 39.6484,
        lng: 27.8826,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'denizli': TrMetro(
        name: 'Denizli',
        lat: 37.7765,
        lng: 29.0864,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'mugla': TrMetro(
        name: 'Muğla',
        lat: 37.2153,
        lng: 28.3636,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'aydin': TrMetro(
        name: 'Aydın',
        lat: 37.8560,
        lng: 27.8416,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'manisa': TrMetro(
        name: 'Manisa',
        lat: 38.6191,
        lng: 27.4289,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'hatay': TrMetro(
        name: 'Hatay',
        lat: 36.4018,
        lng: 36.3498,
        softRadiusKm: 40,
        hardRadiusKm: 70),
    'diyarbakir': TrMetro(
        name: 'Diyarbakır',
        lat: 37.9144,
        lng: 40.2306,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'sanliurfa': TrMetro(
        name: 'Şanlıurfa',
        lat: 37.1674,
        lng: 38.7955,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'malatya': TrMetro(
        name: 'Malatya',
        lat: 38.3552,
        lng: 38.3095,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'erzurum': TrMetro(
        name: 'Erzurum',
        lat: 39.9043,
        lng: 41.2679,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'van': TrMetro(
        name: 'Van',
        lat: 38.5012,
        lng: 43.3730,
        softRadiusKm: 35,
        hardRadiusKm: 65),
    'afyon': TrMetro(
        name: 'Afyonkarahisar',
        lat: 38.7507,
        lng: 30.5567,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'afyonkarahisar': TrMetro(
        name: 'Afyonkarahisar',
        lat: 38.7507,
        lng: 30.5567,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'canakkale': TrMetro(
        name: 'Çanakkale',
        lat: 40.1553,
        lng: 26.4142,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'edirne': TrMetro(
        name: 'Edirne',
        lat: 41.6771,
        lng: 26.5557,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'sivas': TrMetro(
        name: 'Sivas',
        lat: 39.7477,
        lng: 37.0179,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'corum': TrMetro(
        name: 'Çorum',
        lat: 40.5506,
        lng: 34.9556,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'tokat': TrMetro(
        name: 'Tokat',
        lat: 40.3167,
        lng: 36.5500,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'nevsehir': TrMetro(
        name: 'Nevşehir',
        lat: 38.6244,
        lng: 34.7239,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'kirsehir': TrMetro(
        name: 'Kırşehir',
        lat: 39.1425,
        lng: 34.1709,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'kirikkale': TrMetro(
        name: 'Kırıkkale',
        lat: 39.8468,
        lng: 33.5153,
        softRadiusKm: 35,
        hardRadiusKm: 55),
    'bolu': TrMetro(
        name: 'Bolu',
        lat: 40.7350,
        lng: 31.6061,
        softRadiusKm: 35,
        hardRadiusKm: 55),
    'duzce': TrMetro(
        name: 'Düzce',
        lat: 40.8438,
        lng: 31.1565,
        softRadiusKm: 30,
        hardRadiusKm: 50),
    'zonguldak': TrMetro(
        name: 'Zonguldak',
        lat: 41.4564,
        lng: 31.7987,
        softRadiusKm: 35,
        hardRadiusKm: 55),
    'rize': TrMetro(
        name: 'Rize',
        lat: 41.0201,
        lng: 40.5234,
        softRadiusKm: 30,
        hardRadiusKm: 55),
    'ordu': TrMetro(
        name: 'Ordu',
        lat: 40.9839,
        lng: 37.8764,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'giresun': TrMetro(
        name: 'Giresun',
        lat: 40.9128,
        lng: 38.3895,
        softRadiusKm: 30,
        hardRadiusKm: 55),
    'isparta': TrMetro(
        name: 'Isparta',
        lat: 37.7648,
        lng: 30.5566,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'burdur': TrMetro(
        name: 'Burdur',
        lat: 37.7206,
        lng: 30.2906,
        softRadiusKm: 30,
        hardRadiusKm: 55),
    'osmaniye': TrMetro(
        name: 'Osmaniye',
        lat: 37.0742,
        lng: 36.2478,
        softRadiusKm: 30,
        hardRadiusKm: 55),
    'kahramanmaras': TrMetro(
        name: 'Kahramanmaraş',
        lat: 37.5858,
        lng: 36.9371,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'mardin': TrMetro(
        name: 'Mardin',
        lat: 37.3212,
        lng: 40.7245,
        softRadiusKm: 35,
        hardRadiusKm: 60),
    'batman': TrMetro(
        name: 'Batman',
        lat: 37.8812,
        lng: 41.1351,
        softRadiusKm: 30,
        hardRadiusKm: 55),
    'elazig': TrMetro(
        name: 'Elazığ',
        lat: 38.6810,
        lng: 39.2264,
        softRadiusKm: 35,
        hardRadiusKm: 60),
  };

  /// Türkçe şehir eşlemesi için ASCII'ye yakın katlama
  /// (`İstanbul` / `istanbul` / `ISTANBUL` aynı).
  static String foldTr(final String raw) {
    final StringBuffer out = StringBuffer();
    for (final int u in raw.toLowerCase().runes) {
      if (u == 0x307) {
        // Combining dot above (İ.toLowerCase quirk)
        continue;
      }
      if (u == 0x131 || u == 0x130 || u == 0x69) {
        out.write('i');
      } else if (u == 0x11f || u == 0x11e) {
        out.write('g');
      } else if (u == 0xfc || u == 0xdc) {
        out.write('u');
      } else if (u == 0x15f || u == 0x15e) {
        out.write('s');
      } else if (u == 0xf6 || u == 0xd6) {
        out.write('o');
      } else if (u == 0xe7 || u == 0xc7) {
        out.write('c');
      } else {
        out.writeCharCode(u);
      }
    }
    return out.toString();
  }

  /// Kullanıcı konumuna en yakın metropol; 120 km'den uzaksa [fallback].
  static TrMetro resolve(final double userLat, final double userLng) {
    TrMetro? best;
    double bestM = double.infinity;
    for (final TrMetro m in all) {
      final double d = LocationService.distanceInMeters(
          userLat, userLng, m.lat, m.lng);
      if (d < bestM) {
        bestM = d;
        best = m;
      }
    }
    if (best == null || bestM > 120000) {
      return fallback;
    }
    return best;
  }

  /// Adres metninden şehir (yedek — harici bilet için [fromTicketUrl] tercih).
  static TrMetro? fromAddress(final String address) {
    final String a = foldTr(address);
    if (a.trim().isEmpty) {
      return null;
    }
    // Önce ASCII slug (istanbul, izmir…) — adreslerde en güvenilir.
    for (final MapEntry<String, TrMetro> e in _bySlug.entries) {
      if (a.contains(e.key)) {
        return e.value;
      }
    }
    TrMetro? hit;
    for (final TrMetro m in all) {
      final String key = foldTr(m.name);
      if (!a.contains(key)) {
        continue;
      }
      hit = m;
    }
    return hit;
  }

  /// Harici bilet URL'sinden şehir.
  ///
  /// Örnek: `https://www.bubilet.com.tr/istanbul/etkinlik/herkes-farkli-olur`
  /// → İstanbul. Link `/yozgat/...` olunca pin Yozgat'a kayar — ekstra alan yok.
  static TrMetro? fromTicketUrl(final String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final String host = uri.host.toLowerCase().replaceFirst('www.', '');
    final List<String> parts = uri.pathSegments
        .map((final s) => foldTr(s.trim()))
        .where((final s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return null;
    }

    if (host.contains('bubilet.com')) {
      final TrMetro? city = _bySlug[parts.first];
      if (city != null) {
        return city;
      }
    }

    if (host.contains('biletinial.com') || host.contains('biletix.com')) {
      final TrMetro? city = _bySlug[parts.first];
      if (city != null) {
        return city;
      }
    }

    for (final String p in parts) {
      if (p == 'etkinlik' ||
          p == 'mekan' ||
          p == 'sanatci' ||
          p == 'kategori' ||
          p == 'sehir' ||
          p == 'event' ||
          p == 'tr') {
        continue;
      }
      final TrMetro? city = _bySlug[p];
      if (city != null) {
        return city;
      }
    }
    return null;
  }
}

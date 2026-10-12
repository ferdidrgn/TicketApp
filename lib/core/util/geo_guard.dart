import 'dart:math' as math;

import '../../features/discovery/domain/turkey_metro.dart';

/// Konum girişlerini doğrular — yönetim formlarında yanlış (ör. başka
/// ülkede kalan) koordinatın kaydedilmesini engeller. Saf Dart; ağ yok.
abstract final class GeoGuard {
  // Türkiye'yi çevreleyen kaba kutu (ada ve sınır payıyla).
  static const double _minLat = 35.8;
  static const double _maxLat = 42.2;
  static const double _minLng = 25.6;
  static const double _maxLng = 44.9;

  static bool inTurkey(final double lat, final double lng) =>
      lat >= _minLat && lat <= _maxLat && lng >= _minLng && lng <= _maxLng;

  static double _km(final double aLat, final double aLng, final double bLat,
      final double bLng) {
    const double r = 6371;
    double rad(final double d) => d * math.pi / 180;
    final double dLat = rad(bLat - aLat);
    final double dLng = rad(bLng - aLng);
    final double h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(aLat)) *
            math.cos(rad(bLat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  /// `null` → sorun yok. Metin → kullanıcıya gösterilecek uyarı.
  /// [blocking] true ise kayıt ENGELLENMELİ (Türkiye dışı), false ise
  /// "yine de kaydet?" diye sorulabilir (adresle çelişki).
  static ({String message, bool blocking})? check({
    required final double lat,
    required final double lng,
    final String address = '',
  }) {
    if (!inTurkey(lat, lng)) {
      return (
        message:
            'Bu koordinat ($lat, $lng) Türkiye dışında kalıyor. Enlem yaklaşık '
                '36–42, boylam 26–45 arasında olmalı. Enlem/boylam yer değiştirmiş '
                'ya da yanlış girilmiş olabilir.',
        blocking: true,
      );
    }
    final TrMetro? city = TrMetroAreas.fromAddress(address);
    if (city != null) {
      final double d = _km(lat, lng, city.lat, city.lng);
      if (d > city.hardRadiusKm * 1.5) {
        return (
          message:
              'Adres "${city.name}" diyor ama koordinat şehir merkezine ${d.round()} km uzakta. '
                  'Konumu kontrol et.',
          blocking: false,
        );
      }
    }
    return null;
  }
}

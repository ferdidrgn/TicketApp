import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Cihaz konumunu güvenli/toleranslı şekilde okur. İzin verilmemişse,
/// konum servisleri kapalıysa veya herhangi bir hata oluşursa (web'de
/// bazı tarayıcılarda olduğu gibi) sessizce `null` döner — çağıran taraf
/// bunu "konum yok, şehre göre öner" sinyali olarak kullanır.
abstract final class LocationService {
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('LocationService: konum alınamadı: $e');
      return null;
    }
  }

  /// Sadece mevcut izin durumunu kontrol eder, İSTEMEZ (izin diyaloğu açmaz).
  static Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// İki koordinat arasındaki mesafeyi metre cinsinden döner.
  static double distanceInMeters(
    final double lat1,
    final double lon1,
    final double lat2,
    final double lon2,
  ) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
}

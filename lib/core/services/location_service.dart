import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// ==============================================================================
// GERÇEK CİHAZ KONUMU — "Yakınımdakiler"
// ==============================================================================
//
// Android emülatör notu (geolocator #632 / #1082): LocationAccuracy.low/medium
// hücresel üçgenlemeye düşer; emülatörde hücre yok → getCurrentPosition
// SÜRESİZ asılı kalır ("Konumun alınıyor"). GPS emülasyonu için high/best
// gerekir; Extended Controls → Location → Set location (Kadıköy) sonrası
// getLastKnownPosition genelde hemen dolu gelir.

/// Konum alınamadığında fırlatılan taban hata sınıfı.
sealed class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);

  @override
  String toString() => message;
}

class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure()
      : super(
            'Konum servisleri kapalı. Yakınınızdaki etkinlikleri görebilmek için cihaz ayarlarından konumu açmanız gerekiyor.');
}

class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure()
      : super(
            'Yakınınızdaki etkinlikleri gösterebilmemiz için konum izni vermeniz gerekiyor.');
}

class LocationPermissionDeniedForeverFailure extends LocationFailure {
  const LocationPermissionDeniedForeverFailure()
      : super(
            'Konum izni kalıcı olarak reddedilmiş görünüyor. Lütfen uygulama ayarlarından TiyatRol için konum iznini açın.');
}

class LocationTimeoutFailure extends LocationFailure {
  const LocationTimeoutFailure()
      : super(
            'Konumunuz alınamadı. Konum servislerinin açık olduğundan emin olup tekrar dene.');
}

abstract final class LocationService {
  /// Cihazın GERÇEK anlık konumu. Emülatörde high accuracy + lastKnown.
  static Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServiceDisabledFailure();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedFailure();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverFailure();
    }

    // Emülatörde Set location → lastKnown çoğu zaman hemen dolu.
    final Position? last = await Geolocator.getLastKnownPosition();

    try {
      final Position fresh = await Geolocator.getCurrentPosition(
        locationSettings: _settings(timeLimit: const Duration(seconds: 8)),
      );
      return fresh;
    } on TimeoutException {
      if (last != null) {
        debugPrint('LocationService: timeout → lastKnown kullanıldı');
        return last;
      }
      throw const LocationTimeoutFailure();
    } on LocationFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('LocationService: $e\n$st');
      if (last != null) return last;
      throw const LocationTimeoutFailure();
    }
  }

  static LocationSettings _settings({required final Duration timeLimit}) {
    // high = GPS (emülatör destekler). medium/low hücre ister → asılı kalır.
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
        // Emülatörde FusedLocation bazen takılır; LocationManager daha tutarlı.
        forceLocationManager: true,
      );
    }
    if (!kIsWeb && Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
        activityType: ActivityType.other,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: timeLimit,
    );
  }

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static double distanceInMeters(
    final double startLatitude,
    final double startLongitude,
    final double endLatitude,
    final double endLongitude,
  ) =>
      Geolocator.distanceBetween(
          startLatitude, startLongitude, endLatitude, endLongitude);
}

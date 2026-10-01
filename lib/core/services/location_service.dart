import 'dart:async';

import 'package:geolocator/geolocator.dart';

// ==============================================================================
// GERÇEK CİHAZ KONUMU — "Yakınımdakiler" özelliğinin temel taşı
// ==============================================================================
//
// Kullanıcının kendi talebi: "yakınınızdaki etkinlikler dediğimde konum
// sormamız gerekiyor". Bu servis `geolocator` paketiyle GERÇEK izin akışını
// (iste/kontrol et) ve GERÇEK GPS koordinatını yönetir. Hiçbir adımda sahte/
// varsayılan bir konum ÜRETMEZ — izin reddedilirse ya da konum servisi
// kapalıysa ilgili [LocationFailure] alt sınıfı fırlatılır; çağıran taraf
// (bkz. `../../features/discovery/presentation/pages/nearby_events_page.dart`)
// bunu yakalayıp gerçek bir izin isteme/ayarlara yönlendirme UI'ı gösterir.

/// Konum alınamadığında fırlatılan taban hata sınıfı. Kullanıcıya
/// gösterilecek gerçek, anlaşılır Türkçe mesajı taşır.
sealed class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);

  @override
  String toString() => message;
}

/// Cihazın konum servisi (GPS/konum ayarı) tamamen kapalı.
class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure()
      : super(
            'Konum servisleri kapalı. Yakınınızdaki etkinlikleri görebilmek için cihaz ayarlarından konumu açmanız gerekiyor.');
}

/// Kullanıcı izin isteğini bu oturumda reddetti — tekrar sorulabilir.
class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure()
      : super(
            'Yakınınızdaki etkinlikleri gösterebilmemiz için konum izni vermeniz gerekiyor.');
}

/// Kullanıcı izni kalıcı olarak reddetti — sistem artık tekrar sormuyor,
/// uygulama ayarlarına yönlendirilmesi gerekiyor.
class LocationPermissionDeniedForeverFailure extends LocationFailure {
  const LocationPermissionDeniedForeverFailure()
      : super(
            'Konum izni kalıcı olarak reddedilmiş görünüyor. Lütfen uygulama ayarlarından TiyatRol için konum iznini açın.');
}

/// GERÇEK KÖK SEBEP (bkz. mobilde "sürekli loading dönüyor" raporu): izin
/// verilmiş/GPS açık olsa bile `Geolocator.getCurrentPosition()`'ın bir
/// `timeLimit` YOKSA, cihaz kapalı alanda/zayıf sinyaldeyken istenen
/// doğrulukta (`LocationAccuracy.medium`) bir konum güncellemesi hiç
/// gelmeyebilir — `Future` SONSUZA KADAR tamamlanmaz, `devicePositionProvider`
/// (`FutureProvider`) `AsyncValue.loading` durumunda asılı kalır ve UI
/// süresiz dönen bir `CircularProgressIndicator` gösterir. Aşağıda
/// `getCurrentPosition` artık gerçek bir `timeLimit` veriyor ve bu durumda
/// fırlayan `TimeoutException`'ı bu somut, kullanıcıya gösterilecek gerçek
/// mesajla birlikte bu tipe çeviriyor — sahte bir konum ÜRETİLMİYOR, sadece
/// sonsuz bekleme gerçek bir hata+"Tekrar Dene" durumuna dönüştürülüyor.
class LocationTimeoutFailure extends LocationFailure {
  const LocationTimeoutFailure()
      : super(
            'Konumunuz alınamadı (GPS sinyali zayıf ya da yok). Açık bir alanda tekrar deneyin ya da bağlantınızı kontrol edip yeniden deneyin.');
}

/// `Geolocator`'ın etrafına ince bir sarmalayıcı. Statik metodlar dışa
/// kalan tek yüzey — servis durumu tutmuyor, her çağrı GERÇEK zamanlı
/// kontrol/istek yapıyor.
abstract final class LocationService {
  /// Cihazın GERÇEK anlık konumunu döner. Sırasıyla: konum servisi açık mı
  /// -> izin var mı (yoksa GERÇEKTEN ister) -> koordinatı oku. Hiçbir
  /// adımda varsayılan/sahte bir [Position] üretilmez; sorun varsa ilgili
  /// [LocationFailure] fırlatılır.
  static Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServiceDisabledFailure();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Gerçek sistem izin diyaloğu — `Geolocator.requestPermission()`.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw const LocationPermissionDeniedFailure();
    }

    if (permission == LocationPermission.deniedForever)
      throw const LocationPermissionDeniedForeverFailure();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          // KÖK SEBEP DÜZELTMESİ: `timeLimit` verilmezse bu çağrı, istenen
          // doğrulukta bir GPS güncellemesi gelene kadar SÜRESİZ bekler —
          // kapalı alanda/zayıf sinyalde bu hiç gelmeyebilir ve mobilde
          // "sürekli loading dönüyor" şikayetine yol açan asıl `Future`
          // budur. 20 saniye, gerçek bir konum düzeltmesi için makul ama
          // kullanıcıyı süresiz beklemeye bırakmayan bir üst sınır.
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const LocationTimeoutFailure();
    }
  }

  /// Kullanıcıyı uygulamanın sistem ayarlarına (konum izni sayfası) yönlendirir
  /// — `deniedForever` durumunda tek gerçek çözüm bu, uygulama içinden tekrar
  /// izin istenemez.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Kullanıcıyı cihazın konum servisleri (GPS açık/kapalı) ayarına yönlendirir.
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  /// İki GERÇEK koordinat arasındaki büyük daire (Haversine) mesafesini
  /// METRE cinsinden döner — `Geolocator.distanceBetween` sarmalayıcısı.
  static double distanceInMeters(
    final double startLatitude,
    final double startLongitude,
    final double endLatitude,
    final double endLongitude,
  ) =>
      Geolocator.distanceBetween(
          startLatitude, startLongitude, endLatitude, endLongitude);
}

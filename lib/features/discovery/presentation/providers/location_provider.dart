import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';

// ==============================================================================
// GERÇEK CİHAZ KONUMU PROVIDER'I
// ==============================================================================
//
// `nearby_events_provider.dart`daki diğer klasik (codegen'siz) provider'larla
// AYNI sebepten `@riverpod` KULLANMIYOR: bu sandbox'ta `build_runner`
// çalıştırılamıyor, bu yüzden `FutureProvider` (flutter_riverpod) tercih
// edildi — ek kod üretimi gerektirmeden derlenir.
//
// `LocationService.getCurrentPosition()` GERÇEK izin akışını yürütür; izin
// reddedilir/konum kapalıysa bu future ilgili `LocationFailure`'ı OLDUĞU
// GİBİ fırlatır (yutmaz) — `nearby_events_page.dart` bunu `AsyncValue.error`
// dalında yakalayıp gerçek bir izin isteme/ayarlara yönlendirme ekranı
// gösteriyor. Sahte bir varsayılan koordinat asla üretilmiyor.

/// Cihazın GERÇEK anlık konumu. `ref.invalidate(devicePositionProvider)`
/// ile (ör. kullanıcı "Tekrar Dene" butonuna bastığında) yeniden
/// tetiklenir — her seferinde izin/GPS durumu baştan, gerçek zamanlı
/// kontrol edilir.
final devicePositionProvider = FutureProvider<Position>((final ref) async {
  return LocationService.getCurrentPosition();
});

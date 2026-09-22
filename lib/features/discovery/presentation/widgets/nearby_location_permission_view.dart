import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/location_provider.dart';

/// "Yakınımdakiler" için GERÇEK konum izni/servis isteme ekranı.
///
/// Sahte bir "izin verilmiş gibi davran" YOK: konum alınamadığı sürece bu
/// widget ekranda kalır, hiçbir uydurma etkinlik/mesafe gösterilmez.
/// `error`'ın somut [LocationFailure] alt tipine göre GERÇEK, doğru
/// aksiyonu sunar:
///   - [LocationServiceDisabledFailure] -> cihazın konum servisi ayarını aç
///   - [LocationPermissionDeniedForeverFailure] -> uygulama ayarlarını aç
///     (sistem artık uygulama içinden tekrar sormuyor)
///   - diğerleri (ör. ilk reddetme) -> `Geolocator.requestPermission()`'ı
///     tekrar tetikleyen gerçek sistem izin diyaloğu
class NearbyLocationPermissionView extends ConsumerWidget {
  final Object error;
  final Color foregroundColor;
  final Color mutedColor;
  final Color accentColor;
  final Color onAccentColor;

  const NearbyLocationPermissionView({
    super.key,
    required this.error,
    required this.foregroundColor,
    required this.mutedColor,
    required this.accentColor,
    this.onAccentColor = Colors.white,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final Object failure = error;
    final String message = failure is LocationFailure
        ? failure.message
        : 'Konumunuz alınamadı. Lütfen tekrar deneyin.';

    final bool isDeniedForever =
        failure is LocationPermissionDeniedForeverFailure;
    final bool isServiceDisabled = failure is LocationServiceDisabledFailure;

    final String actionLabel = isDeniedForever
        ? 'Uygulama Ayarlarını Aç'
        : isServiceDisabled
            ? 'Konum Ayarlarını Aç'
            : 'Konum İzni Ver';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 44, color: accentColor),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Konumunuza İhtiyacımız Var',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            button: true,
            label: actionLabel,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: onAccentColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: () async {
                // Sahte bir "izin verildi" varsayımı yok: gerçek sistem
                // ayarına/diyaloğuna yönlendirip ardından provider'ı
                // yeniden tetikliyoruz — sonucu GERÇEK, güncel izin/GPS
                // durumu belirliyor.
                if (isDeniedForever) {
                  await LocationService.openAppSettings();
                } else if (isServiceDisabled) {
                  await LocationService.openLocationSettings();
                }
                ref.invalidate(devicePositionProvider);
              },
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

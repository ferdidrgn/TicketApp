import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/listing.dart';
import '../providers/location_provider.dart';

/// "Yakınımdakiler" için GERÇEK konum izni/servis isteme ekranı.
///
/// Sahte bir "izin verilmiş gibi davran" YOK: konum alınamadığı sürece bu
/// widget ekranda kalır, hiçbir uydurma etkinlik/mesafe gösterilmez.
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
    final bool isTimeout = failure is LocationTimeoutFailure;

    final String title = isTimeout
        ? 'Konum alınamadı'
        : isServiceDisabled
            ? 'Konum servisi kapalı'
            : isDeniedForever
                ? 'Konum izni gerekli'
                : 'Konumuna ihtiyacımız var';

    final String actionLabel = isDeniedForever
        ? 'Uygulama ayarlarını aç'
        : isServiceDisabled
            ? 'Konum ayarlarını aç'
            : isTimeout
                ? 'Tekrar dene'
                : 'Konum izni ver';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTimeout
                    ? Icons.gps_not_fixed_rounded
                    : Icons.location_off_rounded,
                size: 28,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: listingUi(
              color: foregroundColor,
              size: 22,
              weight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: listingUi(
              color: mutedColor,
              size: 14,
              weight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            button: true,
            label: actionLabel,
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: onAccentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () async {
                  await HapticFeedback.mediumImpact();
                  if (isDeniedForever) {
                    await LocationService.openAppSettings();
                  } else if (isServiceDisabled) {
                    await LocationService.openLocationSettings();
                  }
                  ref.invalidate(devicePositionProvider);
                },
                icon: Icon(
                  isTimeout
                      ? Icons.refresh_rounded
                      : Icons.my_location_rounded,
                  size: 20,
                ),
                label: Text(
                  actionLabel,
                  style: listingUi(
                    color: onAccentColor,
                    size: 15,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

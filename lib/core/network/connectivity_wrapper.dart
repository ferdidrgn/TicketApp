import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/extentions/app_context_ui_extension.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'connectivity_provider.dart';

/// Bağlantı durumunu izler ama uygulamayı ASLA tam ekran bir "offline"
/// sayfasıyla değiştirmez.
///
/// Eskiden burada `!isOnline` olduğunda `child` tamamen atılıp yerine
/// ayrı, kendi başına bir `MaterialApp` içeren `_OfflineScreen` render
/// ediliyordu. Bu, `AppInitializer` içinde artık açılan Firestore offline
/// persistence'ını (bkz. `_configureFirestorePersistence`) fiilen işe
/// yaramaz hale getiriyordu: cache'te daha önce indirilmiş veri olsa bile
/// kullanıcı bağlantı kesildiği an hiçbir ekranı GÖREMİYORDU, çünkü tüm
/// widget ağacı sökülüp atılıyordu.
///
/// Şimdi: `child` (router/sayfa ağacı — ve onun içindeki, Firestore
/// SDK'sının cache'inden beslenen `StreamBuilder`/`FutureBuilder`'lar) her
/// zaman ekranda ve etkileşimli kalıyor; bağlantı koptuğunda sadece üstte,
/// gerçek `connectivity_plus` stream'ine (`connectivityProvider`) bağlı,
/// küçük ve kalıcı olmayan bir bildirim şeridi beliriyor.
class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _OfflineBanner(visible: !isOnline),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool visible;

  const _OfflineBanner({required this.visible});

  @override
  Widget build(final BuildContext context) => SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            offset: visible ? Offset.zero : const Offset(0, -1.3),
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              curve: AppMotion.symmetric,
              opacity: visible ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Semantics(
                  liveRegion: true,
                  label:
                      'Çevrimdışısın. En son görülen veriler gösteriliyor.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: AppShadows.level3(context.colors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: context.colors.onError,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Çevrimdışısın. En son görülen veriler '
                            'gösteriliyor.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

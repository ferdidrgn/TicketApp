import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/users/presentation/providers/user_provider.dart';
import 'admin_test_entry.dart';

class AdminGuard extends ConsumerWidget {
  final Widget child;

  /// Sadece test derlemelerinde ([AdminTestAccess.enabled]: `flutter run`)
  /// yetkisiz/girişsiz kullanıcıyı da içeri alır ve üstte "TEST MODU"
  /// şeridi gösterir — admin arayüzünü giriş/rol ayarlamadan test
  /// edebilmek için. Release derlemesinde hiçbir etkisi yok. Bu bir
  /// güvenlik açığı değil: tüm yazma işlemleri Firestore `isAdmin()`
  /// kuralı tarafından sunucuda reddedilir.
  final bool allowDebugBypass;

  const AdminGuard({
    super.key,
    required this.child,
    this.allowDebugBypass = false,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool debugBypass = AdminTestAccess.enabled && allowDebugBypass;

    // 1. Profil verisini izle
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (final err, final stack) => debugBypass
          ? _TestModeFrame(reason: 'Kullanıcı verisi alınamadı', child: child)
          : _buildErrorState(context, "HATA", "Kullanıcı verisi alınamadı.",
              Icons.error_outline),
      data: (final user) {
        // 2. Oturum kontrolü
        if (user == null) {
          return debugBypass
              ? _TestModeFrame(reason: 'Giriş yapılmadı', child: child)
              : _buildErrorState(context, "OTURUM GEREKLİ",
                  "Lütfen giriş yapın.", Icons.lock_outline);
        }

        // 3. Yetki kontrolü (user_provider içindeki isUserPrivilegedProvider)
        final isPrivileged = ref.watch(isUserPrivilegedProvider);
        if (!isPrivileged) {
          return debugBypass
              ? _TestModeFrame(
                  reason: 'Hesabının rolü admin/küratör değil', child: child)
              : _buildErrorState(context, "YETKİSİZ ERİŞİM",
                  "Sadece Admin veya Küratörler erişebilir.",
                  Icons.gavel_rounded);
        }

        return child;
      },
    );
  }

  Widget _buildErrorState(final BuildContext context, final String title,
          final String msg, final IconData icon) =>
      Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("GERİ DÖN"),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Debug bypass ile açılan sayfanın üstündeki uyarı şeridi — neden test
/// modunda olunduğunu ve kaydetme işlemlerinin neden reddedileceğini söyler.
class _TestModeFrame extends StatelessWidget {
  final String reason;
  final Widget child;

  const _TestModeFrame({required this.reason, required this.child});

  @override
  Widget build(final BuildContext context) => Column(
        children: [
          Material(
            color: WebColors.warning,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined,
                        color: WebColors.veryDarkBlue, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'TEST MODU — $reason. Listeler görüntülenir; '
                        'kaydet/sil işlemlerini sunucu reddeder. Tam yetki '
                        'için giriş yap ve Firestore\'da User/{uid} '
                        'belgesine role: "admin" ekle.',
                        style: const TextStyle(
                          color: WebColors.veryDarkBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      );
}

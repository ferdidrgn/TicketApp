import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/users/presentation/providers/user_provider.dart'
    hide isUserPrivilegedProvider;

class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Profil verisini izle
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (final err, final stack) => _buildErrorState(
          context, "HATA", "Kullanıcı verisi alınamadı.", Icons.error_outline),
      data: (final user) {
        // 2. Oturum kontrolü
        if (user == null)
          return _buildErrorState(context, "OTURUM GEREKLİ",
              "Lütfen giriş yapın.", Icons.lock_outline);

        // 3. Yetki kontrolü (user_provider içindeki isUserPrivilegedProvider)
        final isPrivileged = ref.watch(isUserPrivilegedProvider);
        if (!isPrivileged)
          return _buildErrorState(context, "YETKİSİZ ERİŞİM",
              "Sadece Admin veya Küratörler erişebilir.", Icons.gavel_rounded);

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

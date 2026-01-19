import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import '../../core/common/enum/enums.dart';
import 'background/shimmer_components.dart';

class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    // 1. Yüklenme durumu
    if (loginState.isLoading)
      return const Scaffold(body: Center(child: ShimmerLoading()));

    // 2. Oturum açık mı kontrolü
    if (!loginState.isLoggedIn)
      return _buildErrorState(
        context,
        "OTURUM GEREKLİ",
        "Bu alana erişmek için küratör hesabı ile giriş yapmalısınız.",
        Icons.lock_outline_rounded,
      );

    // 3. Rol kontrolü (Enum kullanarak)
    if (loginState.userRole != UserRole.curator ||
        loginState.userRole != UserRole.admin) {
      return _buildErrorState(
        context,
        "YETKİSİZ ERİŞİM",
        "Bu operasyonel panel sadece sistem yöneticilerine özeldir.",
        Icons.gavel_rounded,
      );
    }

    // Her şey tamamsa sayfayı göster
    return child;
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

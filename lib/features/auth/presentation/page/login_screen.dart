import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final theme = Theme.of(context);

    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      if (next.hasError) {
        _showSnackBar(context, next.errorMessage!, isError: true);
        Future.microtask(() => ref.read(loginProvider.notifier).clearError());
      }
      if (next.isLoggedIn && next.loginMethod == 'google') {
        if (context.mounted) context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Arka Plan Resmi (Opacity artırıldı, resim daha net)
          Positioned.fill(
            child: Image.asset(
              'assets/images/book_logo.jpg',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.8), // %80 görünürlük
            ),
          ),

          // 2. Hafif Gradyan Karartma (Sadece yazılar okunsun diye, resmi tamamen kapatmaz)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // 3. Login Formu (Blur azaltıldı: sigma 15 -> 5)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    // Blur azaltıldı, arkası daha net
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        // Daha şeffaf siyah
                        borderRadius: BorderRadius.circular(32),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Parlayan Hero Icon
                          _buildHeroIcon(theme),
                          const SizedBox(height: 32),

                          const Text(
                            'SANATIN DÜNYASI',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 10)
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          if (loginState.isLoading)
                            const CircularProgressIndicator(color: Colors.white)
                          else ...[
                            // GOOGLE GRADIENT
                            _buildGradientButton(
                              text: 'GOOGLE İLE BAĞLAN',
                              icon: Icons.g_mobiledata_rounded,
                              colors: [
                                const Color(0xFF4285F4),
                                const Color(0xFF34A853)
                              ],
                              onTap: () => _handleGoogleSignIn(context, ref),
                            ),
                            const SizedBox(height: 20),

                            // PHONE GRADIENT
                            _buildGradientButton(
                              text: 'TELEFON İLE DEVAM ET',
                              icon: Icons.phone_iphone_rounded,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary
                              ],
                              onTap: () => context.push('/phone-login'),
                            ),
                          ],

                          const SizedBox(height: 40),
                          const Text(
                            '• KOLEKSİYONA HOŞ GELDİNİZ •',
                            style: TextStyle(
                                color: Colors.white70,
                                letterSpacing: 2,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(final ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.2),
          // İkonun arkasını hafif karart ki belirgin olsun
          border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5)
          ]),
      child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
    );
  }

  Widget _buildGradientButton({
    required final String text,
    required final IconData icon,
    required final List<Color> colors,
    required final VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // --- Atladığın metodlar varsa buraya ekleyebilirsin ---
  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async {
    final success = await ref.read(loginProvider.notifier).signInWithGoogle();
    if (!success && context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Giriş başarısız.')));
  }

  void _showSnackBar(final BuildContext context, final String msg,
          {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green));
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../providers/login_provider.dart';
import '../providers/login_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    // State dinleyici: Hata mesajları ve yönlendirme
    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      if (next.hasError) {
        _showSnackBar(context, next.errorMessage!, isError: true);
        Future.microtask(() => ref.read(loginProvider.notifier).clearError());
      }

      // Başarılı Google girişi sonrası profil tamamlamaya yönlendir
      if (next.isLoggedIn && next.loginMethod == 'google') {
        if (context.mounted) context.go('/profile-edit/${next.userId}');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Arka Plan Resmi
          _buildBackgroundImage(),

          // 2. Karartma Katmanı
          Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4))),

          // 3. Login İçeriği
          _buildArtisticLoginForm(context, ref, loginState.isLoading),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/book_logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (final ctx, final err, final stack) =>
            Container(color: Colors.grey[900]),
      ),
    );
  }

  Widget _buildArtisticLoginForm(
      final BuildContext context, final WidgetRef ref, final bool isLoading) {
    return SafeArea(
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (final context, final value, final child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Başlık Bölümü
                      const Icon(Icons.palette_outlined,
                          size: 48, color: Colors.white70),
                      const SizedBox(height: 24),
                      const Text(
                        'Sanat Yolculuğu\nBurada Başlar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Deneyiminizi kişiselleştirmek için\ngiriş yapın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Giriş Butonları
                      if (isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else ...[
                        _buildSocialButton(
                          text: 'Google ile Bağlan',
                          icon: Icons.g_mobiledata,
                          onPressed: () => _handleGoogleSignIn(context, ref),
                          color: Colors.white,
                          textColor: Colors.black87,
                        ),
                        const SizedBox(height: 16),
                        _buildSocialButton(
                          text: 'Telefon ile Devam Et',
                          icon: Icons.phone_iphone_rounded,
                          onPressed: () => context.push('/phone-login'),
                          color: Colors.white.withOpacity(0.15),
                          textColor: Colors.white,
                          isBordered: true,
                        ),
                      ],

                      const SizedBox(height: 32),
                      // Alt Bilgi
                      Text(
                        'Devam ederek kullanım koşullarını\nkabul etmiş sayılırsınız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white30, fontSize: 10),
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

  Widget _buildSocialButton({
    required final String text,
    required final IconData icon,
    required final VoidCallback onPressed,
    required final Color color,
    required final Color textColor,
    final bool isBordered = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isBordered
                ? BorderSide(color: Colors.white.withOpacity(0.3))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async {
    final success = await ref.read(loginProvider.notifier).signInWithGoogle();
    if (!success && context.mounted) {
      _showSnackBar(context, 'Google girişi başarısız oldu.', isError: true);
    }
  }

  void _showSnackBar(final BuildContext context, final String message,
      {final bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../providers/login_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    // İşlem devam ediyorsa loading göster
    if (loginState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildLoginForm(context, ref),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() => Positioned.fill(
        child: Image.asset(
          'assets/images/book_logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (final ctx, final err, final stack) =>
              Container(color: Colors.grey[900]),
        ),
      );

  Widget _buildLoginForm(final BuildContext context, final WidgetRef ref) =>
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sanata Doymaya Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // GOOGLE SIGN IN
                CustomElevatedButton(
                  text: 'Google ile Giriş Yap',
                  iconData: Icons.g_mobiledata,
                  onPressed: () => _handleGoogleSignIn(context, ref),
                ),
                const SizedBox(height: 16),

                // PHONE LOGIN
                CustomElevatedButton(
                  text: 'Telefon ile Giriş Yap',
                  iconData: Icons.phone_iphone_rounded,
                  onPressed: () => context.push('/phone-login'),
                ),
                const SizedBox(height: 16),

                // GUEST LOGIN
                CustomElevatedButton(
                  text: 'Misafir Girişi',
                  iconData: Icons.person_outline_rounded,
                  onPressed: () => _handleGuestLogin(context, ref),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async {
    try {
      await ref.read(loginProvider.notifier).signInWithGoogle();

      // Not: Başarılı olursa Router 'refreshListenable' sayesinde tetiklenir.
      // Ancak özel yönlendirme (Profil Edit) istiyorsak manuel müdahale gerekebilir.
      // Firestore kaydı zaten Notifier içinde yapıldı.

      final currentState = ref.read(loginProvider);
      if (currentState.user != null) {
        if (context.mounted) {
          // GoRouter redirect yapmadan önce biz araya girip profile yolluyoruz
          context.go('/profile-edit/${currentState.user!.uid}');
        }
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Hata: $e', isError: true);
    }
  }

  Future<void> _handleGuestLogin(
      final BuildContext context, final WidgetRef ref) async {
    try {
      await ref.read(loginProvider.notifier).signInAnonymously();
      // Misafirler Router redirect ile otomatik /home'a gidecek.
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Hata: $e', isError: true);
    }
  }

  void _showSnack(final BuildContext context, final String msg,
          {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: isError ? Colors.red : Colors.green),
      );
}

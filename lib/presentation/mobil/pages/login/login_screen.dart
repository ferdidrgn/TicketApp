import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/login/phone_login_page.dart';
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../data/providers/login/login_provider.dart';
import '../profile_edit/user_profile_edit.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    if (loginState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _buildContent(context, ref),
    );
  }

  Widget _buildContent(final BuildContext context, final WidgetRef ref) {
    return Stack(
      children: [
        _buildBackgroundImage(),
        _buildLoginForm(context, ref),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/book_logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (final context, final error, final stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 100, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(final BuildContext context, final WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWelcomeText(),
              const SizedBox(height: 20),
              _buildGoogleSignInButton(context, ref),
              const SizedBox(height: 20),
              _buildPhoneLoginButton(context),
              const SizedBox(height: 20),
              _buildGuestLoginButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Text(
      'Sanata Doymaya Hoş Geldiniz',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGoogleSignInButton(
      final BuildContext context, final WidgetRef ref) {
    return CustomElevatedButton(
      text: 'Google ile Giriş Yap',
      iconData: Icons.g_mobiledata,
      onPressed: () => _handleGoogleSignIn(context, ref),
    );
  }

  Widget _buildPhoneLoginButton(final BuildContext context) {
    return CustomElevatedButton(
      text: 'Telefon ile Giriş Yap',
      iconData: Icons.phone,
      onPressed: () => _navigateToPhoneLogin(context),
    );
  }

  Widget _buildGuestLoginButton(
      final BuildContext context, final WidgetRef ref) {
    return CustomElevatedButton(
      text: 'Misafir Olarak Devam Et',
      iconData: Icons.person_outline,
      onPressed: () => _handleGuestLogin(context, ref),
    );
  }

  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async {
    try {
      await ref.read(loginProvider.notifier).signInWithGoogle();
      final loginState = ref.read(loginProvider);

      if (!context.mounted) return;

      if (loginState.user != null)
        _navigateAfterLogin(
            context, 'Google ile giriş başarılı', loginState.user!.uid);
      else
        _showErrorSnackbar(context, 'Google ile giriş başarısız');
    } catch (e) {
      if (context.mounted)
        _showErrorSnackbar(context, 'Google ile giriş sırasında hata: $e');
    }
  }

  void _navigateToPhoneLogin(final BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (final context) => const PhoneLogInPage()),
    );
  }

  Future<void> _handleGuestLogin(
      final BuildContext context, final WidgetRef ref) async {
    try {
      await ref.read(loginProvider.notifier).signInAnonymously();
      final loginState = ref.read(loginProvider);

      if (!context.mounted) return;

      if (loginState.user != null)
        _navigateAfterLogin(
            context, 'Google ile giriş başarılı', loginState.user!.uid);
      else
        _showErrorSnackbar(context, 'Misafir girişi başarısız');
    } catch (e) {
      if (context.mounted)
        _showErrorSnackbar(context, 'Misafir girişi sırasında hata: $e');
    }
  }

  void _navigateAfterLogin(
      final BuildContext context, final String message, final String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (final context) => UserProfileEditScreen(userId: userId),
      ),
    );
  }

  void _showErrorSnackbar(final BuildContext context, final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

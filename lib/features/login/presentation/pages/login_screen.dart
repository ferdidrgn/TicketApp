import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/login/presentation/pages/phone_login_page.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';
import '../../../users/presentation/pages/user_profile_edit.dart';
import '../providers/login_provider.dart';
import '../providers/login_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final isProcessing = ref.watch(loginProcessingProvider);

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _checkAndNavigate(loginState, context);
    });

    if (loginState.isLoading || isProcessing)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(body: _buildContent(context, ref, isProcessing));
  }

  void _checkAndNavigate(
      final LoginState loginState, final BuildContext context) {
    if (loginState.user != null &&
        !loginState.isPersisted &&
        !loginState.isLoading) {
      print('🔄 LOGIN: Yeni kullanıcı tespit edildi, yönlendiriliyor...');
      _navigateAfterLogin(context, 'Giriş başarılı', loginState.user!.uid);
    }
  }

  Widget _buildContent(final BuildContext context, final WidgetRef ref,
          final bool isProcessing) =>
      Stack(
        children: [
          _buildBackgroundImage(),
          _buildLoginForm(context, ref, isProcessing)
        ],
      );

  Widget _buildBackgroundImage() => Positioned.fill(
        child: Image.asset(
          'assets/images/book_logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (final context, final error, final stackTrace) {
            return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 100, color: Colors.grey));
          },
        ),
      );

  Widget _buildLoginForm(final BuildContext context, final WidgetRef ref,
          final bool isProcessing) =>
      Center(
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
                _buildGoogleSignInButton(context, ref, isProcessing),
                const SizedBox(height: 20),
                _buildPhoneLoginButton(context, isProcessing),
                const SizedBox(height: 20),
                _buildGuestLoginButton(context, ref, isProcessing),
              ],
            ),
          ),
        ),
      );

  Widget _buildWelcomeText() => const Text(
        'Sanata Doymaya Hoş Geldiniz',
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      );

  Widget _buildGoogleSignInButton(final BuildContext context,
          final WidgetRef ref, final bool isProcessing) =>
      CustomElevatedButton(
          text: 'Google ile Giriş Yap',
          iconData: Icons.g_mobiledata,
          onPressed: () => _handleGoogleSignIn(context, ref));

  Widget _buildPhoneLoginButton(
          final BuildContext context, final bool isProcessing) =>
      CustomElevatedButton(
          text: 'Telefon ile Giriş Yap',
          iconData: Icons.phone,
          onPressed: () => _navigateToPhoneLogin(context));

  Widget _buildGuestLoginButton(final BuildContext context, final WidgetRef ref,
          final bool isProcessing) =>
      CustomElevatedButton(
          text: 'Misafir Girişi',
          iconData: Icons.person_outline,
          onPressed: () => _handleGuestLogin(context, ref));

  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async {
    ref.read(loginProcessingProvider.notifier).state = true;

    try {
      await ref.read(loginProvider.notifier).signInWithGoogle();

      // State değişikliğini bekle
      await Future.delayed(const Duration(milliseconds: 500));

      final loginState = ref.read(loginProvider);

      if (!context.mounted) return;

      if (loginState.user != null)
        _navigateAfterLogin(
            context, 'Google ile giriş başarılı', loginState.user!.uid);
      else
        _showErrorSnackbar(
            context, loginState.errorMessage ?? 'Google ile giriş başarısız');
    } catch (e) {
      if (context.mounted)
        _showErrorSnackbar(context, 'Google ile giriş sırasında hata: $e');
    } finally {
      if (context.mounted)
        ref.read(loginProcessingProvider.notifier).state = false;
    }
  }

  void _navigateToPhoneLogin(final BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (final context) => const PhoneLogInPage()));

  Future<void> _handleGuestLogin(
      final BuildContext context, final WidgetRef ref) async {
    ref.read(loginProcessingProvider.notifier).state = true;

    try {
      await ref.read(loginProvider.notifier).signInAnonymously();

      // State değişikliğini bekle
      await Future.delayed(const Duration(milliseconds: 500));

      final loginState = ref.read(loginProvider);

      if (!context.mounted) return;

      if (loginState.user != null)
        _navigateAfterLogin(
            context, 'Misafir girişi başarılı', loginState.user!.uid);
      else
        _showErrorSnackbar(
            context, loginState.errorMessage ?? 'Misafir girişi başarısız');
    } catch (e) {
      if (context.mounted)
        _showErrorSnackbar(context, 'Misafir girişi sırasında hata: $e');
    } finally {
      if (context.mounted)
        ref.read(loginProcessingProvider.notifier).state = false;
    }
  }

  void _navigateAfterLogin(
      final BuildContext context, final String message, final String userId) {
    // Snackbar göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2)),
    );

    // Navigasyon işlemi
    WidgetsBinding.instance.addPostFrameCallback((final _) =>
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    UserProfileEditScreen(userId: userId))));
  }

  void _showErrorSnackbar(final BuildContext context, final String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3)),
      );
}

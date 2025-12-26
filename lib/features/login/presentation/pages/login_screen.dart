import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../providers/login_provider.dart';
import '../providers/login_state.dart';

/// 🔐 Login Screen with Clean State Management
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    // Listen to state changes
    ref.listen<LoginState>(loginProvider, (previous, next) {
      // Show error if any
      if (next.hasError) {
        _showSnackBar(
          context,
          next.errorMessage!,
          isError: true,
        );
        // Clear error after showing
        Future.microtask(() => ref.read(loginProvider.notifier).clearError());
      }

      // Navigate to profile edit after Google sign in
      if (next.isLoggedIn &&
          !next.isGuest &&
          previous?.isLoading == true &&
          !next.isLoading) {
        // Only for new users or after Google sign in
        if (next.loginMethod == 'google') {
          Future.microtask(() {
            if (context.mounted) {
              context.go('/profile-edit/${next.userId}');
            }
          });
        }
      }
    });

    if (loginState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/book_logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey[900],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, WidgetRef ref) {
    return Center(
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
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(loginProvider.notifier).signInWithGoogle();

    if (!success && context.mounted) {
      _showSnackBar(context, 'Google girişi başarısız', isError: true);
    }
  }

  Future<void> _handleGuestLogin(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(loginProvider.notifier).signInAnonymously();

    if (!success && context.mounted) {
      _showSnackBar(context, 'Misafir girişi başarısız', isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

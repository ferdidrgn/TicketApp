import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/pages/login/phone_login_page.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../data/providers/login/login_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    return loginState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : loginState.errorMessage != null
            ? _buildErrorState(loginState.errorMessage!)
            : _buildContentState(context, ref);
  }

  Widget _buildErrorState(final String message) {
    return Center(child: Text(message));
  }

  Widget _buildContentState(final BuildContext context, final WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Stack(
        children: [
          _buildBackgroundImage(),
          _buildContent(context, ref),
        ],
      )),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset('assets/images/book_logo.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildContent(final BuildContext context, final WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Sanata Doymaya Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildGoogleSignInButton(context, ref),
                const SizedBox(height: 20),
                _buildPhoneLogIn(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(
      final BuildContext context, final WidgetRef ref) {
    return CustomElevatedButton(
      text: 'Google ile Giriş Yap',
      iconAsset: CachedNetworkImage(
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw09UBmrWncMvaCr60UG1GAWJWuggPlzSlw&s',
        height: 24,
        placeholder: (final context, final url) =>
            const CircularProgressIndicator(),
        errorWidget: (final context, final url, final error) =>
            const Icon(Icons.error),
      ),
      onPressed: () async {
        final loginNotifier = ref.read(loginProvider.notifier);
        await loginNotifier.signInWithGoogle();
        final loginState = ref.read(loginProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loginState.user?.displayName ?? 'Giriş başarısız')),
        );

        if (loginState.user != null) {
          await Navigator.pushReplacementNamed(context, '/home');
        }
      },
    );
  }

  Widget _buildPhoneLogIn(final BuildContext context) {
    return CustomElevatedButton(
      text: 'Tel No İle Giriş Yap',
      iconData: Icons.phone,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (final context) => const PhoneLogInPage()),
        );
      },
    );
  }
}

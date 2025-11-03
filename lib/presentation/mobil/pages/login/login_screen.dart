import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/login/phone_login_page.dart';
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../data/providers/login/login_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(body: _buildBody(loginState, context, ref));
  }

  Widget _buildBody(
      final loginState, final BuildContext context, final WidgetRef ref) {
    if (loginState.isLoading)
      return const Center(child: CircularProgressIndicator());

    return _buildContentState(context, ref);
  }

  Widget _buildContentState(final BuildContext context, final WidgetRef ref) {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            _buildBackgroundImage(),
            _buildContent(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/book_logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (final context, final error, final stackTrace) {
          // Eğer resim bulunamazsa placeholder göster
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 100, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildContent(final BuildContext context, final WidgetRef ref) {
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
              const SizedBox(height: 20),
              _buildGuestLogin(context, ref),
            ],
          ),
        ),
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
        placeholder: (final context, final url) => const ShimmerLoading(),
        errorWidget: (final context, final url, final error) =>
            const Icon(Icons.error, color: Colors.white),
      ),
      onPressed: () async {
        await ref.read(loginProvider.notifier).signInWithGoogle();
        final loginState = ref.read(loginProvider);

        if (!context.mounted) return;

        if (loginState.user != null) {
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Giriş başarılı ${loginState.user?.displayName}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş başarısız')),
          );
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

  Widget _buildGuestLogin(final BuildContext context, final WidgetRef ref) {
    return CustomElevatedButton(
      text: 'Misafir Olarak Devam Et',
      iconData: Icons.person_outline,
      onPressed: () async {
        await ref.read(loginProvider.notifier).signInAnonymously();
        final loginState = ref.read(loginProvider);

        if (!context.mounted) return;

        if (loginState.user != null) {
          await Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Misafir girişi başarılı')),
          );
        } else
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Misafir girişi başarısız')),
          );
      },
    );
  }
}

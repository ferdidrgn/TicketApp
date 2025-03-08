import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/sign_service.dart';
import 'package:ticketapp/presentation/pages/login/phone_page.dart';
import '../../../core/custom_views/custom_elevated_button.dart';

class LoginScreen extends StatelessWidget {
  final LoginService _loginService = LoginService();

  LoginScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [_buildBackgroundImage(), _buildContent(context)],
    ));
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
        child: Image.asset('assets/images/book_logo.jpg', fit: BoxFit.cover));
  }

  Widget _buildContent(final BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            const Text('Sanata Doymaya Hoş Geldiniz',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _buildGoogleSignInButton(context),
            const SizedBox(height: 20),
            _buildPhoneLogIn(context)
          ]))
    ]));
  }

  Widget _buildGoogleSignInButton(final BuildContext context) {
    return CustomElevatedButton(
        text: 'Google ile Giriş Yap',
        iconAsset: Image.network(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw09UBmrWncMvaCr60UG1GAWJWuggPlzSlw&s',
            height: 24),
        onPressed: () async {
          try {
            final account = await _loginService.signInWithGoogle(context);
            if (account != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(account.displayName ?? '')));
              await Navigator.pushReplacementNamed(context, '/home');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Google Girişi Başarısız Oldu.')));
            }
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Girişi Başarısız Oldu.')));
          }
        });
  }

  Widget _buildPhoneLogIn(final context) {
    return CustomElevatedButton(
        text: 'Tel No İle Giriş Yap',
        iconData: Icons.phone,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (final context) => const PhoneLogInPage()),
          );
        });
  }
}

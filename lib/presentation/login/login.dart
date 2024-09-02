import 'package:flutter/material.dart';
import '../../util/custom_views/custom_elevated_button.dart';
import '../../util/google_sign_in_service.dart';

class LoginScreen extends StatelessWidget {
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/art_background.jpg', // Arka plan görselinizin yolu
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(15),
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
                _buildGoogleSignInButton(context),
                const SizedBox(height: 20),
                _buildPhoneLogIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return CustomElevatedButton(
      text: 'Google ile Giriş Yap',
      icon: Icons.abc,
      onPressed: () async {
        try {
          final account = await _googleSignInService.signInWithGoogle();
          if (account != null) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Google Girişi Başarısız Oldu. TEST için girildi.')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $error  TEST için girildi.')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
    );
  }

  Widget _buildPhoneLogIn() {
    return CustomElevatedButton(
      text: 'Tel No İle Giriş Yap',
      icon: Icons.phone,
      onPressed: () async {
        // Telefonla giriş işlemlerini burada gerçekleştirin
      },
    );
  }
}

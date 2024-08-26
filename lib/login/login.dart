import 'package:flutter/material.dart';
import '../util/google_sign_in_service.dart';

class LoginScreen extends StatelessWidget {
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sanata Doymaya Hoş Geldiniz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildGoogleSignInButton(context),
            const SizedBox(height: 20),
            _buildPhoneLogIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text('Google ile Giriş Yap'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
        onPressed: () async {
          try {
            final account = await _googleSignInService.signInWithGoogle();
            if (account != null) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google Girişi Başarısız Oldu. TEST için girildi.')),
              );
              Navigator.pushReplacementNamed(context, '/home');
            }
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: $error  TEST için girildi.')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
    );
  }

  Widget _buildPhoneLogIn() {
    return ElevatedButton.icon(
        icon: const Icon(Icons.phone),
        label: const Text('Tel No İle Giriş Yap'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        onPressed: () async {});
  }
}

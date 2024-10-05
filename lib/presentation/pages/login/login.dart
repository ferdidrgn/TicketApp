import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/presentation/pages/login/phone_page.dart';
import '../../../core/custom_views/custom_elevated_button.dart';
import '../../../core/util/google_sign_in_service.dart';
import '../../../data/model/user.dart';
import '../../../data/repository/user_service.dart';

class LoginScreen extends StatelessWidget {
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [_buildBackgroundImage(), _buildContent(context)],
    ));
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Image.asset('assets/images/book_logo.jpg', fit: BoxFit.cover)
    );
  }

  Widget _buildContent(BuildContext context) {
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

  Widget _buildGoogleSignInButton(BuildContext context) {
    return CustomElevatedButton(
        text: 'Google ile Giriş Yap',
        icon: Icons.abc,
        onPressed: () async {
          try {
            final account = await _googleSignInService.signInWithGoogle();
            if (account != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(account.displayName ?? '')));
              saveUser(account);
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Google Girişi Başarısız Oldu.')));
              Navigator.pushReplacementNamed(context, '/home');
            }
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hata: $error  TEST için girildi.')));
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
  }

  Widget _buildPhoneLogIn(context) {
    return CustomElevatedButton(
        text: 'Tel No İle Giriş Yap',
        icon: Icons.phone,
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PhonePage()),
          );
        });
  }

  void saveUser(GoogleSignInAccount account) {
    final user = User(
      id: account.id,
      createdAt: DateTime.now().toString(),
      updatedAt: DateTime.now().toString(),
      firstName: account.displayName ?? '',
      lastName: '',
      imageUrl: account.photoUrl,
      phone: '',
      age: 0,
      mail: account.email,
      city: '',
      isPhoneActive: false,
      fcmToken: '',
      role: 'user',
    );
    UserService().saveUser(user, account.photoUrl ?? '');
  }
}

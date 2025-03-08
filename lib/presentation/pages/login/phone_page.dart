import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../../core/util/date_formatter.dart';
import '../../../core/util/login_service.dart';
import '../../../data/model/user.dart';
import '../../../data/repository/user_service.dart';

class PhoneLogInPage extends StatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  State<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends State<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final LoginService _loginService = LoginService();
  String _verificationId = '';
  bool _codeSent = false;
  int _timeUntilNextResend = 60;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_timeUntilNextResend > 0) {
        setState(() => _timeUntilNextResend--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar('Lütfen bir telefon numarası girin.');
      return;
    }

    await _loginService.verifyPhone(
      context,
      _phoneController.text,
          (final smsCode) {
        _navigateToHome();
      },
          (final verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
        _startResendTimer();
      },
          (final verificationId) {
        setState(() => _verificationId = verificationId);
      },
    );
  }

  Future<void> _verifyOtp(final String otp) async {
    if (otp.isEmpty) {
      _showErrorSnackBar('Lütfen OTP kodunu girin.');
      return;
    }
    try {
      final bool isVerified =
      await _loginService.verifyOtp(context, _verificationId, otp);
      if (isVerified) {
        saveUser();
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP kodu hatalı. Lütfen tekrar deneyin.')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Hatalı kod. Lütfen tekrar deneyin.');
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showErrorSnackBar(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Telefon Doğrulama"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "+90***********",
                labelText: "Telefon Numarası",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _codeSent ? null : _verifyPhone,
              child: Text(_codeSent ? "Kod Gönderildi" : "Kod Gönder"),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 24),
              const Text(
                "Lütfen size gönderilen kodu giriniz:",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Pinput(
                length: 6,
                onCompleted: _verifyOtp,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _timeUntilNextResend == 0 ? _verifyPhone : null,
                child: Text(
                  _timeUntilNextResend > 0
                      ? "Yeniden gönderme süresi: $_timeUntilNextResend"
                      : "Kodu yeniden gönder",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void saveUser() {
    final auth.User? account = auth.FirebaseAuth.instance.currentUser;

    if (account == null) return;

    final String displayName = account.displayName?.trim() ?? '';
    final List<String> nameParts = displayName.split(' ');

    final String lastName = nameParts.isNotEmpty ? nameParts.removeLast() : '';
    final String firstName = nameParts.join(' ');
    final nowTime = DateFormatter.nowFormatDateTime();

    final user = User(
      id: account.uid,
      createdAt: nowTime,
      updatedAt: nowTime,
      firstName: firstName,
      lastName: lastName,
      imageUrl: account.photoURL,
      phoneNumber: account.phoneNumber ?? '',
      age: 0,
      eMail: account.email,
      city: '',
      isPhoneActive: true,
      fcmToken: '',
      role: 'user',
    );

    UserService().saveUser(user, account.photoURL ?? '');
  }

}

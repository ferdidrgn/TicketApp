import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../providers/login_provider.dart';

class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final _phoneController = TextEditingController();
  String _verificationId = '';
  bool _codeSent = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (mounted) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
        }
      }
    });
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Lütfen telefon numarasını girin', isError: true);
      return;
    }

    // Telefon numarasının başında +90 yoksa ekle (opsiyonel)
    // final formattedPhone = phone.startsWith('+') ? phone : '+90$phone';

    await ref.read(loginProvider.notifier).verifyPhone(
          phoneNumber: phone,
          onVerificationCompleted: (final credential) async {
            // Otomatik doğrulama (Android)
            if (credential.smsCode != null) {
              await _verifyOtp(credential.smsCode!);
            }
          },
          onCodeSent: (final verificationId, final forceResendingToken) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _codeSent = true;
              });
              _startResendTimer();
              _showSnack('Kod gönderildi', isError: false);
            }
          },
          onAutoRetrievalTimeout: (final verificationId) {
            if (mounted) setState(() => _verificationId = verificationId);
          },
        );
  }

  Future<void> _verifyOtp(final String otp) async {
    if (otp.length != 6) return;

    try {
      await ref.read(loginProvider.notifier).verifyOtp(otp);

      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        _showSnack('Giriş Başarılı', isError: false);
        // 🔥 DOĞRUDAN PROFİL DÜZENLEMEYE GİT
        context.go('/profile-edit/${currentUser.uid}');
      }
    } catch (e) {
      if (mounted) _showSnack('Hatalı kod veya süre doldu.', isError: true);
    }
  }

  void _showSnack(final String message, {final bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Telefon Doğrulama"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sms_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            if (!_codeSent) ...[
              const Text(
                "Telefon numaranızı giriniz",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "+90 5XX XXX XX XX",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyPhone,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Kod Gönder"),
              ),
            ] else ...[
              Text(
                "Lütfen ${_phoneController.text} numarasına gelen kodu giriniz.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Pinput(
                length: 6,
                onCompleted: _verifyOtp,
                autofocus: true,
                defaultPinTheme: PinTheme(
                  width: 56,
                  height: 56,
                  textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _resendCountdown == 0 ? _verifyPhone : null,
                child: Text(
                  _resendCountdown > 0
                      ? "$_resendCountdown saniye sonra tekrar deneyin"
                      : "Kodu Tekrar Gönder",
                  style: TextStyle(
                      color: _resendCountdown == 0 ? Colors.blue : Colors.grey),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

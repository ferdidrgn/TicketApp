import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/app_debug.dart';
import '../providers/login_provider.dart';

class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- SAYFA DURUM DEĞİŞKENLERİ ---
  String? _verificationId;
  bool _isCodeSent = false;
  bool _isLoading = false;
  int _timerValue = 180;
  Timer? _timer;

  // --- SAYAÇ BAŞLATMA ---
  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerValue = 180);
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_timerValue == 0) {
        timer.cancel();
      } else {
        setState(() => _timerValue--);
      }
    });
  }

  // --- ADIM 1: SMS GÖNDERME ---
  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    AppDebug.log("SMS İsteği Gönderiliyor...", tag: "AUTH_UI");

    String phone = _phoneController.text.trim();
    if (!phone.startsWith("+")) phone = "+90$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      // A) Otomatik Doğrulama (Android)
      verificationCompleted: (final PhoneAuthCredential credential) async {
        AppDebug.log("Otomatik Doğrulama Başarılı", tag: "AUTH_UI");
        await _auth.signInWithCredential(credential);
        // AuthStateChanges zaten bizi içeri alacaktır
      },
      // B) Hata Durumu
      verificationFailed: (final FirebaseAuthException e) {
        setState(() => _isLoading = false);
        AppDebug.logError(e, null, "AUTH_ERROR");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.message}")),
        );
      },
      // C) Kod Gönderildi (UI'ı değiştiren yer)
      codeSent: (final String verificationId, final int? resendToken) {
        AppDebug.log("Kod Başarıyla Gönderildi: $verificationId",
            tag: "AUTH_UI");
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
          _isLoading = false;
        });
        _startTimer();
      },
      codeAutoRetrievalTimeout: (final String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // --- ADIM 2: OTP DOĞRULAMA ---
  Future<void> _signInWithOTP() async {
    if (_verificationId == null) return;

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      AppDebug.log("Giriş Başarılı", tag: "AUTH_UI");
      // Giriş başarılı olunca authStateChanges tetiklenir ve yönlendirme yapılır.
    } catch (e) {
      setState(() => _isLoading = false);
      AppDebug.logError(e, null, "OTP_ERROR");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hatalı kod girdiniz!")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Telefon ile Giriş")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isCodeSent
                ? _buildOtpUI()
                : _buildPhoneUI(),
      ),
    );
  }

  Widget _buildPhoneUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Telefon Numaranız",
            prefixText: "+90 ",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyPhone,
            child: const Text("KOD GÖNDER"),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Kalan Süre: ${_timerValue ~/ 60}:${(_timerValue % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: "SMS Kodu",
            hintText: "000000",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _signInWithOTP,
            child: const Text("ONAYLA VE GİRİŞ YAP"),
          ),
        ),
        if (_timerValue == 0)
          TextButton(
            onPressed: _verifyPhone,
            child: const Text("Kodu Tekrar Gönder"),
          ),
      ],
    );
  }
}

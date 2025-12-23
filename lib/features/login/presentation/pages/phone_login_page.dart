import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../../core/util/app_debug.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';

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

  // --- FCM TOKEN KAYDETME (KRİTİK ADIM) ---
  Future<void> _saveDeviceToken(final String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
          'platform': 'mobile',
        }, SetOptions(merge: true));
        AppDebug.log("FCM Token Galeriye Mühürlendi.", tag: "FCM_AUTH");
      }
    } catch (e) {
      AppDebug.log("Token Kayıt Hatası: $e", tag: "FCM_ERROR");
    }
  }

  // --- ADIM 1: SMS GÖNDERME ---
  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    String phone = _phoneController.text.trim();
    if (!phone.startsWith("+")) phone = "+90$phone";

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (final PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        if (result.user != null) await _saveDeviceToken(result.user!.uid);
      },
      verificationFailed: (final FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnackBar("Hata: ${e.message}");
      },
      codeSent: (final String verificationId, final int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
          _isLoading = false;
        });
        _startTimer();
      },
      codeAutoRetrievalTimeout: (final String verificationId) =>
          _verificationId = verificationId,
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

      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        await _saveDeviceToken(result.user!.uid);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Hatalı kod girdiniz!");
    }
  }

  void _showSnackBar(final String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SERÜVENE KATIL",
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomAppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child:
                        _isCodeSent ? _buildOtpUI(theme) : _buildPhoneUI(theme),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneUI(final ThemeData theme) {
    return Column(
      key: const ValueKey('phone_ui'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.phone_iphone_rounded,
            size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text("DOĞRULAMA",
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text("Serüvene başlamak için numaranı gir.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 40),
        _buildTextField(_phoneController, "5XX XXX XX XX", prefix: "+90 "),
        const SizedBox(height: 24),
        _buildArtisticButton("KOD GÖNDER", _verifyPhone, theme),
      ],
    );
  }

  Widget _buildOtpUI(final ThemeData theme) {
    return Column(
      key: const ValueKey('otp_ui'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${_timerValue ~/ 60}:${(_timerValue % 60).toString().padLeft(2, '0')}",
          style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text("SMS KODUNU GİR",
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2)),
        const SizedBox(height: 40),
        _buildTextField(_otpController, "000000", textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _buildArtisticButton("DOĞRULA VE BAŞLA", _signInWithOTP, theme),
        if (_timerValue == 0)
          TextButton(
              onPressed: _verifyPhone,
              child: Text("Yeniden Kod Gönder",
                  style: TextStyle(color: theme.colorScheme.secondary))),
      ],
    );
  }

  Widget _buildTextField(
      final TextEditingController controller, final String hint,
      {final String? prefix, final TextAlign textAlign = TextAlign.start}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.primary.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildArtisticButton(
      final String label, final VoidCallback onTap, final ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2))),
      ),
    );
  }
}

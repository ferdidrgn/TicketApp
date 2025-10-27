import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../data/providers/login/login_provider.dart';
import '../../../../domain/entities/user.dart';
import '../profile_edit/user_profile_edit.dart';

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
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_resendCountdown > 0)
        setState(() => _resendCountdown--);
      else
        timer.cancel();
    });
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Lütfen bir telefon numarası girin.');
      return;
    }

    await ref.read(loginProvider.notifier).verifyPhone(
          phoneNumber: phone,
          onVerificationCompleted: _verifyOtp,
          onCodeSent: (final verificationId) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
            });
            _startResendTimer();
          },
          onAutoRetrievalTimeout: (final verificationId) =>
              setState(() => _verificationId = verificationId),
        );
  }

  Future<void> _verifyOtp(final String otp) async {
    if (otp.isEmpty) {
      _showSnack('Lütfen OTP kodunu girin.');
      return;
    }

    try {
      await ref.read(loginProvider.notifier).verifyOtp(_verificationId, otp);
      final loginState = ref.read(loginProvider);

      final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null || loginState.user == null) {
        _showSnack('OTP kodu hatalı. Tekrar deneyin.');
        return;
      }

      await _saveUser(currentUser);

      if (loginState.errorMessage != null)
        _navigateToEditProfile(currentUser.uid);
      else
        _navigateToHome();
    } catch (_) {
      _showSnack('Hatalı kod. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _saveUser(final auth.User account) async {
    final nameParts = account.displayName?.trim().split(' ') ?? [];
    final user = User(
      id: account.uid,
      createdAt: DateFormatter.nowFormatDateTime(),
      updatedAt: DateFormatter.nowFormatDateTime(),
      firstName: nameParts.length > 1
          ? nameParts.sublist(0, nameParts.length - 1).join(' ')
          : '',
      lastName: nameParts.isNotEmpty ? nameParts.last : '',
      imageUrl: account.photoURL ?? '',
      phoneNumber: account.phoneNumber ?? '',
      age: 0,
      eMail: account.email ?? '',
      city: '',
      isPhoneActive: true,
      fcmToken: '',
      role: 'user',
      favoriteShows: [],
      favoriteStages: [],
      favoritePlayers: [],
      ticketsId: [],
    );

    await ref
        .read(userProvider.notifier)
        .saveUser(user, account.photoURL ?? '');
  }

  void _navigateToEditProfile(final String uid) => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (final _) => UserProfileEditScreen(userId: uid)),
      );

  void _navigateToHome() => Navigator.of(context).pushReplacementNamed('/home');

  void _showSnack(final String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar:
            AppBar(title: const Text("Telefon Doğrulama"), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _phoneField(),
              const SizedBox(height: 16),
              _sendCodeButton(),
              if (_codeSent) ..._otpInput(),
            ],
          ),
        ),
      );

  TextField _phoneField() => TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: "Telefon Numarası",
          hintText: "+90***********",
          border: OutlineInputBorder(),
        ),
      );

  ElevatedButton _sendCodeButton() => ElevatedButton(
      onPressed: _codeSent ? null : _verifyPhone,
      child: Text(_codeSent ? "Kod Gönderildi" : "Kod Gönder"));

  List<Widget> _otpInput() => [
        const SizedBox(height: 24),
        const Text("Lütfen size gönderilen kodu giriniz:",
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Pinput(length: 6, onCompleted: _verifyOtp),
        const SizedBox(height: 16),
        TextButton(
            onPressed: _resendCountdown == 0 ? _verifyPhone : null,
            child: Text(_resendCountdown > 0
                ? "Yeniden gönderme süresi: $_resendCountdown"
                : "Kodu yeniden gönder")),
      ];
}

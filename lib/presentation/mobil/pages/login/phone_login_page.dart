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
  _PhoneLogInPageState createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
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
    _timeUntilNextResend = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_timeUntilNextResend > 0) {
        setState(() => _timeUntilNextResend--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyPhone() async {
    final phoneNumber = _phoneController.text;
    if (phoneNumber.isEmpty) {
      _showSnackBar('Lütfen bir telefon numarası girin.');
      return;
    }

    await ref.read(loginProvider.notifier).verifyPhone(
      phoneNumber,
      (final smsCode) => _verifyOtp(smsCode),
      (final verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
        _startResendTimer();
      },
      (final verificationId) =>
          setState(() => _verificationId = verificationId),
    );
  }

  Future<void> _verifyOtp(final String otp) async {
    if (otp.isEmpty) {
      _showSnackBar('Lütfen OTP kodunu girin.');
      return;
    }

    try {
      await ref.read(loginProvider.notifier).verifyOtp(_verificationId, otp);
      final loginState = ref.read(loginProvider);

      if (loginState.user != null) {
        final auth.User? account = auth.FirebaseAuth.instance.currentUser;
        await _saveUser(account!);

        if (loginState.errorMessage != null)
          _navigateToEditProfile(account.uid);
        else
          _navigateToHome();
      } else {
        _showSnackBar('OTP kodu hatalı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      _showSnackBar('Hatalı kod. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _saveUser(final auth.User account) async {
    final user = User(
      id: account.uid,
      createdAt: DateFormatter.nowFormatDateTime(),
      updatedAt: DateFormatter.nowFormatDateTime(),
      firstName: _extractFirstName(account.displayName),
      lastName: _extractLastName(account.displayName),
      imageUrl: account.photoURL ?? "",
      phoneNumber: account.phoneNumber ?? '',
      age: 0,
      eMail: account.email ?? "",
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

  String _extractFirstName(final String? displayName) {
    final parts = displayName?.trim().split(' ') ?? [];
    return parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : '';
  }

  String _extractLastName(final String? displayName) {
    final parts = displayName?.trim().split(' ') ?? [];
    return parts.isNotEmpty ? parts.last : '';
  }

  void _navigateToEditProfile(final String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final context) => UserProfileEditScreen(userId: uid),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showSnackBar(final String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Telefon Doğrulama"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPhoneNumberField(),
            const SizedBox(height: 16),
            _buildSendCodeButton(),
            if (_codeSent) ..._buildOtpInput(),
          ],
        ),
      ),
    );
  }

  TextField _buildPhoneNumberField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        hintText: "+90***********",
        labelText: "Telefon Numarası",
        border: OutlineInputBorder(),
      ),
    );
  }

  ElevatedButton _buildSendCodeButton() {
    return ElevatedButton(
      onPressed: _codeSent ? null : _verifyPhone,
      child: Text(_codeSent ? "Kod Gönderildi" : "Kod Gönder"),
    );
  }

  List<Widget> _buildOtpInput() {
    return [
      const SizedBox(height: 24),
      const Text("Lütfen size gönderilen kodu giriniz:",
          textAlign: TextAlign.center),
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
    ];
  }
}

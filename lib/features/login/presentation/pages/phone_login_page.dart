import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_notifier.dart';
import '../providers/login_provider.dart'; // loginProvider burada tanımlı
import '../providers/login_state.dart';

class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(final BuildContext context) {
    // 🎯 Provider ismini 'loginProvider' olarak düzelttik
    final loginState = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    ref.listen(loginProvider.select((final s) => s.errorMessage),
        (final prev, final next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: loginState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : loginState.isCodeSent
                ? _buildOtpUI(loginState, notifier)
                : _buildPhoneUI(notifier),
      ),
    );
  }

  // 🎯 dynamic yerine gerçek tipi (LoginNotifier) yazdık
  Widget _buildPhoneUI(final LoginNotifier notifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(labelText: "Telefon", prefixText: "+90 "),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => notifier.verifyPhone(_phoneController.text),
          child: const Text("KOD GÖNDER"),
        ),
      ],
    );
  }

  // 🎯 dynamic yerine gerçek tipleri yazdık ve timerValue'yu düzelttik
  Widget _buildOtpUI(final LoginState state, final LoginNotifier notifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🎯 'timerText' getter'ını kullanıyoruz (02:45 formatında gösterir)
        Text("Kalan Süre: ${state.timerText}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "SMS Kodu"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => notifier.verifyOtp(_otpController.text),
          child: const Text("GİRİŞ YAP"),
        ),
        // 🎯 timerValue 0 olduğunda butonu göster
        if (state.timerValue == 0)
          TextButton(
            onPressed: () => notifier.verifyPhone(_phoneController.text),
            child: const Text("Kodu Tekrar Gönder"),
          ),
      ],
    );
  }
}

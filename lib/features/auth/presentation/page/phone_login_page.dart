import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../providers/auth_provider.dart';

/// 🔥 Riverpod ile state management kullanan temiz phone login
class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar("Lütfen telefon numaranızı girin");
      return;
    }

    await ref.read(authMutationProvider.notifier).verifyPhone(phone);
  }

  Future<void> _signInWithOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar("Lütfen 6 haneli kodu girin");
      return;
    }

    await ref.read(authMutationProvider.notifier).verifyOtp(otp);
  }

  void _showSnackBar(final String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(final BuildContext context) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider,
        (final previous, final next) {
      next.whenOrNull(
        error: (final error, final stack) => _showSnackBar(error.toString()),
        data: (final _) {
          if (ref.read(isLoggedInProvider)) if (context.mounted)
            NavigationHandler.goToHome(context);
        },
      );
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "SERÜVENE KATIL",
          style: context.textTheme.labelLarge?.copyWith(letterSpacing: 4),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomAppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: authMutation.isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: (authMutation.hasValue &&
                            !ref.watch(isLoggedInProvider))
                        ? _buildOtpUI()
                        : _buildPhoneUI(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneUI() {
    final color = context.colors;
    final textTheme = context.textTheme;

    return Column(
      key: const ValueKey('phone_ui'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.phone_iphone_rounded,
          size: 64,
          color: color.primary,
        ),
        const SizedBox(height: 24),
        Text(
          "DOĞRULAMA",
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Serüvene başlamak için numaranı gir.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: color.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          _phoneController,
          "5XX XXX XX XX",
          prefix: "+90 ",
        ),
        const SizedBox(height: 24),
        _buildArtisticButton("KOD GÖNDER", _verifyPhone),
      ],
    );
  }

  Widget _buildOtpUI() {
    final color = context.colors;
    final textTheme = context.textTheme;

    final seconds = ref.watch(otpTimerProvider);
    // Saniyeyi 00:XX formatına çevir
    final timerText = "00:${seconds.toString().padLeft(2, '0')}";
    final canResend = seconds == 0;

    return Column(
      key: const ValueKey('otp_ui'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timerText,
          style: textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.w900, color: color.primary),
        ),
        const SizedBox(height: 12),
        Text(
          "SMS KODUNU GİR",
          style: textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          _otpController,
          "000000",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildArtisticButton("DOĞRULA VE BAŞLA", _signInWithOTP),
        if (canResend) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _verifyPhone,
            child: Text(
              "Yeniden Kod Gönder",
              style: TextStyle(
                  color: color.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    final TextEditingController controller,
    final String hint, {
    final String? prefix,
    final TextAlign textAlign = TextAlign.start,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: context.colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.primary.withOpacity(0.1),
          ),
        ),
        child: TextField(
          controller: controller,
          textAlign: textAlign,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            contentPadding: const EdgeInsets.all(20),
            border: InputBorder.none,
          ),
        ),
      );

  Widget _buildArtisticButton(final String label, final VoidCallback onTap) {
    final color = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primary,
              color.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

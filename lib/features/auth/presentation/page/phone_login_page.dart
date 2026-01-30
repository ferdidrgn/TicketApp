import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../providers/auth_provider.dart';

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

  // --- MANTIKSAL METODLAR ---

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
    final bool isLargeScreen = context.isTablet || context.isDesktop;

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

    return BasePageWrapper(
      title: 'SERÜVENE KATIL',
      subtitle: 'Kimliğini doğrula ve sanata başla...',
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 500 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: (authMutation.hasValue && !ref.watch(isLoggedInProvider))
                  ? _buildOtpUI()
                  : _buildPhoneUI(),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildPhoneUI() {
    return Column(
      key: const ValueKey('phone_ui'),
      children: [
        _buildIconHeader(Icons.phonelink_ring_rounded),
        const SizedBox(height: 40),
        _buildTextField(
          _phoneController,
          "5XX XXX XX XX",
          label: "TELEFON NUMARASI",
          prefix: "+90 ",
        ),
        const SizedBox(height: 32),
        _buildArtisticButton("KOD GÖNDER", _verifyPhone),
      ],
    );
  }

  Widget _buildOtpUI() {
    final seconds = ref.watch(otpTimerProvider);
    final timerText = "00:${seconds.toString().padLeft(2, '0')}";
    final canResend = seconds == 0;

    return Column(
      key: const ValueKey('otp_ui'),
      children: [
        Text(
          timerText,
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle("SMS KODUNU GİR"),
        const SizedBox(height: 40),
        _buildTextField(
          _otpController,
          "000000",
          label: "6 HANELİ KOD",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildArtisticButton("DOĞRULA VE BAŞLA", _signInWithOTP),
        if (canResend) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: _verifyPhone,
            child: Text(
              "Yeniden Kod Gönder",
              style: TextStyle(
                  color: context.colors.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconHeader(final IconData icon) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 48, color: context.colors.primary),
      );

  Widget _buildTextField(
    final TextEditingController controller,
    final String hint, {
    required final String label,
    final String? prefix,
    final TextAlign textAlign = TextAlign.start,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(label,
                style: context.textTheme.labelSmall
                    ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.outlineVariant),
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
          ),
        ],
      );

  Widget _buildArtisticButton(final String label, final VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [context.colors.primary, context.colors.secondary]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: context.colors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
          ),
        ),
      );

  Widget _buildSectionTitle(final String title) => Text(
        title,
        style: context.textTheme.labelLarge
            ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
      );
}

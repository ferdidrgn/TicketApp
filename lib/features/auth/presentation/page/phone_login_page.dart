import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';

class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // UI Kontrolü: Kod gönderildi mi?
  bool _isCodeSent = false;

  // Sayaç için
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- SAYAÇ METODLARI ---

  void _startTimer() {
    setState(() {
      _isCodeSent = true;
      _start = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_start == 0)
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      else
        setState(() {
          _start--;
        });
    });
  }

  // --- MANTIKSAL METODLAR ---

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar(
          "Lütfen geçerli bir telefon numarası girin (Başında 0 olmadan)");
      return;
    }

    // Numarayı +90 formatına çevir (Eğer kullanıcı girmediyse)
    final formattedPhone = phone.startsWith("+90") ? phone : "+90$phone";

    // Firebase'e istek at
    await ref.read(authMutationProvider.notifier).verifyPhone(formattedPhone);

    // Hata yoksa sayacı başlat ve ekranı değiştir
    // Not: Hata kontrolünü provider state'i üzerinden listen ile yapıyoruz
  }

  Future<void> _signInWithOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar("Lütfen 6 haneli kodu eksiksiz girin");
      return;
    }
    await ref.read(authMutationProvider.notifier).verifyOtp(otp);
  }

  void _showSnackBar(final String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: context.colors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(final BuildContext context) {
    final authMutation = ref.watch(authMutationProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    // State Dinleyicisi: Başarılı işlemleri yakala
    ref.listen<AsyncValue<void>>(authMutationProvider,
            (final previous, final next) {
          next.whenOrNull(
            error: (final error, final stack) {
              _showSnackBar("Hata: ${error.toString()}");
              // Hata olursa ve kod ekranındaysak belki geri atmak isteyebiliriz
              // Ama genelde kullanıcı tekrar denesin diye kalırız.
            },
            data: (final _) {
              // Eğer işlem başarılıysa ve henüz kod ekranına geçmediysek (Telefon doğrulama başarılıysa)
              if (!_isCodeSent) {
                _startTimer(); // Kod gönderildi, sayacı başlat ve ekranı değiştir
              } else {
                // Zaten kod ekranındayız ve işlem başarılı olduysa -> Login bitti
                if (context.mounted) NavigationHandler.goToHome(context);
              }
            },
          );
        });

    return BasePageWrapper(
      title: _isCodeSent ? 'DOĞRULAMA' : 'SERÜVENE KATIL',
      subtitle: _isCodeSent
          ? 'Telefonuna gelen kodu gir.'
          : 'Kimliğini doğrula ve sanata başla...',
      showBackButton: true,
      // Geri butonuna basınca eğer kod ekranındaysak telefon ekranına dönmeli
      // BasePageWrapper'ın onBack parametresi varsa oraya bağlayın, yoksa WillPopScope kullanın
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        safeAreaTop: true,
      ),
      child: PopScope(
        canPop: !_isCodeSent, // Kod ekranındaysak direkt çıkmasın
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          if (_isCodeSent) {
            setState(() {
              _isCodeSent = false;
              _timer?.cancel();
            });
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: isLargeScreen ? 500 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (final child, final animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _isCodeSent ? _buildOtpUI() : _buildPhoneUI(),
              ),
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
          isPhone: true,
        ),
        const SizedBox(height: 32),
        _buildArtisticButton("KOD GÖNDER", _verifyPhone),
      ],
    );
  }

  Widget _buildOtpUI() {
    final timerText = "00:${_start.toString().padLeft(2, '0')}";

    return Column(
      key: const ValueKey('otp_ui'),
      children: [
        Text(
          timerText,
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: _start < 10 ? context.colors.error : context.colors.primary,
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
          maxLength: 6,
        ),
        const SizedBox(height: 32),
        _buildArtisticButton("DOĞRULA VE BAŞLA", _signInWithOTP),
        const SizedBox(height: 24),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _canResend ? 1.0 : 0.5,
          child: TextButton(
            onPressed: _canResend ? _verifyPhone : null,
            child: Text(
              "Kodu Yeniden Gönder",
              style: TextStyle(
                  color: context.colors.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isCodeSent = false;
              _timer?.cancel();
            });
          },
          child: Text(
            "Numarayı Düzenle",
            style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.6), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildIconHeader(final IconData icon) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 48, color: context.colors.primary),
      );

  Widget _buildTextField(final TextEditingController controller,
      final String hint, {
        required final String label,
        final String? prefix,
        final TextAlign textAlign = TextAlign.start,
        final int? maxLength,
        final bool isPhone = false,
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
              keyboardType: TextInputType.number,
              maxLength: maxLength,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefix,
                counterText: "",
                // Sayacı gizle
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

  Widget _buildSectionTitle(final String title) =>
      Text(
        title,
        style: context.textTheme.labelLarge
            ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
      );
}

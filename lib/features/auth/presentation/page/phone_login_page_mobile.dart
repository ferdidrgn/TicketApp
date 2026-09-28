import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../providers/auth_provider.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ / OTP EKRANI — MOBİL
///
/// `login_screen_mobile.dart` ile AYNI yapısal desen (araştırmanın
/// doğruladığı "bottom sheet auth": üstte sadece atmosfer fotoğrafı, altta
/// DÜZ/opak bir "sahne platformu" üzerinde gerçek form) — önceki tasarımın
/// "her şey fotoğrafın üzerinde yarı saydam" tek-bölge iskeletinden
/// yapısal olarak farklı. Farklı atmosfer fotoğrafı (Unsplash — zaten
/// `home_page_web.dart`'ın hero'sunda da kullanılan, doğrulanmış bir
/// kaynak) kullanılıyor ki iki giriş ekranı birbirine karışmasın.
///
/// OTP adımı `pinput` paketini kullanıyor — pubspec.yaml'da zaten bir
/// bağımlılıktı ama hiçbir yerde kullanılmıyordu.
class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  _PendingAuthAction _pendingAction = _PendingAuthAction.none;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  Animation<double> _fade(final double start) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      );

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar(
          "Lütfen geçerli bir telefon numarası girin (Başında 0 olmadan)",
          isError: true);
      return;
    }

    final formattedPhone = phone.startsWith("+90") ? phone : "+90$phone";
    _pendingAction = _PendingAuthAction.sendCode;
    await ref.read(authMutationProvider.notifier).verifyPhone(formattedPhone);
  }

  Future<void> _signInWithOTP([final String? pin]) async {
    final otp = (pin ?? _otpController.text).trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar("Lütfen 6 haneli kodu eksiksiz girin", isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.verifyCode;
    await ref.read(authMutationProvider.notifier).verifyOtp(otp);
  }

  void _showSnackBar(final String msg, {final bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(
      authMutationProvider,
      (final previous, final next) {
        next.whenOrNull(
          error: (final error, final stack) =>
              _showSnackBar("Hata: ${error.toString()}", isError: true),
          data: (final _) {
            switch (_pendingAction) {
              case _PendingAuthAction.sendCode:
                if (ref.read(isLoggedInProvider)) {
                  if (context.mounted) NavigationHandler.goToHome(context);
                } else {
                  setState(() => _isCodeSent = true);
                }
                break;
              case _PendingAuthAction.verifyCode:
                if (context.mounted) NavigationHandler.goToHome(context);
                break;
              case _PendingAuthAction.none:
                break;
            }
            _pendingAction = _PendingAuthAction.none;
          },
        );
      },
    );

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      // 🔥 DÜZELTME: login_screen_mobile.dart'taki AYNI hata — `safeAreaTop:
      // false`, BasePageWrapper'ın kendi geri butonunu/header'ını da aynı
      // SafeArea'nın içinde bırakıp durum çubuğunun/çentiğin altına değil
      // üstüne çiziyordu. İçerideki SafeArea zaten kendi varsayılan
      // top:true'suyla güvenle iç içe çalışıyor (çift boşluk oluşmaz).
      layoutConfig: const BasePageLayoutConfig(
        safeAreaBottom: false,
      ),
      child: PopScope(
        canPop: !_isCodeSent,
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          if (_isCodeSent) setState(() => _isCodeSent = false);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. ÜST BÖLGE: SAHNE FOTOĞRAFI (SADECE ATMOSFER) ---
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Image(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1503095396549-807759245b35'),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          WebColors.veryDarkBlue.withOpacity(0.4),
                          Colors.transparent,
                          WebColors.darkBlueSurface.withOpacity(0.6),
                          WebColors.darkBlueSurface,
                        ],
                        stops: const [0.0, 0.35, 0.85, 1.0],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _fade(0.0),
                            child: _StatusBadge(isCodeSent: _isCodeSent),
                          ),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: AppMotion.normal,
                            switchInCurve: AppMotion.standard,
                            switchOutCurve: AppMotion.standard,
                            child: Text(
                              _isCodeSent
                                  ? 'Son Bir\nAdım Kaldı.'
                                  : 'Sahne Kapısı\nAralanıyor.',
                              key: ValueKey(_isCodeSent),
                              style: GoogleFonts.playfairDisplay(
                                color: WebColors.whiteText,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                shadows: [
                                  Shadow(
                                    color:
                                        WebColors.veryDarkBlue.withOpacity(0.7),
                                    offset: const Offset(0, 3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. ALT BÖLGE: SAHNE PLATFORMU (AKSİYON — DÜZ ZEMİN) ---
            Expanded(
              flex: 5,
              child: FadeTransition(
                opacity: _fade(0.2),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: WebColors.darkBlueSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      topRight: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                          AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: AppMotion.normal,
                          switchInCurve: AppMotion.standard,
                          switchOutCurve: AppMotion.standard,
                          transitionBuilder: (final child, final animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child:
                              _isCodeSent ? _buildOtpUI() : _buildPhoneUI(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneUI() {
    return Column(
      key: const ValueKey('phone_ui'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Biletinizi almak ve yerinizi seçmek için telefon numaranızı '
          'girin.',
          style: TextStyle(
            fontSize: 13.5,
            color: WebColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _PhoneTextField(
          controller: _phoneController,
          onSubmitted: (final _) => _verifyPhone(),
        ),
        const SizedBox(height: AppSpacing.xl),
        _ArtisticActionButton(
          label: 'KOD GÖNDER',
          icon: Icons.send_rounded,
          onTap: _verifyPhone,
        ),
      ],
    );
  }

  Widget _buildOtpUI() {
    final remainingSeconds = ref.watch(otpTimerProvider);
    final bool canResend = remainingSeconds <= 0;
    final timerText = "00:${remainingSeconds.toString().padLeft(2, '0')}";

    return Column(
      key: const ValueKey('otp_ui'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Telefonunuza gönderdiğimiz 6 haneli kodu girerek perdeyi açın.',
          style: TextStyle(
            fontSize: 13.5,
            color: WebColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Semantics(
            label: 'Doğrulama kodu, 6 hane',
            textField: true,
            child: Pinput(
              length: 6,
              controller: _otpController,
              autofocus: true,
              keyboardType: TextInputType.number,
              defaultPinTheme: _pinTheme(
                background: WebColors.darkBlueBackground,
                border: WebColors.darkBlueAccent,
              ),
              focusedPinTheme: _pinTheme(
                background: WebColors.darkBlueBackground,
                border: WebColors.primaryGoldLight,
                shadow: AppShadows.level2(WebColors.primaryGold),
              ),
              submittedPinTheme: _pinTheme(
                background: WebColors.primaryGold.withOpacity(0.18),
                border: WebColors.primaryGold,
              ),
              onCompleted: (final pin) => _signInWithOTP(pin),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            timerText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: canResend ? Colors.red.shade400 : WebColors.primaryGoldLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _ArtisticActionButton(
          label: 'DOĞRULA VE BAŞLA',
          icon: Icons.check_circle_outline_rounded,
          onTap: () => _signInWithOTP(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _isCodeSent = false),
              style: TextButton.styleFrom(
                foregroundColor: WebColors.textSecondary,
              ),
              child: const Text(
                "Numarayı Düzenle",
                style:
                    TextStyle(fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
            AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: canResend ? 1.0 : 0.4,
              child: TextButton(
                onPressed: canResend ? _verifyPhone : null,
                style: TextButton.styleFrom(
                  foregroundColor: WebColors.primaryGoldLight,
                ),
                child: const Text(
                  "Kodu Yeniden Gönder",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  PinTheme _pinTheme({
    required final Color background,
    required final Color border,
    final List<BoxShadow>? shadow,
  }) =>
      PinTheme(
        width: 46,
        height: 56,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: WebColors.whiteText,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: 1.5),
          boxShadow: shadow,
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool isCodeSent;
  const _StatusBadge({required this.isCodeSent});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      label: isCodeSent ? 'Doğrulama aşaması' : 'Güvenli giriş',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: WebColors.primaryGold.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: AppShadows.level1(WebColors.veryDarkBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCodeSent ? Icons.mark_email_read_rounded : Icons.security_rounded,
              color: WebColors.primaryGoldLight,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isCodeSent ? 'Doğrulama Aşaması' : 'Güvenli Giriş',
              style: TextStyle(
                color: WebColors.whiteText.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Telefon numarası alanı — artık DÜZ platform zemini üzerinde (fotoğrafın
/// üzerinde değil), bu yüzden ham/yarı saydam "cam" zemin yerine
/// `WebColors.darkBlueBackground` (gerçek, opak bir yüzey) kullanıyor —
/// daha yüksek kontrast, daha okunabilir.
class _PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _PhoneTextField({required this.controller, this.onSubmitted});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TELEFON NUMARASI',
            style: TextStyle(
              color: WebColors.textTertiary,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          label: 'Telefon numarası girişi',
          textField: true,
          child: Container(
            decoration: BoxDecoration(
              color: WebColors.darkBlueBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: WebColors.darkBlueAccent,
                width: 1.4,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 10,
              keyboardAppearance: Brightness.dark,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: WebColors.whiteText,
                letterSpacing: 1.4,
              ),
              decoration: InputDecoration(
                hintText: '5XX XXX XX XX',
                hintStyle: TextStyle(color: WebColors.textTertiary),
                prefixText: '+90  ',
                prefixStyle: const TextStyle(
                  color: WebColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                counterText: "",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Aksiyon butonu — ekranın TEK imza asimetrik köşe (`AppRadius.asymLg`)
/// vurgu noktası.
class _ArtisticActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ArtisticActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.asymLg,
      child: Ink(
        decoration: BoxDecoration(
          color: WebColors.whiteText,
          borderRadius: AppRadius.asymLg,
          boxShadow: AppShadows.level3(WebColors.veryDarkBlue),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.asymLg,
          splashColor: Colors.grey.withOpacity(0.2),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1F1F1F)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

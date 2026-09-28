import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../providers/auth_provider.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ / OTP EKRANI — MASAÜSTÜ/WEB
///
/// `login_screen_web.dart` ile AYNI split-screen iskeleti (sol sahne
/// paneli, sağ form kartı, kendi `GlassmorphismBackButton`'ı, ~900px iç
/// kırılma noktası) — ama farklı atmosfer fotoğrafı ve iki-adımlı
/// (telefon → OTP) form içeriği. `BasePageWrapper` burada da bilerek
/// kullanılmıyor (bkz. `login_screen_web.dart` başındaki gerekçe).
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

  void _handleBack() {
    if (_isCodeSent) {
      setState(() => _isCodeSent = false);
    } else {
      NavigationHandler.smartGoBack(context);
    }
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

    return PopScope(
      canPop: !_isCodeSent,
      onPopInvokedWithResult: (final didPop, final result) {
        if (didPop) return;
        if (_isCodeSent) setState(() => _isCodeSent = false);
      },
      child: ColoredBox(
        color: WebColors.veryDarkBlue,
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (final context, final constraints) {
                  final bool split = constraints.maxWidth >= 900;
                  final stage = _StagePanel(
                      fade: _fade, compact: !split, isCodeSent: _isCodeSent);
                  final form = _FormPanel(
                    isCodeSent: _isCodeSent,
                    isLoading: authMutation.isLoading,
                    phoneController: _phoneController,
                    otpController: _otpController,
                    onSendCode: _verifyPhone,
                    onVerify: _signInWithOTP,
                    onEditNumber: () => setState(() => _isCodeSent = false),
                  );
                  if (split) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: stage),
                        Expanded(flex: 4, child: form),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                            height: constraints.maxHeight * 0.4, child: stage),
                        form,
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: AppSpacing.xl,
              left: AppSpacing.xl,
              child: GlassmorphismBackButton(onPressed: _handleBack, size: 44),
            ),
            if (authMutation.isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: WebColors.veryDarkBlue.withOpacity(0.55),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sol panel — `login_screen_web.dart`'taki `_StagePanel` ile aynı teknik,
/// BİLEREK farklı atmosfer fotoğrafı (Unsplash — `home_page_web.dart`'ın
/// hero'sunda da kullanılan, doğrulanmış bir kaynak) kullanıyor ki iki giriş
/// ekranı görsel olarak ayırt edilsin.
class _StagePanel extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool compact;
  final bool isCodeSent;

  const _StagePanel(
      {required this.fade, required this.isCodeSent, this.compact = false});

  @override
  Widget build(final BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Kullanıcının kendi seçimi: login_screen_web ile aynı
        // "sahne/konser atmosferi" fotoğrafı — tutarlılık için.
        const Image(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1800&q=85'),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WebColors.veryDarkBlue.withOpacity(0.88),
                WebColors.darkBlueBackground.withOpacity(0.6),
                WebColors.darkBlueBackground.withOpacity(0.32),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.section,
            compact ? AppSpacing.xxl : AppSpacing.section,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              if (!compact) const Spacer(),
              AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                child: Text(
                  isCodeSent ? 'Son Bir\nAdım Kaldı.' : 'Sahne Kapısı\nAralanıyor.',
                  key: ValueKey(isCodeSent),
                  style: GoogleFonts.playfairDisplay(
                    color: WebColors.whiteText,
                    fontSize: compact ? 28 : 42,
                    fontWeight: FontWeight.w600,
                    height: 1.14,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  isCodeSent
                      ? 'Telefonunuza gönderdiğimiz 6 haneli kodu girerek '
                          'perdeyi açın.'
                      : 'Biletinizi almak ve yerinizi seçmek için telefon '
                          'numaranızı girin.',
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sağ panel — form kartı. Telefon/OTP adımları arasında `AnimatedSwitcher`
/// ile geçiş yapar; kart bütünüyle klavye/Enter ile kullanılabilir
/// (`TextField.onSubmitted`).
class _FormPanel extends StatelessWidget {
  final bool isCodeSent;
  final bool isLoading;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onSendCode;
  final void Function([String? pin]) onVerify;
  final VoidCallback onEditNumber;

  const _FormPanel({
    required this.isCodeSent,
    required this.isLoading,
    required this.phoneController,
    required this.otpController,
    required this.onSendCode,
    required this.onVerify,
    required this.onEditNumber,
  });

  @override
  Widget build(final BuildContext context) {
    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface,
                borderRadius: AppRadius.asymLg,
                border: Border.all(color: WebColors.darkBlueAccent),
                boxShadow: AppShadows.level2(WebColors.veryDarkBlue),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                transitionBuilder: (final child, final animation) =>
                    FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: isCodeSent
                    ? _OtpStep(
                        key: const ValueKey('otp'),
                        controller: otpController,
                        isLoading: isLoading,
                        onVerify: onVerify,
                        onEditNumber: onEditNumber,
                      )
                    : _PhoneStep(
                        key: const ValueKey('phone'),
                        controller: phoneController,
                        isLoading: isLoading,
                        onSendCode: onSendCode,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSendCode;

  const _PhoneStep({
    required super.key,
    required this.controller,
    required this.isLoading,
    required this.onSendCode,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GÜVENLİ GİRİŞ',
          style: TextStyle(
            color: WebColors.primaryGoldLight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Telefon Numaranız',
          style: context.textTheme.headlineSmall?.copyWith(
            color: WebColors.whiteText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'TELEFON NUMARASI',
          style: TextStyle(
            color: WebColors.whiteText.withOpacity(0.6),
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Telefon numarası girişi',
          textField: true,
          child: Container(
            decoration: BoxDecoration(
              color: WebColors.darkBlueBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: WebColors.darkBlueAccent, width: 1.4),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onSubmitted: (final _) => onSendCode(),
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
                    color: WebColors.textSecondary, fontWeight: FontWeight.bold),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _WebPrimaryButton(
          label: 'KOD GÖNDER',
          onTap: isLoading ? null : onSendCode,
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final void Function([String? pin]) onVerify;
  final VoidCallback onEditNumber;

  const _OtpStep({
    required super.key,
    required this.controller,
    required this.isLoading,
    required this.onVerify,
    required this.onEditNumber,
  });

  @override
  Widget build(final BuildContext context) {
    return Consumer(
      builder: (final context, final ref, final _) {
        final remainingSeconds = ref.watch(otpTimerProvider);
        final bool canResend = remainingSeconds <= 0;
        final timerText = "00:${remainingSeconds.toString().padLeft(2, '0')}";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DOĞRULAMA',
              style: TextStyle(
                color: WebColors.primaryGoldLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '6 Haneli Kod',
              style: context.textTheme.headlineSmall?.copyWith(
                color: WebColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Semantics(
                label: 'Doğrulama kodu, 6 hane',
                textField: true,
                child: Pinput(
                  length: 6,
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: PinTheme(
                    width: 48,
                    height: 58,
                    textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: WebColors.whiteText),
                    decoration: BoxDecoration(
                      color: WebColors.darkBlueBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border:
                          Border.all(color: WebColors.darkBlueAccent, width: 1.4),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 48,
                    height: 58,
                    textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: WebColors.whiteText),
                    decoration: BoxDecoration(
                      color: WebColors.darkBlueBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: WebColors.primaryGoldLight, width: 1.6),
                      boxShadow: AppShadows.level2(WebColors.primaryGold),
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 48,
                    height: 58,
                    textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: WebColors.whiteText),
                    decoration: BoxDecoration(
                      color: WebColors.primaryGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: WebColors.primaryGold, width: 1.6),
                    ),
                  ),
                  onCompleted: (final pin) => onVerify(pin),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                timerText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color:
                      canResend ? Colors.red.shade400 : WebColors.primaryGoldLight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _WebPrimaryButton(
              label: 'DOĞRULA VE BAŞLA',
              onTap: isLoading ? null : () => onVerify(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onEditNumber,
                  style: TextButton.styleFrom(
                    foregroundColor: WebColors.textSecondary,
                  ),
                  child: const Text('Numarayı Düzenle',
                      style: TextStyle(
                          fontSize: 13, decoration: TextDecoration.underline)),
                ),
                AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: canResend ? 1.0 : 0.4,
                  child: TextButton(
                    onPressed: canResend && !isLoading ? () => onEditNumber() : null,
                    style:
                        TextButton.styleFrom(foregroundColor: WebColors.primaryGoldLight),
                    child: const Text('Kodu Yeniden Gönder',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Klavye/fare dostu birincil buton — `login_screen_web.dart`'taki
/// `_WebAuthButton` ile aynı `InkWell`/`onHover` tekniği.
class _WebPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _WebPrimaryButton({required this.label, required this.onTap});

  @override
  State<_WebPrimaryButton> createState() => _WebPrimaryButtonState();
}

class _WebPrimaryButtonState extends State<_WebPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Material(
        color: WebColors.whiteText,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (final v) => setState(() => _hovered = v),
          borderRadius: BorderRadius.circular(AppRadius.md),
          focusColor: WebColors.primaryGold.withOpacity(0.18),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.level2(WebColors.veryDarkBlue)
                  .map((final s) => BoxShadow(
                        color: s.color,
                        blurRadius: _hovered ? s.blurRadius + 6 : s.blurRadius,
                        offset: s.offset,
                      ))
                  .toList(),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

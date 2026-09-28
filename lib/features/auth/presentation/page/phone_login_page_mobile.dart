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
import '../widgets/auth_atmosphere.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ / OTP EKRANI — MOBİL (3. TASARIM)
///
/// `login_screen_mobile.dart`'ın "afiş tipografisi + kadro listesi" dilini
/// BİLEREK TEKRARLAMIYOR — kullanıcının talep ettiği "arayış" (o ekran) ile
/// "doğrulama" (bu ekran) farklı anlar hissettirsin diye ayrı bir görsel
/// motif kullanılıyor: sahne kapısındaki küçük bir "gözetleme deliği"
/// (`AuthPortholePhoto` — büyük bir fotoğraf PANELİ değil, tek bir
/// dairesel porthole + ışık halkası) ve altında ADIM 1/ADIM 2 rozetiyle
/// (`AuthStepChip`) ayrışan, dikeyde ortalanmış tek bir form akışı.
///
/// Mantık (Firebase Phone Auth: `verifyPhone`/`verifyOtp`, OTP zamanlayıcı,
/// yeniden gönderme, `_isCodeSent`/`_pendingAction` durum makinesi) ÖNCEKİ
/// sürümle BİREBİR AYNI — sadece sunum değişti.
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
      child: PopScope(
        canPop: !_isCodeSent,
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          if (_isCodeSent) setState(() => _isCodeSent = false);
        },
        child: Stack(
          children: [
            const Positioned.fill(child: _StageDoorBackdrop()),
            // 🔥 NOT: `BasePageWrapper` zaten kendi `SafeArea`'sını
            // (varsayılan `safeAreaTop`/`safeAreaBottom: true`) uyguluyor —
            // burada İKİNCİ bir `SafeArea` sarmalamaya GEREK YOK (bkz.
            // CLAUDE.md'deki daha önceki çift-SafeArea/geri-tuşu çakışması
            // bug'ı notu — o hatanın kökeni tam olarak gereksiz iç içe
            // SafeArea/`safeAreaTop: false` zorlamasıydı).
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg,
                  AppSpacing.xl, AppSpacing.xxl),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fade(0.0),
                      child: const AuthPortholePhoto(imageUrl: _stageImageUrl),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeTransition(
                      opacity: _fade(0.08),
                      child: AuthStepChip(
                        icon: _isCodeSent
                            ? Icons.mark_email_read_rounded
                            : Icons.security_rounded,
                        label: _isCodeSent
                            ? 'ADIM 2 · DOĞRULAMA'
                            : 'ADIM 1 · İLETİŞİM',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      child: Text(
                        _isCodeSent
                            ? 'SON PERDE:\nKODU DOĞRULA.'
                            : 'NUMARANI PAYLAŞ,\nYERİNİ AYIRALIM.',
                        key: ValueKey(_isCodeSent),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: WebColors.whiteText,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isCodeSent
                          ? 'Telefonunuza gönderdiğimiz 6 haneli kodu '
                              'girerek perdeyi açın.'
                          : 'Biletinizi almak ve yerinizi seçmek için '
                              'telefon numaranızı girin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeTransition(
                      opacity: _fade(0.2),
                      child: AnimatedSwitcher(
                        duration: AppMotion.normal,
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.standard,
                        transitionBuilder:
                            (final child, final animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _isCodeSent ? _buildOtpUI() : _buildPhoneUI(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneUI() => Column(
        key: const ValueKey('phone_ui'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhoneTextField(
            controller: _phoneController,
            onSubmitted: (final _) => _verifyPhone(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(
            label: 'KOD GÖNDER',
            icon: Icons.send_rounded,
            onTap: _verifyPhone,
          ),
        ],
      );

  Widget _buildOtpUI() {
    final remainingSeconds = ref.watch(otpTimerProvider);
    final bool canResend = remainingSeconds <= 0;
    final timerText = "00:${remainingSeconds.toString().padLeft(2, '0')}";

    return Column(
      key: const ValueKey('otp_ui'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        AuthPrimaryButton(
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

/// Kullanıcının kendi seçimi (profil sayfasının misafir durumundaki aynı
/// "sahne/konser atmosferi" fotoğrafı) — burada büyük bir panel değil,
/// `AuthPortholePhoto`'nun küçük gözetleme deliğinde kullanılıyor.
const String _stageImageUrl =
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1800&q=85';

/// Zemin: düz gradyan + TEK spot ışığı — alt-orta, sanki sahne ışıkları
/// (footlights) aşağıdan yukarı doğru aydınlatıyormuş gibi asimetrik değil
/// merkezî bir konum (bu ekranın kompozisyonu zaten dikeyde ortalı olduğu
/// için ışık da merkeze yakın duruyor — `login_screen_mobile.dart`'taki
/// sağ-üst asimetrik konumdan BİLEREK farklı).
class _StageDoorBackdrop extends StatelessWidget {
  const _StageDoorBackdrop();

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.veryDarkBlue,
                  WebColors.darkBlueBackground,
                  WebColors.darkBlueSurface,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: 0,
            right: 0,
            child: Center(
              child: AuthAmbientGlow(
                  size: 360, tint: WebColors.primaryGold.withOpacity(0.9)),
            ),
          ),
        ],
      );
}

/// Telefon numarası alanı — "bilet gişesi" hissi veren, ortalanmış, sade
/// bir alt-çizgili giriş (dolu/kenarlıklı kutu DEĞİL — `AuthMarqueeRow`'un
/// çizgi dilini burada da sürdürüyor).
class _PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _PhoneTextField({required this.controller, this.onSubmitted});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TELEFON NUMARASI',
            style: TextStyle(
              color: WebColors.textTertiary,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Telefon numarası girişi',
            textField: true,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: WebColors.primaryGold.withOpacity(0.45),
                    width: 1.4,
                  ),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 10,
                keyboardAppearance: Brightness.dark,
                textAlign: TextAlign.center,
                onSubmitted: onSubmitted,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: WebColors.whiteText,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '5XX XXX XX XX',
                  hintStyle: TextStyle(color: WebColors.textTertiary),
                  prefixText: '+90  ',
                  prefixStyle: const TextStyle(
                    color: WebColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  counterText: "",
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      );
}

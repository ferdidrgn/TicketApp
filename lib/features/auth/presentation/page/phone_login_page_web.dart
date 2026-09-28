import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_atmosphere.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ / OTP EKRANI — MASAÜSTÜ/WEB (5. TASARIM)
///
/// `login_screen_web.dart` ile AYNI "afiş kartı" dilini paylaşır
/// (kullanıcının paylaştığı referans görselin kompozisyonu), AMA farklı bir
/// fotoğraf ve tamamen farklı bir aksiyon bloğu kullanır. Bu ekranın
/// GERÇEKTEN tek bir birincil aksiyonu var (telefon gönder / kodu
/// doğrula), o yüzden referansın "tek fotoğraf + tek başlık + tek pill"
/// iskeletine EN DOĞRUDAN oturan ekran bu.
///
/// GERÇEK responsive kırılma noktaları (`ResponsiveUtils`/
/// `context.responsive` — `home_page_web.dart` ile aynı kural):
///   - Dar/TABLET (<1024): tek sütun afiş kartı, form+pill fotoğrafın alt
///     kenarını bindiriyor.
///   - GENİŞ MASAÜSTÜ (>=1024): sol sütunda saf tipografi (adım rozeti +
///     başlık + alt metin), sağ sütunda SADECE fotoğraf + form + pill'den
///     oluşan afiş paneli — tabletin aynı büyütülmüş hali DEĞİL,
///     kompozisyon gerçekten ikiye ayrılıyor.
///
/// `BasePageWrapper` burada da bilerek kullanılmıyor (bkz.
/// `login_screen_web.dart` başındaki gerekçe). Mantık (Firebase Phone
/// Auth) ÖNCEKİ sürümle BİREBİR AYNI — sadece sunum değişti.
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

    final bool isDesktop = ResponsiveUtils.isDesktop(context);

    final formSlot = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (final child, final animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _isCodeSent
          ? _buildOtpUI(authMutation.isLoading)
          : _buildPhoneUI(authMutation.isLoading),
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
            const Positioned.fill(
              child: AuthStageBackdrop(
                glows: [
                  Positioned(
                    bottom: -180,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AuthAmbientGlow(
                          size: 460, tint: WebColors.primaryGold),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.section),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 460),
                    child: isDesktop
                        ? _WideSplit(
                            fade: _fade,
                            isCodeSent: _isCodeSent,
                            formSlot: formSlot,
                          )
                        : _StackedPoster(
                            fade: _fade,
                            isCodeSent: _isCodeSent,
                            formSlot: formSlot,
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.xl,
              left: AppSpacing.xl,
              child:
                  GlassmorphismBackButton(onPressed: _handleBack, size: 44),
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

  Widget _buildPhoneUI(final bool isLoading) => Column(
        key: const ValueKey('phone_ui'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhoneTextField(
            controller: _phoneController,
            onSubmitted: (final _) => _verifyPhone(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthFloatingPillCTA(
            label: 'KOD GÖNDER',
            icon: Icons.send_rounded,
            onTap: isLoading ? null : _verifyPhone,
          ),
        ],
      );

  Widget _buildOtpUI(final bool isLoading) {
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
        AuthFloatingPillCTA(
          label: 'DOĞRULA VE BAŞLA',
          icon: Icons.check_circle_outline_rounded,
          onTap: isLoading ? null : () => _signInWithOTP(),
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
              child: const Text('Numarayı Düzenle',
                  style: TextStyle(
                      fontSize: 13, decoration: TextDecoration.underline)),
            ),
            AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: canResend ? 1.0 : 0.4,
              child: TextButton(
                onPressed:
                    canResend && !isLoading ? () => _verifyPhone() : null,
                style: TextButton.styleFrom(
                    foregroundColor: WebColors.primaryGoldLight),
                child: const Text('Kodu Yeniden Gönder',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
        width: 48,
        height: 58,
        textStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: WebColors.whiteText),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: 1.5),
          boxShadow: shadow,
        ),
      );
}

/// Kullanıcının kendi seçimi (profil sayfasının misafir durumundaki aynı
/// "sahne/konser atmosferi" fotoğrafı) — artık referans afişteki gibi
/// kartın TAM-KANAMA fotoğraf bandında.
const String _stageImageUrl =
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1800&q=85';

/// DAR/TABLET — tek sütun, tek afiş kartı: başlık bandı + tam-kanama
/// fotoğraf, altında fotoğrafın alt kenarını bindiren form+pill bloğu.
class _StackedPoster extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool isCodeSent;
  final Widget formSlot;

  const _StackedPoster({
    required this.fade,
    required this.isCodeSent,
    required this.formSlot,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PosterCard(fade: fade, isCodeSent: isCodeSent, headlineSize: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              margin:
                  const EdgeInsets.only(top: -(AuthFloatingPillCTA.height / 2)),
              child: FadeTransition(opacity: fade(0.22), child: formSlot),
            ),
          ),
        ],
      );
}

/// GENİŞ MASAÜSTÜ — sol sütun saf tipografi (adım rozeti + başlık + alt
/// metin), sağ sütun SADECE fotoğraf + form + pill'den oluşan afiş paneli.
class _WideSplit extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool isCodeSent;
  final Widget formSlot;

  const _WideSplit({
    required this.fade,
    required this.isCodeSent,
    required this.formSlot,
  });

  @override
  Widget build(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: fade(0.0),
                  child: AuthStepChip(
                    icon: isCodeSent
                        ? Icons.mark_email_read_rounded
                        : Icons.security_rounded,
                    label: isCodeSent
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
                    isCodeSent
                        ? 'SON PERDE:\nKODU DOĞRULA.'
                        : 'NUMARANI PAYLAŞ,\nYERİNİ AYIRALIM.',
                    key: ValueKey(isCodeSent),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: WebColors.whiteText,
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(
                    isCodeSent
                        ? 'Telefonunuza gönderdiğimiz 6 haneli kodu girerek '
                            'perdeyi açın.'
                        : 'Biletinizi almak ve yerinizi seçmek için telefon '
                            'numaranızı girin.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: const AspectRatio(
                    aspectRatio: 0.8,
                    child: AuthHeroPoster(imageUrl: _stageImageUrl),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Container(
                    margin: const EdgeInsets.only(
                        top: -(AuthFloatingPillCTA.height / 2)),
                    child: formSlot,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

/// Referans görseldeki tek, büyük yuvarlak köşeli afiş kartı — dar/tablet
/// TEK-sütun yerleşiminde kullanılan sürüm.
class _PosterCard extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool isCodeSent;
  final double headlineSize;

  const _PosterCard({
    required this.fade,
    required this.isCodeSent,
    required this.headlineSize,
  });

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: WebColors.darkBlueSurface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                    AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: fade(0.0),
                      child: AuthStepChip(
                        icon: isCodeSent
                            ? Icons.mark_email_read_rounded
                            : Icons.security_rounded,
                        label: isCodeSent
                            ? 'ADIM 2 · DOĞRULAMA'
                            : 'ADIM 1 · İLETİŞİM',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      child: Text(
                        isCodeSent
                            ? 'SON PERDE:\nKODU DOĞRULA.'
                            : 'NUMARANI PAYLAŞ,\nYERİNİ AYIRALIM.',
                        key: ValueKey(isCodeSent),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          color: WebColors.whiteText,
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w700,
                          height: 1.14,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isCodeSent
                          ? 'Telefonunuza gönderdiğimiz 6 haneli kodu '
                              'girerek perdeyi açın.'
                          : 'Biletinizi almak ve yerinizi seçmek için '
                              'telefon numaranızı girin.',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: fade(0.1),
              child: const AspectRatio(
                aspectRatio: 1.5,
                child: AuthHeroPoster(imageUrl: _stageImageUrl),
              ),
            ),
          ],
        ),
      );
}

/// Telefon numarası alanı — ortalanmış, sade bir alt-çizgili giriş.
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
                  counterText: '',
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

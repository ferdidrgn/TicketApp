import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../widgets/auth_stage_widgets.dart';

/// TELEFON İLE GİRİŞ — `login_screen.dart` ile AYNI "Sahne Kapısı" dilini
/// paylaşır (`AuthStageScaffold`/`AuthCurtainStage`/`AuthHeadlineBlock`/
/// `AuthActionButton` — bkz. `auth_stage_widgets.dart`), böylece iki sayfa
/// arasında geçiş yaparken kompozisyon aniden değişmiyor: aynı sahne
/// paneli, aynı başlık tipografisi, aynı gradyanlı buton dili — sadece
/// içerik (form alanları) değişiyor. Gerçek OTP sayacı (`otpTimerProvider`)
/// ve doğrulama akışı (`_verificationId`, `verifyPhone`/`verifyOtp`)
/// BİREBİR AYNI kaldı, sadece görsel katman yenilendi.
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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
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
            // Not: Geri sayım gerçek zamanlayıcısı otpTimerProvider üzerinden
            // (auth_mutation_provider'daki onCodeSent) zaten başlatıldı; burada
            // sadece ekranı OTP adımına geçiriyoruz.
            setState(() => _isCodeSent = true);
          } else {
            // Zaten kod ekranındayız ve işlem başarılı olduysa -> Login bitti
            if (context.mounted) NavigationHandler.goToHome(context);
          }
        },
      );
    });

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        safeAreaTop: true,
        safeAreaBottom: false,
      ),
      child: PopScope(
        canPop: !_isCodeSent, // Kod ekranındaysak direkt çıkmasın
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          if (_isCodeSent) setState(() => _isCodeSent = false);
        },
        child: AuthStageScaffold(
          stagePanelBuilder: (final stageContext, final isLargeScreen) =>
              AuthCurtainStage(
            imagePath: 'assets/images/book_logo.jpg',
            borderRadius: AppRadius.asymLg,
            curtainColor: stageContext.colors.primary,
            overlay: isLargeScreen
                ? StageEditorialCaption(
                    eyebrow: 'Sahne Kapısı',
                    title: _isCodeSent
                        ? 'NEREDEYSE\nSAHNEDESİN'
                        : 'KİMLİĞİNİ\nDOĞRULA',
                    subtitle: _isCodeSent
                        ? 'Telefonuna gelen 6 haneli kodu gir, perde senin '
                            'için açılsın.'
                        : 'Telefon numaranla devam et — sana özel tek '
                            'kullanımlık bir kod gönderelim.',
                  )
                : StageBadge(
                    icon: _isCodeSent
                        ? Icons.mark_email_read_rounded
                        : Icons.phonelink_ring_rounded,
                    label: _isCodeSent ? 'KODU DOĞRULA' : 'TİYATROL',
                  ),
          ),
          headline: _buildHeaderText(context),
          formCard: _buildCard(context),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  /// `login_screen`'in `AuthHeadlineBlock`'unu bu adıma taşır; adım
  /// (telefon <-> OTP) değiştiğinde `AnimatedSwitcher` ile yumuşak geçer.
  Widget _buildHeaderText(final BuildContext context) => AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (final child, final animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: AuthHeadlineBlock(
          key: ValueKey(_isCodeSent),
          kicker: _isCodeSent ? 'Son Adım' : 'Sahne Kapısı',
          title: _isCodeSent ? 'KODU\nDOĞRULA' : 'SERÜVENE\nKATIL',
          subtitle: _isCodeSent
              ? 'Telefonuna gelen 6 haneli kodu gir.'
              : 'Kimliğini doğrula ve sanata başla...',
        ),
      );

  /// Eskiden bulanık cam kart (BackdropFilter) idi — artık düz, tema-uyumlu
  /// bir form paneli. İçerik (telefon/OTP adımı) yine `AnimatedSwitcher`
  /// ile geçiyor.
  Widget _buildCard(final BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.primary.withOpacity(0.14)),
          boxShadow: AppShadows.level2(context.colors.shadow),
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
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _isCodeSent ? _buildOtpUI() : _buildPhoneUI(),
        ),
      );

  Widget _buildPhoneUI() {
    return Column(
      key: const ValueKey('phone_ui'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconHeader(Icons.phonelink_ring_rounded),
        const SizedBox(height: AppSpacing.huge),
        _buildTextField(
          _phoneController,
          "5XX XXX XX XX",
          label: "TELEFON NUMARASI",
          prefix: "+90 ",
          isPhone: true,
          semanticLabel:
              'Telefon numarası girişi, başında sıfır olmadan on hane',
        ),
        const SizedBox(height: AppSpacing.xxxl),
        AuthActionButton(
          label: 'KOD GÖNDER',
          icon: Icons.send_rounded,
          semanticLabel: 'Doğrulama kodu gönder',
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
      children: [
        Semantics(
          label: canResend
              ? 'Kodun süresi doldu'
              : 'Kodun süresi dolmasına $remainingSeconds saniye kaldı',
          child: Text(
            timerText,
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: remainingSeconds < 10
                  ? context.colors.error
                  : context.colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionTitle("SMS KODUNU GİR"),
        const SizedBox(height: AppSpacing.huge),
        _buildTextField(
          _otpController,
          "000000",
          label: "6 HANELİ KOD",
          textAlign: TextAlign.center,
          maxLength: 6,
          semanticLabel: 'Doğrulama kodu, 6 haneli',
        ),
        const SizedBox(height: AppSpacing.xxxl),
        AuthActionButton(
          label: 'DOĞRULA VE BAŞLA',
          icon: Icons.check_circle_rounded,
          semanticLabel: 'Kodu doğrula ve giriş yap',
          useAsymCorner: true,
          onTap: _signInWithOTP,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: canResend ? 1.0 : 0.5,
          child: Semantics(
            button: true,
            enabled: canResend,
            label: 'Kodu yeniden gönder',
            child: TextButton(
              onPressed: canResend ? _verifyPhone : null,
              child: Text(
                "Kodu Yeniden Gönder",
                style: TextStyle(
                    color: context.colors.secondary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Telefon numarasını düzenle',
          child: TextButton(
            onPressed: () => setState(() => _isCodeSent = false),
            child: Text(
              "Numarayı Düzenle",
              style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.6),
                  fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconHeader(final IconData icon) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
          boxShadow: AppShadows.level2(context.colors.primary),
        ),
        child: Icon(icon, size: 48, color: context.colors.primary),
      );

  Widget _buildTextField(
    final TextEditingController controller,
    final String hint, {
    required final String label,
    required final String semanticLabel,
    final String? prefix,
    final TextAlign textAlign = TextAlign.start,
    final int? maxLength,
    final bool isPhone = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.sm, bottom: AppSpacing.sm),
            child: Text(label,
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.6),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Semantics(
            label: semanticLabel,
            textField: true,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: context.colors.onSurface.withOpacity(0.14)),
              ),
              child: TextField(
                controller: controller,
                textAlign: textAlign,
                keyboardType: TextInputType.number,
                maxLength: maxLength,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: context.colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: context.colors.onSurface.withOpacity(0.35)),
                  prefixText: prefix,
                  prefixStyle: TextStyle(
                      color: context.colors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold),
                  counterText: "",
                  // Sayacı gizle
                  contentPadding: const EdgeInsets.all(AppSpacing.xl),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildSectionTitle(final String title) => Text(
        title,
        style: TextStyle(
          color: context.colors.onSurface,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      );
}

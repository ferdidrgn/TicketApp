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
import '../providers/auth_provider.dart';
import '../widgets/animated_stage_motif.dart';
import '../widgets/auth_stage_widgets.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ EKRANI — `login_screen.dart` ile ortak mimari dil.
class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  _PendingAuthAction _pendingAction = _PendingAuthAction.none;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar(
          "Lütfen geçerli bir telefon numarası girin (Başında 0 olmadan)");
      return;
    }

    final formattedPhone = phone.startsWith("+90") ? phone : "+90$phone";
    _pendingAction = _PendingAuthAction.sendCode;
    await ref.read(authMutationProvider.notifier).verifyPhone(formattedPhone);
  }

  Future<void> _signInWithOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar("Lütfen 6 haneli kodu eksiksiz girin");
      return;
    }
    _pendingAction = _PendingAuthAction.verifyCode;
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

    ref.listen<AsyncValue<void>>(authMutationProvider,
        (final previous, final next) {
      next.whenOrNull(
        error: (final error, final stack) {
          _showSnackBar("Hata: ${error.toString()}");
        },
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
        canPop: !_isCodeSent,
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          if (_isCodeSent) setState(() => _isCodeSent = false);
        },
        child: AuthStageScaffold(
          stagePanelBuilder: (final stageContext, final isLargeScreen) =>
              AuthCurtainStage(
            revealChild: const AnimatedStageMotif(),
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

  Widget _buildCard(final BuildContext context) => AuthFormPanel(
        eyebrowIcon: _isCodeSent
            ? Icons.mark_email_read_rounded
            : Icons.phonelink_ring_rounded,
        eyebrowLabel: _isCodeSent ? 'Kodu Doğrula' : 'Telefon Doğrulama',
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.standard,
          transitionBuilder: (final child, final animation) => FadeTransition(
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
          color: context.colors.primary.withOpacity(0.12),
          shape: BoxShape.circle,
          boxShadow: AppShadows.level2(context.colors.primary),
        ),
        child: Icon(icon, size: 40, color: context.colors.primary),
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
                color: context.colors.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: context.colors.onSurface.withOpacity(0.12)),
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
                      color: context.colors.onSurface.withOpacity(0.3)),
                  prefixText: prefix,
                  prefixStyle: TextStyle(
                      color: context.colors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold),
                  counterText: "",
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../providers/auth_mutation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_ticket.dart';
import '../widgets/login_ticket_content.dart';
import '../widgets/phone_ticket_content.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFONLA GİRİŞ — MOBİL. Aynı bilet, bu kez doldurulan bir bilet:
/// 1) numara yazıldıkça koçana "SAHİBİ" olarak basılır, 2) kod gönderilince
/// bilete damga vurulur ve SMS kodu sahneye bakan bir koltuk sırasına
/// girilir, 3) doğrulamada koçan yırtılır; hata olursa geri yapışır.
class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  _PendingAuthAction _pendingAction = _PendingAuthAction.none;

  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final AnimationController _headline =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final AnimationController _stamp =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);

  late final Animation<double> _ticketIn =
      CurvedAnimation(parent: _entrance, curve: AppMotion.standard);
  late final Animation<double> _details = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.5, 1.0, curve: AppMotion.standard));
  late final Animation<double> _headlineReveal =
      CurvedAnimation(parent: _headline, curve: AppMotion.dramatic);
  late final Animation<double> _stampCurve =
      CurvedAnimation(parent: _stamp, curve: AppMotion.standard);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  bool _started = false;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _entrance.value = 1;
      _headline.value = 1;
    } else {
      _entrance.forward();
      _headline.forward();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _entrance.dispose();
    _headline.dispose();
    _stamp.dispose();
    _tear.dispose();
    super.dispose();
  }

  void _play(final AnimationController c) {
    if (_reduceMotion) {
      c.value = 1;
    } else {
      c.forward(from: 0);
    }
  }

  void _setCodeSent(final bool value) {
    setState(() => _isCodeSent = value);
    _play(_headline);
    if (value) {
      _otpController.clear();
      _play(_stamp);
    } else {
      _stamp.value = 0;
      _tear.value = 0;
    }
  }

  void _handleBack() {
    if (_isCodeSent) {
      _setCodeSent(false);
    } else {
      NavigationHandler.smartGoBack(context);
    }
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showSnackBar(
          'Numaranı başında 0 olmadan 10 hane olarak gir (5XX XXX XX XX).',
          isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.sendCode;
    await ref.read(authMutationProvider.notifier).verifyPhone('+90$phone');
  }

  Future<void> _signInWithOTP([final String? pin]) async {
    final otp = (pin ?? _otpController.text).trim();
    if (otp.length != 6) {
      _showSnackBar('Lütfen 6 haneli kodu eksiksiz gir.', isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.verifyCode;
    if (!_reduceMotion) _tear.forward(from: 0);
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
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final auth = ref.watch(authMutationProvider);
    final int remaining = ref.watch(otpTimerProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider, (final prev, final next) {
      next.whenOrNull(
        error: (final error, final _) {
          _showSnackBar('Hata: $error', isError: true);
          _tear.reverse();
          _pendingAction = _PendingAuthAction.none;
        },
        data: (final _) {
          switch (_pendingAction) {
            case _PendingAuthAction.sendCode:
              if (ref.read(isLoggedInProvider)) {
                if (context.mounted) NavigationHandler.goToHome(context);
              } else {
                _setCodeSent(true);
              }
            case _PendingAuthAction.verifyCode:
              if (context.mounted) NavigationHandler.goToHome(context);
            case _PendingAuthAction.none:
              break;
          }
          _pendingAction = _PendingAuthAction.none;
        },
      );
    });

    // BasePageWrapper KULLANILMIYOR (bkz. login_screen_mobile.dart): temanın
    // açık üst şeridi koyu sahneyle çakışıyordu.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: WebColors.darkBlueBackground,
          body: TicketStage(
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.section, AppSpacing.lg, AppSpacing.section),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FadeTransition(
                                opacity: _ticketIn,
                                child: const BoxOfficeCaption(
                                    text: 'BİLETİN BASILIYOR'),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedBuilder(
                                animation: _ticketIn,
                                builder: (final context, final child) =>
                                    Opacity(
                                  opacity: _ticketIn.value,
                                  child: Transform.translate(
                                    offset:
                                        Offset(0, (1 - _ticketIn.value) * 56),
                                    child: child,
                                  ),
                                ),
                                child: AdmitTicket(
                                  direction: Axis.vertical,
                                  tear: _tearCurve,
                                  body: PhoneTicketBody(
                                    wide: false,
                                    isCodeSent: _isCodeSent,
                                    headlineReveal: _headlineReveal,
                                    detailsFade: _details,
                                    stamp: _stampCurve,
                                    phoneController: _phoneController,
                                    otpController: _otpController,
                                    onSendCode: _verifyPhone,
                                    onVerify: _signInWithOTP,
                                    onEditNumber: () => _setCodeSent(false),
                                    onResend:
                                        remaining <= 0 ? _verifyPhone : null,
                                    timerText: otpTimerText(remaining),
                                    loading: auth.isLoading,
                                  ),
                                  stub: PhoneTicketStub(
                                    wide: false,
                                    isCodeSent: _isCodeSent,
                                    phoneController: _phoneController,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.lg,
                    child: Semantics(
                      label: _isCodeSent ? 'Numarayı düzenle' : 'Geri dön',
                      button: true,
                      child: GlassmorphismBackButton(
                        onPressed: _handleBack,
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

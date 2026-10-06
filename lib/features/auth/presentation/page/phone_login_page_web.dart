import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../providers/auth_mutation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_ticket.dart';
import '../widgets/login_ticket_content.dart';
import '../widgets/phone_ticket_content.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFONLA GİRİŞ — WEB. Masaüstünde perdeli sahnede YATAY bilet (solda
/// başlık, sağda form, koçan en sağda); tablet/dar pencerede DİKEY bilet.
/// Kendi `Scaffold`'u var (Material atası olmadan TextField çöker).
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
    if (ref.read(authMutationProvider).isLoading) return;
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      authHapticSelection();
      _showSnackBar(
          'Numaranı başında 0 olmadan 10 hane olarak gir (5XX XXX XX XX).',
          isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.sendCode;
    await ref.read(authMutationProvider.notifier).verifyPhone('+90$phone');
  }

  Future<void> _signInWithOTP([final String? pin]) async {
    if (ref.read(authMutationProvider).isLoading) return;
    final otp = (pin ?? _otpController.text).trim();
    if (otp.length != 6) {
      authHapticSelection();
      _showSnackBar('Lütfen 6 haneli kodu eksiksiz gir.', isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.verifyCode;
    await _tearStub();
    await ref.read(authMutationProvider.notifier).verifyOtp(otp);
  }

  Future<void> _tearStub() async {
    if (!_reduceMotion) await _tear.forward(from: 0);
  }

  void _showSnackBar(final String msg, {final bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      showAuthErrorSnackBar(context, message: msg, width: 440);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        width: 440,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  void _showAuthFailure(final Object error, final _PendingAuthAction pending) {
    final VoidCallback? retry = switch (pending) {
      _PendingAuthAction.sendCode => _verifyPhone,
      _PendingAuthAction.verifyCode => () => _signInWithOTP(),
      _ => null,
    };
    showAuthErrorSnackBar(
      context,
      message: authErrorMessage(error),
      width: 440,
      onRetry: retry,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final auth = ref.watch(authMutationProvider);
    final int remaining = ref.watch(otpTimerProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider, (final prev, final next) {
      next.whenOrNull(
        error: (final error, final _) {
          _tear.reverse();
          final pending = _pendingAction;
          _pendingAction = _PendingAuthAction.none;
          _showAuthFailure(error, pending);
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

    final bool wide = ResponsiveUtils.isDesktop(context);
    final bool tablet = ResponsiveUtils.isTablet(context);
    final double maxWidth = wide ? 1080 : (tablet ? 500 : 440);

    final Widget ticket = AdmitTicket(
      direction: wide ? Axis.horizontal : Axis.vertical,
      tear: _tearCurve,
      stubExtent: 220,
      body: PhoneTicketBody(
        wide: wide,
        isCodeSent: _isCodeSent,
        headlineReveal: _headlineReveal,
        detailsFade: _details,
        stamp: _stampCurve,
        phoneController: _phoneController,
        otpController: _otpController,
        onSendCode: _verifyPhone,
        onVerify: _signInWithOTP,
        onEditNumber: () => _setCodeSent(false),
        onResend: remaining <= 0 ? _verifyPhone : null,
        timerText: otpTimerText(remaining),
        loading: auth.isLoading,
      ),
      stub: PhoneTicketStub(
        wide: wide,
        isCodeSent: _isCodeSent,
        phoneController: _phoneController,
      ),
    );

    return PopScope(
      canPop: !_isCodeSent,
      onPopInvokedWithResult: (final didPop, final result) {
        if (!didPop && _isCodeSent) _setCodeSent(false);
      },
      child: Scaffold(
        backgroundColor: WebColors.darkBlueBackground,
        body: TicketStage(
          showCurtains: wide,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? AppSpacing.section : AppSpacing.lg,
                      vertical: AppSpacing.section,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeTransition(
                            opacity: _ticketIn,
                            child: const BoxOfficeCaption(
                                text: 'BİLETİN BASILIYOR'),
                          ),
                          SizedBox(
                              height:
                                  wide ? AppSpacing.xxxl : AppSpacing.lg),
                          AnimatedBuilder(
                            animation: _ticketIn,
                            builder: (final context, final child) => Opacity(
                              opacity: _ticketIn.value,
                              child: Transform.translate(
                                offset:
                                    Offset(0, (1 - _ticketIn.value) * 56),
                                child: child,
                              ),
                            ),
                            child: ticket,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
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
    );
  }
}

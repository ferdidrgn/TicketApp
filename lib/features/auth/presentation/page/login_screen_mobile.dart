import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../providers/auth_mutation_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_ticket.dart';
import '../widgets/login_ticket_content.dart';

enum _LoginAuthAction { none, google, guest }

/// GİRİŞ — MOBİL. "Bilet gişesi": karanlık sahnede spot altında duran
/// fiziksel bir bilet; giriş yöntemleri biletin üstüne basılı, birincil
/// aksiyonda koçan yırtılır.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);

  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: AppMotion.standard));
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 0.9, curve: AppMotion.dramatic));
  late final Animation<double> _details = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1.0, curve: AppMotion.standard));
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  bool _started = false;
  bool _routeBusy = false;
  _LoginAuthAction _authAction = _LoginAuthAction.none;
  bool _guestLoading = false;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _tear.dispose();
    super.dispose();
  }

  Future<void> _tearStub() async {
    if (!_reduceMotion) await _tear.forward(from: 0);
  }

  bool get _authBusy =>
      ref.read(authMutationProvider).isLoading || _guestLoading || _routeBusy;

  Future<void> _goPhone() async {
    if (_authBusy) return;
    authHapticLight();
    setState(() => _routeBusy = true);
    await _tearStub();
    if (!mounted) return;
    setState(() => _routeBusy = false);
    NavigationHandler.goToPhoneLogin(context);
  }

  Future<void> _google() async {
    if (_authBusy) return;
    setState(() => _authAction = _LoginAuthAction.google);
    final tearing = _tearStub();
    await ref.read(authMutationProvider.notifier).signInWithGoogle();
    await tearing;
    if (!mounted) return;
    if (!ref.read(isLoggedInProvider)) _tear.reverse();
    if (_authAction == _LoginAuthAction.google) {
      setState(() => _authAction = _LoginAuthAction.none);
    }
  }

  Future<void> _guest() async {
    if (_authBusy) return;
    authHapticSelection();
    setState(() {
      _authAction = _LoginAuthAction.guest;
      _guestLoading = true;
    });
    final tearing = _tearStub();
    try {
      await ref.read(signInAnonymouslyUseCaseProvider).call().getOrThrow();
      ref.invalidate(authStateProvider);
      if (mounted) NavigationHandler.goToHome(context);
    } catch (e) {
      if (mounted) {
        showAuthErrorSnackBar(
          context,
          message: authErrorMessage(e),
          onRetry: _guest,
        );
      }
    } finally {
      await tearing;
      if (mounted) {
        _tear.reverse();
        setState(() {
          _guestLoading = false;
          _authAction = _LoginAuthAction.none;
        });
      }
    }
  }

  void _showAuthFailure(final Object error) {
    final VoidCallback? retry = switch (_authAction) {
      _LoginAuthAction.google => _google,
      _LoginAuthAction.guest => _guest,
      _ => null,
    };
    showAuthErrorSnackBar(
      context,
      message: authErrorMessage(error),
      onRetry: retry,
    );
    setState(() => _authAction = _LoginAuthAction.none);
  }

  @override
  Widget build(final BuildContext context) {
    final auth = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider, (final prev, final next) {
      next.whenOrNull(
        error: (final error, final _) {
          _tear.reverse();
          _showAuthFailure(error);
        },
        data: (final _) {
          if (_authAction != _LoginAuthAction.google) return;
          if (!ref.read(isLoggedInProvider)) {
            _tear.reverse();
            setState(() => _authAction = _LoginAuthAction.none);
            return;
          }
          if (context.mounted) NavigationHandler.goToHome(context);
        },
      );
    });

    // BasePageWrapper KULLANILMIYOR: o, arkaya temanın açık zeminini ve
    // üst başlığını çiziyor; koyu bilet sahnesiyle çakışıp ekranın üstünde
    // açık renkli bir şerit bırakıyordu. Sahne durum çubuğuna kadar uzanır.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (!didPop) NavigationHandler.smartGoBack(context);
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
                          AppSpacing.sm, AppSpacing.lg, AppSpacing.section),
                      child: Center(
                        // Büyük tablet ekranında bilet gerilmesin; gerçek bir
                        // bilet boyutunda kalıp ortalansın.
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Geri butonu biletle birlikte kayar; eskiden
                              // sabit katmanda durup kaydırınca biletin
                              // başlığının üstüne biniyordu.
                              Row(
                                children: [
                                  Semantics(
                                    label: 'Geri dön',
                                    button: true,
                                    child: GlassmorphismBackButton(
                                      onPressed: () => NavigationHandler.smartGoBack(context),
                                      size: 44,
                                    ),
                                  ),
                                  Expanded(
                                    child: FadeTransition(
                                      opacity: _ticketIn,
                                      child: const BoxOfficeCaption(),
                                    ),
                                  ),
                                  const SizedBox(width: 44),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedBuilder(
                                animation: _ticketIn,
                                builder: (final context, final child) =>
                                    Opacity(
                                  opacity: _ticketIn.value,
                                  child: Transform.translate(
                                    // Bilet gişe camının altından uzatılıyormuş gibi.
                                    offset:
                                        Offset(0, (1 - _ticketIn.value) * 56),
                                    child: child,
                                  ),
                                ),
                                child: AdmitTicket(
                                  direction: Axis.vertical,
                                  tear: _tearCurve,
                                  body: LoginTicketBody(
                                    wide: false,
                                    headlineReveal: _headline,
                                    detailsFade: _details,
                                    loadingGoogle: auth.isLoading &&
                                        _authAction ==
                                            _LoginAuthAction.google,
                                    loadingGuest: _guestLoading,
                                    actionLocked: _routeBusy,
                                    onPhone: _goPhone,
                                    onGoogle: _google,
                                    onGuest: _guest,
                                  ),
                                  stub: const LoginTicketStub(wide: false),
                                ),
                              ),
                            ],
                          ),
                        ),
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

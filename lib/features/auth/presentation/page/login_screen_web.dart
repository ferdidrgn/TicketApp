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
import '../widgets/auth_ticket.dart';
import '../widgets/login_ticket_content.dart';

/// GİRİŞ — WEB. Masaüstünde (≥1024) iki yanında perdeler olan bir sahnede
/// YATAY bilet (koçan sağda); tablet ve dar pencerede DİKEY bilet.
///
/// `BasePageWrapper` kullanılmadığı için sayfa kendi `Scaffold`'unu kurar —
/// TextField/InkWell gibi widget'lar bir Material atası olmadan çöker ve
/// metinler sarı çift alt çizgiyle görünür.
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

  Future<void> _goPhone() async {
    await _tearStub();
    if (!mounted) return;
    NavigationHandler.goToPhoneLogin(context);
  }

  Future<void> _google() async {
    final tearing = _tearStub();
    await ref.read(authMutationProvider.notifier).signInWithGoogle();
    await tearing;
    if (mounted) _tear.reverse();
  }

  void _showError(final String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        width: 440,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final auth = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider, (final prev, final next) {
      next.whenOrNull(
        error: (final error, final _) {
          _showError(error.toString());
          _tear.reverse();
        },
        data: (final _) {
          if (context.mounted) NavigationHandler.goToHome(context);
        },
      );
    });

    final bool wide = ResponsiveUtils.isDesktop(context);
    final bool tablet = ResponsiveUtils.isTablet(context);
    final double maxWidth = wide ? 1040 : (tablet ? 500 : 440);

    final Widget ticket = AdmitTicket(
      direction: wide ? Axis.horizontal : Axis.vertical,
      tear: _tearCurve,
      stubExtent: 220,
      body: LoginTicketBody(
        wide: wide,
        headlineReveal: _headline,
        detailsFade: _details,
        loading: auth.isLoading,
        onPhone: _goPhone,
        onGoogle: _google,
      ),
      stub: LoginTicketStub(wide: wide),
    );

    return Scaffold(
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
                          child: const BoxOfficeCaption(),
                        ),
                        SizedBox(
                            height: wide ? AppSpacing.xxxl : AppSpacing.lg),
                        AnimatedBuilder(
                          animation: _ticketIn,
                          builder: (final context, final child) => Opacity(
                            opacity: _ticketIn.value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - _ticketIn.value) * 56),
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
                label: 'Geri dön',
                button: true,
                child: GlassmorphismBackButton(
                  onPressed: () => NavigationHandler.smartGoBack(context),
                  size: 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

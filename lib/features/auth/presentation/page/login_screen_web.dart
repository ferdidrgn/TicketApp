import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../providers/auth_mutation_provider.dart';
import '../widgets/auth_ticket.dart';
import '../widgets/login_ticket_content.dart';

/// GİRİŞ — WEB. Masaüstünde (≥1024) solda "hesabınla neler yaparsın" paneli,
/// sağda DİKEY giriş bileti; tablet ve dar pencerede yalnız bilet. Zemin
/// temanın kendi yüzeyi (5 tema); perde/spot süsü yok.
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

    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool wide = ResponsiveUtils.isDesktop(context);
    final bool tablet = ResponsiveUtils.isTablet(context);
    final double ticketWidth = wide ? 480 : (tablet ? 500 : 440);

    // Geniş ekranda da dikey bilet: yanındaki değer paneli "neden giriş"
    // sorusunu cevaplar; yatay bilet + perdeler kaldırıldı (tema zemini).
    final Widget ticket = AdmitTicket(
      direction: Axis.vertical,
      tear: _tearCurve,
      shadows: AppShadows.level3(cs.shadow),
      body: LoginTicketBody(
        wide: false,
        headlineReveal: _headline,
        detailsFade: _details,
        loading: auth.isLoading,
        onPhone: _goPhone,
        onGoogle: _google,
      ),
      stub: const LoginTicketStub(wide: false),
    );

    final Widget animatedTicket = AnimatedBuilder(
      animation: _ticketIn,
      builder: (final context, final child) => Opacity(
        opacity: _ticketIn.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _ticketIn.value) * 32),
          child: child,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ticketWidth),
        child: ticket,
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => NavigationHandler.smartGoBack(context),
              onHome: () => NavigationHandler.goToHome(context),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? AppSpacing.section : AppSpacing.lg,
                    vertical: AppSpacing.xxl,
                  ),
                  child: wide
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FadeTransition(
                                  opacity: _details,
                                  child: const _LoginPerks(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.section),
                              animatedTicket,
                            ],
                          ),
                        )
                      : animatedTicket,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;
  const _TopBar({required this.onBack, required this.onHome});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri dön',
            onPressed: onBack,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            link: true,
            label: 'TiyatRol ana sayfa',
            excludeSemantics: true,
            child: InkWell(
              onTap: onHome,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                child: Text('TİYATROL',
                    style: GoogleFonts.playfairDisplay(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Geniş ekranda biletin yanındaki "hesabınla neler yaparsın" paneli. Yalnız
/// uygulamada gerçekten var olan özellikler anlatılır.
class _LoginPerks extends StatelessWidget {
  const _LoginPerks();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget perk(final IconData icon, final String title, final String body) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14.5,
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.local_activity_outlined, size: 16, color: cs.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('GİŞE AÇIK',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text('Hesabınla biletin\nhep yanında.',
              style: GoogleFonts.playfairDisplay(
                  color: cs.onSurface,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1.08)),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        perk(Icons.qr_code_2_rounded, 'QR kodlu biletlerin',
            'Aldığın biletler Biletlerim sayfasında; girişte QR kodu göster.'),
        perk(Icons.favorite_border_rounded, 'Favorilerin kenarda',
            'Oyunları, sahneleri ve sanatçıları kaydet; seansları takip et.'),
        perk(Icons.event_available_outlined, 'Takvim ve yol tarifi',
            'Seansı takvimine ekle, sahneye giden yolu tek dokunuşla aç.'),
      ],
    );
  }
}

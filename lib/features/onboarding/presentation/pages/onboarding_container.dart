import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/ticket/ticket_kit.dart';

/// Bir tanıtım adımı: gerçek bir sıra (bul → seç → al), bu yüzden
/// numaralı.
class _OnboardingStep {
  final String kind;
  final String title;
  final String message;
  final IconData icon;

  const _OnboardingStep({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
  });
}

/// Uygulamanın gerçekte yaptığı üç iş — başka bir şey vaat edilmiyor.
const List<_OnboardingStep> _kSteps = [
  _OnboardingStep(
    kind: 'KEŞFET',
    title: 'Oyunu bul',
    message:
        'Sahnelerde ne oynuyor, tek yerde gör: oyunlar, topluluklar, '
        'oyuncular ve sahneler.',
    icon: Icons.explore_rounded,
  ),
  _OnboardingStep(
    kind: 'SEANS',
    title: 'Seansını seç',
    message:
        'Tarihe ve saate göre seansları karşılaştır; Yakındakiler ile '
        'sana en yakın sahneleri haritada bul.',
    icon: Icons.event_rounded,
  ),
  _OnboardingStep(
    kind: 'BİLET',
    title: 'Koltuğunu al',
    message:
        'Koltuk planından yerini seç; biletin QR koduyla Biletlerim\'de '
        'hazır. Bazı oyunların biletleri resmi satış sitesinde — seni '
        'oraya yönlendiririz.',
    icon: Icons.confirmation_number_rounded,
  ),
];

/// ONBOARDING — "bilet dili".
///
/// Karanlık sahnede (giriş ekranı gibi bir "an") tek bir fiziksel bilet:
/// gövdesinde adımın başlığı ve açıklaması, koçanında adım numarası + TEK
/// birincil aksiyon (damga butonu). Son adımda koçan yırtılır ve ana
/// sayfaya geçilir. Her adımda sağ üstte "Atla" var; Android geri tuşu /
/// "Geri" bir önceki adıma döner.
///
/// Yönlendirme mantığı korunuyor: tamamlanınca (ve atlanınca)
/// `NavigationHandler.goToHome`. Eski konfeti ve 7.7MB'lık
/// `main_theatre.png` arka planı kaldırıldı.
class OnboardingContainer extends ConsumerStatefulWidget {
  const OnboardingContainer({super.key});

  @override
  ConsumerState<OnboardingContainer> createState() =>
      _OnboardingContainerState();
}

class _OnboardingContainerState extends ConsumerState<OnboardingContainer>
    with TickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final AnimationController _headline =
      AnimationController(vsync: this, duration: AppMotion.normal);
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);

  late final Animation<double> _ticketIn =
      CurvedAnimation(parent: _entrance, curve: AppMotion.standard);
  late final Animation<double> _headlineCurve =
      CurvedAnimation(parent: _headline, curve: AppMotion.dramatic);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  int _step = 0;
  bool _started = false;
  bool _leaving = false;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;
  bool get _isLast => _step == _kSteps.length - 1;

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
    _entrance.dispose();
    _headline.dispose();
    _tear.dispose();
    super.dispose();
  }

  void _goTo(final int step) {
    if (step < 0 || step >= _kSteps.length || step == _step) return;
    HapticFeedback.selectionClick();
    setState(() => _step = step);
    if (_reduceMotion) {
      _headline.value = 1;
    } else {
      _headline.forward(from: 0);
    }
  }

  // Onboarding'in tamamlandığı TEK an: koçan yırtılır, ana sayfaya geçilir.
  Future<void> _completeOnboarding() async {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();
    if (!_reduceMotion) await _tear.forward(from: 0);
    if (!mounted) return;
    NavigationHandler.goToHome(context);
  }

  void _skip() {
    if (_leaving) return;
    _leaving = true;
    NavigationHandler.goToHome(context);
  }

  void _onPrimary() {
    if (_isLast) {
      _completeOnboarding();
    } else {
      _goTo(_step + 1);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 768;
    final _OnboardingStep step = _kSteps[_step];

    final Widget ticket = AdmitTicket(
      direction: wide ? Axis.horizontal : Axis.vertical,
      stubExtent: 240,
      tear: _tearCurve,
      body: _StepBody(
        step: step,
        index: _step,
        headline: _headlineCurve,
      ),
      stub: _StepStub(
        index: _step,
        count: _kSteps.length,
        primaryLabel: _isLast ? 'Keşfetmeye başla' : 'Devam',
        onPrimary: _onPrimary,
        onBack: _step > 0 ? () => _goTo(_step - 1) : null,
        wide: wide,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (didPop) return;
          if (_step > 0) {
            _goTo(_step - 1);
          } else {
            NavigationHandler.smartGoBack(context);
          }
        },
        child: Scaffold(
          backgroundColor: WebColors.darkBlueBackground,
          body: TicketStage(
            child: SafeArea(
              child: Column(
                children: [
                  // Üst satır: marka + Atla (her adımda).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.sm, AppSpacing.sm, 0),
                    child: Row(
                      children: [
                        Text(
                          'TİYATROL',
                          style: GoogleFonts.playfairDisplay(
                            color: TicketInk.paper,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: TicketInk.paper,
                            minimumSize: const Size(64, 48),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                          ),
                          child: const Text(
                            'Atla',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      // Kaydırma jesti — butonların kısayolu, tek yol değil.
                      onHorizontalDragEnd: (final d) {
                        final double v = d.primaryVelocity ?? 0;
                        if (v < -250 && !_isLast) _goTo(_step + 1);
                        if (v > 250) _goTo(_step - 1);
                      },
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                              AppSpacing.xl, AppSpacing.lg, AppSpacing.huge),
                          child: SizedBox(
                            width: wide ? 680 : 400,
                            child: AnimatedBuilder(
                              animation: _ticketIn,
                              builder: (final context, final child) => Opacity(
                                opacity: _ticketIn.value,
                                child: Transform.translate(
                                  offset:
                                      Offset(0, (1 - _ticketIn.value) * 48),
                                  child: child,
                                ),
                              ),
                              child: ticket,
                            ),
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

class _StepBody extends StatelessWidget {
  final _OnboardingStep step;
  final int index;
  final Animation<double> headline;

  const _StepBody({
    required this.step,
    required this.index,
    required this.headline,
  });

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TicketHeaderStrip(kind: step.kind),
          const SizedBox(height: AppSpacing.xxl),
          Icon(step.icon, size: 28, color: accent),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            // Align: sütun "stretch" iken sıkı genişlik perde açılışını
            // (widthFactor) etkisiz bırakırdı.
            child: Align(
              alignment: Alignment.centerLeft,
              child: AuthWipeReveal(
                reveal: headline,
                child: Text(step.title, style: TicketInk.headline(34)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            layoutBuilder: (final current, final previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              step.message,
              key: ValueKey(index),
              style: TextStyle(
                color: TicketInk.inkSoft(0.75),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepStub extends StatelessWidget {
  final int index;
  final int count;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;
  final bool wide;

  const _StepStub({
    required this.index,
    required this.count,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
    required this.wide,
  });

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    final String number = '${index + 1}'.padLeft(2, '0');
    final String total = '$count'.padLeft(2, '0');

    final Widget progress = Semantics(
      label: 'Adım ${index + 1} / $count',
      excludeSemantics: true,
      child: Row(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                height: 3,
                color: i <= index ? accent : TicketInk.inkSoft(0.15),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TicketField(label: 'ADIM', value: '$number / $total'),
              ),
              if (onBack != null)
                TicketTextLink(label: 'Geri', onTap: onBack),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          progress,
          SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.xl),
          TicketStampButton(label: primaryLabel, onTap: onPrimary),
        ],
      ),
    );
  }
}

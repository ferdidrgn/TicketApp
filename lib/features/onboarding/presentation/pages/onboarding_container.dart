import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/onboarding_gate.dart';

/// ONBOARDING — "Oyun programı".
///
/// Tanıtım bir tiyatro programı gibi üç perdeden oluşur; her perdede
/// uygulamanın GERÇEK bir parçası durur (vaat değil, gösterim):
///   I.   Oyunu bul       → Firebase'deki gerçek afişler yelpaze gibi açılır
///   II.  Koltuğunu seç   → küçük bir koltuk sırası, bir koltuk seçilir
///   III. Sahneni seç     → tema seçici CANLI: dokununca bütün ekran o
///                          temaya geçer (5 tema + özel renk)
/// Son perdede tek birincil aksiyon "Perdeyi aç" → ana sayfa.
///
/// Zemin temanın kendi yüzeyi (sabit karanlık sahne değil) — III. perdede
/// tema değişimi tüm sayfada anında görülsün diye. Her yerde "Geç" var;
/// geri tuşu bir önceki perdeye döner. Tanıtım cihazda bir kez gösterilir
/// ([OnboardingGate]); tamamlanınca da atlanınca da işaretlenir.
///
/// - Mobil (`context.isMobile`): dikey — üstte gösterim, altta metin + aksiyon.
/// - Tablet / geniş (`!isMobile`): iki sütun, `ConstrainedBox` ile ortalanmış.
class OnboardingContainer extends ConsumerStatefulWidget {
  const OnboardingContainer({super.key});

  @override
  ConsumerState<OnboardingContainer> createState() =>
      _OnboardingContainerState();
}

class _Act {
  final String numeral;
  final String title;
  final String message;
  const _Act(this.numeral, this.title, this.message);
}

const List<_Act> _acts = [
  _Act(
    'I. PERDE',
    'Oyunu bul',
    'Şehrin sahnelerinde bu sezon ne oynuyor, tek yerde gör: oyunlar, '
        'topluluklar, oyuncular ve sahneler.',
  ),
  _Act(
    'II. PERDE',
    'Koltuğunu seç',
    'Seansını seç, salon planından yerini al. Biletin telefonunda, '
        'kapıda okutman yeter.',
  ),
  _Act(
    'III. PERDE',
    'Sahneni seç',
    'Uygulamanın renklerini şimdi seç — dokunduğun an her şey değişir. '
        'Sonra Profil > Görünüm\'den istediğin zaman değiştirebilirsin.',
  ),
];

class _OnboardingContainerState extends ConsumerState<OnboardingContainer>
    with TickerProviderStateMixin {
  /// Her perdenin açılış anı: başlık soldan sağa açılır, gösterim oynar.
  late final AnimationController _act =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline = CurvedAnimation(
      parent: _act, curve: const Interval(0, 0.7, curve: AppMotion.dramatic));
  late final Animation<double> _scene = CurvedAnimation(
      parent: _act, curve: const Interval(0.15, 1, curve: AppMotion.standard));

  int _index = 0;
  bool _started = false;
  bool _leaving = false;

  bool get _reduce => MediaQuery.of(context).disableAnimations;
  bool get _isLast => _index == _acts.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void dispose() {
    _act.dispose();
    super.dispose();
  }

  void _play() {
    if (_reduce) {
      _act.value = 1;
    } else {
      _act.forward(from: 0);
    }
  }

  void _goTo(final int i) {
    if (i < 0 || i >= _acts.length || i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _play();
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();
    await OnboardingGate.markSeen();
    if (mounted) NavigationHandler.goToHome(context);
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen(themeProvider, (final prev, final next) {
      if (_index == 2 && prev != null && prev != next) {
        HapticFeedback.selectionClick();
      }
    });
    ref.listen(customAccentColorProvider, (final prev, final next) {
      if (_index == 2 && prev != next) {
        HapticFeedback.selectionClick();
      }
    });

    final cs = Theme.of(context).colorScheme;
    final bool mobile = context.isMobile;
    final _Act act = _acts[_index];
    final double titleSize = context.responsive(
      mobile: 36,
      tablet: 42,
      desktop: 48,
    );

    final Widget scene = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      switchOutCurve: const Threshold(0),
      child: KeyedSubtree(
        key: ValueKey(_index),
        child: switch (_index) {
          0 => _PosterFan(appear: _scene),
          1 => _SeatRow(appear: _scene),
          _ => const _ThemeStage(),
        },
      ),
    );

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          act.numeral,
          style: TextStyle(
            color: cs.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: AuthWipeReveal(
            reveal: _headline,
            child: Text(
              act.title,
              maxLines: 1,
              style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: AppMotion.normal,
          switchOutCurve: const Threshold(0),
          child: Text(
            act.message,
            key: ValueKey(_index),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: context.bodySize,
              height: 1.5,
            ),
          ),
        ),
      ],
    );

    final Widget controls = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!_isLast)
          Semantics(
            button: true,
            label: 'Tanıtımı geç',
            excludeSemantics: true,
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                minimumSize: const Size(72, 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              child: const Text(
                'Geç',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        const SizedBox(width: AppSpacing.sm),
        _ActProgress(index: _index, count: _acts.length, onTap: _goTo),
        const Spacer(),
        FilledButton.icon(
          onPressed: _isLast ? _finish : () => _goTo(_index + 1),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
          icon: Icon(_isLast
              ? Icons.theater_comedy_rounded
              : Icons.arrow_forward_rounded),
          label: Text(_isLast ? 'Perdeyi aç' : 'Devam'),
        ),
      ],
    );

    final Widget topBar = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'TİYATROL',
          style: GoogleFonts.playfairDisplay(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
    );

    final Widget body = mobile
        ? Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.pagePadding.left,
                    AppSpacing.lg,
                    context.pagePadding.right,
                    0,
                  ),
                  child: scene,
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.pagePadding.left,
                    AppSpacing.xl,
                    context.pagePadding.right,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      text,
                      const SizedBox(height: AppSpacing.xxl),
                      controls,
                    ],
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.responsive(
                  mobile: double.infinity,
                  tablet: 920,
                  desktop: 1080,
                ),
              ),
              child: Padding(
                padding: context.pagePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: scene),
                    SizedBox(
                        width: context.responsive(
                      mobile: AppSpacing.section,
                      tablet: AppSpacing.section,
                      desktop: AppSpacing.huge,
                    )),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          text,
                          SizedBox(
                              height: context.responsive(
                            mobile: AppSpacing.xxl,
                            tablet: AppSpacing.huge,
                            desktop: AppSpacing.huge,
                          )),
                          controls,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (final didPop, final _) {
        if (didPop) return;
        if (_index > 0) {
          _goTo(_index - 1);
        } else {
          _finish();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // Kaydırma butonların kısayolu, tek yol değil.
            onHorizontalDragEnd: (final d) {
              final double v = d.primaryVelocity ?? 0;
              if (v < -250) _goTo(_index + 1);
              if (v > 250) _goTo(_index - 1);
            },
            child: Column(
              children: [topBar, Expanded(child: body)],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// İlerleme: üç küçük koçan (perde) — etkin olan dolu ve uzun
// ─────────────────────────────────────────────────────────────────────────

class _ActProgress extends StatelessWidget {
  final int index;
  final int count;
  final ValueChanged<int> onTap;

  const _ActProgress(
      {required this.index, required this.count, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '${index + 1}. perde, toplam $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < count; i++)
            Semantics(
              button: true,
              selected: i == index,
              label: '${i + 1}. perde',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      width: i == index ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i <= index ? cs.primary : cs.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// I. PERDE — gerçek afişlerin yelpazesi
// ─────────────────────────────────────────────────────────────────────────

class _PosterFan extends ConsumerWidget {
  final Animation<double> appear;
  const _PosterFan({required this.appear});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Show> shows =
        (ref.watch(activeShowsProvider(true)).value ?? const <Show>[])
            .where((final s) => s.imageUrl.trim().isNotEmpty)
            .take(3)
            .toList();

    return LayoutBuilder(builder: (final context, final c) {
      // Yelpaze (yanlar dahil) ~1.9 afiş genişliği; ekrana sığsın.
      final double w =
          math.min(math.min(c.maxHeight, 380) * 2 / 3, c.maxWidth / 1.95);
      final double h = w * 3 / 2;
      // Afiş yoksa (veri gelmedi/yok) aynı yelpaze bilet kağıdından.
      final int n = shows.isEmpty ? 3 : shows.length;
      return Center(
        child: SizedBox(
          width: w * 1.9,
          height: h,
          child: AnimatedBuilder(
            animation: appear,
            builder: (final context, final _) {
              final double t = appear.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < n; i++)
                    _fanned(
                      // Ortadaki en üstte: önce yanlar, sonra orta.
                      order: n == 3 ? [0, 2, 1][i] : i,
                      n: n,
                      t: t,
                      w: w,
                      h: h,
                      child: shows.isEmpty
                          ? const _PaperPoster()
                          : OptimizedCachedImage(
                              imageUrl:
                                  shows[n == 3 ? [0, 2, 1][i] : i].imageUrl,
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  Widget _fanned({
    required final int order,
    required final int n,
    required final double t,
    required final double w,
    required final double h,
    required final Widget child,
  }) {
    final double slot = n == 1 ? 0 : (order / (n - 1)) * 2 - 1; // -1..1
    final double angle = slot * 0.16 * t;
    final double dx = slot * w * 0.42 * t;
    final double scale = slot == 0 ? 1 : 0.86;
    return Transform.translate(
      offset: Offset(dx, (1 - t) * 24 + slot.abs() * 10),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: SizedBox(
              width: w,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: AppShadows.level4(TicketInk.ink),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ColoredBox(
                    color: TicketInk.inkSoft(0.1),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperPoster extends StatelessWidget {
  const _PaperPoster();

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TicketInk.paper, TicketInk.paperShade],
          ),
        ),
        child: Center(
          child: Icon(Icons.theater_comedy_rounded,
              size: 44, color: TicketInk.accentOf(context)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// II. PERDE — sahne + koltuk sırası; bir koltuk seçilir
// ─────────────────────────────────────────────────────────────────────────

class _SeatRow extends StatelessWidget {
  final Animation<double> appear;
  const _SeatRow({required this.appear});

  static const int _cols = 7;
  static const int _rows = 4;
  static const int _pickRow = 2;
  static const int _pickCol = 3;
  static const Set<int> _taken = {1, 5, 8, 9, 16, 20, 24};

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AnimatedBuilder(
          animation: appear,
          builder: (final context, final _) {
            final double t = appear.value;
            // Seçim anı: gösterimin son üçte birinde koltuk dolar.
            final double pick = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sahne: yay biçiminde ince bir kenar + yazı.
                SizedBox(
                  height: 34,
                  width: double.infinity,
                  child: CustomPaint(painter: _StageEdgePainter(cs.primary)),
                ),
                Text(
                  'SAHNE',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (int r = 0; r < _rows; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            String.fromCharCode(65 + r),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (int c = 0; c < _cols; c++)
                          _seat(cs, r, c, t, pick),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Opacity(
                  opacity: pick,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      'C-4 seçildi',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _seat(final ColorScheme cs, final int r, final int c, final double t,
      final double pick) {
    final int id = r * _cols + c;
    final bool picked = r == _pickRow && c == _pickCol;
    final bool taken = _taken.contains(id);
    // Sıra sıra belirir.
    final double a = ((t * 1.6) - r * 0.18).clamp(0.0, 1.0);
    final Color fill = picked
        ? Color.lerp(cs.surfaceContainerHighest, cs.primary, pick)!
        : taken
            ? cs.outlineVariant
            : cs.surfaceContainerHighest;
    return Padding(
      padding: EdgeInsets.only(left: c == 4 ? AppSpacing.md : 4, right: 4),
      child: Opacity(
        opacity: a,
        child: Transform.scale(
          scale: picked ? 1 + 0.18 * math.sin(pick * math.pi) : 1,
          child: Container(
            width: 30,
            height: 26,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xs),
                bottom: Radius.circular(3),
              ),
              border: Border.all(
                color: picked && pick > 0 ? cs.primary : cs.outlineVariant,
              ),
            ),
            child: picked && pick > 0.5
                ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
                : null,
          ),
        ),
      ),
    );
  }
}

class _StageEdgePainter extends CustomPainter {
  final Color color;
  const _StageEdgePainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Path p = Path()
      ..moveTo(size.width * 0.08, size.height * 0.2)
      ..quadraticBezierTo(size.width / 2, size.height * 1.3,
          size.width * 0.92, size.height * 0.2);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant final _StageEdgePainter old) =>
      old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// III. PERDE — tema seçimi CANLI
// ─────────────────────────────────────────────────────────────────────────

class _ThemeStage extends StatelessWidget {
  const _ThemeStage();

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seçilen temanın küçük bir "bilet" önizlemesi: renkler
              // temadan geldiği için seçimle birlikte değişir.
              AnimatedContainer(
                duration: AppMotion.normal,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.normal,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.theater_comedy_rounded,
                          color: cs.onPrimary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bu akşam sahnede',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            'Senin sahnen, senin renklerin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: cs.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const ThemeStylePicker(compact: true),
              const SizedBox(height: AppSpacing.lg),
              const AccentColorPalette(),
            ],
          ),
        ),
      ),
    );
  }
}

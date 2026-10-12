import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Kabuğun (shell) dört sekmesi — mobil alt çubuk, dar web alt çubuğu ve
/// web üst menüsü aynı listeyi kullanır; sıra `app_router.dart`'taki
/// `StatefulShellBranch` sırasıyla BİREBİR aynıdır (0 Ana Sayfa, 1 Keşfet,
/// 2 Yakındakiler, 3 Profil).
class TicketNavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const TicketNavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

const List<TicketNavDestination> kShellDestinations = [
  TicketNavDestination(
    label: 'Ana Sayfa',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  TicketNavDestination(
    label: 'Keşfet',
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
  ),
  TicketNavDestination(
    label: 'Yakındakiler',
    icon: Icons.place_outlined,
    activeIcon: Icons.place_rounded,
  ),
  TicketNavDestination(
    label: 'Profil',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

/// "Delinmiş bilet" işareti — web üst menüsünde aktif sekme için.
///
/// [opensDown] true → çentik ÜST kenardan aşağı açılır;
/// false → ALT kenardan yukarı açılır (web üst menüsü).
class TicketPunchMark extends StatelessWidget {
  final bool visible;
  final bool opensDown;
  final double radius;

  const TicketPunchMark({
    super.key,
    required this.visible,
    required this.opensDown,
    this.radius = 7,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: CustomPaint(
          size: Size(radius * 2, radius),
          painter: _PunchPainter(
            hole: cs.surface,
            rim: cs.primary,
            opensDown: opensDown,
          ),
        ),
      ),
    );
  }
}

class _PunchPainter extends CustomPainter {
  final Color hole;
  final Color rim;
  final bool opensDown;

  const _PunchPainter({
    required this.hole,
    required this.rim,
    required this.opensDown,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final double r = size.width / 2;
    final Offset c = Offset(r, opensDown ? 0 : size.height);
    final Rect disk = Rect.fromCircle(center: c, radius: r);
    final double start = opensDown ? 0 : math.pi;
    canvas.drawArc(disk, start, math.pi, true, Paint()..color = hole);
    canvas.drawArc(
      disk.deflate(0.75),
      start,
      math.pi,
      false,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant final _PunchPainter old) =>
      old.hole != hole || old.rim != rim || old.opensDown != opensDown;
}

/// Alt çubuğun ekranda kapladığı toplam yükseklik (güvenli alan hariç) —
/// üstündeki yüzen öğeler (ör. "başa dön" koçanı) buna göre konumlanır.
const double kTicketNavBarExtent = _barHeight + _barTop + _barBottom;

const double _barHeight = 84;
const double _barTop = AppSpacing.xs;
const double _barBottom = AppSpacing.md;

// Düzen sabitleri (plaka koordinatları)
const double _slabTop = 26;
const double _slabH = 56;
const double _item = 52;
const double _gap = 6;
const double _padX = 16;
const double _iconSz = 24;
const double _iconGap = 6;
const double _slabPadX = 14;
const double _notchMargin = 7;

/// Alt gezinme — plaka + seçili sekmenin arkasında ŞEFFAF OYUK.
///
/// Yumuşak tonlu bir plaka üzerinde sekmeler durur; seçili sekme (ikon +
/// etiketli hap) plakanın üstüne hafifçe yükselir ve arkasında plaka
/// oyulur (sayfa zemini görünür). Sekme değişince oyuk ve hap birlikte
/// kayar. Renkler temadan; yükseklik sabittir ([kTicketNavBarExtent]).
/// Azaltılmış harekette geçiş anında olur.
class TicketBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<TicketNavDestination> destinations;

  const TicketBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.destinations = kShellDestinations,
  });

  double _labelW(final String s) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
          text: s,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    final Duration dur = reduce ? Duration.zero : AppMotion.normal;
    final int n = destinations.length;

    final List<double> pillW = [
      for (final d in destinations)
        _padX * 2 + _iconSz + _iconGap + _labelW(d.label),
    ];
    double totalFor(final int a) {
      double t = _gap * (n - 1);
      for (int i = 0; i < n; i++) {
        t += i == a ? pillW[i] : _item;
      }
      return t;
    }

    double maxTotal = 0;
    for (int a = 0; a < n; a++) {
      maxTotal = totalFor(a) > maxTotal ? totalFor(a) : maxTotal;
    }
    final double slabW = maxTotal + _slabPadX * 2;
    final double start = (slabW - totalFor(currentIndex)) / 2;

    // Sekme konumları (seçiliye göre)
    final List<double> xs = [];
    final List<double> ws = [];
    double x = start;
    for (int i = 0; i < n; i++) {
      final double w = i == currentIndex ? pillW[i] : _item;
      xs.add(x);
      ws.add(w);
      x += w + _gap;
    }
    final Rect activeRect =
        Rect.fromLTWH(xs[currentIndex], 6, ws[currentIndex], _item);

    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, _barTop, AppSpacing.lg, _barBottom),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                height: _barHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: slabW,
                    height: _barHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Plaka + oyuk
                        Positioned.fill(
                          child: TweenAnimationBuilder<Rect?>(
                            tween: RectTween(end: activeRect),
                            duration: dur,
                            curve: Curves.easeOutCubic,
                            builder: (final context, final r, _) =>
                                CustomPaint(
                              painter: _SlabPainter(
                                notch: r ?? activeRect,
                                color: cs.surfaceContainerHigh,
                                shadow: cs.shadow,
                              ),
                            ),
                          ),
                        ),
                        for (int i = 0; i < n; i++)
                          AnimatedPositioned(
                            duration: dur,
                            curve: Curves.easeOutCubic,
                            left: xs[i],
                            top: i == currentIndex ? 6 : _slabTop + 2,
                            width: ws[i],
                            height: _item,
                            child: _NavPill(
                              destination: destinations[i],
                              active: i == currentIndex,
                              duration: dur,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(i);
                              },
                            ),
                          ),
                      ],
                    ),
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

class _SlabPainter extends CustomPainter {
  final Rect notch;
  final Color color;
  final Color shadow;

  const _SlabPainter(
      {required this.notch, required this.color, required this.shadow});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Path slab = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, _slabTop, size.width, _slabH),
        const Radius.circular(_slabH / 2),
      ));
    // Seçili sekmenin etrafı oyulur: şeffaf boşluk.
    final Path hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        notch.inflate(_notchMargin),
        Radius.circular(notch.height / 2 + _notchMargin),
      ));
    final Path cut = Path.combine(PathOperation.difference, slab, hole);
    canvas.drawShadow(cut, shadow.withValues(alpha: 0.35), 6, true);
    canvas.drawPath(cut, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant final _SlabPainter old) =>
      old.notch != notch || old.color != color;
}

class _NavPill extends StatelessWidget {
  final TicketNavDestination destination;
  final bool active;
  final Duration duration;
  final VoidCallback onTap;

  const _NavPill({
    required this.destination,
    required this.active,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color fg = active ? cs.onPrimary : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(_item / 2),
              boxShadow: active ? AppShadows.level1(cs.shadow) : const [],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: fg),
                    duration: duration,
                    builder: (final context, final color, _) => Icon(
                      active ? destination.activeIcon : destination.icon,
                      size: _iconSz,
                      color: color,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: _iconGap),
                    Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

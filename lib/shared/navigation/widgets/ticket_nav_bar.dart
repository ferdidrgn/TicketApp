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

const double _barHeight = 56;
const double _barTop = AppSpacing.sm;
const double _barBottom = AppSpacing.md;

/// Alt gezinme — yüzen hap + yuvarlak butonlar.
///
/// Seçili sekme ikon + etiketli dolu bir hap, diğerleri yumuşak tonlu
/// yuvarlak ikon butonlarıdır. Sekme değişince hap genişleyip daralır
/// (AnimatedSize), ikon yumuşakça renk değiştirir. Renkler temadan
/// (`primary` / `surfaceContainerHigh`); yükseklik sabittir
/// ([kTicketNavBarExtent]). Azaltılmış harekette geçiş anında olur.
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

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    final Duration dur = reduce ? Duration.zero : AppMotion.normal;

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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < destinations.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        _NavPill(
                          destination: destinations[i],
                          active: i == currentIndex,
                          duration: dur,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
                      ],
                    ],
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
    final Color bg = active ? cs.primary : cs.surfaceContainerHigh;
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
            height: _barHeight,
            constraints: const BoxConstraints(minWidth: _barHeight),
            padding: EdgeInsets.symmetric(horizontal: active ? 20 : 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_barHeight / 2),
              boxShadow: active ? AppShadows.level1(cs.shadow) : const [],
            ),
            child: AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: fg),
                    duration: duration,
                    builder: (final context, final color, _) => Icon(
                      active ? destination.activeIcon : destination.icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(
                      destination.label,
                      maxLines: 1,
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

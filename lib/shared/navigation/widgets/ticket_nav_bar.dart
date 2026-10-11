import 'dart:math' as math;

import 'package:flutter/material.dart';

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

const double _barHeight = 70;
const double _barTop = AppSpacing.sm;
const double _barBottom = AppSpacing.md;
const double _circleSize = 46;

/// Alt gezinme — E_Learning tarzı kayan daire + etiketli sekmeler.
///
/// Seçili ikonun arkasında temanın `primary` renginde kayan bir daire;
/// ikon `onPrimary`, diğerleri `onSurfaceVariant`. Etiketler her zaman
/// görünür (eski etiketsiz curved bar reddedilmişti). Renkler temadan;
/// yükseklik sabittir ([kTicketNavBarExtent]).
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
    final Duration slide = reduce ? Duration.zero : AppMotion.normal;
    final int n = destinations.length;

    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, _barTop, AppSpacing.sm, _barBottom),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                height: _barHeight,
                child: LayoutBuilder(
                  builder: (final context, final c) {
                    final double slot = c.maxWidth / n;
                    final double circleLeft = slot * currentIndex +
                        (slot - _circleSize) / 2;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedPositioned(
                          duration: slide,
                          curve: Curves.easeOutCubic,
                          left: circleLeft,
                          top: 0,
                          width: _circleSize,
                          height: _circleSize,
                          child: _NavOrb(
                            key: ValueKey(currentIndex),
                            color: cs.primary,
                            shadow: cs.shadow,
                            animate: !reduce,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < n; i++)
                              Expanded(
                                child: _BottomNavItem(
                                  destination: destinations[i],
                                  active: i == currentIndex,
                                  duration: slide,
                                  onTap: () => onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kayan daire: sekmeye oturunca kısa bir “pat” ölçeği (asset yok).
class _NavOrb extends StatefulWidget {
  final Color color;
  final Color shadow;
  final bool animate;

  const _NavOrb({
    super.key,
    required this.color,
    required this.shadow,
    required this.animate,
  });

  @override
  State<_NavOrb> createState() => _NavOrbState();
}

class _NavOrbState extends State<_NavOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.08), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 45),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ScaleTransition(
        scale: _scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: AppShadows.level1(widget.shadow),
          ),
        ),
      );
}

class _BottomNavItem extends StatelessWidget {
  final TicketNavDestination destination;
  final bool active;
  final Duration duration;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.active,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color iconColor = active ? cs.onPrimary : cs.onSurfaceVariant;
    final Color labelColor = active ? cs.primary : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_circleSize / 2),
        focusColor: cs.primary.withValues(alpha: 0.16),
        hoverColor: cs.onSurface.withValues(alpha: 0.04),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            SizedBox(
              height: _circleSize,
              width: double.infinity,
              child: Center(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: iconColor),
                  duration: duration,
                  builder: (final context, final color, final _) => Icon(
                    active ? destination.activeIcon : destination.icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: labelColor,
                letterSpacing: 0.1,
              ),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

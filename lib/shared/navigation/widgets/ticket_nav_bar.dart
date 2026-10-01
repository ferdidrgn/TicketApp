import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
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
      activeIcon: Icons.home_rounded),
  TicketNavDestination(
      label: 'Keşfet',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded),
  TicketNavDestination(
      label: 'Yakındakiler',
      icon: Icons.place_outlined,
      activeIcon: Icons.place_rounded),
  TicketNavDestination(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded),
];

/// "Delinmiş bilet" işareti: çubuğun kenarında, aktif sekmenin hizasında
/// kontrolörün zımbasıyla açılmış yarım daire bir çentik. Bilet dilinin
/// navigasyondaki tek izi — geri kalan her şey sade.
///
/// [opensDown] true → çentik ÜST kenardan aşağı açılır (alt çubuk);
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
    // Çentiğin merkezi kenar çizgisinin üstünde durur: aşağı açılan
    // çentikte widget'ın üst kenarı, yukarı açılanda alt kenarı.
    final Offset c = Offset(r, opensDown ? 0 : size.height);
    final Rect disk = Rect.fromCircle(center: c, radius: r);
    final double start = opensDown ? 0 : math.pi;
    // Delik: kenar çizgisini de örterek sayfanın zeminini gösterir.
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

const double _barHeight = 64;
const double _barTop = AppSpacing.sm - 2;
const double _barBottom = AppSpacing.md;
const double _barNotch = 7;

/// Alt gezinme çubuğu (mobil uygulama + dar web) — "bilet şeridi".
///
/// Ekranın dibine yapışık düz bir şerit değil: kenarlardan içeride yüzen,
/// iki yan kenarında zımba çentikleri olan bir bilet. Aktif sekme, temanın
/// vurgu renginde küçük bir KOÇAN ile işaretlenir; sekme değişince koçan
/// yeni yerine kayar (iki yanında minik zımba delikleri). Etiketler her
/// zaman görünür, her hedef ≥ 48dp. Renkler tamamen temadan.
///
/// Yükseklik sabittir ([kTicketNavBarExtent] + güvenli alan): Scaffold alt
/// çubuğa tüm ekran kadar gevşek yükseklik verir; burada hiçbir şey o
/// yüksekliği kaplamaz (bkz. eski "boş sayfa" hatası).
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
    const shape = _TicketStripBorder();

    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, _barTop, AppSpacing.md, _barBottom),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              // Tablette dört sekme ekranın iki ucuna savrulmasın.
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                height: _barHeight,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: shape,
                    color: cs.surfaceContainerHigh,
                    shadows: AppShadows.level2(cs.shadow),
                  ),
                  child: LayoutBuilder(
                    builder: (final context, final c) {
                      // Çentiklerin içine öğe taşmasın.
                      const double inset = _barNotch + AppSpacing.xs;
                      final double slot = (c.maxWidth - inset * 2) / n;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: slide,
                            curve: AppMotion.standard,
                            left: inset + slot * currentIndex + 3,
                            width: slot - 6,
                            top: AppSpacing.xs + 2,
                            bottom: AppSpacing.xs + 2,
                            child: _ActiveStub(
                                color: cs.primary,
                                holeColor: cs.surfaceContainerHigh),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: inset),
                            child: Row(
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
      ),
    );
  }
}

/// Aktif sekmenin koçanı: vurgu renginde dolu, iki yan kenarında minik
/// zımba delikleri (delik, çubuğun zemin rengini gösterir).
class _ActiveStub extends StatelessWidget {
  final Color color;
  final Color holeColor;
  const _ActiveStub({required this.color, required this.holeColor});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            for (final bool left in const [true, false])
              Positioned(
                left: left ? -3 : null,
                right: left ? null : -3,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: holeColor, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
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
    final Color fg = active ? cs.onPrimary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        focusColor: cs.primary.withValues(alpha: 0.16),
        hoverColor: cs.onSurface.withValues(alpha: 0.04),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: fg),
              duration: duration,
              builder: (final context, final color, final _) => Icon(
                active ? destination.activeIcon : destination.icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedDefaultTextStyle(
                duration: duration,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: fg,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yüzen şeridin silueti: yuvarlak köşeli bilet, iki yan kenarın
/// ortasında yarım daire zımba çentikleri.
class _TicketStripBorder extends ShapeBorder {
  const _TicketStripBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  Path _path(final Rect r) {
    final Path body = Path()
      ..addRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(AppRadius.lg)));
    final double y = r.center.dy;
    final Path holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(r.left, y), radius: _barNotch))
      ..addOval(Rect.fromCircle(center: Offset(r.right, y), radius: _barNotch));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  Path getOuterPath(final Rect rect, {final TextDirection? textDirection}) =>
      _path(rect);

  @override
  Path getInnerPath(final Rect rect, {final TextDirection? textDirection}) =>
      _path(rect);

  @override
  void paint(final Canvas canvas, final Rect rect,
      {final TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(final double t) => this;
}

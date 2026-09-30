import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
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

/// Alt gezinme çubuğu (mobil uygulama + dar web). Temanın yüzeyinde,
/// üst kenarında ince çizgi; aktif sekme dolu ikon + kalın etiket + çizgiye
/// açılmış zımba çentiğiyle belli olur. Etiketler her zaman görünür,
/// her hedef en az 64×48.
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
    return Material(
      color: cs.surfaceContainer,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          // `heightFactor: 1` şart: Scaffold alt çubuğa ekranın tamamı kadar
          // gevşek yükseklik veriyor; çarpansız `Center` o yüksekliğin
          // hepsini kaplayıp sayfa gövdesini 0 px'e düşürüyordu (boş sayfa,
          // ortada duran menü).
          child: Center(
            heightFactor: 1,
            // Tablette dört sekme ekranın iki ucuna savrulmasın.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (int i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _BottomNavItem(
                          destination: destinations[i],
                          active: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final TicketNavDestination destination;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        focusColor: cs.primary.withOpacity(0.14),
        hoverColor: cs.onSurface.withOpacity(0.04),
        splashColor: cs.primary.withOpacity(0.10),
        highlightColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              // Merkez üst çizginin üstünde: çentik 1px'lik çizgiyi de örter.
              top: -1,
              left: 0,
              right: 0,
              child: Center(
                child: TicketPunchMark(visible: active, opensDown: true),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.xs + 2),
                  Icon(
                    active ? destination.activeIcon : destination.icon,
                    size: 24,
                    color: active ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? cs.onSurface : cs.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

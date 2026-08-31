import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shows/domain/entities/show.dart';

/// 🎭 "Perde Arkası" — merak uyandıran, 3D çevirmeli sürpriz kartlar.
/// Ön yüz gösteriyi bilerek gizler (bulanık afiş + "?" ), arkası
/// GERÇEK gösteri bilgisiyle (kategori/süre/yaş sınırı) açılır. Yeni bir
/// oyun motoru DEĞİL — sadece elimizdeki gerçek veriyle küçük bir
/// etkileşimli sürpriz anı.
class LandingMysterySection extends StatelessWidget {
  final List<Show> shows;
  const LandingMysterySection({super.key, required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) return const SizedBox.shrink();
    final preview = shows.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WebColors.primaryGold.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: WebColors.primaryGoldLight, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Perde Arkası',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Perdeyi arala, sürprizi gör.',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5)),
        const SizedBox(height: 24),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 20),
            itemBuilder: (final context, final i) =>
                _MysteryFlipCard(show: preview[i]),
          ),
        ),
      ],
    );
  }
}

class _MysteryFlipCard extends StatefulWidget {
  final Show show;
  const _MysteryFlipCard({required this.show});

  @override
  State<_MysteryFlipCard> createState() => _MysteryFlipCardState();
}

class _MysteryFlipCardState extends State<_MysteryFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _revealed = false;

  void _toggle() {
    setState(() => _revealed = !_revealed);
    if (_revealed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) {
            final angle = _controller.value * math.pi;
            final showBack = angle > math.pi / 2;
            final displayAngle = showBack ? angle - math.pi : angle;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(displayAngle),
              child: SizedBox(
                width: 170,
                height: 240,
                child: showBack ? _buildBack() : _buildFront(),
              ),
            );
          },
        ),
      );

  Widget _buildFront() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: widget.show.imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.45)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Text('?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Perdeyi Arala',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBack() => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(math.pi),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WebColors.darkBlueSurface, WebColors.darkBlueAccent],
            ),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.show.category.toUpperCase(),
                      style: const TextStyle(
                          color: WebColors.primaryGoldLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(widget.show.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25)),
                  const SizedBox(height: 10),
                  if (widget.show.duration.isNotEmpty)
                    _miniRow(Icons.timer_outlined, widget.show.duration),
                  if (widget.show.ageLimit.isNotEmpty)
                    _miniRow(Icons.shield_outlined, widget.show.ageLimit),
                ],
              ),
              InkWell(
                onTap: () => NavigationHandler.goToApp(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Keşfet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _miniRow(final IconData icon, final String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5)),
          ],
        ),
      );
}

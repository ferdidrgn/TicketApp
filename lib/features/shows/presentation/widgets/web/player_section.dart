import 'package:flutter/material.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

class PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isOld;

  const PlayerSection({
    super.key,
    required this.players,
    required this.isOld,
  });

  @override
  Widget build(final BuildContext context) {
    if (players.isEmpty)
      return Center(
        child: Text(isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.',
            style: const TextStyle(color: Colors.white38)),
      );

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: players.asMap().entries.map((final entry) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(
            milliseconds: 300 + entry.key * 70,
          ),
          builder: (final context, final value, final child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
          ),
          child: AnimatedPlayerCard(player: entry.value, isOld: isOld),
        );
      }).toList(),
    );
  }
}

class AnimatedPlayerCard extends StatelessWidget {
  final Player player;
  final bool isOld;

  const AnimatedPlayerCard({
    super.key,
    required this.player,
    required this.isOld,
  });

  @override
  Widget build(final BuildContext context) {
    final String fullName = '${player.firstName} ${player.lastName}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => NavigationHandler.goToPlayer(
            context, player.id, '${player.firstName} ${player.lastName}'),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: OptimizedCachedImage(
                      imageUrl: player.imageUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              // Eski oyuncu ise üzerine siyah perde ve ikon
              if (isOld)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.history,
                        color: Colors.white38,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              // Sağ üst köşe dekoru
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(isOld ? 0.3 : 0.6),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

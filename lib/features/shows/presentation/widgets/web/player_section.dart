import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
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
            style: TextStyle(color: WebColors.whiteText.withOpacity(0.38))),
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

  // Landing sitesindeki köşegen köşe dili: üst-sol & alt-sağ küçük,
  // üst-sağ & alt-sol büyük (bkz. style.css .show / .venue).
  static const _cardRadius = BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(26),
    bottomRight: Radius.circular(6),
    bottomLeft: Radius.circular(26),
  );

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
            color: WebColors.darkBlueSurface,
            borderRadius: _cardRadius,
            border: Border.all(
              color: WebColors.primaryGold.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.15),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(26),
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
                      style: TextStyle(
                        color: WebColors.whiteText,
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
              // Eski oyuncu ise üzerine koyu perde ve ikon
              if (isOld)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _cardRadius,
                      color: WebColors.veryDarkBlue.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.history,
                        color: WebColors.whiteText.withOpacity(0.38),
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
                        WebColors.primaryGold.withOpacity(isOld ? 0.3 : 0.6),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(26),
                      bottomLeft: Radius.circular(26),
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

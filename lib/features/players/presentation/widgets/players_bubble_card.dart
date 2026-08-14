import 'package:flutter/material.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../favorite/presentation/widgets/favorite_toggle_button.dart';
import '../../../users/domain/entities/favorite_type.dart';

class PlayersBubbleCard extends StatelessWidget {
  final List<Player> players;
  final bool isGrayscale;

  const PlayersBubbleCard({
    super.key,
    required this.players,
    this.isGrayscale = false,
  });

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        itemBuilder: (final context, final index) {
          final player = players[index];
          final fullName = "${player.firstName} ${player.lastName}";

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              // 🔗 NAVİGASYON BAĞLANDI
              onTap: () =>
                  NavigationHandler.goToPlayer(context, player.id, fullName),
              borderRadius: BorderRadius.circular(60),
              child: Card(
                elevation: 4,
                // Derinlik
                shadowColor: context.colors.shadow.withOpacity(0.1),
                color: context.colors.surfaceContainer,
                // Tema uyumlu kart rengi
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // YUVARLAK RESİM
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipOval(
                            child: Container(
                              width: 115,
                              height: 115,
                              color: context.colors.surfaceContainerHighest,
                              child: ColorFiltered(
                                // Eski oyuncular için Siyah/Beyaz filtre
                                colorFilter: isGrayscale
                                    ? const ColorFilter.mode(
                                        Colors.grey, BlendMode.saturation)
                                    : const ColorFilter.mode(
                                        Colors.transparent, BlendMode.dst),
                                child: OptimizedCachedImage(
                                  imageUrl: player.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: FavoriteToggleButton(
                                itemId: player.id,
                                type: FavoriteType.player,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // İSİM SOYİSİM
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          fullName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isGrayscale ? FontWeight.w600 : FontWeight.bold,
                            // Grayscale ise soluk, değilse canlı renk
                            color: isGrayscale
                                ? context.colors.secondary
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

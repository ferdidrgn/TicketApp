import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../domain/entities/player.dart';
import '../pages/player_details.dart';

class PlayerHeroCard extends StatelessWidget {
  final Player player;

  final EdgeInsetsGeometry? margin;
  final double width;
  final double height;
  final double borderRadius;

  const PlayerHeroCard({
    super.key,
    required this.player,
    this.margin,
    this.width = 120,
    this.height = 120,
    this.borderRadius = 60,
  });

  @override
  Widget build(final BuildContext context) => Container(
        width: width,
        margin: margin ?? const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => PlayerDetailPage(playerId: player.id)),
          ),
          child: Column(
            children: [
              Expanded(
                child: OptimizedCachedImage(
                  imageUrl: player.imageUrl,
                  width: width,
                  height: height,
                  isCircular: true,
                  borderRadius: borderRadius,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${player.firstName}\n${player.lastName}",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface),
              ),
            ],
          ),
        ),
      );
}

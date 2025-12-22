import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../domain/entities/player.dart';
import '../pages/player_details.dart';

class PlayerHeroCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;

  const PlayerHeroCard({
    super.key,
    required this.player,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) =>
                          PlayerDetailPage(playerId: player.id)),
                ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resim Alanı (Daima 1:1 Kare oranında ama yuvarlak kesimli)
            AspectRatio(
              aspectRatio: 1, // En ve boy eşit olsun (tam daire için)
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: OptimizedCachedImage(
                  imageUrl: player.imageUrl,
                  isCircular: true,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // İsim Alanı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "${player.firstName}\n${player.lastName}",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
}

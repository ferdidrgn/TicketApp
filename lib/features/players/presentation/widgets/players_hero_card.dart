import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../domain/entities/player.dart';

class PlayerHeroCard extends StatelessWidget {
  final Player? player;
  final bool isLoading;

  const PlayerHeroCard({
    super.key,
    this.player,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading || player == null)
      return Container(
        width: 120, // Tasarımındaki sabit genişlik
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Resim Alanı (Yuvarlak Shimmer)
            const SizedBox(
              height: 120,
              width: 120,
              child: ShimmerLoading(
                width: 120,
                height: 120,
                isCircular: true, // Yuvarlak efekt
              ),
            ),
            const SizedBox(height: 8),
            // İsim Alanı (Çubuk Shimmerlar)
            const ShimmerLoading(height: 12, width: 80, borderRadius: 4),
            const SizedBox(height: 4),
            const ShimmerLoading(height: 12, width: 60, borderRadius: 4),
          ],
        ),
      );

    return GestureDetector(
      onTap: () => context.push('/player/${player!.id}'),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: OptimizedCachedImage(
                  imageUrl: player!.imageUrl,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${player!.firstName}\n${player!.lastName}",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

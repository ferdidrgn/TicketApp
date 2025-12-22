import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../domain/entities/player.dart';
import '../pages/player_details.dart';

class PlayerHeroCard extends StatelessWidget {
  final Player? player; // Veri yoksa null olabilir
  final bool isLoading; // Shimmer kontrolü
  final VoidCallback? onTap;

  const PlayerHeroCard({
    super.key,
    this.player,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // 1. DURUM: YÜKLENİYOR (SHIMMER)
    // =========================================================================
    if (isLoading || player == null) {
      return Container(
        width: 120, // Senin kodundaki genişlik
        margin: const EdgeInsets.only(right: 12), // Senin kodundaki margin
        child: Column(
          children: [
            // Resim Alanı (Yuvarlak Shimmer)
            // Senin kodunda Expanded var, Shimmer için sabit boyut veriyoruz ki düzgün dursun
            const SizedBox(
              height: 120,
              width: 120,
              child: ShimmerLoading(
                width: 120,
                height: 120,
                isCircular: true, // Yuvarlak olması için
              ),
            ),
            const SizedBox(height: 8),

            // İsim Alanı (Çubuk Shimmer)
            const ShimmerLoading(height: 12, width: 80, borderRadius: 4),
            const SizedBox(height: 4),
            const ShimmerLoading(height: 12, width: 60, borderRadius: 4),
          ],
        ),
      );
    }

    // =========================================================================
    // 2. DURUM: VERİ GELDİ (SENİN KODUN - BİREBİR)
    // =========================================================================
    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final _) =>
                        PlayerDetailPage(playerId: player!.id)),
              ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60), // Tam daire (120/2)
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

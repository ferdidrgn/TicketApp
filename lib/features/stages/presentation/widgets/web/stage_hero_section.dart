import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

/// Sahne detay sayfasının masaüstü/web kahraman (hero) bölümü.
///
/// Büyük, sinematik bir mekan fotoğrafı üzerine koyu çam gradyanı, mekan
/// adı ve kısa adres/kapasite bilgisi bindirilir. [fadeAnimation] ve
/// [slideAnimation], sayfa ilk açıldığında bir kere oynayan giriş
/// animasyonunu sağlar (bkz. `show_detail_page_web.dart` deki
/// `ShowDetailHero` ile aynı desen).
class StageHeroSection extends StatelessWidget {
  final Stage stage;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final double height;

  const StageHeroSection({
    super.key,
    required this.stage,
    required this.fadeAnimation,
    required this.slideAnimation,
    this.height = 560,
  });

  @override
  Widget build(final BuildContext context) => FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: OptimizedCachedImage(
                    imageUrl: stage.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                ),
                Positioned.fill(child: _HeroGradientOverlay()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              WebColors.primaryGold,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: ShaderMask(
                          shaderCallback: (final bounds) => const LinearGradient(
                            colors: [WebColors.whiteText, WebColors.primaryGoldLight],
                          ).createShader(bounds),
                          child: Text(
                            stage.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (stage.address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 100),
                          child: Text(
                            stage.address,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 16,
                              letterSpacing: 0.4,
                              height: 1.5,
                            ),
                          ),
                        ),
                      if (stage.capacity.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _CapacityChip(capacity: stage.capacity),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _HeroGradientOverlay extends StatelessWidget {
  const _HeroGradientOverlay();

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WebColors.veryDarkBlue.withOpacity(0.15),
              Colors.transparent,
              WebColors.veryDarkBlue.withOpacity(0.85),
              WebColors.veryDarkBlue,
            ],
            stops: const [0.0, 0.35, 0.82, 1.0],
          ),
        ),
      );
}

class _CapacityChip extends StatelessWidget {
  final String capacity;
  const _CapacityChip({required this.capacity});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: WebColors.primaryGold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_seat_rounded,
                color: WebColors.primaryGoldLight, size: 16),
            const SizedBox(width: 8),
            Text(
              '$capacity KİŞİ KAPASİTELİ',
              style: const TextStyle(
                color: WebColors.primaryGoldLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
}

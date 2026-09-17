import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/gallery_section.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shows/presentation/providers/gallery_provider.dart';
import 'spotlight_reveal.dart';
import 'team_section_title_web.dart';

/// 📸 TAKIM GALERİSİ — SPOTLIGHT REVEAL (MASAÜSTÜ)
///
/// `landing/index.html`'in "Kadro" bölümündeki sahneye çıkış efektinin
/// (`landing/style.css` — `.team .player.reveal` / `spotlightHit`) doğrudan
/// Flutter karşılığı: bu ekibin kadrosuna dair somut, isimlendirilmiş oyuncu
/// verisi bulunmadığından (bkz. `Team` entity: sadece `photosId`), aynı
/// "sahneye adım atma" duygusu topluluk fotoğraflarına uygulanıyor — her
/// kare önce karanlık/gri bir silüet olarak belirir, ardından üstüne düşen
/// spot ışığıyla birlikte tam renge kavuşur. Farklı yükseklikte hücrelerle
/// örgü benzeri (editoryal) bir düzen kurulur; tıklanınca uygulamanın
/// paylaşılan tam ekran galeri görüntüleyicisi açılır.
class TeamGallerySpotlightWeb extends ConsumerWidget {
  final List<String> photos;

  const TeamGallerySpotlightWeb({super.key, required this.photos});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeamSectionTitleWeb(
          title: 'TAKIM GALERİSİ',
          icon: Icons.collections_rounded,
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (final context, final constraints) {
            const crossAxisCount = 4;
            const spacing = 20.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < photos.length; i++)
                  SizedBox(
                    width: tileWidth,
                    // Editoryal ritim için satır arası kısa/uzun kare dönüşümü
                    height: i % 5 == 0 ? tileWidth * 1.15 : tileWidth * 0.85,
                    child: SpotlightReveal(
                      index: i,
                      colorizeFromGray: true,
                      child: _GalleryFrame(
                        url: photos[i],
                        index: i,
                        allPhotos: photos,
                        ref: ref,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GalleryFrame extends StatelessWidget {
  final String url;
  final int index;
  final List<String> allPhotos;
  final WidgetRef ref;

  const _GalleryFrame({
    required this.url,
    required this.index,
    required this.allPhotos,
    required this.ref,
  });

  void _open(final BuildContext context) {
    HapticFeedback.lightImpact();
    ref
        .read(galleryProvider(allPhotos.length).notifier)
        .setCurrentIndex(index);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (final _) =>
          GalleryViewerDialog(images: allPhotos, isMobile: false),
    );
  }

  @override
  Widget build(final BuildContext context) => HoverSpotlightCard(
        borderRadius: BorderRadius.circular(18),
        lift: 6,
        scale: 1.02,
        onTap: () => _open(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(
              imageUrl: url,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: WebColors.primaryGold.withOpacity(0.15),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      );
}

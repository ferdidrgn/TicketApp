import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shows/domain/entities/show.dart';
import 'spotlight_reveal.dart';
import 'team_section_title_web.dart';

/// 🎬 SAHNEDEKİ ESERLER (MASAÜSTÜ)
///
/// Mobildeki tekdüze mozaik yerine, farklı yükseklikte kartlardan oluşan
/// asimetrik bir dergi ızgarası: ilk eser "manşet" gibi geniş, geri kalanı
/// daha küçük destek kartları. Her kart ekrana girerken kademeli olarak
/// belirir ve fare ile üzerine gelindiğinde hafifçe yükselir/büyür.
class TeamShowsSectionWeb extends StatelessWidget {
  final List<Show> shows;

  const TeamShowsSectionWeb({super.key, required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) return const SizedBox.shrink();

    final featured = shows.first;
    final rest = shows.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeamSectionTitleWeb(
          title: 'SAHNEDEKİ ESERLER',
          icon: Icons.auto_awesome_motion_rounded,
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SpotlightReveal(
                index: 0,
                child: _ShowCard(show: featured, height: 460, featured: true),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  for (var i = 0; i < rest.length && i < 2; i++) ...[
                    if (i > 0) const SizedBox(height: 24),
                    SpotlightReveal(
                      index: i + 1,
                      child: _ShowCard(show: rest[i], height: 218),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (rest.length > 2) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              for (var i = 2; i < rest.length; i++)
                SizedBox(
                  width: 280,
                  child: SpotlightReveal(
                    index: i + 1,
                    child: _ShowCard(show: rest[i], height: 200),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ShowCard extends StatelessWidget {
  final Show show;
  final double height;
  final bool featured;

  const _ShowCard(
      {required this.show, required this.height, this.featured = false});

  @override
  Widget build(final BuildContext context) => HoverSpotlightCard(
        borderRadius: BorderRadius.circular(24),
        lift: 12,
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(
                imageUrl: show.imageUrl,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      WebColors.veryDarkBlue.withOpacity(0.35),
                      WebColors.veryDarkBlue.withOpacity(0.92),
                    ],
                    stops: const [0.35, 0.65, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (show.category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: WebColors.primaryGold.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          show.category.toUpperCase(),
                          style: const TextStyle(
                            color: WebColors.veryDarkBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Text(
                      show.name,
                      maxLines: featured ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebColors.whiteText,
                        fontSize: featured ? 30 : 19,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (featured && show.duration.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 15, color: WebColors.secondaryAccentLight),
                          const SizedBox(width: 6),
                          // show.duration serbest metin bir alan (CMS'te
                          // uzunluğu garanti edilmiyor); dar kart genişliğinde
                          // (Positioned(left:24,right:24) ile sıkıca
                          // sınırlanmış) Expanded/Flexible olmadan
                          // RenderFlex taşmasına yol açabilirdi.
                          Flexible(
                            child: Text(
                              show.duration,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: WebColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

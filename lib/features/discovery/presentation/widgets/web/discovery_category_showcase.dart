import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../utils/category_stats.dart';

/// "Kategoriler" vitrin şeridi — GERÇEK `Show.category` dağılımından
/// (`buildCategoryStats`) türetilmiş kartlar: kategori adı + o kategorideki
/// GERÇEK oyun sayısı + kategorideki bir oyunun GERÇEK afişi. Sabit/uydurma
/// bir kategori listesi DEĞİL; `stats` boşsa (hiç kategorili oyun yoksa)
/// hiçbir şey render etmez.
///
/// Hover davranışı `discovery_show_card.dart`/`theatre_show_card.dart` ile
/// aynı tasarım dilini (AppMotion/AppShadows, asimetrik "taç yaprağı"
/// köşe, hover'da hafif kaldırma) paylaşır.
class DiscoveryCategoryShowcase extends StatefulWidget {
  final List<CategoryStat> stats;
  final ValueChanged<String> onCategoryTap;

  const DiscoveryCategoryShowcase({
    super.key,
    required this.stats,
    required this.onCategoryTap,
  });

  @override
  State<DiscoveryCategoryShowcase> createState() =>
      _DiscoveryCategoryShowcaseState();
}

class _DiscoveryCategoryShowcaseState extends State<DiscoveryCategoryShowcase> {
  // Fare tekerleği (dikey delta) yatay kaydırmaya çevriliyor — bkz.
  // `discovery_page.dart`'taki `_trendingScrollController` üzerindeki aynı
  // yorum/teknik.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.stats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: Listener(
        onPointerSignal: (final event) {
          if (event is! PointerScrollEvent ||
              !_scrollController.hasClients) {
            return;
          }
          final double target =
              (_scrollController.offset + event.scrollDelta.dy).clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(target);
        },
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.stats.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.lg),
          itemBuilder: (final context, final index) => _CategoryCard(
            stat: widget.stats[index],
            onTap: () => widget.onCategoryTap(widget.stats[index].category),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryStat stat;
  final VoidCallback onTap;

  const _CategoryCard({required this.stat, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Semantics(
            button: true,
            label:
                '${widget.stat.category} kategorisi, ${widget.stat.count} oyun',
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
              width: 230,
              decoration: BoxDecoration(
                borderRadius: AppRadius.asymLg,
                boxShadow: _hovered
                    ? AppShadows.level3(WebColors.primaryGold)
                    : AppShadows.level2(WebColors.veryDarkBlue),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.asymLg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                      imageUrl: widget.stat.sampleImageUrl,
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
                            WebColors.veryDarkBlue
                                .withOpacity(_hovered ? 0.93 : 0.84),
                          ],
                          stops: const [0.28, 1.0],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.asymLg,
                        border: Border.all(
                          color: WebColors.primaryGold
                              .withOpacity(_hovered ? 0.7 : 0.2),
                          width: _hovered ? 2 : 1,
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.stat.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.stat.count} oyun',
                            style: const TextStyle(
                              color: WebColors.primaryGoldLight,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

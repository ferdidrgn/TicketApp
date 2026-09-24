import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../stages/domain/entities/stage.dart';

/// "Sahneler" vitrin şeridi — GERÇEK `stagesProvider`'dan gelen sahneler:
/// sahne adı + GERÇEK fotoğrafı + o sahnede sahnelenen GERÇEK oyun sayısı
/// (`Stage.showsId.length` — uydurma bir rakam DEĞİL). `stages` boşsa
/// hiçbir şey render etmez.
class DiscoveryStageShowcase extends StatefulWidget {
  final List<Stage> stages;
  final ValueChanged<Stage> onStageTap;

  const DiscoveryStageShowcase({
    super.key,
    required this.stages,
    required this.onStageTap,
  });

  @override
  State<DiscoveryStageShowcase> createState() =>
      _DiscoveryStageShowcaseState();
}

class _DiscoveryStageShowcaseState extends State<DiscoveryStageShowcase> {
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
    if (widget.stages.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 210,
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
          itemCount: widget.stages.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.lg),
          itemBuilder: (final context, final index) => _StageCard(
            stage: widget.stages[index],
            onTap: () => widget.onStageTap(widget.stages[index]),
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatefulWidget {
  final Stage stage;
  final VoidCallback onTap;

  const _StageCard({required this.stage, required this.onTap});

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final int showCount = widget.stage.showsId.length;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: '${widget.stage.name} sahnesi, $showCount oyun sahnelendi',
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
            width: 260,
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
                    imageUrl: widget.stage.imageUrl,
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
                              .withOpacity(_hovered ? 0.92 : 0.82),
                        ],
                        stops: const [0.35, 1.0],
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
                          widget.stage.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.theater_comedy_rounded,
                                size: 13, color: WebColors.primaryGoldLight),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                showCount == 1
                                    ? '1 oyun sahnelendi'
                                    : '$showCount oyun sahnelendi',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: WebColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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
}

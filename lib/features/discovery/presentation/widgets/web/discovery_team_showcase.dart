import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../teams/domain/entities/team.dart';

/// "Topluluklar" vitrin şeridi — GERÇEK `teamsProvider`'dan gelen tiyatro
/// toplulukları: takım adı + GERÇEK fotoğrafı + GERÇEK gösteri sayısı
/// (`Team.showsId.length`). `teams` boşsa hiçbir şey render etmez.
class DiscoveryTeamShowcase extends StatefulWidget {
  final List<Team> teams;
  final ValueChanged<Team> onTeamTap;

  const DiscoveryTeamShowcase({
    super.key,
    required this.teams,
    required this.onTeamTap,
  });

  @override
  State<DiscoveryTeamShowcase> createState() => _DiscoveryTeamShowcaseState();
}

class _DiscoveryTeamShowcaseState extends State<DiscoveryTeamShowcase> {
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
    if (widget.teams.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
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
          itemCount: widget.teams.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.lg),
          itemBuilder: (final context, final index) => _TeamCard(
            team: widget.teams[index],
            onTap: () => widget.onTeamTap(widget.teams[index]),
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatefulWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final int showCount =
        widget.team.showsId.where((final id) => id.isNotEmpty).length;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: '${widget.team.name} topluluğu, $showCount gösteri',
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
            width: 180,
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
                    imageUrl: widget.team.imageUrl,
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
                              .withOpacity(_hovered ? 0.9 : 0.78),
                        ],
                        stops: const [0.4, 1.0],
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
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.team.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          showCount == 1 ? '1 gösteri' : '$showCount gösteri',
                          style: const TextStyle(
                            color: WebColors.primaryGoldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
}

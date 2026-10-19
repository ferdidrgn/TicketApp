import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/sahne/flower_portrait.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../domain/entities/player.dart';
import '../../providers/player_provider.dart';

/// Bir oyuncunun oynadığı (şimdiki + geçmiş) oyunlardaki DİĞER oyuncular,
/// ortak oyun sayısına göre — tamamen mevcut Show.nowPlayersId/oldPlayersId
/// verisinden. Ortak oyunu olan kimse yoksa hiçbir şey çizmez.
class PlayerCoStars extends ConsumerWidget {
  final Player player;
  final List<Show> shows;

  const PlayerCoStars({super.key, required this.player, required this.shows});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Player> all = ref.watch(playersProvider()).value ?? const [];
    if (all.isEmpty || shows.isEmpty) return const SizedBox.shrink();

    final Map<String, int> shared = {};
    for (final Show s in shows) {
      for (final String id in {...s.nowPlayersId, ...s.oldPlayersId}) {
        final String pid = id.trim();
        if (pid.isEmpty || pid == player.id) continue;
        shared[pid] = (shared[pid] ?? 0) + 1;
      }
    }
    if (shared.isEmpty) return const SizedBox.shrink();

    final Map<String, Player> byId = {for (final Player p in all) p.id: p};
    final List<MapEntry<String, int>> ranked = shared.entries
        .where((final e) => byId[e.key] != null)
        .toList()
      ..sort((final a, final b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) return const SizedBox.shrink();

    final List<MapEntry<String, int>> top = ranked.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkSectionHead(
          title: 'Sahne arkadaşları',
          subtitle: 'Aynı oyunlarda birlikte oynadıkları',
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (final context, final i) {
              final Player p = byId[top[i].key]!;
              final int n = top[i].value;
              final String name = '${p.firstName} ${p.lastName}'.trim();
              return Reveal(
                index: i,
                child: SkFlowerPortrait(
                  imageUrl: p.imageUrl,
                  size: 112,
                  semanticLabel: '$name, $n ortak oyun',
                  topChip: '$n ortak oyun',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    NavigationHandler.goToPlayer(context, p.id, name,
                        heroTag: TiyatrolHeroTags.player(p.id, 'costar'),
                        imageUrl: p.imageUrl,
                        title: name);
                  },
                  heroWrap: (final child) => TiyatrolHero(
                      tag: TiyatrolHeroTags.player(p.id, 'costar'),
                      child: child),
                  title: Text(name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 13, weight: FontWeight.w800, height: 1.2)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

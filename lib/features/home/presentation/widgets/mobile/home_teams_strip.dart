import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/team_provider.dart';

/// Anasayfada gerçek Team verisiyle yatay kaydırmalı "Sahne Toplulukları"
/// şeridi. Yükleme durumunda hafif bir shimmer gösterir, veri boşsa ya da
/// hata olursa (bu bölüm kritik bir akış olmadığından) sessizce hiçbir şey
/// render etmez.
class HomeTeamsStrip extends ConsumerWidget {
  const HomeTeamsStrip({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final teamsState = ref.watch(teamsProvider(isLimit: true));

    return teamsState.when(
      data: (final teams) {
        if (teams.isEmpty) return const SizedBox.shrink();
        return _TeamsCarousel(teams: teams);
      },
      loading: () => const _TeamsStripShimmer(),
      // Bu bölüm destekleyici bir anasayfa şeridi olduğundan hata durumunda
      // sessizce hiçbir şey göstermiyoruz.
      error: (final _, final __) => const SizedBox.shrink(),
    );
  }
}

class _TeamsCarousel extends StatelessWidget {
  final List<Team> teams;

  const _TeamsCarousel({required this.teams});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 180,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: teams.length,
          separatorBuilder: (final _, final __) => const SizedBox(width: 15),
          itemBuilder: (final context, final index) {
            final team = teams[index];
            return _TeamCard(
              team: team,
              onTap: () =>
                  NavigationHandler.goToTeam(context, team.id, team.name),
            );
          },
        ),
      );
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 140,
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: team.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (final _, final __) => const ShimmerLoading(
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  errorWidget: (final _, final __, final ___) => Container(
                    color: context.colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.theater_comedy_outlined,
                      color: context.colors.outline,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TeamsStripShimmer extends StatelessWidget {
  const _TeamsStripShimmer();

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 180,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (final _, final __) => const SizedBox(width: 15),
          itemBuilder: (final _, final __) => const ShimmerLoading(
            height: 180,
            width: 140,
            borderRadius: 20,
          ),
        ),
      );
}

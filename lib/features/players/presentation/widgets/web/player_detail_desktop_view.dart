import 'package:flutter/material.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'player_achievements_timeline.dart';
import 'player_hero_split.dart';
import 'player_on_stage_banner.dart';
import 'player_shows_editorial.dart';
import 'player_shows_grid.dart';

/// 🖥️ SANATÇI PROFİLİ — MASAÜSTÜ DÜZENİ
///
/// `show_detail_page_web.dart`'taki kurulumu izler: içerik ~1300px'te
/// ortalanır, bölümler arasında bol boşluk bırakılır, her bölüm ekrana
/// girdiğinde kendi kendine canlanır (bkz. `ScrollReveal`). Tamamen
/// `Player`/`Show` varlıklarındaki gerçek alanlardan beslenir — uydurma alan
/// yoktur.
class PlayerDetailDesktopView extends StatelessWidget {
  final Player player;
  final List<Show> activeShows;
  final List<Show> pastShows;

  const PlayerDetailDesktopView({
    super.key,
    required this.player,
    required this.activeShows,
    required this.pastShows,
  });

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerHeroSplit(
                player: player,
                activeShowCount: activeShows.length,
                pastShowCount: pastShows.length,
              ),
              if (activeShows.isNotEmpty) ...[
                const SizedBox(height: 56),
                PlayerOnStageBanner(activeShows: activeShows),
              ],
              const SizedBox(height: 88),
              PlayerShowsEditorial(
                title: 'Sahnede',
                icon: Icons.theater_comedy_rounded,
                shows: activeShows,
                emptyMessage: 'Şu an sahnede bir oyunu bulunmuyor.',
              ),
              const SizedBox(height: 88),
              PlayerShowsGrid(
                title: 'Geçmiş Sahnelenenler',
                icon: Icons.history_edu_rounded,
                shows: pastShows,
                emptyMessage: 'Arşiv henüz güncellenmemiş.',
              ),
              const SizedBox(height: 88),
              PlayerAchievementsTimeline(achievements: player.achievements),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';
import '../../../users/domain/entities/favorite_type.dart';
import '../providers/favorite_provider.dart';
import '../widgets/favorite_toggle_button.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return DefaultTabController(
      length: 3,
      child: BasePageWrapper(
        title: 'KOLEKSİYONUM',
        subtitle: 'Kalbinde yer eden tüm sahneler...',
        showBackButton: true,
        rightIcon: Icons.favorite_rounded,
        isLoading: favoritesAsync.isLoading,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        onRefresh: () => ref.invalidate(myFavoritesProvider),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1200 : double.infinity),
            child: favoritesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (final err, final _) => _ErrorState(
                onRetry: () => ref.invalidate(myFavoritesProvider),
              ),
              data: (final favorites) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: _FavoriteTabSelector(
                      controller: _tabController,
                      showCount: favorites.shows.length,
                      stageCount: favorites.stages.length,
                      playerCount: favorites.players.length,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ShowsGrid(shows: favorites.shows),
                        _StagesGrid(stages: favorites.stages),
                        _PlayersGrid(players: favorites.players),
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

int _gridCrossAxisCount(final BuildContext context) =>
    context.responsive(mobile: 2, tablet: 3, desktop: 4);

class _ShowsGrid extends StatelessWidget {
  final List<Show> shows;
  const _ShowsGrid({required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) {
      return const _EmptyState(
        icon: Icons.theater_comedy_rounded,
        message: 'Henüz favori oyunun yok.\nBeğendiğin oyunları kalbe dokunarak ekleyebilirsin.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount(context),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: shows.length,
      itemBuilder: (final context, final index) {
        final show = shows[index];
        return Stack(
          children: [
            ShowCard(
              imageUrl: show.imageUrl,
              gameName: show.name,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final _) => ShowDetailPage(showId: show.id)));
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: FavoriteToggleButton(
                    itemId: show.id, type: FavoriteType.show, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StagesGrid extends StatelessWidget {
  final List<Stage> stages;
  const _StagesGrid({required this.stages});

  @override
  Widget build(final BuildContext context) {
    if (stages.isEmpty) {
      return const _EmptyState(
        icon: Icons.stadium_rounded,
        message: 'Henüz favori sahnen yok.\nSahne detayındaki kalbe dokunarak ekleyebilirsin.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount(context),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: stages.length,
      itemBuilder: (final context, final index) {
        final stage = stages[index];
        return Stack(
          children: [
            CustomStageCard(
              text: stage.name,
              imageUrl: stage.imageUrl,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final _) =>
                            StageDetailPage(stageId: stage.id)));
              },
            ),
            Positioned(
              top: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: FavoriteToggleButton(
                    itemId: stage.id, type: FavoriteType.stage, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayersGrid extends StatelessWidget {
  final List<Player> players;
  const _PlayersGrid({required this.players});

  @override
  Widget build(final BuildContext context) {
    if (players.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_alt_rounded,
        message: 'Henüz favori sanatçın yok.\nOyuncu kadrosundaki kalbe dokunarak ekleyebilirsin.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount(context),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: players.length,
      itemBuilder: (final context, final index) {
        final player = players[index];
        final fullName = '${player.firstName} ${player.lastName}';
        return Stack(
          children: [
            CustomStageCard(
              text: fullName,
              imageUrl: player.imageUrl,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final _) => PlayerDetailPage(
                            playerId: player.id)));
              },
            ),
            Positioned(
              top: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: FavoriteToggleButton(
                    itemId: player.id, type: FavoriteType.player, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: context.colors.outline),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: context.colors.error),
              const SizedBox(height: 16),
              const Text('Favoriler yüklenemedi.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
}

// --- TAB SEÇİCİ BİLEŞENİ ---
class _FavoriteTabSelector extends StatelessWidget {
  final TabController controller;
  final int showCount;
  final int stageCount;
  final int playerCount;

  const _FavoriteTabSelector({
    required this.controller,
    required this.showCount,
    required this.stageCount,
    required this.playerCount,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              context.colors.primary,
              context.colors.primary.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: context.colors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        labelColor: context.colors.onPrimary,
        unselectedLabelColor: context.colors.onSurfaceVariant,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(text: 'Oyunlar${showCount > 0 ? ' ($showCount)' : ''}'),
          Tab(text: 'Sahneler${stageCount > 0 ? ' ($stageCount)' : ''}'),
          Tab(text: 'Sanatçılar${playerCount > 0 ? ' ($playerCount)' : ''}'),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/pages/team_details_mobile.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// ORTAK SHIMMER BİLEŞENLERİ
// =============================================================================

class _SearchShimmer {
  static Widget horizontalMosaicShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Etkinlikler Vitrini",
          subtitle: "Akışta Kal",
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (final context, final index) {
              int flexTop, flexBottom;
              final int patternStep = index % 4;
              switch (patternStep) {
                case 0:
                  flexTop = 5;
                  flexBottom = 2;
                  break;
                case 1:
                  flexTop = 3;
                  flexBottom = 4;
                  break;
                case 2:
                  flexTop = 2;
                  flexBottom = 5;
                  break;
                default:
                  flexTop = 4;
                  flexBottom = 3;
                  break;
              }

              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    Expanded(
                      flex: flexTop,
                      child: const ShimmerLoading(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: flexBottom,
                      child: const ShimmerLoading(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static Widget horizontalListShimmer({
    required String title,
    required String subtitle,
    bool isStage = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (final context, final index) {
              return const ShimmerCard(width: 220, height: 150);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static Widget playerSectionShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Performansçılar",
          subtitle: "Sahnenin Yıldızları",
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (final context, final index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: ShimmerCard(height: 120, width: 120),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(height: 12, width: 80, isCircular: true),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static Widget verticalMosaicShimmer({int itemCount = 6}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (final context, final index) {
        if (index % 2 == 0 && index + 1 < itemCount) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: 200 + (index % 3) * 30,
                    borderRadius: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: 220 + (index % 2) * 40,
                    borderRadius: 20,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      itemCount: (itemCount / 2).ceil(),
    );
  }

  static Widget verticalGridShimmer({
    int crossAxisCount = 2,
    double itemHeight = 200,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          width: double.infinity,
          height: itemHeight,
          borderRadius: 16,
        );
      },
    );
  }
}

// =============================================================================
// YATAY MOZAİK BİLEŞENİ (Shimmer entegre)
// =============================================================================

class HorizontalMosaicSection extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;

  const HorizontalMosaicSection({
    super.key,
    required this.shows,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading) {
      return SliverToBoxAdapter(
        child: _SearchShimmer.horizontalMosaicShimmer(),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: "Etkinlikler Vitrini",
            subtitle: "Akışta Kal",
          ),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (shows.length / 2).ceil(),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (final context, final index) {
                final int firstIndex = index * 2;
                final int secondIndex = firstIndex + 1;
                final Show? show1 =
                    firstIndex < shows.length ? shows[firstIndex] : null;
                final Show? show2 =
                    secondIndex < shows.length ? shows[secondIndex] : null;
                if (show1 == null) return const SizedBox();

                int flexTop, flexBottom;
                final int patternStep = index % 4;
                switch (patternStep) {
                  case 0:
                    flexTop = 5;
                    flexBottom = 2;
                    break;
                  case 1:
                    flexTop = 3;
                    flexBottom = 4;
                    break;
                  case 2:
                    flexTop = 2;
                    flexBottom = 5;
                    break;
                  case 3:
                    flexTop = 4;
                    flexBottom = 3;
                    break;
                  default:
                    flexTop = 1;
                    flexBottom = 1;
                }

                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Expanded(
                        flex: flexTop,
                        child: _MosaicShowCard(
                          show: show1,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (final _) =>
                                  ShowDetailPage(showId: show1.id),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (show2 != null)
                        Expanded(
                          flex: flexBottom,
                          child: _MosaicShowCard(
                            show: show2,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (final _) =>
                                    ShowDetailPage(showId: show2.id),
                              ),
                            ),
                          ),
                        )
                      else
                        Spacer(flex: flexBottom),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MosaicShowCard extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const _MosaicShowCard({required this.show, required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(
                imageUrl: show.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "ETKİNLİK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// YATAY LİSTE BİLEŞENİ (Shimmer entegre)
// =============================================================================

class HorizontalListSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<dynamic> items;
  final bool isStage;
  final bool isLoading;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isStage,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading) {
      return _SearchShimmer.horizontalListShimmer(
        title: title,
        subtitle: subtitle,
        isStage: isStage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final context, final index) {
              return HorizontalCard(
                item: items[index],
                isStage: isStage,
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class HorizontalCard extends StatelessWidget {
  final dynamic item;
  final bool isStage;

  const HorizontalCard({
    super.key,
    required this.item,
    required this.isStage,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: () {
          if (isStage)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final _) => StageDetailPage(stageId: item.id),
              ),
            );
          else
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final _) => TeamDetailsPage(teamId: item.id),
              ),
            );
        },
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                height: 142,
                child: OptimizedCachedImage(
                  imageUrl: item.imageUrl,
                  width: 90,
                  height: 142,
                  borderRadius: 16,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStage ? "MEKAN" : "EKİP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// OYUNCU BÖLÜMÜ (Shimmer entegre)
// =============================================================================

class PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isLoading;

  const PlayerSection({
    super.key,
    required this.players,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading) {
      return _SearchShimmer.playerSectionShimmer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Performansçılar",
          subtitle: "Sahnenin Yıldızları",
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final context, final index) =>
                PlayerHeroCard(player: players[index]),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// ANA SEARCH PAGE (Basitleştirilmiş ve Optimize Edilmiş)
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  int _selectedFilterIndex = 0;

  // Manuel pagination
  int _showsPage = 0;
  int _playersPage = 0;
  int _stagesPage = 0;
  int _teamsPage = 0;
  final int _itemsPerPage = 20;

  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _initializeData();
      _scrollController.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_selectedFilterIndex == 0) return; // Tümü'nde pagination yok

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    await Future.wait([
      if (ref.read(showProvider).isListNullOrEmpty)
        ref.read(showProvider.notifier).loadShows(true),
      if (ref.read(playerProvider).isListNullOrEmpty)
        ref.read(playerProvider.notifier).getPlayers(true),
      if (ref.read(stageProvider).isListNullOrEmpty)
        ref.read(stageProvider.notifier).loadStages(true),
      if (ref.read(teamProvider).isListNullOrEmpty)
        ref.read(teamProvider.notifier).loadTeams(true),
    ]);
    setState(() => _isInitialized = true);
  }

  void _onSearchChanged(final String query) =>
      ref.read(searchQueryProvider.notifier).setQuery(query.toLowerCase());

  void _resetPagination() => setState(() {
        _showsPage = 0;
        _playersPage = 0;
        _stagesPage = 0;
        _teamsPage = 0;
      });

  void _loadMoreItems() {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final searchQuery = ref.read(searchQueryProvider);

          if (_selectedFilterIndex == 1) {
            final totalShows = _filterItems(
                  ref.read(showProvider).dataList,
                  (final s) => s.name,
                  searchQuery,
                )?.length ??
                0;
            if ((_showsPage + 1) * _itemsPerPage < totalShows) _showsPage++;
          } else if (_selectedFilterIndex == 2) {
            final totalPlayers = _filterItems(
                  ref.read(playerProvider).dataList,
                  (final p) => '${p.firstName} ${p.lastName}',
                  searchQuery,
                )?.length ??
                0;
            if ((_playersPage + 1) * _itemsPerPage < totalPlayers) {
              _playersPage++;
            }
          } else if (_selectedFilterIndex == 3) {
            final totalStages = _filterItems(
                  ref.read(stageProvider).dataList,
                  (final s) => s.name,
                  searchQuery,
                )?.length ??
                0;
            if ((_stagesPage + 1) * _itemsPerPage < totalStages) _stagesPage++;
          } else if (_selectedFilterIndex == 4) {
            final totalTeams = _filterItems(
                  ref.read(teamProvider).dataList,
                  (final t) => t.name,
                  searchQuery,
                )?.length ??
                0;
            if ((_teamsPage + 1) * _itemsPerPage < totalTeams) _teamsPage++;
          }
          _isLoadingMore = false;
        });
      }
    });
  }

  List<T>? _filterItems<T>(
    final List<T>? items,
    final String Function(T) selector,
    final String query,
  ) {
    if (items == null) return null;
    if (query.isEmpty) return items;
    return items
        .where((final item) => selector(item).toLowerCase().contains(query))
        .toList();
  }

  List<T> _getPaginatedItems<T>(final List<T> items, final int page) =>
      items.sublist(0, math.min((page + 1) * _itemsPerPage, items.length));

  @override
  Widget build(final BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);

    final bool showsLoading = showState.isLoading || !_isInitialized;
    final bool playersLoading = playerState.isLoading || !_isInitialized;
    final bool stagesLoading = stageState.isLoading || !_isInitialized;
    final bool teamsLoading = teamState.isLoading || !_isInitialized;

    // Filtreleme
    final shows = _filterItems(
          showState.dataList,
          (final s) => s.name,
          searchQuery,
        ) ??
        <Show>[];
    final players = _filterItems(
          playerState.dataList,
          (final p) => '${p.firstName} ${p.lastName}',
          searchQuery,
        ) ??
        <Player>[];
    final stages = _filterItems(
          stageState.dataList,
          (final s) => s.name,
          searchQuery,
        ) ??
        <Stage>[];
    final teams = _filterItems(
          teamState.dataList,
          (final t) => t.name,
          searchQuery,
        ) ??
        <Team>[];

    // Pagination uygula
    final paginatedShows = _selectedFilterIndex == 0
        ? shows
        : (shows.isNotEmpty ? _getPaginatedItems(shows, _showsPage) : <Show>[]);
    final paginatedPlayers = _selectedFilterIndex == 0
        ? players
        : (players.isNotEmpty
            ? _getPaginatedItems(players, _playersPage)
            : <Player>[]);
    final paginatedStages = _selectedFilterIndex == 0
        ? stages
        : (stages.isNotEmpty
            ? _getPaginatedItems(stages, _stagesPage)
            : <Stage>[]);
    final paginatedTeams = _selectedFilterIndex == 0
        ? teams
        : (teams.isNotEmpty ? _getPaginatedItems(teams, _teamsPage) : <Team>[]);

    final bool isAllEmpty = !showsLoading &&
        !playersLoading &&
        !stagesLoading &&
        !teamsLoading &&
        paginatedShows.isEmpty &&
        paginatedPlayers.isEmpty &&
        paginatedStages.isEmpty &&
        paginatedTeams.isEmpty;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: ThemeBackground()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TopHeader(title: "Tablolarımız"),
                        const SizedBox(height: 20),
                        GlassSearchBar(
                          controller: _textEditingController,
                          onChanged: _onSearchChanged,
                        ),
                      ],
                    ),
                  ),
                ),

                // FILTERS
                SliverToBoxAdapter(
                  child: FilterList(
                    selectedIndex: _selectedFilterIndex,
                    onSelected: (final index) {
                      setState(() => _selectedFilterIndex = index);
                      _resetPagination();
                      // Scroll'u en üste getir
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                  ),
                ),

                // CONTENT
                if (_selectedFilterIndex == 0) ...[
                  // TÜMÜ - Yatay scroll sections
                  if (playersLoading)
                    SliverToBoxAdapter(
                      child: _SearchShimmer.playerSectionShimmer(),
                    )
                  else if (paginatedPlayers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PlayerSection(players: paginatedPlayers),
                    ),
                  if (showsLoading)
                    const SliverToBoxAdapter(
                      child: HorizontalMosaicSection(
                        shows: [],
                        isLoading: true,
                      ),
                    )
                  else if (paginatedShows.isNotEmpty)
                    HorizontalMosaicSection(shows: paginatedShows),
                  if (stagesLoading)
                    SliverToBoxAdapter(
                      child: _SearchShimmer.horizontalListShimmer(
                        title: "Mekanlar",
                        subtitle: "Atmosfer",
                        isStage: true,
                      ),
                    )
                  else if (paginatedStages.isNotEmpty)
                    SliverToBoxAdapter(
                      child: HorizontalListSection(
                        title: "Mekanlar",
                        subtitle: "Atmosfer",
                        items: paginatedStages,
                        isStage: true,
                      ),
                    ),
                  if (teamsLoading)
                    SliverToBoxAdapter(
                      child: _SearchShimmer.horizontalListShimmer(
                        title: "Ekipler",
                        subtitle: "Mutfak",
                        isStage: false,
                      ),
                    )
                  else if (paginatedTeams.isNotEmpty)
                    SliverToBoxAdapter(
                      child: HorizontalListSection(
                        title: "Ekipler",
                        subtitle: "Mutfak",
                        items: paginatedTeams,
                        isStage: false,
                      ),
                    ),
                ] else ...[
                  // FİLTRE SEÇİLİ - Dikey grid/mosaic
                  ..._buildFilteredContent(
                    context: context,
                    filterIndex: _selectedFilterIndex,
                    shows: paginatedShows,
                    players: paginatedPlayers,
                    stages: paginatedStages,
                    teams: paginatedTeams,
                    showsLoading: showsLoading,
                    playersLoading: playersLoading,
                    stagesLoading: stagesLoading,
                    teamsLoading: teamsLoading,
                  ),
                  if (_isLoadingMore) _buildLoadingIndicator(),
                ],

                // EMPTY STATE
                if (isAllEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: context.colors.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aradığınız kriterlere uygun\nsonuç bulunamadı.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredContent({
    required BuildContext context,
    required int filterIndex,
    required List<Show> shows,
    required List<Player> players,
    required List<Stage> stages,
    required List<Team> teams,
    required bool showsLoading,
    required bool playersLoading,
    required bool stagesLoading,
    required bool teamsLoading,
  }) {
    switch (filterIndex) {
      case 1: // Etkinlikler
        return [
          if (showsLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _SearchShimmer.verticalGridShimmer(),
              ),
            )
          else if (shows.isNotEmpty)
            _buildShowsGrid(shows)
          else
            _buildEmptyState("etkinlik", context),
        ];

      case 2: // Oyuncular
        return [
          if (playersLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _SearchShimmer.verticalGridShimmer(
                  crossAxisCount: 3,
                  itemHeight: 180,
                ),
              ),
            )
          else if (players.isNotEmpty)
            _buildPlayersGrid(players)
          else
            _buildEmptyState("oyuncu", context),
        ];

      case 3: // Mekanlar
        return [
          if (stagesLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _SearchShimmer.verticalGridShimmer(),
              ),
            )
          else if (stages.isNotEmpty)
            _buildStagesGrid(stages)
          else
            _buildEmptyState("mekan", context),
        ];

      case 4: // Ekipler
        return [
          if (teamsLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _SearchShimmer.verticalGridShimmer(),
              ),
            )
          else if (teams.isNotEmpty)
            _buildTeamsGrid(teams)
          else
            _buildEmptyState("ekip", context),
        ];

      default:
        return [];
    }
  }

  SliverGrid _buildShowsGrid(List<Show> shows) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final show = shows[index];
          return _buildShowCard(context, show);
        },
        childCount: shows.length,
      ),
    );
  }

  SliverGrid _buildPlayersGrid(List<Player> players) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final player = players[index];
          return _buildPlayerCard(context, player);
        },
        childCount: players.length,
      ),
    );
  }

  SliverGrid _buildStagesGrid(List<Stage> stages) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stage = stages[index];
          return _buildStageCard(context, stage);
        },
        childCount: stages.length,
      ),
    );
  }

  SliverGrid _buildTeamsGrid(List<Team> teams) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final team = teams[index];
          return _buildTeamCard(context, team);
        },
        childCount: teams.length,
      ),
    );
  }

  Widget _buildShowCard(BuildContext context, Show show) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShowDetailPage(showId: show.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(
                imageUrl: show.imageUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ETKİNLİK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, Player player) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDetailPage(playerId: player.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profil Resmi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OptimizedCachedImage(
                    imageUrl: player.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // İsim
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "OYUNCU",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    player.lastName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(BuildContext context, Stage stage) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StageDetailPage(stageId: stage.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resim
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: OptimizedCachedImage(
                  imageUrl: stage.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "MEKAN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stage.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamDetailsPage(teamId: team.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resim
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: OptimizedCachedImage(
                  imageUrl: team.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "EKİP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type, BuildContext context) {
    final searchQuery = ref.read(searchQueryProvider);
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: context.colors.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? "$type aramak için yazmaya başlayın"
                  : '"$searchQuery" için $type bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        ),
      );
}

// =============================================================================
// DİĞER BİLEŞENLER (Aynı Kalacak)
// =============================================================================

class FilterList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const FilterList({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(final BuildContext context) {
    final filters = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    final List<List<Color>> artisticColorPalettes = [
      [
        WebColors.darkBlueBackground,
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent
      ],
      [
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA)
      ],
      [Colors.pink.shade500, Colors.purple.shade600, const Color(0xFF444653)],
      [
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent,
        AppDarkColors.primaryVariant
      ],
      [WebColors.success, const Color(0xFF2E7D32), const Color(0xFFA5D6A7)],
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (final context, final index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: ArtisticBrushChip(
            text: filters[index],
            isSelected: selectedIndex == index,
            colors: artisticColorPalettes[index],
            onTap: () => onSelected(index),
          ),
        ),
      ),
    );
  }
}

class ArtisticBrushChip extends StatefulWidget {
  final String text;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const ArtisticBrushChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<ArtisticBrushChip> createState() => _ArtisticBrushChipState();
}

class _ArtisticBrushChipState extends State<ArtisticBrushChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isSelected) _controller.forward();
  }

  @override
  void didUpdateWidget(final ArtisticBrushChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (final _) => _controller.forward(),
        onTapUp: (final _) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 90),
            decoration: BoxDecoration(
              borderRadius: _createArtisticBorderRadius(),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isSelected
                    ? [widget.colors[0], widget.colors[1]]
                    : [
                        context.isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFF8FAFC),
                        context.isDarkMode
                            ? const Color(0xFF3C3E4A)
                            : const Color(0xFFEDF2F7),
                      ],
              ),
              border: Border.all(
                color: widget.isSelected
                    ? widget.colors[0].withOpacity(0.8)
                    : context.colors.onSurface.withOpacity(0.1),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.colors[0].withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: widget.colors[2].withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: widget.colors[0].withOpacity(0.1),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Stack(
              children: [
                if (widget.isSelected)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PaintDropletPainter(colors: widget.colors),
                    ),
                  ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: widget.isSelected
                            ? Colors.white
                            : context.colors.onSurface.withOpacity(0.7),
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  BorderRadius _createArtisticBorderRadius() => BorderRadius.only(
        topLeft: const Radius.circular(24),
        bottomRight: const Radius.circular(24),
        topRight: Radius.circular(widget.isSelected ? 10 : 18),
        bottomLeft: Radius.circular(widget.isSelected ? 18 : 10),
      );
}

class _PaintDropletPainter extends CustomPainter {
  final List<Color> colors;

  _PaintDropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[1].withOpacity(0.15);
    final rng = math.Random(colors.hashCode);
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 6 + 2;
      final colorIndex = rng.nextInt(colors.length);
      paint.color =
          colors[colorIndex].withOpacity(rng.nextDouble() * 0.2 + 0.1);
      canvas.drawOval(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: context.colors.onSurface.withOpacity(0.1)),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: context.colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Sanatın izini sür...',
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                prefixIcon:
                    Icon(Icons.search_rounded, color: context.primaryColor),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      );
}

class ThemeBackground extends StatelessWidget {
  const ThemeBackground({super.key});

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.scaffoldBackgroundColor,
              context.colors.surface.withOpacity(0.5),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      );
}

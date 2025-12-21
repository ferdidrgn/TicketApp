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
// ORTAK UTILITY BİLEŞENLERİ
// =============================================================================

class _SearchUtils {
  static List<T>? filterItems<T>(
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

  static List<T> paginateItems<T>(
      final List<T> items, final int page, final int itemsPerPage) {
    final start = page * itemsPerPage;
    final end = math.min(start + itemsPerPage, items.length);
    return items.sublist(0, end);
  }
}

class _SearchShimmers {
  static Widget horizontalMosaic() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (final context, final index) {
                final pattern = index % 4;
                final flexes = _getMosaicFlexes(pattern);
                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Expanded(flex: flexes.$1, child: _shimmerBox(20)),
                      const SizedBox(height: 10),
                      Expanded(flex: flexes.$2, child: _shimmerBox(20)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );

  static Widget horizontalList(
          {required final String title, required final String subtitle}) =>
      Column(
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
              itemBuilder: (final context, final index) =>
                  const ShimmerCard(width: 220, height: 150),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );

  static Widget playerSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: "Performansçılar", subtitle: "Sahnenin Yıldızları"),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (final context, final index) => Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Expanded(child: ShimmerCard(height: 120, width: 120)),
                    const SizedBox(height: 8),
                    ShimmerLoading(height: 12, width: 80, isCircular: true),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );

  static Widget verticalGrid({
    final int crossAxisCount = 2,
    final double itemHeight = 200,
    final int itemCount = 6,
  }) =>
      GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (final context, final index) =>
            _shimmerBox(16, height: itemHeight),
      );

  static Widget _shimmerBox(final double borderRadius,
          {final double? height}) =>
      ShimmerLoading(
        width: double.infinity,
        height: height ?? double.infinity,
        borderRadius: borderRadius,
      );

  static (int, int) _getMosaicFlexes(final int pattern) {
    switch (pattern) {
      case 0:
        return (5, 2);
      case 1:
        return (3, 4);
      case 2:
        return (2, 5);
      case 3:
        return (4, 3);
      default:
        return (1, 1);
    }
  }
}

class _SearchGrids {
  static SliverGrid buildGrid<T>({
    required final List<T> items,
    required final Widget Function(BuildContext, T) itemBuilder,
    final int crossAxisCount = 2,
    final double childAspectRatio = 0.8,
    final double spacing = 16,
  }) =>
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (final context, final index) => itemBuilder(context, items[index]),
          childCount: items.length,
        ),
      );
}

class _SearchCards {
  static Widget showCard(final BuildContext context, final Show show,
          final VoidCallback onTap) =>
      _baseCard(
        context: context,
        imageUrl: show.imageUrl,
        label: "ETKİNLİK",
        title: show.name,
        onTap: onTap,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          stops: const [0.4, 1.0],
        ),
      );

  static Widget playerCard(final BuildContext context, final Player player,
          final VoidCallback onTap) =>
      Container(
        decoration: _cardDecoration(context),
        child: Column(
          children: [
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
            _cardLabel(context, "OYUNCU"),
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
            const SizedBox(height: 8),
          ],
        ),
      );

  static Widget stageCard(final BuildContext context, final Stage stage,
          final VoidCallback onTap) =>
      _verticalCard(
        context: context,
        imageUrl: stage.imageUrl,
        label: "MEKAN",
        title: stage.name,
        onTap: onTap,
      );

  static Widget teamCard(final BuildContext context, final Team team,
          final VoidCallback onTap) =>
      _verticalCard(
        context: context,
        imageUrl: team.imageUrl,
        label: "EKİP",
        title: team.name,
        onTap: onTap,
      );

  static Widget _verticalCard({
    required final BuildContext context,
    required final String imageUrl,
    required final String label,
    required final String title,
    required final VoidCallback onTap,
  }) =>
      Container(
        decoration: _cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child:
                    OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardLabel(context, label),
                  const SizedBox(height: 8),
                  Text(
                    title,
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
      );

  static Widget _baseCard({
    required final BuildContext context,
    required final String imageUrl,
    required final String label,
    required final String title,
    required final VoidCallback onTap,
    required final Gradient gradient,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [_cardShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
                Container(decoration: BoxDecoration(gradient: gradient)),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardLabel(context, label, isDark: true),
                      const SizedBox(height: 8),
                      Text(
                        title,
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

  static BoxDecoration _cardDecoration(final BuildContext context) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.colors.surface,
        boxShadow: [_cardShadow],
      );

  static BoxShadow get _cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static Widget _cardLabel(final BuildContext context, final String text,
          {final bool isDark = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? context.primaryColor.withOpacity(0.9)
              : context.primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

// =============================================================================
// YATAY SCROLL BİLEŞENLERİ
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
    if (isLoading)
      return SliverToBoxAdapter(child: _SearchShimmers.horizontalMosaic());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (shows.length / 2).ceil(),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (final context, final index) {
                final show1 = _getShow(shows, index * 2);
                final show2 = _getShow(shows, index * 2 + 1);
                if (show1 == null) return const SizedBox();

                final flexes = _SearchShimmers._getMosaicFlexes(index % 4);
                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Expanded(
                          flex: flexes.$1, child: _mosaicCard(context, show1)),
                      const SizedBox(height: 10),
                      show2 != null
                          ? Expanded(
                              flex: flexes.$2,
                              child: _mosaicCard(context, show2))
                          : Spacer(flex: flexes.$2),
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

  Show? _getShow(final List<Show> shows, final int index) =>
      index < shows.length ? shows[index] : null;

  Widget _mosaicCard(final BuildContext context, final Show show) =>
      GestureDetector(
        onTap: () => _navigateToShow(context, show),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
              Container(decoration: _mosaicGradient),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("ETKİNLİK",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  BoxDecoration get _mosaicGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          stops: const [0.5, 1.0],
        ),
      );

  void _navigateToShow(final BuildContext context, final Show show) =>
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (final _) => ShowDetailPage(showId: show.id)),
      );
}

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
    if (isLoading)
      return _SearchShimmers.horizontalList(title: title, subtitle: subtitle);

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
            itemBuilder: (final context, final index) =>
                HorizontalCard(item: items[index], isStage: isStage),
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

  const HorizontalCard({super.key, required this.item, required this.isStage});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: () => _navigate(context),
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: _cardBorderRadius,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isStage ? "MEKAN" : "EKİP",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.primaryColor)),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(item.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  BorderRadius get _cardBorderRadius => const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(4),
      );

  void _navigate(final BuildContext context) {
    final route = isStage
        ? MaterialPageRoute(
            builder: (final _) => StageDetailPage(stageId: item.id))
        : MaterialPageRoute(
            builder: (final _) => TeamDetailsPage(teamId: item.id));
    Navigator.push(context, route);
  }
}

class PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isLoading;

  const PlayerSection(
      {super.key, required this.players, this.isLoading = false});

  @override
  Widget build(final BuildContext context) {
    if (isLoading) return _SearchShimmers.playerSection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: "Performansçılar", subtitle: "Sahnenin Yıldızları"),
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
// ANA SEARCH PAGE (En Sade Hali)
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 20;

  bool _isInitialized = false;
  int _selectedFilter = 0;
  int _showsPage = 0, _playersPage = 0, _stagesPage = 0, _teamsPage = 0;
  bool _loadingMore = false;

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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _onScroll() {
    if (_selectedFilter == 0 || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        final query = ref.read(searchQueryProvider);
        final counts = _getTotalCounts(query);

        if (_selectedFilter == 1 &&
            (_showsPage + 1) * _itemsPerPage < counts.shows) _showsPage++;
        if (_selectedFilter == 2 &&
            (_playersPage + 1) * _itemsPerPage < counts.players) _playersPage++;
        if (_selectedFilter == 3 &&
            (_stagesPage + 1) * _itemsPerPage < counts.stages) _stagesPage++;
        if (_selectedFilter == 4 &&
            (_teamsPage + 1) * _itemsPerPage < counts.teams) _teamsPage++;

        _loadingMore = false;
      });
    });
  }

  ({int shows, int players, int stages, int teams}) _getTotalCounts(
          final String query) =>
      (
        shows: _SearchUtils.filterItems(
                    ref.read(showProvider).dataList, (final s) => s.name, query)
                ?.length ??
            0,
        players: _SearchUtils.filterItems(ref.read(playerProvider).dataList,
                    (final p) => '${p.firstName} ${p.lastName}', query)
                ?.length ??
            0,
        stages: _SearchUtils.filterItems(ref.read(stageProvider).dataList,
                    (final s) => s.name, query)
                ?.length ??
            0,
        teams: _SearchUtils.filterItems(
                    ref.read(teamProvider).dataList, (final t) => t.name, query)
                ?.length ??
            0,
      );

  List<T> _getPaginatedItems<T>(final List<T> items, final int page) =>
      _SearchUtils.paginateItems(items, page, _itemsPerPage);

  @override
  Widget build(final BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final states = (
      shows: ref.watch(showProvider),
      players: ref.watch(playerProvider),
      stages: ref.watch(stageProvider),
      teams: ref.watch(teamProvider),
    );

    // İsimlendirilmiş Kayıt (Named Record) oluşturuyoruz
    final loadingStates = (
      shows: states.shows.isLoading || !_isInitialized,
      players: states.players.isLoading || !_isInitialized,
      stages: states.stages.isLoading || !_isInitialized,
      teams: states.teams.isLoading || !_isInitialized,
    );

    final filtered = (
      shows: _SearchUtils.filterItems(
              states.shows.dataList, (final s) => s.name, query) ??
          [],
      players: _SearchUtils.filterItems(states.players.dataList,
              (final p) => '${p.firstName} ${p.lastName}', query) ??
          [],
      stages: _SearchUtils.filterItems(
              states.stages.dataList, (final s) => s.name, query) ??
          [],
      teams: _SearchUtils.filterItems(
              states.teams.dataList, (final t) => t.name, query) ??
          [],
    );

    // İsimlendirilmiş Kayıt (Named Record) oluşturuyoruz
    final paginated = (
      shows: _selectedFilter == 0
          ? filtered.shows
          : _getPaginatedItems(filtered.shows, _showsPage),
      players: _selectedFilter == 0
          ? filtered.players
          : _getPaginatedItems(filtered.players, _playersPage),
      stages: _selectedFilter == 0
          ? filtered.stages
          : _getPaginatedItems(filtered.stages, _stagesPage),
      teams: _selectedFilter == 0
          ? filtered.teams
          : _getPaginatedItems(filtered.teams, _teamsPage),
    );

    final isEmpty = !loadingStates.shows &&
        !loadingStates.players &&
        !loadingStates.stages &&
        !loadingStates.teams &&
        paginated.shows.isEmpty &&
        paginated.players.isEmpty &&
        paginated.stages.isEmpty &&
        paginated.teams.isEmpty;

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
                _buildHeader(context),
                _buildFilters(),
                // Artık burada hata vermeyecek çünkü aşağıda imzaları düzelttik
                ..._buildContent(
                  context: context,
                  filter: _selectedFilter,
                  loading: loadingStates,
                  paginated: paginated,
                  isEmpty: isEmpty,
                ),
                if (_loadingMore) _buildLoadingIndicator(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(final BuildContext context) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopHeader(title: "Tablolarımız"),
              const SizedBox(height: 20),
              GlassSearchBar(
                controller: _textController,
                onChanged: (final q) => ref
                    .read(searchQueryProvider.notifier)
                    .setQuery(q.toLowerCase()),
              ),
            ],
          ),
        ),
      );

  SliverToBoxAdapter _buildFilters() => SliverToBoxAdapter(
        child: FilterList(
          selectedIndex: _selectedFilter,
          onSelected: (final index) {
            setState(() {
              _selectedFilter = index;
              _showsPage = _playersPage = _stagesPage = _teamsPage = 0;
            });
            WidgetsBinding.instance.addPostFrameCallback((final _) {
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            });
          },
        ),
      );

  // DÜZELTME 1: Parametre imzasına {} eklendi.
  List<Widget> _buildContent({
    required final BuildContext context,
    required final int filter,
    required final ({
      bool shows,
      bool players,
      bool stages,
      bool teams
    }) loading,
    required final ({
      List<Show> shows,
      List<Player> players,
      List<Stage> stages,
      List<Team> teams
    }) paginated,
    required final bool isEmpty,
  }) {
    if (isEmpty) return [_buildEmptyState(context)];

    return filter == 0
        ? _buildAllContent(loading: loading, paginated: paginated)
        : _buildFilteredContent(
            context: context,
            filter: filter,
            loading: loading,
            paginated: paginated);
  }

  // DÜZELTME 2: Parametre imzasına {} eklendi.
  List<Widget> _buildAllContent({
    required final ({
      bool shows,
      bool players,
      bool stages,
      bool teams
    }) loading,
    required final ({
      List<Show> shows,
      List<Player> players,
      List<Stage> stages,
      List<Team> teams
    }) paginated,
  }) {
    final widgets = <Widget>[];

    if (loading.players || paginated.players.isNotEmpty) {
      widgets.add(SliverToBoxAdapter(
        child: PlayerSection(
            players: paginated.players, isLoading: loading.players),
      ));
    }

    if (loading.shows || paginated.shows.isNotEmpty) {
      widgets.add(HorizontalMosaicSection(
          shows: paginated.shows, isLoading: loading.shows));
    }

    if (loading.stages || paginated.stages.isNotEmpty) {
      widgets.add(SliverToBoxAdapter(
        child: HorizontalListSection(
          title: "Mekanlar",
          subtitle: "Atmosfer",
          items: paginated.stages,
          isStage: true,
          isLoading: loading.stages,
        ),
      ));
    }

    if (loading.teams || paginated.teams.isNotEmpty) {
      widgets.add(SliverToBoxAdapter(
        child: HorizontalListSection(
          title: "Ekipler",
          subtitle: "Mutfak",
          items: paginated.teams,
          isStage: false,
          isLoading: loading.teams,
        ),
      ));
    }

    return widgets;
  }

  // DÜZELTME 3: Parametre imzasına {} eklendi.
  List<Widget> _buildFilteredContent({
    required final BuildContext context,
    required final int filter,
    required final ({
      bool shows,
      bool players,
      bool stages,
      bool teams
    }) loading,
    required final ({
      List<Show> shows,
      List<Player> players,
      List<Stage> stages,
      List<Team> teams
    }) paginated,
  }) {
    switch (filter) {
      case 1:
        return _buildShowsContent(context, loading.shows, paginated.shows);
      case 2:
        return _buildPlayersContent(
            context, loading.players, paginated.players);
      case 3:
        return _buildStagesContent(context, loading.stages, paginated.stages);
      case 4:
        return _buildTeamsContent(context, loading.teams, paginated.teams);
      default:
        return [];
    }
  }

  List<Widget> _buildShowsContent(final BuildContext context,
          final bool loading, final List<Show> shows) =>
      [
        if (loading)
          _buildShimmerGrid(context)
        else if (shows.isNotEmpty)
          _buildShowsGrid(shows),
        if (shows.isEmpty) _buildTypeEmptyState(context, "etkinlik"),
      ];

  List<Widget> _buildPlayersContent(final BuildContext context,
          final bool loading, final List<Player> players) =>
      [
        if (loading)
          _buildShimmerGrid(context, crossAxisCount: 3, itemHeight: 180),
        if (players.isNotEmpty) _buildPlayersGrid(players),
        if (players.isEmpty) _buildTypeEmptyState(context, "oyuncu"),
      ];

  List<Widget> _buildStagesContent(final BuildContext context,
          final bool loading, final List<Stage> stages) =>
      [
        if (loading) _buildShimmerGrid(context, childAspectRatio: 1.2),
        if (stages.isNotEmpty) _buildStagesGrid(stages),
        if (stages.isEmpty) _buildTypeEmptyState(context, "mekan"),
      ];

  List<Widget> _buildTeamsContent(final BuildContext context,
          final bool loading, final List<Team> teams) =>
      [
        if (loading) _buildShimmerGrid(context, childAspectRatio: 1.2),
        if (teams.isNotEmpty) _buildTeamsGrid(teams),
        if (teams.isEmpty) _buildTypeEmptyState(context, "ekip"),
      ];

  SliverToBoxAdapter _buildShimmerGrid(
    final BuildContext context, {
    final int crossAxisCount = 2,
    final double itemHeight = 200,
    final double childAspectRatio = 0.8,
  }) =>
      SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _SearchShimmers.verticalGrid(
            crossAxisCount: crossAxisCount,
            itemHeight: itemHeight,
          ),
        ),
      );

  SliverGrid _buildShowsGrid(final List<Show> shows) => _SearchGrids.buildGrid(
        items: shows,
        itemBuilder: (final context, final show) => _SearchCards.showCard(
          context,
          show,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => ShowDetailPage(showId: show.id))),
        ),
      );

  SliverGrid _buildPlayersGrid(final List<Player> players) =>
      _SearchGrids.buildGrid(
        items: players,
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        itemBuilder: (final context, final player) => _SearchCards.playerCard(
          context,
          player,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => PlayerDetailPage(playerId: player.id))),
        ),
      );

  SliverGrid _buildStagesGrid(final List<Stage> stages) =>
      _SearchGrids.buildGrid(
        items: stages,
        childAspectRatio: 1.2,
        itemBuilder: (final context, final stage) => _SearchCards.stageCard(
          context,
          stage,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => StageDetailPage(stageId: stage.id))),
        ),
      );

  SliverGrid _buildTeamsGrid(final List<Team> teams) => _SearchGrids.buildGrid(
        items: teams,
        childAspectRatio: 1.2,
        itemBuilder: (final context, final team) => _SearchCards.teamCard(
          context,
          team,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => TeamDetailsPage(teamId: team.id))),
        ),
      );

  SliverFillRemaining _buildEmptyState(final BuildContext context) =>
      SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 80, color: context.colors.onSurface.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text("Aradığınız kriterlere uygun\nsonuç bulunamadı.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      );

  SliverFillRemaining _buildTypeEmptyState(
      final BuildContext context, final String type) {
    final query = ref.read(searchQueryProvider);
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 80, color: context.colors.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? "$type aramak için yazmaya başlayın"
                  : '"$query" için $type bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildLoadingIndicator() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(context.primaryColor)),
          ),
        ),
      );
}
// =============================================================================
// DİĞER BİLEŞENLER (Kısa ve Öz)
// =============================================================================

class FilterList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const FilterList(
      {super.key, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(final BuildContext context) {
    final filters = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    final palettes = [
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
            colors: palettes[index],
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
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forwardIf(widget.isSelected);

  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void didUpdateWidget(covariant final ArtisticBrushChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.isSelected != oldWidget.isSelected
        ? (widget.isSelected ? _controller.forward() : _controller.reverse())
        : null;
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
        onTapCancel: _controller.reverse,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 90),
            decoration: BoxDecoration(
              borderRadius: _borderRadius,
              gradient: _gradient(context),
              border: Border.all(
                  color: _borderColor(context),
                  width: widget.isSelected ? 2 : 1),
              boxShadow: _shadows,
            ),
            child: Stack(
              children: [
                if (widget.isSelected)
                  Positioned.fill(
                      child: CustomPaint(
                          painter:
                              _PaintDropletPainter(colors: widget.colors))),
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
                      child: Text(widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  BorderRadius get _borderRadius => BorderRadius.only(
        topLeft: const Radius.circular(24),
        bottomRight: const Radius.circular(24),
        topRight: Radius.circular(widget.isSelected ? 10 : 18),
        bottomLeft: Radius.circular(widget.isSelected ? 18 : 10),
      );

  LinearGradient _gradient(final BuildContext context) => LinearGradient(
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
      );

  Color _borderColor(final BuildContext context) => widget.isSelected
      ? widget.colors[0].withOpacity(0.8)
      : context.colors.onSurface.withOpacity(0.1);

  List<BoxShadow> get _shadows => widget.isSelected
      ? [
          BoxShadow(
              color: widget.colors[0].withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 3)),
          BoxShadow(
              color: widget.colors[2].withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, -2)),
          BoxShadow(
              color: widget.colors[0].withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 5),
        ]
      : [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ];
}

extension on AnimationController {
  void forwardIf(final bool condition) => condition ? forward() : null;
}

class _PaintDropletPainter extends CustomPainter {
  final List<Color> colors;

  _PaintDropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(colors.hashCode);

    for (int i = 0; i < 8; i++) {
      paint.color = colors[rng.nextInt(colors.length)]
          .withOpacity(rng.nextDouble() * 0.2 + 0.1);
      canvas.drawOval(
        Rect.fromCircle(
            center: Offset(
                rng.nextDouble() * size.width, rng.nextDouble() * size.height),
            radius: rng.nextDouble() * 6 + 2),
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

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

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
                    fontStyle: FontStyle.italic),
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
              context.colors.surface.withOpacity(0.5)
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      );
}

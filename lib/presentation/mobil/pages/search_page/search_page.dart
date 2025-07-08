import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/pagination_controller.dart';
import '../../../../core/widgets/custom_category_card.dart';
import '../../../../core/widgets/custom_search.dart';
import '../../../../core/widgets/custom_show_card.dart';
import '../../../../core/widgets/custom_stage_card.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../data/providers/player/player_provider.dart';
import '../../../../data/providers/search/search_query_provider.dart';
import '../../../../data/providers/show/show_provider.dart';
import '../../../../data/providers/stage/stage_provider.dart';
import '../../../../data/providers/team/team_provider.dart';
import '../../../../domain/entities/player.dart';
import '../../../../domain/entities/show.dart';
import '../../../../domain/entities/stage.dart';
import '../../../../domain/entities/team.dart';
import '../../navigation/bottom_nav_bar.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import '../details_pages/team_details.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  PaginationController<Show>? showsPagination;
  PaginationController<Player>? playersPagination;
  PaginationController<Stage>? stagesPagination;
  PaginationController<Team>? teamsPagination;

  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isInitialized = false;
  bool _isLoading = true;

  final _categories = [
    {'title': 'Tümünü Keşfet', 'icon': Icons.explore},
    {'title': 'Trendler', 'icon': Icons.trending_up},
    {'title': 'Tiyatro', 'icon': Icons.theater_comedy},
    {'title': 'Konser/Müzik', 'icon': Icons.library_music},
    {'title': 'Stand Up', 'icon': Icons.event_seat_rounded},
    {'title': 'Festival', 'icon': Icons.festival_rounded},
    {'title': 'Sinema', 'icon': Icons.movie_filter_rounded},
    {'title': 'Çocuk', 'icon': Icons.family_restroom},
    {'title': 'Spor', 'icon': Icons.sports_baseball},
    {'title': 'Etkinlik', 'icon': Icons.event},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _initializeData());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _initializePaginationControllers() {
    showsPagination = _createPagination(ref.read(showProvider).dataList);
    playersPagination = _createPagination(ref.read(playerProvider).dataList);
    stagesPagination = _createPagination(ref.read(stageProvider).dataList);
    teamsPagination = _createPagination(ref.read(teamProvider).dataList);
  }

  PaginationController<T>? _createPagination<T>(final List<T>? list) {
    if (list == null) return null;
    return PaginationController(allItems: list, itemsPerPage: 20);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() => setState(() {
        showsPagination?.loadMoreItems();
        playersPagination?.loadMoreItems();
        stagesPagination?.loadMoreItems();
        teamsPagination?.loadMoreItems();
      });

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    setState(() {
      _isLoading = true;
      ref.read(searchQueryProvider.notifier).state = "";
    });
    try {
      await Future.wait([
        if (ref.read(showProvider).isListEmpty)
          ref.read(showProvider.notifier).loadShows(true),
        if (ref.read(playerProvider).isListEmpty)
          ref.read(playerProvider.notifier).loadPlayers(true),
        if (ref.read(stageProvider).isListEmpty)
          ref.read(stageProvider.notifier).loadStages(true),
        if (ref.read(teamProvider).isListEmpty)
          ref.read(teamProvider.notifier).loadTeams(true),
      ]);
      _initializePaginationControllers();
      _resetPagination();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Data loading error: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 300),
          () => setState(() => _isLoading = false));
    }
  }

  void _onSearchChanged(final String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query.toLowerCase();
      // Reset pagination when search query changes
      _resetPagination();
    });
  }

  void _resetPagination() => setState(() {
        showsPagination?.reset();
        playersPagination?.reset();
        stagesPagination?.reset();
        teamsPagination?.reset();
        _loadMoreData();
      });

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final isAnyLoading = showState.isLoading ||
        playerState.isLoading ||
        stageState.isLoading ||
        teamState.isLoading ||
        _isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Arama', style: Theme.of(context).textTheme.headlineSmall)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(onSearchChanged: _onSearchChanged),
            const SizedBox(height: 16),
            Expanded(
                child: isAnyLoading
                    ? _buildLoadingView()
                    : _buildSearchResults(searchQuery)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerSection('Eşleşen Etkinlikler'),
            _buildShimmerSection('Gösteri Mekanları'),
            _buildShimmerSection('Oyuncular'),
            _buildShimmerSection('Kategoriler'),
          ],
        ),
      );

  Widget _buildShimmerSection(final String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (final _, final __) => const Padding(
                  padding: EdgeInsets.only(right: 8), child: ShimmerLoading()),
            ),
          ),
        ],
      );

  Widget _buildSearchResults(final String query) {
    final List<Show>? filteredShows =
        _filterItems(showsPagination?.currentItems, (final s) => s.name, query);
    final List<Player>? filteredPlayers = _filterItems(
        playersPagination?.currentItems,
        (final p) => '${p.firstName} ${p.lastName}',
        query);
    final List<Stage>? filteredStages =
        _filterItems(stagesPagination?.currentItems, (final s) => s.name, query);
    final List<Team>? filteredTeams =
        _filterItems(teamsPagination?.currentItems, (final t) => t.name, query);
    final filteredCategories = _categories
        .where((final c) =>
            query.isEmpty ||
            (c['title']! as String).toLowerCase().contains(query))
        .toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (final scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) _loadMoreData();
        return true;
      },
      child: RefreshIndicator(
        onRefresh: _initializeData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (filteredShows?.isNotEmpty ?? false)
              _buildSection( 'Eşleşen Etkinlikler', filteredShows!, _buildShowCard,
                  showAllAction: _buildShowAllButton()),
            if (filteredPlayers?.isNotEmpty ?? false)
              _buildSection('Oyuncular', filteredPlayers!, _buildPlayerCard),
            if (filteredStages?.isNotEmpty ?? false)
              _buildSection('Gösteri Mekanları', filteredStages!, _buildVenueCard),
            if (filteredTeams?.isNotEmpty ?? false)
              _buildSection('Ekipler', filteredTeams!, _buildTeamCard),
            if (filteredCategories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Kategoriler',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  CategoryCardBuilder(categories: filteredCategories),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<T>? _filterItems<T>(
      final List<T>? items, final String Function(T) selector, final String query) {
    if (items == null) return null;
    if (query.isEmpty) return items;
    return items
        .where((final item) => selector(item).toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSection<T>(
    final String title,
    final List<T> items,
    final Widget Function(BuildContext, T) itemBuilder, {
    final Widget? showAllAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (final context, final index) => itemBuilder(context, items[index]),
          ),
        ),
        if (showAllAction != null) ...[
          const SizedBox(height: 16),
          showAllAction,
        ],
      ],
    );
  }

  Widget _buildShowCard(final BuildContext context, final Show show) =>
      CustomVerticalShowCard(
        key: ValueKey(show.id),
        gameName: show.name,
        imageUrl: show.imageUrl,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (final _) => ShowDetailPage(showId: show.id))),
      );

  Widget _buildVenueCard(final BuildContext context, final Stage stage) => CustomStageCard(
        text: stage.name,
        imageUrl: stage.imageUrl,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => StageDetailPage(stageId: stage.id))),
      );

  Widget _buildPlayerCard(final BuildContext context, final Player player) =>
      CustomStageCard(
        text: '${player.firstName} ${player.lastName}',
        imageUrl: player.imageUrl,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => PlayerDetailPage(playerId: player.id))),
      );

  Widget _buildTeamCard(final BuildContext context, final Team team) =>
      CustomVerticalShowCard(
        gameName: team.name,
        imageUrl: team.imageUrl,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => TeamDetailsPage(teamId: team.id))),
      );

  Widget _buildShowAllButton() => ElevatedButton(
        onPressed: () => BottomNavBar.of(context)?.changeTabWithCategory(1, ""),
        child: const Text('Tümünü Göster',
            style: TextStyle(fontSize: 16, color: Colors.red)),
      );
}

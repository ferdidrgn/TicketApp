import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ticketapp/core/widgets/bottom_nav_bar.dart';
import 'package:ticketapp/core/widgets/custom_category_card.dart';
import 'package:ticketapp/core/widgets/custom_search.dart';
import 'package:ticketapp/core/widgets/custom_show_card.dart';
import 'package:ticketapp/core/widgets/custom_stage_card.dart';
import 'package:ticketapp/data/model/player_model.dart';
import 'package:ticketapp/data/model/show_model.dart';
import 'package:ticketapp/data/model/stage_model.dart';
import 'package:ticketapp/data/model/team_model.dart';
import 'package:ticketapp/data/providers/player/player_provider.dart';
import '../../../core/services/pagination_controller.dart';
import '../../../data/providers/search/search_query_provider.dart';
import '../../../data/providers/show/show_provider.dart';
import '../../../data/providers/stage/stage_provider.dart';
import '../../../data/providers/team/team_provider.dart';
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
  late PaginationController<ShowModel?> showsPagination;
  late PaginationController<PlayerModel?> playersPagination;
  late PaginationController<StageModel?> stagesPagination;
  late PaginationController<TeamModel?> teamsPagination;

  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isInitialized = false;
  bool _isLoading = true;

  final List<Map<String, Object>> _categories = [
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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _initializePaginationControllers() {
    showsPagination = PaginationController(
      allItems: ref.read(showProvider).shows,
      itemsPerPage: 5,
    );
    playersPagination = PaginationController(
      allItems: ref.read(playerProvider).players,
      itemsPerPage: 5,
    );
    stagesPagination = PaginationController(
      allItems: ref.read(stageProvider).stages,
      itemsPerPage: 5,
    );
    teamsPagination = PaginationController(
      allItems: ref.read(teamProvider).teams,
      itemsPerPage: 5,
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    setState(() {
      showsPagination.loadMoreItems();
      playersPagination.loadMoreItems();
      stagesPagination.loadMoreItems();
      teamsPagination.loadMoreItems();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch data concurrently
      await Future.wait([
        if (ref.read(showProvider).shows.isEmpty)
          ref.read(showProvider.notifier).loadShows(true),
        if (ref.read(playerProvider).players.isEmpty)
          ref.read(playerProvider.notifier).loadPlayers(true),
        if (ref.read(stageProvider).stages.isEmpty)
          ref.read(stageProvider.notifier).loadStages(true),
        if (ref.read(teamProvider).teams.isEmpty)
          ref.read(teamProvider.notifier).loadTeams(true),
      ]);

      _initializePaginationControllers();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Data loading error: $e');
    } finally {
      // Delay the loading state update to allow UI to render changes properly
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  void _onSearchChanged(final String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query.toLowerCase();
      // Reset pagination when search query changes
      _resetPagination();
    });
  }

  void _resetPagination() {
    setState(() {
      showsPagination.reset();
      playersPagination.reset();
      stagesPagination.reset();
      teamsPagination.reset();
    });
  }

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
      appBar: AppBar(
        title: const Text('Arama', style: TextStyle(fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(onSearchChanged: _onSearchChanged),
            const SizedBox(height: 16),
            Expanded(
              child: isAnyLoading
                  ? _buildLoadingView()
                  : _buildSearchResults(searchQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerSection('Eşleşen Etkinlikler'),
          _buildShimmerSection('Gösteri Mekanları'),
          _buildShimmerSection('Oyuncular'),
          _buildShimmerSection('Ekipler'),
          _buildShimmerSection('Kategoriler'),
        ],
      ),
    );
  }

  Widget _buildShimmerSection(final String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (final context, final index) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 130,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(final String searchQuery) {
    final filteredShows = showsPagination.currentItems
        .where((final show) =>
            searchQuery.isEmpty ||
            (show?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final filteredPlayers = playersPagination.currentItems
        .where((final player) =>
            searchQuery.isEmpty ||
            ('${player?.firstName} ${player?.lastName}')
                .toLowerCase()
                .contains(searchQuery))
        .toList();

    final filteredStages = stagesPagination.currentItems
        .where((final stage) =>
            searchQuery.isEmpty ||
            (stage?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final filteredTeams = teamsPagination.currentItems
        .where((final team) =>
            searchQuery.isEmpty ||
            (team?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final filteredCategories = _categories
        .where((final category) =>
            searchQuery.isEmpty ||
            (category['title']! as String).toLowerCase().contains(searchQuery))
        .toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (final ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200)
          _loadMoreData();

        return true;
      },
      child: RefreshIndicator(
        onRefresh: _initializeData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (filteredShows.isNotEmpty) _buildShowSection(filteredShows),
            if (filteredPlayers.isNotEmpty)
              _buildPlayerSection(filteredPlayers),
            if (filteredStages.isNotEmpty) _buildVenueSection(filteredStages),
            if (filteredTeams.isNotEmpty) _buildTeamSection(filteredTeams),
            if (filteredCategories.isNotEmpty)
              _buildCategorySection(filteredCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildShowSection(final List<ShowModel?> shows) {
    return _buildSection(
      title: 'Eşleşen Etkinlikler',
      itemCount: shows.length,
      itemBuilder: (final context, final index) =>
          _buildShowCard(context, shows[index]),
      showAllAction: _buildShowAllButton(),
    );
  }

  Widget _buildVenueSection(final List<StageModel?> stages) {
    return _buildSection(
      title: 'Gösteri Mekanları',
      itemCount: stages.length,
      itemBuilder: (final context, final index) =>
          _buildVenueCard(context, stages[index]),
    );
  }

  Widget _buildPlayerSection(final List<PlayerModel?> players) {
    return _buildSection(
      title: 'Oyuncular',
      itemCount: players.length,
      itemBuilder: (final context, final index) =>
          _buildPlayerCard(context, players[index]),
    );
  }

  Widget _buildTeamSection(final List<TeamModel?> teams) {
    return _buildSection(
      title: 'Ekipler',
      itemCount: teams.length,
      itemBuilder: (final context, final index) =>
          _buildTeamCard(context, teams[index]),
    );
  }

  Widget _buildCategorySection(final List<Map<String, Object>> categories) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text('Kategoriler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      CategoryCardBuilder(categories: categories)
    ]);
  }

  Widget _buildSection({
    required final String title,
    required final int itemCount,
    required final IndexedWidgetBuilder itemBuilder,
    final Widget? showAllAction,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(
        height: 195,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
      if (showAllAction != null) const SizedBox(height: 16),
      if (showAllAction != null) showAllAction
    ]);
  }

  Widget _buildShowCard(final BuildContext context, final ShowModel? show) {
    return CustomVerticalShowCard(
        key: ValueKey(show?.id),
        gameName: show?.name ?? '',
        imageUrl: show?.imageUrl ?? '',
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    ShowDetailPage(showId: show?.id ?? ''))));
  }

  Widget _buildVenueCard(final BuildContext context, final StageModel? stage) {
    return CustomStageCard(
        text: stage?.name ?? '',
        imageUrl: stage?.imageUrl ?? '',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    StageDetailPage(stageId: stage?.id ?? ''))));
  }

  Widget _buildPlayerCard(
      final BuildContext context, final PlayerModel? player) {
    return CustomStageCard(
        text: '${player?.firstName} ${player?.lastName}',
        imageUrl: player?.imageUrl ?? "",
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    PlayerDetailPage(playerId: player?.id ?? ''))));
  }

  Widget _buildTeamCard(final BuildContext context, final TeamModel? team) {
    return CustomVerticalShowCard(
        gameName: team?.name ?? '',
        imageUrl: team?.imageUrl ?? '',
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    TeamDetailsPage(teamId: team?.id ?? ''))));
  }

  Widget _buildShowAllButton() {
    return ElevatedButton(
        onPressed: () {
          BottomNavBar.of(context)?.changeTabWithCategory(1, "");
        },
        child: const Text('Tümünü Göster',
            style: TextStyle(fontSize: 16, color: Colors.red)));
  }
}

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
import '../../../data/providers/show/show_provider.dart';
import '../../../data/providers/stage/stage_provider.dart';
import '../../../data/providers/team/team_provider.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';
import '../details_pages/stage_details.dart';
import '../details_pages/team_details.dart';

// Arama değişimlerini debounce eden bir provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
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
    // InitState'te addPostFrameCallback kullanarak veri yükleme işlemini başlatıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
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

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Data loading error: $e');
    } finally {
      // Delay the loading state update to allow UI to render changes properly
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(final String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query.toLowerCase();
    });
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Check if any provider is loading
    final isAnyLoading = showState.isLoading || playerState.isLoading || stageState.isLoading || teamState.isLoading || _isLoading;

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

  Widget _buildShimmerSection(String title) {
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
            itemBuilder: (context, index) => Padding(
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

  Widget _buildSearchResults(String searchQuery) {
    // Verileri doğrudan provider'lardan alıp filtreliyoruz
    final shows = ref
        .watch(showProvider)
        .shows
        .where((show) =>
            searchQuery.isEmpty ||
            (show?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final players = ref
        .watch(playerProvider)
        .players
        .where((player) =>
            searchQuery.isEmpty ||
            (player?.firstName ?? '').toLowerCase().contains(searchQuery) ||
            (player?.lastName ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final stages = ref
        .watch(stageProvider)
        .stages
        .where((stage) =>
            searchQuery.isEmpty ||
            (stage?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    final teams = ref
        .watch(teamProvider)
        .teams
        .where((team) =>
            searchQuery.isEmpty ||
            (team?.name ?? '').toLowerCase().contains(searchQuery))
        .toList();

    // Kategorileri filtreleme
    final filteredCategories = searchQuery.isEmpty
        ? _categories
        : _categories
            .where((category) => (category['title'] as String)
                .toLowerCase()
                .contains(searchQuery))
            .toList();

    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shows.isNotEmpty) _buildShowSection(shows),
            if (players.isNotEmpty) _buildPlayerSection(players),
            if (stages.isNotEmpty) _buildVenueSection(stages),
            if (teams.isNotEmpty) _buildTeamSection(teams),
            if (filteredCategories.isNotEmpty)
              _buildCategorySection(filteredCategories),

            // Hiçbir sonuç yoksa
            if (shows.isEmpty &&
                players.isEmpty &&
                stages.isEmpty &&
                teams.isEmpty &&
                filteredCategories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32.0),
                  child: Text('Aramanızla eşleşen sonuç bulunamadı',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowSection(List<ShowModel?> shows) {
    return _buildSection(
      title: 'Eşleşen Etkinlikler',
      itemCount: shows.length,
      itemBuilder: (final context, final index) =>
          _buildShowCard(context, shows[index]),
      showAllAction: _buildShowAllButton(),
    );
  }

  Widget _buildVenueSection(List<StageModel?> stages) {
    return _buildSection(
      title: 'Gösteri Mekanları',
      itemCount: stages.length,
      itemBuilder: (final context, final index) =>
          _buildVenueCard(context, stages[index]),
    );
  }

  Widget _buildPlayerSection(List<PlayerModel?> players) {
    return _buildSection(
      title: 'Oyuncular',
      itemCount: players.length,
      itemBuilder: (final context, final index) =>
          _buildPlayerCard(context, players[index]),
    );
  }

  Widget _buildTeamSection(List<TeamModel?> teams) {
    return _buildSection(
      title: 'Ekipler',
      itemCount: teams.length,
      itemBuilder: (final context, final index) =>
          _buildTeamCard(context, teams[index]),
    );
  }

  Widget _buildCategorySection(List<Map<String, Object>> categories) {
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

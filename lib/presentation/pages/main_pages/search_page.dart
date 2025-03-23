import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:ticketapp/data/providers/stage/stage_state.dart';
import '../../../data/providers/player/player_state.dart';
import '../../../data/providers/show/show_provider.dart';
import '../../../data/providers/show/show_state.dart';
import '../../../data/providers/stage/stage_provider.dart';
import '../../../data/providers/team/team_provider.dart';
import '../../../data/providers/team/team_state.dart';
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
  List<ShowModel?> _filteredShows = [];
  List<PlayerModel?> _filteredPlayers = [];
  List<StageModel?> _filteredStages = [];
  List<TeamModel?> _filteredTeams = [];
  List<Map<String, Object>> _filteredCategories = [];

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

  Future<void> _fetchData(
      final ShowState showState,
      final PlayerState playerState,
      final StageState stageState,
      final TeamState teamState) async {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!showState.isLoading && showState.shows.isEmpty)
        ref.read(showProvider.notifier).loadShows(true);
      if (!playerState.isLoading && playerState.players.isEmpty)
        ref.read(playerProvider.notifier).loadPlayers(true);
      if (!stageState.isLoading && stageState.stages.isEmpty)
        ref.read(stageProvider.notifier).loadStages(true);
      if (!teamState.isLoading && teamState.teams.isEmpty)
        ref.read(teamProvider.notifier).loadTeams(true);
    });
    _updateFilteredData();
  }

  void _updateFilteredData() {
    setState(() {
      _filteredPlayers = ref.read(playerProvider).players;
      _filteredShows = ref.read(showProvider).shows;
      _filteredStages = ref.read(stageProvider).stages;
      _filteredTeams = ref.read(teamProvider).teams;
      _filteredCategories = _categories;
    });
  }

  void _filterData(final String query) {
    setState(() {
      _filteredShows = ref
          .read(showProvider)
          .shows
          .where((final show) =>
              (show?.name ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredPlayers = ref
          .read(playerProvider)
          .players
          .where((final player) =>
              (player?.firstName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (player?.lastName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
      _filteredStages = ref
          .read(stageProvider)
          .stages
          .where((final stage) =>
              (stage?.name ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredTeams = ref
          .read(teamProvider)
          .teams
          .where((final team) =>
              (team?.name ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredCategories = _categories
          .where((final category) => (category['title']! as String)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSearchChanged(final String query) => _filterData(query);

  @override
  Widget build(final BuildContext context) {
    final showNotifier = ref.watch(showProvider);
    final playerNotifier = ref.watch(playerProvider);
    final stageNotifier = ref.watch(stageProvider);
    final teamNotifier = ref.watch(teamProvider);

    if (showNotifier.isLoading ||
        playerNotifier.isLoading ||
        stageNotifier.isLoading ||
        teamNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    _fetchData(showNotifier, playerNotifier, stageNotifier, teamNotifier);

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_filteredShows.isNotEmpty) _buildShowSection(),
                    if (_filteredPlayers.isNotEmpty) _buildPlayerSection(),
                    if (_filteredStages.isNotEmpty) _buildVenueSection(),
                    if (_filteredTeams.isNotEmpty) _buildTeamSection(),
                    if (_filteredCategories.isNotEmpty) _buildCategorySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowSection() {
    return _buildSection(
        title: 'Eşleşen Etkinlikler',
        itemCount: _filteredShows.length,
        itemBuilder: (final context, final index) =>
            _buildShowCard(context, index),
        showAllAction: _buildShowAllButton());
  }

  Widget _buildVenueSection() {
    return _buildSection(
      title: 'Gösteri Mekanları',
      itemCount: _filteredStages.length,
      itemBuilder: (final context, final index) =>
          _buildVenueCard(context, index),
    );
  }

  Widget _buildPlayerSection() {
    return _buildSection(
      title: 'Oyuncular',
      itemCount: _filteredPlayers.length,
      itemBuilder: (final context, final index) =>
          _buildPlayerCard(context, index),
    );
  }

  Widget _buildTeamSection() {
    return _buildSection(
      title: 'Ekipler',
      itemCount: _filteredTeams.length,
      itemBuilder: (final context, final index) =>
          _buildTeamCard(context, index),
    );
  }

  Widget _buildCategorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Kategoriler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      CategoryCardBuilder(categories: _filteredCategories)
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
              itemBuilder: itemBuilder)),
      if (showAllAction != null) const SizedBox(height: 16),
      if (showAllAction != null) showAllAction
    ]);
  }

  Widget _buildShowCard(final BuildContext context, final int index) {
    return CustomVerticalShowCard(
        gameName: _filteredShows[index]?.name ?? '',
        imageUrl: _filteredShows[index]?.imageUrl ?? '',
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    ShowDetailPage(showId: _filteredShows[index]?.id ?? ''))));
  }

  Widget _buildVenueCard(final BuildContext context, final int index) {
    return CustomStageCard(
        text: _filteredStages[index]?.name ?? '',
        imageUrl: _filteredStages[index]?.imageUrl ?? '',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) => StageDetailPage(
                    stageId: _filteredStages[index]?.id ?? ''))));
  }

  Widget _buildPlayerCard(final BuildContext context, final int index) {
    return CustomStageCard(
        text:
            '${_filteredPlayers[index]?.firstName} ${_filteredPlayers[index]?.lastName}',
        imageUrl: _filteredPlayers[index]?.imageUrl ?? "",
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) => PlayerDetailPage(
                    playerId: _filteredPlayers[index]?.id ?? ''))));
  }

  Widget _buildTeamCard(final BuildContext context, final int index) {
    return CustomVerticalShowCard(
        gameName: _filteredTeams[index]?.name ?? '',
        imageUrl: _filteredTeams[index]?.imageUrl ?? '',
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) =>
                    TeamDetailsPage(teamId: _filteredTeams[index]?.id ?? ''))));
  }

  Widget _buildShowAllButton() {
    return ElevatedButton(
        onPressed: () {
          BottomNavBar.of(context)
              ?.changeTabWithCategory(1, ""); // "Discover" sekmesine geçiyoruz
        },
        child: const Text('Tümünü Göster',
            style: TextStyle(fontSize: 16, color: Colors.red)));
  }
}

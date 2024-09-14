import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_search.dart';
import 'package:ticketapp/data/repository/player_service.dart';
import 'package:ticketapp/data/repository/show_service.dart';
import 'package:ticketapp/data/repository/stage_service.dart';
import 'package:ticketapp/presentation/pages/details_pages/stage_details.dart';
import '../../../core/custom_views/custom_category_card.dart';
import '../../../core/custom_views/custom_show_card.dart';
import '../../../core/custom_views/custom_stage_card.dart';
import '../../../data/model/player.dart';
import '../../../data/model/show.dart';
import '../../../data/model/stage.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ShowService _showService = ShowService();
  final PlayerService _playerService = PlayerService();
  final StageService _stageService = StageService();

  List<Show?> shows = [];
  List<Player?> players = [];
  List<Stage?> stages = [];

  List<Show?> _filteredShows = [];
  List<Player?> _filteredPlayers = [];
  List<Stage?> _filteredStages = [];
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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final fetchedShows = await _showService.getShows(true);
      final fetchedPlayers = await _playerService.getPlayers(true);
      final fetchedStages = await _stageService.getStages(true);

      setState(() {
        shows = fetchedShows;
        players = fetchedPlayers;
        stages = fetchedStages;

        _filteredShows = shows;
        _filteredPlayers = players;
        _filteredStages = stages;
        _filteredCategories = _categories;
      });
    } catch (e) {
      throw Exception('Veriler getirilemedi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredShows = shows
          .where((show) =>
              (show?.name ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredPlayers = players
          .where((player) =>
              (player?.firstName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (player?.lastName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
      _filteredStages = stages
          .where((stage) =>
              (stage?.name ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredCategories = _categories
          .where((category) => (category['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSearchChanged(String query) => _filterData(query);

  @override
  Widget build(BuildContext context) {
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_filteredShows.isNotEmpty) _buildShowSection(),
                      if (_filteredPlayers.isNotEmpty) _buildPlayerSection(),
                      if (_filteredStages.isNotEmpty) _buildVenueSection(),
                      if (_filteredCategories.isNotEmpty)
                        _buildCategorySection(),
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
      itemBuilder: (context, index) => _buildShowCard(context, index),
      showAllAction: _buildShowAllButton(),
    );
  }

  Widget _buildVenueSection() {
    return _buildSection(
      title: 'Gösteri Mekanları',
      itemCount: _filteredStages.length,
      itemBuilder: (context, index) => _buildVenueCard(context, index),
    );
  }

  Widget _buildPlayerSection() {
    return _buildSection(
      title: 'Oyuncular',
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) => _buildPlayerCard(context, index),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategoriler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        CategoryCardBuilder(categories: _filteredCategories),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    Widget? showAllAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
        if (showAllAction != null) const SizedBox(height: 16),
        if (showAllAction != null) showAllAction,
      ],
    );
  }

  Widget _buildShowCard(BuildContext context, int index) {
    return CustomVerticalShowCard(
      gameName: _filteredShows[index]?.name ?? '',
      imageUrl: _filteredShows[index]?.imageUrl ?? '',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ShowDetailPage(showId: _filteredShows[index]?.id ?? '')),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, int index) {
    return CustomStageCard(
      text: _filteredStages[index]?.name ?? '',
      imageUrl: _filteredStages[index]?.imageUrl ?? '',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                StageDetailPage(stageId: _filteredStages[index]?.id ?? '')),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, int index) {
    return CustomStageCard(
      text:
          '${_filteredPlayers[index]?.firstName} ${_filteredPlayers[index]?.lastName}',
      imageUrl: _filteredPlayers[index]?.imageUrl ?? "",
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PlayerDetailPage(playerId: _filteredPlayers[index]?.id ?? '')),
      ),
    );
  }

  Widget _buildShowAllButton() {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ShowDetailPage(showId: '0')),
      ),
      child: const Text('Tümünü Göster',
          style: TextStyle(fontSize: 16, color: Colors.red)),
    );
  }
}

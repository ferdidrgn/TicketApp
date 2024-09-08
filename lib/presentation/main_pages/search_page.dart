import 'package:flutter/material.dart';
import 'package:ticketapp/presentation//details_pages/stage_details.dart';
import '../../util/custom_views/custom_category_card.dart';
import '../../util/custom_views/custom_show_card.dart';
import '../../util/custom_views/custom_stage_card.dart';
import '../details_pages/player_details.dart';
import '../details_pages/show_details.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
  final List<String> _venues = [
    'Halit Akçatepe Sahnesi',
    'Sahne 2',
    'Sahne 3',
    'Sahne 4',
    'Sahne 5',
    'Sahne 6',
    'Sahne 7',
    'Sahne 8',
    'Sahne 9',
    'Sahne 10',
    'Sahne 11',
    'Sahne 12',
    'Sahne 13',
    'Sahne 14',
    'Sahne 15'
  ];
  final List<String> _players = [
    'Oyuncu 1',
    'Oyuncu 2',
    'Oyuncu 3',
    'Oyuncu 4',
    'Oyuncu 5',
    'Oyuncu 6',
    'Oyuncu 7',
    'Oyuncu 8',
    'Oyuncu 9',
    'Oyuncu 10',
    'Oyuncu 11',
    'Oyuncu 12',
    'Oyuncu 13',
    'Oyuncu 14',
    'Oyuncu 15'
  ];
  final List<String> _events = [
    'Etkinlik 1',
    'Etkinlik 2',
    'Etkinlik 3',
    'Etkinlik 4',
    'Etkinlik 5',
    'Etkinlik 6',
    'Etkinlik 7',
    'Etkinlik 8',
    'Etkinlik 9',
    'Etkinlik 10',
    'Etkinlik 11',
    'Etkinlik 12',
    'Etkinlik 13',
    'Etkinlik 14',
    'Etkinlik 15'
  ];

  List<String> _filteredEvents = [];
  List<String> _filteredVenues = [];
  List<String> _filteredPlayers = [];
  List<Map<String, Object>> _filteredCategories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredEvents = _events;
    _filteredVenues = _venues;
    _filteredPlayers = _players;
    _filteredCategories = _categories;
  }

  void _filterData(String query) {
    setState(() {
      _filteredEvents = _events
          .where((event) => event.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredVenues = _venues
          .where((venue) => venue.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredPlayers = _players
          .where((player) => player.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredCategories = _categories
          .where((category) =>
          (category['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      _filterData(query);
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      _filterData(query);
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

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
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ara...',
                prefixIcon: Icon(Icons.search),
                labelStyle: TextStyle(fontSize: 16),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_filteredEvents.isNotEmpty) _buildEventList(),
                      if (_filteredEvents.isNotEmpty)
                        const SizedBox(height: 16),
                      if (_filteredEvents.isNotEmpty) _buildShowAllButton(),
                      const SizedBox(height: 16),
                      if (_filteredVenues.isNotEmpty) _buildVenueSection(),
                      const SizedBox(height: 16),
                      if (_filteredPlayers.isNotEmpty) _buildPlayers(),
                      const SizedBox(height: 16),
                      if (_filteredCategories.isNotEmpty) _buildCategories(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Eşleşen Etkinlikler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredEvents.length,
            itemBuilder: (context, index) => _buildEventCard(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, int index) {
    return GestureDetector(
      child: CustomVerticalShowCard(
        imageUrl: 'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
        gameName: _filteredEvents[index],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowDetailPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowAllButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context)=>ShowDetailPage(),
            ),
        );
      },
      child: const Text('Tümünü Göster', style: TextStyle(fontSize: 16, color: Colors.red)),
    );
  }

  Widget _buildVenueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gösteri Mekanları',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredVenues.length,
            itemBuilder: (context, index) {
              return CustomStageCard(
                text: _filteredVenues[index],
                imageUrl: 'https://enstitu.ibb.istanbul/files/ismekOrg/Image/img_brans/brans_yenisitegaleri/drama/1-600.jpg',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const StageDetailPage(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gösteri Mekanları',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredPlayers.length,
            itemBuilder: (context, index) {
              return CustomStageCard(
                text: _filteredPlayers[index],
                imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT-cV2ZIk5Wi_uoyY1PdDVM2vFzuSMQATw7iw&s',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerDetailPage()
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
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
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<String> _categories = [
    'Müzikal', 'Tiyatro', 'Sinema', 'Dans', 'Opera', 'Bale'
  ];
  final List<String> _venues = [
    'Sahne 1 dmslks lsşdjsdl sldsdd', 'Sahne 2', 'Sahne 3', 'Sahne 4', 'Sahne 5',
    'Sahne 6', 'Sahne 7', 'Sahne 8', 'Sahne 9', 'Sahne 10',
    'Sahne 11', 'Sahne 12', 'Sahne 13', 'Sahne 14', 'Sahne 15'
  ];
  final List<String> _players = [
    'Oyuncu 1', 'Oyuncu 2', 'Oyuncu 3', 'Oyuncu 4', 'Oyuncu 5',
    'Oyuncu 6', 'Oyuncu 7', 'Oyuncu 8', 'Oyuncu 9', 'Oyuncu 10',
    'Oyuncu 11', 'Oyuncu 12', 'Oyuncu 13', 'Oyuncu 14', 'Oyuncu 15'
  ];
  final List<String> _events = [
    'Etkinlik 1', 'Etkinlik 2', 'Etkinlik 3', 'Etkinlik 4', 'Etkinlik 5',
    'Etkinlik 6', 'Etkinlik 7', 'Etkinlik 8', 'Etkinlik 9', 'Etkinlik 10',
    'Etkinlik 11', 'Etkinlik 12', 'Etkinlik 13', 'Etkinlik 14', 'Etkinlik 15'
  ];

  List<String> _filteredEvents = [];
  List<String> _filteredVenues = [];
  List<String> _filteredPlayers = [];
  List<String> _filteredCategories = [];
  RangeValues _priceRange = const RangeValues(0, 1000);
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
          .where((category) => category.toLowerCase().contains(query.toLowerCase()))
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtreler'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategoriler:'),
                ..._categories
                    .map((category) => CheckboxListTile(
                  title: Text(category),
                  value: false,
                  onChanged: (bool? checked) {
                    // Kategori seçimi işlevi
                  },
                )),
                const SizedBox(height: 20),
                const Text('Fiyat Aralığı:'),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 1000,
                  divisions: 10,
                  labels: RangeLabels(
                    '${_priceRange.start.round()}₺',
                    '${_priceRange.end.round()}₺',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Uygula'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınınızdaki Etkinlikler', style: TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
            else Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_filteredEvents.isNotEmpty) _buildEventList(),
                    if (_filteredEvents.isNotEmpty) const SizedBox(height: 16),
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
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredEvents.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey[300],
                          child: Center(child: Text('Etkinlik Görseli')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_filteredEvents[index], style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShowAllButton() {
    return TextButton(
      onPressed: () {
        // Tüm etkinlikleri gösterme işlevi
      },
      child: const Text('Tümünü Göster', style: TextStyle(fontSize: 16)),
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
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredVenues.length,
            itemBuilder: (context, index) {
              return _buildVenueCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVenueCard(int index) {
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: 'https://via.placeholder.com/120',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Text(
              _filteredVenues[index],
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oyuncular',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredPlayers.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: Center(child: Text(_filteredPlayers[index], style: const TextStyle(fontSize: 14))),
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
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _filteredCategories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_filteredCategories[index], style: const TextStyle(fontSize: 14)),
                leading: Checkbox(
                  value: false,
                  onChanged: (bool? checked) {
                    // Kategori seçimi işlevi
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
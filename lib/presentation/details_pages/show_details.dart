import 'package:flutter/material.dart';

class ShowDetailPage extends StatelessWidget {
  final game = {
    'title': 'Galactic Battleground',
    'description': 'An epic space battle game where players fight for supremacy in the galaxy.',
    'image': 'https://example.com/game_image.jpg',
    'genres': ['Action', 'Strategy', 'Multiplayer'],
    'platforms': [
      {'id': 1, 'name': 'PC', 'active': true},
      {'id': 2, 'name': 'Xbox', 'active': true},
      {'id': 3, 'name': 'PlayStation', 'active': false},
      {'id': 4, 'name': 'Nintendo Switch', 'active': false},
    ]
  };

  ShowDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildGameImage(),
                const SizedBox(height: 16),
                _buildGameTitle(),
                const SizedBox(height: 8),
                _buildGameDescription(),
                const SizedBox(height: 24),
                _buildGenresSection(),
                const SizedBox(height: 24),
                _buildPlatformsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(game['image'].toString(), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGameTitle() {
    return Text(
      game['title'].toString(),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGameDescription() {
    return Text(
      game['description'].toString(),
      style: TextStyle(fontSize: 16, color: Colors.grey[300]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genres',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: (game['genres'] as List).map((genre) => _buildGenreChip(genre)).toList(),
        ),
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    return Chip(
      label: Text(genre, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.purple[600],
    );
  }

  Widget _buildPlatformsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available on',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: (game['platforms'] as List).map((platform) => _buildPlatformCard(platform)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: platform['active']
              ? [Colors.green[500]!, Colors.green[600]!]
              : [Colors.grey[700]!, Colors.grey[800]!],
        ),
      ),
      child: Center(
        child: Text(
          platform['name'],
          style: TextStyle(
            color: platform['active'] ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
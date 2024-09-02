import 'package:flutter/material.dart';

class PlayerDetailPage extends StatelessWidget {
  final player = {
    'name': 'Alex',
    'surname': 'Johnson',
    'bio': 'Professional gamer with a passion for strategy and FPS games. Known for quick reflexes and tactical thinking.',
    'image': 'https://example.com/player_image.jpg',
    'games': [
      {'id': 1, 'name': 'Cosmic Clash', 'active': true},
      {'id': 2, 'name': 'Neon Nights', 'active': true},
      {'id': 3, 'name': 'Pixel Legends', 'active': false},
      {'id': 4, 'name': 'Quantum Quest', 'active': true},
      {'id': 5, 'name': 'Retro Rumble', 'active': false},
    ]
  };

  PlayerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[900]!, Colors.indigo[900]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPlayerImage(),
                const SizedBox(height: 16),
                _buildPlayerName(),
                const SizedBox(height: 8),
                _buildPlayerBio(),
                const SizedBox(height: 24),
                _buildGamesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.pink[500]!, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: ClipOval(
            child: Image.network(player['image'].toString(), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[500],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerName() {
    return Text(
      '${player['name']} ${player['surname']}',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlayerBio() {
    return Text(
      player['bio'].toString(),
      style: TextStyle(fontSize: 16, color: Colors.grey[300]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Games',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: (player['games'] as List).map((game) => _buildGameCard(game)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: game['active']
              ? [Colors.pink[500]!, Colors.purple[600]!]
              : [Colors.grey[700]!, Colors.grey[800]!],
        ),
      ),
      child: Center(
        child: Text(
          game['name'],
          style: TextStyle(
            color: game['active'] ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
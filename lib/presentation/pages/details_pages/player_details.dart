import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';

import '../../../core/custom_views/custom_show_card.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerId;

  PlayerDetailPage({super.key, required this.playerId});
  final player = {
    'name': 'Alex',
    'surname': 'Johnson',
    'bio':
        'Professional gamer with a passion for strategy and FPS games. Known for quick reflexes and tactical thinking.',
    'image': 'https://example.com/player_image.jpg',
    'games': [
      {'id': 1, 'name': 'Cosmic Clash', 'active': true},
      {'id': 2, 'name': 'Neon Nights', 'active': true},
      {'id': 3, 'name': 'Pixel Legends', 'active': false},
      {'id': 4, 'name': 'Quantum Quest', 'active': true},
      {'id': 5, 'name': 'Retro Rumble', 'active': false},
    ]
  };

  final BorderRadius _cardBorderRadius = const BorderRadius.only(
    topLeft: Radius.circular(75),
    bottomRight: Radius.circular(30),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${player['name']} ${player['surname']}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4, // %40
            child: _buildTopSection(context),
          ),
          Expanded(
            flex: 6, // %60
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _buildBottomSection(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlayerImage(context),
        const SizedBox(height: 16),
        _buildPlayerName(),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayerBio(),
            const SizedBox(height: 24),
            _buildGamesHeader(),
            const SizedBox(height: 16),
            _buildGamesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerImage(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: _cardBorderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: _cardBorderRadius,
        child: Image.network(
          player['image'].toString(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlayerName() {
    return Text(
      '${player['name']} ${player['surname']}',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlayerBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        player['bio'].toString(),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGamesHeader() {
    return const Text(
      'Gösterileri',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGamesSection() {
    final games = player['games'] as List<Map<String, dynamic>>;

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return CustomVerticalShowCard(
            imageUrl:
                'https://cdn.assets.lomography.com/6b/0c7b6e26087d03b91910e9f374a02b45591a7f/256x256x1.jpg?auth=2b45b894a7e2a4ed23eb76da171c4d77cfed0a15',
            gameName: game['name'],
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShowDetailPage(showId: '0')
                ),
              );
            },
          );
        },
      ),
    );
  }
}

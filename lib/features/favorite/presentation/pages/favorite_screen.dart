import 'package:flutter/material.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';
import '../../../../shared/widgets/custom_title.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../stages/presentation/pages/stage_details.dart';

class Favorite {
  final String title;
  final String description;
  final String imageUrl;

  Favorite({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

class FavoritesPage extends StatelessWidget {
  FavoritesPage({super.key});

  // Örnek favori oyunlar, oyuncular ve sahneler verileri
  final List<Favorite> favoriteGames = [
    Favorite(
      title: 'Oyun 1',
      description: 'Macera dolu bir oyun.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Favorite(
      title: 'Oyun 2',
      description: 'Eğlenceli bir bulmaca oyunu.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    // Daha fazla oyun ekleyebilirsiniz
  ];

  final List<Favorite> favoritePlayers = [
    Favorite(
      title: 'Oyuncu 1',
      description: 'Başarılı bir oyuncu.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Favorite(
      title: 'Oyuncu 2',
      description: 'Tecrübeli bir sahne sanatçısı.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    // Daha fazla oyuncu ekleyebilirsiniz
  ];

  final List<Favorite> favoriteScenes = [
    Favorite(
      title: 'Sahne 1',
      description: 'Büyüleyici bir konser sahnesi.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Favorite(
      title: 'Sahne 2',
      description: 'Harika bir tiyatro performansı.',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    // Daha fazla sahne ekleyebilirsiniz
  ];

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const CustomSectionTitle(title: 'Favori Oyunlar'),
            _buildShows(),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Favori Sahneler'),
            _buildStageSection(),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Favori Oyuncular'),
            _buildPlayers(),
          ],
        ),
      ),
    );
  }

  Widget _buildShows() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (final context, final index) {
          return _buildEventCard(context, index);
        },
      ),
    );
  }

  Widget _buildEventCard(final BuildContext context, final int index) {
    final List<String> events = [
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
    return GestureDetector(
      child: ShowCard(
        imageUrl:
            'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
        gameName: events[index],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final context) => const ShowDetailPage(showId: '0')),
          );
        },
      ),
    );
  }

  Widget _buildStageSection() {
    final List<String> venues = [
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: venues.length,
            itemBuilder: (final context, final index) {
              return CustomStageCard(
                text: venues[index],
                imageUrl:
                    'https://enstitu.ibb.istanbul/files/ismekOrg/Image/img_brans/brans_yenisitegaleri/drama/1-600.jpg',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final context) =>
                            const StageDetailPage(stageId: '0')),
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
    final List<String> players = [
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

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: players.length,
        itemBuilder: (final context, final index) {
          return CustomStageCard(
            text: players[index],
            imageUrl:
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT-cV2ZIk5Wi_uoyY1PdDVM2vFzuSMQATw7iw&s',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final context) =>
                        const PlayerDetailPage(playerId: "0")),
              );
            },
          );
        },
      ),
    );
  }
}

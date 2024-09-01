import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSection('Favori Oyunlar', favoriteGames),
            const SizedBox(height: 20),
            _buildSection('Favori Oyuncular', favoritePlayers),
            const SizedBox(height: 20),
            _buildSection('Favori Sahneler', favoriteScenes),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Favorite> favorites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200, // Her bir yatay scroll olan bölümün yüksekliği
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(favorites[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        width: 150, // Kart genişliği
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  favorite.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                favorite.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                favorite.description,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
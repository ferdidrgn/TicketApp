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
  // Örnek favori oyunlar ve sahneler verileri
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
            _buildSectionTitle('Favori Oyunlar'),
            ...favoriteGames.map((game) => _buildFavoriteCard(game)),
            const SizedBox(height: 20),
            _buildSectionTitle('Favori Sahneler'),
            ...favoriteScenes.map((scene) => _buildFavoriteCard(scene)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Image.network(
          favorite.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
        title: Text(favorite.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle:
            Text(favorite.description, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Favori öğesine tıklama işlemi
          // Burada detay sayfasına yönlendirme işlemi yapılabilir
        },
      ),
    );
  }
}

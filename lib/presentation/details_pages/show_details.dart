import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../util/custom_views/custom_event_card.dart';
import '../../util/custom_views/custom_gradient_background_image.dart';

class ShowDetailPage extends StatelessWidget {
  final game = {
    'title': 'Galactic Battleground',
    'description':
        'An epic space battle game where players fight for supremacy in the galaxy.',
    'image':
        'https://cdn.assets.lomography.com/6b/0c7b6e26087d03b91910e9f374a02b45591a7f/256x256x1.jpg?auth=2b45b894a7e2a4ed23eb76da171c4d77cfed0a15',
    'genres': ['Action', 'Strategy', 'Multiplayer'],
    'platforms': [
      {'id': 1, 'name': 'PC', 'active': true},
      {'id': 2, 'name': 'Xbox', 'active': true},
      {'id': 3, 'name': 'PlayStation', 'active': false},
      {'id': 4, 'name': 'Nintendo Switch', 'active': false},
    ],
    'events': [
      {
        'date': '19',
        'month': 'EYLÜL',
        'eventName': 'Grand Battle',
        'city': 'Istanbul'
      },
      {
        'date': '25',
        'month': 'Ekim',
        'eventName': 'Galaxy Wars',
        'city': 'Ankara'
      },
      // Daha fazla event ekleyebilirsiniz
    ],
  };

  ShowDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.all(16), child: _buildGameImage()),
              const SizedBox(height: 16),
              _buildGameTitle(),
              const SizedBox(height: 16),
              _buildBottomSheetCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameImage() {
    return AspectRatio(
      aspectRatio: 9 / 13,
      child: Container(
        width: double.infinity,
        // Genişliği kapsayıcının genişliğine göre ayarla
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                game['image'].toString(),
                fit: BoxFit.cover,
                // Görselin bozulmadan kapsayıcıyı kaplamasını sağlar
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                      child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
            Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    game['image'].toString(),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Icon(Icons.error, color: Colors.red));
                    },
                  ),
                ),
                const GradientStrip(
                  isAlignmentCenterLeft: true,
                ),
                const GradientStrip(
                  isAlignmentCenterLeft: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTitle() {
    return Text(
      game['title'].toString(),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomSheetCard(BuildContext context) {
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
            Text(game['description'].toString(),
                style: const TextStyle(
                    fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
            const SizedBox(height: 20),
            _buildSectionTitle('Etkinlik Takvimi'),
            const SizedBox(height: 16),
            Column(
              children: List.generate(
                (game['events'] as List).length,
                (index) {
                  final events = game['events'] as List? ?? [];
                  if (index >= 0 && index < events.length) {
                    final event = events[index] as Map<String, dynamic>?;

                    if (event != null) {
                      return _buildEventCard(
                        event['date'].toString(),
                        event['month'].toString(),
                        event['eventName'].toString(),
                        event['city'].toString(),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                  // Eğer geçersiz bir event varsa boş bir widget döndür
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Oyundan Kareler'),
            _buildGamesPhotoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
      String date, String month, String eventName, String city) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(1, 3)),
        ],
      ),
      child: Row(
        children: [
          // Tarih kısmı
          Container(
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(month,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Oyun bilgisi kısmı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(
                  city,
                  style: const TextStyle(fontSize: 14),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
  }

  Widget _buildGamesPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildGameCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(int index) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      child: Card(
        elevation: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://via.placeholder.com/150',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Oyun $index',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

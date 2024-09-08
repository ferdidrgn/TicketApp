import 'package:flutter/material.dart';

class Stage {
  final String name;
  final String imageUrl;
  final String description;
  final String address;
  final String contactInfo;
  final String mapUrl;

  Stage({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.address,
    required this.contactInfo,
    required this.mapUrl,
  });
}

class StageDetailPage extends StatelessWidget {
  const StageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {

    final Stage stage = Stage(
      name: 'Grand Theater',
      imageUrl: 'https://tiyatrolar.com.tr/files/location/o/ortaoyuncular-tiyatrosu/gallery/19/ortaoyuncular-tiyatrosu-19.jpg',
      description: 'The Grand Theater is one of the most iconic venues, offering a variety of cultural performances and events.',
      address: '123 Theater St, Cityville',
      contactInfo: 'Phone: (123) 456-7890 | Email: info@theater.com',
      mapUrl: 'https://maps.google.com/?q=123+Theater+St+Cityville',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stage.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage image with overlay
            Stack(
              children: [
                // Stage image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Image.network(
                    stage.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay with contact info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.contactInfo,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description and Address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                stage.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Açık Adres: ${stage.address}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Map and Contact Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMapButton(stage.mapUrl),
                  _buildContactButton(stage.contactInfo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(String mapUrl) {
    return Expanded(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8.0),
          leading: const Icon(Icons.map, size: 40, color: Colors.blue),
          title: const Text('Harita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          onTap: () {
            // Open map URL
            // You can use a package like url_launcher to open the URL
          },
        ),
      ),
    );
  }

  Widget _buildContactButton(String contactInfo) {
    return Expanded(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8.0),
          leading: const Icon(Icons.phone, size: 40, color: Colors.green),
          title: const Text('İletişim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(contactInfo, style: const TextStyle(fontSize: 14)),
          onTap: () {
            // Contact info action
            // You can add functionality to call or send an email
          },
        ),
      ),
    );
  }
}

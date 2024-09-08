import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/details_pages/show_details.dart';
import 'package:ticketapp/util/custom_views/custom_show_card.dart';

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
      imageUrl:
          'https://tiyatrolar.com.tr/files/location/o/ortaoyuncular-tiyatrosu/gallery/19/ortaoyuncular-tiyatrosu-19.jpg',
      description:
          'The Grand Theater is one of the most iconic venues, offering a variety of cultural performances and events.',
      address: '123 Theater St, Cityville',
      contactInfo: 'Phone: (123) 456-7890 \nEmail: info@theater.com',
      mapUrl: 'https://maps.google.com/?q=123+Theater+St+Cityville',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stage.name.toString()),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildStageImage(stage),
              ),
              const SizedBox(height: 16),
              _buildStageTitle(stage),
              const SizedBox(height: 16),
              _buildBottomSheet(context, stage)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageImage(Stage stage) {
    return AspectRatio(
      aspectRatio: 3 / 3.5,
      child: Container(
        width: double.infinity,
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
                stage.imageUrl,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, Stage stage) {
    return Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            _buildStageInfo(stage),
            const SizedBox(height: 16),
            _buildShowList(stage),
            const SizedBox(height: 16),
            _buildStageMap(stage),
            const SizedBox(height: 16),
            _buildStageAddress(context, stage)
          ],
        ));
  }

  Widget _buildStageTitle(Stage stage) {
    return Text(
      stage.name,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStageInfo(Stage stage) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stage.description,
                style: const TextStyle(
                    fontSize: 16, height: 1.1, fontWeight: FontWeight.w300))
          ],
        ));
  }

  Widget _buildShowList(Stage stage) {
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
            itemCount: _events.length,
            itemBuilder: (context, index) => _buildEventCard(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, int index) {
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
    return GestureDetector(
      child: CustomVerticalShowCard(
        imageUrl:
            'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
        gameName: _events[index],
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

  Widget _buildStageMap(Stage stage) {
    return Container(
      height: 200,
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
              stage.mapUrl,
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
        ],
      ),
    );
  }

  Widget _buildStageAddress(BuildContext context, Stage stage) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(stage.address,
                  style: const TextStyle(
                      fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(stage.contactInfo,
                  style: const TextStyle(
                      fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';

class NearbyEventsPage extends StatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  State<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends State<NearbyEventsPage> {
  // Statik verilerimiz - Şık bir görüntü için özenle seçilmiş
  final List<Map<String, dynamic>> staticEvents = [
    {
      'name': 'Cimri - Moliere',
      'category': 'Klasik Tiyatro',
      'date': '24 Aralık, 20:30',
      'stage': 'Harbiye Muhsin Ertuğrul',
      'price': 180.0,
      'image':
          'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
      'isTrend': true,
    },
    {
      'name': 'Hamlet - Versus',
      'category': 'Dram',
      'date': '28 Aralık, 20:00',
      'stage': 'Zorlu PSM - Turkcell Sahnesi',
      'price': 250.0,
      'image':
          'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
      'isTrend': false,
    },
    {
      'name': 'Don Kişot’um Ben',
      'category': 'Komedi',
      'date': '30 Aralık, 20:30',
      'stage': 'Baba Sahne',
      'price': 200.0,
      'image':
          'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
      'isTrend': true,
    },
  ];

  @override
  Widget build(final BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDiscoveryBanner(theme),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: 'Sizin İçin Seçtiklerimiz',
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    // Statik listeyi şık kartlar olarak döner
                    ...staticEvents.map((final event) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildStaticArtCard(event, theme),
                        )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(final ThemeData theme) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yakınlarda Neler Var?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    )),
                Text('Konumunuza en yakın sahneler',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    )),
              ],
            ),
            _buildCircularAction(Icons.filter_list, theme),
          ],
        ),
      );

  Widget _buildCircularAction(final IconData icon, final ThemeData theme) =>
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.1),
          shape: BoxShape.circle,
          border:
              Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: IconButton(
          icon: Icon(icon, color: theme.colorScheme.onSurface),
          onPressed: () {}, // Statik olduğu için boş
        ),
      );

  Widget _buildDiscoveryBanner(final ThemeData theme) => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.error.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.theater_comedy,
                  size: 150, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Şehrin Ritmini Yakala',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Bu hafta sonu 12 yeni oyun sahnede.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStaticArtCard(
      final Map<String, dynamic> event, final ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: EventsCard(
        imageUrl: event['image'],
        showName: event['name'],
        category: event['category'],
        date: event['date'],
        stage: event['stage'],
        price: event['price'],
      ),
    );
  }
}

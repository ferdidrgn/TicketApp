import 'package:flutter/material.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';

class NearbyEventsPage extends StatelessWidget {
  const NearbyEventsPage({super.key});

  // Statik verilerimiz - Tasarımın şıklığını korumak için
  final List<Map<String, dynamic>> staticEvents = const [
    {
      'name': 'Cimri - Moliere',
      'category': 'Klasik Tiyatro',
      'date': '24 Aralık, 20:30',
      'stage': 'Harbiye Muhsin Ertuğrul',
      'price': 180.0,
      'image': 'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
    },
    {
      'name': 'Hamlet - Versus',
      'category': 'Dram',
      'date': '28 Aralık, 20:00',
      'stage': 'Zorlu PSM - Turkcell Sahnesi',
      'price': 250.0,
      'image': 'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
    },
    {
      'name': 'Don Kişot’um Ben',
      'category': 'Komedi',
      'date': '30 Aralık, 20:30',
      'stage': 'Baba Sahne',
      'price': 200.0,
      'image': 'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
    },
  ];

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      title: 'YAKINLARDA NELER VAR?',
      subtitle: 'Konumunuza en yakın sahneleri keşfedin...',
      showBackButton: false,
      rightIcon: Icons.filter_list_rounded, // Filtrele butonu artık header'da
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildDiscoveryBanner(context),
              const SizedBox(height: 32),
              const SectionHeader(
                title: 'Sizin İçin Seçtiklerimiz',
                fontWeight: FontWeight.w900,
              ),
              const SizedBox(height: 20),
              // Etkinlik Listesi
              ...staticEvents.map((final event) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildStaticArtCard(context, event),
              )),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryBanner(final BuildContext context) => Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        colors: [
          context.colors.primary.withOpacity(0.9),
          context.colors.secondary.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: context.colors.primary.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -30,
          bottom: -30,
          child: Icon(
            Icons.theater_comedy_rounded,
            size: 180,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Şehrin Ritmini Yakala',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu hafta sonu 12 yeni oyun sahnede.',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStaticArtCard(final BuildContext context, final Map<String, dynamic> event) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
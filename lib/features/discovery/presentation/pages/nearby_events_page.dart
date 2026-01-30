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
      'stage': 'Harbiye Muhsin Ertuğrul Sahnesi',
      'price': 180.0,
      'image':
          'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
    },
    {
      'name': 'Hamlet - Versus Tiyatro',
      'category': 'Shakespeare Dramı',
      'date': '28 Aralık, 20:00',
      'stage': 'Zorlu PSM - Turkcell Sahnesi',
      'price': 250.0,
      'image':
          'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
    },
    {
      'name': 'Don Kişot\'um Ben',
      'category': 'Modern Komedi',
      'date': '30 Aralık, 20:30',
      'stage': 'Baba Sahne - Taksim',
      'price': 200.0,
      'image':
          'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
    },
    {
      'name': 'Romeo & Juliet',
      'category': 'Klasik Aşk',
      'date': '26 Aralık, 19:30',
      'stage': 'İstanbul Şehir Tiyatrosu',
      'price': 150.0,
      'image':
          'https://i.pinimg.com/originals/cd/f6/58/cdf6583da74eb1838429456c96decdb8.jpg',
    },
    {
      'name': 'Kral Lear',
      'category': 'Tragedy',
      'date': '29 Aralık, 21:00',
      'stage': 'Kadıköy Haldun Taner',
      'price': 220.0,
      'image':
          'https://static.ticimax.cloud/cdn-cgi/image/width=1125,quality=85/43055/uploads/urunresimleri/buyuk/king-lear-17-kasim-21-kasim-2022-55a1c.jpg',
    },
  ];

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final double cardWidth = isLargeScreen ? 400 : context.screenWidth - 48;

    return BasePageWrapper(
      title: 'YAKININIZDAKİ ETKİNLİKLER',
      subtitle: 'Size en yakın sahnelerde bu hafta neler var?',
      showBackButton: false,
      rightIcon: Icons.tune_rounded,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
          backgroundColor: Colors.white, safeAreaTop: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO BANNER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildDiscoveryBanner(context),
            ),
          ),

          // HIZLI FİLTRELER
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('Tümü', true, context),
                  _buildFilterChip('Tiyatro', false, context),
                  _buildFilterChip('Konser', false, context),
                  _buildFilterChip('Sahne', false, context),
                  _buildFilterChip('Bugün', false, context),
                  _buildFilterChip('Yakında', false, context),
                ],
              ),
            ),
          ),

          // BAŞLIK
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SectionHeader(
                title: 'Sizin İçin Önerilenler',
                subtitle: 'Konumunuza göre en uygun etkinlikler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ETKİNLİK LİSTESİ - YATAY KAYDIRMA
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320, // Sabit yükseklik - butonlar için yeterli alan
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: staticEvents.length,
                itemBuilder: (final context, final index) {
                  return Container(
                    width: cardWidth * 0.85, // Daha dar kartlar
                    margin: EdgeInsets.only(
                      right: index < staticEvents.length - 1 ? 16 : 0,
                    ),
                    child: EventsCard(
                      width: cardWidth * 0.85,
                      imageUrl: staticEvents[index]['image'],
                      showName: staticEvents[index]['name'],
                      category: staticEvents[index]['category'],
                      fullDateString: staticEvents[index]['date'],
                      timeString: '',
                      stage: staticEvents[index]['stage'],
                      price: staticEvents[index]['price'],
                      onTap: () {
                        // Kart tıklama işlevi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${staticEvents[index]['name']} - Bilet sayfasına yönlendiriliyorsunuz'),
                            backgroundColor: context.primaryColor,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // POPÜLER MEKANLAR BAŞLIĞI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SectionHeader(
                title: 'Popüler Sahne ve Mekanlar',
                subtitle: 'En çok tercih edilen yerler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // MEKAN LİSTESİ
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLargeScreen ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (final context, final index) => _buildVenueCard(context, index),
                childCount: 6,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBanner(final BuildContext context) => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              context.primaryColor,
              context.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // DEKORATİF ELEMENTLER
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                Icons.star_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Icon(
                Icons.location_on_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Şehrin Ritmini Keşfet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '15+ tiyatro oyunu ve 20+ konser sizi bekliyor.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
      final String text, final bool isActive, final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
        selected: isActive,
        onSelected: (final selected) {},
        backgroundColor: Colors.grey.shade100,
        selectedColor: context.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildVenueCard(final BuildContext context, final int index) {
    final venues = [
      {'name': 'Zorlu PSM', 'type': 'Sahne', 'icon': Icons.theater_comedy},
      {'name': 'İKSV Salon', 'type': 'Konser', 'icon': Icons.music_note},
      {'name': 'BKM', 'type': 'Tiyatro', 'icon': Icons.home_max},
      {'name': 'Kadıköy Sahne', 'type': 'Sahne', 'icon': Icons.location_city},
      {'name': 'Bostancı Gösteri', 'type': 'Konser', 'icon': Icons.mic},
      {'name': 'Akasya Kültür', 'type': 'Tiyatro', 'icon': Icons.palette},
    ];

    final venue = venues[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              venue['icon'] as IconData,
              color: context.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            venue['name'] as String,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            venue['type'] as String,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

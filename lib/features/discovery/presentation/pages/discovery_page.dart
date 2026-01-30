import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  final List<Map<String, dynamic>> trendingShows = [
    {
      'name': 'Gözlerimi Kaparım Vazifemi Yaparım',
      'category': 'Tiyatro',
      'image':
          'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
      'tag': 'YENİ',
    },
    {
      'name': 'Kadınlık Bizde Kalsın',
      'category': 'Müzikal',
      'image':
          'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
      'tag': 'TREND',
    },
  ];

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      title: widget.selectedCategory ?? 'İlhamını Bul',
      subtitle: widget.selectedCategory != null
          ? '${widget.selectedCategory} kategorisindeki etkinlikler'
          : 'Küratörlerin hazırladığı özel seçkiler',
      showBackButton: false,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 1200 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. ÖNE ÇIKAN BAŞYAPITLAR
              const SectionHeader(
                  title: 'Haftanın Başyapıtları', subtitle: 'Seçkiler'),
              const SizedBox(height: 16),
              _buildTrendingSlider(),

              const SizedBox(height: 40),

              // 2. KEŞİF LİSTESİ BAŞLIĞI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeader(title: 'Tümünü Keşfet'),
                  _buildFilterButton(),
                ],
              ),
              const SizedBox(height: 16),

              // 3. EVENT LIST (Responsive Grid veya List)
              _buildResponsiveEventList(isLargeScreen),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSlider() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: trendingShows.length,
        itemBuilder: (final context, final index) {
          final show = trendingShows[index];
          return Container(
            width: 320,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: context.colors.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
              image: DecorationImage(
                image: NetworkImage(show['image']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3), BlendMode.darken),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildTag(show['tag']),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: _buildShowInfo(show),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveEventList(final bool isLargeScreen) {
    // Web'de 2'li grid, mobilde alt alta liste
    if (isLargeScreen) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2.5,
        children: _getStaticEvents(),
      );
    }
    return Column(children: _getStaticEvents(spacing: 16));
  }

  List<Widget> _getStaticEvents({final double spacing = 0}) {
    final events = [
      const EventsCard(
        imageUrl:
            'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
        showName: 'Hamlet - Bir Kimlik Meselesi',
        category: 'Dram',
        stage: 'Zorlu PSM',
        price: 240, fullDateString: '15 Haz 2026', timeString: '19:30',
      ),
      const EventsCard(
        imageUrl:
            'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
        showName: 'Cimri - Şehir Tiyatroları',
        category: 'Komedi',
        stage: 'Kadıköy Sahnesi',
        price: 150, fullDateString: '20 Haz 2020', timeString: '20.30',
      ),
    ];

    if (spacing > 0) {
      return events
          .expand((final e) => [e, SizedBox(height: spacing)])
          .toList();
    }
    return events;
  }

  // --- KÜÇÜK UI BİLEŞENLERİ ---

  Widget _buildTag(final String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(tag,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      );

  Widget _buildShowInfo(final Map<String, dynamic> show) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show['category'].toUpperCase(),
              style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(show['name'],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.1)),
        ],
      );

  Widget _buildFilterButton() => Container(
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon:
              Icon(Icons.tune_rounded, size: 18, color: context.colors.primary),
          label: Text('Filtrele',
              style: TextStyle(
                  color: context.colors.primary, fontWeight: FontWeight.bold)),
        ),
      );
}

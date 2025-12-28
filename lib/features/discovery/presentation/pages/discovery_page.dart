import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  // Statik veriler - Henüz Firebase'de veri olmadığı için burası şık durmalı
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
    final theme = context.theme;

    return Scaffold(
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiscoveryHeader(theme),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ÖNE ÇIKAN BAŞYAPITLAR (Yatay Kaydırma)
                      const SectionHeader(
                          title: 'Haftanın Başyapıtları', subtitle: 'Seçkiler'),
                      const SizedBox(height: 12),
                      _buildTrendingSlider(theme),

                      const SizedBox(height: 32),

                      // 2. KEŞİF LİSTESİ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(title: 'Tümünü Keşfet'),
                          TextButton(
                            onPressed: () {},
                            child: Text('Filtrele',
                                style: TextStyle(
                                    color: theme.colorScheme.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStaticEventList(),
                      const SizedBox(height: 100), // Bottom nav için boşluk
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryHeader(ThemeData theme) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İlhamını Bul',
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text('Küratörlerin hazırladığı özel seçkiler',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildTrendingSlider(ThemeData theme) => SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: trendingShows.length,
          itemBuilder: (context, index) {
            final show = trendingShows[index];
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(show['tag'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(show['category'].toUpperCase(),
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                        Text(show['name'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildStaticEventList() => Column(
        children: const [
          EventsCard(
            imageUrl:
                'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
            showName: 'Hamlet - Bir Kimlik Meselesi',
            category: 'Dram',
            date: '15 Haziran 2024',
            stage: 'Zorlu PSM',
            price: 240,
          ),
          SizedBox(height: 16),
          EventsCard(
            imageUrl:
                'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
            showName: 'Cimri - Şehir Tiyatroları',
            category: 'Komedi',
            date: '18 Haziran 2024',
            stage: 'Kadıköy Sahnesi',
            price: 150,
          ),
        ],
      );
}

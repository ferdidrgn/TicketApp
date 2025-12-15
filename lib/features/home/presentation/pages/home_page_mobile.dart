import 'dart:async';
import 'dart:ui';
import 'dart:math' as math; // Rastgele şekiller için
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import '../../../../core/common/base_loadable_state.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/custom_floating_action_button.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/pages/campaign_showcase_page.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _loadAllData();
    });
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    ref.read(campaignProvider.notifier).loadCampaigns();
    ref.read(showProvider.notifier).loadShows(true);
    ref.read(stageProvider.notifier).loadStages(true);
  }

  void _navigateToPage(final Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (final _) => page));

  Widget _resolveDetailPage(final String url) {
    try {
      final id = url.split('/').last;
      if (url.contains('/shows')) return PlayerDetailPage(playerId: id);
      if (url.contains('/show')) return ShowDetailPage(showId: id);
      if (url.contains('/stages')) return StageDetailPage(stageId: id);
      return const SizedBox();
    } catch (e) {
      return const SizedBox();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    final isDark = context.isDarkMode;
    // Hafif kırık beyaz veya çok koyu gri (Pastel renklerin patlaması için)
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      floatingActionButton: CustomFloatingActionButton(onPressed: _loadAllData),
      body: Stack(
        children: [
          // Ambiyans Işığı (Sağ Üst)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryColor.withOpacity(0.15),
              ),
            ),
          ),

          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 110, bottom: 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. STORY (VİTRİN)
              _buildSectionHeader("Öne Çıkanlar", "Vitrin",
                  onTap: () => _navigateToPage(const CampaignShowcasePage())),
              _buildStoryCircles(campaignState),
              const SizedBox(height: 30),

              // 2. PASTEL KATEGORİLER (YENİ TASARIM)
              _buildSectionHeader("Kategoriler", "Sanatın Renkleri"),
              _buildPastelCategories(), // <-- Yeni Metot
              const SizedBox(height: 30),

              // 3. KEŞFET (KAOTİK KOLAJ - YENİ TASARIM)
              _buildSectionHeader("Keşfet", "Sana Özel Seçkiler"),
              _buildChaoticCollage(showState), // <-- Yeni Metot

              const SizedBox(height: 30),

              // 4. MEKANLAR
              _buildSectionHeader("Mekanlar", "Şehrin Sahneleri"),
              _buildGlassStageList(stageState),
              const SizedBox(height: 30),

              // 5. FIRSAT
              _buildTicketStubRecommendation(),
            ],
          ),
        ],
      ),
    );
  }

  // --- 0. GLASS APP BAR ---
  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: context.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: context.scaffoldBackgroundColor
                .withOpacity(_scrollOffset > 50 ? 0.85 : 0.0),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TicketApp",
                    style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                GestureDetector(
                  onTap: () => _navigateToPage(const SearchPage()),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.primaryColor.withOpacity(0.1))),
                    child: Icon(Icons.search, color: context.primaryColor),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. STORY CIRCLES ---
  Widget _buildStoryCircles(
      final LoadableState<dynamic, List<Campaign>> state) {
    if (!state.hasData) return const SizedBox();
    final list = state.dataList!;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 18),
        itemBuilder: (final context, final index) {
          final item = list[index];
          return GestureDetector(
            onTap: () =>
                _navigateToPage(CampaignShowcasePage(initialIndex: index)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        Color(0xFF833AB4),
                        Color(0xFFF56040),
                        Color(0xFFFCAF45)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: context.scaffoldBackgroundColor,
                        shape: BoxShape.circle),
                    child: CircleAvatar(
                        radius: 34,
                        backgroundImage:
                            CachedNetworkImageProvider(item.imageUrl)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                    width: 75,
                    child: Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)))
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 2. PASTEL KATEGORİLER (BOYA SÜRÜLMÜŞ GİBİ) 🔥
  Widget _buildPastelCategories() {
    final categories = [
      {
        'icon': Icons.theater_comedy,
        'text': 'Tiyatro',
        'color': const Color(0xFFFFB7B2)
      },
      // Pastel Kırmızı
      {
        'icon': Icons.music_note,
        'text': 'Konser',
        'color': const Color(0xFFE2F0CB)
      },
      // Pastel Yeşil
      {
        'icon': Icons.mic_external_on,
        'text': 'Stand-up',
        'color': const Color(0xFFFFDAC1)
      },
      // Pastel Turuncu
      {'icon': Icons.museum, 'text': 'Müze', 'color': const Color(0xFFC7CEEA)},
      // Pastel Mor
    ];

    return SizedBox(
      height: 100, // Yükseklik
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 15),
        itemBuilder: (final context, final index) {
          final cat = categories[index];
          final color = cat['color'] as Color;

          return Column(
            children: [
              // Organik / Amorf Şekilli Container
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.6),
                    // Biraz şeffaflık
                    // Köşeleri rastgele yuvarlatarak "fırça darbesi" hissi veriyoruz
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(30),
                      bottomLeft: const Radius.circular(30),
                      bottomRight: const Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(2, 4), // Hafif taşma
                      )
                    ]),
                child: Icon(cat['icon'] as IconData,
                    color: Colors.black87, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                cat['text'] as String,
                style: context.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔥🔥🔥 3. TAM KAOTİK SANAT DUVARI (KEŞFET) 🔥🔥🔥
  Widget _buildChaoticCollage(final LoadableState<dynamic, List<Show>> state) {
    if (state.isLoading)
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(height: 400, width: double.infinity));
    if (!state.hasData || state.dataList!.isEmpty) return const SizedBox();

    final shows = state.dataList!.take(10).toList();
    final count = shows.length;

    List<Widget> layoutBlocks = [];

    // --- BLOK 1: GİRİŞ (Devasa Sol Poster + 2 Sağ) ---
    if (count > 0) {
      layoutBlocks.add(SizedBox(
        height: 340, // Yüksek blok
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol: Devasa Ana Kart
            Expanded(
                flex: 6,
                child: _buildArtCard(show: shows[0], tagText: "VİZYONDA")),
            const SizedBox(width: 10),
            // Sağ: Üst üste iki küçük
            if (count > 1)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                        flex: 2,
                        child: _buildArtCard(
                            show: shows[1], isTrend: true, tagText: "TREND")),
                    const SizedBox(height: 10),
                    if (count > 2)
                      Expanded(flex: 3, child: _buildArtCard(show: shows[2])),
                  ],
                ),
              ),
          ],
        ),
      ));
    }

    // --- BLOK 2: ŞERİT (Araya giren yatay parça) ---
    if (count > 3) {
      layoutBlocks.add(const SizedBox(height: 10));
      layoutBlocks.add(SizedBox(
        height: 130,
        child: _buildArtCard(show: shows[3], isWide: true, tagText: "FIRSAT"),
      ));
    }

    // --- BLOK 3: ÜÇLÜ ASİMETRİ (1 İnce, 1 Geniş Trend, 1 İnce) ---
    if (count > 4) {
      layoutBlocks.add(const SizedBox(height: 10));
      layoutBlocks.add(SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildArtCard(show: shows[4])),
            const SizedBox(width: 10),
            if (count > 5) ...[
              Expanded(
                  flex: 5,
                  child: _buildArtCard(
                      show: shows[5], isTrend: true, tagText: "ÇOK SATAN")),
              const SizedBox(width: 10),
            ],
            if (count > 6)
              Expanded(flex: 3, child: _buildArtCard(show: shows[6])),
          ],
        ),
      ));
    }

    // --- BLOK 4: TERS KÖŞE (Sol 2 Minik, Sağ Büyük) ---
    if (count > 7) {
      layoutBlocks.add(const SizedBox(height: 10));
      layoutBlocks.add(SizedBox(
        height: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(child: _buildArtCard(show: shows[7])),
                  const SizedBox(height: 10),
                  if (count > 8) Expanded(child: _buildArtCard(show: shows[8])),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (count > 9)
              Expanded(
                  flex: 5,
                  child: _buildArtCard(
                      show: shows[9], tagText: "EDİTÖRÜN SEÇİMİ")),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: layoutBlocks),
    );
  }

  // 🔥 GÖRSEL KART TASARIMI (FİLTRELİ) 🔥
  Widget _buildArtCard({
    required final Show show,
    final bool isTrend = false,
    final bool isWide = false,
    final String? tagText,
  }) {
    return GestureDetector(
      onTap: () => _navigateToPage(ShowDetailPage(showId: show.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(show.imageUrl),
            fit: BoxFit.cover,
            // 🎨 Trend ise Pembe Filtre, Değilse Hafif Karanlık
            colorFilter: isTrend
                ? ColorFilter.mode(context.primaryColor.withOpacity(0.5),
                    BlendMode.srcOver) // Pembe Filtre
                : ColorFilter.mode(
                    Colors.black.withOpacity(0.2), BlendMode.darken),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Trend ise arkada süs ikonu
            if (isTrend)
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.star_rate_rounded,
                    size: 90, color: Colors.white.withOpacity(0.15)),
              ),

            // Alt Gölge (Okunurluk için)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  begin: isWide ? Alignment.centerRight : Alignment.topCenter,
                  end: isWide ? Alignment.centerLeft : Alignment.bottomCenter,
                ),
              ),
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  // Etiket
                  if (tagText != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // Trend ise beyaz zemin, değilse pembe zemin
                          color: isTrend
                              ? Colors.white.withOpacity(0.9)
                              : context.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(
                            color:
                                isTrend ? context.primaryColor : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),

                  // Başlık
                  Text(
                    show.name,
                    maxLines: isWide ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: isWide ? 20 : 15,
                      shadows: [
                        Shadow(
                            color: Colors.black.withOpacity(0.8), blurRadius: 4)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. GLASS STAGE LIST ---
  Widget _buildGlassStageList(final LoadableState<dynamic, List<Stage>> state) {
    if (state.isLoading)
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(height: 160, width: double.infinity));
    if (!state.hasData) return const SizedBox();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: state.dataList!.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 15),
        itemBuilder: (final context, final index) {
          final stage = state.dataList![index];
          return GestureDetector(
            onTap: () => _navigateToPage(StageDetailPage(stageId: stage.id)),
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(stage.imageUrl,
                          maxHeight: 300),
                      fit: BoxFit.cover)),
              child: Stack(children: [
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20))),
                        child: Row(children: [
                          const Icon(Icons.location_on,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(stage.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1))
                        ])))
              ]),
            ),
          );
        },
      ),
    );
  }

  // --- 5. TICKET STUB ---
  Widget _buildTicketStubRecommendation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Row(
              children: [
                Container(
                    width: 100,
                    decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(16)),
                        image: DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1503095392269-2d609236f269?q=80&w=1000&auto=format&fit=crop'),
                            fit: BoxFit.cover))),
                SizedBox(
                    width: 20,
                    child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                            10,
                            (final _) => Container(
                                width: 2,
                                height: 6,
                                color: Colors.grey[600])))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("GÜNÜN FIRSATI",
                                  style: TextStyle(
                                      color: context.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1)),
                              const SizedBox(height: 4),
                              const Text("Romeo & Juliet",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text("%20 İndirim Fırsatı",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12))
                            ]))),
              ],
            ),
          ),
          Positioned(top: -10, left: 108, child: _hole()),
          Positioned(bottom: -10, left: 108, child: _hole()),
        ],
      ),
    );
  }

  Widget _hole() => Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor, shape: BoxShape.circle));

  Widget _buildSectionHeader(String title, String subtitle,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf: Başlıklar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey)),
            ],
          ),

          // Sağ taraf: Ok İşareti (Tıklanabilir)
          GestureDetector(
            onTap: onTap, // <-- Tıklama özelliği buraya bağlandı
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                // Tıklanabilir olduğu belli olsun diye hafif renk verelim
                color: onTap != null
                    ? context.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: onTap != null ? context.primaryColor : Colors.grey,
              ),
            ),
          )
        ],
      ),
    );
  }
}

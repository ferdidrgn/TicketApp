import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import '../../../../core/common/base_loadable_state.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/custom_floating_action_button.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../campaigns/domain/entities/campaign_showcase_page.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  // (Helper metodlar aynı kalıyor, kısalttım)
  Widget _resolveDetailPage(String url) {
    try {
      final id = url.split('/').last;
      if (url.contains('/shows')) return PlayerDetailPage(playerId: id);
      if (url.contains('/show')) return ShowDetailPage(showId: id);
      if (url.contains('/stages')) return StageDetailPage(stageId: id);
      return const SizedBox();
    } catch (e) { return const SizedBox(); }
  }

  @override
  Widget build(BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    // Modern Dark/Light Palette
    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      floatingActionButton: CustomFloatingActionButton(onPressed: _loadAllData),
      body: Stack(
        children: [
          // Arka Planda "Glow" Efekti (Ambiyans ışığı)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryColor.withOpacity(0.2),
              ),
            ),
          ),

          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 100, bottom: 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. STORY SECTION (Hızlı Bakış)
              _buildSectionHeader("Öne Çıkanlar", "Vitrin"),
              _buildStoryCircles(campaignState),

              const SizedBox(height: 30),

              // 2. MOOD PICKER (Yeni Bölüm!)
              _buildMoodSection(),

              const SizedBox(height: 30),

              // 3. BENTO GRID (Asimetrik Yerleşim - Modern Tasarımın Kalbi)
              _buildSectionHeader("Keşfet", "Sana Özel Seçkiler"),
              _buildBentoGrid(showState),

              const SizedBox(height: 30),

              // 4. GLASS CARDS (Stages)
              _buildSectionHeader("Mekanlar", "Şehrin Sahneleri"),
              _buildGlassStageList(stageState),

              const SizedBox(height: 30),

              // 5. TICKET STUB (Bilet Görünümlü Kart - Rastgele Öneri)
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
      systemOverlayStyle: context.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: context.scaffoldBackgroundColor.withOpacity(_scrollOffset > 50 ? 0.8 : 0.0),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo veya Başlık
                Text(
                  "TicketApp",
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                // Arama Butonu (Glassy)
                GestureDetector(
                  onTap: () => _navigateToPage(const SearchPage()),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
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
  Widget _buildStoryCircles(LoadableState<dynamic, List<Campaign>> state) {
    if (!state.hasData) return const SizedBox();
    final list = state.dataList!;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final item = list[index];
          return GestureDetector(
            onTap: () => _navigateToPage(_resolveDetailPage(item.url)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.orange], // Instagram style gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: CachedNetworkImageProvider(item.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 2. MOOD SECTION (YENİ) ---
  Widget _buildMoodSection() {
    final moods = [
      {'emoji': '😂', 'text': 'Gülmek', 'color': Colors.amber},
      {'emoji': '😢', 'text': 'Dram', 'color': Colors.blueGrey},
      {'emoji': '🎸', 'text': 'Coşmak', 'color': Colors.purple},
      {'emoji': '🤯', 'text': 'Ufuk Açıcı', 'color': Colors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("Bugün Modun Ne?", style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = moods[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (mood['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: (mood['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(mood['emoji'] as String, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(mood['text'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: mood['color'] as Color)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. BENTO GRID (HIGHLIGHT) ---
  Widget _buildBentoGrid(LoadableState<dynamic, List<Show>> state) {
    if (state.isLoading || !state.hasData || state.dataList!.isEmpty) return const SizedBox();

    final shows = state.dataList!;
    // En az 3 veri olduğunu varsayalım, yoksa placeholder koy
    final mainShow = shows.isNotEmpty ? shows[0] : null;
    final secShow = shows.length > 1 ? shows[1] : shows[0];
    final thirdShow = shows.length > 2 ? shows[2] : shows[0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 320, // Grid yüksekliği
        child: Row(
          children: [
            // SOL: Büyük Kart (Dikey)
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: () => _navigateToPage(ShowDetailPage(showId: mainShow!.id)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(mainShow!.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildGradientOverlay(),
                      Positioned(
                        bottom: 15, left: 15, right: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTag("EDİTÖRÜN SEÇİMİ"),
                            const SizedBox(height: 8),
                            Text(mainShow.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // SAĞ: İki Küçük Kart (Dikey Stack)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  // Sağ Üst
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(ShowDetailPage(showId: secShow!.id)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.grey[800], // Resim yüklenene kadar
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(secShow!.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(secShow.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), maxLines: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Sağ Alt (Farklı tasarım - renkli)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToPage(ShowDetailPage(showId: thirdShow!.id)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: context.primaryColor, // Düz renk üzerine yazı
                        ),
                        child: Stack(
                          children: [
                            Positioned(right: -20, bottom: -20, child: Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.white.withOpacity(0.2))),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("TREND", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(thirdShow!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
  Widget _buildGlassStageList(LoadableState<dynamic, List<Stage>> state) {
    if (state.isLoading) return const ShimmerLoading(height: 100, width: double.infinity);
    if (!state.hasData) return const SizedBox();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: state.dataList!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final stage = state.dataList![index];
          return GestureDetector(
            onTap: () => _navigateToPage(StageDetailPage(stageId: stage.id)),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: CachedNetworkImageProvider(stage.imageUrl), fit: BoxFit.cover),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  // Sadece alt kısımda blur olsun diye trick yapılabilir ama burada full glass yapıp resmi arkaya attık
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Stack(
                    children: [
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                      Positioned(
                        bottom: 15, left: 15,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stage.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Text("İstanbul", style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 5. TICKET STUB (Sürpriz Bölüm) ---
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                // Sol taraf (Image)
                Container(
                  width: 100,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1503095392269-2d609236f269?q=80&w=1000&auto=format&fit=crop'), // Placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Kesik Çizgi (Ticket Perforation)
                SizedBox(
                  width: 20,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(10, (_) => Container(width: 2, height: 6, color: Colors.grey[600])),
                  ),
                ),
                // Sağ Taraf (Info)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("GÜNÜN FIRSATI", style: TextStyle(color: context.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        const Text("Romeo & Juliet", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("%20 İndirim Fırsatı", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Süs delikleri
          Positioned(top: -10, left: 108, child: _hole()),
          Positioned(bottom: -10, left: 108, child: _hole()),
        ],
      ),
    );
  }

  Widget _hole() => Container(width: 20, height: 20, decoration: BoxDecoration(color: context.scaffoldBackgroundColor, shape: BoxShape.circle));


  // --- HELPERS ---

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: context.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          // More button (Arrow)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.3))),
            child: const Icon(Icons.arrow_forward, size: 16),
          )
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }
}
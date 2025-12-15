import 'dart:async';
import 'dart:ui';
import 'dart:math' as math; // Rastgelelik için
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// SENİN PROJENE AİT IMPORTLAR
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

    // Scroll dinleyicisi AppBar opaklığı için.
    // Tasarımda sabit seed kullandığımız için artık titreme yapmaz.
    _scrollController.addListener(() {
      if (mounted) {
        setState(() => _scrollOffset = _scrollController.offset);
      }
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

  @override
  Widget build(final BuildContext context) {
    // GERÇEK VERİLER BURADA ÇEKİLİYOR
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    final isDark = context.isDarkMode;
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

          // PARÇACIK EFEKTİ (SABİT SEED İLE)
          _buildFloatingParticles(),

          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 110, bottom: 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // 0. ÇARPIK BAŞLIK
              _buildDistortedTextBanner(),
              _buildRandomShapes(),

              // 1. STORY (VİTRİN) - GERÇEK VERİ
              _buildSectionHeader("Öne Çıkanlar", "Vitrin",
                  onTap: () => _navigateToPage(const CampaignShowcasePage())),
              _buildStoryCircles(campaignState),
              _buildChaoticDivider(),
              const SizedBox(height: 30),

              // 2. PASTEL KATEGORİLER
              _buildSectionHeader("Kategoriler", "Sanatın Renkleri"),
              _buildPastelCategories(),
              _buildChaoticDivider(),
              const SizedBox(height: 30),

              // 3. KEŞFET (KAOTİK KOLAJ) - GERÇEK VERİ
              _buildSectionHeader("Keşfet", "Sana Özel Seçkiler"),
              _buildChaoticCollage(showState), // <-- SHOW VERİSİ BURAYA GİDİYOR
              _buildChaoticDivider(),
              const SizedBox(height: 30),

              // 4. MEKANLAR - GERÇEK VERİ
              _buildSectionHeader("Mekanlar", "Şehrin Sahneleri"),
              _buildGlassStageList(stageState),
              _buildChaoticDivider(),
              const SizedBox(height: 30),

              // 5. FIRSAT
              _buildTicketStubRecommendation(),

              // 6. GİZLİ MESAJ
              _buildHiddenMessage(),
            ],
          ),
        ],
      ),
    );
  }

  // --- 0. GLASS APP BAR (NAVİGASYON DAHİL) ---
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
                Flexible(
                  child: Text(
                    "TicketApp",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
                GestureDetector(
                  onTap: () => _navigateToPage(const SearchPage()),
                  // <-- GERÇEK NAVİGASYON
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

  // --- 1. STORY CIRCLES (GERÇEK VERİ) ---
  Widget _buildStoryCircles(
      final LoadableState<dynamic, List<Campaign>> state) {
    // Veri yükleniyor veya yoksa gösterme
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

  // 🔥🔥🔥 3. TAM KAOTİK SANAT DUVARI (DÜZELTİLMİŞ) 🔥🔥🔥
  Widget _buildChaoticCollage(final LoadableState<dynamic, List<Show>> state) {
    // Yükleniyor durumu için Shimmer
    if (state.isLoading)
      return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(height: 400, width: double.infinity));

    // Veri yoksa boş dön
    if (!state.hasData || state.dataList!.isEmpty) return const SizedBox();

    // GERÇEK VERİYİ ALIYORUZ
    final shows = state.dataList!.take(12).toList();

    // 🔥 SABİT SEED: EKRAN TİTREMESİNİ ÖNLER
    final random = math.Random(42);
    final List<double> heights = [280, 320, 240, 300, 260, 340];

    List<Widget> layoutBlocks = [];

    // --- BLOK 1: ÇAPRAZ DÜZEN ---
    layoutBlocks.add(
      SizedBox(
        height: heights[random.nextInt(heights.length)],
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (shows.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                width: MediaQuery.of(context).size.width * 0.6,
                bottom: MediaQuery.of(context).size.height * 0.1,
                child: Transform.rotate(
                  angle: -0.02,
                  child: _buildArtCard(
                      show: shows[0], tagText: "ANA", isWide: false),
                ),
              ),
            if (shows.length > 1)
              Positioned(
                top: 100,
                // Sabit ofset
                right: 0,
                width: MediaQuery.of(context).size.width * 0.5,
                height: 180,
                child: Transform.rotate(
                  angle: 0.03,
                  child: _buildArtCard(
                    show: shows[1],
                    isTrend: true,
                    tagText: "TREND",
                    isWide: false,
                    // ✅ İŞTE BURADA AKTİF ETTİM:
                    hasSplatterEffect: true,
                  ),
                ),
              ),
            if (shows.length > 2)
              Positioned(
                bottom: 0,
                left: 0,
                width: MediaQuery.of(context).size.width * 0.35,
                height: 120,
                child: Transform.rotate(
                  angle: -0.05,
                  child: _buildArtCard(show: shows[2], tagText: "YENİ"),
                ),
              ),
          ],
        ),
      ),
    );

    layoutBlocks.add(const SizedBox(height: 15));
    layoutBlocks.add(_buildChaoticDivider());

    // --- BLOK 2: DÜŞEY ŞERİT ---
    if (shows.length > 3) {
      layoutBlocks.add(
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (int i = 3; i < math.min(7, shows.length); i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: 12,
                    top: random.nextDouble() * 20, // Sabit seed ile dans etmez
                  ),
                  child: Transform.rotate(
                    angle: random.nextDouble() * 0.1 - 0.05,
                    child: SizedBox(
                      width: 100,
                      child: _buildArtCard(
                        show: shows[i],
                        tagText: i == 3 ? "ÖZEL" : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      layoutBlocks.add(const SizedBox(height: 20));
    }

    // --- BLOK 3: MOZAİK DÜZEN ---
    if (shows.length > 7) {
      layoutBlocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 220,
                      child: Transform.rotate(
                        angle: 0.02,
                        child: _buildArtCard(
                          show: shows[7],
                          tagText: "POPÜLER",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        if (shows.length > 8)
                          SizedBox(
                            height: 105,
                            child: Transform.rotate(
                              angle: -0.03,
                              child: _buildArtCard(
                                show: shows[8],
                                tagText: "SÜRPRİZ",
                                // ✅ BURADA DA AKTİF ETTİM:
                                hasSplatterEffect: true,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (shows.length > 9)
                          SizedBox(
                            height: 105,
                            child: _buildArtCard(
                              show: shows[9],
                              tagText: "VİP",
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (shows.length > 10)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 120,
                        child: Transform.rotate(
                          angle: -0.01,
                          child: _buildArtCard(
                            show: shows[10],
                            tagText: "SON ŞANS",
                            isWide: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // --- BLOK 4: KIRIK DÜZEN ---
    if (shows.length > 11) {
      layoutBlocks.add(const SizedBox(height: 25));
      layoutBlocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.primaryColor.withOpacity(0.05),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: Transform.translate(
                        offset: const Offset(-10, 0),
                        child: _buildArtCard(
                          show: shows[11],
                          tagText: "GİZLİ",
                          // ✅ BURADA YIRTIK KENAR EFEKTİNİ AKTİF ETTİM:
                          hasTornEdge: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: Transform.translate(
                        offset: const Offset(0, 20),
                        child: _buildArtCard(
                          show: shows[0],
                          // Final olarak ilk show'u tekrar gösteriyoruz (döngü)
                          tagText: "FİNAL",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: layoutBlocks,
    );
  }

  // 🔥 GELİŞMİŞ GÖRSEL KART TASARIMI (NAVİGASYON DAHİL) 🔥
  Widget _buildArtCard({
    required final Show show,
    final bool isTrend = false,
    final bool isWide = false,
    final String? tagText,
    final double borderRadius = 20,
    final bool hasTornEdge = false,
    final bool hasOverlayPattern = false,
    final bool hasGlitchEffect = false,
    final bool hasGradientBorder = false,
    final bool hasSplatterEffect = false,
  }) {
    return GestureDetector(
      // 🔥 BURADA SHOW ID İLE GERÇEK SAYFAYA GİDİYOR
      onTap: () => _navigateToPage(ShowDetailPage(showId: show.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: hasGradientBorder
              ? Border.all(
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
          image: DecorationImage(
            image: CachedNetworkImageProvider(show.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isTrend ? 0.3 : 0.2),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasTornEdge)
              CustomPaint(
                painter: _TornEdgePainter(color: Colors.white.withOpacity(0.1)),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(isWide ? 0.7 : 0.8),
                  ],
                  begin: isWide ? Alignment.centerRight : Alignment.topCenter,
                  end: isWide ? Alignment.centerLeft : Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isWide
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (tagText != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isTrend
                              ? Colors.white.withOpacity(0.9)
                              : context.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(
                            color:
                                isTrend ? context.primaryColor : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  Text(
                    show.name,
                    maxLines: isWide ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: isWide ? 22 : 16,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isWide)
                    Opacity(
                      opacity: 0.7,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Tarih: Yakında",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Tıklama efekti
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: () => _navigateToPage(ShowDetailPage(showId: show.id)),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. GLASS STAGE LIST (GERÇEK VERİ) ---
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis))
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
        clipBehavior: Clip.none,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("GÜNÜN FIRSATI",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        const Text("Romeo & Juliet",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("%20 İndirim Fırsatı",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                      ],
                    ),
                  ),
                ),
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

  // --- DİĞER YARDIMCI WIDGET'LAR ---

  // Pastel Kategoriler
  Widget _buildPastelCategories() {
    final categories = [
      {
        'icon': Icons.theater_comedy,
        'text': 'Tiyatro',
        'color': const Color(0xFFFFB7B2)
      },
      {
        'icon': Icons.music_note,
        'text': 'Konser',
        'color': const Color(0xFFE2F0CB)
      },
      {
        'icon': Icons.mic_external_on,
        'text': 'Stand-up',
        'color': const Color(0xFFFFDAC1)
      },
      {'icon': Icons.museum, 'text': 'Müze', 'color': const Color(0xFFC7CEEA)},
    ];

    return SizedBox(
      height: 100,
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
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
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

  Widget _buildSectionHeader(final String title, final String subtitle,
      {final VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
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

  Widget _buildFloatingParticles() {
    final random = math.Random(1); // Sabit seed
    return SizedBox.expand(
      child: Stack(
        children: List.generate(15, (final index) {
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            top: random.nextDouble() * MediaQuery.of(context).size.height,
            child: Container(
              width: random.nextDouble() * 3 + 1,
              height: random.nextDouble() * 3 + 1,
              decoration: BoxDecoration(
                color: context.primaryColor
                    .withOpacity(random.nextDouble() * 0.3 + 0.1),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDistortedTextBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: -0.05,
            child: Text(
              "KAOTİK",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: context.primaryColor.withOpacity(0.7),
                letterSpacing: -2,
                shadows: [
                  Shadow(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(30, -15),
            child: Text(
              "SANAT",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: context.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                fontStyle: FontStyle.italic,
                letterSpacing: 3,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(60, -25),
            child: Text(
              "DUVARI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500]!.withOpacity(0.8),
                letterSpacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaoticDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  context.primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(20, -1),
            child: Container(
              height: 1,
              width: 100,
              color: context.isDarkMode ? Colors.grey[600] : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomShapes() {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 10,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.4),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 30,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFB7B2).withOpacity(0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: 100,
            bottom: 15,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 60,
                height: 3,
                color: const Color(0xFFE2F0CB).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenMessage() => Padding(
        padding: const EdgeInsets.all(40.0),
        child: Opacity(
          opacity: 0.5,
          child: Column(
            children: [
              Transform.rotate(
                angle: 0.1,
                child: Text(
                  "✦",
                  style: TextStyle(
                    fontSize: 24,
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "kaos güzeldir",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      );
}

// PAINTER SINIFLARI
class _TornEdgePainter extends CustomPainter {
  final Color color;

  _TornEdgePainter({required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final random = math.Random(42);
    for (double y = 0; y < size.height; y += 8) {
      final x = size.width - 5 + random.nextDouble() * 10 - 5;
      if (y == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

class _SplatterPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    final random = math.Random(123);
    final paint = Paint()
      ..color = const Color(0xFFFFB7B2).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 8 + 2;
      final path = Path();
      path.addOval(Rect.fromCircle(
          center: Offset(x, y), radius: radius + random.nextDouble() * 3));
      for (int j = 0; j < 3; j++) {
        final offsetX = random.nextDouble() * 10 - 5;
        final offsetY = random.nextDouble() * 10 - 5;
        path.addOval(Rect.fromCircle(
            center: Offset(x + offsetX, y + offsetY), radius: radius * 0.3));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

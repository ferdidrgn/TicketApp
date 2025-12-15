import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../core/common/base_loadable_state.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/custom_dots_indicator.dart';
import '../../../../shared/widgets/custom_floating_action_button.dart';
import '../../../../shared/widgets/custom_search.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../campaigns/domain/entities/campaign_showcase_page.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  late AnimationController _floatingAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _fadeAnimationController;

  @override
  void initState() {
    super.initState();

    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _floatingAnimationController.dispose();
    _glowAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    ref.read(campaignProvider.notifier).loadCampaigns();
    ref.read(showProvider.notifier).loadShows(true);
    ref.read(stageProvider.notifier).loadStages(true);
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!_pageController.hasClients || !mounted) return;

      final campaignState = ref.read(campaignProvider);
      if (!campaignState.hasData) return;

      final campaigns = campaignState.dataList!;
      final nextPage = (_pageController.page?.round() ?? 0) + 1;

      _pageController.animateToPage(
        nextPage % campaigns.length,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _navigateToPage(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _resolveDetailPage(String url) {
    try {
      final id = url.split('/').last;
      if (id.isEmpty) throw Exception('Invalid URL ID: $url');

      if (url.contains('/shows')) return PlayerDetailPage(playerId: id);
      if (url.contains('/show')) return ShowDetailPage(showId: id);
      if (url.contains('/stages')) return StageDetailPage(stageId: id);

      throw Exception('Unknown URL type: $url');
    } catch (e) {
      debugPrint('Page resolution failed: $e');
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Sayfa yüklenemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.scaffoldBackgroundColor,
      floatingActionButton: CustomFloatingActionButton(onPressed: _loadAllData),
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          FadeTransition(
            opacity: _fadeAnimationController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),

                SliverToBoxAdapter(
                  child: _buildCampaignHeroSection(campaignState),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: Column(
                      children: [
                        _buildGlassSearch(),
                        const SizedBox(height: 35),
                        _buildFloatingCategories(),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: _buildSectionHeader(
                      'Sahneye Çıkanlar',
                      'En yeni gösteriler',
                      Icons.theater_comedy,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildShowSection(showState),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: _buildSectionHeader(
                      'Tarihi Sahneler',
                      'Kültür mekanları',
                      Icons.location_city,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildStageSection(stageState),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: _buildSectionHeader(
                      'Göz Alıcı Kareler',
                      'Sahneden anlar',
                      Icons.photo_library,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildGallerySection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.isDarkMode
                  ? [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ]
                  : [
                const Color(0xFFFFF5F5),
                const Color(0xFFFFE5E5),
                const Color(0xFFFFF0F0),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 100 + (50 * _glowAnimationController.value),
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200 - (30 * _glowAnimationController.value),
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.secondaryColor.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.scaffoldBackgroundColor,
                context.scaffoldBackgroundColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignHeroSection(
      LoadableState<dynamic, List<Campaign>> state) {
    if (state.isLoading) {
      return ShimmerLoading(
        height: MediaQuery.of(context).size.height * 0.55,
        width: double.infinity,
      );
    }

    if (state.hasError) {
      return _buildErrorWidget(state.errorMessage ?? 'Kampanyalar yüklenemedi');
    }

    if (!state.hasData) return const SizedBox(height: 80);

    final campaigns = state.dataList!;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: campaigns.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildCampaignCard(campaign),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: DotsIndicator(
                  itemCount: campaigns.length,
                  currentIndex: _currentPage % campaigns.length,
                  onPageSelected: (page) {
                    if (!_pageController.hasClients) return;
                    _pageController.animateToPage(
                      page,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return GestureDetector(
      onTap: () => _navigateToPage(_resolveDetailPage(campaign.url)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: campaign.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ShimmerLoading(),
                errorWidget: (_, __, ___) => Container(
                  color: context.surfaceColor,
                  child: const Icon(Icons.error, size: 50),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 25,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.primaryColor,
                            context.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Text(
                        'ÖZEL KAMPANYA',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      campaign.title,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToPage(
                              _resolveDetailPage(campaign.url)),
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Bilet Al',
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: context.primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildGlassSearch() {
    return GestureDetector(
      onTap: () => _navigateToPage(const SearchPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.textColor.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              'Etkinlik, sanatçı veya mekan ara...',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCategories() {
    final categories = [
      {
        'icon': Icons.theater_comedy,
        'title': 'Tiyatro',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
        ),
      },
      {
        'icon': Icons.music_note,
        'title': 'Konser',
        'gradient': const LinearGradient(
          colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
        ),
      },
      {
        'icon': Icons.mic,
        'title': 'Stand-up',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
        ),
      },
      {
        'icon': Icons.palette,
        'title': 'Sergi',
        'gradient': const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final cat = entry.value;
        return AnimatedBuilder(
          animation: _floatingAnimationController,
          builder: (context, child) {
            final offset = math.sin(
              (_floatingAnimationController.value * 2 * math.pi) +
                  (index * math.pi / 2),
            ) * 5;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: _buildCategoryCard(
            cat['icon'] as IconData,
            cat['title'] as String,
            cat['gradient'] as LinearGradient,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, LinearGradient gradient) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appGradient(),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Tümü',
            style: TextStyle(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowSection(LoadableState<dynamic, List<Show>> state) {
    if (state.isLoading) return _buildHorizontalShimmerList(height: 300);
    if (state.hasError)
      return _buildErrorWidget(state.errorMessage ?? 'Gösteriler yüklenemedi');
    if (!state.hasData) return const SizedBox(height: 10);

    final shows = state.dataList!;
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        physics: const BouncingScrollPhysics(),
        itemCount: shows.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _buildShowCard(shows[index]),
        ),
      ),
    );
  }

  Widget _buildShowCard(Show show) {
    return GestureDetector(
      onTap: () => _navigateToPage(ShowDetailPage(showId: show.id)),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: show.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ShimmerLoading(),
                errorWidget: (_, __, ___) => Container(
                  color: context.surfaceColor,
                  child: const Icon(Icons.broken_image),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    'YENİ',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        show.name,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ana Sahne',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStageSection(LoadableState<dynamic, List<Stage>> state) {
    if (state.isLoading) return _buildHorizontalShimmerList(height: 160);
    if (state.hasError)
      return _buildErrorWidget(state.errorMessage ?? 'Sahneler yüklenemedi');
    if (!state.hasData) return const SizedBox(height: 10);

    final stages = state.dataList!;
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        physics: const BouncingScrollPhysics(),
        itemCount: stages.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _buildStageCard(stages[index]),
        ),
      ),
    );
  }

  Widget _buildStageCard(Stage stage) {
    return GestureDetector(
      onTap: () => _navigateToPage(StageDetailPage(stageId: stage.id)),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: stage.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ShimmerLoading(),
                errorWidget: (_, __, ___) => Container(
                  color: context.surfaceColor,
                  child: const Icon(Icons.broken_image),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.theaters_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 180,
                        child: Text(
                          stage.name,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _buildGallerySection() {
    const imageUrl =
        'https://i.ytimg.com/vi/tzPpkRLf9a8/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGHIgWyg9MA8=&rs=AOn4CLCBnYXpB7USjvYDePL64AaVI7Epyw';

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        physics: const BouncingScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: _buildGalleryCard(index, imageUrl),
        ),
      ),
    );
  }

  Widget _buildGalleryCard(int index, String imageUrl) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerLoading(),
              errorWidget: (_, __, ___) => const Icon(Icons.error),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.red.withOpacity(0.1)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.errorColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: context.errorColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bir şeyler ters gitti',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShimmerList({double height = 200, double width = 160}) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 20),
          child: ShimmerLoading(width: width, height: height),
        ),
      ),
    );
  }
}
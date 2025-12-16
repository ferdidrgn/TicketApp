import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/custom_floating_action_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../campaigns/presentation/pages/campaign_showcase_page.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../widgets/mobile/artistic_search_bar.dart';
import '../widgets/mobile/category_grid.dart';
import '../widgets/mobile/decorative_elements.dart';
import '../widgets/mobile/glass_app_bar.dart';
import '../widgets/mobile/quick_actions_grid.dart';
import '../widgets/mobile/show_collage.dart';
import '../widgets/mobile/stage_carousel.dart';
import '../widgets/mobile/stroy_circles.dart';
import '../widgets/mobile/subsrice_widget.dart';
import '../widgets/mobile/ticket_stub_card.dart';
import '../widgets/mobile/trending_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _showSearchInAppBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) => _loadAllData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showSearchInAppBar = _scrollOffset > 250;
      });
    }
  }

  void _loadAllData() {
    ref.read(campaignProvider.notifier).loadCampaigns();
    ref.read(showProvider.notifier).loadShows(true);
    ref.read(stageProvider.notifier).loadStages(true);
  }

  void _navigateToPage(final Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (final _) => page));
  }

  void _openSearch() {
    _navigateToPage(const SearchPage());
  }

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignProvider);
    final showState = ref.watch(showProvider);
    final stageState = ref.watch(stageProvider);

    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAnimatedAppBar(context, isDark),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: _loadAllData,
      ),
      body: Stack(
        children: [
          // Ambient lighting effects
          const AmbientLightEffect(),
          const FloatingParticles(),

          // Main content
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 110, bottom: 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // Hero text
              const HeroSection(),

              // Artistic Search Bar (ana sayfa)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                opacity: _showSearchInAppBar ? 0 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: _showSearchInAppBar ? 0 : null,
                  child: ArtisticSearchBar(onTap: _openSearch),
                ),
              ),

              const SizedBox(height: 20),

              // Stories (Campaigns)
              SectionHeader(
                title: "Öne Çıkanlar",
                subtitle: "Vitrin",
                onTap: () => _navigateToPage(const CampaignShowcasePage()),
              ),
              StoryCircles(
                state: campaignState,
                onStoryTap: (final index) => _navigateToPage(
                  CampaignShowcasePage(initialIndex: index),
                ),
              ),
              const DividerWithAccent(),
              const SizedBox(height: 30),

              // Categories
              SectionHeader(
                title: "Kategoriler",
                subtitle: "Sanatın Renkleri",
                onTap: () {}, // TODO: Kategori sayfası
              ),
              const CategoryGrid(),
              const DividerWithAccent(),
              const SizedBox(height: 30),

              // Discover Shows
              SectionHeader(
                title: "Keşfet",
                subtitle: "Sana Özel Seçkiler",
                onTap: () {}, // TODO: Kategori sayfası
              ),
              ShowCollage(
                state: showState,
                onShowTap: (final showId) => _navigateToPage(
                  ShowDetailPage(showId: showId),
                ),
              ),
              const DividerWithAccent(),
              const SizedBox(height: 30),

              // Venues
              SectionHeader(
                title: "Mekanlar",
                subtitle: "Şehrin Sahneleri",
                onTap: () {}, // TODO: Mekanlar sayfası
              ),
              StageCarousel(
                state: stageState,
                onStageTap: (final stageId) => _navigateToPage(
                  StageDetailPage(stageId: stageId),
                ),
              ),
              const DividerWithAccent(),
              const SizedBox(height: 30),

              // Special offer
              const TicketStubCard(
                title: "Romeo & Juliet",
                subtitle: "%20 İndirim Fırsatı",
                imageUrl:
                    'https://images.unsplash.com/photo-1503095392269-2d609236f269?q=80&w=1000&auto=format&fit=crop',
              ),
              const SizedBox(height: 30),

              // Bottom extras
              QuickActionsGrid(
                onNotificationsTap: () {
                  // TODO: Bildirimler sayfası
                },
                onFavoritesTap: () {
                  // TODO: Favoriler sayfası
                },
                onTicketsTap: () {
                  // TODO: Biletlerim sayfası
                },
                onCalendarTap: () {
                  // TODO: Etkinlik takvimi
                },
              ),
              const SizedBox(height: 30),

              const TrendingNowSection(),
              const SizedBox(height: 30),

              const NewsletterSubscribe(),
              const SizedBox(height: 40),

              const BottomQuote(),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(
      final BuildContext context, final bool isDark) {
    final opacity = (_scrollOffset / 100).clamp(0.0, 0.9);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _scrollOffset > 50 ? 12 : 0,
                sigmaY: _scrollOffset > 50 ? 12 : 0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor.withOpacity(opacity),
                  border: _scrollOffset > 50
                      ? Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Logo
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showSearchInAppBar ? 0 : 1,
                            child: Text(
                              "TicketApp",
                              style: context.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),

                        // Compact Search Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: _showSearchInAppBar
                              ? MediaQuery.of(context).size.width - 40
                              : 0,
                          height: _showSearchInAppBar ? 42 : 0,
                          child: _showSearchInAppBar
                              ? GestureDetector(
                                  onTap: _openSearch,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                        color: context.primaryColor
                                            .withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(21),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.search,
                                              color: context.primaryColor
                                                  .withOpacity(0.8),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "Ara...",
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.5)
                                                      : Colors.black
                                                          .withOpacity(0.4),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

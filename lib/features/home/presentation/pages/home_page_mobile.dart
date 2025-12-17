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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // AppBar yüksekliğini 0 yap
        flexibleSpace: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: _showSearchInAppBar ? 110 : 0,
          child: OverflowBox(
            maxHeight: 110,
            alignment: Alignment.topCenter,
            child: Container(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _showSearchInAppBar ? 20 : 0,
                    left: 20,
                    right: 20,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showSearchInAppBar ? 1 : 0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: _showSearchInAppBar ? 1 : 0.9,
                      curve: Curves.easeOutBack,
                      child: ArtisticSearchBar(
                        onTap: _openSearch,
                        isCompact:
                            true, // Bu prop'u ArtisticSearchBar'a eklemelisiniz
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: _loadAllData,
      ),
      body: Stack(
        children: [
          // Ambient lighting effects
          const AmbientLightEffect(),
          const FloatingParticles(),

          // Main content - Üstten padding'i kaldırıyoruz
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 20, bottom: 100),
            // Top padding'i azalt
            physics: const BouncingScrollPhysics(),
            children: [
              // Hero text
              const HeroSection(),

              // Artistic Search Bar (ana sayfa) - Normal boyutta
              ArtisticSearchBar(onTap: _openSearch),

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
}

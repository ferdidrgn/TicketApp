import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/settings/presentation/pages/app_settings.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/decorative_elements.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/pages/campaign_showcase_page.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../favorite/presentation/pages/favorite_screen.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../widgets/mobile/category_grid.dart';
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted)
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showSearchInAppBar = _scrollOffset > 250;
      });
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  void _navigateToPage(final Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (final _) => page));

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignsProvider);
    final showState = ref.watch(showsProvider(isLimit: true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;

    final hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      appBar: _buildDynamicAppBar(),
      isLoading: isLoading && (campaignState.value == null),
      layoutConfig: PageBackgroundLayoutConfig(
        ambientColor: context.colors.primary.withOpacity(0.05),
        extendBody: true,
      ),
      child: hasError
          ? _buildErrorWidget(context, ref)
          : _buildActualContent(
              context,
              campaignState.value ?? [],
              showState.value ?? [],
              stageState.value ?? [],
              isLoggedIn,
              currentUser,
            ),
    );
  }

  PreferredSizeWidget _buildDynamicAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 5,
        toolbarHeight: _showSearchInAppBar ? 70 : 0,
        flexibleSpace: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            height: _showSearchInAppBar ? 60 : 0,
            child: Padding(
              padding: EdgeInsets.only(
                  top: _showSearchInAppBar ? 8 : 0, left: 20, right: 20),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSearchInAppBar ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  scale: _showSearchInAppBar ? 1 : 0.9,
                  curve: Curves.easeOutBack,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openSearch,
                      // Direkt burada tıklama olayı
                      borderRadius: BorderRadius.circular(24),
                      // ArtisticSearchBar'ın border radius'u ile aynı
                      child:
                          CustomSearchbar(onTap: _openSearch, isCompact: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildActualContent(
    final BuildContext context,
    final List<Campaign> campaigns,
    final List<Show> shows,
    final List<Stage> stages,
    final bool isLoggedIn,
    final User? currentUser,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const HeroSection(),
          CustomSearchbar(onTap: _openSearch),
          const SizedBox(height: 20),
          SectionHeader(
            title: "Öne Çıkanlar",
            subtitle: "Vitrin",
            onTap: () => _navigateToPage(const CampaignShowcasePage()),
          ),
          StoryCircles(
            campaigns: campaigns,
            onStoryTap: (final index) =>
                _navigateToPage(CampaignShowcasePage(initialIndex: index)),
          ),
          const DividerWithAccent(),
          const SizedBox(height: 30),
          SectionHeader(
            title: "Kategoriler",
            subtitle: "Sanatın Renkleri",
            onTap: () {},
          ),
          const CategoryGrid(),
          const DividerWithAccent(),
          const SizedBox(height: 30),
          SectionHeader(
            title: "Keşfet",
            subtitle: "Sana Özel Seçkiler",
            onTap: () {},
          ),
          ShowCollage(
            shows: shows,
            onShowTap: (final showId) =>
                _navigateToPage(ShowDetailPage(showId: showId)),
          ),
          const DividerWithAccent(),
          const SizedBox(height: 30),
          SectionHeader(
            title: "Mekanlar",
            subtitle: "Şehrin Sahneleri",
            onTap: () {},
          ),
          StageCarousel(
            stages: stages,
            onStageTap: (final stageId) =>
                _navigateToPage(StageDetailPage(stageId: stageId)),
          ),
          const DividerWithAccent(),
          const SizedBox(height: 30),
          const TicketStubCard(
            title: "Romeo & Juliet",
            subtitle: "%20 İndirim Fırsatı",
            imageUrl:
                'https://img.freepik.com/premium-vector/theatre2_1189973-28.jpg?semt=ais_hybrid&w=740&q=80',
          ),
          const SizedBox(height: 30),
          QuickActionsGrid(
            onNotificationsTap: () => _navigateToPage(const AppSettingsPage()),
            onFavoritesTap: () => _navigateToPage(const FavoritesPage()),
            onTicketsTap: () {
              if (isLoggedIn && currentUser != null)
                NavigationHandler.goToMyTickets(context, currentUser.uid);
              else
                NavigationHandler.goToLogin(context);
            },
            onCalendarTap: () {},
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
    );
  }

  Widget _buildErrorWidget(final BuildContext context, final WidgetRef ref) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.theater_comedy_outlined,
                size: 80,
                color: context.colors.outline,
              ),
              const SizedBox(height: 24),
              Text(
                "Perdeler Henüz Açılmadı!",
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "İnternet bağlantını kontrol edip sahneyi tekrar canlandırabilirsin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(campaignsProvider);
                  ref.invalidate(showsProvider);
                  ref.invalidate(stagesProvider);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text("Sahneyi Yenile"),
              ),
            ],
          ),
        ),
      );
}

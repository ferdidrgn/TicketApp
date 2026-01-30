import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/decorative_elements.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
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
    if (mounted) {
      final bool showSearch = _scrollController.offset > 250;
      if (_showSearchInAppBar != showSearch)
        setState(() => _showSearchInAppBar = showSearch);
    }
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignsProvider);
    final showState = ref.watch(showsProvider(isLimit: true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scrollController,
      // 💡 Web'de AppBar sabit durabilir, Mobilde dinamik
      appBar: isLargeScreen ? _buildWebAppBar(context) : _buildDynamicAppBar(),
      isLoading: isLoading && (campaignState.value == null),
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.05),
        extendBody: true,
      ),
      child: hasError
          ? _buildErrorWidget(context, ref)
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 1100 : double.infinity),
                child: _buildActualContent(
                  context,
                  campaignState.value ?? [],
                  showState.value ?? [],
                  stageState.value ?? [],
                  isLoggedIn,
                  currentUser,
                ),
              ),
            ),
    );
  }

  // --- APPBAR TASARIMLARI ---

  PreferredSizeWidget _buildDynamicAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: _showSearchInAppBar ? 80 : 0,
        flexibleSpace: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showSearchInAppBar
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: CustomSearchbar(onTap: _openSearch, isCompact: true),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );

  PreferredSizeWidget _buildWebAppBar(final BuildContext context) => AppBar(
        backgroundColor: context.colors.surface.withOpacity(0.8),
        elevation: 0,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: CustomSearchbar(onTap: _openSearch, isCompact: true),
        ),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded)),
          IconButton(
              onPressed: () => NavigationHandler.goToSettings(context),
              icon: const Icon(Icons.person_outline_rounded)),
          const SizedBox(width: 20),
        ],
      );

  // --- İÇERİK ---

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

          // Arama Çubuğu (Üstteki Arama)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomSearchbar(onTap: _openSearch),
          ),

          const SizedBox(height: 32),

          // 1. Öne Çıkanlar (Story)
          SectionHeader(
              title: "Öne Çıkanlar",
              subtitle: "Vitrin",
              onTap: () => NavigationHandler.goToCampaigns(context)),
          StoryCircles(
              campaigns: campaigns,
              onStoryTap: (final index) =>
                  NavigationHandler.goToCampaigns(context, index: index)),

          const DividerWithAccent(),

          // 2. Kategoriler
          SectionHeader(title: "Kategoriler", subtitle: "Sanatın Renkleri"),
          const CategoryGrid(),

          const DividerWithAccent(),

          // 3. Keşfet (Show Collage)
          SectionHeader(title: "Keşfet", subtitle: "Sana Özel Seçkiler"),
          ShowCollage(shows: shows),

          const DividerWithAccent(),

          // 4. Mekanlar (Carousel)
          SectionHeader(title: "Mekanlar", subtitle: "Şehrin Sahneleri"),
          StageCarousel(
            stages: stages,
            onStageTap: (final stageId) {
              final stage = stages.firstWhere((final e) => e.id == stageId);
              NavigationHandler.goToStage(context, stage.id, stage.name);
            },
          ),

          const DividerWithAccent(),

          // 5. Özel Kartlar & Aksiyonlar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TicketStubCard(
              title: "Romeo & Juliet",
              subtitle: "%20 İndirim Fırsatı",
              imageUrl:
                  'https://img.freepik.com/premium-vector/theatre2_1189973-28.jpg?semt=ais_hybrid&w=740&q=80',
            ),
          ),

          const SizedBox(height: 32),

          QuickActionsGrid(
            onNotificationsTap: () => NavigationHandler.goToSettings(context),
            onFavoritesTap: () => NavigationHandler.goToFavorites(context),
            onTicketsTap: () {
              if (isLoggedIn && currentUser != null)
                NavigationHandler.goToMyTickets(context, currentUser.uid);
              else
                NavigationHandler.goToLogin(context);
            },
            onCalendarTap: () {},
          ),

          const SizedBox(height: 40),
          const TrendingNowSection(),
          const SizedBox(height: 40),
          const NewsletterSubscribe(),
          const SizedBox(height: 60),
          const BottomQuote(),
          const SizedBox(height: 40),
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
              Icon(Icons.theater_comedy_outlined,
                  size: 80, color: context.colors.outline),
              const SizedBox(height: 24),
              Text("Perdeler Henüz Açılmadı!",
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(campaignsProvider);
                  ref.invalidate(showsProvider);
                  ref.invalidate(stagesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Sahneyi Yenile"),
              ),
            ],
          ),
        ),
      );
}

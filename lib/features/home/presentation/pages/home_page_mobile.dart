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
import '../widgets/mobile/home_dashboard_extras.dart';
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
      if (_showSearchInAppBar != showSearch) {
        setState(() => _showSearchInAppBar = showSearch);
      }
    }
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  @override
  Widget build(final BuildContext context) {
    // Orijinal Riverpod Sağlayıcı hatlarınız %100 aynen korunuyor
    final campaignState = ref.watch(campaignsProvider);
    final showState = ref.watch(showsProvider(isLimit: true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
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
          child: SingleChildScrollView(
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

                // 1. Öne Çıkanlar (Story) - Performans Sınıfına Bölündü
                _PerformantStorySection(
                    campaigns: campaignState.value ?? []),

                const DividerWithAccent(),

                // 2. Kategoriler - Sabit Düzen Katmanı
                _PerformantCategorySection(),

                const DividerWithAccent(),

                // 3. Keşfet (Show Collage)
                _PerformantCollageSection(shows: showState.value ?? []),

                const DividerWithAccent(),

                // 4. Mekanlar (Carousel)
                _PerformantStageCarouselSection(
                    stages: stageState.value ?? []),

                const DividerWithAccent(),

                // 5. Özel Kartlar, Aksiyonlar ve Kapanış Alanı
                const _PerformantSpecialCardsAndActionsSection(),

                _PerformantQuickActionsGridSection(),

                const SizedBox(height: 40),
                const TrendingNowSection(),
                const SizedBox(height: 40),
                const NewsletterSubscribe(),
                const SizedBox(height: 60),
                const BottomQuote(),
                const SizedBox(height: 40),

                // 🆕 EK DASHBOARD BÖLÜMLERİ — home içeriğinin ALTINA
                // eklendi, yukarıdaki hiçbir bileşen değiştirilmedi.
                // Giriş yapılmamışsa veya gösterilecek veri yoksa (etkinlik
                // bitmiş/bileti yok/tarihsiz) ilgili bölüm hiç render
                // edilmez — anasayfada "boş" içerik göstermiyoruz.
                const UpcomingTicketDashboardCard(),
                const SizedBox(height: 32),
                const NearbyEventsDashboardSection(),
                const SizedBox(height: 32),
                const FavoritesDashboardRow(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- APPBAR TASARIMLARI (Birebir Aynı Tutuldu) ---

  PreferredSizeWidget _buildDynamicAppBar() =>
      AppBar(
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

  PreferredSizeWidget _buildWebAppBar(final BuildContext context) =>
      AppBar(
        backgroundColor: context.colors.surface.withOpacity(0.8),
        elevation: 0,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: CustomSearchbar(onTap: _openSearch, isCompact: true),
        ),
        actions: [
          IconButton(
              onPressed: () => NavigationHandler.goToNotifications(context),
              icon: const Icon(Icons.notifications_none_rounded)),
          IconButton(
              onPressed: () => NavigationHandler.goToSettings(context),
              icon: const Icon(Icons.person_outline_rounded)),
          const SizedBox(width: 20),
        ],
      );

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

// --- ARKA PLANDA HIZLANMAYI SAĞLAYAN PERFORMANS WIDGET SINIFLARI ---

class _PerformantStorySection extends StatelessWidget {
  final List<Campaign> campaigns;

  const _PerformantStorySection({required this.campaigns});

  @override
  Widget build(final BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: "Öne Çıkanlar",
              subtitle: "Vitrin",
              onTap: () => NavigationHandler.goToCampaigns(context)),
          StoryCircles(
              campaigns: campaigns,
              onStoryTap: (final index) =>
                  NavigationHandler.goToCampaigns(context, index: index)),
        ],
      );
}

class _PerformantCategorySection extends StatelessWidget {
  const _PerformantCategorySection();

  @override
  Widget build(final BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: "Kategoriler", subtitle: "Sanatın Renkleri"),
          const CategoryGrid(),
        ],
      );
}

class _PerformantCollageSection extends StatelessWidget {
  final List<Show> shows;

  const _PerformantCollageSection({required this.shows});

  @override
  Widget build(final BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: "Keşfet", subtitle: "Sana Özel Seçkiler"),
          ShowCollage(shows: shows),
        ],
      );
}

class _PerformantStageCarouselSection extends StatelessWidget {
  final List<Stage> stages;

  const _PerformantStageCarouselSection({required this.stages});

  @override
  Widget build(final BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: "Mekanlar", subtitle: "Şehrin Sahneleri"),
          StageCarousel(
            stages: stages,
            onStageTap: (final stageId) {
              final stage = stages.firstWhere((final e) => e.id == stageId);
              NavigationHandler.goToStage(context, stage.id, stage.name);
            },
          ),
        ],
      );
}

class _PerformantSpecialCardsAndActionsSection extends StatelessWidget {
  const _PerformantSpecialCardsAndActionsSection();

  @override
  Widget build(final BuildContext context) =>
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: TicketStubCard(
          title: "Romeo & Juliet",
          subtitle: "%20 İndirim Fırsatı",
          imageUrl:
          'https://img.freepik.com/premium-vector/theatre2_1189973-28.jpg?semt=ais_hybrid&w=740&q=80',
        ),
      );
}

class _PerformantQuickActionsGridSection extends ConsumerWidget {
  const _PerformantQuickActionsGridSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: QuickActionsGrid(
          onNotificationsTap: () => NavigationHandler.goToNotifications(context),
          onFavoritesTap: () => NavigationHandler.goToFavorites(context),
          onTicketsTap: () {
            if (ref.read(isLoggedInProvider)) {
              final uid = ref.read(currentUserIdProvider);
              NavigationHandler.goToMyTickets(context, uid ?? "");
            } else
              NavigationHandler.goToLogin(context);
          },
          onCalendarTap: () => NavigationHandler.goToDiscover(context),
        ),
      );
}

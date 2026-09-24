import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/decorative_elements.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/theatre_show_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../providers/home_show_filter_provider.dart';
import '../widgets/mobile/category_grid.dart';
import '../widgets/mobile/home_teams_strip.dart';
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
    // 🔥 DÜZELTME: Ana sayfa artık TÜM Firestore kataloğunu değil, SADECE
    // TiyatRol ve Ataşehir Tiyatro Topluluğu'na ait gösterileri gösteriyor
    // (bkz. home_show_filter_provider.dart) — "dışarıdan aldığımız
    // oyunlar ana sayfada görünmemeli" talebi. Arama/keşfet sayfaları
    // BİLEREK bu filtreye tabi DEĞİL, tüm katalog orada kalıyor.
    // Önce aktif (takviminde gelecek etkinliği olan) oyunlar, ardından
    // (yer kaldıysa) aktif olmayanlar.
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    // "Aktif Oyunlar" şeridinin gerçek verisi — SADECE takviminde gelecek
    // etkinliği olan oyunlar (`homeShowsActiveFirstProvider`'ın TÜM sonucu
    // DEĞİL). İkincil bir bölüm; sayfanın genel loading/error durumunu
    // etkilemez, boşsa (henüz yüklenmemiş ya da gerçekten aktif oyun yoksa)
    // bölüm build() içinde tamamen gizlenir.
    final activeShowState = ref.watch(homeActiveShowsProvider(true));
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

                      // 0. Aktif Oyunlar — takviminde gelecek etkinliği
                      // olan gerçek oyunlar (web'deki `_HeroBand`/"sıradaki
                      // oyun" kavramının mobildeki karşılığı, ama mobilin
                      // kendi collage/şerit diliyle). Hiç aktif oyun yoksa
                      // (`activeShowState.value` boş/null) bölüm ve
                      // ayırıcısı tamamen gizlenir — sahte/placeholder
                      // içerik gösterilmez.
                      if ((activeShowState.value ?? const []).isNotEmpty) ...[
                        _PerformantActiveShowsSection(
                            shows: activeShowState.value!),
                        const DividerWithAccent(),
                      ],

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

                      // 4.5 Sahne Toplulukları (Teams)
                      const _PerformantTeamsSection(),

                      const DividerWithAccent(),

                      // 5. Özel Kartlar, Aksiyonlar ve Kapanış Alanı
                      _PerformantSpecialCardsAndActionsSection(
                          campaigns: campaignState.value ?? []),

                      _PerformantQuickActionsGridSection(),

                      const SizedBox(height: 40),
                      const TrendingNowSection(),
                      const SizedBox(height: 40),
                      const NewsletterSubscribe(),
                      const SizedBox(height: 60),
                      const BottomQuote(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- APPBAR TASARIMLARI (Birebir Aynı Tutuldu) ---

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

  PreferredSizeWidget _buildWebAppBar(final BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final unreadCount =
        isLoggedIn ? ref.watch(unreadNotificationCountProvider(uid)) : 0;

    return AppBar(
      backgroundColor: context.colors.surface.withOpacity(0.8),
      elevation: 0,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: CustomSearchbar(onTap: _openSearch, isCompact: true),
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.homeTooltipNotifications,
          onPressed: () => isLoggedIn
              ? NavigationHandler.goToNotifications(context)
              : NavigationHandler.goToLogin(context),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        IconButton(
            tooltip: AppLocalizations.of(context)!.homeTooltipSettings,
            onPressed: () => NavigationHandler.goToSettings(context),
            icon: const Icon(Icons.person_outline_rounded)),
        const SizedBox(width: 20),
      ],
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
              Text(AppLocalizations.of(context)!.homeErrorTitleMobile,
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
                label: Text(AppLocalizations.of(context)!.homeErrorRetryMobile),
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
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: AppLocalizations.of(context)!.homeFeaturedTitle,
              subtitle: AppLocalizations.of(context)!.homeFeaturedSubtitle,
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
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: AppLocalizations.of(context)!.homeCategoriesTitle,
              subtitle: AppLocalizations.of(context)!.homeCategoriesSubtitle),
          const CategoryGrid(),
        ],
      );
}

/// "Aktif Oyunlar" — sadece takviminde GELECEK tarihli en az bir etkinliği
/// olan oyunlar (`activeShowsProvider(true)`'dan gelen gerçek liste,
/// `showsActiveFirstProvider`'ın toplam uzunluğu DEĞİL). Bu widget'a
/// verilen `shows` her zaman zaten filtrelenmiş/gerçek "aktif" listedir —
/// aktiflik mantığı burada tekrar YAZILMIYOR, `show_provider.dart`'taki
/// `_activeShowIdsFromEvents`'ten türeyen provider'lar tüketiliyor.
///
/// Kart tasarımı `theatre_show_card.dart`'taki paylaşılan
/// `TheatreShowCard`'ı birebir kullanıyor (aynı gölge/köşe/hover dili) —
/// web'in hover-perde tekniği dokunmatik'te tetiklenmez ama kart zaten
/// dokunma ile `onTap` üzerinden çalışır, tasarım dili tutarlı kalır.
class _PerformantActiveShowsSection extends StatelessWidget {
  final List<Show> shows;

  const _PerformantActiveShowsSection({required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title: AppLocalizations.of(context)!.homeActiveShowsTitle,
            subtitle: AppLocalizations.of(context)!.homeActiveShowsSubtitle,
            onTap: () => NavigationHandler.goToDiscover(context)),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            physics: const BouncingScrollPhysics(),
            itemCount: shows.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (final context, final index) {
              final show = shows[index];
              return SizedBox(
                width: 168,
                child: Semantics(
                  button: true,
                  label: '${show.name}, ${show.category}',
                  child: TheatreShowCard(
                    show: show,
                    onTap: () => NavigationHandler.goToShow(
                        context, show.id, show.name),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PerformantCollageSection extends StatelessWidget {
  final List<Show> shows;

  const _PerformantCollageSection({required this.shows});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: AppLocalizations.of(context)!.homeDiscoverTitle,
              subtitle: AppLocalizations.of(context)!.homeCuratedForYou),
          ShowCollage(shows: shows),
        ],
      );
}

class _PerformantStageCarouselSection extends StatelessWidget {
  final List<Stage> stages;

  const _PerformantStageCarouselSection({required this.stages});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: AppLocalizations.of(context)!.homeVenuesTitle,
              subtitle: AppLocalizations.of(context)!.homeVenuesSubtitle),
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

class _PerformantTeamsSection extends StatelessWidget {
  const _PerformantTeamsSection();

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: AppLocalizations.of(context)!.homeTeamsTitle,
              subtitle: AppLocalizations.of(context)!.homeTeamsSubtitle,
              onTap: () => NavigationHandler.goToSearch(context)),
          const HomeTeamsStrip(),
        ],
      );
}

class _PerformantSpecialCardsAndActionsSection extends StatelessWidget {
  final List<Campaign> campaigns;

  const _PerformantSpecialCardsAndActionsSection({required this.campaigns});

  @override
  Widget build(final BuildContext context) {
    // Daha önce burada sabit/uydurma bir "Romeo & Juliet %20 İndirim"
    // kartı vardı (gerçek bir Firestore kampanyasına bağlı değildi, stok
    // görsel kullanıyordu, tıklanamazdı). Artık `campaignsProvider`'dan
    // (bu sayfa zaten build() başında çekiyor) gelen gerçek ilk kampanya
    // gösteriliyor; hiç kampanya yoksa kart tamamen gizleniyor — sahte bir
    // yer tutucuyla doldurulmuyor.
    if (campaigns.isEmpty) return const SizedBox.shrink();
    final campaign = campaigns.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TicketStubCard(
        title: campaign.title,
        subtitle: AppLocalizations.of(context)!.homeCampaignDiscoverSubtitle,
        imageUrl: campaign.imageUrl,
        onTap: () => NavigationHandler.goToCampaigns(
            context, index: campaigns.indexOf(campaign)),
      ),
    );
  }
}

class _PerformantQuickActionsGridSection extends ConsumerWidget {
  const _PerformantQuickActionsGridSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final unreadCount =
        isLoggedIn ? ref.watch(unreadNotificationCountProvider(uid)) : 0;

    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: QuickActionsGrid(
        notificationBadgeCount: unreadCount,
        onNotificationsTap: () {
          if (isLoggedIn)
            NavigationHandler.goToNotifications(context);
          else
            NavigationHandler.goToLogin(context);
        },
        onFavoritesTap: () => NavigationHandler.goToFavorites(context),
        onTicketsTap: () {
          if (isLoggedIn)
            NavigationHandler.goToMyTickets(context, uid);
          else
            NavigationHandler.goToLogin(context);
        },
        onCalendarTap: () {},
      ),
    );
  }
}

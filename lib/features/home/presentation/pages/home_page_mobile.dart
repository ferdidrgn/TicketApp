import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../widgets/mobile/home_dashboard_extras.dart';
import '../widgets/web/app_home_web_body.dart';

/// 🧩 TASARIM SİSTEMİ 2.0 — Home (mobil).
/// Eski dar tek-sütun mobil bileşen ağacı (HeroSection/StoryCircles/
/// CategoryGrid/ShowCollage/StageCarousel/TicketStubCard/QuickActionsGrid/
/// TrendingNowSection/NewsletterSubscribe/BottomQuote) tamamen kaldırıldı.
/// Veri katmanı (campaignsProvider/showsProvider/stagesProvider) birebir
/// korundu — sadece UI sıfırdan Bento-grid diliyle kuruldu.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  @override
  Widget build(final BuildContext context) {
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
      showFab: false,
      customScrollController: _scrollController,
      appBar: isLargeScreen ? _buildWebAppBar(context) : null,
      isLoading: isLoading && (campaignState.value == null),
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        extendBody: true,
        safeAreaTop: false,
      ),
      child: hasError
          ? _buildErrorWidget(context, ref)
          : isLargeScreen
              ? SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: AppHomeWebBody(
                    campaigns: campaignState.value ?? [],
                    shows: showState.value ?? [],
                    stages: stageState.value ?? [],
                    onOpenSearch: _openSearch,
                  ),
                )
              : _MobileBentoBody(
                  scrollController: _scrollController,
                  campaigns: campaignState.value ?? const [],
                  shows: showState.value ?? const [],
                  stages: stageState.value ?? const [],
                  onOpenSearch: _openSearch,
                ),
    );
  }

  PreferredSizeWidget _buildWebAppBar(final BuildContext context) => AppBar(
        backgroundColor: BentoColors.canvas.withOpacity(0.85),
        elevation: 0,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _SearchField(onTap: _openSearch, compact: true),
        ),
        actions: [
          IconButton(
              onPressed: () => NavigationHandler.goToNotifications(context),
              icon: const Icon(LucideIcons.bell, color: Colors.white70)),
          IconButton(
              onPressed: () => NavigationHandler.goToSettings(context),
              icon: const Icon(LucideIcons.user, color: Colors.white70)),
          const SizedBox(width: 20),
        ],
      );

  Widget _buildErrorWidget(final BuildContext context, final WidgetRef ref) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: BentoErrorState(
            message: 'Sahne şu an yüklenemedi. Bağlantını kontrol edip tekrar dene.',
            onRetry: () {
              ref.invalidate(campaignsProvider);
              ref.invalidate(showsProvider);
              ref.invalidate(stagesProvider);
            },
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// MOBİL GÖVDE — SliverAppBar + Bento-grid CustomScrollView
// ══════════════════════════════════════════════════════════════
class _MobileBentoBody extends ConsumerWidget {
  final ScrollController scrollController;
  final List<Campaign> campaigns;
  final List<Show> shows;
  final List<Stage> stages;
  final VoidCallback onOpenSearch;

  const _MobileBentoBody({
    required this.scrollController,
    required this.campaigns,
    required this.shows,
    required this.stages,
    required this.onOpenSearch,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: BentoColors.canvas,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TiyatRol',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4)),
                        const Text('Sahnedeki hikayeni keşfet',
                            style: TextStyle(
                                color: Color(0xFFA1A1AA), fontSize: 11.5)),
                      ],
                    ),
                  ),
                  _IconGhostButton(
                    icon: LucideIcons.bell,
                    badgeCount: unread,
                    onTap: () => NavigationHandler.goToNotifications(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SearchField(onTap: onOpenSearch),
              const SizedBox(height: 20),
              FadeInUp(child: _HeroBento(campaigns: campaigns, shows: shows)),
              const SizedBox(height: 20),
              const FadeInUp(
                  delay: Duration(milliseconds: 80),
                  child: _QuickActionsBentoRow()),
              if (shows.isNotEmpty) ...[
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 120),
                  child: _CategoryChipsRow(shows: shows),
                ),
              ],
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 160),
                child: BentoSectionHeader(
                  title: 'Öne Çıkan Oyunlar',
                  subtitle: 'Sana özel seçkiler',
                  icon: LucideIcons.sparkles,
                  onActionTap: () => NavigationHandler.goToDiscover(context),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _FeaturedShowsBento(shows: shows),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 240),
                child: BentoSectionHeader(
                  title: 'Mekanlar',
                  subtitle: 'Şehrin sahneleri',
                  icon: LucideIcons.mapPin,
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 280),
                child: _StagesBentoRow(stages: stages),
              ),
              const SizedBox(height: 32),
              const FadeInUp(
                delay: Duration(milliseconds: 320),
                child: UpcomingTicketDashboardCard(),
              ),
              const SizedBox(height: 20),
              const FadeInUp(
                delay: Duration(milliseconds: 360),
                child: FavoritesDashboardRow(),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ARAMA ALANI
// ══════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SearchField({required this.onTap, this.compact = false});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: compact ? 44 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: BentoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BentoColors.microBorder),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.search, size: 18, color: Color(0xFF71717A)),
              const SizedBox(width: 12),
              Text('Oyun, sahne veya sanatçı ara...',
                  style: TextStyle(
                      color: const Color(0xFF71717A),
                      fontSize: compact ? 13 : 14)),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// HERO BENTO KARTI
// ══════════════════════════════════════════════════════════════
class _HeroBento extends StatelessWidget {
  final List<Campaign> campaigns;
  final List<Show> shows;
  const _HeroBento({required this.campaigns, required this.shows});

  @override
  Widget build(final BuildContext context) {
    final Campaign? campaign = campaigns.isNotEmpty ? campaigns.first : null;
    final Show? show = shows.isNotEmpty ? shows.first : null;
    final String imageUrl = campaign?.imageUrl ?? show?.imageUrl ?? '';
    final String title = campaign?.title ?? show?.name ?? 'TiyatRol Sahnesi';

    return GestureDetector(
      onTap: () {
        if (show != null) NavigationHandler.goToShow(context, show.id, show.name);
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: BentoColors.microBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
              else
                Container(color: BentoColors.card),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      BentoColors.canvas.withOpacity(0.92),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BentoBadge(
                        label: 'SAHNEDE ŞİMDİ', icon: LucideIcons.flame),
                    const SizedBox(height: 10),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HIZLI AKSİYONLAR
// ══════════════════════════════════════════════════════════════
class _QuickActionsBentoRow extends ConsumerWidget {
  const _QuickActionsBentoRow();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final items = <_QuickAction>[
      _QuickAction(LucideIcons.compass, 'Keşfet',
          () => NavigationHandler.goToDiscover(context)),
      _QuickAction(LucideIcons.mapPin, 'Yakınımda',
          () => NavigationHandler.goToNearby(context)),
      _QuickAction(LucideIcons.heart, 'Favoriler',
          () => NavigationHandler.goToFavorites(context)),
      _QuickAction(LucideIcons.ticket, 'Biletlerim', () {
        if (ref.read(isLoggedInProvider)) {
          final uid = ref.read(currentUserIdProvider);
          NavigationHandler.goToMyTickets(context, uid ?? '');
        } else {
          NavigationHandler.goToLogin(context);
        }
      }),
    ];

    return Row(
      children: items
          .map((final item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: BentoCard(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    radius: 18,
                    onTap: item.onTap,
                    child: Column(
                      children: [
                        Icon(item.icon, size: 20, color: BentoColors.indigoLight),
                        const SizedBox(height: 8),
                        Text(item.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.onTap);
}

// ══════════════════════════════════════════════════════════════
// KATEGORİ ÇİPLERİ
// ══════════════════════════════════════════════════════════════
class _CategoryChipsRow extends StatelessWidget {
  final List<Show> shows;
  const _CategoryChipsRow({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final categories = shows
        .map((final s) => s.category)
        .where((final c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 8),
        itemBuilder: (final context, final index) {
          final c = categories[index];
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => NavigationHandler.goToDiscoverWithCategory(context, c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BentoColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: BentoColors.microBorder),
              ),
              child: Text(c,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÖNE ÇIKAN OYUNLAR — Bento grid (ilk kart büyük, gerisi 2 sütun)
// ══════════════════════════════════════════════════════════════
class _FeaturedShowsBento extends StatelessWidget {
  final List<Show> shows;
  const _FeaturedShowsBento({required this.shows});

  @override
  Widget build(final BuildContext context) {
    if (shows.isEmpty) {
      return const BentoEmptyState(
          icon: LucideIcons.theater, title: 'Henüz gösteri eklenmemiş.');
    }

    final rest = shows.skip(1).take(4).toList();

    return Column(
      children: [
        _ShowTile(show: shows.first, height: 220),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: rest.length,
            itemBuilder: (final context, final index) =>
                _ShowTile(show: rest[index], height: null),
          ),
        ],
      ],
    );
  }
}

class _ShowTile extends StatelessWidget {
  final Show show;
  final double? height;
  const _ShowTile({required this.show, required this.height});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BentoColors.microBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(show.category.toUpperCase(),
                          style: const TextStyle(
                              color: BentoColors.indigoLight,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// MEKANLAR
// ══════════════════════════════════════════════════════════════
class _StagesBentoRow extends StatelessWidget {
  final List<Stage> stages;
  const _StagesBentoRow({required this.stages});

  @override
  Widget build(final BuildContext context) {
    if (stages.isEmpty) {
      return const BentoEmptyState(
          icon: LucideIcons.building2, title: 'Henüz sahne eklenmemiş.');
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 12),
        itemBuilder: (final context, final index) {
          final stage = stages[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                NavigationHandler.goToStage(context, stage.id, stage.name),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BentoColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BentoColors.microBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: CachedNetworkImage(
                          imageUrl: stage.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(stage.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KÜÇÜK YARDIMCI: rozetli ikon butonu
// ══════════════════════════════════════════════════════════════
class _IconGhostButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconGhostButton(
      {required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BentoColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BentoColors.microBorder),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 19, color: Colors.white),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      );
}

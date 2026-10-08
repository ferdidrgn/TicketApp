import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/base/base_page_wrapper.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/admin_test_entry.dart';
import '../../../../../shared/widgets/craft.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../users/presentation/providers/user_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../stages/presentation/providers/stage_provider.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/team_provider.dart';
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';
import '../common/home_ui.dart';

/// Telefon ana sayfası — web gişesinden bağımsız, sıfırdan program yüzeyi.
///
/// İlk bakışta: bu gece ne var, hangisi öne çıkar, kimler sahnede, ne yapılır.
/// Bilet kromu yok; görsel gerçek afiş/fotoğraftan, renkler temadan gelir.
class MobileHomeCanvas extends ConsumerStatefulWidget {
  const MobileHomeCanvas({super.key});

  @override
  ConsumerState<MobileHomeCanvas> createState() => _MobileHomeCanvasState();
}

class _MobileHomeCanvasState extends ConsumerState<MobileHomeCanvas> {
  final ScrollController _scrollController = ScrollController();
  bool _buying = false;
  String? _when; // tonight | week | null
  String? _genre;
  String? _stageId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  void _openShow(final Show show, {final String from = 'home'}) =>
      NavigationHandler.goToShow(
        context,
        show.id,
        show.name,
        heroTag: TiyatrolHeroTags.show(show.id, from),
        imageUrl: show.imageUrl,
        title: show.name,
      );

  void _openTickets() {
    if (ref.read(isLoggedInProvider)) {
      NavigationHandler.goToMyTickets(
          context, ref.read(currentUserIdProvider) ?? '');
    } else {
      NavigationHandler.goToLogin(context);
    }
  }

  void _openNotifications() {
    if (ref.read(isLoggedInProvider)) {
      NavigationHandler.goToNotifications(context);
    } else {
      NavigationHandler.goToLogin(context);
    }
  }

  void _refresh() {
    ref.invalidate(campaignsProvider);
    ref.invalidate(homeShowsActiveFirstProvider(true));
    ref.invalidate(homeActiveShowsProvider(true));
    ref.invalidate(stagesProvider(isLimit: true));
    ref.invalidate(homeUpcomingSessionsProvider);
    ref.invalidate(playersProvider());
    ref.invalidate(teamsProvider(isLimit: true));
  }

  Future<void> _buy(final HomeFeatured featured) async {
    if (_buying) {
      return;
    }
    HapticFeedback.mediumImpact(); // ignore: unawaited_futures
    final Show show = featured.show;
    if (show.hasExternalTicketing) {
      setState(() => _buying = true);
      await openExternalTickets(context, show.externalTicketUrl);
      if (mounted) {
        setState(() => _buying = false);
      }
      return;
    }
    final HomeSession? session = featured.session;
    if (session != null) {
      final String userId = ref.read(currentUserIdProvider) ?? 'guest';
      NavigationHandler.goToSeatSelection(
          context, show.id, session.event.id, userId);
      return;
    }
    _openShow(show, from: 'mobile-cover');
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final campaignState = ref.watch(campaignsProvider);
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    final activeShowState = ref.watch(homeActiveShowsProvider(true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
    final sessionsState = ref.watch(homeUpcomingSessionsProvider);
    final playerState = ref.watch(playersProvider());
    final teamState = ref.watch(teamsProvider(isLimit: true));

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final bool hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    final List<Campaign> campaigns = campaignState.value ?? const [];
    final List<Show> shows = showState.value ?? const [];
    final List<Show> activeShows = activeShowState.value ?? const [];
    final List<Stage> stages = stageState.value ?? const [];
    final List<HomeSession> sessions = sessionsState.value ?? const [];
    final List<Player> players = (playerState.value ?? const <Player>[])
        .where((final p) => p.firstName.trim().isNotEmpty)
        .take(12)
        .toList();
    final List<Team> teams = teamState.value ?? const [];

    final List<HomeSession> filteredSessions = sessions.where((final s) {
      if (_when == 'tonight' && !_isTonight(s.date)) {
        return false;
      }
      if (_when == 'week' && !_isThisWeek(s.date)) {
        return false;
      }
      if (_genre != null &&
          browseCategoryKey(s.show.category) != _genre) {
        return false;
      }
      if (_stageId != null && s.stage?.id != _stageId) {
        return false;
      }
      return true;
    }).toList();
    final List<Show> filteredShows = shows.where((final show) {
      if (_genre != null && browseCategoryKey(show.category) != _genre) {
        return false;
      }
      return true;
    }).toList();
    final HomeFeatured? featured = filteredShows.isEmpty
        ? null
        : pickHomeFeatured(filteredSessions, filteredShows);
    final List<HomeSession> tonight = _tonight(filteredSessions);
    final List<HomeSession> upcomingBoard = tonight.isNotEmpty
        ? tonight
        : filteredSessions.take(5).toList();
    final Set<String> featuredIds = {
      if (featured != null) featured.show.id,
      ...upcomingBoard.map((final s) => s.show.id),
    };
    final List<Show> stories = [
      ...activeShows.where((final s) => !featuredIds.contains(s.id)),
      ...shows.where((final s) => !featuredIds.contains(s.id)),
    ];
    final List<Show> uniqueStories = <Show>[];
    final Set<String> seen = {};
    for (final Show show in stories) {
      if (seen.add(show.id)) {
        uniqueStories.add(show);
      }
      if (uniqueStories.length >= 6) {
        break;
      }
    }
    final List<BrowseCategory> genres = browseCategoriesOf(shows);
    Campaign? foundCampaign;
    for (final Campaign item in campaigns) {
      if (item.imageUrl.trim().isNotEmpty) {
        foundCampaign = item;
        break;
      }
    }
    final Campaign? campaign = foundCampaign;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scrollController,
      isLoading: isLoading && shows.isEmpty,
      shimmerSkeleton: const _HomeSkeleton(),
      onRefresh: _refresh,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        ambientColor: Colors.transparent,
        extendBody: true,
        safeAreaTop: false,
      ),
      child: hasError
          ? _HomeError(onRetry: _refresh)
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.isTablet ? 720 : double.infinity,
                ),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: AdminTestStrip()),
                    SliverToBoxAdapter(
                      child: _Masthead(
                        unreadCount: _unreadCount(),
                        onTickets: _openTickets,
                        onNotifications: _openNotifications,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Hello(
                        name: (ref.watch(userProfileProvider).value?.firstName ??
                                '')
                            .trim(),
                        tonightCount: tonight.length,
                        onSearch: _openSearch,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Filters(
                        when: _when,
                        genre: _genre,
                        stageId: _stageId,
                        genres: genres,
                        stages: stages,
                        onWhen: (final v) => setState(() => _when = v),
                        onGenre: (final v) => setState(() => _genre = v),
                        onStage: (final v) => setState(() => _stageId = v),
                      ),
                    ),
                    if (featured != null)
                      SliverToBoxAdapter(
                        child: _ListingCover(
                          featured: featured,
                          buying: _buying,
                          onOpen: () =>
                              _openShow(featured.show, from: 'mobile-cover'),
                          onBuy: () => _buy(featured),
                        ),
                      ),
                    if (tonight.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            0,
                            AppSpacing.xl,
                            AppSpacing.xl,
                          ),
                          child: ListingWaveCard(
                            onTap: () => NavigationHandler.goToDiscover(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bu gece',
                                  style: listingUi(
                                    color: context.colors.onPrimaryContainer,
                                    size: 13,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${tonight.length} seans seni bekliyor',
                                  style: listingUi(
                                    color: context.colors.onPrimaryContainer,
                                    size: 22,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  tonight.first.show.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: listingUi(
                                    color: context.colors.onPrimaryContainer
                                        .withValues(alpha: 0.85),
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (upcomingBoard.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _Programme(
                          sessions: upcomingBoard,
                          tonight: tonight.isNotEmpty,
                          onOpen: (final session) =>
                              _openShow(session.show, from: 'mobile-tonight'),
                          onSeeAll: () =>
                              NavigationHandler.goToDiscover(context),
                        ),
                      ),
                    if (uniqueStories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _Stories(
                          shows: uniqueStories,
                          onOpen: (final show) =>
                              _openShow(show, from: 'mobile-stories'),
                          onSeeAll: () =>
                              NavigationHandler.goToDiscover(context),
                        ),
                      ),
                    if (players.isNotEmpty)
                      SliverToBoxAdapter(child: _Faces(players: players)),
                    if (stages.isNotEmpty)
                      SliverToBoxAdapter(child: _Venues(stages: stages)),
                    if (teams.isNotEmpty)
                      SliverToBoxAdapter(child: _Companies(teams: teams)),
                    if (campaign != null)
                      SliverToBoxAdapter(
                        child: _CampaignBanner(
                          campaign: campaign,
                          onOpen: () => NavigationHandler.goToCampaigns(
                            context,
                            index: campaigns.indexOf(campaign),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
    );
  }

  int _unreadCount() {
    final bool loggedIn = ref.watch(isLoggedInProvider);
    final String uid = ref.watch(currentUserIdProvider) ?? '';
    return loggedIn ? ref.watch(unreadNotificationCountProvider(uid)) : 0;
  }
}

List<HomeSession> _tonight(final List<HomeSession> sessions) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  return [
    for (final HomeSession session in sessions)
      if (session.day == today && !session.date.isBefore(now)) session,
  ];
}

String _clock(final DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

const List<String> _kMonths = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

bool _isTonight(final DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(date.year, date.month, date.day);
  return day == today && !date.isBefore(now);
}

bool _isThisWeek(final DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime end = today.add(const Duration(days: 7));
  return !date.isBefore(now) && date.isBefore(end);
}

String _dayPhrase(final DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(date.year, date.month, date.day);
  if (day == today) {
    return 'Bu gece';
  }
  if (day == today.add(const Duration(days: 1))) {
    return 'Yarın';
  }
  return '${date.day} ${_kMonths[date.month - 1]}';
}

TextStyle _display(final Color color, {final double size = 36}) => listingUi(
      color: color,
      size: size,
      weight: FontWeight.w800,
      height: 1.04,
    );

class _Masthead extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;

  const _Masthead({
    required this.unreadCount,
    required this.onTickets,
    required this.onNotifications,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final double top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        top,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            'TiyatRol',
            style: listingUi(
              color: colors.onSurface,
              size: 22,
              weight: FontWeight.w800,
              height: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: homeText(context, 'Biletlerim', 'My tickets'),
            onPressed: onTickets,
            color: colors.onSurface,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.homeTooltipNotifications,
            onPressed: onNotifications,
            color: colors.onSurface,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hello extends StatelessWidget {
  final String name;
  final int tonightCount;
  final VoidCallback onSearch;

  const _Hello({
    required this.name,
    required this.tonightCount,
    required this.onSearch,
  });

  @override
  Widget build(final BuildContext context) {
    final String prompt = tonightCount > 0
        ? homeText(
            context,
            'Bu gece $tonightCount seans. Ne aramak istersin?',
            '$tonightCount performances tonight. What are you looking for?',
          )
        : homeText(
            context,
            'Ne aramak istersin?',
            'What are you looking for?',
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: ListingGreeting(
        name: name,
        prompt: prompt,
        onSearch: onSearch,
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String? when;
  final String? genre;
  final String? stageId;
  final List<BrowseCategory> genres;
  final List<Stage> stages;
  final ValueChanged<String?> onWhen;
  final ValueChanged<String?> onGenre;
  final ValueChanged<String?> onStage;

  const _Filters({
    required this.when,
    required this.genre,
    required this.stageId,
    required this.genres,
    required this.stages,
    required this.onWhen,
    required this.onGenre,
    required this.onStage,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListingLabel(homeText(context, 'Ne zaman', 'When')),
          ListingChipRow(
            children: [
              ListingChip(
                label: homeText(context, 'Bu gece', 'Tonight'),
                selected: when == 'tonight',
                onTap: () => onWhen(when == 'tonight' ? null : 'tonight'),
              ),
              ListingChip(
                label: homeText(context, 'Bu hafta', 'This week'),
                selected: when == 'week',
                onTap: () => onWhen(when == 'week' ? null : 'week'),
              ),
              ListingChip(
                label: homeText(context, 'Tümü', 'All'),
                selected: when == null,
                onTap: () => onWhen(null),
              ),
            ],
          ),
          if (genres.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ListingLabel(homeText(context, 'Tür', 'Genre')),
            ListingChipRow(
              children: [
                for (final BrowseCategory g in genres.take(8))
                  ListingChip(
                    label: g.label,
                    selected: genre == g.key,
                    onTap: () => onGenre(genre == g.key ? null : g.key),
                  ),
              ],
            ),
          ],
          if (stages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ListingLabel(homeText(context, 'Sahne', 'Venue')),
            ListingChipRow(
              children: [
                for (final Stage stage in stages.take(8))
                  ListingChip(
                    label: stage.name,
                    icon: Icons.place_outlined,
                    selected: stageId == stage.id,
                    onTap: () => onStage(stageId == stage.id ? null : stage.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingCover extends StatelessWidget {
  final HomeFeatured featured;
  final bool buying;
  final VoidCallback onOpen;
  final VoidCallback onBuy;

  const _ListingCover({
    required this.featured,
    required this.buying,
    required this.onOpen,
    required this.onBuy,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final Show show = featured.show;
    final HomeSession? session = featured.session;
    final String tag = TiyatrolHeroTags.show(show.id, 'mobile-cover');
    final String when = session == null
        ? homeText(context, 'Programda', 'On the bill')
        : '${_dayPhrase(session.date)}  ·  ${_clock(session.date)}';
    final String where = (session?.stage?.name ?? '').trim();
    final String action = show.hasExternalTicketing
        ? homeText(context, 'Bileti aç', 'Open tickets')
        : session == null
            ? homeText(context, 'Oyunu incele', 'View play')
            : homeText(context, 'Bilet al', 'Get tickets');
    final String duration = show.duration.trim().isEmpty
        ? '—'
        : show.duration.replaceAll(RegExp(r'[^0-9]'), '').isEmpty
            ? show.duration
            : show.duration.replaceAll(RegExp(r'[^0-9]'), '');
    final String age = show.ageLimit.trim().isEmpty ? '—' : show.ageLimit.trim();
    final String price = session?.priceLabel ?? when;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.huge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TiyatrolHero(
            tag: tag,
            child: ListingPhotoFrame(
              imageUrl: show.imageUrl,
              overlay: where.isEmpty ? null : where,
              height: 240,
              onTap: onOpen,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ListingLabel(homeText(context, 'Seans', 'Session')),
          Text(
            show.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: listingUi(
              color: colors.onSurface,
              size: 28,
              weight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            price,
            style: listingUi(
              color: colors.onSurface,
              size: 22,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              ListingMetricOrb(
                value: duration,
                unit: homeText(context, 'dk', 'min'),
                emphasized: true,
              ),
              const SizedBox(width: AppSpacing.md),
              ListingMetricOrb(
                value: session == null ? '—' : _clock(session.date),
                unit: homeText(context, 'saat', 'time'),
              ),
              const SizedBox(width: AppSpacing.md),
              ListingMetricOrb(
                value: age,
                unit: homeText(context, 'yaş', 'age'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ListingCta(label: action, busy: buying, onPressed: onBuy),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHead({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: listingUi(
                color: colors.onSurface,
                size: 20,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: listingUi(
                  color: colors.primary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Programme extends StatelessWidget {
  final List<HomeSession> sessions;
  final bool tonight;
  final ValueChanged<HomeSession> onOpen;
  final VoidCallback onSeeAll;

  const _Programme({
    required this.sessions,
    required this.tonight,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: tonight
                ? homeText(context, 'Bu gece', 'Tonight')
                : homeText(context, 'Sıradaki perdeler', 'Next curtains'),
            action: homeText(context, 'Tümü', 'See all'),
            onAction: onSeeAll,
          ),
          for (int i = 0; i < sessions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.6),
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
              ),
            _ProgrammeRow(
              session: sessions[i],
              onTap: () => onOpen(sessions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgrammeRow extends StatelessWidget {
  final HomeSession session;
  final VoidCallback onTap;

  const _ProgrammeRow({required this.session, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final String venue = (session.stage?.name ?? '').trim();
    return Semantics(
      button: true,
      label: '${session.show.name}, ${_clock(session.date)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    _clock(session.date),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: listingUi(
                          color: colors.onSurface,
                          size: 18,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if (venue.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreBoard extends StatelessWidget {
  final List<BrowseCategory> genres;
  final ValueChanged<String> onPick;

  const _GenreBoard({required this.genres, required this.onPick});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Ne izlemek istersin?', 'What mood?'),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: genres.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final i) {
                final BrowseCategory genre = genres[i];
                return Semantics(
                  button: true,
                  label: '${genre.label}, ${genre.count} oyun',
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: () => onPick(genre.label),
                    child: SizedBox(
                      width: 168,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: context.colors.surfaceContainerHighest,
                              child: genre.imageUrl.isEmpty
                                  ? null
                                  : OptimizedCachedImage(
                                      imageUrl: genre.imageUrl,
                                      fit: BoxFit.cover,
                                      borderRadius: 0,
                                    ),
                            ),
                            const ColoredBox(color: Color(0x73000000)),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Spacer(),
                                  Text(
                                    genre.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${genre.count}',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stories extends StatelessWidget {
  final List<Show> shows;
  final ValueChanged<Show> onOpen;
  final VoidCallback onSeeAll;

  const _Stories({
    required this.shows,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Hikâyeler', 'Stories'),
            action: homeText(context, 'Keşfet', 'Browse'),
            onAction: onSeeAll,
          ),
          for (final Show show in shows)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: _StoryRow(
                show: show,
                onTap: () => onOpen(show),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const _StoryRow({required this.show, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final String tag = TiyatrolHeroTags.show(show.id, 'mobile-stories');
    final List<String> meta = [
      if (show.category.trim().isNotEmpty) show.category.trim(),
      if (show.duration.trim().isNotEmpty) show.duration.trim(),
    ];
    return Semantics(
      button: true,
      label: '${show.name} oyununu aç',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              height: 118,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: AppShadows.level2(colors.shadow),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: TiyatrolHero(
                    tag: tag,
                    child: OptimizedCachedImage(
                      imageUrl: show.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                      width: 84,
                      height: 118,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: SizedBox(
                height: 118,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: listingUi(
                        color: colors.onSurface,
                        size: 20,
                        weight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      meta.isEmpty
                          ? homeText(context, 'Oyunu incele', 'View play')
                          : meta.join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faces extends StatelessWidget {
  final List<Player> players;

  const _Faces({required this.players});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Yüzler', 'Faces'),
            action: homeText(context, 'Tümü', 'See all'),
            onAction: () => NavigationHandler.goToSearch(context),
          ),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: players.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final i) =>
                  _FaceCard(player: players[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final Player player;

  const _FaceCard({required this.player});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final String name = '${player.firstName} ${player.lastName}'.trim();
    final String initials = [
      if (player.firstName.isNotEmpty) player.firstName[0],
      if (player.lastName.isNotEmpty) player.lastName[0],
    ].join().toUpperCase();
    final String heroTag = TiyatrolHeroTags.player(player.id, 'mobile-faces');
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: PressScale(
        onTap: () {
          TiyatrolHeroFlight.prepare(
            heroTag,
            imageUrl: player.imageUrl,
            title: name,
          );
          NavigationHandler.goToPlayer(
            context,
            player.id,
            name,
            heroTag: heroTag,
            imageUrl: player.imageUrl,
            title: name,
          );
        },
        child: SizedBox(
          width: 120,
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: AppShadows.level2(colors.shadow),
                  ),
                  child: TiyatrolHero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: ColoredBox(
                        color: colors.primaryContainer,
                        child: OptimizedCachedImage(
                          imageUrl: player.imageUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          borderRadius: 0,
                          errorBuilder: (final _, final __, final ___) =>
                              Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${player.firstName}\n${player.lastName}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Venues extends StatelessWidget {
  final List<Stage> stages;

  const _Venues({required this.stages});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Sahne', 'Venues'),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: stages.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final i) {
                final Stage stage = stages[i];
                return Semantics(
                  button: true,
                  label: stage.name,
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: () => NavigationHandler.goToStage(
                      context,
                      stage.id,
                      stage.name,
                    ),
                    child: SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            OptimizedCachedImage(
                              imageUrl: stage.imageUrl,
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            ),
                            const ColoredBox(color: Color(0x66000000)),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  stage.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: listingUi(
                                    color: Colors.white,
                                    size: 20,
                                    weight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Companies extends StatelessWidget {
  final List<Team> teams;

  const _Companies({required this.teams});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Topluluklar', 'Companies'),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: teams.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (final context, final i) {
                final Team team = teams[i];
                return Semantics(
                  button: true,
                  label: team.name,
                  excludeSemantics: true,
                  child: PressScale(
                    onTap: () => NavigationHandler.goToTeam(
                      context,
                      team.id,
                      team.name,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Material(
                        color: context.colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xs,
                            AppSpacing.xs,
                            AppSpacing.lg,
                            AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: OptimizedCachedImage(
                                    imageUrl: team.imageUrl,
                                    fit: BoxFit.cover,
                                    borderRadius: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                team.name,
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignBanner extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onOpen;

  const _CampaignBanner({required this.campaign, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Semantics(
        button: true,
        label: campaign.title,
        excludeSemantics: true,
        child: PressScale(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedCachedImage(
                    imageUrl: campaign.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                  const ColoredBox(color: Color(0x59000000)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: listingUi(
                          color: Colors.white,
                          size: 22,
                          weight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    Widget block(final double height, {final double radius = AppRadius.md}) =>
        Container(
          height: height,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.massive,
        AppSpacing.xl,
        120,
      ),
      children: [
        block(72),
        const SizedBox(height: AppSpacing.xl),
        block(52),
        const SizedBox(height: AppSpacing.xxl),
        block(360, radius: 0),
        const SizedBox(height: AppSpacing.xxl),
        block(72),
        const SizedBox(height: AppSpacing.md),
        block(72),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  final VoidCallback onRetry;

  const _HomeError({required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.theater_comedy_outlined,
              size: 64,
              color: colors.outline,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppLocalizations.of(context)!.homeErrorTitleMobile,
              textAlign: TextAlign.center,
              style: _display(colors.onSurface, size: 26),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              homeText(
                context,
                'Program yüklenemedi. Bağlantını kontrol edip tekrar dene.',
                'The programme could not load. Check the connection and retry.',
              ),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.homeErrorRetryMobile),
            ),
          ],
        ),
      ),
    );
  }
}

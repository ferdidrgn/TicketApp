import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/base/base_page_wrapper.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/admin_test_entry.dart';
import '../../../../../shared/widgets/craft.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
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
import '../../../../users/presentation/providers/user_provider.dart';
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';
import '../common/home_ui.dart';

/// Telefon ana sayfası — "Akşam Defteri".
///
/// İlk bakış: marka + selamlama + arama, sonra afiş kapak ve program satırları.
/// Bilet kromu yok; renkler temadan; görsel gerçek afiş/fotoğraftan.
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
      if (_genre != null && browseCategoryKey(s.show.category) != _genre) {
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
    final List<HomeSession> programme = tonight.isNotEmpty
        ? tonight
        : filteredSessions.take(6).toList();
    final Set<String> featuredIds = {
      if (featured != null) featured.show.id,
      ...programme.map((final s) => s.show.id),
    };
    final List<Show> moreShows = <Show>[];
    final Set<String> seen = {};
    for (final Show show in [...activeShows, ...shows]) {
      if (featuredIds.contains(show.id) || !seen.add(show.id)) {
        continue;
      }
      moreShows.add(show);
      if (moreShows.length >= 8) {
        break;
      }
    }
    final List<BrowseCategory> genres = browseCategoriesOf(shows);
    Campaign? campaign;
    for (final Campaign item in campaigns) {
      if (item.imageUrl.trim().isNotEmpty) {
        campaign = item;
        break;
      }
    }

    final String firstName =
        (ref.watch(userProfileProvider).value?.firstName ?? '').trim();

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
                        name: firstName,
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
                        onWhen: (final v) {
                          HapticFeedback.selectionClick();
                          setState(() => _when = v);
                        },
                        onGenre: (final v) {
                          HapticFeedback.selectionClick();
                          setState(() => _genre = v);
                        },
                        onStage: (final v) {
                          HapticFeedback.selectionClick();
                          setState(() => _stageId = v);
                        },
                      ),
                    ),
                    if (featured != null)
                      SliverToBoxAdapter(
                        child: _Cover(
                          featured: featured,
                          buying: _buying,
                          onOpen: () =>
                              _openShow(featured.show, from: 'mobile-cover'),
                          onBuy: () => _buy(featured),
                        ),
                      ),
                    if (programme.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _Programme(
                          sessions: programme,
                          tonight: tonight.isNotEmpty,
                          onOpen: (final session) =>
                              _openShow(session.show, from: 'mobile-tonight'),
                          onSeeAll: () =>
                              NavigationHandler.goToDiscover(context),
                        ),
                      ),
                    if (moreShows.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _PosterRail(
                          shows: moreShows,
                          onOpen: (final show) =>
                              _openShow(show, from: 'mobile-rail'),
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
                            index: campaigns.indexOf(campaign!),
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

// ─── helpers ────────────────────────────────────────────────────────────────

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

// ─── masthead ───────────────────────────────────────────────────────────────

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
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: listingUi(
                  color: colors.onSurface,
                  size: 24,
                  weight: FontWeight.w800,
                  height: 1.0,
                ),
                children: [
                  const TextSpan(text: 'Tiyat'),
                  TextSpan(
                    text: 'Rol',
                    style: TextStyle(color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
          _IconBtn(
            icon: Icons.confirmation_number_outlined,
            label: 'Biletlerim',
            onTap: onTickets,
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconBtn(
            icon: Icons.notifications_none_rounded,
            label: 'Bildirimler',
            badge: unreadCount,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: colors.onSurface),
                if (badge > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── hello + search ─────────────────────────────────────────────────────────

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
    final ColorScheme colors = context.colors;
    final String greet = name.isEmpty
        ? homeText(context, 'Merhaba', 'Hello')
        : homeText(context, 'Merhaba $name', 'Hello $name');
    final String headline = tonightCount > 0
        ? homeText(
            context, 'Bu akşam sahnede ne var?', "What's on tonight?")
        : homeText(
            context, 'Bu hafta ne izlemek istersin?', 'What to watch this week?');
    final String hint = tonightCount > 0
        ? homeText(
            context,
            '$tonightCount seans bu gece · ara',
            '$tonightCount shows tonight · search',
          )
        : homeText(
            context,
            'Oyun, oyuncu veya sahne ara',
            'Search plays, actors or venues',
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greet,
            style: listingUi(
              color: colors.onSurfaceVariant,
              size: 13,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            headline,
            style: listingUi(
              color: colors.onSurface,
              size: 30,
              weight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            button: true,
            label: hint,
            child: PressScale(
              onTap: () {
                HapticFeedback.selectionClick();
                onSearch();
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: AppShadows.level1(colors.shadow),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: colors.onSurfaceVariant, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: listingUi(
                          color: colors.onSurfaceVariant,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── filters ────────────────────────────────────────────────────────────────

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
    final ColorScheme colors = context.colors;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        children: [
          _Chip(
            label: homeText(context, 'Bu gece', 'Tonight'),
            selected: when == 'tonight',
            onTap: () => onWhen(when == 'tonight' ? null : 'tonight'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: homeText(context, 'Bu hafta', 'This week'),
            selected: when == 'week',
            onTap: () => onWhen(when == 'week' ? null : 'week'),
          ),
          for (final BrowseCategory g in genres.take(6)) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(
              label: g.label,
              selected: genre == g.key,
              onTap: () => onGenre(genre == g.key ? null : g.key),
            ),
          ],
          for (final Stage s in stages.take(4)) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(
              label: s.name,
              selected: stageId == s.id,
              onTap: () => onStage(stageId == s.id ? null : s.id),
              tone: colors.secondaryContainer,
              ink: colors.onSecondaryContainer,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tone;
  final Color? ink;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone,
    this.ink,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    final Color bg = selected
        ? colors.onSurface
        : (tone ?? colors.surfaceContainerHighest);
    final Color fg = selected
        ? colors.surface
        : (ink ?? colors.onSurface);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: listingUi(color: fg, size: 13, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ─── cover ──────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  final HomeFeatured featured;
  final bool buying;
  final VoidCallback onOpen;
  final VoidCallback onBuy;

  const _Cover({
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
        ? homeText(context, 'Yakında', 'Coming soon')
        : '${_dayPhrase(session.date)} · ${_clock(session.date)}';
    final String place = [
      if (session?.stage?.name.trim().isNotEmpty == true)
        session!.stage!.name.trim(),
      if (session?.priceLabel != null)
        homeText(
          context,
          '${session!.priceLabel}\'den',
          'from ${session.priceLabel}',
        ),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Semantics(
        button: true,
        label: '${show.name}, $when',
        child: PressScale(
          onTap: onOpen,
          child: AspectRatio(
            aspectRatio: 3 / 4.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.level3(colors.shadow),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TiyatrolHero(
                      tag: tag,
                      child: OptimizedCachedImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x99000000),
                            Color(0xE6000000),
                          ],
                          stops: [0.35, 0.72, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs + 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                when.toUpperCase(),
                                style: listingUi(
                                  color: Colors.white,
                                  size: 11,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            show.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: listingUi(
                              color: Colors.white,
                              size: 28,
                              weight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          if (place.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: listingUi(
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: buying ? null : onBuy,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                              ),
                              child: buying
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      homeText(
                                          context, 'Bilet al', 'Get tickets'),
                                      style: listingUi(
                                        color: colors.onPrimary,
                                        size: 15,
                                        weight: FontWeight.w800,
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
          ),
        ),
      ),
    );
  }
}

// ─── programme ──────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: tonight
                ? homeText(context, 'Program', 'Programme')
                : homeText(context, 'Yaklaşan', 'Upcoming'),
            action: homeText(context, 'Tümü', 'See all'),
            onAction: onSeeAll,
          ),
          for (final HomeSession session in sessions)
            _ProgrammeRow(
              session: session,
              onTap: () => onOpen(session),
            ),
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
    final Show show = session.show;
    final String tag = TiyatrolHeroTags.show(show.id, 'mobile-tonight');
    return Semantics(
      button: true,
      label: '${show.name}, ${_clock(session.date)}',
      child: PressScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _clock(session.date),
                          style: listingUi(
                            color: colors.onSurface,
                            size: 14,
                            weight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _dayPhrase(session.date),
                          style: listingUi(
                            color: colors.onSurfaceVariant,
                            size: 11,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 56,
                    height: 74,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        boxShadow: AppShadows.level1(colors.shadow),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: TiyatrolHero(
                          tag: tag,
                          child: OptimizedCachedImage(
                            imageUrl: show.imageUrl,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 74,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: listingUi(
                            color: colors.onSurface,
                            size: 15,
                            weight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          session.stage?.name.trim().isNotEmpty == true
                              ? session.stage!.name
                              : (show.category.trim().isNotEmpty
                                  ? show.category
                                  : homeText(
                                      context, 'Oyunu aç', 'Open show')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: listingUi(
                            color: colors.onSurfaceVariant,
                            size: 12,
                            weight: FontWeight.w600,
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
      ),
    );
  }
}

// ─── poster rail ────────────────────────────────────────────────────────────

class _PosterRail extends StatelessWidget {
  final List<Show> shows;
  final ValueChanged<Show> onOpen;
  final VoidCallback onSeeAll;

  const _PosterRail({
    required this.shows,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Daha fazla', 'More'),
            action: homeText(context, 'Keşfet', 'Discover'),
            onAction: onSeeAll,
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: shows.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final i) {
                final Show show = shows[i];
                final String tag =
                    TiyatrolHeroTags.show(show.id, 'mobile-rail');
                return Semantics(
                  button: true,
                  label: show.name,
                  child: PressScale(
                    onTap: () => onOpen(show),
                    child: SizedBox(
                      width: 128,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                boxShadow:
                                    AppShadows.level2(context.colors.shadow),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: TiyatrolHero(
                                  tag: tag,
                                  child: OptimizedCachedImage(
                                    imageUrl: show.imageUrl,
                                    fit: BoxFit.cover,
                                    width: 128,
                                    borderRadius: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            show.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: listingUi(
                              color: context.colors.onSurface,
                              size: 13,
                              weight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ],
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

// ─── faces / venues / companies ─────────────────────────────────────────────

class _Faces extends StatelessWidget {
  final List<Player> players;

  const _Faces({required this.players});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
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
                style: listingUi(
                  color: colors.onSurface,
                  size: 12,
                  weight: FontWeight.w700,
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
    final ColorScheme colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Mekanlar', 'Venues'),
            action: homeText(context, 'Tümü', 'See all'),
            onAction: () => NavigationHandler.goToSearch(context),
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: stages.take(8).length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final i) {
                final Stage stage = stages[i];
                return Semantics(
                  button: true,
                  label: stage.name,
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
                            ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: OptimizedCachedImage(
                                imageUrl: stage.imageUrl,
                                fit: BoxFit.cover,
                                borderRadius: 0,
                              ),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0xCC000000),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              bottom: AppSpacing.md,
                              child: Text(
                                stage.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: listingUi(
                                  color: Colors.white,
                                  size: 15,
                                  weight: FontWeight.w800,
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
    final ColorScheme colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHead(
            title: homeText(context, 'Topluluklar', 'Companies'),
            action: homeText(context, 'Tümü', 'See all'),
            onAction: () => NavigationHandler.goToSearch(context),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: teams.take(10).length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (final context, final i) {
                final Team team = teams[i];
                return Semantics(
                  button: true,
                  label: team.name,
                  child: PressScale(
                    onTap: () => NavigationHandler.goToTeam(
                      context,
                      team.id,
                      team.name,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: OptimizedCachedImage(
                                imageUrl: team.imageUrl,
                                fit: BoxFit.cover,
                                borderRadius: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Flexible(
                            child: Text(
                              team.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: listingUi(
                                color: colors.onSurface,
                                size: 13,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
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
        child: PressScale(
          onTap: onOpen,
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: OptimizedCachedImage(
                imageUrl: campaign.imageUrl,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── section / states ───────────────────────────────────────────────────────

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
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: listingUi(
                color: colors.onSurface,
                size: 22,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(48, 40),
              ),
              child: Text(
                action!,
                style: listingUi(
                  color: colors.primary,
                  size: 13,
                  weight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              homeText(
                context,
                'Program yüklenemedi',
                'Could not load programme',
              ),
              textAlign: TextAlign.center,
              style: listingUi(
                color: colors.onSurface,
                size: 18,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(homeText(context, 'Tekrar dene', 'Try again')),
            ),
          ],
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
    Widget box(final double h, {final double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        box(28, w: 140),
        const SizedBox(height: AppSpacing.xl),
        box(16, w: 120),
        const SizedBox(height: AppSpacing.sm),
        box(36, w: 260),
        const SizedBox(height: AppSpacing.lg),
        box(52),
        const SizedBox(height: AppSpacing.lg),
        box(420),
        const SizedBox(height: AppSpacing.xl),
        box(22, w: 100),
        const SizedBox(height: AppSpacing.md),
        box(72),
        const SizedBox(height: AppSpacing.sm),
        box(72),
      ],
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/listing.dart';
import '../../../../shared/widgets/rive/tiyatrol_rive.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart' show Reveal;
import '../../../../shared/widgets/ticket/stage_moments.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../home/presentation/providers/home_sessions_provider.dart';
import '../../../home/presentation/widgets/common/home_showcase.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../widgets/browse_controls.dart';
import '../widgets/discovery_spine.dart';

/// KEŞFET — dikey tür omurgası + afiş ızgarası.
///
/// Sol şerit: program kenarı gibi 90° türler. Sağ: gerçek oyun afişleri.
/// Kocaman chip şeritleri yok; zaman/sıralama ince nabız çubuğunda.
class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

String discoveryCategoryKey(final String raw) => browseCategoryKey(raw);

enum _Sort { soonest, newest, alpha }

const List<String> _sortLabels = ['Yakın tarih', 'Yeni', 'A–Z'];

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  String? _categoryKey;
  bool _showPast = false;
  _Sort _sort = _Sort.soonest;
  BrowseWhen _when = BrowseWhen.any;
  bool _showAllInactive = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _categoryKey = _keyOf(widget.selectedCategory);
  }

  @override
  void didUpdateWidget(covariant final DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _categoryKey = _keyOf(widget.selectedCategory);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String? _keyOf(final String? raw) =>
      (raw == null || raw.trim().isEmpty) ? null : discoveryCategoryKey(raw);

  void _pickCategory(final String? key) {
    sparkBurst(context);
    setState(() {
      _categoryKey = key;
      _showAllInactive = false;
    });
    if (widget.selectedCategory != null && key == null) {
      context.go('/discover');
    }
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _categoryKey = null;
      _when = BrowseWhen.any;
      _showAllInactive = false;
    });
    if (widget.selectedCategory != null) {
      context.go('/discover');
    }
  }

  void _openShow(final Show show, {final String from = 'discover'}) {
    final String tag = TiyatrolHeroTags.show(show.id, from);
    TiyatrolHeroFlight.prepare(tag,
        imageUrl: show.imageUrl, title: show.name);
    NavigationHandler.goToShow(
      context,
      show.id,
      show.name,
      heroTag: tag,
      imageUrl: show.imageUrl,
      title: show.name,
    );
  }

  void _retry() {
    ref.invalidate(showsProvider);
    ref.invalidate(eventsByShowIdsProvider);
    ref.invalidate(showsActiveFirstProvider);
    ref.invalidate(pastShowsProvider);
    ref.invalidate(activeShowsProvider);
  }

  List<Show> _sorted(final List<Show> shows) {
    switch (_sort) {
      case _Sort.soonest:
        return shows;
      case _Sort.newest:
        final l = List<Show>.of(shows);
        sortShowsByCreatedAtDescending(l);
        return l;
      case _Sort.alpha:
        return List<Show>.of(shows)
          ..sort((final a, final b) => discoveryCategoryKey(a.name)
              .compareTo(discoveryCategoryKey(b.name)));
    }
  }

  Set<String> _showIdsForWhen(
    final List<HomeSession> sessions,
    final BrowseWhen when,
  ) {
    if (when == BrowseWhen.any) {
      return {for (final s in sessions) s.show.id};
    }
    return {
      for (final HomeSession s in sessions)
        if (browseMatchesWhen(s.date, when)) s.show.id,
    };
  }

  Map<BrowseWhen, int> _whenCounts(
    final List<Show> pool,
    final List<HomeSession> sessions,
  ) {
    final Set<String> poolIds = pool.map((final s) => s.id).toSet();
    final Map<BrowseWhen, int> out = {};
    for (final BrowseWhen w in BrowseWhen.values) {
      if (w == BrowseWhen.any) {
        out[w] = pool.length;
        continue;
      }
      out[w] =
          _showIdsForWhen(sessions, w).where(poolIds.contains).length;
    }
    return out;
  }

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<List<Show>> showsState = _showPast
        ? ref.watch(pastShowsProvider(false))
        : ref.watch(activeShowsProvider(false));
    final AsyncValue<List<Show>> activeState =
        ref.watch(activeShowsProvider(false));

    final bool loading = (showsState.isLoading && !showsState.hasValue) ||
        (!_showPast && activeState.isLoading && !activeState.hasValue);
    final bool failed = !loading &&
        ((showsState.hasError && !showsState.hasValue) ||
            (!_showPast && activeState.hasError && !activeState.hasValue));

    final List<Show> all = showsState.value ?? const <Show>[];
    final Set<String> activeIds =
        (activeState.value ?? const <Show>[]).map((final s) => s.id).toSet();
    final List<BrowseCategory> categories = browseCategoriesOf(all);
    final String? key =
        categories.any((final c) => c.key == _categoryKey) ? _categoryKey : null;
    List<Show> filtered = key == null
        ? all
        : all
            .where((final s) => discoveryCategoryKey(s.category) == key)
            .toList();

    final List<HomeSession> sessions = (!_showPast && !loading && !failed)
        ? (ref.watch(homeUpcomingSessionsProvider).value ??
            const <HomeSession>[])
        : const <HomeSession>[];
    final Map<BrowseWhen, int> whenCounts =
        _showPast ? const {} : _whenCounts(filtered, sessions);

    if (!_showPast && _when != BrowseWhen.any) {
      final Set<String> whenIds = _showIdsForWhen(sessions, _when);
      filtered = filtered.where((final s) => whenIds.contains(s.id)).toList();
    }

    final List<Show> primary = _sorted(_showPast
        ? filtered
        : filtered.where((final s) => activeIds.contains(s.id)).toList());
    final List<Show> secondary = _showPast
        ? const []
        : _sorted(
            filtered.where((final s) => !activeIds.contains(s.id)).toList());

    final view = _View(
      loading: loading,
      failed: failed,
      categories: categories,
      categoryKey: key,
      primary: primary,
      secondary: secondary,
      whenCounts: whenCounts,
      filtersActive: key != null || (!_showPast && _when != BrowseWhen.any),
    );

    return context.isDesktop
        ? _shell(context, view, columns: 4, gutter: AppSpacing.huge, spine: 64)
        : _shell(
            context,
            view,
            columns: context.isTablet ? 3 : 2,
            gutter: context.isTablet ? AppSpacing.xxl : AppSpacing.lg,
            spine: 50,
          );
  }

  String _statusLine(final _View v) {
    if (v.loading) {
      return 'Oyunlar yükleniyor…';
    }
    if (v.failed) {
      return 'Yüklenemedi — tekrar dene.';
    }
    final String? label = v.categoryLabel;
    final int n = v.primary.length;
    if (_showPast) {
      return label == null ? '$n geçmiş oyun' : '$label · $n oyun';
    }
    if (n == 0) {
      return 'Bu süzgeçte oyun yok';
    }
    return label == null ? '$n oyun sahnede' : '$label · $n oyun';
  }

  Widget _shell(
    final BuildContext context,
    final _View v, {
    required final int columns,
    required final double gutter,
    required final double spine,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int total =
        v.categories.fold(0, (final n, final c) => n + c.count);

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BrowseHeading(
                      title: 'Keşfet',
                      lede: _statusLine(v),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Yakınımdakiler haritası',
                    child: IconButton(
                      tooltip: 'Haritada yakınımdakiler',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/nearby');
                      },
                      icon: Icon(Icons.map_outlined, color: cs.primary),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Ara',
                    child: IconButton(
                      tooltip: 'Ara',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        NavigationHandler.goToSearch(context);
                      },
                      icon: Icon(Icons.search_rounded, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DiscoveryModeSegment(
                showPast: _showPast,
                onChanged: (final past) => setState(() {
                  _showPast = past;
                  _when = BrowseWhen.any;
                  _showAllInactive = false;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              DiscoveryPulseBar(
                when: _when,
                whenCounts: v.whenCounts,
                showWhen: !_showPast,
                onWhen: (final w) => setState(() {
                  _when = w;
                  _showAllInactive = false;
                }),
                sortIndex: _sort.index,
                sortLabels: _sortLabels,
                onSort: (final i) => setState(() => _sort = _Sort.values[i]),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (v.categories.isNotEmpty)
                DiscoverySpine(
                  width: spine,
                  categories: v.categories,
                  selectedKey: v.categoryKey,
                  totalCount: total,
                  onPick: _pickCategory,
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (final child, final anim) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: RefreshIndicator(
                    key: ValueKey(
                        '${v.categoryKey}|$_when|$_sort|$_showPast'),
                    onRefresh: () async => _retry(),
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        ..._results(v, gutter, columns),
                        if (kIsWeb || context.isDesktop) ...[
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.section)),
                          const SliverToBoxAdapter(child: Footer()),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (context.isDesktop) {
      return Scaffold(backgroundColor: cs.surface, body: SafeArea(child: body));
    }

    return BasePageWrapper(
      showBackButton: false,
      customScrollController: _scroll,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: body,
    );
  }

  List<Widget> _results(final _View v, final double gutter, final int columns) {
    if (v.loading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: TiyatrolRiveLoader(
              size: 64,
              caption: 'Oyunlar perdesi açılıyor…',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter * 0.6, 0, gutter, 0),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: columns * 2,
            itemBuilder: (final _, final __) => const TicketCardSkeleton(),
          ),
        ),
      ];
    }
    if (v.failed) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter * 0.6, AppSpacing.xl, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: TicketNotice(
              label: 'KEŞFET',
              title: 'Oyunlar yüklenemedi',
              message: 'Bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              actionIcon: Icons.refresh_rounded,
              onAction: _retry,
            ),
          ),
        ),
      ];
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Show> inactive = _showAllInactive
        ? v.secondary
        : v.secondary.take(columns * 2).toList();

    return [
      if (v.primary.isEmpty)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter * 0.6, AppSpacing.xl, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: TicketNotice(
              label: 'KEŞFET',
              title: v.filtersActive
                  ? 'Bu süzgeçte oyun yok'
                  : 'Şu an sahnede oyun yok',
              message: v.filtersActive
                  ? 'Tür veya zaman süzgecini temizleyip yeniden dene.'
                  : 'Geçmiş oyunlara göz atabilirsin.',
              actionLabel:
                  v.filtersActive ? 'Süzgeçleri temizle' : 'Geçmiş oyunlar',
              onAction: v.filtersActive
                  ? _clearFilters
                  : () => setState(() => _showPast = true),
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              gutter * 0.55, 4, gutter, AppSpacing.xxxl),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: v.primary.length,
            itemBuilder: (final context, final i) => Reveal(
              index: i,
              child: HomePosterCard(
                key: ValueKey('disc-${v.primary[i].id}'),
                show: v.primary[i],
                heroFrom: 'discover',
                onTap: () => _openShow(v.primary[i], from: 'discover'),
              ),
            ),
          ),
        ),
      if (inactive.isNotEmpty) ...[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter * 0.55, 0, gutter, AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Şu an sahnede değil · ${v.secondary.length}',
              style: listingUi(
                color: cs.onSurfaceVariant,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter * 0.55, 0, gutter, 0),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(columns),
            itemCount: inactive.length,
            itemBuilder: (final context, final i) => Reveal(
              index: i,
              child: HomePosterCard(
                show: inactive[i],
                heroFrom: 'discover-idle',
                onTap: () => _openShow(inactive[i], from: 'discover-idle'),
              ),
            ),
          ),
        ),
        if (!_showAllInactive && v.secondary.length > inactive.length)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter * 0.55, 0, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _showAllInactive = true),
                  child: Text('Tümünü göster (${v.secondary.length})'),
                ),
              ),
            ),
          ),
      ],
    ];
  }

  SliverGridDelegate _grid(final int columns) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.56,
      );
}

class _View {
  final bool loading;
  final bool failed;
  final List<BrowseCategory> categories;
  final String? categoryKey;
  final List<Show> primary;
  final List<Show> secondary;
  final Map<BrowseWhen, int> whenCounts;
  final bool filtersActive;

  const _View({
    required this.loading,
    required this.failed,
    required this.categories,
    required this.categoryKey,
    required this.primary,
    required this.secondary,
    required this.whenCounts,
    required this.filtersActive,
  });

  String? get categoryLabel {
    if (categoryKey == null) {
      return null;
    }
    for (final c in categories) {
      if (c.key == categoryKey) {
        return c.label;
      }
    }
    return null;
  }
}

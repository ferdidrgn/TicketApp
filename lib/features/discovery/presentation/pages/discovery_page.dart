import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/theatre_show_card.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/recommended_shows_section.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/nearby_events_provider.dart';
import '../utils/category_stats.dart';
import '../widgets/browse_controls.dart';

/// KEŞFET — oyun repertuarında hızlı tarama.
///
/// Yapı: "kenar çubuğu + sütun".
/// - Masaüstü (≥1024): solda sabit kenar çubuğu (Sahnede/Geçmiş anahtarı +
///   kategori listesi), sağda kayan sonuç ızgarası + site alt bilgisi.
/// - Tablet (768–1023) ve mobil (<768): başlık, altında kaydırırken üstte
///   kalan filtre şeridi (anahtar + yatay kategori çipleri), sonra ızgara.
///
/// Veri mantığı değişmedi: `showsActiveFirstProvider(false)` (hiçbir oyun
/// gizlenmez, aktifler önce), Geçmiş modunda `pastShowsProvider(false)`,
/// gerçek aktif kümesi `activeShowsProvider(false)` (harici biletli oyunlar
/// da aktif sayılır), kategoriler gerçek `Show.category`'den
/// (`buildCategoryStats`). Oyunlar bilet koçanlı `TheatreShowCard` ile.
class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

enum _Layout { mobile, tablet, desktop }

/// Seçili moda ve kategoriye göre süzülmüş görünüm verisi.
class _Browse {
  final List<CategoryStat> categories;
  final String? category;

  /// Sahnede modunda: gerçekten aktif oyunlar; Geçmiş modunda: tüm liste.
  final List<Show> primary;

  /// Sahnede modunda: aktif OLMAYANLAR (gizlenmez, önizleme + "Tümünü gör").
  final List<Show> secondary;

  const _Browse({
    required this.categories,
    required this.category,
    required this.primary,
    required this.secondary,
  });

  factory _Browse.from({
    required final List<Show> shows,
    required final Set<String> activeIds,
    required final bool showPast,
    required final String? requestedCategory,
  }) {
    final List<CategoryStat> categories = buildCategoryStats(shows);
    final String? wanted = requestedCategory?.trim();
    // Seçili kategori bu modun verisinde yoksa (ör. arşivde o türde oyun
    // yok) "Tümü"ne düşülür; kullanıcının seçimi state'te korunur.
    final String? category = (wanted != null &&
            categories.any((final c) => c.category == wanted))
        ? wanted
        : null;
    final List<Show> filtered = category == null
        ? shows
        : shows.where((final s) => s.category.trim() == category).toList();
    if (showPast) {
      return _Browse(
        categories: categories,
        category: category,
        primary: filtered,
        secondary: const <Show>[],
      );
    }
    return _Browse(
      categories: categories,
      category: category,
      primary: filtered.where((final s) => activeIds.contains(s.id)).toList(),
      secondary:
          filtered.where((final s) => !activeIds.contains(s.id)).toList(),
    );
  }
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  String? _activeCategory;

  /// false: "Sahnede" (varsayılan), true: "Geçmiş" (arşiv).
  bool _showPast = false;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant final DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `/discover?category=...` ile aynı sayfaya yeni kategoriyle gelinirse.
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _activeCategory = widget.selectedCategory;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _setMode(final bool past) {
    if (past == _showPast) return;
    setState(() => _showPast = past);
  }

  void _setCategory(final String? category) =>
      setState(() => _activeCategory = category);

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  void _retry() {
    ref.invalidate(showsProvider);
    ref.invalidate(eventsByShowIdsProvider);
    ref.invalidate(showsActiveFirstProvider);
    ref.invalidate(pastShowsProvider);
    ref.invalidate(activeShowsProvider);
  }

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<List<Show>> showsState = _showPast
        ? ref.watch(pastShowsProvider(false))
        : ref.watch(showsActiveFirstProvider(false));
    final AsyncValue<List<Show>> activeState =
        ref.watch(activeShowsProvider(false));

    final bool loading = (showsState.isLoading && !showsState.hasValue) ||
        (!_showPast && activeState.isLoading && !activeState.hasValue);
    final bool failed = !loading &&
        ((showsState.hasError && !showsState.hasValue) ||
            (!_showPast && activeState.hasError && !activeState.hasValue));

    final _Browse? data = (loading || failed)
        ? null
        : _Browse.from(
            shows: showsState.value ?? const <Show>[],
            activeIds: (activeState.value ?? const <Show>[])
                .map((final s) => s.id)
                .toSet(),
            showPast: _showPast,
            requestedCategory: _activeCategory,
          );

    final _Layout layout = context.isDesktop
        ? _Layout.desktop
        : (context.isTablet ? _Layout.tablet : _Layout.mobile);

    if (layout == _Layout.desktop) {
      return _buildDesktop(context, data, loading);
    }
    return _buildCompact(context, data, loading, layout);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Başlık metni (gerçek sayılar)
  // ─────────────────────────────────────────────────────────────────────

  String get _title => _showPast ? 'Geçmiş oyunlar' : 'Keşfet';

  String? _lede(final _Browse? d) {
    if (d == null) return null;
    final String? cat = d.category;
    final int n = d.primary.length;
    if (_showPast) {
      if (n == 0) return null;
      return cat == null
          ? 'Perdesi kapanmış $n oyun. Hikâyesine ve kadrosuna bakmak için birine dokun.'
          : '“$cat” kategorisinde perdesi kapanmış $n oyun.';
    }
    if (n == 0) {
      return cat == null
          ? 'Şu an sahnede oyun yok.'
          : '“$cat” kategorisinde şu an sahnede oyun yok.';
    }
    return cat == null
        ? 'Şu an sahnede $n oyun var. Birine dokun, seansını seç.'
        : '“$cat” kategorisinde şu an sahnede $n oyun var.';
  }

  List<BrowseOption> _categoryOptions(final _Browse? d) => [
        const BrowseOption('Tümü'),
        if (d != null)
          for (final c in d.categories) BrowseOption(c.category),
      ];

  int _selectedCategoryIndex(final _Browse? d) {
    if (d == null || d.category == null) return 0;
    final int i = d.categories.indexWhere((final c) => c.category == d.category);
    return i < 0 ? 0 : i + 1;
  }

  void _onCategoryIndex(final _Browse? d, final int index) {
    if (index == 0 || d == null) {
      _setCategory(null);
    } else {
      _setCategory(d.categories[index - 1].category);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü: kenar çubuğu + kayan sonuçlar
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDesktop(
      final BuildContext context, final _Browse? d, final bool loading) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // BasePageWrapper kullanılmıyor → Material atası için kendi Scaffold'u.
    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: _DesktopSidebar(
              showPast: _showPast,
              onModeChanged: _setMode,
              loading: loading,
              options: _categoryOptions(d),
              selectedIndex: _selectedCategoryIndex(d),
              onCategory: (final i) => _onCategoryIndex(d, i),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
          Expanded(
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                // Içerik ~1240px'te sınırlanır, kenarlar nefes alır; kaydırma
                // çubuğu yine gerçek sağ kenarda kalır.
                final double gutter = math.max(
                    AppSpacing.huge, (constraints.maxWidth - 1240) / 2);
                return CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.massive,
                          gutter, AppSpacing.xxxl),
                      sliver: SliverToBoxAdapter(
                        child: BrowseHeading(title: _title, lede: _lede(d)),
                      ),
                    ),
                    ..._contentSlivers(d, loading, _Layout.desktop, gutter),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.section)),
                    const SliverToBoxAdapter(child: Footer()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet: başlık + yapışkan filtre şeridi + ızgara
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCompact(final BuildContext context, final _Browse? d,
      final bool loading, final _Layout layout) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double gutter =
        layout == _Layout.tablet ? AppSpacing.xxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scroll,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        // Sade zemin: ortam ışığı / parçacık süsü yok.
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                gutter, AppSpacing.xl, gutter, AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: BrowseHeading(title: _title, lede: _lede(d)),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedBrowseHeader(
              extent: 116,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: SizedBox(
                      width: layout == _Layout.tablet ? 320 : double.infinity,
                      child: ShowsModeToggle(
                          showPast: _showPast, onChanged: _setMode),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrowseChoiceChips(
                    options: _categoryOptions(d),
                    selectedIndex: _selectedCategoryIndex(d),
                    onSelected: (final i) => _onCategoryIndex(d, i),
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ..._contentSlivers(d, loading, layout, gutter),
          if (kIsWeb) ...[
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
            const SliverToBoxAdapter(child: Footer()),
          ],
          // Alt navigasyon çubuğunun altında içerik kalmasın.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Ortak içerik
  // ─────────────────────────────────────────────────────────────────────

  Widget _boxed(final double gutter, final Widget child,
          {final double bottom = AppSpacing.section}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
        sliver: SliverToBoxAdapter(child: child),
      );

  Widget _notice(final double gutter, final TicketNotice notice) => _boxed(
        gutter,
        Align(alignment: Alignment.centerLeft, child: notice),
      );

  List<Widget> _contentSlivers(final _Browse? d, final bool loading,
      final _Layout layout, final double gutter) {
    final double cardMax = switch (layout) {
      _Layout.mobile => 200.0,
      _Layout.tablet => 220.0,
      _Layout.desktop => 240.0,
    };

    if (loading) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverGrid.builder(
            gridDelegate: browseShowGridDelegate(cardMax),
            itemCount: layout == _Layout.desktop ? 8 : 6,
            itemBuilder: (final _, final __) => const TicketCardSkeleton(),
          ),
        ),
      ];
    }

    if (d == null) {
      return [
        _notice(
          gutter,
          TicketNotice(
            label: 'BAĞLANTI',
            title: 'Oyunlar yüklenemedi',
            message:
                'Oyun listesine ulaşamadık. İnternet bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            actionIcon: Icons.refresh_rounded,
            onAction: _retry,
          ),
        ),
      ];
    }

    final List<Widget> slivers = [];

    // SANA ÖZEL — gerçek favori/bilet geçmişinden; sinyal yoksa kendini
    // gizler. Sadece filtresiz "Sahnede" görünümünde.
    if (!_showPast && d.category == null) {
      slivers.add(const SliverToBoxAdapter(child: RecommendedShowsSection()));
    }

    if (d.primary.isEmpty && d.secondary.isEmpty) {
      slivers.add(_notice(gutter, _emptyNotice(d)));
    } else {
      if (d.primary.isNotEmpty) {
        if (!_showPast) {
          slivers.add(_boxed(
            gutter,
            BrowseSectionTitle(title: 'Sahnede', count: d.primary.length),
            bottom: 0,
          ));
        }
        slivers.add(_showGrid(d.primary, cardMax, gutter));
      }
      if (!_showPast && d.secondary.isNotEmpty) {
        // Aktif olmayan oyunlar gizlenmez: bir sıralık önizleme + tamamı
        // "Geçmiş" görünümünde (aynı liste — `pastShowsProvider`).
        slivers.add(_boxed(
          gutter,
          BrowseSectionTitle(
            title: 'Geçmiş oyunlar',
            count: d.secondary.length,
            actionLabel: 'Tümünü gör',
            onAction: () => _setMode(true),
          ),
          bottom: 0,
        ));
        slivers.add(_showGrid(d.secondary, cardMax, gutter, oneRow: true));
      }
    }

    if (!_showPast) {
      slivers.add(_boxed(
        gutter,
        _UpcomingSessions(category: d.category, onOpenShow: _openShow),
        bottom: 0,
      ));
    }

    slivers.add(_boxed(gutter, _StagesBlock(rail: layout == _Layout.mobile),
        bottom: 0));
    slivers.add(
        _boxed(gutter, _TeamsBlock(rail: layout == _Layout.mobile), bottom: 0));

    return slivers;
  }

  TicketNotice _emptyNotice(final _Browse d) {
    if (d.category != null) {
      return TicketNotice(
        label: 'KATEGORİ',
        title: '“${d.category}” için oyun yok',
        message: _showPast
            ? 'Bu kategoride geçmiş oyun bulunmuyor. Tüm kategorilere dönebilirsin.'
            : 'Bu kategoride henüz oyun bulunmuyor. Tüm kategorilere dönebilirsin.',
        actionLabel: 'Tüm kategoriler',
        onAction: () => _setCategory(null),
      );
    }
    if (_showPast) {
      return TicketNotice(
        label: 'ARŞİV',
        title: 'Arşiv henüz boş',
        message: 'Perdesi kapanan oyunlar burada listelenecek.',
        actionLabel: 'Sahnedekilere dön',
        onAction: () => _setMode(false),
      );
    }
    return const TicketNotice(
      label: 'REPERTUAR',
      title: 'Henüz oyun yok',
      message: 'Oyunlar eklendiğinde burada listelenecek.',
    );
  }

  Widget _showGrid(final List<Show> shows, final double cardMax,
          final double gutter,
          {final bool oneRow = false}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
            gutter, 0, gutter, AppSpacing.section - AppSpacing.lg),
        sliver: SliverLayoutBuilder(
          builder: (final context, final constraints) {
            int count = shows.length;
            if (oneRow) {
              // SliverGridDelegateWithMaxCrossAxisExtent ile aynı hesap.
              final int columns = (constraints.crossAxisExtent /
                      (cardMax + AppSpacing.lg))
                  .ceil();
              count = math.min(math.max(columns, 1), count);
            }
            return SliverGrid.builder(
              gridDelegate: browseShowGridDelegate(cardMax),
              itemCount: count,
              itemBuilder: (final context, final i) => TheatreShowCard(
                key: ValueKey('discover-${shows[i].id}'),
                show: shows[i],
                onTap: () => _openShow(shows[i]),
              ),
            );
          },
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Masaüstü kenar çubuğu
// ─────────────────────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final bool showPast;
  final ValueChanged<bool> onModeChanged;
  final bool loading;
  final List<BrowseOption> options;
  final int selectedIndex;
  final ValueChanged<int> onCategory;

  const _DesktopSidebar({
    required this.showPast,
    required this.onModeChanged,
    required this.loading,
    required this.options,
    required this.selectedIndex,
    required this.onCategory,
  });

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.massive,
            AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrowseSideLabel('Görünüm'),
            ShowsModeToggle(showPast: showPast, onChanged: onModeChanged),
            const SizedBox(height: AppSpacing.xxxl),
            const BrowseSideLabel('Kategori'),
            if (loading)
              for (int i = 0; i < 5; i++)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: ShimmerLoading(
                      width: double.infinity, height: 20, borderRadius: 6),
                )
            else
              for (int i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: BrowseSideOption(
                    label: options[i].label,
                    selected: i == selectedIndex,
                    onTap: () => onCategory(i),
                  ),
                ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Yaklaşan seanslar — seans = koçan
// ─────────────────────────────────────────────────────────────────────────

/// `upcomingNearbyEventsProvider` (konum istemeyen, gerçek yaklaşan
/// etkinlikler) — en yakın 6 seans, seçili kategoriye göre süzülür. Veri
/// yoksa ya da hata olursa sessizce gizlenir (ana içerik değil).
class _UpcomingSessions extends ConsumerWidget {
  final String? category;
  final ValueChanged<Show> onOpenShow;

  const _UpcomingSessions({required this.category, required this.onOpenShow});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<List<NearbyEventEntry>> state =
        ref.watch(upcomingNearbyEventsProvider);
    final List<NearbyEventEntry>? entries = state.value;

    if (entries == null) {
      if (!state.isLoading) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.section),
        child: Column(
          children: [
            TicketRowSkeleton(height: 88),
            SizedBox(height: AppSpacing.md),
            TicketRowSkeleton(height: 88),
          ],
        ),
      );
    }

    final List<NearbyEventEntry> visible = (category == null
            ? entries
            : entries.where((final e) => e.show.category.trim() == category))
        .take(6)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrowseSectionTitle(
            title: 'Yaklaşan seanslar',
            actionLabel: 'Yakınımdakiler',
            onAction: () => NavigationHandler.goToNearby(context),
          ),
          BrowseColumns(
            minItemWidth: 380,
            children: [
              for (final e in visible)
                SessionTicketRow(
                  key: ValueKey('discover-session-${e.event.id}'),
                  title: e.show.name,
                  dateTime: e.dateTime,
                  price: ticketPrice(e.event.price),
                  extraLabel: 'SAHNE',
                  extraValue: e.stage.name,
                  onTap: () => onOpenShow(e.show),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sahneler / Topluluklar — yerler ve kişiler (bilet değil, sade satırlar)
// ─────────────────────────────────────────────────────────────────────────

class _StagesBlock extends ConsumerWidget {
  final bool rail;
  const _StagesBlock({required this.rail});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Stage> stages =
        ref.watch(stagesProvider(isLimit: false)).value ?? const <Stage>[];
    if (stages.isEmpty) return const SizedBox.shrink();
    final List<Widget> tiles = [
      for (final stage in stages)
        BrowseListTile(
          key: ValueKey('discover-stage-${stage.id}'),
          imageUrl: stage.imageUrl,
          title: stage.name,
          subtitle: stage.address,
          fallbackIcon: Icons.location_city_rounded,
          onTap: () =>
              NavigationHandler.goToStage(context, stage.id, stage.name),
        ),
    ];
    return _PlacesSection(
        title: 'Sahneler', count: stages.length, rail: rail, tiles: tiles);
  }
}

class _TeamsBlock extends ConsumerWidget {
  final bool rail;
  const _TeamsBlock({required this.rail});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Team> teams =
        ref.watch(teamsProvider(isLimit: false)).value ?? const <Team>[];
    if (teams.isEmpty) return const SizedBox.shrink();
    final List<Widget> tiles = [
      for (final team in teams)
        BrowseListTile(
          key: ValueKey('discover-team-${team.id}'),
          imageUrl: team.imageUrl,
          title: team.name,
          subtitle:
              team.showsId.isEmpty ? null : '${team.showsId.length} oyun',
          fallbackIcon: Icons.groups_rounded,
          onTap: () => NavigationHandler.goToTeam(context, team.id, team.name),
        ),
    ];
    return _PlacesSection(
        title: 'Topluluklar', count: teams.length, rail: rail, tiles: tiles);
  }
}

class _PlacesSection extends StatelessWidget {
  final String title;
  final int count;
  final bool rail;
  final List<Widget> tiles;

  const _PlacesSection({
    required this.title,
    required this.count,
    required this.rail,
    required this.tiles,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrowseSectionTitle(title: title, count: count),
            if (rail)
              BrowseRail(height: 72, itemWidth: 280, children: tiles)
            else
              BrowseColumns(minItemWidth: 320, children: tiles),
          ],
        ),
      );
}

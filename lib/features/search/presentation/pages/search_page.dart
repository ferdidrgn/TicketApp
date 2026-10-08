import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/stagecraft.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../shared/widgets/ticket/ticket_search.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../home/presentation/widgets/common/home_showcase.dart';
import '../../../players/domain/entities/player.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';
import '../widgets/search_place_cards.dart';

// =============================================================================
// ARAMA
// =============================================================================
//
// Mantık değişmedi: `searchQueryProvider` (serbest metin), `searchFilterProvider`
// (0 Tümü, 1 Oyunlar, 2 Oyuncular, 3 Mekanlar, 4 Ekipler) ve
// `searchResultProvider` (boş sorguda aktif-önce/en yeni oyunlar, yazınca
// TÜM oyunlar içinde arama).
//
// - Mobil (<768): üstte kalan arama kutusu + tür çipleri; oyunlar afiş
//   ızgarası, kişiler hap portre, mekanlar sahne fotoğrafı, ekipler topluluk.
// - Tablet (768–1023): aynı üst şerit; oyunlar bilet koçanlı kart ızgarası.
// - Masaüstü (≥1024): solda sabit kenar çubuğu (arama kutusu + türler),
//   sağda kayan sonuç ızgarası + site alt bilgisi.
//
// Yazarken sonuçlar titremesin diye önceki sonuç ekranda kalır; yeni sonuç
// gelene kadar üstte ince bir ilerleme çizgisi görünür. İlk yüklemede
// sonuçların şeklinde iskelet gösterilir.

const List<String> _kFacets = [
  'Tümü',
  'Oyunlar',
  'Oyuncular',
  'Mekanlar',
  'Ekipler',
];

const List<IconData> _kFacetIcons = [
  Icons.apps_rounded,
  Icons.theater_comedy_rounded,
  Icons.person_rounded,
  Icons.location_city_rounded,
  Icons.groups_rounded,
];

enum _Layout { mobile, tablet, desktop }

const String _kRecentSearches = 'tiyatrol.recent_searches';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with ResponsiveUtils, GlobalScrollMixin, SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _fieldFocused = false;
  String? _showCategory;
  List<String> _recents = const [];
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.8, curve: AppMotion.dramatic));
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _textController.text = ref.read(searchQueryProvider);
    _loadRecents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    // Flutter 3.47 analyzer misses ValueNotifier.dispose on this type.
    // ignore: undefined_method
    _textController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() => debugPrint("Daha fazla arama sonucu yükleniyor...");

  void _onSeeAll(final int filterIndex) =>
      ref.read(searchFilterProvider.notifier).setFilter(filterIndex);

  void _onQueryChanged(final String value) =>
      ref.read(searchQueryProvider.notifier).update(value);

  void _clearQuery() {
    _textController.clear();
    ref.read(searchQueryProvider.notifier).update("");
  }

  Future<void> _loadRecents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(
        () => _recents = prefs.getStringList(_kRecentSearches) ?? const []);
  }

  Future<void> _rememberQuery(final String raw) async {
    final String clean = raw.trim();
    if (clean.length < 2) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> next = [
      clean,
      ...?prefs
          .getStringList(_kRecentSearches)
          ?.where((final item) => item.toLowerCase() != clean.toLowerCase()),
    ].take(6).toList();
    await prefs.setStringList(_kRecentSearches, next);
    if (mounted) {
      setState(() => _recents = next);
    }
  }

  void _applyRecent(final String value) {
    HapticFeedback.selectionClick();
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _onQueryChanged(value);
  }

  Future<void> _submitQuery(final String value) async {
    FocusScope.of(context).unfocus();
    await _rememberQuery(value);
  }

  /// Boş sonuçta "Tümünde ara": sorgu korunur, tür filtresi kalkar.
  void _searchEverywhere() =>
      ref.read(searchFilterProvider.notifier).setFilter(0);

  void _pickShowCategory(final String? key) {
    HapticFeedback.selectionClick();
    final String? next = (key == _showCategory) ? null : key;
    setState(() => _showCategory = next);
    final int filter = ref.read(searchFilterProvider);
    if (next != null && filter != 0 && filter != 1) {
      ref.read(searchFilterProvider.notifier).setFilter(1);
    }
  }

  String? _activeCategory(final List<BrowseCategory> categories) {
    final String? key = _showCategory;
    if (key == null) {
      return null;
    }
    for (final BrowseCategory category in categories) {
      if (category.key == key) {
        return key;
      }
    }
    return null;
  }

  List<Show> _showsInCategory(final List<Show> shows, final String? category) {
    if (category == null) {
      return shows;
    }
    return [
      for (final Show show in shows)
        if (browseCategoryKey(show.category) == category) show,
    ];
  }

  Widget _desktopCategories(final List<Show> shows) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<BrowseCategory> categories = browseCategoriesOf(shows);
    final String? active = _activeCategory(categories);
    final List<Color> tones = [
      cs.primaryContainer,
      cs.tertiaryContainer,
      cs.secondaryContainer,
    ];
    final List<Color> inks = [
      cs.onPrimaryContainer,
      cs.onTertiaryContainer,
      cs.onSecondaryContainer,
    ];
    return Column(
      children: [
        BrowseSideOption(
          label: 'Tümü',
          icon: Icons.apps_rounded,
          selected: active == null,
          onTap: () => _pickShowCategory(null),
        ),
        for (int i = 0; i < categories.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: BrowseSideOption(
              label: categories[i].label,
              count: categories[i].count,
              selected: active == categories[i].key,
              tone: tones[i % 3],
              toneInk: inks[i % 3],
              onTap: () => _pickShowCategory(categories[i].key),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    final int filter = ref.watch(searchFilterProvider);
    final String query = ref.watch(searchQueryProvider);
    final AsyncValue<SearchResultState> state = ref.watch(searchResultProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    final _Layout layout = context.isDesktop
        ? _Layout.desktop
        : (context.isTablet ? _Layout.tablet : _Layout.mobile);

    // Önceki sonuç varken yenileniyorsa (yazarken) içerik ekranda kalır.
    final bool refreshing = state.isLoading && state.hasValue;

    return BasePageWrapper(
      // Geri butonu sayfanın kendi başlığında (tema renkli, sade).
      showBackButton: false,
      showFab: true,
      customScrollController: scrollController,
      onRefresh: () => ref.invalidate(searchResultProvider),
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
      ),
      child: layout == _Layout.desktop
          ? _buildDesktop(context, state, filter, query, refreshing)
          : layout == _Layout.mobile
              ? _buildMobile(context, state, filter, query, refreshing)
              : _buildCompact(
                  context, state, filter, query, refreshing, layout),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Arama kutusu
  // ─────────────────────────────────────────────────────────────────────

  /// Onaylı ışıyan kenar + daktilo ipucu (gerçek oyun adları).
  Widget _searchField(final BuildContext context,
      {final bool autofocus = true}) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Focus(
      onFocusChange: (final v) => setState(() => _fieldFocused = v),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _textController,
        builder: (final context, final value, final _) => TicketSearchShell(
          focused: _fieldFocused,
          trailing: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Aramayı temizle',
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: _clearQuery,
                ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (value.text.isEmpty)
                const IgnorePointer(child: RotatingSearchHint()),
              Semantics(
                label: 'Oyun, oyuncu, sahne ya da ekip ara',
                textField: true,
                child: TextField(
                  controller: _textController,
                  autofocus: autofocus,
                  onChanged: _onQueryChanged,
                  onSubmitted: _submitQuery,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: cs.primary,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(final BuildContext context) => IconButton(
        tooltip: 'Geri',
        onPressed: () => NavigationHandler.smartGoBack(context),
        icon: Icon(Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface),
      );

  Widget _progressLine(final bool refreshing) => SizedBox(
        height: 2,
        child: refreshing
            ? const LinearProgressIndicator(minHeight: 2)
            : const SizedBox.shrink(),
      );

  Widget _mobileSearchField(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Focus(
      onFocusChange: (final v) => setState(() => _fieldFocused = v),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _textController,
        builder: (final context, final value, final _) {
          return AnimatedContainer(
            duration: AppMotion.fast,
            height: 52,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _fieldFocused
                  ? colors.surfaceContainerLowest
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _fieldFocused ? colors.primary : colors.outlineVariant,
                width: _fieldFocused ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color:
                      _fieldFocused ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      if (value.text.isEmpty)
                        IgnorePointer(
                          child: Text(
                            'Oyun, oyuncu, sahne veya ekip',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Semantics(
                        label: 'Oyun, oyuncu, sahne ya da ekip ara',
                        textField: true,
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          onChanged: _onQueryChanged,
                          onSubmitted: _submitQuery,
                          textInputAction: TextInputAction.search,
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: colors.primary,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (value.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: _clearQuery,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobile(
      final BuildContext context,
      final AsyncValue<SearchResultState> state,
      final int filter,
      final String query,
      final bool refreshing) {
    const double gutter = AppSpacing.xl;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: CustomScrollView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedBrowseHeader(
              extent: 148,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        gutter,
                        0,
                      ),
                      child: Row(
                        children: [
                          _backButton(context),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _mobileSearchField(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScopeRail(
                      labels: _kFacets,
                      selectedIndex: filter,
                      onSelected: _onSeeAll,
                      padding: const EdgeInsets.symmetric(horizontal: gutter),
                    ),
                    _progressLine(refreshing),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.xxl,
                gutter,
                query.trim().isEmpty ? AppSpacing.xl : AppSpacing.lg,
              ),
              child: _MobileSearchIntro(
                key: ValueKey('$filter-${query.trim()}'),
                query: query,
                filter: filter,
                total: state.value?.total,
                reveal: _headline,
              ),
            ),
          ),
          if (query.trim().isEmpty && _recents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  gutter,
                  0,
                  gutter,
                  AppSpacing.xxl,
                ),
                child: _RecentSearches(
                  recents: _recents,
                  onPick: _applyRecent,
                ),
              ),
            ),
          ..._resultSlivers(state, filter, query, _Layout.mobile, gutter),
          if (kIsWeb) ...[
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
            const SliverToBoxAdapter(child: Footer()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCompact(
      final BuildContext context,
      final AsyncValue<SearchResultState> state,
      final int filter,
      final String query,
      final bool refreshing,
      final _Layout layout) {
    final double gutter =
        layout == _Layout.tablet ? AppSpacing.xxl : AppSpacing.lg;

    return AnimationLimiter(
      child: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedBrowseHeader(
              extent: 174,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          gutter - AppSpacing.sm, AppSpacing.sm, gutter, 0),
                      child: Row(
                        children: [
                          _backButton(context),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _searchField(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScopeRail(
                      labels: _kFacets,
                      selectedIndex: filter,
                      onSelected: _onSeeAll,
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _progressLine(refreshing),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xxl, gutter,
                  query.trim().isEmpty ? AppSpacing.xxl : AppSpacing.lg),
              child: PageTransitionSwitcher(
                duration: AppMotion.normal,
                reverse: false,
                transitionBuilder:
                    (final child, final animation, final secondaryAnimation) =>
                        FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Theme.of(context).colorScheme.surface,
                  child: child,
                ),
                child: _MobileSearchIntro(
                  key: ValueKey('$filter-${query.trim()}'),
                  query: query,
                  filter: filter,
                  total: state.value?.total,
                  reveal: _headline,
                ),
              ),
            ),
          ),
          ..._resultSlivers(state, filter, query, layout, gutter),
          if (kIsWeb) ...[
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
            const SliverToBoxAdapter(child: Footer()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü: kenar çubuğu + kayan sonuçlar
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDesktop(
      final BuildContext context,
      final AsyncValue<SearchResultState> state,
      final int filter,
      final String query,
      final bool refreshing) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _backButton(context),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Ara',
                      style: GoogleFonts.playfairDisplay(
                        color: cs.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _searchField(context),
                const SizedBox(height: AppSpacing.xxl),
                const BrowseSideLabel('Ne arıyorsun?'),
                for (int i = 0; i < _kFacets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: BrowseSideOption(
                      label: _kFacets[i],
                      icon: _kFacetIcons[i],
                      selected: i == filter,
                      onTap: () => _onSeeAll(i),
                    ),
                  ),
                if (browseCategoriesOf(state.value?.shows ?? const <Show>[])
                        .length >=
                    2) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const BrowseSideLabel('Türler'),
                  _desktopCategories(state.value?.shows ?? const <Show>[]),
                ],
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
        Expanded(
          child: Column(
            children: [
              _progressLine(refreshing),
              Expanded(
                child: LayoutBuilder(
                  builder: (final context, final constraints) {
                    final double gutter = math.max(
                        AppSpacing.huge, (constraints.maxWidth - 1240) / 2);
                    return CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                              gutter,
                              AppSpacing.xxl + AppSpacing.sm,
                              gutter,
                              AppSpacing.xl),
                          sliver: SliverToBoxAdapter(
                            child: _ResultsHeadline(
                              query: query,
                              filter: filter,
                              total: state.value?.total,
                            ),
                          ),
                        ),
                        ..._resultSlivers(
                            state, filter, query, _Layout.desktop, gutter),
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
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Sonuçlar (ortak)
  // ─────────────────────────────────────────────────────────────────────

  Widget _boxed(final double gutter, final Widget child,
          {final double bottom = 0}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
        sliver: SliverToBoxAdapter(child: child),
      );

  Widget _noticeSliver(final double gutter, final _SearchNotice notice) =>
      _boxed(gutter, Align(alignment: Alignment.centerLeft, child: notice));

  List<Widget> _resultSlivers(
      final AsyncValue<SearchResultState> state,
      final int filter,
      final String query,
      final _Layout layout,
      final double gutter) {
    final SearchResultState? data = state.value;

    if (data == null) {
      if (state.hasError) {
        return [
          _noticeSliver(
            gutter,
            _SearchNotice(
              icon: Icons.wifi_off_rounded,
              title: 'Arama yapılamadı',
              message:
                  'Sonuçlara ulaşamadık. İnternet bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              actionIcon: Icons.refresh_rounded,
              onAction: () => ref.invalidate(searchResultProvider),
            ),
          ),
        ];
      }
      return [_skeletonSliver(layout, gutter, filter)];
    }

    if (data.total == 0) {
      if (query.isNotEmpty) {
        final bool narrowed = filter != 0;
        return [
          _noticeSliver(
            gutter,
            _SearchNotice(
              icon: Icons.search_off_rounded,
              title: '“$query” bulunamadı',
              message: narrowed
                  ? '${_kFacets[filter]} içinde eşleşen sonuç yok. Tüm türlerde aramayı dene.'
                  : 'Yazımı kontrol et ya da daha kısa bir kelimeyle dene.',
              actionLabel: narrowed ? 'Tümünde ara' : 'Aramayı temizle',
              onAction: narrowed ? _searchEverywhere : _clearQuery,
            ),
          ),
        ];
      }
      return [
        _noticeSliver(
          gutter,
          _SearchNotice(
            icon: Icons.theater_comedy_outlined,
            title: 'Henüz içerik yok',
            message:
                'Oyunlar, oyuncular ve sahneler eklendikçe burada listelenecek.',
            actionLabel: "Keşfet'e git",
            onAction: () => NavigationHandler.goToDiscover(context),
          ),
        ),
      ];
    }

    final List<BrowseCategory> categories = browseCategoriesOf(data.shows);
    final String? category = _activeCategory(categories);
    final List<Show> shows = _showsInCategory(data.shows, category);
    final bool showStrip = layout != _Layout.desktop && categories.length >= 2;

    switch (filter) {
      case 1:
        return [
          if (showStrip) _categoryStrip(categories, data.shows, gutter),
          if (category != null && shows.isEmpty)
            _categoryEmpty(gutter, categories, category)
          else
            _showsSliver(shows, layout, gutter),
        ];
      case 2:
        return [_playersGridSliver(data.players, gutter)];
      case 3:
        return [_stagesSliver(data.stages, layout, gutter)];
      case 4:
        return [_teamsSliver(data.teams, layout, gutter)];
    }

    final int showPreview = 8;
    final int tilePreview = layout == _Layout.mobile ? 4 : 6;
    final bool browsing = query.isEmpty;
    return [
      if (browsing && layout != _Layout.mobile && data.shows.isNotEmpty) ...[
        _boxed(gutter,
            const BrowseSectionTitle(title: 'Bugün ne izlemek istersin?')),
        SliverToBoxAdapter(
          child: HomeMoodPicker(
              shows: data.shows,
              padding: EdgeInsets.symmetric(horizontal: gutter)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
      if (showStrip) ...[
        _boxed(gutter, const BrowseSectionTitle(title: 'Türler')),
        _categoryStrip(categories, data.shows, gutter),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
      if (data.shows.isNotEmpty) ...[
        _boxed(
          gutter,
          BrowseSectionTitle(
            title: category == null
                ? 'Oyunlar'
                : _categoryLabel(categories, category),
            count: shows.length,
            onAction: category == null && data.shows.length > showPreview
                ? () => _onSeeAll(1)
                : null,
          ),
        ),
        if (category != null && shows.isEmpty)
          _categoryEmpty(gutter, categories, category)
        else
          _showsSliver(
              category == null ? shows.take(showPreview).toList() : shows,
              layout,
              gutter),
      ],
      if (data.players.isNotEmpty) ...[
        _boxed(
          gutter,
          BrowseSectionTitle(
            title: 'Oyuncular',
            count: data.players.length,
            onAction: data.players.length > 12 ? () => _onSeeAll(2) : null,
          ),
        ),
        _boxed(
          gutter,
          BrowseRail(
            height: _PlayerAvatar.railHeight,
            itemWidth: _PlayerAvatar.cellWidth,
            children: [
              for (final p in data.players.take(12)) _PlayerAvatar(player: p),
            ],
          ),
          bottom: AppSpacing.section - AppSpacing.lg,
        ),
      ],
      if (data.stages.isNotEmpty) ...[
        _boxed(
          gutter,
          BrowseSectionTitle(
            title: 'Mekanlar',
            count: data.stages.length,
            onAction:
                data.stages.length > tilePreview ? () => _onSeeAll(3) : null,
          ),
        ),
        _stagesSliver(data.stages.take(tilePreview).toList(), layout, gutter),
      ],
      if (data.teams.isNotEmpty) ...[
        _boxed(
          gutter,
          BrowseSectionTitle(
            title: 'Ekipler',
            count: data.teams.length,
            onAction:
                data.teams.length > tilePreview ? () => _onSeeAll(4) : null,
          ),
        ),
        _teamsSliver(data.teams.take(tilePreview).toList(), layout, gutter),
      ],
    ];
  }

  void _openShow(final Show show, {final String from = 'search'}) =>
      NavigationHandler.goToShow(
        context,
        show.id,
        show.name,
        heroTag: TiyatrolHeroTags.show(show.id, from),
        imageUrl: show.imageUrl,
        title: show.name,
      );

  Widget _showsSliver(
      final List<Show> shows, final _Layout layout, final double gutter) {
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
            gutter, 0, gutter, AppSpacing.section - AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: shows.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (final context, final i) => _MobileShowResult(
            show: shows[i],
            onTap: () => _openShow(shows[i], from: 'search-mobile'),
          ),
        ),
      );
    }
    final int columns = layout == _Layout.tablet ? 3 : 5;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
          gutter, 0, gutter, AppSpacing.section - AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.xl,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.56,
        ),
        itemCount: shows.length,
        itemBuilder: (final context, final i) =>
            AnimationConfiguration.staggeredGrid(
          position: i,
          duration: const Duration(milliseconds: 420),
          columnCount: columns,
          child: SlideAnimation(
            verticalOffset: 36,
            child: FadeInAnimation(
              child: HomePosterCard(
                key: ValueKey('search-show-${shows[i].id}'),
                show: shows[i],
                heroFrom: 'search',
                onTap: () => _openShow(shows[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryStrip(final List<BrowseCategory> categories,
          final List<Show> shows, final double gutter) =>
      SliverToBoxAdapter(
        child: BrowseCategoryStrip(
          categories: categories,
          selectedKey: _activeCategory(categories),
          total: shows.where((final s) => s.category.trim().isNotEmpty).length,
          onPick: _pickShowCategory,
          padding: EdgeInsets.symmetric(horizontal: gutter),
        ),
      );

  String _categoryLabel(
      final List<BrowseCategory> categories, final String key) {
    for (final BrowseCategory category in categories) {
      if (category.key == key) {
        return category.label;
      }
    }
    return 'Oyunlar';
  }

  Widget _categoryEmpty(final double gutter,
          final List<BrowseCategory> categories, final String? category) =>
      _noticeSliver(
        gutter,
        _SearchNotice(
          icon: Icons.category_outlined,
          title: category == null
              ? 'Bu türde oyun yok'
              : '“${_categoryLabel(categories, category)}” türünde oyun yok',
          message: 'Başka bir tür seç ya da tümüne bak.',
          actionLabel: 'Tüm türler',
          onAction: () => _pickShowCategory(null),
        ),
      );

  Widget _playersGridSliver(final List<Player> players, final double gutter) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
            gutter, 0, gutter, AppSpacing.section - AppSpacing.lg),
        sliver: SliverGrid.builder(
          // İlk tasarımla aynı: telefonda 3, tablette 5, masaüstünde 6 sütun.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                context.responsive(mobile: 3, tablet: 5, desktop: 6),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: _PlayerAvatar.gridAspect,
          ),
          itemCount: players.length,
          itemBuilder: (final context, final i) =>
              _PlayerAvatar(player: players[i]),
        ),
      );

  Widget _stagesSliver(
      final List<Stage> stages, final _Layout layout, final double gutter) {
    final List<Widget> tiles = [
      for (final Stage stage in stages)
        SearchStageCard(
          key: ValueKey('search-stage-${stage.id}'),
          stage: stage,
          onTap: () =>
              NavigationHandler.goToStage(context, stage.id, stage.name),
        ),
    ];
    final EdgeInsets padding = EdgeInsets.fromLTRB(
        gutter, 0, gutter, AppSpacing.section - AppSpacing.lg);
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: tiles.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.lg),
          itemBuilder: (final context, final i) => tiles[i],
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: layout == _Layout.desktop ? 420 : 480,
          mainAxisExtent: 220,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
        ),
        delegate: SliverChildListDelegate(tiles),
      ),
    );
  }

  Widget _teamsSliver(
      final List<Team> teams, final _Layout layout, final double gutter) {
    final List<Widget> tiles = [
      for (final Team team in teams)
        SearchTeamCard(
          key: ValueKey('search-team-${team.id}'),
          team: team,
          onTap: () => NavigationHandler.goToTeam(context, team.id, team.name),
        ),
    ];
    final EdgeInsets padding = EdgeInsets.fromLTRB(
        gutter, 0, gutter, AppSpacing.section - AppSpacing.lg);
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: tiles.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (final context, final i) => tiles[i],
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: browseRowGridDelegate(maxRowWidth: 480, rowHeight: 116),
        delegate: SliverChildListDelegate(tiles),
      ),
    );
  }

  /// İlk yükleme: seçili türün sonuç şeklinde iskelet.
  Widget _skeletonSliver(
      final _Layout layout, final double gutter, final int filter) {
    final EdgeInsets padding = EdgeInsets.symmetric(horizontal: gutter);
    final bool showsShape = filter == 0 || filter == 1;
    if (showsShape && layout != _Layout.mobile) {
      return SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          gridDelegate:
              browseShowGridDelegate(layout == _Layout.tablet ? 220 : 240),
          itemCount: 8,
          itemBuilder: (final _, final __) => const TicketCardSkeleton(),
        ),
      );
    }
    if (showsShape) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: 5,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (final context, final __) =>
              const _SearchRowSkeleton(height: 124),
        ),
      );
    }
    final double rowHeight = switch (filter) {
      3 => 200,
      4 => 112,
      _ => 72,
    };
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (final _, final __) =>
            SizedBox(height: filter == 3 ? AppSpacing.lg : AppSpacing.sm),
        itemBuilder: (final _, final __) =>
            _SearchRowSkeleton(height: rowHeight),
      ),
    );
  }
}

class _ScopeRail extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsets padding;

  const _ScopeRail({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.xxl),
        itemBuilder: (final context, final index) {
          final bool selected = selectedIndex == index;
          return Semantics(
            button: true,
            selected: selected,
            label: '${labels[index]} kapsamında ara',
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(index);
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      width: selected ? 24 : 0,
                      height: 2,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<String> recents;
  final ValueChanged<String> onPick;

  const _RecentSearches({required this.recents, required this.onPick});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son aramalar',
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final String recent in recents)
              Semantics(
                button: true,
                label: '$recent aramasını tekrarla',
                excludeSemantics: true,
                child: ActionChip(
                  onPressed: () => onPick(recent),
                  avatar: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  label: Text(recent),
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchRowSkeleton extends StatelessWidget {
  final double height;

  const _SearchRowSkeleton({this.height = 124});

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;

  const _SearchNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: colors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: colors.onSurface,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.arrow_forward_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

extension on SearchResultState {
  int get total => shows.length + players.length + stages.length + teams.length;
}

class _MobileSearchIntro extends StatelessWidget {
  final String query;
  final int filter;
  final int? total;
  final Animation<double> reveal;

  const _MobileSearchIntro({
    super.key,
    required this.query,
    required this.filter,
    required this.total,
    required this.reveal,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String clean = query.trim();
    final bool browsing = clean.isEmpty;
    final String title = browsing
        ? 'Sahnede ne arıyorsun?'
        : filter == 0
            ? '“$clean” için bulduklarımız'
            : '${_kFacets[filter]} · “$clean”';
    final String supporting = browsing
        ? 'Bir oyun adı, oyuncu, sahne ya da topluluk yaz. '
            'İstersen aşağıdaki seçkiden başla.'
        : total == null
            ? 'Arşiv taranıyor…'
            : total == 0
                ? 'Başka bir kelime ya da kapsam deneyebilirsin.'
                : '$total gerçek içerik eşleşti.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: AuthWipeReveal(
            reveal: reveal,
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: colors.onSurface,
                fontSize: browsing ? 32 : 27,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          supporting,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _MobileShowResult extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const _MobileShowResult({required this.show, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String tag = TiyatrolHeroTags.show(show.id, 'search-mobile');
    final List<String> meta = [
      if (show.category.trim().isNotEmpty) show.category.trim(),
      if (show.duration.trim().isNotEmpty) show.duration.trim(),
    ];

    return Semantics(
      button: true,
      label: '${show.name} oyununu aç',
      excludeSemantics: true,
      child: PosterPlate(
        radius: AppRadius.md,
        shadows: AppShadows.level2(colors.shadow),
        child: Material(
          color: colors.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 94,
                    child: TiyatrolHero(
                      tag: tag,
                      child: OptimizedCachedImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              show.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: colors.onSurface,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meta.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ],
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

/// Masaüstü sonuç başlığı: ne arandığı + gerçek sonuç sayısı.
class _ResultsHeadline extends StatelessWidget {
  final String query;
  final int filter;
  final int? total;

  const _ResultsHeadline({
    required this.query,
    required this.filter,
    required this.total,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String title = query.isEmpty
        ? (filter == 0 ? 'Göz at' : _kFacets[filter])
        : '“$query”';
    final String? sub = total == null
        ? null
        : query.isEmpty
            ? (filter == 0
                ? 'Aramaya başlamadan önce en yeni oyunlar ve tüm içerik.'
                : '$total sonuç')
            : (filter == 0
                ? '$total sonuç'
                : '${_kFacets[filter]} içinde $total sonuç');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: cs.onSurface,
              fontSize: browseFluid(context, 28, 40),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(sub, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        ],
      ],
    );
  }
}

/// Oyuncu: sahibinin İLK tasarımı (`PlayerHeroCard`, ilk sürüm) birebir —
/// 120 genişlikte, köşeleri tamamen yuvarlatılmış uzun "hap/ayna"
/// portre (ClipRRect r=60) ve altında ad / soyad iki satır. Sonraki
/// sürümler (yuvarlak, elips) beğenilmedi; bu dil korunur.
class _PlayerAvatar extends StatelessWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  static const double cellWidth = 120;
  static const double railHeight = 180;
  static const double gridAspect = 0.65;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String name = '${player.firstName} ${player.lastName}'.trim();
    final String initials = [
      if (player.firstName.isNotEmpty) player.firstName[0],
      if (player.lastName.isNotEmpty) player.lastName[0],
    ].join().toUpperCase();
    final String heroTag = TiyatrolHeroTags.player(player.id, 'search');
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          TiyatrolHeroFlight.prepare(
            heroTag,
            imageUrl: player.imageUrl,
            title: name,
          );
          NavigationHandler.goToPlayer(context, player.id, name,
              heroTag: heroTag, imageUrl: player.imageUrl, title: name);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: cellWidth,
            child: Column(
              children: [
                Expanded(
                  child: TiyatrolHero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: ColoredBox(
                        color: cs.primary.withValues(alpha: 0.12),
                        child: OptimizedCachedImage(
                          imageUrl: player.imageUrl,
                          fit: BoxFit.cover,
                          width: cellWidth,
                          errorBuilder: (final _, final __, final ___) =>
                              Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: cs.primary,
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
                const SizedBox(height: 8),
                Text(
                  '${player.firstName}\n${player.lastName}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/craft.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/listing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_search.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';
import '../widgets/search_place_cards.dart';

// =============================================================================
// ARAMA — "Katalog"
// =============================================================================
//
// Mantık aynı: searchQueryProvider / searchFilterProvider / searchResultProvider.
// Görsel dil: ışıyan kenar arama (TicketSearchShell), yoğun afiş ızgarası,
// hap oyuncu portreleri (120px), fotoğraflı mekan/ekip kartları.

const List<String> _kFacets = [
  'Tümü',
  'Oyunlar',
  'Oyuncular',
  'Mekanlar',
  'Ekipler',
];

enum _Layout { mobile, tablet, desktop }

const String _kRecentSearches = 'tiyatrol.recent_searches';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with ResponsiveUtils, GlobalScrollMixin {
  final _textController = TextEditingController();
  bool _fieldFocused = false;
  String? _showCategory;
  List<String> _recents = const [];

  @override
  void initState() {
    super.initState();
    _textController.text = ref.read(searchQueryProvider);
    _loadRecents();
  }

  @override
  void dispose() {
    // ignore: undefined_method
    _textController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() {}

  void _onSeeAll(final int filterIndex) =>
      ref.read(searchFilterProvider.notifier).setFilter(filterIndex);

  void _onQueryChanged(final String value) =>
      ref.read(searchQueryProvider.notifier).update(value);

  void _clearQuery() {
    _textController.clear();
    ref.read(searchQueryProvider.notifier).update('');
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

  void _openShow(final Show show, {final String from = 'search'}) =>
      NavigationHandler.goToShow(
        context,
        show.id,
        show.name,
        heroTag: TiyatrolHeroTags.show(show.id, from),
        imageUrl: show.imageUrl,
        title: show.name,
      );

  @override
  Widget build(final BuildContext context) {
    final int filter = ref.watch(searchFilterProvider);
    final String query = ref.watch(searchQueryProvider);
    final AsyncValue<SearchResultState> state = ref.watch(searchResultProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _Layout layout = context.isDesktop
        ? _Layout.desktop
        : (context.isTablet ? _Layout.tablet : _Layout.mobile);
    final bool refreshing = state.isLoading && state.hasValue;

    return BasePageWrapper(
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
          ? _desktop(context, state, filter, query, refreshing)
          : _phone(context, state, filter, query, refreshing, layout),
    );
  }

  // ─── chrome ───────────────────────────────────────────────────────────────

  Widget _searchField({final bool autofocus = true}) {
    return Focus(
      onFocusChange: (final v) => setState(() => _fieldFocused = v),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _textController,
        builder: (final context, final value, final _) {
          return TicketSearchShell(
            focused: _fieldFocused,
            trailing: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    onPressed: _clearQuery,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                    style: listingUi(
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 16,
                      weight: FontWeight.w600,
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
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
          );
        },
      ),
    );
  }

  Widget _facets(final int filter) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kFacets.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (final context, final i) {
          final bool on = filter == i;
          final ColorScheme cs = Theme.of(context).colorScheme;
          return Semantics(
            button: true,
            selected: on,
            label: _kFacets[i],
            child: PressScale(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(searchFilterProvider.notifier).setFilter(i);
              },
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? cs.onSurface : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _kFacets[i],
                  style: listingUi(
                    color: on ? cs.surface : cs.onSurface,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _progress(final bool refreshing) => SizedBox(
        height: 2,
        child: refreshing
            ? const LinearProgressIndicator(minHeight: 2)
            : const SizedBox.shrink(),
      );

  // ─── phone / tablet ───────────────────────────────────────────────────────

  Widget _phone(
    final BuildContext context,
    final AsyncValue<SearchResultState> state,
    final int filter,
    final String query,
    final bool refreshing,
    final _Layout layout,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double gutter = AppSpacing.lg;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, 0),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Geri',
                  child: PressScale(
                    onTap: () => NavigationHandler.smartGoBack(context),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: cs.onSurface),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _searchField()),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, 0),
          child: _facets(filter),
        ),
        _progress(refreshing),
        Expanded(
          child: state.when(
            loading: () => const _SearchSkeleton(),
            error: (final _, final __) => _ErrorBody(
              onRetry: () => ref.invalidate(searchResultProvider),
            ),
            data: (final data) => CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: _bodySlivers(
                data,
                filter,
                query,
                layout,
                gutter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── desktop ──────────────────────────────────────────────────────────────

  Widget _desktop(
    final BuildContext context,
    final AsyncValue<SearchResultState> state,
    final int filter,
    final String query,
    final bool refreshing,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Material(
            color: cs.surfaceContainerLow,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Geri',
                          onPressed: () =>
                              NavigationHandler.smartGoBack(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Arama',
                            style: listingUi(
                              color: cs.onSurface,
                              size: 22,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _searchField(autofocus: !kIsWeb),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Tür',
                      style: listingUi(
                        color: cs.onSurfaceVariant,
                        size: 12,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (int i = 0; i < _kFacets.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          selected: filter == i,
                          selectedTileColor: cs.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          title: Text(
                            _kFacets[i],
                            style: listingUi(
                              color: filter == i
                                  ? cs.onPrimaryContainer
                                  : cs.onSurface,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        Expanded(
          child: Column(
            children: [
              _progress(refreshing),
              Expanded(
                child: state.when(
                  loading: () => const _SearchSkeleton(),
                  error: (final _, final __) => _ErrorBody(
                    onRetry: () => ref.invalidate(searchResultProvider),
                  ),
                  data: (final data) => CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      ..._bodySlivers(
                        data,
                        filter,
                        query,
                        _Layout.desktop,
                        AppSpacing.xxl,
                      ),
                      const SliverToBoxAdapter(child: Footer()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── content ──────────────────────────────────────────────────────────────

  List<Widget> _bodySlivers(
    final SearchResultState data,
    final int filter,
    final String query,
    final _Layout layout,
    final double gutter,
  ) {
    final bool browsing = query.trim().isEmpty;
    final List<BrowseCategory> categories = browseCategoriesOf(data.shows);
    final String? activeCat = _activeCategory(categories);
    final List<Show> shows = _showsInCategory(data.shows, activeCat);

    if (!browsing) {
      final int total = _count(data, filter, shows);
      if (total == 0) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyQuery(
              query: query,
              filter: filter,
              onClear: _clearQuery,
              onEverywhere: _searchEverywhere,
            ),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, AppSpacing.md),
            child: Text(
              '“${query.trim()}” · $total sonuç',
              style: listingUi(
                color: Theme.of(context).colorScheme.onSurface,
                size: 22,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if ((filter == 0 || filter == 1) && categories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: BrowseCategoryStrip(
                categories: categories,
                selectedKey: activeCat,
                total: data.shows
                    .where((final s) => s.category.trim().isNotEmpty)
                    .length,
                onPick: _pickShowCategory,
                padding: EdgeInsets.symmetric(horizontal: gutter),
              ),
            ),
          ),
        ..._resultBlocks(data, filter, shows, layout, gutter),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    }

    // Browse (boş sorgu)
    if (data.shows.isEmpty &&
        data.players.isEmpty &&
        data.stages.isEmpty &&
        data.teams.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CatalogEmpty(
            onDiscover: () => NavigationHandler.goToDiscover(context),
          ),
        ),
      ];
    }

    return [
      if (layout != _Layout.desktop)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.lg,
              gutter,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahnede ne arıyorsun?',
                  style: listingUi(
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 26,
                    weight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Son aramaların ve çok bakılan oyunlar',
                  style: listingUi(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_recents.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, AppSpacing.md, gutter, AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final String recent in _recents)
                  ActionChip(
                    label: Text(
                      recent,
                      style: listingUi(
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _applyRecent(recent),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ),
        ),
      if ((filter == 0 || filter == 1) && categories.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: BrowseCategoryStrip(
              categories: categories,
              selectedKey: activeCat,
              total: data.shows
                  .where((final s) => s.category.trim().isNotEmpty)
                  .length,
              onPick: _pickShowCategory,
              padding: EdgeInsets.symmetric(horizontal: gutter),
            ),
          ),
        ),
      if (filter == 0 || filter == 1) ...[
        if (shows.isNotEmpty) ...[
          _sectionTitle(gutter, 'Çok bakılanlar', shows.length,
              onAction: shows.length > 8 ? () => _onSeeAll(1) : null),
          _showsGrid(shows.take(filter == 1 ? shows.length : 8).toList(),
              layout, gutter),
        ],
      ],
      if (filter == 0 || filter == 2) ...[
        if (data.players.isNotEmpty) ...[
          _sectionTitle(gutter, 'Oyuncular', data.players.length,
              onAction:
                  data.players.length > 9 ? () => _onSeeAll(2) : null),
          _playersGrid(
            data.players.take(filter == 2 ? data.players.length : 9).toList(),
            gutter,
          ),
        ],
      ],
      if (filter == 0 || filter == 3) ...[
        if (data.stages.isNotEmpty) ...[
          _sectionTitle(gutter, 'Mekanlar', data.stages.length,
              onAction: data.stages.length > 4 ? () => _onSeeAll(3) : null),
          _stagesList(
            data.stages.take(filter == 3 ? data.stages.length : 4).toList(),
            layout,
            gutter,
          ),
        ],
      ],
      if (filter == 0 || filter == 4) ...[
        if (data.teams.isNotEmpty) ...[
          _sectionTitle(gutter, 'Ekipler', data.teams.length,
              onAction: data.teams.length > 4 ? () => _onSeeAll(4) : null),
          _teamsList(
            data.teams.take(filter == 4 ? data.teams.length : 4).toList(),
            layout,
            gutter,
          ),
        ],
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  List<Widget> _resultBlocks(
    final SearchResultState data,
    final int filter,
    final List<Show> shows,
    final _Layout layout,
    final double gutter,
  ) {
    return [
      if ((filter == 0 || filter == 1) && shows.isNotEmpty) ...[
        if (filter == 0)
          _sectionTitle(gutter, 'Oyunlar', shows.length,
              onAction: shows.length > 6 ? () => _onSeeAll(1) : null),
        _showsGrid(
          shows.take(filter == 1 ? shows.length : 6).toList(),
          layout,
          gutter,
        ),
      ],
      if ((filter == 0 || filter == 2) && data.players.isNotEmpty) ...[
        if (filter == 0)
          _sectionTitle(gutter, 'Oyuncular', data.players.length,
              onAction: data.players.length > 9 ? () => _onSeeAll(2) : null),
        _playersGrid(
          data.players
              .take(filter == 2 ? data.players.length : 9)
              .toList(),
          gutter,
        ),
      ],
      if ((filter == 0 || filter == 3) && data.stages.isNotEmpty) ...[
        if (filter == 0)
          _sectionTitle(gutter, 'Mekanlar', data.stages.length,
              onAction: data.stages.length > 4 ? () => _onSeeAll(3) : null),
        _stagesList(
          data.stages.take(filter == 3 ? data.stages.length : 4).toList(),
          layout,
          gutter,
        ),
      ],
      if ((filter == 0 || filter == 4) && data.teams.isNotEmpty) ...[
        if (filter == 0)
          _sectionTitle(gutter, 'Ekipler', data.teams.length,
              onAction: data.teams.length > 4 ? () => _onSeeAll(4) : null),
        _teamsList(
          data.teams.take(filter == 4 ? data.teams.length : 4).toList(),
          layout,
          gutter,
        ),
      ],
    ];
  }

  int _count(
    final SearchResultState data,
    final int filter,
    final List<Show> shows,
  ) {
    switch (filter) {
      case 1:
        return shows.length;
      case 2:
        return data.players.length;
      case 3:
        return data.stages.length;
      case 4:
        return data.teams.length;
      default:
        return shows.length +
            data.players.length +
            data.stages.length +
            data.teams.length;
    }
  }

  Widget _sectionTitle(
    final double gutter,
    final String title,
    final int count, {
    final VoidCallback? onAction,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$title · $count',
                style: listingUi(
                  color: cs.onSurface,
                  size: 20,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            if (onAction != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  'Tümü',
                  style: listingUi(
                    color: cs.primary,
                    size: 13,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _showsGrid(
    final List<Show> shows,
    final _Layout layout,
    final double gutter,
  ) {
    final int columns = layout == _Layout.desktop
        ? 5
        : (layout == _Layout.tablet ? 3 : 2);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (final context, final i) {
            final Show show = shows[i];
            final String tag =
                TiyatrolHeroTags.show(show.id, 'search-grid');
            return Semantics(
              button: true,
              label: show.name,
              child: PressScale(
                onTap: () => _openShow(show, from: 'search-grid'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.level2(
                            Theme.of(context).colorScheme.shadow,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: TiyatrolHero(
                            tag: tag,
                            child: OptimizedCachedImage(
                              imageUrl: show.imageUrl,
                              fit: BoxFit.cover,
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
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 13,
                        weight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (show.category.trim().isNotEmpty)
                      Text(
                        show.category.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: listingUi(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 11,
                          weight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: shows.length,
        ),
      ),
    );
  }

  Widget _playersGrid(final List<Player> players, final double gutter) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.responsive(mobile: 3, tablet: 5, desktop: 6),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (final context, final i) => _PlayerPill(player: players[i]),
          childCount: players.length,
        ),
      ),
    );
  }

  Widget _stagesList(
    final List<Stage> stages,
    final _Layout layout,
    final double gutter,
  ) {
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: stages.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (final context, final i) => SearchStageCard(
            stage: stages[i],
            onTap: () => NavigationHandler.goToStage(
              context,
              stages[i].id,
              stages[i].name,
            ),
          ),
        ),
      );
    }
    return _showsAsGridSlots(stages.length, gutter, layout, (final i) {
      return SearchStageCard(
        stage: stages[i],
        onTap: () => NavigationHandler.goToStage(
          context,
          stages[i].id,
          stages[i].name,
        ),
      );
    }, extent: 220);
  }

  Widget _teamsList(
    final List<Team> teams,
    final _Layout layout,
    final double gutter,
  ) {
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: teams.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (final context, final i) => SearchTeamCard(
            team: teams[i],
            onTap: () => NavigationHandler.goToTeam(
              context,
              teams[i].id,
              teams[i].name,
            ),
          ),
        ),
      );
    }
    return _showsAsGridSlots(teams.length, gutter, layout, (final i) {
      return SearchTeamCard(
        team: teams[i],
        onTap: () => NavigationHandler.goToTeam(
          context,
          teams[i].id,
          teams[i].name,
        ),
      );
    }, extent: 160);
  }

  Widget _showsAsGridSlots(
    final int count,
    final double gutter,
    final _Layout layout,
    final Widget Function(int) builder, {
    required final double extent,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: layout == _Layout.desktop ? 420 : 480,
          mainAxisExtent: extent,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
        ),
        delegate: SliverChildBuilderDelegate(
          (final context, final i) => builder(i),
          childCount: count,
        ),
      ),
    );
  }
}

// ─── player pill (onaylı 120×hap) ───────────────────────────────────────────

class _PlayerPill extends StatelessWidget {
  final Player player;

  const _PlayerPill({required this.player});

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
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: AppShadows.level2(cs.shadow),
                ),
                child: TiyatrolHero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: ColoredBox(
                      color: cs.primaryContainer,
                      child: OptimizedCachedImage(
                        imageUrl: player.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                        errorBuilder: (final _, final __, final ___) => Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
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
                color: cs.onSurface,
                size: 12,
                weight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── empty / error / skeleton ───────────────────────────────────────────────

class _EmptyQuery extends StatelessWidget {
  final String query;
  final int filter;
  final VoidCallback onClear;
  final VoidCallback onEverywhere;

  const _EmptyQuery({
    required this.query,
    required this.filter,
    required this.onClear,
    required this.onEverywhere,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '“${query.trim()}” bulunamadı',
            textAlign: TextAlign.center,
            style: listingUi(
              color: cs.onSurface,
              size: 22,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Yazımı kontrol et veya başka bir türde ara.',
            textAlign: TextAlign.center,
            style: listingUi(
              color: cs.onSurfaceVariant,
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (filter != 0)
            FilledButton(
              onPressed: onEverywhere,
              child: const Text('Tümünde ara'),
            )
          else
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Aramayı temizle'),
            ),
        ],
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  final VoidCallback onDiscover;

  const _CatalogEmpty({required this.onDiscover});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Henüz içerik yok',
            style: listingUi(
              color: cs.onSurface,
              size: 22,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keşfet’e göz at, yeni oyunlar eklendikçe burada görünür.',
            textAlign: TextAlign.center,
            style: listingUi(
              color: cs.onSurfaceVariant,
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: onDiscover,
            child: const Text('Keşfet’e git'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBody({required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arama yüklenemedi',
              style: listingUi(
                color: Theme.of(context).colorScheme.onSurface,
                size: 18,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(final BuildContext context) {
    final Color box = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget cell() => Container(
          decoration: BoxDecoration(
            color: box,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        );
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (final _, final __) => cell(),
    );
  }
}

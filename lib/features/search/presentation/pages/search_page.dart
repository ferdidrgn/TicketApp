import 'dart:math' as math;
import '../../../../shared/widgets/ticket/ticket_search.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/theatre_show_card.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// ARAMA
// =============================================================================
//
// Mantık değişmedi: `searchQueryProvider` (serbest metin), `searchFilterProvider`
// (0 Tümü, 1 Oyunlar, 2 Oyuncular, 3 Mekanlar, 4 Ekipler) ve
// `searchResultProvider` (boş sorguda aktif-önce/en yeni oyunlar, yazınca
// TÜM oyunlar içinde arama).
//
// - Mobil (<768): üstte kalan arama kutusu + tür çipleri; oyunlar kompakt
//   BİLET SATIRLARI (`ShowTicketRow`), kişiler yatay şerit, yerler liste.
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

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with ResponsiveUtils, GlobalScrollMixin {
  final _textController = TextEditingController();
  bool _fieldFocused = false;

  @override
  void dispose() {
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

  /// Boş sonuçta "Tümünde ara": sorgu korunur, tür filtresi kalkar.
  void _searchEverywhere() =>
      ref.read(searchFilterProvider.notifier).setFilter(0);

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
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
      ),
      child: layout == _Layout.desktop
          ? _buildDesktop(context, state, filter, query, refreshing)
          : _buildCompact(context, state, filter, query, refreshing, layout),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Arama kutusu
  // ─────────────────────────────────────────────────────────────────────

  /// Ortak "gişe arama fişi" ([TicketSearchShell]): vurgu renginde arama
  /// damgası + delik çizgisi + gerçek yazı alanı. Alan boşken dönen gerçek
  /// örnekler ("Ara: …") gösterilir; yazmaya başlayınca kaybolur.
  Widget _searchField(final BuildContext context, {final bool autofocus = true}) {
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
                  onSubmitted: (final _) => FocusScope.of(context).unfocus(),
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

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: PinnedBrowseHeader(
            extent: 124,
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
                const SizedBox(height: AppSpacing.xs),
                BrowseChoiceChips(
                  options: [for (final f in _kFacets) BrowseOption(f)],
                  selectedIndex: filter,
                  onSelected: _onSeeAll,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                ),
                _progressLine(refreshing),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ..._resultSlivers(state, filter, query, layout, gutter),
        if (kIsWeb) ...[
          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.section)),
          const SliverToBoxAdapter(child: Footer()),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl,
                AppSpacing.lg, AppSpacing.xxl),
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
                    final double gutter = math.max(AppSpacing.huge,
                        (constraints.maxWidth - 1240) / 2);
                    return CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(gutter,
                              AppSpacing.xxl + AppSpacing.sm, gutter,
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

  Widget _noticeSliver(final double gutter, final TicketNotice notice) =>
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
            TicketNotice(
              label: 'ARAMA',
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
            TicketNotice(
              label: 'ARAMA',
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
          TicketNotice(
            label: 'ARAMA',
            title: 'Henüz içerik yok',
            message: 'Oyunlar, oyuncular ve sahneler eklendikçe burada listelenecek.',
            actionLabel: "Keşfet'e git",
            onAction: () => NavigationHandler.goToDiscover(context),
          ),
        ),
      ];
    }

    switch (filter) {
      case 1:
        return [_showsSliver(data.shows, layout, gutter)];
      case 2:
        return [_playersGridSliver(data.players, gutter)];
      case 3:
        return [
          _tilesSliver(
              [for (final s in data.stages) _stageTile(s)], layout, gutter)
        ];
      case 4:
        return [
          _tilesSliver(
              [for (final t in data.teams) _teamTile(t)], layout, gutter)
        ];
    }

    // Tümü: her tür için kısa bir bölüm + "Tümünü gör".
    final int showPreview = layout == _Layout.mobile ? 4 : 8;
    final int tilePreview = layout == _Layout.mobile ? 4 : 6;
    return [
      if (data.shows.isNotEmpty) ...[
        _boxed(
          gutter,
          BrowseSectionTitle(
            title: 'Oyunlar',
            count: data.shows.length,
            onAction:
                data.shows.length > showPreview ? () => _onSeeAll(1) : null,
          ),
        ),
        _showsSliver(
            data.shows.take(showPreview).toList(), layout, gutter),
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
            height: _PlayerAvatar.cellHeight,
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
        _tilesSliver([
          for (final s in data.stages.take(tilePreview)) _stageTile(s),
        ], layout, gutter),
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
        _tilesSliver([
          for (final t in data.teams.take(tilePreview)) _teamTile(t),
        ], layout, gutter),
      ],
    ];
  }

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  /// Oyunlar: mobilde kompakt bilet satırları, tablet/masaüstünde bilet
  /// koçanlı kart ızgarası.
  Widget _showsSliver(
      final List<Show> shows, final _Layout layout, final double gutter) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(
        gutter, 0, gutter, AppSpacing.section - AppSpacing.lg);
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: shows.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (final context, final i) => ShowTicketRow(
            key: ValueKey('search-show-${shows[i].id}'),
            show: shows[i],
            onTap: () => _openShow(shows[i]),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        gridDelegate:
            browseShowGridDelegate(layout == _Layout.tablet ? 220 : 240),
        itemCount: shows.length,
        itemBuilder: (final context, final i) => TheatreShowCard(
          key: ValueKey('search-show-${shows[i].id}'),
          show: shows[i],
          onTap: () => _openShow(shows[i]),
        ),
      ),
    );
  }

  Widget _playersGridSliver(final List<Player> players, final double gutter) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
            gutter, 0, gutter, AppSpacing.section - AppSpacing.lg),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _PlayerAvatar.cellWidth + AppSpacing.lg,
            mainAxisExtent: _PlayerAvatar.cellHeight,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
          ),
          itemCount: players.length,
          itemBuilder: (final context, final i) =>
              _PlayerAvatar(player: players[i]),
        ),
      );

  Widget _tilesSliver(
      final List<Widget> tiles, final _Layout layout, final double gutter) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(
        gutter, 0, gutter, AppSpacing.section - AppSpacing.lg);
    if (layout == _Layout.mobile) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: tiles.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (final context, final i) => tiles[i],
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate:
            browseRowGridDelegate(maxRowWidth: 400, rowHeight: 72),
        delegate: SliverChildListDelegate(tiles),
      ),
    );
  }

  Widget _stageTile(final Stage stage) => BrowseListTile(
        key: ValueKey('search-stage-${stage.id}'),
        imageUrl: stage.imageUrl,
        title: stage.name,
        subtitle: stage.address,
        fallbackIcon: Icons.location_city_rounded,
        onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
      );

  Widget _teamTile(final Team team) => BrowseListTile(
        key: ValueKey('search-team-${team.id}'),
        imageUrl: team.imageUrl,
        title: team.name,
        subtitle: team.showsId.isEmpty ? null : '${team.showsId.length} oyun',
        fallbackIcon: Icons.groups_rounded,
        onTap: () => NavigationHandler.goToTeam(context, team.id, team.name),
      );

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
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: 5,
        separatorBuilder: (final _, final __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (final _, final __) =>
            TicketRowSkeleton(height: showsShape ? 96 : 72),
      ),
    );
  }
}

extension on SearchResultState {
  int get total => shows.length + players.length + stages.length + teams.length;
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
          Text(sub,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
        ],
      ],
    );
  }
}

/// Oyuncu: eski "el aynası" kartı (sahibinin isteğiyle geri getirildi) —
/// 84x128 dikey oval portre, ince çerçeve, altta iki satırlık ad. Üzerine
/// gelince / klavye odağında çerçeve belirginleşir, fotoğraf hafifçe
/// büyür. `BoxShape.circle` + `ClipOval` kutunun oranına göre elips çizer;
/// dikey kutu otomatik olarak el aynası ovaline dönüşür. Renkler temadan
/// (eski sürümdeki sabit altın yerine vurgu rengi).
class _PlayerAvatar extends StatefulWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  static const double mirrorWidth = 84;
  static const double mirrorHeight = 128;
  static const double cellWidth = 104;
  static const double cellHeight = mirrorHeight + AppSpacing.md + 32 + 8;

  @override
  State<_PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<_PlayerAvatar> {
  bool _active = false;

  void _set(final bool v) {
    if (_active != v) setState(() => _active = v);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final player = widget.player;
    final String name = '${player.firstName} ${player.lastName}'.trim();
    final String initials = [
      if (player.firstName.isNotEmpty) player.firstName[0],
      if (player.lastName.isNotEmpty) player.lastName[0],
    ].join().toUpperCase();
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => NavigationHandler.goToPlayer(context, player.id, name),
          onHover: _set,
          onFocusChange: _set,
          mouseCursor: SystemMouseCursors.click,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  width: _PlayerAvatar.mirrorWidth,
                  height: _PlayerAvatar.mirrorHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _active
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.28),
                      width: _active ? 2 : 1,
                    ),
                    boxShadow: _active
                        ? AppShadows.level2(cs.primary)
                        : AppShadows.level0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: AnimatedScale(
                        scale: _active ? 1.08 : 1.0,
                        duration: AppMotion.normal,
                        curve: AppMotion.standard,
                        child: ColoredBox(
                          color: cs.primary.withValues(alpha: 0.12),
                          child: OptimizedCachedImage(
                            imageUrl: player.imageUrl,
                            fit: BoxFit.cover,
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
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: _PlayerAvatar.cellWidth,
                  // Sabit yükseklik: iki satırlık uzun isimlerde ızgara
                  // hücresi taşmasın.
                  height: 32,
                  child: Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _active ? cs.primary : cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: 0.1,
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

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/pages/team_details_mobile.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// 1. DESIGN TOKENS & STYLES
// =============================================================================

class _Styles {
  static final cardRadius = BorderRadius.circular(16.0);
  static final mosaicRadius = BorderRadius.circular(16);
  static const horizontalCardRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    bottomRight: Radius.circular(20),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
  );

  static List<BoxShadow> shadow(final bool isSelected, final Color color) =>
      isSelected
          ? [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 3)),
              BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, -2))
            ]
          : [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ];

  static BoxDecoration glassDecoration(final BuildContext context) =>
      BoxDecoration(
        color: (context.isDarkMode ? Colors.white : Colors.white)
            .withOpacity(context.isDarkMode ? 0.08 : 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.onSurface.withOpacity(0.1)),
      );

  static final darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
    stops: const [0.5, 1.0],
  );

  static final bottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
    stops: const [0.6, 1.0],
  );
}

// =============================================================================
// 2. DATA LOGIC
// =============================================================================

class _SearchLogic {
  static List<T> filterAndPaginate<T>(final List<T>? items, final String query,
      final String Function(T) selector,
      {final int page = 0, final bool paginate = true}) {
    if (items == null) return [];
    final filtered = query.isEmpty
        ? items
        : items
            .where((final i) => selector(i).toLowerCase().contains(query))
            .toList();
    if (!paginate) return filtered;

    final start = page * 20;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, math.min(start + 20, filtered.length));
  }

  static int totalCount<T>(final List<T>? items, final String query,
          final String Function(T) selector) =>
      items
          ?.where((final i) =>
              query.isEmpty || selector(i).toLowerCase().contains(query))
          .length ??
      0;
}

// =============================================================================
// 3. UI COMPONENTS
// =============================================================================

class _BaseCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const _BaseCardContainer(
      {required this.child,
      this.onTap,
      this.borderRadius,
      this.width,
      this.padding,
      this.margin});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: borderRadius ?? _Styles.cardRadius,
              boxShadow: _Styles.shadow(false, Colors.black)),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      );
}

class _BadgeLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _BadgeLabel(this.text, {this.isDark = false});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(isDark ? 0.9 : 1.0),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
      );
}

// =============================================================================
// 4. MAIN SEARCH PAGE
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isInitialized = false;
  bool _loadingMore = false;
  int _selectedFilter = 0;
  final Map<int, int> _pages = {1: 0, 2: 0, 3: 0, 4: 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _initData();
      _scrollController.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (_isInitialized) return;
    await Future.wait([
      if (ref.read(showProvider).isListNullOrEmpty)
        ref.read(showProvider.notifier).loadShows(true),
      if (ref.read(playerProvider).isListNullOrEmpty)
        ref.read(playerProvider.notifier).getPlayers(true),
      if (ref.read(stageProvider).isListNullOrEmpty)
        ref.read(stageProvider.notifier).loadStages(true),
      if (ref.read(teamProvider).isListNullOrEmpty)
        ref.read(teamProvider.notifier).loadTeams(true),
    ]);
    setState(() => _isInitialized = true);
  }

  void _onScroll() {
    if (_selectedFilter == 0 || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) _loadMoreItems();
  }

  void _loadMoreItems() {
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = ref.read(searchQueryProvider);
      void increment(final int type, final int total) {
        if (((_pages[type] ?? 0) + 1) * 20 < total)
          _pages[type] = (_pages[type] ?? 0) + 1;
      }

      setState(() {
        switch (_selectedFilter) {
          case 1:
            increment(
                1,
                _SearchLogic.totalCount(ref.read(showProvider).dataList, query,
                    (final s) => s.name));
          case 2:
            increment(
                2,
                _SearchLogic.totalCount(ref.read(playerProvider).dataList,
                    query, (final p) => '${p.firstName} ${p.lastName}'));
          case 3:
            increment(
                3,
                _SearchLogic.totalCount(ref.read(stageProvider).dataList, query,
                    (final s) => s.name));
          case 4:
            increment(
                4,
                _SearchLogic.totalCount(ref.read(teamProvider).dataList, query,
                    (final t) => t.name));
        }
        _loadingMore = false;
      });
    });
  }

  @override
  Widget build(final BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final (rawShows, rawPlayers, rawStages, rawTeams) = (
      ref.watch(showProvider),
      ref.watch(playerProvider),
      ref.watch(stageProvider),
      ref.watch(teamProvider)
    );

    final loading = (
      shows: rawShows.isLoading || !_isInitialized,
      players: rawPlayers.isLoading || !_isInitialized,
      stages: rawStages.isLoading || !_isInitialized,
      teams: rawTeams.isLoading || !_isInitialized,
    );

    final data = (
      shows: _SearchLogic.filterAndPaginate(
          rawShows.dataList, query, (final s) => s.name,
          page: _pages[1]!, paginate: _selectedFilter == 1),
      players: _SearchLogic.filterAndPaginate(rawPlayers.dataList, query,
          (final p) => '${p.firstName} ${p.lastName}',
          page: _pages[2]!, paginate: _selectedFilter == 2),
      stages: _SearchLogic.filterAndPaginate(
          rawStages.dataList, query, (final s) => s.name,
          page: _pages[3]!, paginate: _selectedFilter == 3),
      teams: _SearchLogic.filterAndPaginate(
          rawTeams.dataList, query, (final t) => t.name,
          page: _pages[4]!, paginate: _selectedFilter == 4),
    );

    final isAllEmpty = !loading.shows &&
        !loading.players &&
        !loading.stages &&
        !loading.teams &&
        data.shows.isEmpty &&
        data.players.isEmpty &&
        data.stages.isEmpty &&
        data.teams.isEmpty;

    return Scaffold(
      // 1. ÖNEMLİ: Scaffold rengini şeffaf yapıyoruz ki alttaki efekt görünsün
      backgroundColor: Colors.transparent,

      // 2. ExtendBodyBehindAppBar önemli, içerik en tepeye kadar çıksın
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        backgroundColor: context.isDarkMode
            ? const Color(0xFF10141C) // Daha lacivert/koyu bir zemin
            : const Color(0xFFF0F4F8),
        // Daha soğuk bir gri/beyaz

        ambientColor: Colors.indigoAccent,
        // Işık huzmesi indigo renginde olsun

        particleColor: Colors.blueGrey.withOpacity(0.3),
        // Parçacıklar mavi-gri olsun
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(query)),
                  SliverToBoxAdapter(child: _buildFilterList()),
                  if (isAllEmpty)
                    _buildEmptyState()
                  else if (_selectedFilter == 0)
                    ..._buildAllSections(loading, data)
                  else
                    ..._buildFilteredSection(loading, data),
                  if (_loadingMore)
                    const SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()))),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(final String query) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TopHeader(title: "Tablolarımız"),
          const SizedBox(height: 20),
          GlassSearchBar(
              controller: _textController,
              onChanged: (final v) => ref
                  .read(searchQueryProvider.notifier)
                  .setQuery(v.toLowerCase())),
        ]),
      );

  Widget _buildFilterList() => FilterList(
        selectedIndex: _selectedFilter,
        onSelected: (final i) {
          setState(() {
            _selectedFilter = i;
            _pages.updateAll((final _, final __) => 0);
          });
          WidgetsBinding.instance.addPostFrameCallback((final _) {
            if (_scrollController.hasClients)
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
          });
        },
      );

  List<Widget> _buildAllSections(
    final ({bool players, bool shows, bool stages, bool teams}) loading,
    final ({
      List<Player> players,
      List<Show> shows,
      List<Stage> stages,
      List<Team> teams
    }) data,
  ) =>
      [
        if (loading.players || data.players.isNotEmpty)
          SliverToBoxAdapter(
              child: _PlayerSection(
                  players: data.players, isLoading: loading.players)),
        if (loading.shows || data.shows.isNotEmpty)
          _HorizontalMosaicSection(shows: data.shows, isLoading: loading.shows),
        if (loading.stages || data.stages.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Mekanlar",
                  subtitle: "Atmosfer",
                  items: data.stages,
                  isStage: true,
                  isLoading: loading.stages)),
        if (loading.teams || data.teams.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Ekipler",
                  subtitle: "Mutfak",
                  items: data.teams,
                  isStage: false,
                  isLoading: loading.teams)),
      ];

  List<Widget> _buildFilteredSection(
    final ({bool players, bool shows, bool stages, bool teams}) l,
    final ({
      List<Player> players,
      List<Show> shows,
      List<Stage> stages,
      List<Team> teams
    }) d,
  ) =>
      switch (_selectedFilter) {
        1 => [
            if (l.shows)
              _GridHelpers.mosaicShimmer()
            else
              _ChaoticMosaicBuilder(
                  items: d.shows,
                  builder: (final c, final s, final h) =>
                      _GridCards.showMosaic(c, s as Show, height: h)),
            if (d.shows.isEmpty && !l.shows)
              _buildEmptyState(msg: "Etkinlik bulunamadı"),
          ],
        2 => [
            if (l.players)
              _GridHelpers.standardShimmer(cross: 3, ratio: 0.7)
            else
              _GridHelpers.grid(d.players,
                  (final c, final p) => _GridCards.player(c, p as Player),
                  cross: 3, ratio: 0.7),
            if (d.players.isEmpty && !l.players)
              _buildEmptyState(msg: "Oyuncu bulunamadı"),
          ],
        3 => [
            if (l.stages)
              _GridHelpers.standardShimmer(ratio: 1.2)
            else
              _GridHelpers.grid(
                  d.stages,
                  (final c, final s) =>
                      _GridCards.vertical(c, s as Stage, true),
                  ratio: 1.2),
            if (d.stages.isEmpty && !l.stages)
              _buildEmptyState(msg: "Mekan bulunamadı"),
          ],
        4 => [
            if (l.teams)
              _GridHelpers.standardShimmer(ratio: 1.2)
            else
              _GridHelpers.grid(
                  d.teams,
                  (final c, final t) =>
                      _GridCards.vertical(c, t as Team, false),
                  ratio: 1.2),
            if (d.teams.isEmpty && !l.teams)
              _buildEmptyState(msg: "Ekip bulunamadı"),
          ],
        _ => [],
      };

  Widget _buildEmptyState({final String? msg}) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 80, color: context.colors.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(msg ?? "Aradığınız kriterlere uygun\nsonuç bulunamadı.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurface.withOpacity(0.5))),
        ])),
      );
}

// =============================================================================
// 5. HELPER WIDGETS (GRIDS, CARDS, SECTIONS)
// =============================================================================

class _GridHelpers {
  static Widget grid(final List<dynamic> items,
          final Widget Function(BuildContext, dynamic) builder,
          {final int cross = 2, final double ratio = 0.8}) =>
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: ratio),
          delegate: SliverChildBuilderDelegate(
              (final ctx, final i) => builder(ctx, items[i]),
              childCount: items.length),
        ),
      );

  static Widget standardShimmer(
          {final int cross = 2, final double ratio = 0.8}) =>
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: ratio),
          delegate: SliverChildBuilderDelegate(
              (final _, final __) => const ShimmerLoading(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16),
              childCount: 6),
        ),
      );

  static Widget mosaicShimmer() => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                (final _, final index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: ShimmerLoading(
                                  width: double.infinity,
                                  height: 200 + (index % 2) * 80,
                                  borderRadius: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: ShimmerLoading(
                                  width: double.infinity,
                                  height: 280 - (index % 2) * 80,
                                  borderRadius: 20)),
                        ])),
                childCount: 4)),
      );
}

class _GridCards {
  // Ortak Kart Yapısı (Stack + Gradient + Text)
  static Widget _cardStack(
          final String img, final String title, final String badge,
          {required final double h, required final Gradient grad}) =>
      SizedBox(
        height: h,
        child: Stack(fit: StackFit.expand, children: [
          OptimizedCachedImage(imageUrl: img, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: grad)),
          Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BadgeLabel(badge, isDark: grad == _Styles.darkGradient),
                    const SizedBox(height: 6),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2)),
                  ])),
        ]),
      );

  static Widget showMosaic(final BuildContext context, final Show s,
          {required final double height}) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => ShowDetailPage(showId: s.id))),
        width: double.infinity,
        child: _cardStack(s.imageUrl, s.name, "ETKİNLİK",
            h: height, grad: _Styles.darkGradient),
      );

  static Widget vertical(
          final BuildContext context, final dynamic item, final bool isStage) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => isStage
                    ? StageDetailPage(stageId: item.id)
                    : TeamDetailsPage(teamId: item.id))),
        child: _cardStack(item.imageUrl, item.name, isStage ? "MEKAN" : "EKİP",
            h: double.infinity, grad: _Styles.bottomGradient),
      );

  static Widget player(final BuildContext context, final Player p) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => PlayerDetailPage(playerId: p.id))),
        child: Column(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: OptimizedCachedImage(
                          imageUrl: p.imageUrl, fit: BoxFit.cover)))),
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(children: [
                const _BadgeLabel("OYUNCU"),
                const SizedBox(height: 2),
                Text(p.firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface)),
                Text(p.lastName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface.withOpacity(0.8))),
              ])),
        ]),
      );
}

class _ChaoticMosaicBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, double) builder;

  const _ChaoticMosaicBuilder({required this.items, required this.builder});

  @override
  Widget build(final BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate((final context, final index) {
          final chunk = index * 3;
          if (chunk >= items.length) return null;
          final i1 = items[chunk];
          final i2 = (chunk + 1 < items.length) ? items[chunk + 1] : null;
          final i3 = (chunk + 2 < items.length) ? items[chunk + 2] : null;
          final isA = index % 2 == 0;

          return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (isA) ...[
                      _big(context, i1, 10),
                      const SizedBox(width: 12),
                      _smallCol(context, i2, i3)
                    ],
                    if (!isA) ...[
                      _smallCol(context, i1, i2),
                      const SizedBox(width: 12),
                      i3 != null
                          ? _big(context, i3, -10)
                          : const Spacer(flex: 10)
                    ],
                  ])));
        }, childCount: (items.length / 3).ceil())),
      );

  Widget _big(final BuildContext c, final T item, final double offset) =>
      Expanded(
          flex: 10,
          child: Transform.translate(
              offset: Offset(0, offset), child: builder(c, item, 320)));

  Widget _smallCol(final BuildContext c, final T? i1, final T? i2) => Expanded(
      flex: 9,
      child: Column(children: [
        if (i1 != null) SizedBox(height: 150, child: builder(c, i1, 150)),
        if (i2 != null) ...[
          const SizedBox(height: 12),
          SizedBox(height: 150, child: builder(c, i2, 150))
        ],
      ]));
}

class _HorizontalMosaicSection extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;

  const _HorizontalMosaicSection({required this.shows, this.isLoading = false});

  @override
  Widget build(final BuildContext context) {
    if (isLoading) return _shimmer();
    return SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
      SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (shows.length / 2).ceil(),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final context, final index) {
              final s1 = (index * 2 < shows.length) ? shows[index * 2] : null;
              final s2 =
                  (index * 2 + 1 < shows.length) ? shows[index * 2 + 1] : null;
              if (s1 == null) return const SizedBox();
              final flexes = switch (index % 4) {
                0 => (5, 2),
                1 => (3, 4),
                2 => (2, 5),
                _ => (4, 3)
              };
              return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(children: [
                    Expanded(
                        flex: flexes.$1,
                        child: _GridCards.showMosaic(context, s1,
                            height: double.infinity)),
                    const SizedBox(height: 10),
                    s2 != null
                        ? Expanded(
                            flex: flexes.$2,
                            child: _GridCards.showMosaic(context, s2,
                                height: double.infinity))
                        : Spacer(flex: flexes.$2),
                  ]));
            },
          )),
      const SizedBox(height: 32),
    ]));
  }

  Widget _shimmer() => SliverToBoxAdapter(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
        SizedBox(
            height: 340,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (final _, final i) {
                  final f = switch (i % 4) {
                    0 => (5, 2),
                    1 => (3, 4),
                    2 => (2, 5),
                    _ => (4, 3)
                  };
                  return Container(
                      width: 155,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(children: [
                        Expanded(
                            flex: f.$1,
                            child: const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 16)),
                        const SizedBox(height: 10),
                        Expanded(
                            flex: f.$2,
                            child: const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 16))
                      ]));
                })),
        const SizedBox(height: 32),
      ]));
}

class _HorizontalListSection extends StatelessWidget {
  final String title, subtitle;
  final List<dynamic> items;
  final bool isStage, isLoading;

  const _HorizontalListSection(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.isStage,
      this.isLoading = false});

  @override
  Widget build(final BuildContext context) {
    if (isLoading)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: title, subtitle: subtitle),
        SizedBox(
            height: 150,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (final _, final __) =>
                    const ShimmerCard(width: 220, height: 150))),
        const SizedBox(height: 32),
      ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: title, subtitle: subtitle),
      SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final ctx, final i) => _card(ctx, items[i]),
          )),
      const SizedBox(height: 32),
    ]);
  }

  Widget _card(final BuildContext context, final dynamic item) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => isStage
                    ? StageDetailPage(stageId: item.id)
                    : TeamDetailsPage(teamId: item.id))),
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(4),
        borderRadius: _Styles.horizontalCardRadius,
        child: Row(children: [
          SizedBox(
              width: 90,
              height: 142,
              child: OptimizedCachedImage(
                  imageUrl: item.imageUrl,
                  width: 90,
                  height: 142,
                  borderRadius: 16)),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BadgeLabel(isStage ? "MEKAN" : "EKİP"),
                        const SizedBox(height: 4),
                        Text(item.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface)),
                      ]))),
        ]),
      );
}

class _PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isLoading;

  const _PlayerSection({required this.players, this.isLoading = false});

  @override
  Widget build(final BuildContext context) {
    if (isLoading)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: "Performansçılar", subtitle: "Sahnenin Yıldızları"),
        SizedBox(
            height: 190,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (final _, final __) => Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: const Column(children: [
                      Expanded(child: ShimmerCard(height: 120, width: 120)),
                      SizedBox(height: 8),
                      ShimmerLoading(height: 12, width: 80, isCircular: true)
                    ])))),
        const SizedBox(height: 32),
      ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(
          title: "Performansçılar", subtitle: "Sahnenin Yıldızları"),
      SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final ctx, final i) => GestureDetector(
              onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (final _) =>
                          PlayerDetailPage(playerId: players[i].id))),
              child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(children: [
                    Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: OptimizedCachedImage(
                                imageUrl: players[i].imageUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120))),
                    const SizedBox(height: 8),
                    Text("${players[i].firstName}\n${players[i].lastName}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface)),
                  ])),
            ),
          )),
      const SizedBox(height: 32),
    ]);
  }
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: _Styles.glassDecoration(context),
              child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(color: context.colors.onSurface),
                  decoration: InputDecoration(
                      hintText: 'Sanatın izini sür...',
                      hintStyle: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.5),
                          fontStyle: FontStyle.italic),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: context.primaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16))),
            )),
      );
}

class FilterList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const FilterList(
      {super.key, required this.selectedIndex, required this.onSelected});

  static const _filters = [
    "Tümü",
    "Etkinlikler",
    "Oyuncular",
    "Mekanlar",
    "Ekipler"
  ];
  static final _palettes = [
    [
      WebColors.darkBlueBackground,
      WebColors.darkBlueSurface,
      WebColors.darkBlueAccent
    ],
    [const Color(0xFFDC2626), const Color(0xFFB91C1C), const Color(0xFFFECACA)],
    [Colors.pink.shade500, Colors.purple.shade600, const Color(0xFF444653)],
    [
      WebColors.darkBlueSurface,
      WebColors.darkBlueAccent,
      AppDarkColors.primaryVariant
    ],
    [WebColors.success, const Color(0xFF2E7D32), const Color(0xFFA5D6A7)],
  ];

  @override
  Widget build(final BuildContext context) => SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (final _, final i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ArtisticBrushChip(
                text: _filters[i],
                isSelected: selectedIndex == i,
                colors: _palettes[i],
                onTap: () => onSelected(i))),
      ));
}

class ArtisticBrushChip extends StatefulWidget {
  final String text;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const ArtisticBrushChip(
      {super.key,
      required this.text,
      required this.isSelected,
      required this.colors,
      required this.onTap});

  @override
  State<ArtisticBrushChip> createState() => _ArtisticBrushChipState();
}

class _ArtisticBrushChipState extends State<ArtisticBrushChip>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300), vsync: this);
  late final _scale = Tween<double>(begin: 1.0, end: 0.95)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant final ArtisticBrushChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected)
      widget.isSelected ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (final _) => _ctrl.forward(),
        onTapUp: (final _) => _ctrl.reverse(),
        onTapCancel: _ctrl.reverse,
        child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 90),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(10)),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [widget.colors[0], widget.colors[1]]
                        : [
                            context.isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFF8FAFC),
                            context.isDarkMode
                                ? const Color(0xFF3C3E4A)
                                : const Color(0xFFEDF2F7)
                          ]),
                border: Border.all(
                    color: widget.isSelected
                        ? widget.colors[0].withOpacity(0.8)
                        : context.colors.onSurface.withOpacity(0.1),
                    width: widget.isSelected ? 2 : 1),
                boxShadow: _Styles.shadow(widget.isSelected, widget.colors[0]),
              ),
              child: Stack(children: [
                if (widget.isSelected)
                  Positioned.fill(
                      child: CustomPaint(
                          painter:
                              _PaintDropletPainter(colors: widget.colors))),
                Center(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                                color: widget.isSelected
                                    ? Colors.white
                                    : context.colors.onSurface.withOpacity(0.7),
                                fontWeight: widget.isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 15),
                            child: Text(widget.text)))),
              ]),
            )),
      );
}

class _PaintDropletPainter extends CustomPainter {
  final List<Color> colors;

  _PaintDropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(colors.hashCode);
    for (int i = 0; i < 8; i++) {
      paint.color = colors[rng.nextInt(colors.length)]
          .withOpacity(rng.nextDouble() * 0.2 + 0.1);
      canvas.drawOval(
          Rect.fromCircle(
              center: Offset(rng.nextDouble() * size.width,
                  rng.nextDouble() * size.height),
              radius: rng.nextDouble() * 6 + 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

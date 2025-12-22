import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/card/glass_back_bottom.dart';
import '../../../../shared/widgets/card/shimmer_card.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/pages/team_details_mobile.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// 1. DESIGN TOKENS & STYLES (TEMİZLENDİ)
// =============================================================================

class _Styles {
  static final cardRadius = BorderRadius.circular(16.0);

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
}

// =============================================================================
// 2. DATA LOGIC
// =============================================================================

class _SearchLogic {
  static List<T> filterAndPaginate<T>(final List<T>? items, final String query,
      final String Function(T) selector,
      {final int page = 0, final bool paginate = true, final int? limit}) {
    if (items == null) return [];
    final filtered = query.isEmpty
        ? items
        : items
            .where((final i) => selector(i).toLowerCase().contains(query))
            .toList();

    if (limit != null && !paginate)
      return filtered.sublist(0, math.min(limit, filtered.length));

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

  void _onSeeAll(final int filterIndex) {
    setState(() {
      _selectedFilter = filterIndex;
      _pages.updateAll((final _, final __) => 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (_scrollController.hasClients)
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
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
          page: _selectedFilter == 1 ? _pages[1]! : 0,
          paginate: _selectedFilter == 1,
          limit: _selectedFilter == 0 ? 10 : null),
      players: _SearchLogic.filterAndPaginate(rawPlayers.dataList, query,
          (final p) => '${p.firstName} ${p.lastName}',
          page: _selectedFilter == 2 ? _pages[2]! : 0,
          paginate: _selectedFilter == 2,
          limit: _selectedFilter == 0 ? 10 : null),
      stages: _SearchLogic.filterAndPaginate(
          rawStages.dataList, query, (final s) => s.name,
          page: _selectedFilter == 3 ? _pages[3]! : 0,
          paginate: _selectedFilter == 3,
          limit: _selectedFilter == 0 ? 10 : null),
      teams: _SearchLogic.filterAndPaginate(
          rawTeams.dataList, query, (final t) => t.name,
          page: _selectedFilter == 4 ? _pages[4]! : 0,
          paginate: _selectedFilter == 4,
          limit: _selectedFilter == 0 ? 10 : null),
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        backgroundColor: context.isDarkMode
            ? const Color(0xFF10141C)
            : const Color(0xFFF0F4F8),
        ambientColor: Colors.indigoAccent,
        particleColor: Colors.blueGrey.withOpacity(0.3),
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
          Row(
            children: [
              GlassBackButton(),
              const TopHeader(title: "Tablolarımız"),
            ],
          ),
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
        // 1. OYUNCULAR (PlayerHeroCard kendi loadingini yönetiyor)
        if (loading.players || data.players.isNotEmpty)
          SliverToBoxAdapter(
              child: _PlayerSection(
                  players: data.players,
                  isLoading: loading.players,
                  onSeeAll: () => _onSeeAll(2))),

        // 2. ETKİNLİKLER (ShowMosaicGallery kendi loadingini yönetiyor)
        if (loading.shows || data.shows.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: "Etkinlikler Vitrini",
                  subtitle: "Akışta Kal",
                  onTap: () => _onSeeAll(1),
                ),
                ShowMosaicGallery(
                  shows: data.shows,
                  isLoading: loading.shows,
                  direction: Axis.horizontal,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

        // 3. MEKANLAR & 4. EKİPLER (Eski yapı - değişmedi)
        if (loading.stages || data.stages.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Mekanlar",
                  subtitle: "Atmosfer",
                  items: data.stages,
                  isStage: true,
                  isLoading: loading.stages,
                  onSeeAll: () => _onSeeAll(3))),
        if (loading.teams || data.teams.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Ekipler",
                  subtitle: "Mutfak",
                  items: data.teams,
                  isStage: false,
                  isLoading: loading.teams,
                  onSeeAll: () => _onSeeAll(4))),
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
            ShowMosaicGallery(
                shows: d.shows, isLoading: l.shows, direction: Axis.vertical),
            if (d.shows.isEmpty && !l.shows)
              _buildEmptyState(msg: "Etkinlik bulunamadı"),
          ],
        2 => [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (final ctx, final i) => PlayerHeroCard(
                    isLoading: l.players,
                    player: l.players ? null : d.players[i],
                  ),
                  childCount: l.players ? 9 : d.players.length,
                ),
              ),
            ),
            if (d.players.isEmpty && !l.players)
              _buildEmptyState(msg: "Oyuncu bulunamadı"),
          ],
        3 => [
            if (l.stages)
              _GridHelpers.standardShimmer(cross: 2, ratio: 1.4)
            else
              _GridHelpers.grid(
                  d.stages,
                  (final c, final s) =>
                      _GridCards.verticalLarge(c, s as Stage, true),
                  cross: 2,
                  ratio: 1.4),
            if (d.stages.isEmpty && !l.stages)
              _buildEmptyState(msg: "Mekan bulunamadı"),
          ],
        4 => [
            if (l.teams)
              _GridHelpers.standardShimmer(cross: 2, ratio: 1.4)
            else
              _GridHelpers.grid(
                  d.teams,
                  (final c, final t) =>
                      _GridCards.verticalLarge(c, t as Team, false),
                  cross: 2,
                  ratio: 1.4),
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
// YARDIMCI WIDGETLAR (ÖZEL SECTIONLAR)
// =============================================================================

class _PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isLoading;
  final VoidCallback? onSeeAll;

  const _PlayerSection(
      {required this.players, this.isLoading = false, this.onSeeAll});

  @override
  Widget build(final BuildContext context) {
    // Yükleniyorsa 6 sahte veri
    final itemCount = isLoading ? 6 : players.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
          title: "Performansçılar",
          subtitle: "Sahnenin Yıldızları",
          onTap: onSeeAll),
      // Expanded kullanıldığı için Yükseklik Şart
      SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final ctx, final i) => PlayerHeroCard(
              isLoading: isLoading,
              player: isLoading ? null : players[i],
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
    [
      Colors.orange.shade500,
      Colors.deepOrange.shade600,
      const Color(0xFFFFB74D)
    ],
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
}

class _GridCards {
  static Widget verticalLarge(
          final BuildContext context, final dynamic item, final bool isStage) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => isStage
                    ? StageDetailPage(stageId: item.id)
                    : TeamDetailsPage(teamId: item.id))),
        child: LayoutBuilder(
          builder: (final context, final constraints) => Stack(
            children: [
              Positioned.fill(
                child: OptimizedCachedImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isStage
                          ? [
                              Colors.cyan.withOpacity(0.15),
                              Colors.blue.withOpacity(0.25),
                              Colors.indigo.withOpacity(0.35),
                              Colors.black.withOpacity(0.85),
                            ]
                          : [
                              Colors.orange.withOpacity(0.15),
                              Colors.deepOrange.withOpacity(0.25),
                              Colors.red.withOpacity(0.35),
                              Colors.black.withOpacity(0.85),
                            ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotPatternPainter(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.92),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isStage
                                ? [
                                    Colors.cyan.shade400,
                                    Colors.blue.shade600,
                                  ]
                                : [
                                    Colors.orange.shade400,
                                    Colors.deepOrange.shade600,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (isStage ? Colors.cyan : Colors.orange)
                                  .withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStage ? Icons.location_on : Icons.group,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isStage ? "MEKAN" : "EKİP",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: _CornerLinePainter(
                    color: (isStage ? Colors.cyan : Colors.orange)
                        .withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HorizontalListSection extends StatelessWidget {
  final String title, subtitle;
  final List<dynamic> items;
  final bool isStage, isLoading;
  final VoidCallback? onSeeAll;

  const _HorizontalListSection(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.isStage,
      this.isLoading = false,
      this.onSeeAll});

  @override
  Widget build(final BuildContext context) {
    if (isLoading)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: title, subtitle: subtitle, onTap: onSeeAll),
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
      SectionHeader(title: title, subtitle: subtitle, onTap: onSeeAll),
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
        padding: EdgeInsets.zero,
        borderRadius: _Styles.cardRadius,
        child: LayoutBuilder(
          builder: (final context, final constraints) => Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 90,
                child: OptimizedCachedImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 90,
                top: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isStage
                          ? [
                              Colors.cyan.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05),
                            ]
                          : [
                              Colors.orange.withOpacity(0.1),
                              Colors.deepOrange.withOpacity(0.05),
                            ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isStage
                                ? [
                                    Colors.cyan.shade400,
                                    Colors.blue.shade600,
                                  ]
                                : [
                                    Colors.orange.shade400,
                                    Colors.deepOrange.shade600,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: (isStage ? Colors.cyan : Colors.orange)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStage ? Icons.location_on : Icons.group,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isStage ? "MEKAN" : "EKİP",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(
                      color: (isStage ? Colors.cyan : Colors.orange)
                          .withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isStage ? Icons.place : Icons.star,
                    color: (isStage ? Colors.cyan : Colors.orange).shade300,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DotPatternPainter extends CustomPainter {
  final Color color;

  _DotPatternPainter({required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const spacing = 15.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

class _CornerLinePainter extends CustomPainter {
  final Color color;

  _CornerLinePainter({required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

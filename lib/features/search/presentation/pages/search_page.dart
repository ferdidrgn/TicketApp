import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- PROJE IMPORTLARI ---
import 'package:ticketapp/core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_extension.dart';
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
// 1. MERKEZİ STİL VE SABİTLER (DESIGN TOKENS)
// =============================================================================

class _Styles {
  static const double cardRadiusValue = 16.0;
  static const double shimmerRadius = 20.0;

  static BorderRadius get cardRadius => BorderRadius.circular(cardRadiusValue);

  static BorderRadius get mosaicRadius => BorderRadius.circular(16);

  static const BorderRadius horizontalCardRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    bottomRight: Radius.circular(20),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
  );

  static List<BoxShadow> shadow(final bool isSelected, final Color color) {
    if (isSelected) {
      return [
        BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 3)),
        BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, -2)),
      ];
    }
    return [
      BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2))
    ];
  }

  static BoxDecoration glassDecoration(final BuildContext context) =>
      BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.onSurface.withOpacity(0.1)),
      );

  static LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
    stops: const [0.5, 1.0],
  );
}

// =============================================================================
// 2. LOGIC & DATA HELPERS (MANTIK KATMANI)
// =============================================================================

class _SearchLogic {
  static List<T> filterAndPaginate<T>(
    final List<T>? items,
    final String query,
    final String Function(T) selector, {
    final int page = 0,
    final int limit = 20,
    final bool paginate = true,
  }) {
    if (items == null) return [];

    // 1. Filtreleme
    final filtered = query.isEmpty
        ? items
        : items
            .where((final item) => selector(item).toLowerCase().contains(query))
            .toList();

    // 2. Sayfalama (Eğer isteniyorsa)
    if (!paginate) return filtered;

    final start = page * limit;
    if (start >= filtered.length) return [];
    final end = math.min(start + limit, filtered.length);

    return filtered.sublist(start, end);
  }

  static int totalCount<T>(final List<T>? items, final String query,
      final String Function(T) selector) {
    if (items == null) return 0;
    if (query.isEmpty) return items.length;
    return items
        .where((final item) => selector(item).toLowerCase().contains(query))
        .length;
  }
}

// =============================================================================
// 3. UI COMPONENTS (ATOMİK WIDGETLAR)
// =============================================================================

/// Ortak Kart Konteyneri (Tüm kartlar bunu kullanır)
class _BaseCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const _BaseCardContainer({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.width,
    this.margin,
    this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: borderRadius ?? _Styles.cardRadius,
          boxShadow: _Styles.shadow(false, Colors.black),
        ),
        clipBehavior: Clip.antiAlias,
        // Taşan içeriği keser
        child: child,
      ),
    );
  }
}

/// Etiket (Badge) Widget'ı
class _BadgeLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _BadgeLabel(this.text, {this.isDark = false});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? context.primaryColor.withOpacity(0.9)
            : context.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}

// =============================================================================
// 4. MAIN PAGE & STATE
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // State variables
  bool _isInitialized = false;
  bool _loadingMore = false;
  int _selectedFilter = 0;

  // Pagination counters
  final Map<int, int> _pages = {
    1: 0,
    2: 0,
    3: 0,
    4: 0
  }; // 1:Shows, 2:Players, 3:Stages, 4:Teams
  static const int _limit = 20;

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
    // Paralel veri yükleme
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
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = ref.read(searchQueryProvider);

      // Dinamik sayfa artırımı
      void tryIncrement(final int type, final int total) {
        if (((_pages[type] ?? 0) + 1) * _limit < total) {
          _pages[type] = (_pages[type] ?? 0) + 1;
        }
      }

      setState(() {
        switch (_selectedFilter) {
          case 1:
            tryIncrement(
                1,
                _SearchLogic.totalCount(ref.read(showProvider).dataList, query,
                    (final s) => s.name));
          case 2:
            tryIncrement(
                2,
                _SearchLogic.totalCount(ref.read(playerProvider).dataList,
                    query, (final p) => '${p.firstName} ${p.lastName}'));
          case 3:
            tryIncrement(
                3,
                _SearchLogic.totalCount(ref.read(stageProvider).dataList, query,
                    (final s) => s.name));
          case 4:
            tryIncrement(
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

    // Veri kaynaklarını hazırla
    final rawShows = ref.watch(showProvider);
    final rawPlayers = ref.watch(playerProvider);
    final rawStages = ref.watch(stageProvider);
    final rawTeams = ref.watch(teamProvider);

    final loading = (
      shows: rawShows.isLoading || !_isInitialized,
      players: rawPlayers.isLoading || !_isInitialized,
      stages: rawStages.isLoading || !_isInitialized,
      teams: rawTeams.isLoading || !_isInitialized,
    );

    // Verileri filtrele ve sayfalara böl
    final data = (
      shows: _SearchLogic.filterAndPaginate(
          rawShows.dataList, query, (final s) => s.name,
          page: _selectedFilter == 0 ? 0 : _pages[1]!,
          paginate: _selectedFilter != 0),
      players: _SearchLogic.filterAndPaginate(rawPlayers.dataList, query,
          (final p) => '${p.firstName} ${p.lastName}',
          page: _selectedFilter == 0 ? 0 : _pages[2]!,
          paginate: _selectedFilter != 0),
      stages: _SearchLogic.filterAndPaginate(
          rawStages.dataList, query, (final s) => s.name,
          page: _selectedFilter == 0 ? 0 : _pages[3]!,
          paginate: _selectedFilter != 0),
      teams: _SearchLogic.filterAndPaginate(
          rawTeams.dataList, query, (final t) => t.name,
          page: _selectedFilter == 0 ? 0 : _pages[4]!,
          paginate: _selectedFilter != 0),
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
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _ThemeBackground()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(query)),
                SliverToBoxAdapter(child: _buildFilterList()),

                // İçerik Oluşturucu
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
    );
  }

  Widget _buildHeader(final String query) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopHeader(title: "Tablolarımız"),
            const SizedBox(height: 20),
            GlassSearchBar(
              controller: _textController,
              onChanged: (final val) => ref
                  .read(searchQueryProvider.notifier)
                  .setQuery(val.toLowerCase()),
            ),
          ],
        ),
      );

  Widget _buildFilterList() => FilterList(
        selectedIndex: _selectedFilter,
        onSelected: (final index) {
          setState(() {
            _selectedFilter = index;
            _pages.updateAll((final key, final val) => 0); // Sayfaları sıfırla
          });
          // Scroll to top
          WidgetsBinding.instance.addPostFrameCallback((final _) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            }
          });
        },
      );

  // --- SECTIONS BUILDERS ---

  List<Widget> _buildAllSections(
    final ({bool players, bool shows, bool stages, bool teams}) loading,
    final ({
      List<Player> players,
      List<Show> shows,
      List<Stage> stages,
      List<Team> teams
    }) data,
  ) {
    return [
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
  }

// _SearchPageState sınıfının içinde bu metodu güncelle:

  List<Widget> _buildFilteredSection(
    ({bool players, bool shows, bool stages, bool teams}) loading,
    ({
      List<Player> players,
      List<Show> shows,
      List<Stage> stages,
      List<Team> teams
    }) data,
  ) {
    // 1. Standart Grid Helper (Oyuncu, Mekan, Ekip için)
    Widget standardGrid(
        List<dynamic> items, Widget Function(BuildContext, dynamic) builder,
        {int cross = 2, double ratio = 0.8}) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: ratio),
          delegate: SliverChildBuilderDelegate(
              (ctx, i) => builder(ctx, items[i]),
              childCount: items.length),
        ),
      );
    }

    // 2. Standart Shimmer Helper
    Widget standardShimmer({int cross = 2, double ratio = 0.8}) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: ratio),
          delegate: SliverChildBuilderDelegate(
              (_, __) => const ShimmerLoading(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16),
              childCount: 6),
        ),
      );
    }

    // 3. Mozaik Shimmer (Sadece Etkinlikler için)
    Widget mosaicShimmer() => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
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
                  ],
                ),
              ),
              childCount: 4,
            ),
          ),
        );

    // KONTROL MANTIĞI
    return switch (_selectedFilter) {
      // CASE 1: ETKİNLİKLER (MOZAİK / KAOTİK TASARIM)
      1 => [
          if (loading.shows)
            mosaicShimmer()
          else
            _ChaoticMosaicBuilder(
                items: data.shows,
                builder: (c, s, h) =>
                    _GridCards.showMosaic(c, s as Show, height: h)),
          if (data.shows.isEmpty && !loading.shows)
            _buildEmptyState(msg: "Etkinlik bulunamadı"),
        ],

      // CASE 2: OYUNCULAR (STANDART GRID - 3 Sütun)
      2 => [
          if (loading.players)
            standardShimmer(cross: 3, ratio: 0.7)
          else
            standardGrid(
                data.players, (c, p) => _GridCards.player(c, p as Player),
                cross: 3, ratio: 0.7),
          if (data.players.isEmpty && !loading.players)
            _buildEmptyState(msg: "Oyuncu bulunamadı"),
        ],

      // CASE 3: MEKANLAR (STANDART GRID - 2 Sütun, Yatay)
      3 => [
          if (loading.stages)
            standardShimmer(ratio: 1.2)
          else
            standardGrid(
                data.stages, (c, s) => _GridCards.vertical(c, s as Stage, true),
                ratio: 1.2),
          if (data.stages.isEmpty && !loading.stages)
            _buildEmptyState(msg: "Mekan bulunamadı"),
        ],

      // CASE 4: EKİPLER (STANDART GRID - 2 Sütun, Yatay)
      4 => [
          if (loading.teams)
            standardShimmer(ratio: 1.2)
          else
            standardGrid(
                data.teams, (c, t) => _GridCards.vertical(c, t as Team, false),
                ratio: 1.2),
          if (data.teams.isEmpty && !loading.teams)
            _buildEmptyState(msg: "Ekip bulunamadı"),
        ],
      _ => [],
    };
  }

  Widget _buildEmptyState({final String? msg}) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 80, color: context.colors.onSurface.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(msg ?? "Aradığınız kriterlere uygun\nsonuç bulunamadı.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      );
}

class _ChaoticMosaicBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, double) builder;

  const _ChaoticMosaicBuilder({required this.items, required this.builder});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Listeyi 3'erli gruplar (chunks) halinde işle
            final chunkIndex = index * 3;
            if (chunkIndex >= items.length) return null;

            // Bu gruptaki itemları al (güvenli şekilde)
            final item1 = items[chunkIndex];
            final item2 =
                (chunkIndex + 1 < items.length) ? items[chunkIndex + 1] : null;
            final item3 =
                (chunkIndex + 2 < items.length) ? items[chunkIndex + 2] : null;

            // Desen Tipi: Çift indeksler Tip A (Sol Büyük), Tek indeksler Tip B (Sağ Büyük)
            final isTypeA = index % 2 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16), // Gruplar arası boşluk
              child: isTypeA
                  ? _buildTypeA(context, item1, item2, item3) // Sol Büyük
                  : _buildTypeB(context, item1, item2, item3), // Sağ Büyük
            );
          },
          childCount: (items.length / 3).ceil(),
        ),
      ),
    );
  }

  // TİP A: Sol tarafta devasa tek kart, Sağda iki küçük kart
  Widget _buildTypeA(BuildContext context, T item1, T? item2, T? item3) {
    return IntrinsicHeight(
      // Yükseklikleri eşitlemek veya kontrol etmek için
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL: Büyük Kart (Girintili efekt için biraz aşağı itilmiş)
          Expanded(
            flex: 10,
            child: Transform.translate(
              offset: const Offset(0, 10), // Modern sarkma efekti
              child: builder(context, item1, 320),
            ),
          ),
          const SizedBox(width: 12),
          // SAĞ: Varsa 2 tane alt alta küçük kart
          Expanded(
            flex: 9, // Hafif asimetri (10'a 9 oran)
            child: Column(
              children: [
                if (item2 != null)
                  SizedBox(height: 150, child: builder(context, item2, 150)),
                if (item3 != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(height: 150, child: builder(context, item3, 150)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TİP B: Solda iki küçük kart, Sağda devasa tek kart
  Widget _buildTypeB(BuildContext context, T item1, T? item2, T? item3) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL: Küçük kartlar sütunu
          Expanded(
            flex: 9,
            child: Column(
              children: [
                SizedBox(height: 150, child: builder(context, item1, 150)),
                if (item2 != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(height: 150, child: builder(context, item2, 150)),
                ]
              ],
            ),
          ),
          const SizedBox(width: 12),
          // SAĞ: Büyük Kart (Burada item3 varsa onu büyük yapıyoruz, yoksa yer tutucu)
          if (item3 != null)
            Expanded(
              flex: 10,
              child: Transform.translate(
                offset: const Offset(0, -10), // Bu sefer yukarı çıkıntı efekti
                child: builder(context, item3, 320),
              ),
            )
          else
            const Spacer(flex: 10),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. CARD IMPLEMENTATIONS (KART TASARIMLARI)
// =============================================================================

class _GridCards {
  // 1. MOZAİK İÇİN (Yükseklik alır)
  static Widget showMosaic(BuildContext context, Show show,
          {required double height}) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ShowDetailPage(showId: show.id))),
        width: double.infinity,
        child: SizedBox(
          // Yüksekliği zorlamak için
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
              Container(
                  decoration: BoxDecoration(gradient: _Styles.darkGradient)),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BadgeLabel("ETKİNLİK", isDark: true),
                      const SizedBox(height: 8),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2)),
                    ]),
              ),
            ],
          ),
        ),
      );

  // 2. STANDART GRID İÇİN (Yükseklik almaz, Aspect Ratio'ya uyar)
  static Widget player(BuildContext context, Player player) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PlayerDetailPage(playerId: player.id))),
        child: Column(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OptimizedCachedImage(
                            imageUrl: player.imageUrl, fit: BoxFit.cover)))),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  const _BadgeLabel("OYUNCU"),
                  const SizedBox(height: 2),
                  Text(player.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface)),
                  Text(player.lastName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.colors.onSurface.withOpacity(0.8))),
                ],
              ),
            ),
          ],
        ),
      );

  // 3. STANDART GRID İÇİN (Mekan ve Ekip)
  static Widget vertical(BuildContext context, dynamic item, bool isStage) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => isStage
                    ? StageDetailPage(stageId: item.id)
                    : TeamDetailsPage(teamId: item.id))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7)
                ],
                        stops: const [
                  0.6,
                  1.0
                ]))),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BadgeLabel(isStage ? "MEKAN" : "EKİP"),
                    const SizedBox(height: 6),
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ]),
            ),
          ],
        ),
      );
} // =============================================================================
// 6. SECTIONS (YATAY LİSTELER)
// =============================================================================

class _HorizontalMosaicSection extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;

  const _HorizontalMosaicSection({required this.shows, this.isLoading = false});

  @override
  Widget build(final BuildContext context) {
    if (isLoading) return _shimmer();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
          SizedBox(
              height: 340,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (shows.length / 2).ceil(),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (final context, final index) {
                  final show1 =
                      (index * 2 < shows.length) ? shows[index * 2] : null;
                  final show2 = (index * 2 + 1 < shows.length)
                      ? shows[index * 2 + 1]
                      : null;
                  if (show1 == null) return const SizedBox();

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
                        Expanded(flex: flexes.$1, child: _card(context, show1)),
                        const SizedBox(height: 10),
                        show2 != null
                            ? Expanded(
                                flex: flexes.$2, child: _card(context, show2))
                            : Spacer(flex: flexes.$2),
                      ]));
                },
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _card(final BuildContext context, final Show show) =>
      _BaseCardContainer(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => ShowDetailPage(showId: show.id))),
        borderRadius: _Styles.mosaicRadius,
        child: Stack(fit: StackFit.expand, children: [
          OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: _Styles.darkGradient)),
          Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BadgeLabel("ETKİNLİK", isDark: true),
                    const SizedBox(height: 4),
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ])),
        ]),
      );

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
                itemBuilder: (final _, final index) {
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
                            child: const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 16)),
                        const SizedBox(height: 10),
                        Expanded(
                            flex: flexes.$2,
                            child: const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 16)),
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
            itemBuilder: (final context, final index) =>
                _card(context, items[index]),
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
            itemBuilder: (final context, final index) => GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) =>
                          PlayerDetailPage(playerId: players[index].id))),
              child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(children: [
                    Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: OptimizedCachedImage(
                                imageUrl: players[index].imageUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120))),
                    const SizedBox(height: 8),
                    Text(
                        "${players[index].firstName}\n${players[index].lastName}",
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

// =============================================================================
// 7. UTILITY WIDGETS (Background, Filters, SearchBar)
// =============================================================================

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
                  prefixIcon:
                      Icon(Icons.search_rounded, color: context.primaryColor),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
            ),
          ),
        ),
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
  late final _controller = AnimationController(
      duration: const Duration(milliseconds: 300), vsync: this);
  late final _scale = Tween<double>(begin: 1.0, end: 0.95)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (widget.isSelected) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant final ArtisticBrushChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected)
      widget.isSelected ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (final _) => _controller.forward(),
        onTapUp: (final _) => _controller.reverse(),
        onTapCancel: _controller.reverse,
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

class _ThemeBackground extends StatelessWidget {
  const _ThemeBackground();

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              context.scaffoldBackgroundColor,
              context.colors.surface.withOpacity(0.5)
            ])),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent)),
      );
}

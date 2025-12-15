import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/players/presentation/widgets/players_card.dart';
import '../../../../core/services/pagination_controller.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/navigation/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/custom_search.dart';
import '../../../../shared/widgets/footers/custom_category_card.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/pages/team_details_mobile.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/search_query_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  PaginationController<Show>? showsPagination;
  PaginationController<Player>? playersPagination;
  PaginationController<Stage>? stagesPagination;
  PaginationController<Team>? teamsPagination;

  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isInitialized = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Tümünü Keşfet', 'icon': Icons.explore, 'gradient': 0},
    {'title': 'Trendler', 'icon': Icons.trending_up, 'gradient': 1},
    {'title': 'Tiyatro', 'icon': Icons.theater_comedy, 'gradient': 2},
    {'title': 'Konser/Müzik', 'icon': Icons.library_music, 'gradient': 3},
    {'title': 'Stand Up', 'icon': Icons.event_seat_rounded, 'gradient': 4},
    {'title': 'Festival', 'icon': Icons.festival_rounded, 'gradient': 5},
    {'title': 'Sinema', 'icon': Icons.movie_filter_rounded, 'gradient': 6},
    {'title': 'Çocuk', 'icon': Icons.family_restroom, 'gradient': 7},
    {'title': 'Spor', 'icon': Icons.sports_baseball, 'gradient': 8},
    {'title': 'Etkinlik', 'icon': Icons.event, 'gradient': 9},
  ];

  final List<List<Color>> _categoryGradients = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Mor
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Turuncu
    [const Color(0xFF10B981), const Color(0xFF059669)], // Yeşil
    [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Mavi
    [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Kırmızı
    [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Mor ton
    [const Color(0xFFF97316), const Color(0xFFEA580C)], // Turuncu ton
    [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Camgöbeği
    [const Color(0xFF84CC16), const Color(0xFF65A30D)], // Açık yeşil
    [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pembe
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance
        .addPostFrameCallback((final _) => _initializeData());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _initializePaginationControllers() {
    showsPagination = _createPagination(ref.read(showProvider).dataList);
    playersPagination = _createPagination(ref.read(playerProvider).dataList);
    stagesPagination = _createPagination(ref.read(stageProvider).dataList);
    teamsPagination = _createPagination(ref.read(teamProvider).dataList);
  }

  PaginationController<T>? _createPagination<T>(final List<T>? list) {
    if (list == null) return null;
    return PaginationController(allItems: list, itemsPerPage: 20);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) _loadMoreData();
  }

  void _loadMoreData() => setState(() {
        showsPagination?.loadMoreItems();
        playersPagination?.loadMoreItems();
        stagesPagination?.loadMoreItems();
        teamsPagination?.loadMoreItems();
      });

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
      ref.read(searchQueryProvider.notifier).setQuery("");
    });

    // Eğer listeler boşsa yükle
    try {
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

      _initializePaginationControllers();
      _resetPagination();

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Data loading error: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 300),
          () => setState(() => _isLoading = false));
    }
  }

  void _onSearchChanged(final String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).setQuery(query.toLowerCase());
      // Reset pagination when search query changes
      _resetPagination();
    });
  }

  void _resetPagination() => setState(() {
        showsPagination?.reset();
        playersPagination?.reset();
        stagesPagination?.reset();
        teamsPagination?.reset();
        _loadMoreData();
      });

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final isAnyLoading = showState.isLoading ||
        playerState.isLoading ||
        stageState.isLoading ||
        teamState.isLoading ||
        _isLoading;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Keşfet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        elevation: 0,
        backgroundColor: context.colors.surface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDarkMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.background.withOpacity(0.98),
                    context.colors.background,
                    context.colors.surface.withOpacity(0.8),
                  ],
                )
              : null,
          color: !context.isDarkMode ? context.colors.background : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arama Çubuğu
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: CustomSearchBar(
                  onSearchChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 20),

              // Ana İçerik
              Expanded(
                child: isAnyLoading
                    ? _buildLoadingView()
                    : _buildSearchResults(searchQuery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerSection('Popüler Etkinlikler', isLarge: true),
            const SizedBox(height: 24),
            _buildShimmerSection('Mekanlar'),
            const SizedBox(height: 24),
            _buildShimmerSection('Kategoriler', isGrid: true),
          ],
        ),
      );

  Widget _buildShimmerSection(final String title,
      {final bool isLarge = false, final bool isGrid = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık Shimmer
        Container(
          width: 120,
          height: 24,
          margin: const EdgeInsets.only(bottom: 12, left: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.colors.surface.withOpacity(0.6),
          ),
        ),

        // İçerik Shimmer
        if (isGrid)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 6,
            itemBuilder: (final _, final __) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.colors.surface.withOpacity(0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const ShimmerLoading(),
              ),
            ),
          )
        else
          SizedBox(
            height: isLarge ? 240 : 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (final _, final index) => Container(
                width: isLarge ? 160 : 140,
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: context.colors.surface.withOpacity(0.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const ShimmerLoading(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(final String query) {
    final List<Show>? filteredShows =
        _filterItems(showsPagination?.currentItems, (final s) => s.name, query);
    final List<Player>? filteredPlayers = _filterItems(
        playersPagination?.currentItems,
        (final p) => '${p.firstName} ${p.lastName}',
        query);
    final List<Stage>? filteredStages = _filterItems(
        stagesPagination?.currentItems, (final s) => s.name, query);
    final List<Team>? filteredTeams =
        _filterItems(teamsPagination?.currentItems, (final t) => t.name, query);
    final filteredCategories = _categories
        .where((final c) =>
            query.isEmpty ||
            (c['title']! as String).toLowerCase().contains(query))
        .toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (final scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreData();
        }
        return true;
      },
      child: RefreshIndicator(
        color: context.primaryColor,
        backgroundColor: context.colors.surface,
        onRefresh: _initializeData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 8),

            // Eşleşen Etkinlikler
            if (filteredShows?.isNotEmpty ?? false)
              _buildSection(
                '🎭 Eşleşen Etkinlikler',
                filteredShows!,
                _buildShowCard,
                showAllAction: _buildShowAllButton('Etkinlikler'),
              ),

            // Oyuncular
            if (filteredPlayers?.isNotEmpty ?? false)
              _buildPlayerSection(filteredPlayers!),

            // Mekanlar
            if (filteredStages?.isNotEmpty ?? false)
              _buildSection(
                '🏛️ Gösteri Mekanları',
                filteredStages!,
                _buildVenueCard,
                showAllAction: _buildShowAllButton('Mekanlar'),
              ),

            // Ekipler
            if (filteredTeams?.isNotEmpty ?? false)
              _buildSection(
                '👥 Ekipler',
                filteredTeams!,
                _buildTeamCard,
                showAllAction: _buildShowAllButton('Ekipler'),
              ),

            // Kategoriler
            if (filteredCategories.isNotEmpty)
              _buildCategorySection(filteredCategories),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<T>? _filterItems<T>(final List<T>? items,
      final String Function(T) selector, final String query) {
    if (items == null) return null;
    if (query.isEmpty) return items;
    return items
        .where((final item) => selector(item).toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSection<T>(
    final String title,
    final List<T> items,
    final Widget Function(BuildContext, T) itemBuilder, {
    final Widget? showAllAction,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Tümünü Gör
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                ),
                if (showAllAction != null) showAllAction,
              ],
            ),
          ),

          const SizedBox(height: 8),

          // İçerik Listesi
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              padding: const EdgeInsets.only(left: 4, right: 16),
              itemBuilder: (final context, final index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: itemBuilder(context, items[index]),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      );

  Widget _buildShowCard(final BuildContext context, final Show show) =>
      ShowCard(
        key: ValueKey(show.id),
        gameName: show.name,
        imageUrl: show.imageUrl,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (final _) => ShowDetailPage(showId: show.id),
          ),
        ),
      );

  Widget _buildVenueCard(final BuildContext context, final Stage stage) =>
      CustomStageCard(
        text: stage.name,
        imageUrl: stage.imageUrl,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (final _) => StageDetailPage(stageId: stage.id),
          ),
        ),
      );

  Widget _buildTeamCard(final BuildContext context, final Team team) =>
      ShowCard(
        gameName: team.name,
        imageUrl: team.imageUrl,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (final _) => TeamDetailsPage(teamId: team.id),
          ),
        ),
      );

  Widget _buildShowAllButton(final String type) => TextButton(
        onPressed: () => BottomNavBar.of(context)?.changeTabWithCategory(1, ""),
        style: TextButton.styleFrom(
          foregroundColor: context.appGradient(isActive: true).first,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tümünü Gör',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.appGradient(isActive: true).first,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: context.appGradient(isActive: true).first,
            ),
          ],
        ),
      );

  Widget _buildPlayerSection(final List<Player> players) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayersCard(
            title: "🎬 Oyuncular",
            players: players,
            onPlayerTap: (final id) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final _) => PlayerDetailPage(playerId: id),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );

  Widget _buildCategorySection(final List<Map<String, dynamic>> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            '📂 Kategoriler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: categories.length,
          itemBuilder: (final context, final index) {
            final category = categories[index];
            final gradientIndex = category['gradient'] as int;
            final gradient =
                _categoryGradients[gradientIndex % _categoryGradients.length];

            return CustomCategoryCard(
              title: category['title'] as String,
              icon: category['icon'] as IconData,
              gradient: gradient,
              onTap: () {
                // Kategoriye tıklama işlemi
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category['title']} kategorisi seçildi'),
                    backgroundColor: context.primaryColor,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

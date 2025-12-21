import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

// Kendi proje importlarınızın yollarını koruyun
import 'package:ticketapp/core/theme/app_colors.dart';
import '../../../../core/services/pagination_controller.dart';
import '../../../../core/theme/theme_context_extension.dart';
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
// SHIMMER WIDGETS
// =============================================================================

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isCircular;

  const ShimmerLoading({
    super.key,
    this.height = 190.0,
    this.width = 130.0,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(final BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor:
          context.isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isCircular
              ? BorderRadius.circular(height / 2)
              : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final bool showTextLine;

  const ShimmerCard({
    super.key,
    this.width = 220,
    this.height = 150,
    this.showTextLine = true,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ShimmerLoading(
              height: height - (showTextLine ? 40 : 0),
              width: width,
              borderRadius: 16,
            ),
          ),
          if (showTextLine)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(height: 10, width: 60, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerLoading(
                      height: 14, width: width - 40, borderRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool isCircular;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: isCircular
          ? BorderRadius.circular((height ?? width ?? 50) / 2)
          : BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ShimmerLoading(
            width: width ?? 100.0,
            height: height ?? 100.0,
            borderRadius: borderRadius,
            isCircular: isCircular,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : Colors.grey[200]!.withOpacity(0.5),
              borderRadius: isCircular
                  ? BorderRadius.circular((height ?? width ?? 50) / 2)
                  : BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: Icon(
                Icons.photo_outlined,
                color:
                    context.isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                size: (width ?? height ?? 40) / 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// MAIN SEARCH PAGE
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // Pagination Controllers
  PaginationController<Show>? showsPagination;
  PaginationController<Player>? playersPagination;
  PaginationController<Stage>? stagesPagination;
  PaginationController<Team>? teamsPagination;

  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;
  bool _isInitialized = false;

  // 0: Tümü, 1: Etkinlik, 2: Oyuncu, 3: Mekan, 4: Ekip
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textEditingController.dispose();
    super.dispose();
  }

  // --- DATA LOGIC ---
  Future<void> _initializeData() async {
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

    _initializePaginationControllers();
    setState(() => _isInitialized = true);
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

  void _onSearchChanged(final String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).setQuery(query.toLowerCase());
      setState(() {
        showsPagination?.reset();
        playersPagination?.reset();
        stagesPagination?.reset();
        teamsPagination?.reset();
      });
    });
  }

  List<T>? _filterItems<T>(final List<T>? items,
      final String Function(T) selector, final String query) {
    if (items == null) return null;
    if (query.isEmpty) return items;
    return items
        .where((final item) => selector(item).toLowerCase().contains(query))
        .toList();
  }

  // --- UI BUILD ---
  @override
  Widget build(final BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);

    final bool showsLoading = showState.isLoading || !_isInitialized;
    final bool playersLoading = playerState.isLoading || !_isInitialized;
    final bool stagesLoading = stageState.isLoading || !_isInitialized;
    final bool teamsLoading = teamState.isLoading || !_isInitialized;

    final shows = _filterItems(showState.dataList, (s) => s.name, searchQuery);
    final players = _filterItems(playerState.dataList,
        (p) => '${p.firstName} ${p.lastName}', searchQuery);
    final stages =
        _filterItems(stageState.dataList, (s) => s.name, searchQuery);
    final teams = _filterItems(teamState.dataList, (t) => t.name, searchQuery);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: ThemeBackground()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ArtisticTitle(),
                        const SizedBox(height: 20),
                        GlassSearchBar(
                          controller: _textEditingController,
                          onChanged: _onSearchChanged,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. FILTERS
                SliverToBoxAdapter(
                  child: FilterList(
                      selectedIndex: _selectedFilterIndex,
                      onSelected: (index) =>
                          setState(() => _selectedFilterIndex = index)),
                ),

                // 3. CONTENT
                // OYUNCULAR
                if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 2))
                  if (playersLoading || (players?.isEmpty ?? true))
                    SliverToBoxAdapter(
                      child: PlayerSection(players: const [], isLoading: true),
                    )
                  else if (players?.isNotEmpty ?? false)
                    SliverToBoxAdapter(
                      child: PlayerSection(players: players!),
                    ),

                // ETKİNLİKLER (GİRİFT / İÇ İÇE MOZAİK)
                if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 1))
                  if (showsLoading || (shows?.isEmpty ?? true))
                    const HorizontalMosaicSection(shows: [], isLoading: true)
                  else if (shows?.isNotEmpty ?? false)
                    HorizontalMosaicSection(shows: shows!),

                // MEKANLAR
                if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 3))
                  SliverToBoxAdapter(
                    child: HorizontalListSection(
                      title: "Mekanlar",
                      subtitle: "Atmosfer",
                      items: stages ?? [],
                      isStage: true,
                      isLoading: stagesLoading,
                    ),
                  ),

                // EKİPLER
                if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 4))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: HorizontalListSection(
                        title: "Ekipler",
                        subtitle: "Mutfak",
                        items: teams ?? [],
                        isStage: false,
                        isLoading: teamsLoading,
                      ),
                    ),
                  ),

                // EMPTY STATE
                if (!showsLoading &&
                    !playersLoading &&
                    !stagesLoading &&
                    !teamsLoading &&
                    (shows?.isEmpty ?? true) &&
                    (players?.isEmpty ?? true) &&
                    (stages?.isEmpty ?? true) &&
                    (teams?.isEmpty ?? true))
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: context.colors.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Sanat eseri bulunamadı...",
                            style: TextStyle(
                              fontSize: 16,
                              color: context.colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REFACTORED MOSAIC SECTION (GİRİFT MOZAİK)
// =============================================================================

class HorizontalMosaicSection extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;

  const HorizontalMosaicSection({
    super.key,
    required this.shows,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildMosaicShimmer(context);
    }

    final int columnCount = (shows.length / 2).ceil();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: "Etkinlikler Vitrini",
            subtitle: "Akışta Kal",
          ),
          SizedBox(
            height: 340, // Toplam yükseklik
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: columnCount,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final int firstIndex = index * 2;
                final int secondIndex = firstIndex + 1;

                final Show? show1 =
                    firstIndex < shows.length ? shows[firstIndex] : null;
                final Show? show2 =
                    secondIndex < shows.length ? shows[secondIndex] : null;

                if (show1 == null) return const SizedBox();

                // --- GİRİFT (KARMAŞIK) MOZAİK MANTIĞI ---
                // 4 Adımlı bir desen kullanarak kartların birleşme noktasını
                // sürekli değiştiriyoruz. Bu bir dalga/karmaşa etkisi yaratır.
                // Desen:
                // 0: Çok Üst Ağır (Flex 5:2) -> Üst kart büyük
                // 1: Orta Alt Ağır (Flex 3:4) -> Alt kart biraz büyük
                // 2: Çok Alt Ağır (Flex 2:5) -> Alt kart çok büyük
                // 3: Orta Üst Ağır (Flex 4:3) -> Üst kart biraz büyük

                int flex1, flex2;
                final int patternStep = index % 4;

                switch (patternStep) {
                  case 0: // Üst çok geniş
                    flex1 = 5;
                    flex2 = 2;
                    break;
                  case 1: // Alt biraz geniş
                    flex1 = 3;
                    flex2 = 4;
                    break;
                  case 2: // Alt çok geniş
                    flex1 = 2;
                    flex2 = 5;
                    break;
                  case 3: // Üst biraz geniş
                    flex1 = 4;
                    flex2 = 3;
                    break;
                  default: // Eşit (olur da pattern şaşarsa)
                    flex1 = 1;
                    flex2 = 1;
                }

                return Container(
                  width: 155, // Biraz daha daraltarak "sıkışık/içe içe" hissi
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      // Üst Kart
                      Expanded(
                        flex: flex1,
                        child: _MosaicShowCard(
                          show: show1,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ShowDetailPage(showId: show1.id)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10), // Boşluk biraz daha az

                      // Alt Kart
                      if (show2 != null)
                        Expanded(
                          flex: flex2,
                          child: _MosaicShowCard(
                            show: show2,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ShowDetailPage(showId: show2.id)),
                            ),
                          ),
                        )
                      else
                        Spacer(flex: flex2),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMosaicShimmer(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: "Etkinlikler Vitrini",
            subtitle: "Akışta Kal",
          ),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                // Shimmer da aynı deseni takip etsin
                int flex1, flex2;
                final int patternStep = index % 4;
                switch (patternStep) {
                  case 0:
                    flex1 = 5;
                    flex2 = 2;
                    break;
                  case 1:
                    flex1 = 3;
                    flex2 = 4;
                    break;
                  case 2:
                    flex1 = 2;
                    flex2 = 5;
                    break;
                  default:
                    flex1 = 4;
                    flex2 = 3;
                    break;
                }

                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Expanded(
                        flex: flex1,
                        child: const ShimmerLoading(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: flex2,
                        child: const ShimmerLoading(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MosaicShowCard extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const _MosaicShowCard({
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16), // Köşeler biraz daha keskin
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWithFallback(
              imageUrl: show.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "ETKİNLİK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    show.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENT WIDGETS (HORIZONTAL LISTS & PLAYERS)
// =============================================================================

class HorizontalListSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<dynamic> items;
  final bool isStage;
  final bool isLoading;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isStage,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: isLoading ? 5 : items.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (final context, final index) {
                if (isLoading) {
                  return const ShimmerCard(width: 220, height: 150);
                }
                return HorizontalCard(
                  item: items[index],
                  isStage: isStage,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
}

class HorizontalCard extends StatelessWidget {
  final dynamic item;
  final bool isStage;
  final bool isLoading;

  const HorizontalCard({
    super.key,
    required this.item,
    required this.isStage,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading) {
      return const ShimmerCard(width: 220, height: 150);
    }

    return GestureDetector(
      onTap: () {
        if (isStage)
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => StageDetailPage(stageId: item.id)));
        else
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => TeamDetailsPage(teamId: item.id)));
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 142,
              child: NetworkImageWithFallback(
                imageUrl: item.imageUrl,
                width: 90,
                height: 142,
                borderRadius: 16,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStage ? "MEKAN" : "EKİP",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isLoading;

  const PlayerSection({
    super.key,
    required this.players,
    this.isLoading = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading) {
      return _buildPlayerShimmer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Oyuncular", subtitle: "Sahnenin Yıldızları"),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final context, final index) {
              final player = players[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final _) =>
                            PlayerDetailPage(playerId: player.id)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: NetworkImageWithFallback(
                          imageUrl: player.imageUrl,
                          width: 120,
                          height: 120,
                          isCircular: true,
                          borderRadius: 60,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${player.firstName}\n${player.lastName}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPlayerShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Oyuncular",
          subtitle: "Sahnenin Yıldızları",
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (final context, final index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: ShimmerLoading(
                        height: 120,
                        width: 120,
                        isCircular: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(height: 12, width: 80, borderRadius: 4),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// SUPPORT WIDGETS
// =============================================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                color: context.primaryColor.withOpacity(0.8),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
}

class FilterList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const FilterList({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(final BuildContext context) {
    final filters = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    final List<List<Color>> artisticColorPalettes = [
      [
        WebColors.darkBlueBackground,
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent
      ],
      [
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA)
      ],
      [Colors.pink.shade500, Colors.purple.shade600, const Color(0xFF444653)],
      [
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent,
        AppDarkColors.primaryVariant
      ],
      [WebColors.success, const Color(0xFF2E7D32), const Color(0xFFA5D6A7)],
    ];

    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (final context, final index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ArtisticBrushChip(
              text: filters[index],
              isSelected: isSelected,
              colors: artisticColorPalettes[index],
              onTap: () => onSelected(index),
            ),
          );
        },
      ),
    );
  }
}

class ArtisticBrushChip extends StatefulWidget {
  final String text;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const ArtisticBrushChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<ArtisticBrushChip> createState() => _ArtisticBrushChipState();
}

class _ArtisticBrushChipState extends State<ArtisticBrushChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(final ArtisticBrushChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (final _) => _controller.forward(),
      onTapUp: (final _) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(minWidth: 90),
          decoration: BoxDecoration(
            borderRadius: _createArtisticBorderRadius(),
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
                          : const Color(0xFFEDF2F7),
                    ],
            ),
            border: Border.all(
              color: widget.isSelected
                  ? widget.colors[0].withOpacity(0.8)
                  : context.colors.onSurface.withOpacity(0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                        color: widget.colors[0].withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 3)),
                    BoxShadow(
                        color: widget.colors[2].withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, -2)),
                    BoxShadow(
                        color: widget.colors[0].withOpacity(0.1),
                        blurRadius: 25,
                        spreadRadius: 5),
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: Stack(
            children: [
              if (widget.isSelected)
                Positioned.fill(
                    child: CustomPaint(
                        painter: _PaintDropletPainter(colors: widget.colors))),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: widget.isSelected
                          ? Colors.white
                          : context.colors.onSurface.withOpacity(0.7),
                      fontWeight:
                          widget.isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                    child: Text(widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _createArtisticBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
      topRight: Radius.circular(widget.isSelected ? 10 : 18),
      bottomLeft: Radius.circular(widget.isSelected ? 18 : 10),
    );
  }
}

class _PaintDropletPainter extends CustomPainter {
  final List<Color> colors;

  _PaintDropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[1].withOpacity(0.15);
    final rng = math.Random(colors.hashCode);
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 6 + 2;
      final colorIndex = rng.nextInt(colors.length);
      paint.color =
          colors[colorIndex].withOpacity(rng.nextDouble() * 0.2 + 0.1);
      canvas.drawOval(
          Rect.fromCircle(center: Offset(x, y), radius: radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

class ArtisticTitle extends StatelessWidget {
  const ArtisticTitle({super.key});

  @override
  Widget build(final BuildContext context) {
    return ShaderMask(
      shaderCallback: (final bounds) => LinearGradient(
        colors: context.appGradient(isActive: true),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text("Keşfet",
          style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              fontFamily: 'Serif',
              letterSpacing: -1.5,
              color: Colors.white)),
    );
  }
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: context.colors.onSurface.withOpacity(0.1)),
          ),
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
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeBackground extends StatelessWidget {
  const ThemeBackground({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.scaffoldBackgroundColor,
            context.colors.surface.withOpacity(0.5)
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

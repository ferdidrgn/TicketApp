import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/pagination_controller.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/navigation/widgets/bottom_nav_bar.dart';
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

    // Veriler boşsa yükle
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

    // Paginationları başlat
    _initializePaginationControllers();
    setState(() => _isInitialized = true);
  }

  void _initializePaginationControllers() {
    showsPagination = _createPagination(ref.read(showProvider).dataList);
    playersPagination = _createPagination(ref.read(playerProvider).dataList);
    stagesPagination = _createPagination(ref.read(stageProvider).dataList);
    teamsPagination = _createPagination(ref.read(teamProvider).dataList);
  }

  PaginationController<T>? _createPagination<T>(List<T>? list) {
    if (list == null) return null;
    return PaginationController(allItems: list, itemsPerPage: 20);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).setQuery(query.toLowerCase());
      // Arama değiştiğinde pagination'ı resetlemek gerekir
      setState(() {
        showsPagination?.reset();
        playersPagination?.reset();
        stagesPagination?.reset();
        teamsPagination?.reset();
      });
    });
  }

  // --- HELPER: FILTER ---
  List<T>? _filterItems<T>(
      List<T>? items, String Function(T) selector, String query) {
    if (items == null) return null;
    if (query.isEmpty) return items;
    return items
        .where((item) => selector(item).toLowerCase().contains(query))
        .toList();
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    // Providerları izle (UI güncellemeleri için şart)
    final showState = ref.watch(showProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final teamState = ref.watch(teamProvider);

    // Listeleri hazırla
    final shows = _filterItems(showState.dataList, (s) => s.name, searchQuery);
    final players = _filterItems(playerState.dataList,
        (p) => '${p.firstName} ${p.lastName}', searchQuery);
    final stages =
        _filterItems(stageState.dataList, (s) => s.name, searchQuery);
    final teams = _filterItems(teamState.dataList, (t) => t.name, searchQuery);

    final bool isAnyLoading =
        showState.isLoading || playerState.isLoading || !_isInitialized;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Arka plan (Tema renkleri ile hafif gradient)
          const Positioned.fill(child: _ThemeBackground()),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              // Hata önleyici yapı: CustomScrollView + Slivers
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. HEADER (KEŞFET & SEARCH)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildArtisticTitle(context),
                        const SizedBox(height: 20),
                        _buildGlassSearchBar(context),
                      ],
                    ),
                  ),
                ),

                // 2. BOYA FIRÇASI CHIPS (Filtreler)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: _buildPaintChips(),
                  ),
                ),

                // 3. İÇERİK (Loading veya Data)
                if (isAnyLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // OYUNCULAR (Players)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 2) &&
                      (players?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                              context, "Sahnenin Yıldızları", "Oyuncular"),
                          _buildPlayerReel(players!),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                  // ETKİNLİKLER (Mosaic - DEĞİŞMEYEN KISIM)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 1) &&
                      (shows?.isNotEmpty ?? false)) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                          context, "Göz Alıcı", "Etkinlikler"),
                    ),
                    // Mozaik Yapı
                    _buildMosaicGridSliver(shows!),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],

                  // MEKANLAR (Stages)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 3) &&
                      (stages?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, "Atmosfer", "Mekanlar"),
                          _buildHorizontalCards(stages!, isStage: true),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                  // EKİPLER (Teams)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 4) &&
                      (teams?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, "Mutfak", "Ekipler"),
                          _buildHorizontalCards(teams!, isStage: false),
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),

                  // BOŞ DURUM
                  if ((shows?.isEmpty ?? true) &&
                      (players?.isEmpty ?? true) &&
                      (stages?.isEmpty ?? true) &&
                      (teams?.isEmpty ?? true))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "Sanat eseri bulunamadı...",
                          style: TextStyle(
                              color: context.colors.onSurface.withOpacity(0.5)),
                        ),
                      ),
                    ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildArtisticTitle(BuildContext context) {
    // App Gradient (ThemeContextExtension'dan gelen)
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: context.appGradient(isActive: true),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text(
        "Keşfet",
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          fontFamily: 'Serif',
          letterSpacing: -1.5,
          color: Colors.white, // ShaderMask için beyaz zemin gerekli
        ),
      ),
    );
  }

  Widget _buildGlassSearchBar(BuildContext context) {
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
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: _textEditingController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Sanatın izini sür...',
              hintStyle: TextStyle(
                color: context.colors.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
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

  Widget _buildPaintChips() {
    final filters = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: _PaintStroke(
              text: filters[index],
              isSelected: isSelected,
              context: context,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String subtitle, String title) {
    return Padding(
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

  // --- OYUNCU REEL ---
  Widget _buildPlayerReel(List<Player> players) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: players.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final player = players[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlayerDetailPage(playerId: player.id)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        // Uzun hap şekli
                        image: DecorationImage(
                          image: NetworkImage(player.imageUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                        border:
                            Border.all(color: context.colors.surface, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${player.firstName}\n${player.lastName}",
                    textAlign: TextAlign.center,
                    maxLines: 2,
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
    );
  }

  // --- MEKAN & EKİP KARTLARI ---
  Widget _buildHorizontalCards(List<dynamic> items, {required bool isStage}) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (isStage) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StageDetailPage(stageId: item.id)));
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TeamDetailsPage(teamId: item.id)));
              }
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
                        offset: const Offset(0, 4))
                  ]),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(item.imageUrl,
                        width: 90, height: 142, fit: BoxFit.cover),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStage ? "MEKAN" : "EKİP",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MOZAİK IZGARA (SLIVER VERSIYONU - SEVDİĞİN TASARIM) ---
  Widget _buildMosaicGridSliver(List<Show> shows) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (int i = 0; i < shows.length; i += 3) ...[
              // Büyük Kart (Satır başı)
              if (i < shows.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LeafShowCard(
                    show: shows[i],
                    isLarge: true,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ShowDetailPage(showId: shows[i].id))),
                  ),
                ),

              // Küçük İkili Kart (Satır devamı)
              if (i + 1 < shows.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LeafShowCard(
                          show: shows[i + 1],
                          isLarge: false,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ShowDetailPage(showId: shows[i + 1].id))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (i + 2 < shows.length)
                        Expanded(
                          child: _LeafShowCard(
                            show: shows[i + 2],
                            isLarge: false,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ShowDetailPage(
                                        showId: shows[i + 2].id))),
                          ),
                        )
                      else
                        const Spacer(),
                    ],
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- DESIGN COMPONENTS (PAINT CHIPS & CARDS) ---
// -----------------------------------------------------------------------------

/// **YENİ:** Boya Darbesi Görünümlü Chip
class _PaintStroke extends StatelessWidget {
  final String text;
  final bool isSelected;
  final BuildContext context;

  const _PaintStroke(
      {required this.text, required this.isSelected, required this.context});

  @override
  Widget build(BuildContext context) {
    // Tema renklerinden gradient al
    final colors = context.appGradient(isActive: true);

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        // Boya darbesi efekti için asimetrik border radius
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
          topRight: Radius.circular(isSelected ? 15 : 5),
          bottomLeft: Radius.circular(isSelected ? 5 : 15),
        ),
        gradient: isSelected
            ? LinearGradient(colors: colors)
            : LinearGradient(
                colors: [
                  context.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  context.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                ],
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(2, 4),
                )
              ]
            : [],
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : context.colors.onSurface.withOpacity(0.1),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : context.colors.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// (Korunan Tasarım) Mozaik Kartı
class _LeafShowCard extends StatelessWidget {
  final Show show;
  final bool isLarge;
  final VoidCallback onTap;

  const _LeafShowCard(
      {required this.show, required this.isLarge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge ? 240 : 180,
        decoration: BoxDecoration(
          color: context.colors.surface, // Tema rengi
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(32),
            bottomRight: const Radius.circular(32),
            topRight: Radius.circular(isLarge ? 8 : 24),
            bottomLeft: Radius.circular(isLarge ? 8 : 24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(show.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLarge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("TAVSİYE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  Text(
                    show.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLarge ? 22 : 16,
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

/// Arka Plan (Tema uyumlu gradient)
class _ThemeBackground extends StatelessWidget {
  const _ThemeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.scaffoldBackgroundColor,
            context.colors.surface.withOpacity(0.5),
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

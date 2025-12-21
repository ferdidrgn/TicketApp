import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    WidgetsBinding.instance
        .addPostFrameCallback((final _) => _initializeData());
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

    final shows =
        _filterItems(showState.dataList, (final s) => s.name, searchQuery);
    final players = _filterItems(playerState.dataList,
        (final p) => '${p.firstName} ${p.lastName}', searchQuery);
    final stages =
        _filterItems(stageState.dataList, (final s) => s.name, searchQuery);
    final teams =
        _filterItems(teamState.dataList, (final t) => t.name, searchQuery);

    final bool isAnyLoading =
        showState.isLoading || playerState.isLoading || !_isInitialized;

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
                    onSelected: (final index) =>
                        setState(() => _selectedFilterIndex = index),
                  ),
                ),

                // 3. CONTENT
                if (isAnyLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // OYUNCULAR
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 2) &&
                      (players?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: PlayerSection(players: players!),
                    ),

                  // ETKİNLİKLER (Masonry)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 1) &&
                      (shows?.isNotEmpty ?? false))
                    ScatteredMasonrySection(shows: shows!),

                  // MEKANLAR
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 3) &&
                      (stages?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: HorizontalListSection(
                        title: "Mekanlar",
                        subtitle: "Atmosfer",
                        items: stages!,
                        isStage: true,
                      ),
                    ),

                  // EKİPLER (Hatanın olduğu kısım artık burası)
                  if ((_selectedFilterIndex == 0 ||
                          _selectedFilterIndex == 4) &&
                      (teams?.isNotEmpty ?? false))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: HorizontalListSection(
                          title: "Ekipler",
                          subtitle: "Mutfak",
                          items: teams!,
                          isStage: false,
                        ),
                      ),
                    ),

                  // EMPTY STATE
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
}

// -----------------------------------------------------------------------------
// --- REFACTORED WIDGETS ---
// -----------------------------------------------------------------------------

/// **YENİ:** Ekipler ve Mekanlar için Yatay Liste Konteynerı
class HorizontalListSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<dynamic> items;
  final bool isStage;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isStage,
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
              itemCount: items.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (final context, final index) {
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

/// **YENİ:** Taşma Sorununu Çözen Özel Kart Widget'ı
class HorizontalCard extends StatelessWidget {
  final dynamic item;
  final bool isStage;

  const HorizontalCard({
    super.key,
    required this.item,
    required this.isStage,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
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
          // Sabit genişlik
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
            mainAxisSize: MainAxisSize.min, // Önemli: İçerik kadar yer kapla
            children: [
              // 1. Resim Alanı (Sabit Boyut)
              SizedBox(
                width: 90,
                height: 142,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (final context, final error, final stackTrace) =>
                            Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // 2. Metin Alanı (Kalan Alan)
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
                      // Taşmayı önleyen Text yapısı
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true, // Alt satıra geçmeyi zorla
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

class PlayerSection extends StatelessWidget {
  final List<Player> players;

  const PlayerSection({super.key, required this.players});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              title: "Oyuncular", subtitle: "Sahnenin Yıldızları"),
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
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
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
                              border: Border.all(
                                  color: context.colors.surface, width: 2),
                            ),
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

class ScatteredMasonrySection extends StatelessWidget {
  final List<Show> shows;

  const ScatteredMasonrySection({super.key, required this.shows});

  @override
  Widget build(final BuildContext context) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < shows.length; i++) {
      final double heightFactor = (i % 3 == 0) ? 1.4 : (i % 2 == 0 ? 1.0 : 1.2);
      final double topMargin = (i == 1) ? 40.0 : 0.0;

      final card = Padding(
        padding: EdgeInsets.only(bottom: 16, top: topMargin),
        child: _ScatteredShowCard(
          show: shows[i],
          heightFactor: heightFactor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (final _) => ShowDetailPage(showId: shows[i].id)),
          ),
        ),
      );

      if (0 == i % 2)
        leftColumn.add(card);
      else
        rightColumn.add(card);
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              title: "Etkinlikler Vitrini", subtitle: "Akışta Kal"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: leftColumn)),
                const SizedBox(width: 16),
                Expanded(child: Column(children: rightColumn)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- DİĞER KÜÇÜK YARDIMCI WIDGET'LAR ---

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

    // Pastoral/ebru renk paleti (your colors)
    final List<List<Color>> artisticColorPalettes = [
      // Tümü - Altın ve mavi tonları
      [
        WebColors.darkBlueBackground,
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent
      ],
      // Etkinlikler - Kırmızı tonları
      [
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA)
      ],
      // Oyuncular - Mor ve pembe tonları
      [Colors.pink.shade500, Colors.purple.shade600, const Color(0xFF444653)],
      // Mekanlar - Mavi tonları
      [
        WebColors.darkBlueSurface,
        WebColors.darkBlueAccent,
        AppDarkColors.primaryVariant
      ],
      // Ekipler - Yeşil tonları (alternatif)
      [WebColors.success, const Color(0xFF2E7D32), const Color(0xFFA5D6A7)],
    ];

    return SizedBox(
      height: 65, // Biraz daha yüksek
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
  late Animation<double> _opacityAnimation;

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

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      onTap: () {
        widget.onTap();
      },
      onTapDown: (final _) => _controller.forward(),
      onTapUp: (final _) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          // PAH! PADDING'I ARTIRDIK!
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: BoxConstraints(
            minWidth: 90, // Minimum genişlik ekledik
          ),
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
            // Ebru/çini tarzı kenarlık
            border: Border.all(
              color: widget.isSelected
                  ? widget.colors[0].withOpacity(0.8)
                  : context.colors.onSurface.withOpacity(0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            // Boya sıçraması efekti
            boxShadow: widget.isSelected
                ? [
                    // Ana gölge
                    BoxShadow(
                      color: widget.colors[0].withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                    // İç parıltı
                    BoxShadow(
                      color: widget.colors[2].withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                    ),
                    // Dış hale
                    BoxShadow(
                      color: widget.colors[0].withOpacity(0.1),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    // Pasif durumda ince gölge
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Boya damlacığı efekti (arka plan)
              if (widget.isSelected)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PaintDropletPainter(
                      colors: widget.colors,
                    ),
                  ),
                ),

              // Metin - EN ÖNEMLİ KISIM!
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
                      letterSpacing: widget.isSelected ? 0.5 : 0.0,
                      shadows: widget.isSelected
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Asimetrik, organik kenarlık - fırça darbesi efekti
  BorderRadius _createArtisticBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
      topRight: Radius.circular(widget.isSelected ? 10 : 18),
      bottomLeft: Radius.circular(widget.isSelected ? 18 : 10),
    );
  }
}

// Boya damlacıkları için custom painter
class _PaintDropletPainter extends CustomPainter {
  final List<Color> colors;

  _PaintDropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[1].withOpacity(0.15);

    final rng = math.Random(colors.hashCode);

    // Rastgele boya damlacıkları
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 6 + 2;

      // Rastgele renk opaklığı
      final colorIndex = rng.nextInt(colors.length);
      paint.color =
          colors[colorIndex].withOpacity(rng.nextDouble() * 0.2 + 0.1);

      // Oval/kabarcık şeklinde damlacıklar
      final path = Path()
        ..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

      // Fırça darbesi efekti için blur
      canvas.drawPath(path, paint);
    }

    // Hafif fırça izleri
    final brushPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors[0].withOpacity(0.1)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final startX = rng.nextDouble() * size.width * 0.3;
      final startY = rng.nextDouble() * size.height;
      final endX = startX + rng.nextDouble() * size.width * 0.4;
      final endY = startY + (rng.nextDouble() * 20 - 10);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), brushPaint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

// Alternatif: Daha minimal pastoral chip tasarımı
class PastoralChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const PastoralChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected
              ? primaryColor.withOpacity(0.9)
              : context.colors.surface.withOpacity(0.7),
          border: Border.all(
            color: isSelected
                ? primaryColor.withOpacity(0.5)
                : context.colors.onSurface.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          // Çini deseni efekti
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: -2,
                    offset: const Offset(0, -2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : context.colors.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class PaintStroke extends StatelessWidget {
  final String text;
  final bool isSelected;

  const PaintStroke({super.key, required this.text, required this.isSelected});

  @override
  Widget build(final BuildContext context) {
    final colors = context.appGradient(isActive: true);
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
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
                    offset: const Offset(2, 4))
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
      child: const Text(
        "Keşfet",
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          fontFamily: 'Serif',
          letterSpacing: -1.5,
          color: Colors.white,
        ),
      ),
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

class _ScatteredShowCard extends StatelessWidget {
  final Show show;
  final double heightFactor;
  final VoidCallback onTap;

  const _ScatteredShowCard({
    required this.show,
    required this.heightFactor,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    const double baseHeight = 180;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: baseHeight * heightFactor,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("ETKİNLİK",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    show.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
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

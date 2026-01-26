import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/button/fab_scroll_up.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_gradient_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// 1. STYLE & CONSTANTS
// =============================================================================

class _SearchStyles {
  static const List<List<Color>> filterPalettes = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Tümü
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Etkinlikler
    [Color(0xFFEC4899), Color(0xFFBE185D)], // Oyuncular
    [Color(0xFF10B981), Color(0xFF047857)], // Mekanlar
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Ekipler
  ];
}

// =============================================================================
// 2. MAIN SEARCH PAGE
// =============================================================================

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with GlobalScrollMixin, ResponsiveUtils {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() {} // Veriler tek seferde yüklendiği için boş bırakıldı

  void _onSeeAll(final int filterIndex) {
    ref.read(searchFilterProvider.notifier).setFilter(filterIndex);
    scrollToTop(); // GlobalScrollMixin üzerinden yukarı kaydır
  }

  @override
  Widget build(final BuildContext context) {
    final selectedFilter = ref.watch(searchFilterProvider);
    final searchState = ref.watch(searchResultProvider);
    final query = ref.watch(searchQueryProvider);
    final activeColor = _SearchStyles.filterPalettes[selectedFilter][0];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        ambientColor: activeColor,
        particleColor: activeColor.withOpacity(0.2),
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Header (Arama Çubuğu Dahil)
                  SliverToBoxAdapter(child: _buildHeader(context)),

                  // 2. Sticky Glass Tabs
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverFilterDelegate(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            color: context.colors.surface.withOpacity(0.65),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: _buildFilterTabs(selectedFilter),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Dynamic Content Group
                  searchState.when(
                    data: (final data) {
                      if (_isResultEmpty(data))
                        return _buildEmptyState(context, query);
                      return SliverMainAxisGroup(
                        slivers: _buildContent(context, data, selectedFilter),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (final e, final _) => SliverToBoxAdapter(
                      child: Center(child: Text("Hata: ${e.toString()}")),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),

            // Scroll Up FAB
            ScrollUpButton(
              scrollController: scrollController,
              visibleNotifier: showFloatingButton,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Build Methods ---

  Widget _buildHeader(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 15),
        child: Column(
          children: [
            const TopHeader(title: "Sanat Galerisi"),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(mobile: 20.0, desktop: 180.0),
              ),
              child: GlassSearchBar(
                controller: _textController,
                onChanged: (final v) =>
                    ref.read(searchQueryProvider.notifier).update(v),
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterTabs(final int selectedIndex) {
    const labels = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        itemBuilder: (context, i) => ArtisticBrushChip(
          text: labels[i],
          isSelected: selectedIndex == i,
          colors: _SearchStyles.filterPalettes[i],
          onTap: () => ref.read(searchFilterProvider.notifier).setFilter(i),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
      BuildContext context, SearchResultState state, int filter) {
    if (filter == 0) {
      return [
        _buildSection(
            state.players.length,
            _PlayerHorizontalSection(
                players: state.players, onSeeAll: () => _onSeeAll(2))),

        // Girift Mozaik Tasarımı (Blur kaldırıldı, keskinleştirildi)
        _buildSection(
            state.shows.length,
            Column(children: [
              ShowMosaicGallery(shows: state.shows, direction: Axis.horizontal),
              const SizedBox(height: 35),
            ])),

        _buildSection(
            state.stages.length,
            _HorizontalListSection(
                title: "Mekanlar",
                subtitle: "Sanatın Kalbi",
                items: state.stages,
                isStage: true,
                onSeeAll: () => _onSeeAll(3))),

        _buildSection(
            state.teams.length,
            _HorizontalListSection(
                title: "Ekipler",
                subtitle: "Yaratıcı Gruplar",
                items: state.teams,
                isStage: false,
                onSeeAll: () => _onSeeAll(4))),
      ];
    } else {
      final crossAxisCount =
          context.responsive(mobile: 3, tablet: 4, desktop: 6);
      return _buildFilteredSection(context, state, filter, crossAxisCount);
    }
  }

  Widget _buildSection(int count, Widget child) {
    if (count == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(child: child);
  }

  List<Widget> _buildFilteredSection(BuildContext context, SearchResultState d,
      int filter, int crossAxisCount) {
    switch (filter) {
      case 1: // Etkinlikler Dikey Mozaik
        return [
          SliverPadding(
              padding: context.paddingHorizontal,
              sliver:
                  ShowMosaicGallery(shows: d.shows, direction: Axis.vertical))
        ];
      case 2: // Oyuncular Grid
        return [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68),
              delegate: SliverChildBuilderDelegate(
                  (ctx, i) => PlayerHeroCard(player: d.players[i]),
                  childCount: d.players.length),
            ),
          )
        ];
      case 3: // Mekanlar Grid (Görseller büyütüldü)
        return [
          _GridHelpers.buildGridSliver(context,
              items: d.stages,
              crossAxisCount: crossAxisCount,
              ratio: 1.0,
              itemBuilder: (ctx, item) =>
                  _GridCards.verticalLarge(ctx, item as Stage, true))
        ];
      case 4: // Ekipler Grid
        return [
          _GridHelpers.buildGridSliver(context,
              items: d.teams,
              crossAxisCount: crossAxisCount,
              ratio: 1.0,
              itemBuilder: (ctx, item) =>
                  _GridCards.verticalLarge(ctx, item as Team, false))
        ];
      default:
        return [];
    }
  }

  bool _isResultEmpty(SearchResultState state) =>
      state.shows.isEmpty &&
      state.players.isEmpty &&
      state.stages.isEmpty &&
      state.teams.isEmpty;

  Widget _buildEmptyState(BuildContext context, String query) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_rounded,
                size: 90, color: context.colors.onSurface.withOpacity(0.15)),
            const SizedBox(height: 25),
            Text("'$query' için eser bulunamadı.",
                style:
                    context.textTheme.titleMedium?.copyWith(letterSpacing: 1)),
            TextButton(
                onPressed: () =>
                    ref.read(searchQueryProvider.notifier).update(""),
                child: const Text("Galeriyi Temizle")),
          ]),
        ),
      );
}

// =============================================================================
// 3. ATOMIC UI COMPONENTS
// =============================================================================

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      height: 54,
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8))
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.12 : 0.45))),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: context.primaryColor,
              style: TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Sanatın derinliklerine in...',
                hintStyle: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.4),
                    fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: context.primaryColor, size: 26),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArtisticBrushChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10)),
          gradient: isSelected
              ? LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isSelected ? null : context.colors.surface.withOpacity(0.5),
          border: Border.all(
              color: isSelected
                  ? colors[0].withOpacity(0.6)
                  : context.colors.onSurface.withOpacity(0.08),
              width: 1.8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: colors[0].withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Stack(children: [
          if (isSelected)
            Positioned.fill(
                child: CustomPaint(painter: _DropletPainter(colors: colors))),
          Center(
              child: Text(text,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : context.colors.onSurface.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5))),
        ]),
      ),
    );
  }
}

class _DropletPainter extends CustomPainter {
  final List<Color> colors;

  _DropletPainter({required this.colors});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(colors.hashCode);
    for (int i = 0; i < 6; i++) {
      paint.color = colors[rng.nextInt(colors.length)].withOpacity(0.12);
      canvas.drawOval(
          Rect.fromCircle(
              center: Offset(rng.nextDouble() * size.width,
                  rng.nextDouble() * size.height),
              radius: rng.nextDouble() * 5 + 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverFilterDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(BuildContext ctx, double offset, bool overlaps) => child;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}

class _GridHelpers {
  static Widget buildGridSliver(BuildContext context,
      {required List<dynamic> items,
      required int crossAxisCount,
      required double ratio,
      required Widget Function(BuildContext, dynamic) itemBuilder}) {
    final spacing = context.gridSpacing;
    return SliverPadding(
      padding: context.paddingAll,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: ratio),
        delegate: SliverChildBuilderDelegate(
            (ctx, i) => itemBuilder(ctx, items[i]),
            childCount: items.length),
      ),
    );
  }
}

class _GridCards {
  static Widget verticalLarge(
      BuildContext context, dynamic item, bool isStage) {
    return GestureDetector(
      onTap: () => isStage
          ? context.push('/stage/${item.id}')
          : context.push('/team/${item.id}'),
      child: Container(
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ]),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
              child: OptimizedCachedImage(
                  imageUrl: item.imageUrl, fit: BoxFit.cover)),
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                Colors.black.withOpacity(0.9),
                Colors.transparent
              ],
                          stops: const [
                0.0,
                0.6
              ])))),
          Positioned(
              bottom: 15,
              left: 15,
              right: 15,
              child: Text(item.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  static Widget horizontalCard(BuildContext context, dynamic item, bool isStage,
      {required double width}) {
    return GestureDetector(
      onTap: () => isStage
          ? context.push('/stage/${item.id}')
          : context.push('/team/${item.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          SizedBox(
              width: width * 0.42,
              child: OptimizedCachedImage(
                  imageUrl: item.imageUrl, fit: BoxFit.cover)),
          Expanded(
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(item.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis))),
        ]),
      ),
    );
  }
}

class _PlayerHorizontalSection extends StatelessWidget {
  final List<Player> players;
  final VoidCallback? onSeeAll;

  const _PlayerHorizontalSection({required this.players, this.onSeeAll});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: context.paddingHorizontal,
            child: SectionHeader(
                title: "Performansçılar",
                subtitle: "Sahnenin Yıldızları",
                onTap: onSeeAll)),
        SizedBox(
            height: 230,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: context.paddingHorizontal,
                itemCount: players.length,
                itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: PlayerHeroCard(player: players[i])))),
        const SizedBox(height: 35),
      ]);
}

class _HorizontalListSection extends StatelessWidget {
  final String title, subtitle;
  final List<dynamic> items;
  final bool isStage;
  final VoidCallback? onSeeAll;

  const _HorizontalListSection(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.isStage,
      this.onSeeAll});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: context.paddingHorizontal,
            child: SectionHeader(
                title: title, subtitle: subtitle, onTap: onSeeAll)),
        SizedBox(
            height: 150,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: context.paddingHorizontal,
                itemCount: items.length,
                itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _GridCards.horizontalCard(context, items[i], isStage,
                        width: 290)))),
        const SizedBox(height: 35),
      ]);
}

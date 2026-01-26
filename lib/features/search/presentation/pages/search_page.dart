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
  void onLoadMore() {}

  void _onSeeAll(final int filterIndex) {
    ref.read(searchFilterProvider.notifier).setFilter(filterIndex);
    scrollToTop();
  }

  @override
  Widget build(final BuildContext context) {
    final selectedFilter = ref.watch(searchFilterProvider);
    final searchState = ref.watch(searchResultProvider);
    final query = ref.watch(searchQueryProvider);
    final activeColor = _SearchStyles.filterPalettes[selectedFilter][0];

    return Scaffold(
      backgroundColor: context.colors.surface,
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        ambientColor: activeColor,
        particleColor: activeColor.withOpacity(0.1),
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Üst Boşluk ve Header
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
            SliverToBoxAdapter(child: _buildHeader(context)),

            // 2. Sticky Glass Tabs (Garantili Yükseklik)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverFilterDelegate(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: context.colors.surface.withOpacity(0.8),
                      alignment: Alignment.center,
                      child: _buildFilterTabs(selectedFilter),
                    ),
                  ),
                ),
              ),
            ),

            // 3. İçerik Akışı
            searchState.when(
              data: (final data) {
                final content = _buildContent(context, data, selectedFilter);
                if (content.isEmpty) return _buildEmptyState(context, query);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    ...content,
                    const SizedBox(height: 100),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (final e, final stack) => SliverToBoxAdapter(
                child: Center(child: Text("Hata: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Yardımcı Metotlar ---

  Widget _buildHeader(final BuildContext context) => Column(
    children: [
      const TopHeader(title: "Sanat Galerisi"),
      const SizedBox(height: 25),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassSearchBar(
          controller: _textController,
          onChanged: (final v) => ref.read(searchQueryProvider.notifier).update(v),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );

  Widget _buildFilterTabs(final int selectedIndex) {
    const labels = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: labels.length,
      itemBuilder: (final context, final i) => ArtisticBrushChip(
        text: labels[i],
        isSelected: selectedIndex == i,
        colors: _SearchStyles.filterPalettes[i],
        onTap: () => ref.read(searchFilterProvider.notifier).setFilter(i),
      ),
    );
  }

  List<Widget> _buildContent(final BuildContext context, final SearchResultState state, final int filter) {
    List<Widget> list = [];

    if (filter == 0) {
      if (state.players.isNotEmpty) {
        list.add(_PlayerHorizontalSection(players: state.players, onSeeAll: () => _onSeeAll(2)));
      }
      if (state.shows.isNotEmpty) {
        list.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              SectionHeader(title: "Etkinlikler", subtitle: "Öne Çıkanlar", onTap: () => _onSeeAll(1)),
              const SizedBox(height: 15),
              ShowMosaicGallery(shows: state.shows, direction: Axis.horizontal),
            ],
          ),
        ));
      }
      if (state.stages.isNotEmpty) {
        list.add(_HorizontalListSection(title: "Mekanlar", subtitle: 'Sanatsal', items: state.stages, isStage: true, onSeeAll: () => _onSeeAll(3)));
      }
    } else {
      list.add(_buildFilteredGrid(context, state, filter));
    }
    return list;
  }

  Widget _buildFilteredGrid(final BuildContext context, final SearchResultState d, final int filter) {
    // GridView'ı Column içine alıp shrinkWrap: true yaparak SliverList içinde çalıştırıyoruz
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: filter == 1 ? d.shows.length : (filter == 2 ? d.players.length : (filter == 3 ? d.stages.length : d.teams.length)),
        itemBuilder: (final context, final i) {
          if (filter == 2) return PlayerHeroCard(player: d.players[i]);
          final item = filter == 1 ? d.shows[i] : (filter == 3 ? d.stages[i] : d.teams[i]);
          return _GridCards.verticalLarge(context, item, filter == 3);
        },
      ),
    );
  }

  Widget _buildEmptyState(final BuildContext context, final String query) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text("'$query' bulunamadı."),
        ),
      );
}

class _SearchStyles {
  static const List<List<Color>> filterPalettes = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Tümü
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Etkinlikler
    [Color(0xFFEC4899), Color(0xFFBE185D)], // Oyuncular
    [Color(0xFF10B981), Color(0xFF047857)], // Mekanlar
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Ekipler
  ];
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.colors.primary.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Sahneyi keşfet...',
              prefixIcon: Icon(Icons.search, color: context.colors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
  Widget build(final BuildContext context) {
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
  bool shouldRepaint(covariant final CustomPainter old) => false;
}

class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverFilterDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(final BuildContext ctx, final double offset, final bool overlaps) => child;

  @override
  bool shouldRebuild(covariant final SliverPersistentHeaderDelegate old) => true;
}

class _GridCards {
  static Widget verticalLarge(
      final BuildContext context, final dynamic item, final bool isStage) {
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

  static Widget horizontalCard(final BuildContext context, final dynamic item, final bool isStage,
      {required final double width}) {
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
  Widget build(final BuildContext context) =>
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
                itemBuilder: (final ctx, final i) => Padding(
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
  Widget build(final BuildContext context) =>
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
                itemBuilder: (final ctx, final i) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _GridCards.horizontalCard(context, items[i], isStage,
                        width: 290)))),
        const SizedBox(height: 35),
      ]);
}

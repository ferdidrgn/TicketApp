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
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        ambientColor: activeColor,
        particleColor: activeColor.withOpacity(0.1),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildPremiumHeader(context),
                    ),
                  ),

                  // STICKY FILTER TABS
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverFilterDelegate(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            color: context.colors.surface.withOpacity(0.7),
                            alignment: Alignment.center,
                            child: _buildFilterTabs(selectedFilter),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // CONTENT
                  searchState.when(
                    data: (data) {
                      // Eğer filtre 1 (Etkinlikler) seçiliyse, dikey mozaik doğrudan Sliver olarak döner.
                      if (selectedFilter == 1) {
                        return SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: ShowMosaicGallery(shows: data.shows, direction: Axis.vertical),
                        );
                      }

                      // Diğer durumlar (Tümü veya Oyuncular/Mekanlar/Ekipler)
                      final content = _buildContent(context, data, selectedFilter);
                      return SliverPadding(
                        padding: const EdgeInsets.only(top: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            ...content,
                            const SizedBox(height: 120),
                          ]),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(child: Text("Hata: $e")),
                    ),
                  ),
                ],
              ),
            ),

            ScrollUpButton(
              scrollController: scrollController,
              visibleNotifier: showFloatingButton,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Column(
      children: [
        const TopHeader(title: "Keşfet"),
        const SizedBox(height: 20),
        ModernSearchBar(
          controller: _textController,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).update(v),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(int selectedIndex) {
    const labels = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: labels.length,
      itemBuilder: (context, i) => ArtisticBrushChip(
        text: labels[i],
        isSelected: selectedIndex == i,
        colors: _SearchStyles.filterPalettes[i],
        onTap: () => _onSeeAll(i),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, SearchResultState state, int filter) {
    if (filter == 0) {
      return [
        // ETKİNLİKLER (YATAY) - 10 ADET SINIRI
        if (state.shows.isNotEmpty) ...[
          SectionHeader(title: "Etkinlikler", subtitle: "Sanatın Akışı", onTap: () => _onSeeAll(1)),
          const SizedBox(height: 12),
          ShowMosaicGallery(shows: state.shows.take(10).toList(), direction: Axis.horizontal),
          const SizedBox(height: 30),
        ],

        // OYUNCULAR (YATAY) - 10 ADET SINIRI
        if (state.players.isNotEmpty) ...[
          SectionHeader(title: "Oyuncular", subtitle: "Sahne Yıldızları", onTap: () => _onSeeAll(2)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.players.take(10).length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(width: 120, child: PlayerHeroCard(player: state.players[i])),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],

        // MEKANLAR (YATAY)
        if (state.stages.isNotEmpty)
          _HorizontalSection(title: "Mekanlar", items: state.stages.take(10).toList(), isStage: true, onSeeAll: () => _onSeeAll(3)),
      ];
    }

    // Diğer filtreler (Oyuncular, Mekanlar, Ekipler) için Grid Görünümü
    return [_buildCommonGrid(context, state, filter)];
  }

  Widget _buildCommonGrid(BuildContext context, SearchResultState d, int filter) {
    final items = filter == 2 ? d.players : (filter == 3 ? d.stages : d.teams);
    final crossAxisCount = context.responsive(mobile: 3, tablet: 5, desktop: 6);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: filter == 2 ? 0.65 : 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        if (filter == 2) return PlayerHeroCard(player: items[i] as Player);
        return _GridCards.verticalLarge(context, items[i], filter == 3);
      },
    );
  }
}

// --- COMPONENTLER AYNI KALDI (StatusBar ve Tasarım düzeltmeleri dahil) ---

class ArtisticBrushChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const ArtisticBrushChip({super.key, required this.text, required this.isSelected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          gradient: isSelected ? LinearGradient(colors: colors) : null,
          color: isSelected ? null : context.colors.surface.withOpacity(0.5),
          border: Border.all(color: isSelected ? Colors.transparent : context.colors.onSurface.withOpacity(0.1)),
          boxShadow: isSelected ? [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8)] : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.onSurface.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const ModernSearchBar({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.primary.withOpacity(0.3), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Sanat eserini keşfet...',
              prefixIcon: Icon(Icons.auto_awesome, color: context.colors.primary),
              filled: true,
              fillColor: context.colors.surface.withOpacity(0.6),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final bool isStage;
  final VoidCallback onSeeAll;

  const _HorizontalSection({required this.title, required this.items, required this.isStage, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: title, subtitle: "Keşfe Başla", onTap: onSeeAll),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _GridCards.horizontalCard(context, items[i], isStage, width: 260),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverFilterDelegate({required this.child});
  @override double get minExtent => 65;
  @override double get maxExtent => 65;
  @override Widget build(ctx, offset, overlaps) => child;
  @override bool shouldRebuild(old) => true;
}

class _SearchStyles {
  static const List<List<Color>> filterPalettes = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF10B981), Color(0xFF047857)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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
              hintText: 'Sanatı keşfet...',
              prefixIcon: Icon(Icons.auto_awesome,
                  color: context.colors.primary, size: 20),
              filled: true,
              fillColor: context.colors.surface.withOpacity(0.9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: context.colors.primary.withOpacity(0.15), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 1.5), // Fokus olduğunda netleşen border
              ),
            ),
          ),
        ),
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

  static Widget horizontalCard(
      final BuildContext context, final dynamic item, final bool isStage,
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

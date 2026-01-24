import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_gradient_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../teams/domain/entities/team.dart';
import '../providers/search_query_provider.dart';

class _Styles {
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
}

class _SearchLogic {
  static int totalCount<T>(final List<T>? items, final String query,
          final String Function(T) selector) =>
      items
          ?.where((final i) =>
              query.isEmpty || selector(i).toLowerCase().contains(query))
          .length ??
      0;
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with ResponsiveUtils {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // _initData ve _isInitialized SİLİNDİ. Riverpod 3.0 otomatik yapar.

  @override
  void initState() {
    super.initState();
    // Scroll listener kalabilir ama initData'ya gerek yok
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll logic...
  }

  void _onSeeAll(final int filterIndex) {
    ref.read(searchFilterProvider.notifier).setFilter(filterIndex);
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  // 🔥 DÜZELTME: build metodunda parametre olarak 'WidgetRef ref' OLMAZ.
  // ConsumerState sınıfı zaten 'ref' property'sine sahiptir.
  @override
  Widget build(final BuildContext context) {
    // 'ref' doğrudan kullanılıyor (this.ref)
    final searchState = ref.watch(searchResultProvider);
    final selectedFilter = ref.watch(searchFilterProvider);
    final query = ref.watch(searchQueryProvider);

    final crossAxisCount = context.responsive(mobile: 2, tablet: 3, desktop: 4);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CustomAppBackground(
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: _FilterList(
                  selectedIndex: selectedFilter,
                  onSelected: (final i) =>
                      ref.read(searchFilterProvider.notifier).setFilter(i),
                ),
              ),
              if (searchState.isLoading && query.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (_isResultEmpty(searchState))
                _buildEmptyState(context)
              else
                ..._buildContent(
                    context, searchState, selectedFilter, crossAxisCount),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  bool _isResultEmpty(final SearchResultState state) =>
      state.shows.isEmpty &&
      state.players.isEmpty &&
      state.stages.isEmpty &&
      state.teams.isEmpty;

  Widget _buildHeader(final BuildContext context) {
    return Column(
      children: [
        const TopHeader(title: "Tablolarımız"), // const eklendi
        const SizedBox(height: 20),
        Padding(
          padding: context.paddingHorizontal,
          child: GlassSearchBar(
            controller: _textController,
            onChanged: (final v) =>
                ref.read(searchQueryProvider.notifier).update(v),
          ),
        ),
      ],
    );
  }

  // --- CONTENT BUILDERS (Aynı kalabilir) ---
  List<Widget> _buildContent(
      final BuildContext context,
      final SearchResultState state,
      final int filter,
      final int crossAxisCount) {
    if (filter == 0) {
      return [
        if (state.players.isNotEmpty)
          SliverToBoxAdapter(
              child: _PlayerHorizontalSection(
                  players: state.players, onSeeAll: () => _onSeeAll(2))),
        if (state.shows.isNotEmpty)
          SliverToBoxAdapter(
              child: Column(
            children: [
              Padding(
                  padding: context.paddingHorizontal,
                  child: SectionHeader(
                      title: "Etkinlikler Vitrini",
                      subtitle: "Akışta Kal",
                      onTap: () => _onSeeAll(1))),
              ShowMosaicGallery(shows: state.shows, direction: Axis.horizontal),
              const SizedBox(height: 32),
            ],
          )),
        if (state.stages.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Mekanlar",
                  subtitle: "Atmosfer",
                  items: state.stages,
                  isStage: true,
                  onSeeAll: () => _onSeeAll(3))),
        if (state.teams.isNotEmpty)
          SliverToBoxAdapter(
              child: _HorizontalListSection(
                  title: "Ekipler",
                  subtitle: "Mutfak",
                  items: state.teams,
                  isStage: false,
                  onSeeAll: () => _onSeeAll(4))),
      ];
    } else {
      return _buildFilteredSection(context, state, filter, crossAxisCount);
    }
  }

  // ... (Geri kalan _buildFilteredSection, _buildEmptyState vs. kodun geri kalanı aynı)
  // Sadece buildFilteredSection içinde _GridHelpers kullanırken hata alırsan importları kontrol et.

  List<Widget> _buildFilteredSection(final BuildContext context,
      final SearchResultState d, final int filter, final int crossAxisCount) {
    final gridSpacing = context.gridSpacing;
    switch (filter) {
      case 1: // Shows
        return [
          SliverPadding(
            padding: context.paddingHorizontal.copyWith(bottom: 20),
            sliver: d.shows.isEmpty
                ? SliverToBoxAdapter(
                    child:
                        _buildEmptyState(context, msg: "Etkinlik bulunamadı"))
                : ShowMosaicGallery(shows: d.shows, direction: Axis.vertical),
          )
        ];
      case 2: // Players
        return [
          SliverPadding(
            padding: context.paddingAll,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    context.responsive(mobile: 3, tablet: 4, desktop: 6),
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                (final ctx, final i) => PlayerHeroCard(player: d.players[i]),
                childCount: d.players.length,
              ),
            ),
          )
        ];
      case 3: // Stages
        return [
          _GridHelpers.buildGridSliver(
            context,
            items: d.stages,
            crossAxisCount: crossAxisCount,
            ratio: 1.4,
            itemBuilder: (final ctx, final item) =>
                _GridCards.verticalLarge(ctx, item as Stage, true),
          )
        ];
      case 4: // Teams
        return [
          _GridHelpers.buildGridSliver(
            context,
            items: d.teams,
            crossAxisCount: crossAxisCount,
            ratio: 1.4,
            itemBuilder: (final ctx, final item) =>
                _GridCards.verticalLarge(ctx, item as Team, false),
          )
        ];
      default:
        return [];
    }
  }

  Widget _buildEmptyState(final BuildContext context, {final String? msg}) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 80, color: context.colors.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(msg ?? "Sonuç bulunamadı.",
              style:
                  TextStyle(color: context.colors.onSurface.withOpacity(0.5))),
        ])),
      );
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GlassSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      height: 56,
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5))
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
            child: Center(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                cursorColor: context.primaryColor,
                style: TextStyle(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Sanatın izini sür...',
                  hintStyle: TextStyle(
                      color: context.colors.onSurface.withOpacity(0.5),
                      fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.primaryColor.withOpacity(0.8), size: 24),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridHelpers {
  static Widget buildGridSliver(final BuildContext context,
      {required final List<dynamic> items,
      required final int crossAxisCount,
      required final double ratio,
      required final Widget Function(BuildContext, dynamic) itemBuilder}) {
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
            (final ctx, final i) => itemBuilder(ctx, items[i]),
            childCount: items.length),
      ),
    );
  }
}

class _GridCards {
  static Widget verticalLarge(
      final BuildContext context, final dynamic item, final bool isStage) {
    return _BaseCardContainer(
      onTap: () => isStage
          ? context.push('/stage/${item.id}')
          : context.push('/team/${item.id}'),
      child: Stack(children: [
        Positioned.fill(
            child: OptimizedCachedImage(
                imageUrl: item.imageUrl, fit: BoxFit.cover)),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black54,
                child: Text(item.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
    );
  }

  static Widget horizontalCard(
      final BuildContext context, final dynamic item, final bool isStage,
      {required final double width}) {
    return _BaseCardContainer(
      onTap: () => isStage
          ? context.push('/stage/${item.id}')
          : context.push('/team/${item.id}'),
      width: width,
      child: Row(children: [
        SizedBox(
            width: width * 0.4,
            child: OptimizedCachedImage(
                imageUrl: item.imageUrl, fit: BoxFit.cover)),
        Expanded(
            child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(item.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface)))),
      ]),
    );
  }
}

class _BaseCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const _BaseCardContainer(
      {required this.child,
      this.onTap,
      this.width,
      this.margin,
      this.padding,
      this.borderRadius});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      );
}

class _PlayerHorizontalSection extends StatelessWidget {
  final List<Player> players;
  final VoidCallback? onSeeAll;

  const _PlayerHorizontalSection({required this.players, this.onSeeAll});

  @override
  Widget build(final BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: context.paddingHorizontal,
          child: SectionHeader(
              title: "Performansçılar",
              subtitle: "Sahnenin Yıldızları",
              onTap: onSeeAll)),
      SizedBox(
          height: 220,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: context.paddingHorizontal,
              itemCount: players.length,
              itemBuilder: (final ctx, final i) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PlayerHeroCard(player: players[i])))),
      const SizedBox(height: 32),
    ]);
  }
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
  Widget build(final BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: context.paddingHorizontal,
          child:
              SectionHeader(title: title, subtitle: subtitle, onTap: onSeeAll)),
      SizedBox(
          height: 180,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: context.paddingHorizontal,
              itemCount: items.length,
              itemBuilder: (final ctx, final i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _GridCards.horizontalCard(context, items[i], isStage,
                      width: 260)))),
      const SizedBox(height: 32),
    ]);
  }
}

class _FilterList extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const _FilterList({required this.selectedIndex, required this.onSelected});

  static const _filters = [
    "Tümü",
    "Etkinlikler",
    "Oyuncular",
    "Mekanlar",
    "Ekipler"
  ];

  @override
  Widget build(final BuildContext context) => SizedBox(
      height: 80,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _filters.length,
          itemBuilder: (final _, final i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                  label: Text(_filters[i]),
                  selected: selectedIndex == i,
                  onSelected: (final _) => onSelected(i)))));
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

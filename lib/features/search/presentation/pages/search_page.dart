import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../providers/search_query_provider.dart';

// =============================================================================
// 1. STYLE & CONSTANTS
// =============================================================================

class _SearchStyles {
  static const List<List<Color>> filterPalettes = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Tümü (Indigo)
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Etkinlikler (Amber)
    [Color(0xFFEC4899), Color(0xFFBE185D)], // Oyuncular (Pink)
    [Color(0xFF10B981), Color(0xFF047857)], // Mekanlar (Emerald)
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Ekipler (Blue)
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
    with ResponsiveUtils, GlobalScrollMixin {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() => debugPrint("Daha fazla arama sonucu yükleniyor...");

  void _onSeeAll(final int filterIndex) =>
      ref.read(searchFilterProvider.notifier).setFilter(filterIndex);

  @override
  Widget build(final BuildContext context) {
    final selectedFilter = ref.watch(searchFilterProvider);
    final searchState = ref.watch(searchResultProvider);
    final activeColor = _SearchStyles.filterPalettes[selectedFilter][0];

    return BasePageWrapper(
        showBackButton: true,
        showFab: true,
        title: "Sanat Serüveni",
        isLoading: searchState.isLoading,
        customScrollController: scrollController,
        layoutConfig: BasePageLayoutConfig(
          ambientColor: activeColor,
          particleColor: activeColor.withOpacity(0.1),
        ),
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Üst boşluk (Geri butonu ve Header için)
            SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top)),

            // Filtreler (Pinned Header)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverFilterDelegate(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: context.colors.surface.withOpacity(0.7),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          _buildIntegratedSearchField(context),
                          _buildFilterTabs(selectedFilter),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sonuçlar
            searchState.when(
              data: (final data) =>
                  _buildSearchResultContent(data, selectedFilter),
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (final e, final _) =>
                  SliverToBoxAdapter(child: Center(child: Text("Hata: $e"))),
            ),
          ],
        ));
  }

  // --- Widget Oluşturucular (Sınıf İçinde Olmalı) ---

  Widget _buildIntegratedSearchField(final BuildContext context) {
    final bool isLarge = context.isTablet || context.isDesktop;

    return Center(
        // ✅ İçeriği ortala
        child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isLarge ? 800 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CustomSearchVisualShell(
                isDark: context.isDarkMode,
                primaryColor: context.colors.primary,
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  onChanged: (final v) =>
                      ref.read(searchQueryProvider.notifier).update(v),
                  onSubmitted: (final _) => FocusScope.of(context).unfocus(),
                  textInputAction: TextInputAction.search,
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Sanatçını veya sahneni bul...",
                    hintStyle: TextStyle(
                        color: context.colors.onSurface.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.colors.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            )));
  }

  Widget _buildFilterTabs(final int selectedIndex) {
    const labels = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return Center(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          itemBuilder: (final context, final i) => ArtisticBrushChip(
            text: labels[i],
            isSelected: selectedIndex == i,
            colors: _SearchStyles.filterPalettes[i],
            onTap: () => _onSeeAll(i),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultContent(
      final SearchResultState data, final int selectedFilter) {
    final query = ref.watch(searchQueryProvider);
    final bool isEmpty = data.shows.isEmpty &&
        data.players.isEmpty &&
        data.stages.isEmpty &&
        data.teams.isEmpty;

    if (isEmpty && query.isNotEmpty)
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_motion_outlined,
                  size: 80, color: context.colors.primary.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(context.l10n.searchEmptyState(query),
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  _textController.clear();
                  ref.read(searchQueryProvider.notifier).update("");
                },
                child: Text(context.l10n.searchClearGallery),
              )
            ],
          ),
        ),
      );

    if (selectedFilter == 1)
      return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver:
              ShowMosaicGallery(shows: data.shows, direction: Axis.vertical));

    final content = _buildContentList(context, data, selectedFilter);
    return SliverPadding(
      padding: const EdgeInsets.only(top: 20),
      sliver: SliverList(
        delegate:
            SliverChildListDelegate([...content, const SizedBox(height: 120)]),
      ),
    );
  }

  List<Widget> _buildContentList(final BuildContext context,
      final SearchResultState state, final int filter) {
    if (filter == 0)
      return [
        if (state.shows.isNotEmpty) ...[
          SectionHeader(
              title: "Etkinlikler",
              subtitle: "Sanatın Akışı",
              onTap: () => _onSeeAll(1)),
          const SizedBox(height: 12),
          ShowMosaicGallery(
              shows: state.shows.take(10).toList(), direction: Axis.horizontal),
          const SizedBox(height: 30),
        ],
        if (state.players.isNotEmpty) ...[
          SectionHeader(
              title: "Oyuncular",
              subtitle: "Sahne Yıldızları",
              onTap: () => _onSeeAll(2)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.players.take(10).length,
              itemBuilder: (final context, final i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                    width: 120,
                    child: PlayerHeroCard(player: state.players[i])),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
        if (state.stages.isNotEmpty)
          _HorizontalSection(
              title: "Mekanlar",
              items: state.stages.take(10).toList(),
              isStage: true,
              onSeeAll: () => _onSeeAll(3)),
        if (state.teams.isNotEmpty)
          _HorizontalSection(
              title: "Ekipler",
              items: state.teams.take(10).toList(),
              isStage: false,
              onSeeAll: () => _onSeeAll(4)),
      ];

    return [_buildCommonGrid(context, state, filter)];
  }

  Widget _buildCommonGrid(
      final BuildContext context, final SearchResultState d, final int filter) {
    final items = filter == 2 ? d.players : (filter == 3 ? d.stages : d.teams);
    final crossAxisCount = context.responsive(mobile: 3, tablet: 5, desktop: 6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: filter == 2 ? 0.65 : 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (final context, final i) {
          if (filter == 2) return PlayerHeroCard(player: items[i] as Player);
          return _GridCards.verticalLarge(context, items[i], filter == 3);
        },
      ),
    );
  }
}

// =============================================================================
// 3. ATOMIC UI COMPONENTS & EXTRAS
// =============================================================================

class _CustomSearchVisualShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color primaryColor;

  const _CustomSearchVisualShell(
      {required this.child, required this.isDark, required this.primaryColor});

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: child,
            ),
          ),
        ),
      );
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
  Widget build(final BuildContext context) => GestureDetector(
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
            border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : context.colors.onSurface.withOpacity(0.1)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: colors[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.colors.onSurface.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14)),
          ),
        ),
      );
}

class _HorizontalSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final bool isStage;
  final VoidCallback onSeeAll;

  const _HorizontalSection(
      {required this.title,
      required this.items,
      required this.isStage,
      required this.onSeeAll});

  @override
  Widget build(final BuildContext context) => Column(
        children: [
          SectionHeader(title: title, subtitle: "Keşfe Başla", onTap: onSeeAll),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (final context, final i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _GridCards.horizontalCard(context, items[i], isStage,
                      width: 260)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      );
}

class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverFilterDelegate({required this.child});

  @override
  double get minExtent => 110;

  @override
  double get maxExtent => 110;

  @override
  Widget build(
          final BuildContext ctx, final double offset, final bool overlaps) =>
      child;

  @override
  bool shouldRebuild(covariant final SliverPersistentHeaderDelegate old) =>
      true;
}

class _GridCards {
  static Widget verticalLarge(
          final BuildContext context, final dynamic item, final bool isStage) =>
      GestureDetector(
        onTap: () => isStage
            ? NavigationHandler.goToStage(context, item.id, item.name)
            : NavigationHandler.goToTeam(context, item.id, item.name),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
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
                        fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );

  static Widget horizontalCard(
          final BuildContext context, final dynamic item, final bool isStage,
          {required final double width}) =>
      GestureDetector(
        onTap: () => isStage
            ? NavigationHandler.goToStage(context, item.id, item.name)
            : NavigationHandler.goToTeam(context, item.id, item.name),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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

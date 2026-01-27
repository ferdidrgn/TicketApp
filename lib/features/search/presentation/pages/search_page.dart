import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/button/fab_scroll_up.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/top_gradient_header.dart';
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
    with GlobalScrollMixin, ResponsiveUtils {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() {} // Veriler provider tarafında yönetiliyor

  void _onSeeAll(final int filterIndex) {
    ref.read(searchFilterProvider.notifier).setFilter(filterIndex);
    scrollToTop(); // GlobalScrollMixin
  }

  @override
  Widget build(final BuildContext context) {
    final selectedFilter = ref.watch(searchFilterProvider);
    final searchState = ref.watch(searchResultProvider);
    final query = ref.watch(searchQueryProvider);
    final activeColor = _SearchStyles.filterPalettes[selectedFilter][0];

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      isLoading: searchState.isLoading,
      // Provider'ın yüklenme durumuna bağlıyoruz
      layoutConfig: PageBackgroundLayoutConfig(
        ambientColor: activeColor, // Dinamik renk yönetimi
        particleColor: activeColor.withOpacity(0.1),
      ),
      child: Stack(
        children: [
          // StatusBar ve tıklama sorunlarını çözen SafeArea
          CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- Arama ve Başlık Kısmı ---
              SliverToBoxAdapter(child: _buildPremiumHeader(context)),

              // --- Sticky (Yapışkan) Filtre Sekmeleri ---
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

              // --- Dinamik İçerik Alanı ---
              searchState.when(
                data: (final data) {
                  final bool isEmpty = data.shows.isEmpty &&
                      data.players.isEmpty &&
                      data.stages.isEmpty &&
                      data.teams.isEmpty;

                  if (isEmpty && query.isNotEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_motion_outlined,
                                size: 80,
                                color: context.colors.primary.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(context.l10n.searchEmptyState(query),
                                style: context.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {
                                _textController.clear();
                                ref
                                    .read(searchQueryProvider.notifier)
                                    .update("");
                              },
                              child: Text(context.l10n.searchClearGallery),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  // HATA ÇÖZÜMÜ: Filtre 1 (Etkinlikler) seçiliyse, Sliver olan dikey mozaik doğrudan döner.
                  if (selectedFilter == 1)
                    return SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: ShowMosaicGallery(
                            shows: data.shows, direction: Axis.vertical));

                  // Diğer durumlar için SliverList içinde normal widget akışı
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
                    child: Center(child: CircularProgressIndicator.adaptive())),
                error: (final e, final _) => SliverToBoxAdapter(
                    child: Center(child: Text("Hata oluştu: $e"))),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GlassmorphismBackButton(),
          ),
          // Yukarı Kaydır Butonu
          ScrollUpButton(
              scrollController: scrollController,
              visibleNotifier: showFloatingButton),
        ],
      ),
    );
  }

  // --- Widget Oluşturucular ---

  Widget _buildPremiumHeader(final BuildContext context) {
    final currentQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          // Query doluysa farklı başlık göster
          TopGradientHeader(
            title: currentQuery.isEmpty
                ? context.l10n.searchTitle
                : "'$currentQuery' için sonuçlar",
          ),
          const SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.responsive(mobile: 24.0, desktop: 200.0)),
            child: ModernSearchBar(
              controller: _textController,
              onChanged: (final String v) =>
                  ref.read(searchQueryProvider.notifier).update(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(final int selectedIndex) {
    const labels = ["Tümü", "Etkinlikler", "Oyuncular", "Mekanlar", "Ekipler"];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: labels.length,
      itemBuilder: (final context, final i) => ArtisticBrushChip(
        text: labels[i],
        isSelected: selectedIndex == i,
        colors: _SearchStyles.filterPalettes[i],
        onTap: () => _onSeeAll(i),
      ),
    );
  }

  List<Widget> _buildContent(final BuildContext context,
      final SearchResultState state, final int filter) {
    // Filtre 0: TÜMÜ Sekmesi (Her şey Yatay ve 10 Item Sınırlı)
    if (filter == 0)
      return [
        // 1. ETKİNLİKLER (YATAY MOZAİK)
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

        // 2. OYUNCULAR (YATAY LİSTE)
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

        // 3. MEKANLAR (YATAY LİSTE)
        if (state.stages.isNotEmpty)
          _HorizontalSection(
              title: "Mekanlar",
              items: state.stages.take(10).toList(),
              isStage: true,
              onSeeAll: () => _onSeeAll(3)),

        // 4. EKİPLER (YATAY LİSTE)
        if (state.teams.isNotEmpty)
          _HorizontalSection(
              title: "Ekipler",
              items: state.teams.take(10).toList(),
              isStage: false,
              onSeeAll: () => _onSeeAll(4)),
      ];

    // Diğer Filtreler (Oyuncular, Mekanlar, Ekipler) için Grid Görünümü
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
// 3. ATOMIC UI COMPONENTS
// =============================================================================

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
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : context.colors.onSurface.withOpacity(0.7),
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

  const ModernSearchBar(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: context.colors.primary.withOpacity(0.2), width: 1.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (final value) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: Icon(Icons.auto_awesome,
                    color: context.colors.primary, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        onPressed: () {
                          controller.clear();
                          onChanged("");
                        },
                      )
                    : null,
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

// --- Yatay Liste Bölümü (Mekanlar/Ekipler için) ---
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
  Widget build(final BuildContext context) {
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
            itemBuilder: (final context, final i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _GridCards.horizontalCard(context, items[i], isStage,
                  width: 260),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// =============================================================================
// 4. HELPERS & CARD WIDGETS
// =============================================================================

class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverFilterDelegate({required this.child});

  @override
  double get minExtent => 65;

  @override
  double get maxExtent => 65;

  @override
  Widget build(
          final BuildContext ctx, final double offset, final bool overlaps) =>
      child;

  @override
  bool shouldRebuild(covariant final SliverPersistentHeaderDelegate old) =>
      true;
}

class _GridCards {
  // Dikey Kart (Filtreli Görünümler için)
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
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      );

  // Yatay Kart (All sekmesi için)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(item.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      );
}

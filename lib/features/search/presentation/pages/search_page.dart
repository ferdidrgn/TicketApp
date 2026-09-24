import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_hero_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/widgets/mobile/show_mosaic_gallery.dart';
import '../providers/search_query_provider.dart';
import '../widgets/web/search_category_palette.dart';
import '../widgets/web/search_header_web.dart';
import '../widgets/web/search_result_cards_web.dart';

// =============================================================================
// 1. STYLE & CONSTANTS
// =============================================================================
//
// Filtre kategorilerinin (Tümü/Etkinlikler/Oyuncular/Mekanlar/Ekipler) renk
// kodlaması artık `SearchCategoryPalette` tek kaynağından geliyor — "Çam &
// Mercan" marka paletinden türetilmiş, birbirinden ayırt edilebilir 5 ton.
// Hem mobil hem masaüstü aynı kaynağı kullanır ki kategori kimliği tutarlı
// kalsın.

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

  /// Boş sonuç durumunda gerçek bir kategoriye "göz at" çipine dokunulunca:
  /// hem serbest metin sorgusunu temizler hem de o kategoriye geçer —
  /// böylece kullanıcı gerçekten var olan içeriği görür, uydurma bir öneri
  /// değil.
  void _onBrowseCategory(final int filterIndex) {
    _textController.clear();
    ref.read(searchQueryProvider.notifier).update("");
    ref.read(searchFilterProvider.notifier).setFilter(filterIndex);
  }

  @override
  Widget build(final BuildContext context) {
    final selectedFilter = ref.watch(searchFilterProvider);
    final searchState = ref.watch(searchResultProvider);
    final activeColor = SearchCategoryPalette.tintFor(selectedFilter)[0];
    // 🖥️ Masaüstü/web deneyimi: mobildeki renkli filtre paleti yerine
    // Çam & Mercan marka kimliğini (WebColors) kullanır. Mobil davranış
    // (activeColor, ambientColor vs.) hiç değişmez.
    final bool isDesktop = context.isDesktop;

    return BasePageWrapper(
        showBackButton: true,
        showFab: true,
        title: "Sanat Serüveni",
        isLoading: searchState.isLoading,
        customScrollController: scrollController,
        layoutConfig: BasePageLayoutConfig(
          ambientColor: isDesktop ? WebColors.primaryGold : activeColor,
          particleColor:
              (isDesktop ? WebColors.primaryGold : activeColor).withOpacity(0.1),
          backgroundColor: isDesktop ? WebColors.darkBlueBackground : null,
        ),
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Üst boşluk (Geri butonu ve Header için)
            SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top)),

            // Masaüstünde: büyük, editoryal "hero" girişi (Apple/Spotlight
            // hissi). Pinned çubuğun üstünde yer alır, aşağı kaydırılınca
            // sahneden çıkar. Mobilde hiç render edilmez.
            if (isDesktop)
              const SliverToBoxAdapter(child: SearchHeroIntro()),

            // Filtreler (Pinned Header)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverFilterDelegate(
                minExtent: isDesktop ? 108 : 110,
                maxExtent: isDesktop ? 108 : 110,
                child: isDesktop
                    ? _buildDesktopHeaderBar(context, selectedFilter)
                    : ClipRect(
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
              data: (final data) => isDesktop
                  ? _buildDesktopSearchResultContent(data, selectedFilter)
                  : _buildSearchResultContent(data, selectedFilter),
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (final e, final _) =>
                  SliverToBoxAdapter(child: Center(child: Text("Hata: $e"))),
            ),

            // Masaüstünde sonuçların altında ortak site alt bilgisi —
            // diğer masaüstü sayfalarıyla (ana sayfa, gösteri detayı, keşif
            // vb.) aynı desen. Mobilde hiç render edilmez.
            if (isDesktop) const SliverToBoxAdapter(child: Footer()),
          ],
        ));
  }

  // --- Masaüstü Pinned Header Çubuğu ---

  Widget _buildDesktopHeaderBar(
          final BuildContext context, final int selectedFilter) =>
      ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: WebColors.veryDarkBlue.withOpacity(0.88),
              border: Border(
                bottom: BorderSide(
                    color: WebColors.primaryGold.withOpacity(0.12)),
              ),
            ),
            alignment: Alignment.center,
            child: DesktopSearchCommandBar(
              controller: _textController,
              hintText: context.l10n.searchHint,
              onChanged: (final v) =>
                  ref.read(searchQueryProvider.notifier).update(v),
              onSubmitted: () => FocusScope.of(context).unfocus(),
              onClear: () {
                _textController.clear();
                ref.read(searchQueryProvider.notifier).update("");
              },
              selectedIndex: selectedFilter,
              onSelectFacet: _onSeeAll,
            ),
          ),
        ),
      );

  // --- Widget Oluşturucular (Sınıf İçinde Olmalı) ---

  Widget _buildIntegratedSearchField(final BuildContext context) {
    final bool isLarge = context.isTablet || context.isDesktop;

    return Center(
        // ✅ İçeriği ortala
        child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isLarge ? 800 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: labels.length,
          itemBuilder: (final context, final i) => ArtisticBrushChip(
            text: labels[i],
            isSelected: selectedIndex == i,
            colors: SearchCategoryPalette.tintFor(i),
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
              const SizedBox(height: AppSpacing.lg),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver:
              ShowMosaicGallery(shows: data.shows, direction: Axis.vertical));

    final content = _buildContentList(context, data, selectedFilter);
    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      sliver: SliverList(
        delegate:
            SliverChildListDelegate([...content, const SizedBox(height: 120)]),
      ),
    );
  }

  // ===========================================================================
  // MASAÜSTÜ SONUÇ İÇERİĞİ (Apple/Spotlight tarzı, geniş whitespace'li grid)
  // ===========================================================================

  Widget _buildDesktopSearchResultContent(
      final SearchResultState data, final int selectedFilter) {
    final query = ref.watch(searchQueryProvider);
    final bool isEmpty = data.shows.isEmpty &&
        data.players.isEmpty &&
        data.stages.isEmpty &&
        data.teams.isEmpty;

    if (isEmpty && query.isNotEmpty)
      return SliverFillRemaining(
        hasScrollBody: false,
        child: DesktopSearchEmptyState(
          message: context.l10n.searchEmptyState(query),
          clearLabel: context.l10n.searchClearGallery,
          onClear: () {
            _textController.clear();
            ref.read(searchQueryProvider.notifier).update("");
          },
          onBrowseCategory: _onBrowseCategory,
        ),
      );

    final content = _buildDesktopContentList(data, selectedFilter);
    final int totalCount = data.shows.length +
        data.players.length +
        data.stages.length +
        data.teams.length;
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.huge, AppSpacing.xxl, AppSpacing.huge, 140),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesktopResultsMetaBar(
                    count: totalCount,
                    filterIndex: selectedFilter,
                    query: query,
                  ),
                  ...content,
                ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDesktopContentList(
      final SearchResultState state, final int filter) {
    // "Tümü" filtresi: her kategori için editoryal bir bölüm.
    if (filter == 0)
      return [
        // Etkinlikler (shows) bölümü, diğer kategorilerin aksine ortak
        // `_buildDesktopSection`/`_buildDesktopGrid` sabit-oranlı grid'ini
        // KULLANMAZ — kart yüksekliği artık gerçek veriye (kategori/süre
        // rozeti var/yok) göre değişebildiğinden, masonry düzen için ayrı
        // bir bölüm gövdesi kurulur. Oyuncu/Mekan/Ekip bölümleri aşağıda
        // hiç değişmeden `_buildDesktopSection` üzerinden devam eder.
        if (state.shows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopSectionTitle(
                  title: "Etkinlikler",
                  subtitle: "Sanatın Akışı",
                  icon: SearchCategoryPalette.icons[SearchCategoryPalette.events],
                  onSeeAll: () => _onSeeAll(1),
                  accentColors:
                      SearchCategoryPalette.tints[SearchCategoryPalette.events],
                ),
                _buildDesktopShowGrid(
                  crossAxisCount: context.responsive(
                      mobile: 2, tablet: 3, desktop: 4, largeDesktop: 4),
                  shows: state.shows.take(8).toList(),
                ),
              ],
            ),
          ),
        if (state.players.isNotEmpty)
          _buildDesktopSection(
            title: "Oyuncular",
            subtitle: "Sahne Yıldızları",
            icon: SearchCategoryPalette.icons[SearchCategoryPalette.players],
            accentColors: SearchCategoryPalette.tints[SearchCategoryPalette.players],
            onSeeAll: () => _onSeeAll(2),
            // Kart artık küçük/oval (bkz. DesktopPlayerCard) — mobil
            // uygulamanın kendi oyuncu şeridi kadar minimal; bu yüzden
            // eskisinden (6 sütun, 0.62 oran) çok daha yoğun bir ızgara.
            // Avatar artık 84x128 uzun oval (eskiden 72x72 tam yuvarlak) —
            // kart oranı bu ek yüksekliğe göre 0.60'a düşürüldü, aksi
            // halde isim satırı hücreden taşabilirdi.
            crossAxisCount: context.responsive(
                mobile: 4, tablet: 6, desktop: 9, largeDesktop: 10),
            aspectRatio: 0.60,
            itemCount: state.players.take(20).length,
            itemBuilder: (final i) =>
                DesktopPlayerCard(player: state.players[i], index: i),
          ),
        if (state.stages.isNotEmpty)
          _buildDesktopSection(
            title: "Mekanlar",
            subtitle: "Sanatın Kalbi",
            icon: SearchCategoryPalette.icons[SearchCategoryPalette.stages],
            accentColors: SearchCategoryPalette.tints[SearchCategoryPalette.stages],
            onSeeAll: () => _onSeeAll(3),
            crossAxisCount: context.responsive(
                mobile: 2, tablet: 3, desktop: 4, largeDesktop: 4),
            aspectRatio: 1.1,
            itemCount: state.stages.take(8).length,
            itemBuilder: (final i) => DesktopPlaceCard(
                item: state.stages[i], index: i, isStage: true),
          ),
        if (state.teams.isNotEmpty)
          _buildDesktopSection(
            title: "Ekipler",
            subtitle: "Yaratıcı Gruplar",
            icon: SearchCategoryPalette.icons[SearchCategoryPalette.teams],
            accentColors: SearchCategoryPalette.tints[SearchCategoryPalette.teams],
            onSeeAll: () => _onSeeAll(4),
            crossAxisCount: context.responsive(
                mobile: 2, tablet: 3, desktop: 4, largeDesktop: 4),
            aspectRatio: 1.1,
            itemCount: state.teams.take(8).length,
            itemBuilder: (final i) => DesktopPlaceCard(
                item: state.teams[i], index: i, isStage: false),
          ),
      ];

    // Tekil filtre görünümleri: tüm sonuçlar tek bir geniş grid'de.
    final Widget grid;
    switch (filter) {
      case 1:
        grid = _buildDesktopShowGrid(
          crossAxisCount: context.responsive(
              mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5),
          shows: state.shows,
        );
        break;
      case 2:
        grid = _buildDesktopGrid(
          crossAxisCount: context.responsive(
              mobile: 4, tablet: 6, desktop: 9, largeDesktop: 11),
          aspectRatio: 0.78,
          itemCount: state.players.length,
          itemBuilder: (final i) =>
              DesktopPlayerCard(player: state.players[i], index: i),
        );
        break;
      case 3:
        grid = _buildDesktopGrid(
          crossAxisCount: context.responsive(
              mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5),
          aspectRatio: 1.1,
          itemCount: state.stages.length,
          itemBuilder: (final i) => DesktopPlaceCard(
              item: state.stages[i], index: i, isStage: true),
        );
        break;
      default:
        grid = _buildDesktopGrid(
          crossAxisCount: context.responsive(
              mobile: 2, tablet: 3, desktop: 4, largeDesktop: 5),
          aspectRatio: 1.1,
          itemCount: state.teams.length,
          itemBuilder: (final i) => DesktopPlaceCard(
              item: state.teams[i], index: i, isStage: false),
        );
    }

    return [grid];
  }

  Widget _buildDesktopSection({
    required final String title,
    required final String subtitle,
    required final IconData icon,
    required final VoidCallback onSeeAll,
    required final int crossAxisCount,
    required final double aspectRatio,
    required final int itemCount,
    required final Widget Function(int index) itemBuilder,
    final List<Color>? accentColors,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopSectionTitle(
                title: title,
                subtitle: subtitle,
                icon: icon,
                onSeeAll: onSeeAll,
                accentColors: accentColors),
            _buildDesktopGrid(
              crossAxisCount: crossAxisCount,
              aspectRatio: aspectRatio,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
          ],
        ),
      );

  Widget _buildDesktopGrid({
    required final int crossAxisCount,
    required final double aspectRatio,
    required final int itemCount,
    required final Widget Function(int index) itemBuilder,
  }) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 28,
          crossAxisSpacing: 28,
          childAspectRatio: aspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (final context, final i) => itemBuilder(i),
      );

  // SHOW kartları için ayrı, masonry grid. `DesktopShowCard` artık gerçek
  // veriye göre (bkz. `search_result_cards_web.dart` — `show.category` /
  // `show.duration` rozeti var/yok) farklı yüksekliklerde render edilebilir;
  // sabit `childAspectRatio`'lu `_buildDesktopGrid` bu farkı ezip tekdüze
  // bir ızgaraya zorlardı. `MasonryGridView.count`, her kolonun kendi
  // akışında kartları yüksekliklerine göre dizerek gerçek bir "dergi"
  // (magazine) düzeni oluşturur. Oyuncu/Mekan/Ekip grid'leri hâlâ
  // `_buildDesktopGrid`'i kullanır — burada dokunulmadı.
  Widget _buildDesktopShowGrid({
    required final int crossAxisCount,
    required final List<Show> shows,
  }) =>
      MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 28,
        crossAxisSpacing: 28,
        itemCount: shows.length,
        itemBuilder: (final context, final i) =>
            DesktopShowCard(show: shows[i], index: i),
      );

  List<Widget> _buildContentList(final BuildContext context,
      final SearchResultState state, final int filter) {
    if (filter == 0)
      return [
        if (state.shows.isNotEmpty) ...[
          SectionHeader(
              title: "Etkinlikler",
              subtitle: "Sanatın Akışı",
              onTap: () => _onSeeAll(1)),
          const SizedBox(height: AppSpacing.md),
          ShowMosaicGallery(
              shows: state.shows.take(10).toList(), direction: Axis.horizontal),
          const SizedBox(height: 30),
        ],
        if (state.players.isNotEmpty) ...[
          SectionHeader(
              title: "Oyuncular",
              subtitle: "Sahne Yıldızları",
              onTap: () => _onSeeAll(2)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: state.players.take(10).length,
              itemBuilder: (final context, final i) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.level3(primaryColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? context.colors.surface.withOpacity(0.05)
                    : context.colors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppRadius.xl),
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
  Widget build(final BuildContext context) => Semantics(
        button: true,
        selected: isSelected,
        label: text,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            margin: const EdgeInsets.symmetric(
                horizontal: 6, vertical: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: AppRadius.asymSm,
              gradient: isSelected ? LinearGradient(colors: colors) : null,
              color:
                  isSelected ? null : context.colors.surface.withOpacity(0.5),
              border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : context.colors.onSurface.withOpacity(0.1)),
              boxShadow:
                  isSelected ? AppShadows.level1(colors[0]) : AppShadows.level0,
            ),
            child: Center(
              child: Text(text,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : context.colors.onSurface.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 14)),
            ),
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
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: items.length,
              itemBuilder: (final context, final i) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
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
  final double _minExtent;
  final double _maxExtent;

  _SliverFilterDelegate({
    required this.child,
    final double minExtent = 110,
    final double maxExtent = 110,
  })  : _minExtent = minExtent,
        _maxExtent = maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

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
              boxShadow: AppShadows.level1(context.colors.shadow)),
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
              boxShadow: AppShadows.level1(context.colors.shadow)),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/shimmer_components.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import 'package:ticketapp/shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../widgets/web/discovery_category_filter.dart';
import '../widgets/web/discovery_featured_show.dart';
import '../widgets/web/discovery_hero.dart';
import '../widgets/web/discovery_show_card.dart';
import '../widgets/web/scroll_reveal.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  @override
  Widget build(final BuildContext context) {
    // Masaüstünde (>=1024px) tamamen ayrı, gerçek bir "premium" web keşif
    // deneyimi kullanılır (bkz. _DiscoveryDesktopPage). Mobil/tablet
    // görünümü aşağıdaki orijinal gövdeyle bire bir aynı kalır.
    if (context.isDesktop) {
      return _DiscoveryDesktopPage(selectedCategory: widget.selectedCategory);
    }

    final bool isLargeScreen = context.isTablet || context.isDesktop;
    // Web/masaüstünde sitenin geri kalanıyla aynı lacivert/altın "premium"
    // temayı, mobil uygulamada ise kendi Material temasını kullanır.
    final bool premium = context.isDesktop;

    return BasePageWrapper(
      title: widget.selectedCategory ?? 'İlhamını Bul',
      subtitle: widget.selectedCategory != null
          ? '${widget.selectedCategory} kategorisindeki etkinlikler'
          : 'Küratörlerin hazırladığı özel seçkiler',
      showBackButton: false,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor:
            premium ? WebColors.darkBlueBackground : context.colors.surface,
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 1200 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. ÖNE ÇIKAN BAŞYAPITLAR (gerçek oyun verisiyle)
              SectionHeader(
                title: 'Haftanın Başyapıtları',
                subtitle: 'Seçkiler',
                titleColor: premium ? Colors.white : null,
                accentColor: premium ? WebColors.primaryGold : null,
              ),
              const SizedBox(height: 16),
              _buildTrendingSlider(premium),

              const SizedBox(height: 40),

              // 2. KEŞİF LİSTESİ BAŞLIĞI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionHeader(
                    title: 'Tümünü Keşfet',
                    titleColor: premium ? Colors.white : null,
                    accentColor: premium ? WebColors.primaryGold : null,
                  ),
                  _buildFilterButton(premium),
                ],
              ),
              const SizedBox(height: 16),

              // 3. EVENT LIST (Responsive Grid veya List)
              _buildResponsiveEventList(isLargeScreen, premium),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSlider(final bool premium) {
    final showsState = ref.watch(showsProvider(isLimit: true));

    return SizedBox(
      height: 240,
      child: showsState.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (final context, final index) => const Padding(
            padding: EdgeInsets.only(right: 20),
            child: ShimmerLoading(width: 320, height: 240, borderRadius: 28),
          ),
        ),
        error: (final err, final stack) => Center(
          child: Text('Oyunlar yüklenemedi',
              style: TextStyle(
                  color: premium ? Colors.white70 : context.colors.error)),
        ),
        data: (final shows) {
          if (shows.isEmpty)
            return Center(
                child: Text('Henüz öne çıkan oyun yok',
                    style: TextStyle(
                        color: premium
                            ? Colors.white70
                            : context.colors.onSurfaceVariant)));

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shows.length,
            itemBuilder: (final context, final index) =>
                _buildTrendingCard(shows[index], premium),
          );
        },
      ),
    );
  }

  Widget _buildTrendingCard(final Show show, final bool premium) =>
      GestureDetector(
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
        child: Container(
          width: 320,
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: premium
                ? Border.all(color: WebColors.primaryGold.withOpacity(0.25))
                : null,
            boxShadow: [
              BoxShadow(
                  color: (premium ? Colors.black : context.colors.shadow)
                      .withOpacity(premium ? 0.4 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(
                    imageUrl: show.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildTag(show.category, premium),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: _buildShowInfo(show, premium),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildResponsiveEventList(
      final bool isLargeScreen, final bool premium) {
    // Web'de 2'li grid, mobilde alt alta liste
    if (isLargeScreen) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2.5,
        children: _getStaticEvents(premium),
      );
    }
    return Column(children: _getStaticEvents(premium, spacing: 16));
  }

  List<Widget> _getStaticEvents(final bool premium, {final double spacing = 0}) {
    final events = [
      EventsCard(
        imageUrl:
            'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
        showName: 'Hamlet - Bir Kimlik Meselesi',
        category: 'Dram',
        stage: 'Zorlu PSM',
        price: 240,
        fullDateString: '15 Haz 2026',
        timeString: '19:30',
        premium: premium,
      ),
      EventsCard(
        imageUrl:
            'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
        showName: 'Cimri - Şehir Tiyatroları',
        category: 'Komedi',
        stage: 'Kadıköy Sahnesi',
        price: 150,
        fullDateString: '20 Haz 2026',
        timeString: '20.30',
        premium: premium,
      ),
    ];

    if (spacing > 0) {
      return events
          .expand((final e) => [e, SizedBox(height: spacing)])
          .toList();
    }
    return events;
  }

  // --- KÜÇÜK UI BİLEŞENLERİ ---

  Widget _buildTag(final String tag, final bool premium) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: premium ? WebColors.goldGradient : null,
          color: premium ? null : context.colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(tag.toUpperCase(),
            style: TextStyle(
                color: premium ? WebColors.darkBlueBackground : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      );

  Widget _buildShowInfo(final Show show, final bool premium) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show.category.toUpperCase(),
              style: TextStyle(
                  color: premium ? WebColors.primaryGoldLight : context.colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.1)),
        ],
      );

  Widget _buildFilterButton(final bool premium) => Container(
        decoration: BoxDecoration(
          color: premium
              ? WebColors.primaryGold.withOpacity(0.12)
              : context.colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: premium
              ? Border.all(color: WebColors.primaryGold.withOpacity(0.3))
              : null,
        ),
        child: TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.tune_rounded,
              size: 18,
              color: premium ? WebColors.primaryGoldLight : context.colors.primary),
          label: Text('Filtrele',
              style: TextStyle(
                  color: premium ? WebColors.primaryGoldLight : context.colors.primary,
                  fontWeight: FontWeight.bold)),
        ),
      );
}

// =============================================================================
// MASAÜSTÜ (WEB) KEŞİF SAYFASI
// =============================================================================
//
// Mobil/tablet gövdesinden tamamen ayrı, gerçek gösteri verisiyle çalışan
// "premium" bir tarama deneyimi: sinematik editoryal başlık, öne çıkanlar
// şeridi, gerçek kategorilere göre filtre hapları, haftanın seçkisi paneli
// ve poster/fotoğraf hover geçişli bir keşif ızgarası. `show_detail_page_web`
// dosyasındaki BasePageWrapper + WebColors kullanım kalıbını izler.
class _DiscoveryDesktopPage extends StatelessWidget {
  final String? selectedCategory;

  const _DiscoveryDesktopPage({this.selectedCategory});

  @override
  Widget build(final BuildContext context) => BasePageWrapper(
        title: selectedCategory ?? 'İlhamını Bul',
        subtitle: selectedCategory != null
            ? '$selectedCategory kategorisindeki etkinlikler'
            : 'Küratörlerin hazırladığı özel seçkiler',
        showBackButton: false,
        showFab: true,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: WebColors.darkBlueBackground,
          ambientColor: WebColors.primaryGold.withOpacity(0.05),
          safeAreaTop: true,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: _DiscoveryDesktopBrowser(initialCategory: selectedCategory),
          ),
        ),
      );
}

class _DiscoveryDesktopBrowser extends ConsumerStatefulWidget {
  final String? initialCategory;

  const _DiscoveryDesktopBrowser({this.initialCategory});

  @override
  ConsumerState<_DiscoveryDesktopBrowser> createState() =>
      _DiscoveryDesktopBrowserState();
}

class _DiscoveryDesktopBrowserState
    extends ConsumerState<_DiscoveryDesktopBrowser> {
  String? _activeCategory;

  // "Aktif Oyunlar" (varsayılan) / "Geçmiş Oyunlar" (arşiv) görünümü
  // arasındaki anahtar. Kategori seçimi her iki listede de kalıcı — sadece
  // hangi Show listesinin süzüldüğü değişir.
  bool _showPast = false;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
  }

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  @override
  Widget build(final BuildContext context) {
    // Varsayılan/ana tarama listesi artık `activeShowsProvider` — takviminde
    // en az bir GELECEK etkinliği olan oyunlar (bkz. show_provider.dart).
    // Geçmişi/arşivi gösteren "Geçmiş Oyunlar" moduna geçildiğinde aynı
    // AsyncValue<List<Show>> şeklini koruyan `pastShowsProvider`e geçilir —
    // her iki provider de `showsProvider`in "en yeni N oyun" limitini
    // (isLimit) miras alır; burada tam listeyi istediğimiz için `false`
    // geçiyoruz (aynı `showsProvider(isLimit: false)` çağrısının yerini
    // alıyor).
    final showsState = _showPast
        ? ref.watch(pastShowsProvider(false))
        : ref.watch(activeShowsProvider(false));

    return showsState.when(
      loading: () => _buildLoading(),
      error: (final err, final stack) => _buildError(),
      data: (final shows) {
        if (shows.isEmpty) return _buildEmpty();
        return _buildBrowser(context, shows);
      },
    );
  }

  Widget _buildBrowser(final BuildContext context, final List<Show> shows) {
    final categories = <String>{
      for (final show in shows)
        if (show.category.trim().isNotEmpty) show.category,
    }.toList()
      ..sort();

    // Aktif kategori artık veride yoksa (ör. filtre eskimişse, ya da mod
    // değiştiğinde o kategoride hiç geçmiş/aktif oyun kalmadıysa) "Tümü"ne
    // düş.
    final String? activeCategory =
        (_activeCategory != null && categories.contains(_activeCategory))
            ? _activeCategory
            : null;

    final List<Show> filtered = activeCategory == null
        ? shows
        : shows.where((final s) => s.category == activeCategory).toList();

    // "Haftanın Başyapıtları" (öne çıkanlar şeridi) ve "Haftanın Seçkisi"
    // (büyük öne çıkan panel) kavramsal olarak sadece AKTİF tarama modunda
    // anlamlı — bir arşiv görünümünde her şey zaten geçmiş, "öne çıkan"
    // vurgusu yanıltıcı olurdu. Geçmiş Oyunlar modunda direkt kategori
    // filtresi + ızgaraya geçiyoruz.
    final List<Show> trending = _showPast ? const [] : shows.take(6).toList();
    final Show? featured =
        (!_showPast && filtered.isNotEmpty) ? filtered.first : null;
    final List<Show> gridShows = featured == null
        ? filtered
        : filtered.where((final s) => s.id != featured.id).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 36),
      children: [
        ScrollReveal(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DiscoveryHero(
              categoryLabel: activeCategory,
              showCount: shows.length,
              archiveMode: _showPast,
            ),
          ),
        ),
        const SizedBox(height: 28),
        ScrollReveal(
          delay: const Duration(milliseconds: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildModeToggle(),
          ),
        ),
        const SizedBox(height: 36),
        if (!_showPast) ...[
          ScrollReveal(
            delay: const Duration(milliseconds: 80),
            child: SectionHeader(
              title: 'Haftanın Başyapıtları',
              subtitle: 'Seçkiler',
              titleColor: Colors.white,
              accentColor: WebColors.primaryGold,
            ),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 120),
            child: _buildTrendingRow(trending),
          ),
          const SizedBox(height: 64),
        ],
        ScrollReveal(
          child: SectionHeader(
            title: _showPast ? 'Geçmiş Oyunlar' : 'Tümünü Keşfet',
            subtitle: _showPast ? 'Arşiv' : null,
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        ScrollReveal(
          delay: const Duration(milliseconds: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DiscoveryCategoryFilter(
              categories: categories,
              selected: activeCategory,
              onSelected: (final category) =>
                  setState(() => _activeCategory = category),
            ),
          ),
        ),
        const SizedBox(height: 36),
        if (featured != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ScrollReveal(
              child: DiscoveryFeaturedShow(
                key: ValueKey('featured-${featured.id}'),
                show: featured,
                onTap: () => _openShow(featured),
              ),
            ),
          )
        else if (!_showPast)
          _buildEmptyCategoryNotice(showPast: false),
        const SizedBox(height: 56),
        if (gridShows.isEmpty && _showPast)
          _buildEmptyCategoryNotice(showPast: true)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildGrid(gridShows),
          ),
        const SizedBox(height: 100),
      ],
    );
  }

  /// "Aktif Oyunlar" / "Geçmiş Oyunlar" arasında geçiş yapan segmentli
  /// kontrol. Mobil tarafta karşılığı yok — bu tamamen masaüstüne özel,
  /// arşivin görünmez kalmaması için eklenen gerçek bir tarama yolu.
  Widget _buildModeToggle() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModePill(
            label: 'Aktif Oyunlar',
            icon: Icons.theater_comedy_rounded,
            isActive: !_showPast,
            onTap: () {
              if (_showPast) setState(() => _showPast = false);
            },
          ),
          const SizedBox(width: 12),
          _ModePill(
            label: 'Geçmiş Oyunlar',
            icon: Icons.inventory_2_outlined,
            isActive: _showPast,
            onTap: () {
              if (!_showPast) setState(() => _showPast = true);
            },
          ),
        ],
      );

  Widget _buildTrendingRow(final List<Show> shows) {
    if (shows.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 360,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: shows.length,
        itemBuilder: (final context, final index) {
          final show = shows[index];
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: ScrollReveal(
              delay: Duration(milliseconds: 60 * index),
              offsetY: 18,
              child: SizedBox(
                width: 260,
                child: DiscoveryShowCard(
                  key: ValueKey('trending-${show.id}'),
                  imageUrl: show.imageUrl,
                  secondaryImageUrl: show.photosShowId.isNotEmpty
                      ? show.photosShowId.first
                      : null,
                  title: show.name,
                  category: show.category,
                  description: show.description,
                  onTap: () => _openShow(show),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(final List<Show> shows) {
    if (shows.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 32,
        crossAxisSpacing: 28,
        childAspectRatio: 0.72,
      ),
      itemCount: shows.length,
      itemBuilder: (final context, final index) {
        final show = shows[index];
        return ScrollReveal(
          delay: Duration(milliseconds: 50 * (index % 6)),
          child: DiscoveryShowCard(
            key: ValueKey('grid-${show.id}'),
            imageUrl: show.imageUrl,
            secondaryImageUrl:
                show.photosShowId.isNotEmpty ? show.photosShowId.first : null,
            title: show.name,
            category: show.category,
            description: show.description,
            onTap: () => _openShow(show),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCategoryNotice({required final bool showPast}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          showPast
              ? 'Bu kategoride arşivlenmiş (geçmiş) oyun yok.'
              : 'Bu kategoride henüz bir oyun yok.',
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );

  Widget _buildLoading() => SizedBox(
        height: 480,
        child: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
          ),
        ),
      );

  Widget _buildError() => Center(
        child: Text(
          'Oyunlar yüklenemedi',
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Text(
          _showPast ? 'Arşivde henüz geçmiş oyun yok' : 'Henüz aktif oyun yok',
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );
}

/// "Aktif Oyunlar" / "Geçmiş Oyunlar" anahtarının tek bir hap (pill)
/// düğmesi. `discovery_category_filter.dart`'taki `_CategoryPill` ile aynı
/// hover/aktif görsel dilini izler, böylece sayfa genelinde tutarlı kalır.
class _ModePill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ModePill> createState() => _ModePillState();
}

class _ModePillState extends State<_ModePill> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool highlight = widget.isActive || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isActive ? WebColors.goldGradient : null,
            color: widget.isActive
                ? null
                : (_hovered
                    ? WebColors.primaryGold.withOpacity(0.14)
                    : WebColors.darkBlueSurface.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlight
                  ? WebColors.primaryGold.withOpacity(widget.isActive ? 1 : 0.6)
                  : WebColors.primaryGold.withOpacity(0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? WebColors.darkBlueBackground
                    : WebColors.whiteText,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive
                      ? WebColors.darkBlueBackground
                      : WebColors.whiteText,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

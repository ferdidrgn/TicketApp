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

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  @override
  Widget build(final BuildContext context) {
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

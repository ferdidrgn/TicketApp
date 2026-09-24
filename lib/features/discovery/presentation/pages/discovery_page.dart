import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/shimmer_components.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import 'package:ticketapp/shared/widgets/section_header.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../../../shows/presentation/widgets/recommended_shows_section.dart';
import '../providers/nearby_events_provider.dart';
import '../utils/category_stats.dart';
import '../widgets/web/discovery_category_filter.dart';
import '../widgets/web/discovery_category_showcase.dart';
import '../widgets/web/discovery_featured_show.dart';
import '../widgets/web/discovery_hero.dart';
import '../widgets/web/discovery_show_card.dart';
import '../widgets/web/discovery_stage_showcase.dart';
import '../widgets/web/discovery_team_showcase.dart';
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
              // 1. AKTİF OYUNLAR / DİĞER OYUNLAR — takviminde gelecek
              // etkinliği olan gerçek "aktif" oyunlar kendi başlığı
              // altında, aktif OLMAYANLAR "Diğer Oyunlar" başlığı altında.
              // Hiçbir oyun gizlenmiyor — sadece görsel/başlıklı bir ayrım
              // ekleniyor. Aktiflik mantığı burada YENİDEN YAZILMIYOR:
              // `show_provider.dart`'taki `activeShowsProvider`/
              // `showsActiveFirstProvider` (`_activeShowIdsFromEvents`den
              // türeyen) aynen tüketiliyor.
              _buildActiveOtherShowSections(premium),

              // 1a. SANA ÖZEL — kullanıcının GERÇEK favori/satın alma
              // geçmişinden türetilmiş öneriler (bkz.
              // recommended_shows_provider.dart). Gerçek sinyal yoksa
              // (misafir/yeni kullanıcı) sessizce hiçbir şey render etmez.
              const RecommendedShowsSection(),

              // 1b. KATEGORİLER — gerçek `show.category` dağılımından
              // türetilen ("uydurma" bir kategori listesi DEĞİL), yatay
              // kaydırmalı bir "yelpaze" şeridi (bkz. `category_stats.dart`
              // — masaüstüyle AYNI hesap fonksiyonu). Kategorisi olan
              // gerçek oyun yoksa hiçbir şey render etmez.
              _buildCategoryShowcaseSection(),

              // 1c. SAHNELER — gerçek `stagesProvider`'dan, her sahne için
              // GERÇEK "kaç oyun sahnelendi" sayısıyla (`Stage.showsId`)
              // yatay kaydırmalı bir şerit. Gerçek sahne yoksa gizlenir.
              _buildStageShowcaseSection(),

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

              // Web masaüstü deneyiminde sayfanın sonuna site geneli footer eklenir.
              if (premium) const Footer(),
            ],
          ),
        ),
      ),
    );
  }

  // `showsActiveFirstProvider`/`activeShowsProvider` (show_provider.dart)
  // burada da aynen tüketiliyor — "aktif" hesabı elle tekrar YAZILMIYOR.
  // `all` HİÇBİR oyunu gizlemez (aktif önce sıralı, tam liste);
  // `activeState`'ten gelen gerçek aktif id kümesiyle iki gerçek alt
  // listeye (aktif / diğer) bölünüyor, ikisi de aynı sayfada gösteriliyor.
  Widget _buildActiveOtherShowSections(final bool premium) {
    final allState = ref.watch(showsActiveFirstProvider(true));
    final activeState = ref.watch(activeShowsProvider(true));

    if (allState.isLoading && allState.value == null) {
      return SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (final context, final index) => const Padding(
            padding: EdgeInsets.only(right: 20),
            child: ShimmerLoading(width: 320, height: 240, borderRadius: 28),
          ),
        ),
      );
    }

    if (allState.hasError) {
      return Center(
        child: Text('Oyunlar yüklenemedi',
            style: TextStyle(
                color: premium ? Colors.white70 : context.colors.error)),
      );
    }

    final List<Show> all = allState.value ?? const <Show>[];
    if (all.isEmpty) {
      return Center(
          child: Text('Henüz öne çıkan oyun yok',
              style: TextStyle(
                  color: premium
                      ? Colors.white70
                      : context.colors.onSurfaceVariant)));
    }

    // `activeState` henüz yüklenmediyse (kısa bir an) geçici olarak boş
    // kümeye düşer — `all` zaten aktif-önce sıralı geldiği için görsel
    // olarak yanlış bir şey göstermez, sadece başlıklı ayrım bir an
    // gecikebilir.
    final Set<String> activeIds =
        (activeState.value ?? const <Show>[]).map((final s) => s.id).toSet();
    final List<Show> active =
        all.where((final s) => activeIds.contains(s.id)).toList();
    final List<Show> other =
        all.where((final s) => !activeIds.contains(s.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active.isNotEmpty) ...[
          SectionHeader(
            title: 'Aktif Oyunlar',
            subtitle: 'Sahnede',
            titleColor: premium ? Colors.white : null,
            accentColor: premium ? WebColors.primaryGold : null,
          ),
          const SizedBox(height: 16),
          _buildShowRow(active, premium),
        ],
        if (active.isNotEmpty && other.isNotEmpty)
          const SizedBox(height: 32),
        if (other.isNotEmpty) ...[
          SectionHeader(
            title: 'Diğer Oyunlar',
            subtitle: 'Arşiv',
            titleColor: premium ? Colors.white : null,
            accentColor: premium ? WebColors.primaryGold : null,
          ),
          const SizedBox(height: 16),
          _buildShowRow(other, premium),
        ],
      ],
    );
  }

  Widget _buildShowRow(final List<Show> shows, final bool premium) =>
      SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: shows.length,
          itemBuilder: (final context, final index) =>
              _buildTrendingCard(shows[index], premium),
        ),
      );

  // Kategoriler ve Sahneler şeritleri her ikisi de GERÇEK, bu sayfada
  // başka amaçla zaten kullanılan verilerden geliyor — hiçbir yeni
  // Firestore sorgusu/provider icat edilmedi:
  //   * Kategoriler: `showsActiveFirstProvider(false)` (TAM katalog, hiçbir
  //     oyun gizlenmez) + `category_stats.dart`'taki paylaşılan
  //     `buildCategoryStats` (masaüstüyle AYNI hesap).
  //   * Sahneler: `stagesProvider(isLimit: false)` — `Stage.showsId.length`
  //     GERÇEK "kaç oyun sahnelendi" sayısı.
  //
  // İkisi de veri boşsa (ya da henüz yüklenmediyse) sessizce hiçbir şey
  // render etmez — sahte/placeholder bir bölüm göstermez.

  Widget _buildCategoryShowcaseSection() {
    final showsState = ref.watch(showsActiveFirstProvider(false));
    final List<CategoryStat> stats =
        buildCategoryStats(showsState.value ?? const <Show>[]);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Kategoriler', subtitle: 'Yelpazemiz'),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: stats.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final index) =>
                  _MobileCategoryCard(
                stat: stats[index],
                onTap: () => NavigationHandler.goToDiscoverWithCategory(
                    context, stats[index].category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageShowcaseSection() {
    final stagesState = ref.watch(stagesProvider(isLimit: false));
    final List<Stage> stages = stagesState.value ?? const <Stage>[];
    if (stages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sahneler', subtitle: 'Mekanlar'),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: stages.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (final context, final index) {
                final stage = stages[index];
                return _MobileStageCard(
                  stage: stage,
                  onTap: () => NavigationHandler.goToStage(
                      context, stage.id, stage.name),
                );
              },
            ),
          ),
        ],
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

  // `upcomingNearbyEventsProvider` (bkz. `nearby_events_provider.dart`) zaten
  // gerçek, Firestore kökenli YAKLAŞAN etkinlikleri; ait oldukları gösteri ve
  // gerçekleştikleri sahneyle birleştirilmiş halde döndüren, bu oturumda
  // başka bir sayfa için kurulmuş bir provider — burada da aynen yeniden
  // kullanılıyor, ikinci bir Firestore sorgusu/provider icat edilmiyor.
  Widget _buildResponsiveEventList(
      final bool isLargeScreen, final bool premium) {
    final eventsState = ref.watch(upcomingNearbyEventsProvider);

    return eventsState.when(
      loading: () => _buildEventListLoading(isLargeScreen),
      error: (final err, final stack) => _buildEventListMessage(
          'Etkinlikler yüklenemedi', premium,
          isError: true),
      data: (final entries) {
        if (entries.isEmpty)
          return _buildEventListMessage(
              'Şu an yaklaşan bir etkinlik yok', premium);

        final cards = _buildEventCards(entries, premium);
        // Web'de 2'li grid, mobilde alt alta liste
        if (isLargeScreen) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2.5,
            children: cards,
          );
        }
        return Column(
          children: cards
              .expand((final e) => [e, const SizedBox(height: 16)])
              .toList(),
        );
      },
    );
  }

  List<Widget> _buildEventCards(
      final List<NearbyEventEntry> entries, final bool premium) {
    return entries.map((final entry) {
      final dateParts = DateFormatter.formatForEventCard(entry.event.date);
      final String fullDateString =
          '${dateParts['day']} ${dateParts['monthName']}';
      return EventsCard(
        imageUrl: entry.show.imageUrl,
        showName: entry.show.name,
        category: entry.show.category,
        stage: entry.stage.name,
        price: double.tryParse(entry.event.price) ?? 0.0,
        fullDateString: fullDateString,
        timeString: dateParts['time'] ?? '--:--',
        premium: premium,
        onTap: () =>
            NavigationHandler.goToShow(context, entry.show.id, entry.show.name),
      );
    }).toList();
  }

  Widget _buildEventListLoading(final bool isLargeScreen) {
    final shimmers = List.generate(
      isLargeScreen ? 4 : 2,
      (final _) =>
          const ShimmerLoading(width: 280, height: 280, borderRadius: 28),
    );

    if (isLargeScreen) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 2.5,
        children: shimmers,
      );
    }
    return Column(
      children: shimmers
          .expand((final e) => [e, const SizedBox(height: 16)])
          .toList(),
    );
  }

  Widget _buildEventListMessage(final String message, final bool premium,
          {final bool isError = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
                color: premium
                    ? Colors.white70
                    : (isError
                        ? context.colors.error
                        : context.colors.onSurfaceVariant)),
          ),
        ),
      );

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

/// Mobil "Kategoriler" şeridinin tek kartı — GERÇEK `show.category`
/// dağılımından gelen bir `CategoryStat` (kategori adı + o kategorideki
/// GERÇEK oyun sayısı + kategorideki bir oyunun GERÇEK afişi). Mobil
/// tarafın kendi Material temasını (`context.colors`) kullanır — bu sayfa
/// masaüstündeki gibi `WebColors` ile "premium" temalanmıyor (bkz. dosya
/// başındaki mobil/masaüstü ayrımı).
class _MobileCategoryCard extends StatelessWidget {
  final CategoryStat stat;
  final VoidCallback onTap;

  const _MobileCategoryCard({required this.stat, required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '${stat.category} kategorisi, ${stat.count} oyun',
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              borderRadius: AppRadius.asymSm,
              boxShadow: AppShadows.level1(context.colors.shadow),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.asymSm,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedCachedImage(
                    imageUrl: stat.sampleImageUrl,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.72),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stat.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${stat.count} oyun',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Mobil "Sahneler" şeridinin tek kartı — GERÇEK `Stage` verisi + o
/// sahnede sahnelenen GERÇEK oyun sayısı (`Stage.showsId.length`).
class _MobileStageCard extends StatelessWidget {
  final Stage stage;
  final VoidCallback onTap;

  const _MobileStageCard({required this.stage, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final int showCount = stage.showsId.length;
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${stage.name} sahnesi, $showCount oyun sahnelendi',
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            borderRadius: AppRadius.asymSm,
            boxShadow: AppShadows.level1(context.colors.shadow),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.asymSm,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(
                  imageUrl: stage.imageUrl,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.72),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stage.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        showCount == 1
                            ? '1 oyun sahnelendi'
                            : '$showCount oyun sahnelendi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
/// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — o mobil uygulama
/// çatısıdır (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı, pull-to-
/// refresh, `CustomAppBackground`'ın renksiz/rastgele parçacık noktaları
/// — burada `particleColor` hiç verilmediği için `context.primaryColor`
/// gibi markaya ait olmayan bir renkle geliyordu). Bunlar
/// `home_page_web.dart`'ta "Android uygulaması gibi görünüyor" şikayetinin
/// asıl sebebiydi (bkz. o dosyadaki aynı gerekçe). Üst navigasyon zaten
/// `WebTopNavigationBar`'dan geliyor — burada ikinci bir gradyanlı başlık
/// çubuğuna gerek yok. Sade, düz zeminli bir kaydırma alanı.
class _DiscoveryDesktopPage extends StatelessWidget {
  final String? selectedCategory;

  const _DiscoveryDesktopPage({this.selectedCategory});

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: `_DiscoveryDesktopBrowser` kendi `ListView`'ı ile zaten
        // kaydırılabilir — ikinci bir SingleChildScrollView SARMAK
        // "unbounded height" hatasına yol açar, bilerek eklenmedi.
        //
        // KRİTİK: genişlik kısıtı (max-width) BURADA, `ListView`'ın
        // KENDİSİNİ sarmıyor artık — `ListView` (scroll edilen katman)
        // tam genişlikte kalmalı ki tarayıcı scrollbar'ı gerçek sağ
        // kenarda otursun. Eskiden Center+ConstrainedBox ListView'ın
        // DIŞINI sarıyordu; bu da scrollbar'ı 1180-1360px'lik kutunun
        // kenarına (yani ekranın ortasına yakın bir yere) düşürüyordu —
        // diğer web sayfalarından (home_page_web.dart vb., hep dış
        // scrollable TAM genişlikte) farklı davranmasının sebebi buydu.
        // Genişlik kısıtı artık `_buildBrowser`'ın İÇİNDE, ListView'ın
        // TEK çocuğunu (tüm içerik Column'ı) sarıyor.
        color: WebColors.darkBlueBackground,
        child: _DiscoveryDesktopBrowser(initialCategory: selectedCategory),
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

  // Hero'nun arka plan fotoğrafı — `TheatreShowCard`'daki ("bir kez
  // rastgele seç, sonra state yaşadığı sürece sabit kal") ilkesiyle AYNI:
  // bu widget state'i canlı kaldığı sürece BİR KEZ seçilir, mod/kategori
  // değiştikçe (rebuild'lerde) tekrar zar atılmaz — aksi halde kullanıcı
  // "Geçmiş Oyunlar"a geçtiğinde hero fotoğrafı rahatsız edici şekilde
  // değişirdi.
  String? _heroBackdropUrl;
  final Random _random = Random();

  // 🔥 DÜZELTME: "Haftanın Başyapıtları" şeridi (bkz. `_buildTrendingRow`)
  // dikey kaydırılan sayfanın İÇİNDE yatay bir `ListView` — web'de fare
  // tekerleği varsayılan olarak SADECE dikey kaydırmayı bu iç listeye değil
  // dış sayfaya yönlendiriyor, bu yüzden yatay kaydırma fare tekerleğiyle
  // "çalışmıyor" gibi görünüyordu (sürükleme ile teknik olarak mümkündü
  // ama masaüstü kullanıcısının beklediği davranış bu değil). Kendi
  // `ScrollController`'ı + aşağıdaki `Listener` ile dikey tekerlek
  // delta'sı bu listenin yatay kaydırmasına çevriliyor.
  final ScrollController _trendingScrollController = ScrollController();

  @override
  void dispose() {
    _trendingScrollController.dispose();
    super.dispose();
  }

  String? _pickHeroBackdrop(final List<Show> shows) {
    if (_heroBackdropUrl != null) return _heroBackdropUrl;
    if (shows.isEmpty) return null;
    final withPhotos =
        shows.where((final s) => s.photosShowId.isNotEmpty).toList();
    if (withPhotos.isNotEmpty) {
      final show = withPhotos[_random.nextInt(withPhotos.length)];
      return _heroBackdropUrl =
          show.photosShowId[_random.nextInt(show.photosShowId.length)];
    }
    // Hiçbir oyunun galeri fotoğrafı yoksa gerçek afişine (imageUrl) düş —
    // asla uydurma bir görsel değil.
    return _heroBackdropUrl = shows[_random.nextInt(shows.length)].imageUrl;
  }

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
  }

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  @override
  Widget build(final BuildContext context) {
    // Varsayılan/ana tarama listesi `showsActiveFirstProvider` — HİÇBİR
    // oyun gizlenmez, sadece takviminde gelecek etkinliği olan (aktif)
    // oyunlar öne alınır, ardından (yer kaldıysa) aktif olmayanlar gelir
    // (bkz. show_provider.dart). Kullanıcı bilerek "Geçmiş Oyunlar"
    // moduna geçtiğinde SADECE geçmiş oyunları gösteren `pastShowsProvider`e
    // geçilir — bu, kullanıcının kendi seçtiği bir filtre, gizlenen bir
    // şey değil. Her iki provider de `showsProvider`in "en yeni N oyun"
    // limitini (isLimit) miras alır; burada tam listeyi istediğimiz için
    // `false` geçiyoruz.
    final showsState = _showPast
        ? ref.watch(pastShowsProvider(false))
        : ref.watch(showsActiveFirstProvider(false));

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
    // `shows` burada `showsActiveFirstProvider`'ın TÜM sonucu (aktif +
    // aktif olmayan, hiçbiri gizlenmiyor) — rozetin "AKTİF OYUN" yazıp
    // bu listenin tam uzunluğunu (ör. 5) göstermesi yanıltıcıydı, çünkü
    // gerçekte bunların çoğu aktif olmayabilir. Rozet için (ve aşağıdaki
    // ızgaranın "Aktif Oyunlar"/"Diğer Oyunlar" ayrımı için) gerçek aktif
    // Show listesini TEK bir yerden okuyoruz; arşiv modunda zaten etiket
    // "GEÇMİŞ OYUN"a dönüyor ve `shows` doğrudan geçmiş oyunlar olduğu için
    // orada bu ayrıma gerek yok.
    final List<Show>? realActiveShows =
        ref.watch(activeShowsProvider(false)).value;
    final Set<String> realActiveIds =
        (realActiveShows ?? const <Show>[]).map((final s) => s.id).toSet();
    final int activeCount =
        _showPast ? shows.length : (realActiveShows?.length ?? shows.length);
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

    // Kullanıcının "aktif pasif ayırmayalım, hepsi gelsin" talimatı
    // korunuyor — `gridShows` hâlâ TAM liste (kategori filtresiyle
    // süzülmüş, hiçbir oyun ekstra gizlenmiyor). Sadece görsel/başlıklı
    // bir ayrım için `gridShows`, gerçek aktif id kümesine (`realActiveIds`)
    // göre iki gerçek alt listeye bölünüyor. Arşiv (`_showPast`) modunda
    // zaten hepsi aktif değildir (pastShowsProvider'dan geldiği için) —
    // orada tek bir "Diğer Oyunlar/Arşiv" ızgarası yeterli, üstteki
    // "Geçmiş Oyunlar" SectionHeader'ı zaten aynı anlamı taşıyor.
    final List<Show> activeGridShows = _showPast
        ? const []
        : gridShows.where((final s) => realActiveIds.contains(s.id)).toList();
    final List<Show> otherGridShows = _showPast
        ? gridShows
        : gridShows.where((final s) => !realActiveIds.contains(s.id)).toList();

    // Kategoriler vitrini HER ZAMAN uygulamanın TAM kataloğundan türetilir
    // (mod/kategori filtresinden bağımsız) — "Geçmiş Oyunlar" modundayken
    // bile gerçek geniş yelpazeyi göstersin diye. `!_showPast` durumunda
    // `shows` zaten bu tam katalog (bkz. yukarıdaki `showsState` yorumu),
    // `_showPast` durumunda ayrıca watch ediliyor.
    final List<Show> categoryOverviewShows = _showPast
        ? (ref.watch(showsActiveFirstProvider(false)).value ?? shows)
        : shows;
    final List<CategoryStat> categoryStats =
        buildCategoryStats(categoryOverviewShows);

    // Sahneler/Topluluklar vitrinleri — gerçek `stagesProvider`/
    // `teamsProvider`, tam liste (`isLimit: false`). Bu sayfada başka bir
    // amaçla zaten kullanılan bir Firestore sorgusu icat edilmedi.
    final List<Stage> allStages =
        ref.watch(stagesProvider(isLimit: false)).value ?? const <Stage>[];
    final List<Team> allTeams =
        ref.watch(teamsProvider(isLimit: false)).value ?? const <Team>[];

    // 🔥 DÜZELTME ("yarım/ortada duruyor" şikayeti): genişlik kısıtı
    // (max-width) artık HERO'yu sarmıyor — hero, `ListView`'ın doğrudan
    // çocuğu olarak (`_DiscoveryDesktopPage`'in tam genişlikteki
    // `ColoredBox`'ı içinde) tarayıcının TAM genişliğine yayılan, gerçek
    // bir "fullscreen editorial" bant (bkz. `DiscoveryHero(fullBleed:
    // true)` ve `home_page_web.dart`'taki `_HeroBand` referans tekniği).
    // Genişlik kısıtı sadece HERO'DAN SONRAKİ içerik Column'ını sarıyor —
    // `ListView`'ın kendisi hâlâ tam genişlikte kalıyor ki scrollbar
    // gerçek sağ kenarda otursun (bkz. yukarıdaki `_DiscoveryDesktopPage`
    // yorumu). `Footer` de aynı sebeple bu ConstrainedBox'ın DIŞINDA, en
    // altta ayrı bir `ListView` çocuğu olarak eklenir (bkz. metodun sonu).
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 32),
        ScrollReveal(
          child: DiscoveryHero(
            categoryLabel: activeCategory,
            showCount: activeCount,
            archiveMode: _showPast,
            backdropImageUrl: _pickHeroBackdrop(shows),
            fullBleed: true,
          ),
        ),
        const SizedBox(height: 36),
        // Geniş monitörlerde (>=1440px) içerik genişliği artık 1360 değil
        // 1680 — ızgara (`_buildGrid`) `maxCrossAxisExtent: 300` kullandığı
        // için bu genişleme kart boyutunu ŞİŞİRMEK yerine otomatik olarak
        // DAHA FAZLA SÜTUN açar (5-6 sütun), yani gerçekten daha fazla
        // içerik gösterir — sadece boş kenar boşluğu büyümez.
        Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1680 : 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
        ScrollReveal(
          delay: const Duration(milliseconds: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildModeToggle(),
          ),
        ),
        const SizedBox(height: 36),
        // SANA ÖZEL — kullanıcının GERÇEK favori/satın alma geçmişinden
        // türetilmiş öneriler (bkz. recommended_shows_provider.dart).
        // Gerçek sinyal yoksa (misafir/yeni kullanıcı) widget'ın kendisi
        // sessizce hiçbir şey render etmez.
        ScrollReveal(
          delay: const Duration(milliseconds: 80),
          child: const RecommendedShowsSection(),
        ),
        // KATEGORİLER — GERÇEK `Show.category` dağılımından türetilen bir
        // vitrin şeridi (kategori + kategorideki GERÇEK oyun sayısı +
        // kategoriden bir GERÇEK afiş). Mod (Aktif/Geçmiş) değişse bile
        // uygulamanın TAM yelpazesini gösterir (bkz. `categoryStats`
        // yorumu). Gerçek kategorili oyun yoksa hiçbir şey render etmez.
        if (categoryStats.isNotEmpty) ...[
          ScrollReveal(
            delay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionHeader(
                title: 'Kategoriler',
                subtitle: 'Yelpazemiz',
                titleColor: Colors.white,
                accentColor: WebColors.primaryGold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DiscoveryCategoryShowcase(
                stats: categoryStats,
                // Gerçek, çalışan bir filtre: mevcut kategori hap
                // filtresiyle (`DiscoveryCategoryFilter`) AYNI
                // `_activeCategory` state'ini paylaşır — yeni bir
                // navigasyon icat etmiyor, sayfanın kendi filtresini
                // kullanıyor.
                onCategoryTap: (final category) =>
                    setState(() => _activeCategory = category),
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
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
        else if (_showPast)
          // Arşiv modunda zaten hepsi geçmiş — üstteki "Geçmiş Oyunlar"
          // başlığı yeterli, ayrıca "Aktif Oyunlar" alt başlığına gerek yok.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildGrid(otherGridShows),
          )
        else ...[
          // Aktif tarama modunda gerçek bir görsel ayrım: takviminde
          // gelecek etkinliği olan oyunlar "Aktif Oyunlar" ızgarasında,
          // aktif OLMAYANLAR "Diğer Oyunlar" ızgarasında — ikisi de
          // gösteriliyor, hiçbiri gizlenmiyor.
          if (activeGridShows.isNotEmpty) ...[
            ScrollReveal(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: 'Aktif Oyunlar',
                  subtitle: 'Sahnede',
                  titleColor: Colors.white,
                  accentColor: WebColors.primaryGold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildGrid(activeGridShows),
            ),
            if (otherGridShows.isNotEmpty) const SizedBox(height: 48),
          ],
          if (otherGridShows.isNotEmpty) ...[
            ScrollReveal(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: 'Diğer Oyunlar',
                  subtitle: 'Arşiv',
                  titleColor: Colors.white,
                  accentColor: WebColors.primaryGold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildGrid(otherGridShows),
            ),
          ],
          if (activeGridShows.isEmpty && otherGridShows.isEmpty)
            _buildEmptyCategoryNotice(showPast: false),
        ],
        // SAHNELER — GERÇEK `stagesProvider`'dan, her sahne için GERÇEK
        // "kaç oyun sahnelendi" sayısıyla (`Stage.showsId.length`) bir
        // vitrin şeridi. Gerçek sahne yoksa hiçbir şey render etmez.
        if (allStages.isNotEmpty) ...[
          const SizedBox(height: 64),
          ScrollReveal(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionHeader(
                title: 'Sahneler',
                subtitle: 'Mekanlar',
                titleColor: Colors.white,
                accentColor: WebColors.primaryGold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DiscoveryStageShowcase(
                stages: allStages,
                onStageTap: (final stage) => NavigationHandler.goToStage(
                    context, stage.id, stage.name),
              ),
            ),
          ),
        ],
        // TOPLULUKLAR — GERÇEK `teamsProvider`'dan, her topluluk için
        // GERÇEK gösteri sayısıyla (`Team.showsId.length`) bir vitrin
        // şeridi. Gerçek topluluk yoksa hiçbir şey render etmez.
        if (allTeams.isNotEmpty) ...[
          const SizedBox(height: 64),
          ScrollReveal(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionHeader(
                title: 'Topluluklar',
                subtitle: 'Kadro',
                titleColor: Colors.white,
                accentColor: WebColors.primaryGold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DiscoveryTeamShowcase(
                teams: allTeams,
                onTeamTap: (final team) =>
                    NavigationHandler.goToTeam(context, team.id, team.name),
              ),
            ),
          ),
        ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
        // Masaüstü deneyiminde sayfanın sonuna site geneli footer eklenir
        // (`home_page_web.dart`/`nearby_events_page.dart` desktop
        // sayfalarıyla AYNI yerleşik desen). `Footer` artık ÜSTTEKİ
        // ConstrainedBox'ın DIŞINDA — tam genişlikte, diğer web
        // sayfalarındaki gibi kenardan kenara yayılır; eskiden 1180-1360px
        // kutunun İÇİNE hapsolmuştu, bu da footer'ın (ve onunla birlikte
        // tüm sayfanın) ekranın ortasında küçük durduğu şikayetinin bir
        // parçasıydı.
        const Footer(),
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
      child: Stack(
        children: [
          // 🔥 Fare tekerleği (dikey delta) yatay kaydırmaya çevriliyor —
          // bkz. `_trendingScrollController` üzerindeki yorum.
          Listener(
            onPointerSignal: (final event) {
              if (event is! PointerScrollEvent ||
                  !_trendingScrollController.hasClients) return;
              final double target = (_trendingScrollController.offset +
                      event.scrollDelta.dy)
                  .clamp(
                _trendingScrollController.position.minScrollExtent,
                _trendingScrollController.position.maxScrollExtent,
              );
              _trendingScrollController.jumpTo(target);
            },
            child: ListView.builder(
              controller: _trendingScrollController,
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
          ),
          // Kaydırılabilir olduğunu (daha fazla kart olduğunu) ima eden
          // ince kenar solması — boş/durağan görünen kenarlar yerine
          // "burada daha fazlası var" hissi verir.
          IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        WebColors.darkBlueBackground,
                        WebColors.darkBlueBackground.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WebColors.darkBlueBackground.withOpacity(0),
                        WebColors.darkBlueBackground,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(final List<Show> shows) {
    if (shows.isEmpty) return const SizedBox.shrink();
    // Izgara `shrinkWrap: true` + `NeverScrollableScrollPhysics` olduğu için
    // tüm hücreler ebeveyn `ListView` tarafından anında (kaydırma beklemeden)
    // inşa ediliyor — `ScrollReveal` (aşağıda, dokunulmadı) her kartın
    // gerçekten ekrana girişini `visibility_detector` ile ayrı ayrı yönetmeye
    // devam ediyor. Burada eklenen `AnimationLimiter` +
    // `AnimationConfiguration.staggeredList` katmanı, o görünürlük tetiği
    // gerçekleştiğinde kartların hepsinin birden değil, kademeli bir
    // "cascade" ile belirmesini sağlıyor. Süre/eğri yine `reveal_on_scroll
    // .dart`'taki (`RevealOnScroll`) 650ms/easeOutCubic diliyle aynı;
    // `index % 6` sınırlaması da mevcut `ScrollReveal` gecikmesiyle
    // (`50 * (index % 6)`) aynı desen — büyük ızgaralarda gecikmenin sınırsız
    // birikmesini önlüyor.
    return AnimationLimiter(
      child: GridView.builder(
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
          return AnimationConfiguration.staggeredList(
            position: index % 6,
            duration: const Duration(milliseconds: 650),
            delay: const Duration(milliseconds: 70),
            child: SlideAnimation(
              verticalOffset: 28,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                curve: Curves.easeOutCubic,
                child: ScrollReveal(
                  delay: Duration(milliseconds: 50 * (index % 6)),
                  child: DiscoveryShowCard(
                    key: ValueKey('grid-${show.id}'),
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
            ),
          );
        },
      ),
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

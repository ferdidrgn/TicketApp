import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/nearby_events_provider.dart';
import '../widgets/nearby_event_map_card.dart';
import '../widgets/nearby_events_map.dart';
import '../widgets/nearby_location_permission_view.dart';

class NearbyEventsPage extends ConsumerWidget {
  const NearbyEventsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Masaüstünde (>=1024px) gerçek Firestore verisiyle çalışan, ayrı bir
    // "premium" web deneyimi kullanılır (bkz. _NearbyEventsDesktopPage).
    if (context.isDesktop) return const _NearbyEventsDesktopPage();
    return const _NearbyEventsMobileBody();
  }
}

// =============================================================================
// GERÇEK KONUM/MESAFE HAKKINDA
// =============================================================================
//
// Bu sayfa artık cihazın GERÇEK konumunu istiyor (`devicePositionProvider`,
// bkz. ../providers/location_provider.dart -> lib/core/services/
// location_service.dart) ve gösterilen her etkinliği İKİ GERÇEK filtreden
// geçiriyor (bkz. ../providers/nearby_events_provider.dart ->
// `nearbyEventsProvider`): sahnenin gerçek koordinatı kullanıcıya 50 km
// içinde OLMALI, VE etkinlik takvimde en fazla 30 gün içinde OLMALI. İzin
// reddedilirse/GPS kapalıysa sahte bir konum/mesafe ASLA üretilmiyor —
// bunun yerine `NearbyLocationPermissionView` gerçek bir izin isteme/
// ayarlara yönlendirme ekranı gösteriyor.

/// Sahnede sistemin çektiği yaklaşan etkinlik LİSTESİNİ, bir hızlı filtreye
/// ("Tümü" / "Bugün" / "Bu Hafta" / gerçek bir kategori adı) göre süzer.
/// Kategori listesi UYDURULMUYOR — `discovery_page.dart`'taki
/// `_buildBrowser` ile AYNI desen: gerçek `entries`'ten (`show.category`)
/// türetiliyor.
List<NearbyEventEntry> _applyQuickFilter(
    final List<NearbyEventEntry> entries, final String filter) {
  if (filter == 'Tümü') return entries;
  if (filter == 'Bugün') {
    final now = DateTime.now();
    return entries
        .where((final e) =>
            e.dateTime.year == now.year &&
            e.dateTime.month == now.month &&
            e.dateTime.day == now.day)
        .toList();
  }
  if (filter == 'Bu Hafta') {
    final cutoff = DateTime.now().add(const Duration(days: 7));
    return entries.where((final e) => e.dateTime.isBefore(cutoff)).toList();
  }
  return entries.where((final e) => e.show.category == filter).toList();
}

/// Gerçek `entries`'ten türetilen dinamik hızlı filtre listesi — sabit
/// `['Tiyatro','Komedi',...]` gibi UYDURMA bir dizi değil.
List<String> _quickFilterOptions(final List<NearbyEventEntry> entries) {
  final categories = <String>{
    for (final entry in entries)
      if (entry.show.category.trim().isNotEmpty) entry.show.category,
  }.toList()
    ..sort();
  return ['Tümü', 'Bugün', 'Bu Hafta', ...categories];
}

class _NearbyEventsMobileBody extends ConsumerStatefulWidget {
  const _NearbyEventsMobileBody();

  @override
  ConsumerState<_NearbyEventsMobileBody> createState() =>
      _NearbyEventsMobileBodyState();
}

class _NearbyEventsMobileBodyState
    extends ConsumerState<_NearbyEventsMobileBody> {
  String _activeFilter = 'Tümü';

  /// Kart listesinden seçilen, haritanın şu an odaklandığı GERÇEK sahne —
  /// bir karta dokunmak bunu günceller, `NearbyEventsMap` da kamerayı
  /// oraya kaydırır (bkz. `nearby_events_map.dart`'taki `focusedStage`).
  Stage? _focusedStage;

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final double cardWidth = isLargeScreen ? 400 : context.screenWidth - 48;

    final eventsState = ref.watch(nearbyEventsProvider);
    final stagesState =
        ref.watch(nearbyStageGroupsProvider).whenData((final groups) {
      return groups.map((final g) => g.stage).toList();
    });

    final List<NearbyEventEntry> entriesForFilters = eventsState.value ?? [];
    final List<String> filterOptions = _quickFilterOptions(entriesForFilters);
    final String activeFilter =
        filterOptions.contains(_activeFilter) ? _activeFilter : 'Tümü';

    return BasePageWrapper(
      title: 'YAKININIZDAKİ ETKİNLİKLER',
      subtitle: 'Size en yakın sahnelerde önümüzdeki 30 günde neler var?',
      showBackButton: false,
      rightIcon: Icons.tune_rounded,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface, safeAreaTop: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO BANNER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
              child: _buildDiscoveryBanner(context),
            ),
          ),

          // GERÇEK VERİ İSTATİSTİK ŞERİDİ — "X sahne, Y etkinlik" (uydurma
          // değil, `nearbyStageGroupsProvider`/`nearbyEventsProvider`'dan
          // gerçek `.length`).
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
              child: _NearbyStatStrip(
                stageCount: stagesState.value?.length,
                eventCount: eventsState.value?.length,
                foregroundColor: context.colors.onSurface,
                mutedColor: context.colors.onSurfaceVariant,
                accentColor: context.primaryColor,
                surfaceColor: context.colors.surfaceContainer,
                borderColor: context.colors.outlineVariant,
                scrollable: true,
              ),
            ),
          ),

          // GERÇEK HARİTA — kullanıcının konumu + yakındaki gerçek sahneler
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
              child: NearbyEventsMap(
                borderColor: context.colors.outlineVariant,
                surfaceColor: context.colors.surfaceContainer,
                foregroundColor: context.colors.onSurface,
                mutedColor: context.colors.onSurfaceVariant,
                accentColor: context.primaryColor,
                focusedStage: _focusedStage,
              ),
            ),
          ),

          // HIZLI FİLTRELER — gerçek verideki kategorilerden türetilir
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final option in filterOptions)
                    _buildFilterChip(
                      option,
                      option == activeFilter,
                      context,
                      () => setState(() => _activeFilter = option),
                    ),
                ],
              ),
            ),
          ),

          // BAŞLIK
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
              child: SectionHeader(
                title: 'Sizin İçin Önerilenler',
                subtitle: 'Konumunuza göre en uygun etkinlikler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ETKİNLİK LİSTESİ - YATAY KAYDIRMA
          SliverToBoxAdapter(
            child: _buildEventsSection(
                context, eventsState, cardWidth, activeFilter),
          ),

          // POPÜLER MEKANLAR BAŞLIĞI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
              child: SectionHeader(
                title: 'Yakınınızdaki Sahne ve Mekanlar',
                subtitle: 'Önümüzdeki 30 günde etkinliği olan gerçek sahneler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // MEKAN LİSTESİ
          _buildVenuesSliver(context, stagesState, isLargeScreen),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBanner(final BuildContext context) =>
      _NearbyHeroIntro(accentColor: context.primaryColor);

  Widget _buildFilterChip(final String text, final bool isActive,
      final BuildContext context, final VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$text filtresi',
        child: ChoiceChip(
          label: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive
                  ? context.colors.onPrimary
                  : context.colors.onSurfaceVariant,
            ),
          ),
          selected: isActive,
          onSelected: (final selected) {
            if (selected) onTap();
          },
          backgroundColor: context.colors.surfaceContainerHighest,
          selectedColor: context.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  /// "Sizin İçin Önerilenler" — GERÇEK konuma göre yakındaki etkinlikler.
  Widget _buildEventsSection(
      final BuildContext context,
      final AsyncValue<List<NearbyEventEntry>> state,
      final double cardWidth,
      final String activeFilter) {
    return state.when(
      loading: () => const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (final err, final stack) {
        if (err is LocationFailure) {
          return SizedBox(
            height: 320,
            child: Center(
              child: NearbyLocationPermissionView(
                error: err,
                foregroundColor: context.colors.onSurface,
                mutedColor: context.colors.onSurfaceVariant,
                accentColor: context.primaryColor,
              ),
            ),
          );
        }
        return const _MobileNearbyEmptyNotice(
          message: 'Etkinlikler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
        );
      },
      data: (final allEntries) {
        final entries = _applyQuickFilter(allEntries, activeFilter);
        if (entries.isEmpty)
          return _MobileNearbyEmptyNotice(
            message: allEntries.isEmpty
                ? 'Önümüzdeki 30 gün içinde, 50 km çevrenizde bir etkinlik bulunmuyor.'
                : 'Bu filtreye uyan bir etkinlik bulunmuyor.',
            // Filtreden değil, ham veriden kaynaklı gerçek boşluksa Keşfet
            // sayfasına yönlendiren CTA gösterilir.
            showDiscoverCta: allEntries.isEmpty,
          );

        return SizedBox(
          height: 320, // Sabit yükseklik - butonlar için yeterli alan
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            physics: const BouncingScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (final context, final index) {
              final entry = entries[index];
              return Container(
                width: cardWidth * 0.85, // Daha dar kartlar
                margin: EdgeInsets.only(
                  right: index < entries.length - 1 ? AppSpacing.lg : 0,
                ),
                child: NearbyEventMapCard(
                  key: ValueKey('nearby-mobile-event-${entry.event.id}'),
                  entry: entry,
                  width: cardWidth * 0.85,
                  isSelected: entry.stage.id == _focusedStage?.id,
                  surfaceColor: context.colors.surfaceContainer,
                  borderColor: context.colors.outlineVariant,
                  selectedColor: context.primaryColor,
                  foregroundColor: context.colors.onSurface,
                  mutedColor: context.colors.onSurfaceVariant,
                  accentColor: context.primaryColor,
                  onAccentColor: context.colors.onPrimary,
                  onSelect: () =>
                      setState(() => _focusedStage = entry.stage),
                  onOpenShow: () => NavigationHandler.goToShow(
                      context, entry.show.id, entry.show.name),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// "Yakınınızdaki Sahne ve Mekanlar" — GERÇEK konuma göre süzülmüş,
  /// önümüzdeki 30 günde etkinliği olan sahneler (bkz.
  /// `nearbyStageGroupsProvider`).
  Widget _buildVenuesSliver(final BuildContext context,
      final AsyncValue<List<Stage>> state, final bool isLargeScreen) {
    return state.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (final err, final stack) => SliverToBoxAdapter(
        child: _MobileNearbyEmptyNotice(
          message: err is LocationFailure
              ? 'Sahneleri gösterebilmemiz için yukarıdaki konum iznini vermeniz gerekiyor.'
              : 'Sahneler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
        ),
      ),
      data: (final stages) {
        if (stages.isEmpty)
          return const SliverToBoxAdapter(
            child: _MobileNearbyEmptyNotice(
              message:
                  'Önümüzdeki 30 gün içinde, 50 km çevrenizde etkinliği olan bir sahne bulunmuyor.',
              showDiscoverCta: true,
            ),
          );

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLargeScreen ? 3 : 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
              (final context, final index) =>
                  _buildVenueCard(context, stages[index]),
              childCount: stages.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVenueCard(final BuildContext context, final Stage stage) {
    return GestureDetector(
      onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
      child: Semantics(
        button: true,
        label: '${stage.name}, ${stage.address}',
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadow.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: OptimizedCachedImage(
                  imageUrl: stage.imageUrl,
                  width: 50,
                  height: 50,
                  isCircular: true,
                  errorBuilder: (final ctx, final url, final error) =>
                      Container(
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.theater_comedy_rounded,
                      color: context.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  stage.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  stage.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayfanın en üstündeki cinematik giriş bloğu — `home_page_web.dart`'taki
/// `_HeroBand` tekniğinden ilham alır (birebir kopyalanmadı: burada tek
/// seferlik `AnimationController` yerine hafif bir `TweenAnimationBuilder`
/// giriş animasyonu, tam ekran fotoğraf yerine gradyan + "sahne ışığı"
/// motifleri var). Kullanıcının GERÇEK konumundan güvenilir bir şehir adı
/// çıkarılamıyor (`Stage.locationLat/Lng` sayısal ama cihaz konumu için
/// bir reverse-geocoding paketi projede YOK — bkz.
/// `nearby_events_provider.dart`'taki "Mesafe mi, şehir metni mi" yorumu),
/// bu yüzden sahte bir şehir adı UYDURULMUYOR — jenerik ama gerçek bir
/// başlık ("Yakınındaki Sahneler") kullanılıyor.
class _NearbyHeroIntro extends StatelessWidget {
  final Color accentColor;

  const _NearbyHeroIntro({required this.accentColor});

  @override
  Widget build(final BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.slow,
        curve: AppMotion.dramatic,
        builder: (final context, final t, final child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppShadows.level4(accentColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // DEKORATİF ELEMENTLER — "sahne ışığı" motifi
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.star_rounded,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                bottom: -10,
                left: -10,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'YAKININIZDA',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Yakınındaki Sahneler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gerçek konumunuza göre 50 km içindeki, önümüzdeki 30 gündeki etkinlikler.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// GERÇEK veri istatistik şeridi — "X sahne, Y etkinlik" (uydurma değil,
/// `nearbyStageGroupsProvider`/`nearbyEventsProvider`'dan gerçek
/// `.length`). Kullanıcının "içerikleri doldur... geniş yelpazelerimiz
/// olsun" isteğine göre sayıların yanına gerçek filtre parametrelerini
/// (`kNearbyRadiusMeters`/`kNearbyWindowDays`) de bilgi kartı olarak
/// ekler — hem mobil (yatay kaydırılabilir) hem masaüstü (sabit satır)
/// yerleşimini destekler.
class _NearbyStatStrip extends StatelessWidget {
  final int? stageCount;
  final int? eventCount;
  final Color foregroundColor;
  final Color mutedColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;
  final bool scrollable;

  const _NearbyStatStrip({
    required this.stageCount,
    required this.eventCount,
    required this.foregroundColor,
    required this.mutedColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.borderColor,
    this.scrollable = false,
  });

  @override
  Widget build(final BuildContext context) {
    final List<_NearbyStatTile> tiles = [
      _NearbyStatTile(
        icon: Icons.theater_comedy_rounded,
        value: stageCount == null ? '—' : '$stageCount',
        label: 'Sahne',
        foreground: foregroundColor,
        muted: mutedColor,
        accent: accentColor,
        surface: surfaceColor,
        border: borderColor,
      ),
      _NearbyStatTile(
        icon: Icons.event_available_rounded,
        value: eventCount == null ? '—' : '$eventCount',
        label: 'Etkinlik',
        foreground: foregroundColor,
        muted: mutedColor,
        accent: accentColor,
        surface: surfaceColor,
        border: borderColor,
      ),
      _NearbyStatTile(
        icon: Icons.radar_rounded,
        value: '${(kNearbyRadiusMeters / 1000).round()}',
        label: 'km yarıçap',
        foreground: foregroundColor,
        muted: mutedColor,
        accent: accentColor,
        surface: surfaceColor,
        border: borderColor,
      ),
      _NearbyStatTile(
        icon: Icons.calendar_month_rounded,
        value: '$kNearbyWindowDays',
        label: 'gün pencere',
        foreground: foregroundColor,
        muted: mutedColor,
        accent: accentColor,
        surface: surfaceColor,
        border: borderColor,
      ),
    ];

    if (scrollable) {
      return SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: tiles.length,
          separatorBuilder: (final context, final index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (final context, final index) =>
              SizedBox(width: 150, child: tiles[index]),
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

/// `_NearbyStatStrip` içindeki tek bir gerçek istatistik/bilgi kartı.
class _NearbyStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color foreground;
  final Color muted;
  final Color accent;
  final Color surface;
  final Color border;

  const _NearbyStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
        label: '$value $label',
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: foreground,
                          fontSize: 17,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Mobil/tablet gövdesi için sade, temaya duyarlı "boş/hata" bildirimi.
/// Masaüstündeki `_NearbyEmptyNotice` ile aynı fikir, ama sabit
/// `WebColors` yerine mobil temanın `context.colors`'ını kullanır — o
/// sınıf yalnızca masaüstü lacivert/altın temasında doğru görünür.
/// `showDiscoverCta` — gerçekten hiçbir yakın etkinlik/sahne bulunamadığı
/// (filtreden değil, ham veriden kaynaklı) durumlarda kullanıcıyı Keşfet
/// sayfasına yönlendiren gerçek bir aksiyon ekler
/// (`NavigationHandler.goToDiscover`) — sahte/boş bir buton değil.
class _MobileNearbyEmptyNotice extends StatelessWidget {
  final String message;
  final bool showDiscoverCta;

  const _MobileNearbyEmptyNotice(
      {required this.message, this.showDiscoverCta = false});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style:
                  TextStyle(color: context.colors.onSurfaceVariant, fontSize: 15),
            ),
            if (showDiscoverCta) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: 'Keşfet sayfasına git',
                child: OutlinedButton.icon(
                  onPressed: () => NavigationHandler.goToDiscover(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    side: BorderSide(color: context.primaryColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: const Text("Keşfet'e Göz At"),
                ),
              ),
            ],
          ],
        ),
      );
}

// =============================================================================
// MASAÜSTÜ (WEB) YAKINDAKİLER SAYFASI — GERÇEK KONUM + GERÇEK VERİ
// =============================================================================
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — o mobil uygulama
// çatısıdır (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı, pull-to-
// refresh, `CustomAppBackground`'ın rastgele renkli parçacık noktaları).
// Bunlar `home_page_web.dart`'ta "Android uygulaması gibi görünüyor"
// şikayetinin asıl sebebiydi (bkz. o dosyadaki aynı gerekçe). Üst
// navigasyon zaten `WebTopNavigationBar`'dan geliyor; burada ikinci bir
// başlık çubuğuna gerek yok. Sade, düz zeminli bir kaydırma alanı.
class _NearbyEventsDesktopPage extends StatelessWidget {
  const _NearbyEventsDesktopPage();

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: `_NearbyEventsDesktopBody` kendi `ListView`'ı ile zaten
        // kaydırılabilir — burada ikinci bir SingleChildScrollView SARMAK
        // "unbounded height" hatasına yol açar, bilerek eklenmedi.
        //
        // KRİTİK: genişlik kısıtı (max-width) artık `ListView`'ın KENDİSİNİ
        // sarmıyor — `_NearbyEventsDesktopBody`'nin İÇİNDEKİ ListView'ın
        // TEK çocuğunu sarıyor (bkz. discovery_page.dart'taki AYNI
        // düzeltme). Eskiden Center+ConstrainedBox ListView'ı dıştan
        // sarıyordu, bu yüzden scrollbar 1180-1360px'lik kutunun kenarına
        // (ekranın ortasına yakın) düşüyordu — diğer web sayfalarından
        // farklı davranmasının sebebi buydu.
        color: WebColors.darkBlueBackground,
        child: const _NearbyEventsDesktopBody(),
      );
}

class _NearbyEventsDesktopBody extends ConsumerStatefulWidget {
  const _NearbyEventsDesktopBody();

  @override
  ConsumerState<_NearbyEventsDesktopBody> createState() =>
      _NearbyEventsDesktopBodyState();
}

class _NearbyEventsDesktopBodyState
    extends ConsumerState<_NearbyEventsDesktopBody> {
  /// Kart listesinden seçilen, haritanın şu an odaklandığı GERÇEK sahne —
  /// bkz. mobil taraftaki aynı isimli alanın yorumu.
  Stage? _focusedStage;

  @override
  Widget build(final BuildContext context) {
    final eventsState = ref.watch(nearbyEventsProvider);
    final stagesState = ref.watch(nearbyStageGroupsProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _NearbyDesktopBanner(eventCount: eventsState.value?.length),
        ),
        const SizedBox(height: AppSpacing.lg),
        // GERÇEK VERİ İSTATİSTİK ŞERİDİ — "X sahne, Y etkinlik" (uydurma
        // değil, `nearbyStageGroupsProvider`/`nearbyEventsProvider`'dan
        // gerçek `.length`).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _NearbyStatStrip(
            stageCount: stagesState.value?.length,
            eventCount: eventsState.value?.length,
            foregroundColor: Colors.white,
            mutedColor: WebColors.textSecondary,
            accentColor: WebColors.primaryGold,
            surfaceColor: WebColors.darkBlueSurface,
            borderColor: WebColors.primaryGold.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: AppSpacing.section - 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: SectionHeader(
            title: 'Haritada Yakınınızdakiler',
            subtitle: 'Konumunuz ve önümüzdeki 30 gündeki gerçek sahneler',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: NearbyEventsMap(
            height: 320,
            borderColor: WebColors.primaryGold.withOpacity(0.2),
            surfaceColor: WebColors.darkBlueSurface,
            foregroundColor: Colors.white,
            mutedColor: WebColors.textSecondary,
            accentColor: WebColors.primaryGold,
            focusedStage: _focusedStage,
          ),
        ),
        const SizedBox(height: AppSpacing.section - 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: SectionHeader(
            title: 'Yaklaşan Etkinlikler',
            subtitle: 'Konumunuza 50 km, takviminize 30 gün içinde',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildEventsSection(context, eventsState),
        const SizedBox(height: AppSpacing.section - 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: SectionHeader(
            title: 'Sahne ve Mekanlar',
            subtitle: 'Yakınınızdaki, yaklaşan etkinliği olan gerçek sahneler',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _buildStagesSection(context, stagesState),
        ),
        const SizedBox(height: 100),
        // Web masaüstü deneyiminde sayfanın sonuna site geneli footer eklenir.
        const Footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsSection(
      final BuildContext context, final AsyncValue<List<NearbyEventEntry>> state) {
    return state.when(
      loading: () => SizedBox(
        height: 320,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (final context, final index) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      error: (final err, final stack) {
        if (err is LocationFailure) {
          return Center(
            child: NearbyLocationPermissionView(
              error: err,
              foregroundColor: Colors.white,
              mutedColor: WebColors.textSecondary,
              accentColor: WebColors.primaryGold,
            ),
          );
        }
        return const _NearbyEmptyNotice(
          message: 'Etkinlikler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
        );
      },
      data: (final entries) {
        if (entries.isEmpty)
          return const _NearbyEmptyNotice(
            message:
                'Önümüzdeki 30 gün içinde, 50 km çevrenizde bir etkinlik bulunmuyor.',
            showDiscoverCta: true,
          );

        return SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            itemCount: entries.length,
            itemBuilder: (final context, final index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: NearbyEventMapCard(
                  key: ValueKey('nearby-event-${entry.event.id}'),
                  entry: entry,
                  width: 280,
                  isSelected: entry.stage.id == _focusedStage?.id,
                  surfaceColor: WebColors.darkBlueSurface,
                  borderColor: WebColors.primaryGold.withOpacity(0.2),
                  selectedColor: WebColors.primaryGold,
                  foregroundColor: Colors.white,
                  mutedColor: WebColors.textSecondary,
                  accentColor: WebColors.primaryGoldLight,
                  onSelect: () =>
                      setState(() => _focusedStage = entry.stage),
                  onOpenShow: () => NavigationHandler.goToShow(
                      context, entry.show.id, entry.show.name),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStagesSection(
      final BuildContext context, final AsyncValue<List<NearbyStageGroup>> state) {
    return state.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
          ),
        ),
      ),
      error: (final err, final stack) => _NearbyEmptyNotice(
        message: err is LocationFailure
            ? 'Sahneleri gösterebilmemiz için yukarıdaki konum iznini vermeniz gerekiyor.'
            : 'Sahneler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
      ),
      data: (final groups) {
        if (groups.isEmpty)
          return const _NearbyEmptyNotice(
            message:
                'Önümüzdeki 30 gün içinde, 50 km çevrenizde etkinliği olan bir sahne bulunmuyor.',
            showDiscoverCta: true,
          );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.35,
          ),
          itemCount: groups.length,
          itemBuilder: (final context, final index) =>
              _NearbyStageCard(group: groups[index]),
        );
      },
    );
  }
}

class _NearbyDesktopBanner extends StatelessWidget {
  final int? eventCount;

  const _NearbyDesktopBanner({required this.eventCount});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: WebColors.cardGradient,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
          boxShadow: AppShadows.level3(WebColors.primaryGold),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sahnede Şu An Neler Var?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.h3Size,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventCount == null
                        ? 'Gerçek konumunuz ve etkinlik takviminiz kontrol ediliyor…'
                        : eventCount == 0
                            ? 'Konumunuza 50 km, takvime 30 gün içinde yaklaşan bir etkinlik yok.'
                            : '$eventCount yaklaşan etkinlik, gerçek konumunuza ve sahne bilgilerinize göre listeleniyor.',
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.theater_comedy_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      );
}

class _NearbyStageCard extends StatelessWidget {
  final NearbyStageGroup group;

  const _NearbyStageCard({required this.group});

  @override
  Widget build(final BuildContext context) {
    final stage = group.stage;
    final nearest = group.entries.first;
    final formatted = DateFormatter.formatForEventCard(nearest.event.date);

    return GestureDetector(
      onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
      child: Semantics(
        button: true,
        label: '${stage.name}, ${stage.address}',
        child: Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          // Asimetrik köşeler — show_detail_page_web / discovery kartlarıyla
          // aynı "premium" imza.
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                        imageUrl: stage.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            WebColors.darkBlueSurface.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: WebColors.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          group.entries.length == 1
                              ? '1 ETKİNLİK'
                              : '${group.entries.length} ETKİNLİK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: WebColors.primaryGoldLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stage.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: WebColors.primaryGoldLight),
                        const SizedBox(width: 6),
                        Text(
                          'En yakın: ${formatted['day']} ${formatted['monthName']}, ${formatted['time']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

/// `showDiscoverCta` — gerçekten hiçbir yakın etkinlik/sahne bulunamadığı
/// durumlarda kullanıcıyı Keşfet sayfasına yönlendiren gerçek bir aksiyon
/// ekler (`NavigationHandler.goToDiscover`) — mobildeki
/// `_MobileNearbyEmptyNotice` ile aynı fikir, masaüstü lacivert/altın
/// temasıyla.
class _NearbyEmptyNotice extends StatelessWidget {
  final String message;
  final bool showDiscoverCta;

  const _NearbyEmptyNotice(
      {required this.message, this.showDiscoverCta = false});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
            ),
            if (showDiscoverCta) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: 'Keşfet sayfasına git',
                child: OutlinedButton.icon(
                  onPressed: () => NavigationHandler.goToDiscover(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WebColors.primaryGoldLight,
                    side: BorderSide(
                        color: WebColors.primaryGold.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: const Text("Keşfet'e Göz At"),
                ),
              ),
            ],
          ],
        ),
      );
}

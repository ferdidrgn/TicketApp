import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import '../widgets/browse_controls.dart';
import '../widgets/discovery_responsive.dart';
import '../widgets/nearby_events_map.dart';
import '../widgets/nearby_location_permission_view.dart';

/// YAKINIMDAKİLER — harita + mesafeye göre sahneler.
///
/// Veri: `nearbyOverviewProvider` — cihazın GERÇEK konumu, yaklaşan HER
/// seansın sahnesi ve sahnenin kullanıcıya GERÇEK uzaklığı (takvim
/// penceresi yok). Harita 50 km halkasını ve TÜM sahneleri gösterir
/// (içeride kırmızı, dışarıda mor); liste "Tümü / 50 km içinde / Daha
/// uzakta" seçicisiyle süzülür. Sahne kartına dokununca harita o sahneye
/// gider; seansa dokununca oyuna. "Yol tarifi" gerçek harita uygulamasını
/// açar.
///
/// - Mobil/tablet: başlık → harita → seçici → sahne kartları.
/// - Masaüstü: solda kayan liste, sağda sabit harita.
class NearbyEventsPage extends ConsumerStatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  ConsumerState<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

enum _Zone { all, inside, outside }

class _NearbyEventsPageState extends ConsumerState<NearbyEventsPage> {
  _Zone _zone = _Zone.all;
  Stage? _focused;
  final Set<String> _expanded = {};
  final ScrollController _scroll = ScrollController();

  static final int _radiusKm = (kNearbyRadiusMeters / 1000).round();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focus(final Stage stage) {
    HapticFeedback.selectionClick();
    setState(() => _focused = stage);
    if (_scroll.hasClients && _scroll.offset > 0 && !context.isDesktop) {
      final bool reduce = MediaQuery.of(context).disableAnimations;
      reduce
          ? _scroll.jumpTo(0)
          : _scroll.animateTo(0,
              duration: AppMotion.normal, curve: AppMotion.standard);
    }
  }

  void _retry() {
    ref.invalidate(devicePositionProvider);
    ref.invalidate(activeShowsProvider);
    ref.invalidate(upcomingNearbyEventsProvider);
  }

  String _lede(final AsyncValue<NearbyOverview> s) {
    if (s.isLoading && !s.hasValue) {
      return 'Konumun alınıyor, yakınındaki sahneler kontrol ediliyor.';
    }
    if (s.hasError && !s.hasValue) {
      return s.error is LocationFailure
          ? 'Yakınındaki seansları gösterebilmek için konumuna ihtiyacımız var.'
          : 'Seanslar şu an yüklenemedi.';
    }
    final o = s.value!;
    if (o.pins.isEmpty) return 'Yaklaşan bir seans bulunamadı.';
    final int inS = o.inside.length, outS = o.outside.length;
    final String first = inS == 0
        ? '$_radiusKm km içinde yaklaşan seans yok.'
        : '$_radiusKm km içinde $inS sahnede ${o.insideEventCount} seans var.';
    return outS == 0 ? first : '$first $outS sahne daha uzakta.';
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(nearbyOverviewProvider);
    if (DiscoveryResponsive.useSidebar(context)) {
      return _desktop(context, state);
    }
    return _compact(context, state, DiscoveryResponsive.layout(context));
  }

  // ─────────────────────────────────────────────────────────────────────
  // Ortak içerik (sliver'lar)
  // ─────────────────────────────────────────────────────────────────────

  List<Widget> _content(
      final AsyncValue<NearbyOverview> state, final double gutter) {
    final cs = Theme.of(context).colorScheme;
    if (state.isLoading && !state.hasValue) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (final _, final __) =>
                const BrowseVenueCardSkeleton(),
          ),
        ),
      ];
    }
    if (state.hasError && !state.hasValue) {
      final err = state.error!;
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: err is LocationFailure
                ? NearbyLocationPermissionView(
                    error: err,
                    foregroundColor: cs.onSurface,
                    mutedColor: cs.onSurfaceVariant,
                    accentColor: cs.primary,
                    onAccentColor: cs.onPrimary,
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: TicketNotice(
                      label: 'YAKINIMDAKİLER',
                      title: 'Seanslar yüklenemedi',
                      message: 'İnternet bağlantını kontrol edip tekrar dene.',
                      actionLabel: 'Tekrar dene',
                      actionIcon: Icons.refresh_rounded,
                      onAction: _retry,
                    ),
                  ),
          ),
        ),
      ];
    }

    final o = state.value!;
    if (o.pins.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TicketNotice(
                label: 'YAKINIMDAKİLER',
                title: 'Yaklaşan seans yok',
                message: o.unlocatedCount > 0
                    ? '${o.unlocatedCount} seansın sahne konumu girilmemiş; haritada gösterilemiyor.'
                    : 'Yeni seanslar eklendikçe burada görünecek.',
                actionLabel: 'Tüm oyunlara göz at',
                onAction: () => NavigationHandler.goToDiscover(context),
              ),
            ),
          ),
        ),
      ];
    }

    final List<NearbyPin> pins = switch (_zone) {
      _Zone.all => o.pins,
      _Zone.inside => o.inside,
      _Zone.outside => o.outside,
    };

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: BrowseChoiceChips(
            wrap: true,
            options: [
              BrowseOption('Tümü', count: o.pins.length),
              BrowseOption('$_radiusKm km içinde', count: o.inside.length),
              BrowseOption('Daha uzakta', count: o.outside.length),
            ],
            selectedIndex: _zone.index,
            onSelected: (final i) => setState(() => _zone = _Zone.values[i]),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            child: pins.isEmpty
                ? Padding(
                    key: ValueKey<String>('nearby-empty-${_zone.name}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(
                      _zone == _Zone.inside
                          ? '$_radiusKm km içinde yaklaşan seans yok.'
                          : '$_radiusKm km dışında sahne yok.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    key: ValueKey<String>(
                        'nearby-pins-${_zone.name}-${pins.length}'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pins.length,
                    separatorBuilder: (final _, final __) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (final context, final i) => _PinCard(
                      pin: pins[i],
                      focused: pins[i].stage.id == _focused?.id,
                      expanded: _expanded.contains(pins[i].stage.id),
                      onFocus: () => _focus(pins[i].stage),
                      onToggle: () => setState(() {
                        if (!_expanded.remove(pins[i].stage.id)) {
                          _expanded.add(pins[i].stage.id);
                        }
                      }),
                    ),
                  ),
          ),
        ),
      ),
      if (o.unlocatedCount > 0)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${o.unlocatedCount} seansın sahne konumu girilmemiş; haritada gösterilmiyor.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
          ),
        ),
    ];
  }

  void _onPinTap(final NearbyPin pin) {
    HapticFeedback.selectionClick();
    setState(() {
      _focused = pin.stage;
      _zone = pin.inside ? _Zone.inside : _Zone.outside;
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet
  // ─────────────────────────────────────────────────────────────────────

  Widget _compact(final BuildContext context,
      final AsyncValue<NearbyOverview> state,
      final DiscoveryBrowseLayout _) {
    final cs = Theme.of(context).colorScheme;
    final double gutter = DiscoveryResponsive.pageGutter(context);
    final double mapHeight = DiscoveryResponsive.nearbyMapHeight(context);
    final bool blocked = state.hasError && state.error is LocationFailure;

    return BasePageWrapper(
      showBackButton: false,
      customScrollController: _scroll,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: RefreshIndicator(
        onRefresh: () async => _retry(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  gutter, AppSpacing.xl, gutter, AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: BrowseHeading(
                    title: 'Yakınımdakiler', lede: _lede(state)),
              ),
            ),
            if (!blocked)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
                sliver: SliverToBoxAdapter(
                  child: NearbyEventsMap(
                    height: mapHeight,
                    focusedStage: _focused,
                    onPinTap: _onPinTap,
                  ),
                ),
              ),
            ..._content(state, gutter),
            if (kIsWeb) ...[
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section)),
              const SliverToBoxAdapter(child: Footer()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü: solda liste, sağda sabit harita
  // ─────────────────────────────────────────────────────────────────────

  Widget _desktop(
      final BuildContext context, final AsyncValue<NearbyOverview> state) {
    final cs = Theme.of(context).colorScheme;
    final bool blocked = state.hasError && state.error is LocationFailure;
    final double gutter = DiscoveryResponsive.pageGutter(context);
    final Widget list = RefreshIndicator(
      onRefresh: () async => _retry(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              gutter, AppSpacing.massive, gutter, AppSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: BrowseHeading(title: 'Yakınımdakiler', lede: _lede(state)),
          ),
        ),
        ..._content(state, gutter),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
        const SliverToBoxAdapter(child: Footer()),
      ],
      ),
    );
    return Scaffold(
      backgroundColor: cs.surface,
      body: blocked
          ? list
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: list),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        0, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
                    child: LayoutBuilder(
                      builder: (final context, final c) => NearbyEventsMap(
                        height: c.maxHeight,
                        focusedStage: _focused,
                        onPinTap: _onPinTap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Sahne kartı: görsel + ad + mesafe rozeti + seanslar
// ═════════════════════════════════════════════════════════════════════════

class _PinCard extends StatelessWidget {
  final NearbyPin pin;
  final bool focused;
  final bool expanded;
  final VoidCallback onFocus;
  final VoidCallback onToggle;

  const _PinCard({
    required this.pin,
    required this.focused,
    required this.expanded,
    required this.onFocus,
    required this.onToggle,
  });

  static const int _preview = 3;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = pin.stage;
    final double km = pin.distanceKm;
    final String distance =
        '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
    final visible = expanded ? pin.entries : pin.entries.take(_preview).toList();
    final int rest = pin.entries.length - visible.length;
    final timeFmt = DateFormat('HH:mm', 'tr');
    final dayFmt = DateFormat('d MMM EEE', 'tr');

    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: focused ? cs.primary : cs.outlineVariant,
          width: focused ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık: dokununca harita bu sahneye gider.
          Semantics(
            button: true,
            label: '${stage.name}, $distance, haritada göster',
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
              hoverColor: cs.primary.withValues(alpha: 0.06),
              onTap: onFocus,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: ColoredBox(
                          color: cs.surfaceContainerHighest,
                          child: stage.imageUrl.trim().isEmpty
                              ? Icon(Icons.location_city_rounded,
                                  color: cs.onSurfaceVariant)
                              : OptimizedCachedImage(
                                  imageUrl: stage.imageUrl,
                                  fit: BoxFit.cover,
                                  borderRadius: 0,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: cs.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (stage.address.trim().isNotEmpty)
                            Text(
                              stage.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12.5),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: pin.inside
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 13,
                              color: pin.inside
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            distance,
                            style: TextStyle(
                              color: pin.inside
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
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
          ),
          Divider(height: 1, color: cs.outlineVariant),
          for (final e in visible)
            Semantics(
              button: true,
              label: '${e.show.name}, ${dayFmt.format(e.dateTime)} ${timeFmt.format(e.dateTime)}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () =>
                    NavigationHandler.goToShow(context, e.show.id, e.show.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 86,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dayFmt.format(e.dateTime),
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text(timeFmt.format(e.dateTime),
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.xs),
            child: Row(
              children: [
                if (rest > 0 || expanded && pin.entries.length > _preview)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onToggle,
                    child: Text(expanded ? 'Daha az göster' : '+$rest seans daha'),
                  ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => TiyatrolCommunicationActions.openStageLocation(
                    lat: stage.locationLat,
                    lng: stage.locationLng,
                    stageName: stage.name,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Yol tarifi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

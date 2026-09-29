import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import '../widgets/browse_controls.dart';
import '../widgets/nearby_events_map.dart';
import '../widgets/nearby_location_permission_view.dart';

// =============================================================================
// YAKINIMDAKİLER — gerçek konum + gerçek veri
// =============================================================================
//
// Mantık değişmedi: cihazın GERÇEK konumu (`devicePositionProvider`) →
// `nearbyEventsProvider` (sahne 50 km içinde VE seans 30 gün içinde) →
// harita `nearbyStageGroupsProvider`. İzin reddedilirse/GPS kapalıysa/20 sn
// zaman aşımında sahte konum üretilmez; `NearbyLocationPermissionView`
// gerçek aksiyonu sunar.
//
// Tasarım: seanslar SAHNEYE göre gruplanır. Her sahne bir "yer" başlığıdır
// (ad, adres, GERÇEK uzaklık, yol tarifi); altındaki her seans bir bilet
// koçanıdır (TARİH koçanı + SAAT / FİYAT). Seansa dokunmak oyuna götürür,
// sahne başlığına dokunmak haritayı o sahneye kaydırır.
// - Masaüstü: solda kayan sonuç sütunu, sağda sabit (yapışkan) harita.
// - Tablet: üstte harita, altında sahneler; seanslar iki sütun.
// - Mobil: üstte kompakt harita, filtre çipleri, sahneler; seanslar liste.

/// Seans listesini hızlı filtreye ("Tümü" / "Bugün" / "Bu Hafta" / gerçek
/// bir kategori adı) göre süzer.
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

/// Gerçek `entries`'ten türetilen hızlı filtre listesi (uydurma kategori
/// dizisi değil).
List<String> _quickFilterOptions(final List<NearbyEventEntry> entries) {
  final categories = <String>{
    for (final entry in entries)
      if (entry.show.category.trim().isNotEmpty) entry.show.category,
  }.toList()
    ..sort();
  return ['Tümü', 'Bugün', 'Bu Hafta', ...categories];
}

/// Süzülmüş seansları sahneye göre gruplar — en yakın seansı olan sahne
/// önce (`nearbyStageGroupsProvider` ile aynı sıralama).
List<NearbyStageGroup> _groupByStage(final List<NearbyEventEntry> entries) {
  final Map<String, List<NearbyEventEntry>> grouped = {};
  for (final entry in entries) {
    grouped.putIfAbsent(entry.stage.id, () => []).add(entry);
  }
  final groups = grouped.values
      .map((final list) =>
          NearbyStageGroup(stage: list.first.stage, entries: list))
      .toList()
    ..sort((final a, final b) =>
        a.entries.first.dateTime.compareTo(b.entries.first.dateTime));
  return groups;
}

String _distanceLabel(final double meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

final int _kRadiusKm = (kNearbyRadiusMeters / 1000).round();

class NearbyEventsPage extends ConsumerStatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  ConsumerState<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends ConsumerState<NearbyEventsPage> {
  String _activeFilter = 'Tümü';

  /// Haritanın odaklandığı GERÇEK sahne — sahne başlığına dokunmak bunu
  /// günceller, `NearbyEventsMap` kamerayı oraya kaydırır.
  Stage? _focusedStage;

  /// "+N seans daha" ile açılmış sahneler.
  final Set<String> _expandedStages = {};

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focusStage(final Stage stage, {final bool scrollToMap = false}) {
    setState(() => _focusedStage = stage);
    if (scrollToMap && _scroll.hasClients && _scroll.offset > 0) {
      if (MediaQuery.of(context).disableAnimations) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(0,
            duration: AppMotion.normal, curve: AppMotion.standard);
      }
    }
  }

  void _toggleExpanded(final String stageId) => setState(() {
        if (!_expandedStages.remove(stageId)) _expandedStages.add(stageId);
      });

  void _retry() {
    ref.invalidate(activeShowsProvider);
    ref.invalidate(upcomingNearbyEventsProvider);
  }

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<List<NearbyEventEntry>> eventsState =
        ref.watch(nearbyEventsProvider);
    final Position? position = ref.watch(devicePositionProvider).value;

    final bool loading = eventsState.isLoading && !eventsState.hasValue;
    final Object? error =
        (!loading && eventsState.hasError && !eventsState.hasValue)
            ? eventsState.error
            : null;
    final bool locationBlocked = error is LocationFailure;

    final List<NearbyEventEntry> all =
        eventsState.value ?? const <NearbyEventEntry>[];
    final List<String> options = _quickFilterOptions(all);
    final String activeFilter =
        options.contains(_activeFilter) ? _activeFilter : 'Tümü';
    final List<NearbyStageGroup> groups =
        _groupByStage(_applyQuickFilter(all, activeFilter));

    final _NearbyView view = _NearbyView(
      loading: loading,
      error: error,
      all: all,
      groups: groups,
      options: options,
      activeFilter: activeFilter,
      position: position,
    );

    if (context.isDesktop) return _buildDesktop(context, view, locationBlocked);
    return _buildCompact(context, view, locationBlocked,
        tablet: context.isTablet);
  }

  String _lede(final _NearbyView v) {
    if (v.loading) {
      return 'Konumun alınıyor, yakınındaki sahneler kontrol ediliyor.';
    }
    if (v.error is LocationFailure) {
      return 'Yakınındaki seansları gösterebilmek için konumuna ihtiyacımız var.';
    }
    if (v.error != null) return 'Seanslar şu an yüklenemedi.';
    final int stageCount = _groupByStage(v.all).length;
    if (v.all.isEmpty) {
      return '$_kRadiusKm km içinde önümüzdeki $kNearbyWindowDays günde seans yok.';
    }
    return '$_kRadiusKm km içindeki $stageCount sahnede, önümüzdeki $kNearbyWindowDays günde ${v.all.length} seans var.';
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü: kayan sonuçlar + sabit harita
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDesktop(final BuildContext context, final _NearbyView view,
      final bool locationBlocked) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget results = LayoutBuilder(
      builder: (final context, final constraints) {
        final double gutter = locationBlocked
            ? math.max(AppSpacing.huge, (constraints.maxWidth - 1040) / 2)
            : AppSpacing.huge;
        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  gutter, AppSpacing.massive, gutter, AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: BrowseHeading(
                    title: 'Yakınımdakiler', lede: _lede(view)),
              ),
            ),
            if (view.showFilters)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    gutter, 0, gutter, AppSpacing.xxl),
                sliver: SliverToBoxAdapter(
                  child: BrowseChoiceChips(
                    wrap: true,
                    options: [for (final o in view.options) BrowseOption(o)],
                    selectedIndex: view.options.indexOf(view.activeFilter),
                    onSelected: (final i) =>
                        setState(() => _activeFilter = view.options[i]),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: _resultsSliver(view, sessionColumnsMinWidth: 10000),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
            const SliverToBoxAdapter(child: Footer()),
          ],
        );
      },
    );

    // BasePageWrapper kullanılmıyor → Material atası için kendi Scaffold'u.
    return Scaffold(
      backgroundColor: cs.surface,
      body: locationBlocked
          // Konum yoksa harita da yok: tek bir izin isteği gösterilir.
          ? results
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: results),
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        0, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
                    child: LayoutBuilder(
                      builder: (final context, final constraints) =>
                          NearbyEventsMap(
                        height: constraints.maxHeight,
                        borderColor: cs.outlineVariant,
                        surfaceColor: cs.surfaceContainer,
                        foregroundColor: cs.onSurface,
                        mutedColor: cs.onSurfaceVariant,
                        accentColor: cs.primary,
                        focusedStage: _focusedStage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCompact(final BuildContext context, final _NearbyView view,
      final bool locationBlocked,
      {required final bool tablet}) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double gutter = tablet ? AppSpacing.xxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scroll,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                gutter, AppSpacing.xl, gutter, AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child:
                  BrowseHeading(title: 'Yakınımdakiler', lede: _lede(view)),
            ),
          ),
          if (!locationBlocked)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: NearbyEventsMap(
                  height: tablet ? 320 : 220,
                  borderColor: cs.outlineVariant,
                  surfaceColor: cs.surfaceContainer,
                  foregroundColor: cs.onSurface,
                  mutedColor: cs.onSurfaceVariant,
                  accentColor: cs.primary,
                  focusedStage: _focusedStage,
                ),
              ),
            ),
          if (view.showFilters)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: BrowseChoiceChips(
                  options: [for (final o in view.options) BrowseOption(o)],
                  selectedIndex: view.options.indexOf(view.activeFilter),
                  onSelected: (final i) =>
                      setState(() => _activeFilter = view.options[i]),
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: _resultsSliver(
              view,
              sessionColumnsMinWidth: tablet ? 320 : 10000,
              scrollToMapOnFocus: true,
            ),
          ),
          if (kIsWeb) ...[
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
            const SliverToBoxAdapter(child: Footer()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Sonuçlar (ortak)
  // ─────────────────────────────────────────────────────────────────────

  Widget _resultsSliver(final _NearbyView v,
      {required final double sessionColumnsMinWidth,
      final bool scrollToMapOnFocus = false}) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (v.loading) {
      return SliverList.list(children: const [
        _VenueSkeleton(),
        SizedBox(height: AppSpacing.xxxl),
        _VenueSkeleton(),
      ]);
    }

    if (v.error != null) {
      final Object err = v.error!;
      if (err is LocationFailure) {
        return SliverToBoxAdapter(
          child: Center(
            child: NearbyLocationPermissionView(
              error: err,
              foregroundColor: cs.onSurface,
              mutedColor: cs.onSurfaceVariant,
              accentColor: cs.primary,
              onAccentColor: cs.onPrimary,
            ),
          ),
        );
      }
      return _noticeSliver(TicketNotice(
        label: 'BAĞLANTI',
        title: 'Seanslar yüklenemedi',
        message:
            'Etkinlik takvimine ulaşamadık. İnternet bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        actionIcon: Icons.refresh_rounded,
        onAction: _retry,
      ));
    }

    if (v.all.isEmpty) {
      return _noticeSliver(TicketNotice(
        label: 'YAKININDA',
        title: 'Yakınında seans yok',
        message:
            '$_kRadiusKm km içinde önümüzdeki $kNearbyWindowDays günde oynanan bir oyun bulamadık. Tüm oyunlara göz atabilirsin.',
        actionLabel: "Keşfet'e göz at",
        onAction: () => NavigationHandler.goToDiscover(context),
      ));
    }

    if (v.groups.isEmpty) {
      final String f = v.activeFilter;
      return _noticeSliver(TicketNotice(
        label: 'FİLTRE',
        title: f == 'Bugün'
            ? 'Bugün yakınında seans yok'
            : f == 'Bu Hafta'
                ? 'Bu hafta yakınında seans yok'
                : '“$f” için yakında seans yok',
        message:
            'Bu filtreye uyan seans bulunamadı. Yakınındaki tüm seanslara dönebilirsin.',
        actionLabel: 'Tüm seanslar',
        onAction: () => setState(() => _activeFilter = 'Tümü'),
      ));
    }

    return SliverList.separated(
      itemCount: v.groups.length,
      separatorBuilder: (final _, final __) =>
          const SizedBox(height: AppSpacing.xxxl),
      itemBuilder: (final context, final i) {
        final NearbyStageGroup group = v.groups[i];
        final Stage stage = group.stage;
        final Position? p = v.position;
        final double? meters = p == null
            ? null
            : LocationService.distanceInMeters(p.latitude, p.longitude,
                stage.locationLat, stage.locationLng);
        return _VenueGroup(
          key: ValueKey('nearby-venue-${stage.id}'),
          group: group,
          distance: meters == null ? null : _distanceLabel(meters),
          focused: stage.id == _focusedStage?.id,
          expanded: _expandedStages.contains(stage.id),
          sessionColumnsMinWidth: sessionColumnsMinWidth,
          onFocus: () =>
              _focusStage(stage, scrollToMap: scrollToMapOnFocus),
          onToggleExpanded: () => _toggleExpanded(stage.id),
          onOpenEntry: (final e) =>
              NavigationHandler.goToShow(context, e.show.id, e.show.name),
        );
      },
    );
  }

  Widget _noticeSliver(final TicketNotice notice) => SliverToBoxAdapter(
        child: Align(alignment: Alignment.centerLeft, child: notice),
      );
}

class _NearbyView {
  final bool loading;
  final Object? error;
  final List<NearbyEventEntry> all;
  final List<NearbyStageGroup> groups;
  final List<String> options;
  final String activeFilter;
  final Position? position;

  const _NearbyView({
    required this.loading,
    required this.error,
    required this.all,
    required this.groups,
    required this.options,
    required this.activeFilter,
    required this.position,
  });

  bool get showFilters => !loading && error == null && all.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────
// Sahne grubu: yer başlığı + seans koçanları
// ─────────────────────────────────────────────────────────────────────────

class _VenueGroup extends StatelessWidget {
  static const int _collapsedCount = 3;

  final NearbyStageGroup group;
  final String? distance;
  final bool focused;
  final bool expanded;
  final double sessionColumnsMinWidth;
  final VoidCallback onFocus;
  final VoidCallback onToggleExpanded;
  final ValueChanged<NearbyEventEntry> onOpenEntry;

  const _VenueGroup({
    super.key,
    required this.group,
    required this.distance,
    required this.focused,
    required this.expanded,
    required this.sessionColumnsMinWidth,
    required this.onFocus,
    required this.onToggleExpanded,
    required this.onOpenEntry,
  });

  String get _mapsQuery {
    final String name = group.stage.name.trim();
    final String address = group.stage.address.trim();
    if (name.isEmpty) return address;
    if (address.isEmpty) return name;
    return '$name, $address';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Stage stage = group.stage;
    final List<NearbyEventEntry> entries = group.entries;
    final int hidden = entries.length - _collapsedCount;
    final List<NearbyEventEntry> visible = (expanded || hidden <= 0)
        ? entries
        : entries.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Yer başlığı — ada dokununca harita bu sahneye kayar; sağda yol
        // tarifi ve Google Haritalar (gerçek aksiyonlar).
        Material(
          color: focused ? cs.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: focused ? cs.primary : cs.outlineVariant,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: focused,
                    label:
                        '${stage.name}${distance == null ? '' : ', $distance uzakta'}. Haritada göster.',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onFocus,
                      focusColor: cs.primary.withOpacity(0.16),
                      hoverColor: cs.onSurface.withOpacity(0.04),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: cs.onSurface,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (distance != null) distance!,
                              if (stage.address.trim().isNotEmpty)
                                stage.address.trim(),
                            ].join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),
                    IconButton(
                      tooltip: 'Yol tarifi al',
                      color: cs.primary,
                      icon: const Icon(Icons.directions_rounded),
                      onPressed: () =>
                          TiyatrolCommunicationActions.openStageLocation(
                        lat: stage.locationLat,
                        lng: stage.locationLng,
                        stageName: stage.name,
                      ),
                    ),
                    IconButton(
                      tooltip: "Google Haritalar'da gör",
                      color: cs.onSurfaceVariant,
                      icon: const Icon(Icons.travel_explore_rounded),
                      onPressed: () => TiyatrolCommunicationActions
                          .openAddressOnGoogleMaps(_mapsQuery),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BrowseColumns(
          minItemWidth: sessionColumnsMinWidth,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in visible)
              SessionTicketRow(
                key: ValueKey('nearby-session-${entry.event.id}'),
                title: entry.show.name,
                dateTime: entry.dateTime,
                price: ticketPrice(entry.event.price),
                onTap: () => onOpenEntry(entry),
              ),
          ],
        ),
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onToggleExpanded,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                minimumSize: const Size(48, 44),
              ),
              child: Text(
                expanded ? 'Daha az göster' : '$hidden seans daha',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _VenueSkeleton extends StatelessWidget {
  const _VenueSkeleton();

  @override
  Widget build(final BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 220, height: 22, borderRadius: 6),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoading(width: 160, height: 14, borderRadius: 6),
          SizedBox(height: AppSpacing.lg),
          TicketRowSkeleton(height: 88),
          SizedBox(height: AppSpacing.sm),
          TicketRowSkeleton(height: 88),
        ],
      );
}

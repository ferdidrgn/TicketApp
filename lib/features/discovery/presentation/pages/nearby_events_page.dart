import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/listing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/rive/tiyatrol_rive.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart'
    show PressScale, Reveal;
import '../../../../shared/widgets/ticket/stage_moments.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import '../widgets/browse_controls.dart';
import '../widgets/nearby_events_map.dart';
import '../widgets/nearby_location_permission_view.dart';

/// YAKINIMDAKİLER — harita + mesafeye göre sahneler.
///
/// Gerçek cihaz konumu; sahte GPS yok. Liste zone + "ne zaman" süzgeçleri
/// gerçek seanslara bağlı; hafta sonu yalnızca yaklaşan Cumartesi–Pazar.
class NearbyEventsPage extends ConsumerStatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  ConsumerState<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

enum _Zone { all, inside, outside }

class _NearbyEventsPageState extends ConsumerState<NearbyEventsPage> {
  _Zone _zone = _Zone.all;
  BrowseWhen _when = BrowseWhen.any;
  Stage? _focused;
  final Set<String> _expanded = {};
  final ScrollController _scroll = ScrollController();

  static const Map<BrowseWhen, String> _whenLabels = {
    BrowseWhen.any: 'Tüm tarihler',
    BrowseWhen.tonight: 'Bu akşam',
    BrowseWhen.tomorrow: 'Yarın',
    BrowseWhen.weekend: 'Hafta sonu',
    BrowseWhen.week: 'Bu hafta',
  };

  static const Map<BrowseWhen, IconData> _whenIcons = {
    BrowseWhen.any: Icons.calendar_month_outlined,
    BrowseWhen.tonight: Icons.nights_stay_outlined,
    BrowseWhen.tomorrow: Icons.wb_sunny_outlined,
    BrowseWhen.weekend: Icons.weekend_outlined,
    BrowseWhen.week: Icons.date_range_outlined,
  };

  List<NearbyPin> _filterWhen(final List<NearbyPin> pins) {
    if (_when == BrowseWhen.any) {
      return pins;
    }
    final out = <NearbyPin>[];
    for (final p in pins) {
      // Harici-only: bizde seans tarihi yok → tarih süzgecinde gösterme.
      if (p.isExternalOnly) {
        continue;
      }
      final entries = p.entries
          .where((final e) => browseMatchesWhen(e.dateTime, _when))
          .toList();
      if (entries.isEmpty) {
        continue;
      }
      out.add(NearbyPin(
        stage: p.stage,
        entries: entries,
        distanceMeters: p.distanceMeters,
        softRadiusMeters: p.softRadiusMeters,
        isApproximate: p.isApproximate,
        externalShow: p.externalShow,
        cityLabel: p.cityLabel,
      ));
    }
    return out;
  }

  Map<BrowseWhen, int> _whenCounts(final List<NearbyPin> zoned) {
    final Map<BrowseWhen, int> out = {};
    for (final BrowseWhen w in BrowseWhen.values) {
      if (w == BrowseWhen.any) {
        out[w] = zoned.length;
        continue;
      }
      int n = 0;
      for (final p in zoned) {
        if (p.entries.any((final e) => browseMatchesWhen(e.dateTime, w))) {
          n++;
        }
      }
      out[w] = n;
    }
    return out;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focus(final Stage stage) {
    sparkBurst(context);
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

  void _clearWhen() {
    HapticFeedback.selectionClick();
    setState(() => _when = BrowseWhen.any);
  }

  String _lede(final AsyncValue<NearbyOverview> s) {
    if (s.isLoading && !s.hasValue) {
      final pos = ref.watch(devicePositionProvider);
      if (pos.isLoading) {
        return 'Konumun alınıyor…';
      }
      if (pos.hasError) {
        return 'Konum alınamadı. İzni kontrol edip tekrar dene.';
      }
      return 'Konum hazır — yakınındaki sahneler yükleniyor.';
    }
    if (s.hasError && !s.hasValue) {
      return s.error is LocationFailure
          ? 'Yakınındaki seansları gösterebilmek için konumuna ihtiyacımız var.'
          : 'Seanslar şu an yüklenemedi.';
    }
    final o = s.value!;
    final int r = o.softRadiusKm;
    final String city =
        o.metro.name == 'Türkiye' ? 'bölgende' : o.metro.name;
    if (o.pins.isEmpty) {
      return 'Yaklaşan bir seans bulunamadı.';
    }
    final int inS = o.inside.length;
    final int outS = o.outside.length;
    final String first = inS == 0
        ? '$city · $r km içinde yaklaşan seans yok.'
        : '$city · $r km içinde $inS sahnede ${o.insideEventCount} seans.';
    final String zone =
        outS == 0 ? first : '$first $outS sahne daha uzakta.';
    if (_when == BrowseWhen.any) {
      return zone;
    }
    return '$zone · ${_whenLabels[_when]} süzgeci açık.';
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(nearbyOverviewProvider);
    return context.isDesktop
        ? _desktop(context, state)
        : _compact(context, state, tablet: context.isTablet);
  }

  List<Widget> _content(
      final AsyncValue<NearbyOverview> state, final double gutter) {
    final cs = Theme.of(context).colorScheme;
    if (state.isLoading && !state.hasValue) {
      final pos = ref.watch(devicePositionProvider);
      final String loadingLabel = pos.isLoading
          ? 'Konumun alınıyor…'
          : (pos.hasError
              ? 'Konum alınamadı'
              : 'Sahneler yükleniyor…');
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: TiyatrolRiveLoader(size: 56, caption: loadingLabel),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.lg),
            itemBuilder: (final _, final __) =>
                const TicketRowSkeleton(height: 160),
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
                    ? '${o.unlocatedCount} kayıt konumlandırılamadı. Harici bilette URL şehir slug’ı olmalı (ör. bubilet.com.tr/istanbul/etkinlik/...).'
                    : 'Yeni seanslar eklendikçe burada görünecek.',
                actionLabel: 'Tüm oyunlara göz at',
                onAction: () => NavigationHandler.goToDiscover(context),
              ),
            ),
          ),
        ),
      ];
    }

    final List<NearbyPin> zoned = switch (_zone) {
      _Zone.all => o.pins,
      _Zone.inside => o.inside,
      _Zone.outside => o.outside,
    };
    final Map<BrowseWhen, int> whenCounts = _whenCounts(zoned);
    final List<NearbyPin> pins = _filterWhen(zoned);

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
        sliver: SliverToBoxAdapter(
          child: BrowseChoiceChips(
            wrap: true,
            options: [
              BrowseOption('Tümü', count: o.pins.length),
              BrowseOption('${o.softRadiusKm} km içinde',
                  count: o.inside.length),
              BrowseOption('Daha uzakta', count: o.outside.length),
            ],
            selectedIndex: _zone.index,
            onSelected: (final i) => setState(() => _zone = _Zone.values[i]),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
        sliver: SliverToBoxAdapter(
          child: BrowseChoiceChips(
            options: [
              for (final w in BrowseWhen.values)
                BrowseOption(
                  _whenLabels[w]!,
                  count: whenCounts[w],
                  icon: _whenIcons[w],
                ),
            ],
            selectedIndex: _when.index,
            onSelected: (final i) =>
                setState(() => _when = BrowseWhen.values[i]),
          ),
        ),
      ),
      if (pins.isEmpty)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TicketNotice(
                label: 'YAKINIMDAKİLER',
                title: _when != BrowseWhen.any
                    ? 'Bu tarihte sahne yok'
                    : (_zone == _Zone.inside
                        ? '${o.softRadiusKm} km içinde yaklaşan seans yok'
                        : 'Bu bölgede sahne yok'),
                message: _when != BrowseWhen.any
                    ? '“${_whenLabels[_when]}” süzgecini temizleyip yeniden dene.'
                    : 'Başka bir mesafe dilimi seçebilirsin.',
                actionLabel: _when != BrowseWhen.any
                    ? 'Tarih süzgecini temizle'
                    : 'Tümünü göster',
                onAction: _when != BrowseWhen.any
                    ? _clearWhen
                    : () => setState(() => _zone = _Zone.all),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverList.separated(
            itemCount: pins.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.xl),
            itemBuilder: (final context, final i) => Reveal(
              index: i,
              child: _PinCard(
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
      if (o.unlocatedCount > 0)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${o.unlocatedCount} kayıt konumlandırılamadı. Turuncu pin = harici bilet URL şehri (ör. /istanbul/) veya yaklaşık adres; link Yozgat’a dönünce pin de kayar.',
              style: listingUi(
                color: cs.onSurfaceVariant,
                size: 12.5,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ),
    ];
  }

  void _onPinTap(final NearbyPin pin) {
    setState(() {
      _focused = pin.stage;
      _zone = pin.inside ? _Zone.inside : _Zone.outside;
    });
  }

  Widget _compact(final BuildContext context,
      final AsyncValue<NearbyOverview> state,
      {required final bool tablet}) {
    final cs = Theme.of(context).colorScheme;
    final double gutter = tablet ? AppSpacing.xxl : AppSpacing.lg;
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.7)),
                      boxShadow: AppShadows.level1(cs.shadow),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: NearbyEventsMap(
                        height: tablet ? 360 : 280,
                        focusedStage: _focused,
                        onPinTap: _onPinTap,
                      ),
                    ),
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

  Widget _desktop(
      final BuildContext context, final AsyncValue<NearbyOverview> state) {
    final cs = Theme.of(context).colorScheme;
    final bool blocked = state.hasError && state.error is LocationFailure;
    final Widget list = CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.huge, AppSpacing.massive,
              AppSpacing.huge, AppSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: BrowseHeading(title: 'Yakınımdakiler', lede: _lede(state)),
          ),
        ),
        ..._content(state, AppSpacing.huge),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
        const SliverToBoxAdapter(child: Footer()),
      ],
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
                      builder: (final context, final c) => DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.7)),
                          boxShadow: AppShadows.level1(cs.shadow),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: NearbyEventsMap(
                            height: c.maxHeight,
                            focusedStage: _focused,
                            onPinTap: _onPinTap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Sahne kartı: fotoğraf çerçevesi + mesafe orb + seans satırları.
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
    final String distanceValue =
        km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0);
    final visible = expanded ? pin.entries : pin.entries.take(_preview).toList();
    final int rest = pin.entries.length - visible.length;
    final timeFmt = DateFormat('HH:mm', 'tr');
    final dayFmt = DateFormat('d MMM EEE', 'tr');

    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: focused ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
          width: focused ? 1.8 : 1,
        ),
        boxShadow: focused
            ? AppShadows.level2(cs.shadow)
            : AppShadows.level1(cs.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: '${stage.name}, $distanceValue km, haritada göster',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
              onTap: onFocus,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    PressScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final ext = pin.externalShow;
                        if (ext != null) {
                          final String tag =
                              TiyatrolHeroTags.show(ext.id, 'nearby');
                          TiyatrolHeroFlight.prepare(tag,
                              imageUrl: ext.imageUrl, title: ext.name);
                          NavigationHandler.goToShow(
                            context,
                            ext.id,
                            ext.name,
                            heroTag: tag,
                            imageUrl: ext.imageUrl,
                            title: ext.name,
                          );
                          return;
                        }
                        final String tag =
                            TiyatrolHeroTags.stage(stage.id, 'nearby');
                        TiyatrolHeroFlight.prepare(tag,
                            imageUrl: stage.imageUrl, title: stage.name);
                        NavigationHandler.goToStage(
                          context,
                          stage.id,
                          stage.name,
                          heroTag: tag,
                          imageUrl: stage.imageUrl,
                          title: stage.name,
                        );
                      },
                      semanticLabel: pin.isExternalOnly
                          ? '${stage.name}, oyun detayı'
                          : '${stage.name}, sahne detayı',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: ColoredBox(
                            color: cs.surfaceContainerHighest,
                            child: stage.imageUrl.trim().isEmpty
                                ? Icon(Icons.location_city_rounded,
                                    color: cs.onSurfaceVariant, size: 28)
                                : TiyatrolHero(
                                    tag: pin.isExternalOnly
                                        ? TiyatrolHeroTags.show(
                                            pin.externalShow!.id, 'nearby')
                                        : TiyatrolHeroTags.stage(
                                            stage.id, 'nearby'),
                                    flightRadius: AppRadius.lg,
                                    child: OptimizedCachedImage(
                                      imageUrl: stage.imageUrl,
                                      fit: BoxFit.cover,
                                      borderRadius: 0,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: listingUi(
                              color: cs.onSurface,
                              size: 17,
                              weight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          if (stage.address.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              stage.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: listingUi(
                                color: cs.onSurfaceVariant,
                                size: 12.5,
                                weight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            pin.isExternalOnly
                                ? 'Harici bilet · ${pin.cityLabel ?? 'şehir'} (yaklaşık)'
                                : (pin.isApproximate
                                    ? '${pin.entries.length} seans · yaklaşık konum'
                                    : '${pin.entries.length} seans'),
                            style: listingUi(
                              color: cs.primary,
                              size: 12.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ListingMetricOrb(
                      value: distanceValue,
                      unit: 'km',
                      emphasized: pin.inside,
                      size: 72,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (pin.isExternalOnly) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
            Semantics(
              button: true,
              label: '${pin.externalShow!.name}, harici bilet, oyun detayı',
              excludeSemantics: true,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final ext = pin.externalShow!;
                  final String tag =
                      TiyatrolHeroTags.show(ext.id, 'nearby');
                  TiyatrolHeroFlight.prepare(tag,
                      imageUrl: ext.imageUrl, title: ext.name);
                  NavigationHandler.goToShow(
                    context,
                    ext.id,
                    ext.name,
                    heroTag: tag,
                    imageUrl: ext.imageUrl,
                    title: ext.name,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 18, color: cs.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Bilet başka platformda · detaya git',
                          style: listingUi(
                            color: cs.onSurface,
                            size: 14,
                            weight: FontWeight.w700,
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
          ] else ...[
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
          for (final e in visible)
            Semantics(
              button: true,
              label:
                  '${e.show.name}, ${dayFmt.format(e.dateTime)} ${timeFmt.format(e.dateTime)}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final String tag =
                      TiyatrolHeroTags.show(e.show.id, 'nearby');
                  TiyatrolHeroFlight.prepare(tag,
                      imageUrl: e.show.imageUrl, title: e.show.name);
                  NavigationHandler.goToShow(
                    context,
                    e.show.id,
                    e.show.name,
                    heroTag: tag,
                    imageUrl: e.show.imageUrl,
                    title: e.show.name,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          width: 44,
                          height: 64,
                          child: TiyatrolHero(
                            tag: TiyatrolHeroTags.show(e.show.id, 'nearby'),
                            flightRadius: AppRadius.sm,
                            child: OptimizedCachedImage(
                              imageUrl: e.show.imageUrl,
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 72,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayFmt.format(e.dateTime),
                              style: listingUi(
                                color: cs.onSurfaceVariant,
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              timeFmt.format(e.dateTime),
                              style: listingUi(
                                color: cs.onSurface,
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: listingUi(
                            color: cs.onSurface,
                            size: 14.5,
                            weight: FontWeight.w700,
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
                AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                if (rest > 0 || (expanded && pin.entries.length > _preview))
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onToggle();
                    },
                    child:
                        Text(expanded ? 'Daha az göster' : '+$rest seans daha'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    TiyatrolCommunicationActions.openStageLocation(
                      lat: stage.locationLat,
                      lng: stage.locationLng,
                      stageName: stage.name,
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Yol tarifi'),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

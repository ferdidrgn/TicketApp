import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart' show SkPencilLine;
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import '../widgets/browse_controls.dart';
import '../widgets/nearby_events_map.dart';
import '../widgets/nearby_location_permission_view.dart';

/// YAKINDAKİLER — WEB. Mağaza listeleme düzeni: solda süzgeç paneli
/// (mesafe, ne zaman, sıralama), ortada sahne kartları ızgarası, sağda
/// kaydırırken yapışkan kalan harita + özet paneli. Mobil "Yakınımdakiler"
/// sayfasından AYRIDIR. Başlık kabuktaki site başlığından gelir.
class NearbyEventsPageWeb extends ConsumerStatefulWidget {
  const NearbyEventsPageWeb({super.key});

  @override
  ConsumerState<NearbyEventsPageWeb> createState() =>
      _NearbyEventsPageWebState();
}

enum _Zone { all, inside, outside }

enum _Order { distance, date }

const Map<BrowseWhen, String> _whenLabels = {
  BrowseWhen.any: 'Tüm tarihler',
  BrowseWhen.tonight: 'Bu akşam',
  BrowseWhen.tomorrow: 'Yarın',
  BrowseWhen.weekend: 'Hafta sonu',
  BrowseWhen.week: 'Bu hafta',
};

class _NearbyEventsPageWebState extends ConsumerState<NearbyEventsPageWeb> {
  _Zone _zone = _Zone.all;
  BrowseWhen _when = BrowseWhen.any;
  _Order _order = _Order.distance;
  Stage? _focused;
  final Set<String> _expanded = {};

  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  final ValueNotifier<double> _stick = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateSticky);
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateSticky);
    _scroll.dispose();
    _stick.dispose();
    super.dispose();
  }

  /// Sağ paneli satırın içinde, kaydırmayı izleyerek aşağı kaydırır.
  void _updateSticky() {
    final RenderObject? row = _rowKey.currentContext?.findRenderObject();
    final RenderObject? panel = _panelKey.currentContext?.findRenderObject();
    if (row is! RenderBox ||
        panel is! RenderBox ||
        !row.attached ||
        !panel.attached) {
      return;
    }
    final double rowTop = row.localToGlobal(Offset.zero).dy;
    const double stickAt = 24;
    final double travel = row.size.height - panel.size.height;
    final double v = (stickAt - rowTop).clamp(0.0, travel < 0 ? 0.0 : travel);
    if ((v - _stick.value).abs() > 0.5) _stick.value = v;
  }

  void _retry() {
    ref.invalidate(devicePositionProvider);
    ref.invalidate(activeShowsProvider);
    ref.invalidate(upcomingNearbyEventsProvider);
  }

  List<NearbyPin> _applyWhen(final List<NearbyPin> pins) {
    if (_when == BrowseWhen.any) return pins;
    final List<NearbyPin> out = [];
    for (final NearbyPin p in pins) {
      if (p.isExternalOnly) continue;
      final entries = p.entries
          .where((final e) => browseMatchesWhen(e.dateTime, _when))
          .toList();
      if (entries.isEmpty) continue;
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

  int _whenCount(final List<NearbyPin> zoned, final BrowseWhen w) {
    if (w == BrowseWhen.any) return zoned.length;
    int n = 0;
    for (final NearbyPin p in zoned) {
      if (p.entries.any((final e) => browseMatchesWhen(e.dateTime, w))) n++;
    }
    return n;
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _zone = _Zone.all;
      _when = BrowseWhen.any;
      _order = _Order.distance;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<NearbyOverview> state = ref.watch(nearbyOverviewProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (final context, final box) {
              final double w = box.maxWidth;
              final double gutter = Sk.gutter(w);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
                    child: _body(context, state, w - 2 * gutter),
                  ),
                ),
              );
            }),
            const SizedBox(height: 72),
            const WebMegaFooter(),
          ],
        ),
      ),
    );
  }

  Widget _body(final BuildContext context, final AsyncValue<NearbyOverview> s,
      final double w) {
    if (s.isLoading && !s.hasValue) return _loading(context, w);
    if (s.hasError && !s.hasValue) return _error(context, s.error!);
    final NearbyOverview o = s.value!;
    if (o.pins.isEmpty) {
      return _Hero(
        headline: 'Yakınında yaklaşan seans yok',
        sub: o.unlocatedCount > 0
            ? '${o.unlocatedCount} kayıt konumlandırılamadı.'
            : 'Yeni seanslar eklendikçe burada görünecek.',
        trailing: SkEmpty(
          icon: Icons.near_me_disabled_outlined,
          title: 'Şimdilik sessiz',
          message: 'Tüm oyunlara göz atıp başka şehirlerdeki seanslara bakabilirsin.',
          actionLabel: 'Oyunlara göz at',
          onAction: () => NavigationHandler.goToDiscover(context),
        ),
      );
    }

    final List<NearbyPin> zoned = switch (_zone) {
      _Zone.all => o.pins,
      _Zone.inside => o.inside,
      _Zone.outside => o.outside,
    };
    final List<NearbyPin> pins = _applyWhen(zoned);
    if (_order == _Order.date) {
      pins.sort((final a, final b) => a.nextDate.compareTo(b.nextDate));
    } else {
      pins.sort((final a, final b) =>
          a.distanceMeters.compareTo(b.distanceMeters));
    }

    final bool desktop = w >= 1100;
    final bool tablet = w >= 720;
    final String city = o.metro.name == 'Türkiye' ? 'Bölgen' : o.metro.name;
    final int sessions = pins.fold(
        0, (final n, final p) => n + (p.isExternalOnly ? 1 : p.entries.length));

    final Widget filters = _Filters(
      overview: o,
      zone: _zone,
      when: _when,
      order: _order,
      whenCount: (final z, final wh) => _whenCount(
          switch (z) {
            _Zone.all => o.pins,
            _Zone.inside => o.inside,
            _Zone.outside => o.outside,
          },
          wh),
      onZone: (final z) => setState(() => _zone = z),
      onWhen: (final v) => setState(() => _when = v),
      onOrder: (final v) => setState(() => _order = v),
      onClear: _clear,
      horizontal: !desktop,
    );

    final double mainW = desktop ? w - 280 - 360 - 64 : w;
    final Widget results = _Results(
      pins: pins,
      width: mainW,
      focused: _focused,
      expanded: _expanded,
      sessions: sessions,
      onFocus: (final st) {
        HapticFeedback.selectionClick();
        setState(() => _focused = st);
        if (!desktop && _scroll.hasClients) {
          _scroll.animateTo(0,
              duration: AppMotion.normal, curve: Curves.easeOut);
        }
      },
      onToggle: (final id) => setState(() {
        _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
      }),
      onClear: _clear,
    );

    final Widget panel = _MapPanel(
      key: _panelKey,
      overview: o,
      focused: _focused,
      onPinTap: (final p) => setState(() => _focused = p.stage),
      height: desktop ? 360 : (tablet ? 380 : 280),
    );

    final Widget head = _Hero(
      headline: o.insideEventCount == 0
          ? '$city çevresinde yaklaşan seans yok'
          : '$city çevresinde ${o.insideEventCount} seans var',
      sub: o.inside.isEmpty
          ? 'Daha uzaktaki ${o.outside.length} sahneye aşağıdan bakabilirsin.'
          : '${o.softRadiusKm} km içinde ${o.inside.length} sahne · '
              'önümüzdeki $kNearbyHorizonDays gün',
    );

    if (desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          const SizedBox(height: 28),
          Row(
            key: _rowKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: filters),
              const SizedBox(width: 32),
              Expanded(child: results),
              const SizedBox(width: 32),
              SizedBox(
                width: 360,
                child: ValueListenableBuilder<double>(
                  valueListenable: _stick,
                  builder: (final _, final dy, final child) =>
                      Transform.translate(offset: Offset(0, dy), child: child),
                  child: panel,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        const SizedBox(height: 20),
        panel,
        const SizedBox(height: 20),
        filters,
        const SizedBox(height: 24),
        results,
      ],
    );
  }

  Widget _loading(final BuildContext context, final double w) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue pos = ref.watch(devicePositionProvider);
    final String label = pos.isLoading
        ? 'Konumun alınıyor…'
        : (pos.hasError ? 'Konum alınamadı' : 'Sahneler yükleniyor…');
    final int cols = w >= 1100 ? 3 : (w >= 720 ? 2 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(headline: 'Yakınındaki sahneler', sub: label),
        const SizedBox(height: 28),
        Wrap(spacing: 24, runSpacing: 24, children: [
          for (int i = 0; i < cols * 2; i++)
            SkBone(
                width: (w - 24 * (cols - 1)) / cols - 0.5,
                height: 280,
                radius: 20),
        ]),
        Semantics(
          liveRegion: true,
          label: label,
          child: SizedBox(height: 1, child: ColoredBox(color: cs.surface)),
        ),
      ],
    );
  }

  Widget _error(final BuildContext context, final Object err) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Hero(
            headline: 'Yakınındaki sahneler',
            sub: 'Seansları konumuna göre sıralıyoruz.'),
        const SizedBox(height: 28),
        if (err is LocationFailure)
          NearbyLocationPermissionView(
            error: err,
            foregroundColor: cs.onSurface,
            mutedColor: cs.onSurfaceVariant,
            accentColor: cs.primary,
            onAccentColor: cs.onPrimary,
          )
        else
          SkEmpty(
            icon: Icons.cloud_off_rounded,
            title: 'Seanslar yüklenemedi',
            message: 'İnternet bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: _retry,
          ),
      ],
    );
  }
}

// ─── Üst başlık ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final String headline;
  final String sub;
  final Widget? trailing;
  const _Hero({required this.headline, required this.sub, this.trailing});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(headline,
              style: Sk.display(context, size: 38, height: 1.1)),
        ),
        const SizedBox(height: 6),
        const SkPencilLine(width: 120),
        const SizedBox(height: 8),
        Text(sub,
            style: Sk.ui(context,
                size: 15.5,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w500,
                height: 1.45)),
        if (trailing != null) ...[
          const SizedBox(height: 24),
          Center(child: trailing),
        ],
      ],
    );
  }
}

// ─── Süzgeçler ───────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  final NearbyOverview overview;
  final _Zone zone;
  final BrowseWhen when;
  final _Order order;
  final int Function(_Zone, BrowseWhen) whenCount;
  final ValueChanged<_Zone> onZone;
  final ValueChanged<BrowseWhen> onWhen;
  final ValueChanged<_Order> onOrder;
  final VoidCallback onClear;
  final bool horizontal;

  const _Filters({
    required this.overview,
    required this.zone,
    required this.when,
    required this.order,
    required this.whenCount,
    required this.onZone,
    required this.onWhen,
    required this.onOrder,
    required this.onClear,
    required this.horizontal,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final NearbyOverview o = overview;

    if (horizontal) {
      Widget row(final List<Widget> chips) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final Widget c in chips)
                Padding(padding: const EdgeInsets.only(right: 8), child: c),
            ]),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row([
            SkChip(
                label: 'Tümü',
                count: o.pins.length,
                selected: zone == _Zone.all,
                onTap: () => onZone(_Zone.all)),
            SkChip(
                label: '${o.softRadiusKm} km içinde',
                count: o.inside.length,
                selected: zone == _Zone.inside,
                onTap: () => onZone(_Zone.inside)),
            SkChip(
                label: 'Daha uzakta',
                count: o.outside.length,
                selected: zone == _Zone.outside,
                onTap: () => onZone(_Zone.outside)),
          ]),
          const SizedBox(height: 10),
          row([
            for (final BrowseWhen wh in BrowseWhen.values)
              SkChip(
                  label: _whenLabels[wh]!,
                  count: whenCount(zone, wh),
                  selected: when == wh,
                  onTap: () => onWhen(wh)),
          ]),
        ],
      );
    }

    Widget head(final String t) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(t, style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
        );

    Widget option(final String label, final bool sel, final VoidCallback tap,
            {final int? count}) =>
        Semantics(
          button: true,
          selected: sel,
          label: label,
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                tap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Icon(
                      sel
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: sel ? cs.primary : cs.outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: Sk.ui(context,
                            size: 14.5,
                            weight: sel ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  if (count != null)
                    Text('$count',
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Süzgeçler', style: Sk.display(context, size: 24, height: 1.1)),
          head('Mesafe'),
          option('Tümü', zone == _Zone.all, () => onZone(_Zone.all),
              count: o.pins.length),
          option('${o.softRadiusKm} km içinde', zone == _Zone.inside,
              () => onZone(_Zone.inside),
              count: o.inside.length),
          option('Daha uzakta', zone == _Zone.outside,
              () => onZone(_Zone.outside),
              count: o.outside.length),
          head('Ne zaman'),
          for (final BrowseWhen wh in BrowseWhen.values)
            option(_whenLabels[wh]!, when == wh, () => onWhen(wh),
                count: whenCount(zone, wh)),
          head('Sıralama'),
          option('En yakın sahne', order == _Order.distance,
              () => onOrder(_Order.distance)),
          option('En yakın tarih', order == _Order.date,
              () => onOrder(_Order.date)),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: const StadiumBorder()),
            child: const Text('Süzgeçleri temizle'),
          ),
        ],
      ),
    );
  }
}

// ─── Sonuçlar ────────────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
  final List<NearbyPin> pins;
  final double width;
  final Stage? focused;
  final Set<String> expanded;
  final int sessions;
  final ValueChanged<Stage> onFocus;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  const _Results({
    required this.pins,
    required this.width,
    required this.focused,
    required this.expanded,
    required this.sessions,
    required this.onFocus,
    required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (pins.isEmpty) {
      return SkSoftCard(
        padding: const EdgeInsets.all(24),
        child: SkEmpty(
          icon: Icons.filter_alt_off_rounded,
          title: 'Bu süzgeçlerle sahne yok',
          message: 'Mesafeyi ya da tarihi genişletip yeniden dene.',
          actionLabel: 'Süzgeçleri temizle',
          onAction: onClear,
        ),
      );
    }
    const double gap = 22;
    final int cols = width >= 760 ? 2 : 1;
    final double cw = (width - gap * (cols - 1)) / cols;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text('Sahneler',
                style: Sk.display(context, size: 28, height: 1.1)),
          ),
          Text('${pins.length} sahne · $sessions seans',
              style: Sk.ui(context,
                  size: 14,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w600)),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: gap, runSpacing: gap, children: [
          for (int i = 0; i < pins.length; i++)
            SizedBox(
              width: cw,
              child: Reveal(
                index: i.clamp(0, 6),
                child: _StageCard(
                  pin: pins[i],
                  focused: focused?.id == pins[i].stage.id,
                  expanded: expanded.contains(pins[i].stage.id),
                  onFocus: () => onFocus(pins[i].stage),
                  onToggle: () => onToggle(pins[i].stage.id),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

class _StageCard extends StatefulWidget {
  final NearbyPin pin;
  final bool focused;
  final bool expanded;
  final VoidCallback onFocus;
  final VoidCallback onToggle;

  const _StageCard({
    required this.pin,
    required this.focused,
    required this.expanded,
    required this.onFocus,
    required this.onToggle,
  });

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _hover = false;

  static const int _preview = 3;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final NearbyPin pin = widget.pin;
    final Stage stage = pin.stage;
    final double km = pin.distanceKm;
    final String distance =
        km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0);
    final List<NearbyEventEntry> shown = widget.expanded
        ? pin.entries
        : pin.entries.take(_preview).toList();
    final int rest = pin.entries.length - shown.length;
    final String imageUrl = pin.isExternalOnly
        ? pin.externalShow!.imageUrl
        : stage.imageUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.focused
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: _hover ? 0.9 : 0.5),
            width: widget.focused ? 1.8 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PressScale(
              semanticLabel: '${stage.name}, $distance km, haritada göster',
              onTap: widget.onFocus,
              child: AspectRatio(
                aspectRatio: 16 / 8.5,
                child: Stack(fit: StackFit.expand, children: [
                  SkImage(
                      url: imageUrl,
                      fallbackIcon: Icons.location_city_rounded),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: SkBadge(
                        label: '$distance km',
                        icon: Icons.near_me_rounded,
                        accent: pin.inside,
                        onImage: !pin.inside),
                  ),
                  if (pin.isApproximate || pin.isExternalOnly)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: SkBadge(
                          label: pin.isExternalOnly
                              ? 'Başka platform'
                              : 'Yaklaşık konum',
                          icon: pin.isExternalOnly
                              ? Icons.open_in_new_rounded
                              : Icons.place_outlined,
                          onImage: true),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 17, weight: FontWeight.w800, height: 1.25)),
                  if (stage.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(stage.address.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            if (pin.isExternalOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _SessionRow(
                  title: pin.externalShow!.name,
                  when: 'Biletler başka platformda',
                  price: null,
                  onTap: () => NavigationHandler.goToShow(
                      context, pin.externalShow!.id, pin.externalShow!.name,
                      imageUrl: pin.externalShow!.imageUrl,
                      title: pin.externalShow!.name),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                child: AnimatedSize(
                  duration: AppMotion.fast,
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: Column(children: [
                    for (final NearbyEventEntry e in shown)
                      _SessionRow(
                        title: e.show.name,
                        when:
                            '${skDayPhrase(e.dateTime)} · ${skClock(e.dateTime)}',
                        price: double.tryParse(
                            e.event.price.replaceAll(',', '.')),
                        onTap: () => NavigationHandler.goToShow(
                            context, e.show.id, e.show.name,
                            imageUrl: e.show.imageUrl, title: e.show.name),
                      ),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(children: [
                if (!pin.isExternalOnly && (rest > 0 || widget.expanded))
                  TextButton(
                    onPressed: widget.onToggle,
                    child: Text(widget.expanded
                        ? 'Daha az göster'
                        : '$rest seans daha'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => NavigationHandler.goToStage(
                      context, stage.id, stage.name,
                      imageUrl: stage.imageUrl, title: stage.name),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Sahneye git'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String title;
  final String when;
  final double? price;
  final VoidCallback onTap;
  const _SessionRow(
      {required this.title,
      required this.when,
      required this.price,
      required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $when',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 14.5, weight: FontWeight.w700)),
                  Text(when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 12.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
            if (price != null && price! > 0)
              Text("${skPrice(price!)}'den",
                  style: Sk.ui(context,
                      size: 14, color: cs.primary, weight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

// ─── Harita + özet paneli ────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  final NearbyOverview overview;
  final Stage? focused;
  final ValueChanged<NearbyPin> onPinTap;
  final double height;

  const _MapPanel({
    super.key,
    required this.overview,
    required this.focused,
    required this.onPinTap,
    required this.height,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final NearbyOverview o = overview;
    NearbyPin? focusedPin;
    for (final NearbyPin p in o.pins) {
      if (p.stage.id == focused?.id) focusedPin = p;
    }
    final NearbyPin? nearest = o.pins.isEmpty ? null : o.pins.first;

    Widget stat(final String v, final String l) => Expanded(
          child: Column(children: [
            Text(v, style: Sk.display(context, size: 26, height: 1.1)),
            const SizedBox(height: 2),
            Text(l,
                textAlign: TextAlign.center,
                style: Sk.ui(context,
                    size: 12,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
          ]),
        );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: NearbyEventsMap(
              height: height,
              focusedStage: focused,
              onPinTap: onPinTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  stat('${o.inside.length}', '${o.softRadiusKm} km içinde\nsahne'),
                  stat('${o.insideEventCount}', 'yaklaşan\nseans'),
                  stat('${o.outside.length}', 'daha uzakta\nsahne'),
                ]),
                const SizedBox(height: 14),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                if (focusedPin != null) ...[
                  Text('Seçili sahne',
                      style: Sk.ui(context,
                          size: 12,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(focusedPin.stage.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 16, weight: FontWeight.w800, height: 1.25)),
                  Text(
                      '${focusedPin.distanceKm.toStringAsFixed(1)} km · '
                      '${focusedPin.entries.length} seans',
                      style: Sk.ui(context,
                          size: 13,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => NavigationHandler.goToStage(
                        context, focusedPin!.stage.id, focusedPin.stage.name,
                        imageUrl: focusedPin.stage.imageUrl,
                        title: focusedPin.stage.name),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: const StadiumBorder()),
                    child: const Text('Sahneye git'),
                  ),
                ] else if (nearest != null)
                  Text(
                      'En yakın sahne: ${nearest.stage.name} '
                      '(${nearest.distanceKm.toStringAsFixed(1)} km)',
                      style: Sk.ui(context,
                          size: 13.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600,
                          height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

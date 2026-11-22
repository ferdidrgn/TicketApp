import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/map/tiyatrol_map.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';

/// Anahtar gerektirmeyen OpenStreetMap tabanlı Yakınımdakiler haritası.
class NearbyEventsMap extends ConsumerStatefulWidget {
  final double? height;
  final Stage? focusedStage;
  final ValueChanged<NearbyPin>? onPinTap;
  final bool expandable;

  const NearbyEventsMap({
    super.key,
    this.height = 280,
    this.focusedStage,
    this.onPinTap,
    this.expandable = true,
  });

  @override
  ConsumerState<NearbyEventsMap> createState() => _NearbyEventsMapState();
}

class _NearbyEventsMapState extends ConsumerState<NearbyEventsMap> {
  final MapController _controller = MapController();
  String? _fittedForKey;
  NearbyPin? _selectedPin;
  bool _ready = false;

  bool _valid(final double lat, final double lng) =>
      !(lat == 0 && lng == 0) && lat.abs() <= 90 && lng.abs() <= 180;

  @override
  void didUpdateWidget(covariant final NearbyEventsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stage = widget.focusedStage;
    if (!_ready || stage == null || stage.id == oldWidget.focusedStage?.id) {
      return;
    }
    if (_valid(stage.locationLat, stage.locationLng)) {
      _controller.move(LatLng(stage.locationLat, stage.locationLng), 14);
    }
  }

  void _fit(final NearbyOverview overview, {final bool force = false}) {
    final key =
        '${overview.position.latitude},${overview.position.longitude}|${overview.pins.length}|${overview.softRadiusKm}';
    if (!_ready || (!force && _fittedForKey == key)) {
      return;
    }
    _fittedForKey = key;
    final points = <LatLng>[
      LatLng(overview.position.latitude, overview.position.longitude),
      for (final pin in overview.pins)
        if (_valid(pin.stage.locationLat, pin.stage.locationLng))
          LatLng(pin.stage.locationLat, pin.stage.locationLng),
    ];
    if (points.length == 1) {
      _controller.move(points.first, 11);
    } else {
      _controller.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(56),
        maxZoom: 14,
      ));
    }
  }

  void _zoom(final double delta) {
    if (!_ready) {
      return;
    }
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + delta).clamp(3, 18));
  }

  void _select(final NearbyPin pin) {
    setState(() => _selectedPin = pin);
    _controller.move(
      LatLng(pin.stage.locationLat, pin.stage.locationLng),
      _controller.camera.zoom.clamp(11, 16),
    );
    widget.onPinTap?.call(pin);
  }

  void _openShow(final NearbyPin pin) {
    final show = pin.externalShow ??
        (pin.entries.length == 1 ? pin.entries.first.show : null);
    if (show == null) {
      return;
    }
    NavigationHandler.goToShow(context, show.id, show.name,
        imageUrl: show.imageUrl, title: show.name);
  }

  void _expand() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final context) => _ExpandedMapSheet(
          focusedStage: widget.focusedStage,
          onPinTap: widget.onPinTap,
        ),
      );

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final position = ref.watch(devicePositionProvider);
    final overview = ref.watch(nearbyOverviewProvider);
    final body = position.when(
      loading: () => const _StatusPane(
        icon: Icons.my_location_rounded,
        label: 'Konumun alınıyor…',
        hint: 'Konum izni açıksa kısa sürede burada görünür.',
      ),
      error: (final error, final _) => _StatusPane(
        icon: Icons.location_off_rounded,
        label: error is LocationFailure ? 'Konum gerekli' : 'Konum alınamadı',
        hint: error is LocationFailure
            ? error.message
            : 'Konum iznini kontrol edip tekrar dene.',
      ),
      data: (final current) {
        if (overview.isLoading && !overview.hasValue) {
          final point = LatLng(current.latitude, current.longitude);
          return Stack(fit: StackFit.expand, children: [
            TiyatrolMap(
              center: point,
              zoom: 12,
              markers: [_deviceMarker(context, point)],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TiyatrolMapLoadingBar(label: 'Sahneler yükleniyor…'),
            ),
          ]);
        }
        if (overview.hasError && !overview.hasValue) {
          return const _StatusPane(
            icon: Icons.cloud_off_rounded,
            label: 'Seanslar yüklenemedi',
            hint: 'İnterneti kontrol edip sayfayı yenile.',
          );
        }
        final data = overview.value;
        return data == null
            ? const _StatusPane(
                icon: Icons.map_outlined, label: 'Harita hazırlanıyor')
            : _map(context, data);
      },
    );

    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
        color: cs.surfaceContainer,
      ),
      child: body,
    );
  }

  Widget _map(final BuildContext context, final NearbyOverview data) {
    final cs = Theme.of(context).colorScheme;
    final me = LatLng(data.position.latitude, data.position.longitude);
    final focusedId = widget.focusedStage?.id;
    return Stack(children: [
      TiyatrolMap(
        controller: _controller,
        center: me,
        zoom: 11,
        options: MapOptions(
          initialCenter: me,
          initialZoom: 11,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onMapReady: () {
            _ready = true;
            _fit(data);
          },
        ),
        circles: [
          CircleMarker(
            point: me,
            radius: data.softRadiusMeters,
            useRadiusInMeter: true,
            color: cs.primary.withValues(alpha: 0.08),
            borderColor: cs.primary.withValues(alpha: 0.7),
            borderStrokeWidth: 2,
          ),
        ],
        markers: [
          _deviceMarker(context, me),
          for (final pin in data.pins)
            if (_valid(pin.stage.locationLat, pin.stage.locationLng))
              Marker(
                point: LatLng(pin.stage.locationLat, pin.stage.locationLng),
                width: 52,
                height: 52,
                child: TiyatrolMapPin(
                  semanticsLabel: '${pin.stage.name}, ${_summary(pin)}',
                  color: pin.stage.id == focusedId || _selectedPin == pin
                      ? cs.tertiary
                      : pin.isApproximate
                          ? cs.secondary
                          : pin.inside
                              ? cs.primary
                              : cs.onSurfaceVariant,
                  selected: pin.stage.id == focusedId || _selectedPin == pin,
                  onTap: () => _select(pin),
                ),
              ),
        ],
      ),
      Positioned(
        left: AppSpacing.sm,
        top: AppSpacing.sm,
        child: _Legend(
          city: data.metro.name,
          softKm: data.softRadiusKm,
          inside: data.inside.length,
          outside: data.outside.length,
        ),
      ),
      Positioned(
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        child: Column(children: [
          if (widget.expandable) ...[
            _MapFab(
                icon: Icons.open_in_full_rounded,
                label: 'Haritayı büyüt',
                onTap: _expand),
            const SizedBox(height: AppSpacing.sm),
          ],
          _MapFab(
              icon: Icons.add_rounded,
              label: 'Yakınlaştır',
              onTap: () => _zoom(1)),
          const SizedBox(height: AppSpacing.sm),
          _MapFab(
              icon: Icons.remove_rounded,
              label: 'Uzaklaştır',
              onTap: () => _zoom(-1)),
          const SizedBox(height: AppSpacing.sm),
          _MapFab(
              icon: Icons.my_location_rounded,
              label: 'Konumuma dön',
              onTap: () => _fit(data, force: true)),
        ]),
      ),
      if (_selectedPin case final pin?)
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          // OSM lisans atfını hiçbir durumda kartın altında bırakma.
          bottom: AppSpacing.massive,
          child: _PinCard(
            pin: pin,
            onOpen: pin.externalShow != null || pin.entries.length == 1
                ? () => _openShow(pin)
                : null,
            onClose: () => setState(() => _selectedPin = null),
          ),
        ),
    ]);
  }

  Marker _deviceMarker(final BuildContext context, final LatLng point) =>
      Marker(
        point: point,
        width: 48,
        height: 48,
        child: TiyatrolMapPin(
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.my_location_rounded,
          semanticsLabel: 'Konumun',
        ),
      );

  String _summary(final NearbyPin pin) =>
      '${pin.distanceKm.toStringAsFixed(pin.distanceKm < 10 ? 1 : 0)} kilometre, '
      '${pin.entries.isEmpty ? 'harici oyun' : '${pin.entries.length} seans'}';
}

class _PinCard extends StatelessWidget {
  final NearbyPin pin;
  final VoidCallback? onOpen;
  final VoidCallback onClose;
  const _PinCard(
      {required this.pin, required this.onOpen, required this.onClose});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(children: [
          Icon(Icons.theater_comedy_rounded, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pin.stage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                '${pin.distanceKm.toStringAsFixed(pin.distanceKm < 10 ? 1 : 0)} km · ${pin.entries.isEmpty ? 'Harici oyun' : '${pin.entries.length} seans'}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          )),
          if (onOpen != null)
            IconButton(
                tooltip: 'Oyunu aç',
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward_rounded)),
          IconButton(
              tooltip: 'Kapat',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded)),
        ]),
      ),
    );
  }
}

class _StatusPane extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  const _StatusPane({required this.icon, required this.label, this.hint});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(fit: StackFit.expand, children: [
      const ShimmerLoading(
          width: double.infinity, height: double.infinity, borderRadius: 0),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontSize: 12, height: 1.35)),
          ],
        ]),
      ),
    ]);
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(final BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        elevation: 2,
        shape: const CircleBorder(),
        child: IconButton(
            tooltip: label, onPressed: onTap, icon: Icon(icon, size: 20)),
      );
}

class _Legend extends StatelessWidget {
  final String city;
  final int softKm;
  final int inside;
  final int outside;
  const _Legend(
      {required this.city,
      required this.softKm,
      required this.inside,
      required this.outside});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
        color: cs.onSurface, fontSize: 11.5, fontWeight: FontWeight.w700);
    Widget item(final Color color, final String label) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: style),
        ]);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(city == 'Türkiye' ? 'Bölge' : city,
                style: style.copyWith(color: cs.primary)),
            item(cs.primary, '$softKm km ($inside)'),
            item(cs.onSurfaceVariant, 'Uzak ($outside)'),
          ]),
    );
  }
}

class _ExpandedMapSheet extends StatelessWidget {
  final Stage? focusedStage;
  final ValueChanged<NearbyPin>? onPinTap;
  const _ExpandedMapSheet({required this.focusedStage, required this.onPinTap});

  @override
  Widget build(final BuildContext context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.92,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            child: Row(children: [
              const Expanded(
                  child: Text('Yakınımdakiler haritası',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800))),
              IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
            child: NearbyEventsMap(
                height: null,
                expandable: false,
                focusedStage: focusedStage,
                onPinTap: onPinTap),
          )),
        ]),
      );
}

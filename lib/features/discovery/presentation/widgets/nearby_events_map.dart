import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import 'dark_map_style.dart';

/// Yakındakiler haritası — stil asset, zoom, tam ekran, yeniden ortala.
class NearbyEventsMap extends ConsumerStatefulWidget {
  final double? height;
  final Stage? focusedStage;
  final ValueChanged<NearbyPin>? onPinTap;
  /// Tam ekran sheet içindeyken büyüt butonu gizlenir (iç içe sheet yok).
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
  GoogleMapController? _controller;
  String? _fittedForKey;
  bool _disposed = false;
  String? _style;

  @override
  void initState() {
    super.initState();
    loadDarkMapStyle().then((final s) {
      if (mounted) setState(() => _style = s);
    });
  }

  @override
  void didUpdateWidget(covariant final NearbyEventsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Stage? stage = widget.focusedStage;
    if (stage == null || stage.id == oldWidget.focusedStage?.id) return;
    if (!_hasCoords(stage.locationLat, stage.locationLng)) return;
    _safeCamera(() async {
      final GoogleMapController? c = _controller;
      if (c == null) return;
      await c.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(stage.locationLat, stage.locationLng), 14));
      try {
        await c.showMarkerInfoWindow(MarkerId('stage-${stage.id}'));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _disposed = true;
    final GoogleMapController? c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  bool _hasCoords(final double lat, final double lng) =>
      !(lat == 0 && lng == 0) && lat.abs() <= 90 && lng.abs() <= 180;

  Future<void> _safeCamera(final Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      debugPrint('NearbyEventsMap camera: $e\n$st');
    }
  }

  void _fit(final NearbyOverview o, {final bool force = false}) {
    final GoogleMapController? controller = _controller;
    final String key =
        '${o.position.latitude},${o.position.longitude}|${o.pins.length}|${o.softRadiusKm}';
    if (controller == null || _disposed) return;
    if (!force && _fittedForKey == key) return;
    _fittedForKey = key;

    final LatLng me = LatLng(o.position.latitude, o.position.longitude);
    final points = <LatLng>[
      me,
      for (final p in o.pins)
        if (_hasCoords(p.stage.locationLat, p.stage.locationLng))
          LatLng(p.stage.locationLat, p.stage.locationLng),
    ];

    _safeCamera(() async {
      if (_disposed || _controller == null) return;
      if (points.length < 2) {
        await _controller!.moveCamera(CameraUpdate.newLatLngZoom(me, 11));
        return;
      }
      double s = points.first.latitude, n = s;
      double w = points.first.longitude, e = w;
      for (final p in points) {
        s = math.min(s, p.latitude);
        n = math.max(n, p.latitude);
        w = math.min(w, p.longitude);
        e = math.max(e, p.longitude);
      }
      const double pad = 0.04;
      if ((n - s).abs() < pad) {
        s -= pad;
        n += pad;
      }
      if ((e - w).abs() < pad) {
        w -= pad;
        e += pad;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (_disposed || _controller == null) return;
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(s, w),
            northeast: LatLng(n, e),
          ),
          56,
        ),
      );
    });
  }

  Future<void> _zoomBy(final double delta) async {
    final GoogleMapController? c = _controller;
    if (c == null) return;
    await _safeCamera(() async {
      final double z = await c.getZoomLevel();
      await c.animateCamera(CameraUpdate.zoomTo((z + delta).clamp(3, 18)));
    });
  }

  void _openExpanded() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final ctx) => _ExpandedMapSheet(
        focusedStage: widget.focusedStage,
        onPinTap: widget.onPinTap,
      ),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> get _gestures =>
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      };

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final posAsync = ref.watch(devicePositionProvider);
    final overviewState = ref.watch(nearbyOverviewProvider);
    final String? style =
        Theme.of(context).brightness == Brightness.dark
            ? (_style ?? kDarkMapStyleFallback)
            : null;

    final Widget body = posAsync.when(
        loading: () => const _StatusPane(
          icon: Icons.my_location_rounded,
          label: 'Konumun alınıyor…',
          hint: 'Konum izni açıksa kısa sürede burada görünür.',
        ),
        error: (final err, final _) => _StatusPane(
          icon: Icons.location_off_rounded,
          label: err is LocationFailure
              ? 'Konum gerekli'
              : 'Konum alınamadı',
          hint: err is LocationFailure
              ? err.message
              : 'Konum iznini kontrol edip tekrar dene.',
        ),
        data: (final pos) {
          // Konum hazır; sahneler hâlâ geliyor olabilir.
          if (overviewState.isLoading && !overviewState.hasValue) {
            return Stack(
              fit: StackFit.expand,
              children: [
                GoogleMap(
                  style: style,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(pos.latitude, pos.longitude),
                    zoom: 12,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('device-position'),
                      position: LatLng(pos.latitude, pos.longitude),
                      infoWindow: const InfoWindow(title: 'Konumun'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                    ),
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: _gestures,
                  onMapCreated: (final c) {
                    if (_disposed) {
                      c.dispose();
                      return;
                    }
                    _controller = c;
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: cs.surface.withValues(alpha: 0.92),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Sahneler yükleniyor…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          if (overviewState.hasError && !overviewState.hasValue) {
            return _StatusPane(
              icon: Icons.cloud_off_rounded,
              label: 'Seanslar yüklenemedi',
              hint: 'İnterneti kontrol edip sayfayı yenile.',
            );
          }

          final NearbyOverview? o = overviewState.value;
          if (o == null) {
            return _StatusPane(
              icon: Icons.map_outlined,
              label: 'Harita hazırlanıyor',
            );
          }

          return _MapBody(
            overview: o,
            focusedStage: widget.focusedStage,
            style: style,
            gestureRecognizers: _gestures,
            expandable: widget.expandable,
            onMapCreated: (final c) {
              if (_disposed) {
                c.dispose();
                return;
              }
              _controller = c;
              _fit(o);
            },
            onPinTap: widget.onPinTap,
            onExpand: _openExpanded,
            onRecenter: () => _fit(o, force: true),
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
          );
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
}

class _StatusPane extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  const _StatusPane({required this.icon, required this.label, this.hint});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ShimmerLoading(
            width: double.infinity, height: double.infinity, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              if (hint != null) ...[
                const SizedBox(height: 6),
                Text(hint!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MapBody extends StatelessWidget {
  final NearbyOverview overview;
  final Stage? focusedStage;
  final String? style;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final bool expandable;
  final MapCreatedCallback onMapCreated;
  final ValueChanged<NearbyPin>? onPinTap;
  final VoidCallback onExpand;
  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _MapBody({
    required this.overview,
    required this.focusedStage,
    required this.style,
    required this.gestureRecognizers,
    required this.expandable,
    required this.onMapCreated,
    required this.onPinTap,
    required this.onExpand,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = overview;
    final LatLng me = LatLng(o.position.latitude, o.position.longitude);
    final String? focusedId = focusedStage?.id;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('device-position'),
        position: me,
        infoWindow: const InfoWindow(title: 'Konumun'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      for (final p in o.pins)
        if (!(p.stage.locationLat == 0 && p.stage.locationLng == 0))
          Marker(
            markerId: MarkerId('stage-${p.stage.id}'),
            position: LatLng(p.stage.locationLat, p.stage.locationLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              p.stage.id == focusedId
                  ? BitmapDescriptor.hueYellow
                  : (p.isApproximate
                      ? BitmapDescriptor.hueOrange
                      : (p.inside
                          ? BitmapDescriptor.hueRed
                          : BitmapDescriptor.hueViolet)),
            ),
            infoWindow: InfoWindow(
              title: p.stage.name,
              snippet: p.isExternalOnly
                  ? 'Harici · ${p.cityLabel ?? 'şehir'} · ${p.distanceKm.toStringAsFixed(p.distanceKm < 10 ? 1 : 0)} km'
                  : '${p.isApproximate ? 'Yaklaşık · ' : ''}${p.distanceKm.toStringAsFixed(p.distanceKm < 10 ? 1 : 0)} km · '
                      '${p.entries.length == 1 ? p.entries.first.show.name : '${p.entries.length} seans'}',
            ),
            onTap: () {
              if (onPinTap != null) {
                onPinTap!(p);
              } else if (p.externalShow != null) {
                final show = p.externalShow!;
                NavigationHandler.goToShow(context, show.id, show.name,
                    imageUrl: show.imageUrl, title: show.name);
              } else if (p.entries.length == 1) {
                final show = p.entries.first.show;
                NavigationHandler.goToShow(context, show.id, show.name,
                    imageUrl: show.imageUrl, title: show.name);
              }
            },
          ),
    };

    return Stack(
      children: [
        GoogleMap(
          style: style,
          initialCameraPosition: CameraPosition(target: me, zoom: 11),
          markers: markers,
          circles: {
            Circle(
              circleId: const CircleId('soft-radius'),
              center: me,
              radius: o.softRadiusMeters,
              strokeWidth: 2,
              strokeColor: cs.primary.withValues(alpha: 0.7),
              fillColor: cs.primary.withValues(alpha: 0.08),
            ),
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          gestureRecognizers: gestureRecognizers,
          onMapCreated: onMapCreated,
        ),
        Positioned(
          left: AppSpacing.sm,
          top: AppSpacing.sm,
          child: _Legend(
            city: o.metro.name,
            softKm: o.softRadiusKm,
            inside: o.inside.length,
            outside: o.outside.length,
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          child: Column(
            children: [
              if (expandable) ...[
                _MapFab(
                  icon: Icons.open_in_full_rounded,
                  tooltip: 'Haritayı büyüt',
                  onTap: onExpand,
                ),
                const SizedBox(height: 8),
              ],
              _MapFab(
                icon: Icons.add_rounded,
                tooltip: 'Yakınlaştır',
                onTap: onZoomIn,
              ),
              const SizedBox(height: 8),
              _MapFab(
                icon: Icons.remove_rounded,
                tooltip: 'Uzaklaştır',
                onTap: onZoomOut,
              ),
              const SizedBox(height: 8),
              _MapFab(
                icon: Icons.my_location_rounded,
                tooltip: 'Konumuma dön',
                onTap: onRecenter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _MapFab(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.94),
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String city;
  final int softKm;
  final int inside;
  final int outside;
  const _Legend({
    required this.city,
    required this.softKm,
    required this.inside,
    required this.outside,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget dot(final Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    final style = TextStyle(
        color: cs.onSurface, fontSize: 11.5, fontWeight: FontWeight.w700);
    final String cityLabel = city == 'Türkiye' ? 'Bölge' : city;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: 4,
        children: [
          Text(cityLabel, style: style.copyWith(color: cs.primary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot(const Color(0xFFE53935)),
              const SizedBox(width: 4),
              Text('$softKm km ($inside)', style: style),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot(const Color(0xFF8E24AA)),
              const SizedBox(width: 4),
              Text('Uzak ($outside)', style: style),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tam ekrana yakın büyütülmüş harita (bottom sheet).
class _ExpandedMapSheet extends StatelessWidget {
  final Stage? focusedStage;
  final ValueChanged<NearbyPin>? onPinTap;

  const _ExpandedMapSheet({
    required this.focusedStage,
    required this.onPinTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double h = MediaQuery.sizeOf(context).height * 0.92;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Yakınımdakiler haritası',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: NearbyEventsMap(
                height: null,
                expandable: false,
                focusedStage: focusedStage,
                onPinTap: onPinTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

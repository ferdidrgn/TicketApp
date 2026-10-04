import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/nearby_events_provider.dart';
import 'dark_map_style.dart';
import 'nearby_location_permission_view.dart';

/// Yakındakiler haritası — TÜM yaklaşan seansların sahneleri.
///
/// - Kullanıcının konumu etrafında 50 km'lik halka (vurgu renginde).
/// - Halkanın içindeki sahneler kırmızı, dışındakiler mor işaret; odaktaki
///   sahne sarı.
/// - Kamera açılışta kullanıcıyı ve tüm sahneleri kapsayacak şekilde
///   ayarlanır (dışarıdaki oyun da görünür).
/// - Sol üstte lejant: "50 km içinde (N)  ·  Daha uzakta (M)".
/// - İşarete dokununca: tek seansı varsa oyuna gider, yoksa [onPinTap].
///
/// Veri `nearbyOverviewProvider`'dan; konum alınamazsa izin ekranı.
class NearbyEventsMap extends ConsumerStatefulWidget {
  final double height;
  final Stage? focusedStage;
  final ValueChanged<NearbyPin>? onPinTap;

  const NearbyEventsMap({
    super.key,
    this.height = 260,
    this.focusedStage,
    this.onPinTap,
  });

  @override
  ConsumerState<NearbyEventsMap> createState() => _NearbyEventsMapState();
}

class _NearbyEventsMapState extends ConsumerState<NearbyEventsMap> {
  GoogleMapController? _controller;
  bool _fitted = false;

  @override
  void didUpdateWidget(covariant final NearbyEventsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Stage? stage = widget.focusedStage;
    if (stage != null && stage.id != oldWidget.focusedStage?.id) {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(stage.locationLat, stage.locationLng), 14));
      _controller?.showMarkerInfoWindow(MarkerId('stage-${stage.id}'));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Kullanıcı + tüm sahneleri kapsayan kamera.
  void _fit(final NearbyOverview o) {
    final controller = _controller;
    if (controller == null || _fitted) return;
    _fitted = true;
    final points = <LatLng>[
      LatLng(o.position.latitude, o.position.longitude),
      for (final p in o.pins) LatLng(p.stage.locationLat, p.stage.locationLng),
    ];
    if (points.length < 2) {
      controller.moveCamera(CameraUpdate.newLatLngZoom(points.first, 9));
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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 56));
    });
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overviewState = ref.watch(nearbyOverviewProvider);

    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
        color: cs.surfaceContainer,
      ),
      child: overviewState.when(
        loading: () => Stack(
          fit: StackFit.expand,
          children: [
            const ShimmerLoading(
                width: double.infinity, height: double.infinity, borderRadius: 0),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Konumun alınıyor',
                      style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        error: (final err, final _) => SingleChildScrollView(
          child: NearbyLocationPermissionView(
            error: err,
            foregroundColor: cs.onSurface,
            mutedColor: cs.onSurfaceVariant,
            accentColor: cs.primary,
            onAccentColor: cs.onPrimary,
          ),
        ),
        data: (final o) {
          final LatLng me = LatLng(o.position.latitude, o.position.longitude);
          final String? focusedId = widget.focusedStage?.id;
          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('device-position'),
              position: me,
              infoWindow: const InfoWindow(title: 'Konumun'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
            for (final p in o.pins)
              Marker(
                markerId: MarkerId('stage-${p.stage.id}'),
                position: LatLng(p.stage.locationLat, p.stage.locationLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  p.stage.id == focusedId
                      ? BitmapDescriptor.hueYellow
                      : (p.inside
                          ? BitmapDescriptor.hueRed
                          : BitmapDescriptor.hueViolet),
                ),
                infoWindow: InfoWindow(
                  title: p.stage.name,
                  snippet: '${p.distanceKm.toStringAsFixed(p.distanceKm < 10 ? 1 : 0)} km · '
                      '${p.entries.length == 1 ? p.entries.first.show.name : '${p.entries.length} seans'}',
                ),
                onTap: () {
                  if (widget.onPinTap != null) {
                    widget.onPinTap!(p);
                  } else if (p.entries.length == 1) {
                    final show = p.entries.first.show;
                    NavigationHandler.goToShow(context, show.id, show.name);
                  }
                },
              ),
          };

          return Stack(
            children: [
              GoogleMap(
                style: Theme.of(context).brightness == Brightness.dark
                    ? kDarkMapStyle
                    : null,
                initialCameraPosition: CameraPosition(target: me, zoom: 9),
                markers: markers,
                circles: {
                  Circle(
                    circleId: const CircleId('radius-50km'),
                    center: me,
                    radius: kNearbyRadiusMeters,
                    strokeWidth: 2,
                    strokeColor: cs.primary.withValues(alpha: 0.7),
                    fillColor: cs.primary.withValues(alpha: 0.08),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (final controller) {
                  _controller = controller;
                  _fit(o);
                },
              ),
              Positioned(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                child: _Legend(
                  inside: o.inside.length,
                  outside: o.outside.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final int inside;
  final int outside;
  const _Legend({required this.inside, required this.outside});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget dot(final Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    final style = TextStyle(
        color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w700);
    return Semantics(
      label: '50 km içinde $inside sahne, daha uzakta $outside sahne',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(const Color(0xFFE53935)),
            const SizedBox(width: 5),
            Text('50 km içinde ($inside)', style: style),
            const SizedBox(width: AppSpacing.md),
            dot(const Color(0xFF8E24AA)),
            const SizedBox(width: 5),
            Text('Daha uzakta ($outside)', style: style),
          ],
        ),
      ),
    );
  }
}

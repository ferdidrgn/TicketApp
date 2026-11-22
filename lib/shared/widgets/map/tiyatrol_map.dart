import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

const String kOpenStreetMapTileUrl =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// TiyatRol'un anahtarsız, açık kaynak harita temeli.
///
/// OSM'nin herkese açık karo sunucusu düşük/orta trafikli etkileşimli
/// gösterimler içindir. Görünür atıf ve uygulamayı tanımlayan User-Agent
/// bilinçli olarak burada merkezi tutulur.
class TiyatrolMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final MapController? controller;
  final List<Marker> markers;
  final List<CircleMarker> circles;
  final MapOptions? options;

  const TiyatrolMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.controller,
    this.markers = const <Marker>[],
    this.circles = const <CircleMarker>[],
    this.options,
  });

  @override
  Widget build(final BuildContext context) => FlutterMap(
        mapController: controller,
        options:
            options ?? MapOptions(initialCenter: center, initialZoom: zoom),
        children: [
          TileLayer(
            urlTemplate: kOpenStreetMapTileUrl,
            userAgentPackageName: 'com.ferdidrgn.ticketapp',
            maxZoom: 19,
          ),
          if (circles.isNotEmpty) CircleLayer(circles: circles),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap katkıda bulunanlar',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ],
      );
}

/// Haritada tema renkleriyle çizilen, erişilebilir sahne/konum işaretçisi.
class TiyatrolMapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool selected;

  const TiyatrolMapPin({
    super.key,
    required this.color,
    required this.semanticsLabel,
    this.icon = Icons.location_on_rounded,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: selected ? 46 : 40,
            height: selected ? 46 : 40,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: selected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.2),
                  blurRadius: selected ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: selected ? 27 : 23),
          ),
        ),
      ),
    );
  }
}

class TiyatrolMapLoadingBar extends StatelessWidget {
  final String label;

  const TiyatrolMapLoadingBar({super.key, required this.label});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

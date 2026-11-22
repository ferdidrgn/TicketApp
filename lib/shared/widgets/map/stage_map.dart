import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'tiyatrol_map.dart';

/// Sahne detaylarında kullanılan tek konumlu OpenStreetMap görünümü.
class StageMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String stageName;

  const StageMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.stageName,
  });

  @override
  Widget build(final BuildContext context) {
    final point = LatLng(latitude, longitude);
    return TiyatrolMap(
      center: point,
      zoom: 15,
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          // Detay sayfasının dikey kaydırmasını ele geçirme; kullanıcı yine
          // iki parmakla veya çift dokunarak haritayı yakınlaştırabilir.
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
        ),
      ),
      markers: [
        Marker(
          point: point,
          width: 52,
          height: 52,
          child: TiyatrolMapPin(
            color: Theme.of(context).colorScheme.primary,
            semanticsLabel: '$stageName konumu',
            selected: true,
          ),
        ),
      ],
    );
  }
}

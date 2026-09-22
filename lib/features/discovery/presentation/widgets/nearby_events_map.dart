import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import 'nearby_location_permission_view.dart';

// ==============================================================================
// GERÇEK, ETKİLEŞİMLİ HARİTA — "Yakınımdakiler"
// ==============================================================================
//
// `google_maps_flutter` zaten `stage_details.dart`'ta (bkz. `_buildStageMap`)
// kullanılıyor — burada AYNI paket, aynı teknik tekrar kullanılıyor. Marker'lar:
//   - kullanıcının GERÇEK cihaz konumu (`devicePositionProvider`)
//   - GERÇEK yakındaki sahnelerin GERÇEK `locationLat`/`locationLng`
//     koordinatları (`nearbyStageGroupsProvider` — zaten 50km + 1 ay
//     filtresinden geçmiş)
// Sahte bir konum/koordinat YOK; hiçbir marker uydurulmuyor.
//
// GOOGLE MAPS API ANAHTARI: bkz. `android/app/src/main/AndroidManifest.xml`,
// `ios/Runner/Info.plist` ve `web/index.html`'deki TODO yorumları — repoda
// gerçek bir Maps API anahtarı YOK (sahte bir anahtar da eklenmedi). Anahtar
// tanımlanana kadar harita platformuna göre boş/gri görünebilir; bu widget'ın
// kendisi doğru kurulu, eksik olan platform tarafı anahtar konfigürasyonu.

/// Kullanıcının konumu + yakındaki sahnelerin bulunduğu gerçek, etkileşimli
/// harita. Bir sahne marker'ına dokunmak — o sahnede tek bir yaklaşan
/// etkinlik varsa doğrudan o gösteriye, birden fazlaysa sahnenin kendi
/// detay sayfasına götürür.
class NearbyEventsMap extends ConsumerWidget {
  final double height;
  final Color borderColor;
  final Color surfaceColor;
  final Color foregroundColor;
  final Color mutedColor;
  final Color accentColor;

  const NearbyEventsMap({
    super.key,
    required this.borderColor,
    required this.surfaceColor,
    required this.foregroundColor,
    required this.mutedColor,
    required this.accentColor,
    this.height = 260,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final positionState = ref.watch(devicePositionProvider);
    final groupsState = ref.watch(nearbyStageGroupsProvider);

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        color: surfaceColor,
      ),
      child: positionState.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: accentColor)),
        error: (final err, final _) => SingleChildScrollView(
          child: NearbyLocationPermissionView(
            error: err,
            foregroundColor: foregroundColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
          ),
        ),
        data: (final position) {
          final LatLng userLatLng =
              LatLng(position.latitude, position.longitude);

          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('device-position'),
              position: userLatLng,
              infoWindow: const InfoWindow(title: 'Konumunuz'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
            for (final group in groupsState.value ?? const [])
              Marker(
                markerId: MarkerId('stage-${group.stage.id}'),
                position: LatLng(
                    group.stage.locationLat, group.stage.locationLng),
                infoWindow: InfoWindow(
                  title: group.stage.name,
                  snippet: group.entries.length == 1
                      ? group.entries.first.show.name
                      : '${group.entries.length} yaklaşan etkinlik',
                ),
                onTap: () {
                  if (group.entries.length == 1) {
                    final entry = group.entries.first;
                    NavigationHandler.goToShow(
                        context, entry.show.id, entry.show.name);
                  } else {
                    NavigationHandler.goToStage(
                        context, group.stage.id, group.stage.name);
                  }
                },
              ),
          };

          return GoogleMap(
            initialCameraPosition:
                CameraPosition(target: userLatLng, zoom: 11),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          );
        },
      ),
    );
  }
}

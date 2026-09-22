import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../stages/domain/entities/stage.dart';
import '../providers/location_provider.dart';
import '../providers/nearby_events_provider.dart';
import 'dark_map_style.dart';
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
//
// KOYU HARİTA STİLİ: `kDarkMapStyle` (bkz. `dark_map_style.dart`) — Google'ın
// standart, herkese açık "Night Mode" JSON'ı. Uygulamanın "Crimson Noir"
// koyu temasıyla artık parlak/beyaz-yeşil varsayılan Google stili göze
// batmıyor. Harita stilleri kendi ayrı renk sistemidir; bu istisna
// `app_colors.dart`'taki renk tokenlarını DEĞİŞTİRMİYOR.
//
// KART↔HARİTA SENKRONU: `focusedStage` dolu ve önceki build'den FARKLIYSA,
// `GoogleMapController.animateCamera` ile o sahnenin GERÇEK koordinatına
// gidilir ve `showMarkerInfoWindow` ile marker'ın bilgi balonu otomatik
// açılır (bkz. `nearby_events_page.dart`'taki kart listesi — bir karta
// dokunmak `focusedStage`'i günceller).

/// Kullanıcının konumu + yakındaki sahnelerin bulunduğu gerçek, etkileşimli
/// harita. Bir sahne marker'ına dokunmak — o sahnede tek bir yaklaşan
/// etkinlik varsa doğrudan o gösteriye, birden fazlaysa sahnenin kendi
/// detay sayfasına götürür.
class NearbyEventsMap extends ConsumerStatefulWidget {
  final double height;
  final Color borderColor;
  final Color surfaceColor;
  final Color foregroundColor;
  final Color mutedColor;
  final Color accentColor;

  /// Yan taraftaki/alttaki kart listesinden seçilen sahne — dolu olduğunda
  /// harita kamerası buraya GERÇEK koordinatıyla kayar ve marker'ı
  /// vurgulanır. `nearby_events_page.dart`'taki kart senkronu için.
  final Stage? focusedStage;

  const NearbyEventsMap({
    super.key,
    required this.borderColor,
    required this.surfaceColor,
    required this.foregroundColor,
    required this.mutedColor,
    required this.accentColor,
    this.height = 260,
    this.focusedStage,
  });

  @override
  ConsumerState<NearbyEventsMap> createState() => _NearbyEventsMapState();
}

class _NearbyEventsMapState extends ConsumerState<NearbyEventsMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant final NearbyEventsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Stage? stage = widget.focusedStage;
    if (stage != null && stage.id != oldWidget.focusedStage?.id) {
      _focusOnStage(stage);
    }
  }

  void _focusOnStage(final Stage stage) {
    final GoogleMapController? controller = _controller;
    if (controller == null) return;
    if (stage.locationLat == 0 && stage.locationLng == 0) return;
    controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(stage.locationLat, stage.locationLng), 15));
    controller.showMarkerInfoWindow(MarkerId('stage-${stage.id}'));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final positionState = ref.watch(devicePositionProvider);
    final groupsState = ref.watch(nearbyStageGroupsProvider);

    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: widget.borderColor),
        color: widget.surfaceColor,
      ),
      child: positionState.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: widget.accentColor)),
        error: (final err, final _) => SingleChildScrollView(
          child: NearbyLocationPermissionView(
            error: err,
            foregroundColor: widget.foregroundColor,
            mutedColor: widget.mutedColor,
            accentColor: widget.accentColor,
          ),
        ),
        data: (final position) {
          final LatLng userLatLng =
              LatLng(position.latitude, position.longitude);
          final String? focusedStageId = widget.focusedStage?.id;

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
                // Seçili sahne diğerlerinden belirgin şekilde ayrılsın diye
                // farklı bir marker rengi (hue) — özel bir görsel/asset
                // uydurmuyor, Google Maps'in kendi marker paletini kullanıyor.
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    group.stage.id == focusedStageId
                        ? BitmapDescriptor.hueYellow
                        : BitmapDescriptor.hueRose),
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
            style: kDarkMapStyle,
            initialCameraPosition:
                CameraPosition(target: userLatLng, zoom: 11),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (final controller) {
              _controller = controller;
              final Stage? stage = widget.focusedStage;
              if (stage != null) {
                // İlk karede kamera henüz hazır olmayabilir — bir sonraki
                // frame'e ertelenir.
                WidgetsBinding.instance
                    .addPostFrameCallback((final _) => _focusOnStage(stage));
              }
            },
          );
        },
      ),
    );
  }
}

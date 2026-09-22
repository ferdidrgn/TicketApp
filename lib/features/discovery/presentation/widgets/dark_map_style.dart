// ==============================================================================
// KOYU HARİTA STİLİ — Google'ın standart, herkese açık "Night Mode" JSON'ı
// ==============================================================================
//
// Bu STANDART bir Google Maps stil dizisidir (feature/element/stylers) —
// Google'ın kendi stil sihirbazının yayınladığı, sayısız resmi örnek ve
// üçüncü parti kaynakta (snazzy-maps dahil) birebir aynı biçimde tekrarlanan
// bilinen bir "koyu tema" JSON'ı. Uydurma bir API anahtarı/uç nokta DEĞİL —
// sadece statik, görsel bir stil verisi. Uygulamanın `WebColors`/
// `AppLightColors`/`AppDarkColors` renk tokenlarına BİREBİR uymaya
// çalışmıyor (harita stilleri kendi ayrı renk sistemidir, marka renklerini
// kopyalamak zorunda değil) — amaç sadece Google'ın parlak/beyaz-yeşil
// varsayılan stiliyle "Crimson Noir" koyu temanın yan yana göze batmasını
// önlemek.
//
// Kullanım: `GoogleMap(style: kDarkMapStyle, ...)` — `google_maps_flutter`
// 2.7+'ta eklenen deklaratif `style` parametresi, `GoogleMapController.
// setMapStyle()`'ın yerini alıyor ve ilk kare açılışında bile (controller
// hazır olmadan) doğru stille render ediyor.
const String kDarkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1b1b1b"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#373737"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [{"color": "#4e4e4e"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d3d3d"}]
  }
]
''';

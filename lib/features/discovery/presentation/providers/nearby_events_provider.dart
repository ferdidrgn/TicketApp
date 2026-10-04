import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import 'location_provider.dart';

// ==============================================================================
// "YAKINDAKİLER" (NEARBY) İÇİN GERÇEK VERİ SAĞLAYICILARI
// ==============================================================================
//
// `event_provider.dart` / `show_provider.dart` / `stage_provider.dart`
// `@riverpod` kod üretimi kullanıyor (`part '*.g.dart'`) — bu sandbox'ta
// `build_runner` çalıştırılamadığı için o dosyalara yeni provider EKLEMEK
// mümkün değil (yeni bir `.g.dart` parçası gerektirir). Bu yüzden bu dosya
// klasik `FutureProvider` API'sini (flutter_riverpod) kullanıyor — ek kod
// üretimi gerektirmeden derlenir — ve o dosyalardaki HAZIR provider'ları
// (`activeShowsProvider`, `eventsByShowIdsProvider`, `stagesByIdsProvider`)
// birleştirerek gerçek, Firestore kökenli bir "yakındaki etkinlikler"
// listesi türetiyor. Hiçbir alan uydurulmuyor; bir gösteri/etkinlik/sahne
// eksikse (henüz Firestore'a yazılmamışsa) o kayıt sonuçtan sessizce
// düşürülüyor — sahte bir yer tutucuyla doldurulmuyor.

/// Tek bir gerçek, YAKLAŞAN etkinliği; ait olduğu gösteri ve sahnelendiği
/// gerçek sahne bilgisiyle birlikte taşıyan birleşik kayıt.
class NearbyEventEntry {
  final Event event;
  final Show show;
  final Stage stage;
  final DateTime dateTime;

  const NearbyEventEntry({
    required this.event,
    required this.show,
    required this.stage,
    required this.dateTime,
  });
}

/// Aynı sahnede oynayan yaklaşan etkinlikleri bir arada tutan grup — "Popüler
/// Sahne ve Mekanlar" bölümü gerçek veriyle bunun üzerine kurulu.
class NearbyStageGroup {
  final Stage stage;
  final List<NearbyEventEntry> entries;

  const NearbyStageGroup({required this.stage, required this.entries});
}

/// 🟢 YAKLAŞAN GERÇEK ETKİNLİKLER
/// Şu an sahnede olan (yani takviminde en az bir gelecek tarihli etkinliği
/// bulunan — bkz. `activeShowsProvider`) tüm gösterilerin YAKLAŞAN
/// etkinliklerini, gerçekleştikleri gerçek sahnelerle birlikte, en yakın
/// tarihten en uzağa doğru sıralı döner.
///
/// Temel liste `activeShowsProvider(false)` — limitsiz sürüm — çünkü burada
/// amaç "son eklenen N oyun" değil, sahnede olan HER ŞEY.
final upcomingNearbyEventsProvider =
    FutureProvider<List<NearbyEventEntry>>((final ref) async {
  final shows = await ref.watch(activeShowsProvider(false).future);
  if (shows.isEmpty) return [];

  final showsById = {for (final s in shows) s.id: s};

  // Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Event.showId`
  // ve `Show.eventsId`); biri senkron kalmayı unutabilir. Her iki yoldan
  // gelen sonuçlar birleştiriliyor — bkz. `show_provider.dart`'taki
  // `_activeShowIdsFromEvents` yorumu, aynı kök sebep burada tekrarlanmasın.
  final eventIdsFromArrays = shows
      .expand((final s) => s.eventsId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();
  final eventLists = await Future.wait([
    ref.watch(eventsByShowIdsProvider(showsById.keys.toList()).future),
    eventIdsFromArrays.isNotEmpty
        ? ref.watch(eventsByIdsProvider(eventIdsFromArrays).future)
        : Future.value(<Event>[]),
  ]);
  final eventsById = <String, Event>{};
  for (final event in [...eventLists[0], ...eventLists[1]]) {
    eventsById[event.id] = event;
  }

  final showIdsByEventId = <String, Set<String>>{};
  for (final show in shows) {
    for (final eventId in show.eventsId) {
      if (eventId.isEmpty) continue;
      showIdsByEventId.putIfAbsent(eventId, () => {}).add(show.id);
    }
  }

  // `Event.showId` doluysa TEK doğruluk kaynağı odur (bkz.
  // `show_provider.dart` `_mergedEventsByShow`). Eskiden, `showId` dolu ama
  // o oyun bu listede yoksa `Show.eventsId` dizisine düşülüyordu — dizisi
  // bayat kalmış BAŞKA bir oyunun adı altında yanlış seans gösterilebiliyordu.
  // Dizi artık sadece `showId` BOŞSA yedek.
  String? resolveShowId(final Event event) {
    if (event.showId.isNotEmpty) {
      return showsById.containsKey(event.showId) ? event.showId : null;
    }
    return showIdsByEventId[event.id]?.first;
  }

  final now = DateTime.now();
  final upcoming = <(Event, Show, DateTime)>[];
  for (final event in eventsById.values) {
    final showId = resolveShowId(event);
    final show = showId == null ? null : showsById[showId];
    if (show == null) continue;
    final date = DateFormatter.parseDateString(event.date);
    if (date != null && date.isAfter(now)) upcoming.add((event, show, date));
  }
  if (upcoming.isEmpty) return [];

  final stageIds = upcoming
      .map((final e) => e.$1.stageId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();
  if (stageIds.isEmpty) return [];

  final stages = await ref.watch(stagesByIdsProvider(stageIds).future);
  final stagesById = {for (final s in stages) s.id: s};

  final entries = <NearbyEventEntry>[];
  for (final (event, show, date) in upcoming) {
    final stage = stagesById[event.stageId];
    if (stage == null) continue;
    entries.add(NearbyEventEntry(
      event: event,
      show: show,
      stage: stage,
      dateTime: date,
    ));
  }

  entries.sort((final a, final b) => a.dateTime.compareTo(b.dateTime));
  return entries;
});

// ==============================================================================
// 📍 GERÇEK KONUMA GÖRE "YAKINIMDAKİLER" — asıl özellik burada
// ==============================================================================
//
// Kullanıcının kendi talebi (birebir): "yakınınızdaki etkinlikler dediğimde
// konum sormamız gerekiyor. konumu neresi o konuma göre oyunlar bulmalıyız.
// oyunların sahneleri hangi şehirde ise ve 1 ay içerisinde oyun var ise
// yakın kısma eklemeliyiz." Yukarıdaki `upcomingNearbyEventsProvider` KONUM
// KULLANMIYOR (kasıtlı — `discovery_page.dart`'taki "Sizin İçin
// Önerilenler" ve `home_page_web.dart`'taki hero paneli de aynı provider'ı
// izliyor; o iki yer konum izni istemeyen genel bir "yaklaşan etkinlikler"
// vitrinidir, dokunulmadı). Bu bölüm SADECE "Yakınımdakiler" sayfası
// (`nearby_events_page.dart`) için, GERÇEK cihaz konumu + GERÇEK sahne
// koordinatı + GERÇEK 1 aylık takvim penceresiyle çalışan ayrı bir katman.
//
// Mesafe mi, şehir metni mi: `Stage.address` serbest metin bir adres
// string'i (örn. "Kadıköy, İstanbul") — güvenilir bir şehir alanı/kod YOK,
// metin eşleştirmesi ("İstanbul" geçiyor mu?) kırılgan ve YANLIŞ sonuç
// üretebilir (ör. "İstanbul Caddesi, Ankara"). `Stage.locationLat/locationLng`
// ise zaten gerçek, sayısal ve güvenilir — bu yüzden mesafe
// (`Geolocator.distanceBetween`, Haversine) tercih edildi. Koordinatı
// girilmemiş (0.0/0.0) bir sahne, kullanıcının GERÇEK konumundan pratikte
// binlerce km hesaplanır ve doğal olarak yarıçap dışında kalıp listeden
// düşer — sahte bir "yakın" varsayımı asla üretilmiyor.

/// "Yakın" sayılan yarıçap — 50 km. Türkiye'deki bir ilin/büyükşehrin
/// metropol alanını makul biçimde kapsıyor, aynı zamanda komşu şehirdeki
/// bir sahneyi de (mantıklıysa) dışarıda bırakmıyor.
const double kNearbyRadiusMeters = 50000;

// ==============================================================================
// 🗺️ HARİTA ÖZETİ — tüm yaklaşan seanslar, sahne başına mesafe
// ==============================================================================
//
// Sahibinin isteği: "50 km içinde 2 event, 1 tane de dışarıda bir oyun var;
// bunları haritada göstermemiz gerekiyor." Eskiden harita ve liste YALNIZCA
// "50 km içinde VE 30 gün içinde" olanları gösteriyordu — dışarıdaki oyun
// hiç çizilmiyor, tarihi 30 günden uzak seanslar kayboluyordu. Artık:
//   - Koordinatı olan HER sahne (yaklaşan seansı varsa) haritada,
//   - her birinin kullanıcıya GERÇEK uzaklığı (Haversine) hesaplanır,
//   - 50 km içi / dışı ayrımı işaretlenir (harita halkası + liste),
//   - takvim penceresi yok: yaklaşan her seans sayılır.
// Koordinatı girilmemiş (0,0) sahne uydurma bir konuma konmaz; sayısı
// `unlocatedCount` ile dürüstçe bildirilir.

/// Haritadaki tek bir sahne: o sahnedeki yaklaşan seanslar (tarih sırası)
/// ve kullanıcıya uzaklığı.
class NearbyPin {
  final Stage stage;
  final List<NearbyEventEntry> entries;
  final double distanceMeters;

  const NearbyPin({
    required this.stage,
    required this.entries,
    required this.distanceMeters,
  });

  bool get inside => distanceMeters <= kNearbyRadiusMeters;
  double get distanceKm => distanceMeters / 1000;
  DateTime get nextDate => entries.first.dateTime;
}

/// Konum + mesafeye göre sıralı sahne pinleri.
class NearbyOverview {
  final Position position;
  final List<NearbyPin> pins;
  final int unlocatedCount;

  const NearbyOverview({
    required this.position,
    required this.pins,
    required this.unlocatedCount,
  });

  List<NearbyPin> get inside => pins.where((final p) => p.inside).toList();
  List<NearbyPin> get outside => pins.where((final p) => !p.inside).toList();
  int get insideEventCount =>
      inside.fold(0, (final n, final p) => n + p.entries.length);
}

bool _hasCoordinates(final Stage s) =>
    !(s.locationLat == 0 && s.locationLng == 0) &&
    s.locationLat.abs() <= 90 &&
    s.locationLng.abs() <= 180;

/// 🗺️ Yakındakiler sayfası + haritanın TEK veri kaynağı.
/// Konum alınamazsa `LocationFailure` olduğu gibi fırlar (UI izin ekranı
/// gösterir).
final nearbyOverviewProvider = FutureProvider<NearbyOverview>((final ref) async {
  final position = await ref.watch(devicePositionProvider.future);
  final entries = await ref.watch(upcomingNearbyEventsProvider.future);

  final Map<String, List<NearbyEventEntry>> byStage = {};
  int unlocated = 0;
  for (final e in entries) {
    if (!_hasCoordinates(e.stage)) {
      unlocated++;
      continue;
    }
    byStage.putIfAbsent(e.stage.id, () => []).add(e);
  }

  final pins = byStage.values.map((final list) {
    list.sort((final a, final b) => a.dateTime.compareTo(b.dateTime));
    final stage = list.first.stage;
    return NearbyPin(
      stage: stage,
      entries: list,
      distanceMeters: LocationService.distanceInMeters(
        position.latitude,
        position.longitude,
        stage.locationLat,
        stage.locationLng,
      ),
    );
  }).toList()
    ..sort((final a, final b) => a.distanceMeters.compareTo(b.distanceMeters));

  return NearbyOverview(
      position: position, pins: pins, unlocatedCount: unlocated);
});

/// 📍 50 km içindeki yaklaşan seanslar (tarih sırası) — özetten türetilir.
final nearbyEventsProvider =
    FutureProvider<List<NearbyEventEntry>>((final ref) async {
  final overview = await ref.watch(nearbyOverviewProvider.future);
  return overview.inside.expand((final p) => p.entries).toList()
    ..sort((final a, final b) => a.dateTime.compareTo(b.dateTime));
});

/// 🏛️ 50 km içindeki sahne grupları (en yakın seans önce).
final nearbyStageGroupsProvider =
    FutureProvider<List<NearbyStageGroup>>((final ref) async {
  final overview = await ref.watch(nearbyOverviewProvider.future);
  final groups = overview.inside
      .map((final p) => NearbyStageGroup(stage: p.stage, entries: p.entries))
      .toList()
    ..sort((final a, final b) =>
        a.entries.first.dateTime.compareTo(b.entries.first.dateTime));
  return groups;
});

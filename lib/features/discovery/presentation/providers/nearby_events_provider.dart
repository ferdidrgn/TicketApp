import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/data/repositories/stage_repository_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/turkey_metro.dart';
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
  final upcoming = <_UpcomingRow>[];
  for (final event in eventsById.values) {
    final showId = resolveShowId(event);
    final show = showId == null ? null : showsById[showId];
    if (show == null) {
      continue;
    }
    final date = DateFormatter.parseDateString(event.date);
    if (date != null && date.isAfter(now)) {
      upcoming.add(_UpcomingRow(event: event, show: show, dateTime: date));
    }
  }
  if (upcoming.isEmpty) {
    return [];
  }

  // Hedefli sahne çözümleme (tüm Stage koleksiyonu DEĞİL):
  // 1) Event.stageId → documentId + `_id` whereIn
  // 2) Hâlâ sahnesiz show’lar → showsId array-contains-any
  final stageIds = upcoming
      .map((final e) => e.event.stageId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();

  final repo = ref.watch(stageRepositoryProvider);
  final Map<String, Stage> stagesById = {};
  final List<Stage> stagesByShow = [];

  if (stageIds.isNotEmpty) {
    final resolved = await repo.resolveStagesByIds(stageIds);
    resolved.fold((final _) {}, (final map) {
      stagesById.addAll(map);
      for (final s in map.values) {
        stagesById.putIfAbsent(s.id, () => s);
      }
    });
  }

  final showIdsNeedingStage = upcoming
      .where((final row) {
        final String sid = row.event.stageId;
        return sid.isEmpty || !stagesById.containsKey(sid);
      })
      .map((final row) => row.show.id)
      .toSet()
      .toList();

  if (showIdsNeedingStage.isNotEmpty) {
    final byShows = await repo.getStagesByShowIds(showIdsNeedingStage);
    byShows.fold((final _) {}, (final list) {
      stagesByShow.addAll(list);
      for (final s in list) {
        stagesById.putIfAbsent(s.id, () => s);
      }
    });
  }

  Stage? resolveStage(final _UpcomingRow row) {
    final String sid = row.event.stageId;
    if (sid.isNotEmpty) {
      final Stage? direct = stagesById[sid];
      if (direct != null) {
        return direct;
      }
    }
    for (final Stage s in stagesByShow) {
      if (s.showsId.contains(row.show.id)) {
        return s;
      }
    }
    for (final Stage s in stagesById.values) {
      if (s.showsId.contains(row.show.id)) {
        return s;
      }
    }
    return null;
  }

  final entries = <NearbyEventEntry>[];
  for (final row in upcoming) {
    final Stage? stage = resolveStage(row);
    if (stage == null) {
      continue;
    }
    entries.add(NearbyEventEntry(
      event: row.event,
      show: row.show,
      stage: stage,
      dateTime: row.dateTime,
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

/// Geriye dönük varsayılan — UI eski sabitleri için; asıl yarıçap
/// [NearbyOverview.softRadiusMeters] (şehre göre).
const double kNearbyRadiusMeters = 50000;

/// Yakındakiler takvim penceresi — yaklaşan seanslar (1 ay).
const int kNearbyHorizonDays = 30;

class _UpcomingRow {
  final Event event;
  final Show show;
  final DateTime dateTime;

  const _UpcomingRow({
    required this.event,
    required this.show,
    required this.dateTime,
  });
}

// ==============================================================================
// 🗺️ HARİTA ÖZETİ — metropol yarıçapı + sahne pinleri
// ==============================================================================
//
// Şehir: cihaz lat/lng → en yakın TrMetro (ücretsiz, çevrimdışı). Soft halka
// "yakın", hard üst sınır haritada gösterilecek pinler. Koordinatsız ama
// adresinde şehir geçen sahneler (harici tiyatrolar dahil) şehir merkezine
// yaklaşık pin olarak eklenir (`isApproximate`).

/// Haritadaki tek bir sahne / harici oyun pini.
class NearbyPin {
  final Stage stage;
  final List<NearbyEventEntry> entries;
  final double distanceMeters;
  final double softRadiusMeters;
  /// lat/lng yoktu veya harici URL şehrinden yaklaşık pin.
  final bool isApproximate;
  /// Bizde seansı yok; şehir harici bilet URL path'inden (Bubilet vb.).
  final Show? externalShow;
  /// URL/adres'ten çözülen şehir adı (ör. "İstanbul").
  final String? cityLabel;

  const NearbyPin({
    required this.stage,
    required this.entries,
    required this.distanceMeters,
    required this.softRadiusMeters,
    this.isApproximate = false,
    this.externalShow,
    this.cityLabel,
  });

  bool get isExternalOnly => externalShow != null;
  bool get inside => distanceMeters <= softRadiusMeters;
  double get distanceKm => distanceMeters / 1000;
  DateTime get nextDate =>
      entries.isNotEmpty ? entries.first.dateTime : DateTime.now();
}

/// Konum + mesafeye göre sıralı sahne pinleri.
class NearbyOverview {
  final Position position;
  final List<NearbyPin> pins;
  final int unlocatedCount;
  final TrMetro metro;
  final double softRadiusMeters;
  final double hardRadiusMeters;

  const NearbyOverview({
    required this.position,
    required this.pins,
    required this.unlocatedCount,
    required this.metro,
    required this.softRadiusMeters,
    required this.hardRadiusMeters,
  });

  int get softRadiusKm => (softRadiusMeters / 1000).round();

  List<NearbyPin> get inside => pins.where((final p) => p.inside).toList();
  List<NearbyPin> get outside => pins.where((final p) => !p.inside).toList();
  int get insideEventCount => inside.fold(
      0,
      (final n, final p) =>
          n + (p.isExternalOnly ? 1 : p.entries.length));
}

bool _hasCoordinates(final Stage s) =>
    !(s.locationLat == 0 && s.locationLng == 0) &&
    s.locationLat.abs() <= 90 &&
    s.locationLng.abs() <= 180;

/// Koordinatsız sahneyi adres şehrinin merkezine yerleştir (yaklaşık pin).
Stage _approxStage(final Stage s, final TrMetro city) => Stage(
      id: s.id,
      name: s.name,
      imageUrl: s.imageUrl,
      capacity: s.capacity,
      description: s.description,
      communication: s.communication,
      address: s.address.isEmpty ? city.name : s.address,
      locationLat: city.lat,
      locationLng: city.lng,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      showsId: s.showsId,
    );

/// Harici-only oyun için sentetik "şehir" sahnesi (URL slug → merkez).
Stage _externalCityStage(final Show show, final TrMetro city) => Stage(
      id: 'ext-${show.id}',
      name: show.name,
      imageUrl: show.imageUrl,
      capacity: '',
      description: '',
      communication: '',
      address: '${city.name} · harici bilet',
      locationLat: city.lat,
      locationLng: city.lng,
      createdAt: show.createdAt,
      updatedAt: show.updatedAt,
      showsId: [show.id],
    );

/// 🗺️ Yakındakiler sayfası + haritanın TEK veri kaynağı.
/// Konum alınamazsa `LocationFailure` olduğu gibi fırlar (UI izin ekranı
/// gösterir).
///
/// Harici biletli oyunlar (bizde Event yok): şehir
/// `Show.externalTicketUrl` path'inden okunur
/// (`bubilet.com.tr/istanbul/...`). Tur başka şehre kayınca admin linki
/// günceller — ayrı şehir alanı yok.
final nearbyOverviewProvider = FutureProvider<NearbyOverview>((final ref) async {
  final position = await ref.watch(devicePositionProvider.future);
  final entries = await ref.watch(upcomingNearbyEventsProvider.future);
  final allShows = await ref.watch(activeShowsProvider(false).future);

  final TrMetro metro =
      TrMetroAreas.resolve(position.latitude, position.longitude);
  final double softM = metro.softRadiusKm * 1000;
  final double hardM = metro.hardRadiusKm * 1000;

  // Seanslı oyunlar: önümüzdeki 30 gün. Harici-only (Event yok) ayrıca eklenir.
  final DateTime horizon =
      DateTime.now().add(const Duration(days: kNearbyHorizonDays));
  final List<NearbyEventEntry> inWindow = [
    for (final e in entries)
      if (!e.dateTime.isAfter(horizon)) e,
  ];

  final Map<String, List<NearbyEventEntry>> byStage = {};
  final showIdsWithSessions = <String>{};
  int unlocated = 0;
  for (final e in inWindow) {
    byStage.putIfAbsent(e.stage.id, () => []).add(e);
    showIdsWithSessions.add(e.show.id);
  }

  final pins = <NearbyPin>[];
  for (final list in byStage.values) {
    list.sort((final a, final b) => a.dateTime.compareTo(b.dateTime));
    final Stage raw = list.first.stage;
    final bool exact = _hasCoordinates(raw);
    Stage stage = raw;
    var approximate = false;
    String? cityLabel;
    if (!exact) {
      // Önce oyunun harici URL şehri (tur güncelliği), yoksa adres / ad.
      final Show show = list.first.show;
      final TrMetro? fromUrl = show.hasExternalTicketing
          ? TrMetroAreas.fromTicketUrl(show.externalTicketUrl)
          : null;
      final TrMetro? fromAddr = TrMetroAreas.fromAddress(raw.address);
      final TrMetro? fromName = TrMetroAreas.fromAddress(raw.name);
      final TrMetro? city = fromUrl ?? fromAddr ?? fromName;
      if (city == null) {
        unlocated += list.length;
        continue;
      }
      stage = _approxStage(raw, city);
      approximate = true;
      cityLabel = city.name;
    }

    double dist = LocationService.distanceInMeters(
      position.latitude,
      position.longitude,
      stage.locationLat,
      stage.locationLng,
    );
    if (dist > hardM && exact) {
      // Koordinat ADRESLE ÇELİŞİYOR (ör. adres "Ataşehir/İstanbul" ama
      // lat/long başka bir ülkede — admin'de yanlış girilmiş). Oyunu
      // haritadan sessizce düşürmek yerine adresteki şehre göre YAKLAŞIK
      // pin kullanılır; gerçek koordinat düzeltilince tam konum görünür.
      final TrMetro? addrCity = TrMetroAreas.fromAddress(raw.address) ??
          TrMetroAreas.fromAddress(raw.name);
      if (addrCity != null) {
        final Stage alt = _approxStage(raw, addrCity);
        final double d2 = LocationService.distanceInMeters(
          position.latitude,
          position.longitude,
          alt.locationLat,
          alt.locationLng,
        );
        if (d2 <= hardM) {
          stage = alt;
          dist = d2;
          approximate = true;
          cityLabel = addrCity.name;
        }
      }
    }
    if (dist > hardM) {
      continue;
    }

    pins.add(NearbyPin(
      stage: stage,
      entries: list,
      distanceMeters: dist,
      softRadiusMeters: softM,
      isApproximate: approximate,
      cityLabel: cityLabel,
    ));
  }

  // Harici-only: Event yok → URL slug şehri.
  for (final Show show in allShows) {
    if (!show.hasExternalTicketing) {
      continue;
    }
    if (showIdsWithSessions.contains(show.id)) {
      continue;
    }
    final TrMetro? city =
        TrMetroAreas.fromTicketUrl(show.externalTicketUrl);
    if (city == null) {
      unlocated += 1;
      continue;
    }
    final Stage stage = _externalCityStage(show, city);
    final double dist = LocationService.distanceInMeters(
      position.latitude,
      position.longitude,
      stage.locationLat,
      stage.locationLng,
    );
    if (dist > hardM) {
      continue;
    }
    pins.add(NearbyPin(
      stage: stage,
      entries: const [],
      distanceMeters: dist,
      softRadiusMeters: softM,
      isApproximate: true,
      externalShow: show,
      cityLabel: city.name,
    ));
  }

  pins.sort((final a, final b) => a.distanceMeters.compareTo(b.distanceMeters));

  return NearbyOverview(
    position: position,
    pins: pins,
    unlocatedCount: unlocated,
    metro: metro,
    softRadiusMeters: softM,
    hardRadiusMeters: hardM,
  );
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

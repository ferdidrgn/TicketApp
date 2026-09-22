import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

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

  String? resolveShowId(final Event event) {
    if (event.showId.isNotEmpty && showsById.containsKey(event.showId))
      return event.showId;
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

/// 🏛️ SAHNEYE GÖRE GRUPLANMIŞ YAKLAŞAN ETKİNLİKLER
/// `upcomingNearbyEventsProvider` sonucunu sahneye göre gruplar. Gruplar, en
/// yakın etkinliğe sahip sahne en önde olacak şekilde sıralanır.
final nearbyStagesProvider =
    FutureProvider<List<NearbyStageGroup>>((final ref) async {
  final entries = await ref.watch(upcomingNearbyEventsProvider.future);
  if (entries.isEmpty) return [];

  final Map<String, List<NearbyEventEntry>> grouped = {};
  for (final entry in entries) {
    grouped.putIfAbsent(entry.stage.id, () => []).add(entry);
  }

  final groups = grouped.values
      .map((final list) => NearbyStageGroup(stage: list.first.stage, entries: list))
      .toList();

  // `entries` zaten tarihe göre sıralı geldiğinden her grubun ilk öğesi o
  // sahnenin en yakın etkinliğidir.
  groups.sort((final a, final b) =>
      a.entries.first.dateTime.compareTo(b.entries.first.dateTime));

  return groups;
});

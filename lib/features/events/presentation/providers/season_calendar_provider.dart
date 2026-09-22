import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/event.dart';
import 'event_provider.dart';

part 'season_calendar_provider.g.dart';

/// Tek bir etkinliği, ait olduğu oyunla birlikte taşır.
/// (Sahne takviminde "hangi oyunun etkinliği" gösterebilmek için.)
class SeasonCalendarEntry {
  final Event event;
  final Show? show;
  final DateTime? dateTime;

  SeasonCalendarEntry({required this.event, required this.show})
      : dateTime = DateFormatter.parseDateString(event.date);
}

/// Tüm oyunların tüm etkinliklerini tek bir listede, tarihe göre sıralı
/// olarak döner. Sezon takvimi gibi "tüm oyunlar" görünümleri bunu kullanır.
///
/// Gerçek Firestore verisini kullanır: sahte/placeholder oyun adı göstermez.
/// Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Show.eventsId`
/// dizisi VE `Event.showId` alanı) — biri senkron kalmayı unutabilir. Bu
/// fonksiyon önceden SADECE `Show.eventsId` dizisini kullanıyordu; bir
/// event'in kendi `showId` alanı dolu ama hiçbir gösterinin dizisinde
/// listelenmemişse o event burada sessizce hiç görünmüyordu (tam olarak
/// "ana sayfada hâlâ yanlış oyun gösteriliyor" hatasının kök nedeniyle
/// aynı mekanizma — bkz. `show_provider.dart`'taki
/// `_activeShowIdsFromEvents`). Artık her iki yoldan gelen sonuçlar
/// birleştiriliyor.
@riverpod
Future<List<SeasonCalendarEntry>> seasonCalendarEntries(final Ref ref) async {
  final shows = await ref.watch(showsProvider(isLimit: false).future);
  if (shows.isEmpty) return [];

  final showIds = shows.map((final s) => s.id).toList();
  final eventIdsFromArrays =
      shows.expand((final s) => s.eventsId).where((final id) => id.isNotEmpty).toSet().toList();

  final results = await Future.wait([
    ref.watch(eventsByShowIdsProvider(showIds).future),
    eventIdsFromArrays.isNotEmpty
        ? ref.watch(eventsByIdsProvider(eventIdsFromArrays).future)
        : Future.value(<Event>[]),
  ]);

  final Map<String, Event> eventsById = {};
  for (final event in [...results[0], ...results[1]]) {
    eventsById[event.id] = event;
  }

  // eventId -> show eşlemesi: önce `Event.showId` (doluysa tek doğruluk
  // kaynağı), yoksa `Show.eventsId` dizisi üzerinden yedek.
  final showById = {for (final s in shows) s.id: s};
  final Map<String, Show> showByEventId = {};
  for (final show in shows) {
    for (final eventId in show.eventsId) {
      if (eventId.isNotEmpty) showByEventId[eventId] = show;
    }
  }

  final entries = eventsById.values
      .map((final e) => SeasonCalendarEntry(
          event: e,
          show: e.showId.isNotEmpty
              ? (showById[e.showId] ?? showByEventId[e.id])
              : showByEventId[e.id]))
      .where((final entry) => entry.dateTime != null)
      .toList()
    ..sort((final a, final b) => a.dateTime!.compareTo(b.dateTime!));

  return entries;
}

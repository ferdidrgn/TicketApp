import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/event.dart';

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
/// Gerçek Firestore verisini kullanır: sahte/placeholder oyun adı göstermez,
/// her etkinliğin gerçek `showId`'sine bakıp gerçek oyun adını eşler.
@riverpod
Future<List<SeasonCalendarEntry>> seasonCalendarEntries(final Ref ref) async {
  final shows = await ref.watch(showsProvider(isLimit: false).future);

  final Set<String> allEventIds = shows.expand((final s) => s.eventsId).toSet();
  if (allEventIds.isEmpty) return [];

  final events =
      await ref.watch(eventsByIdsProvider(allEventIds.toList()).future);
  final Map<String, Show> showsById = {for (final s in shows) s.id: s};

  final entries = events
      .map((final e) =>
          SeasonCalendarEntry(event: e, show: showsById[e.showId]))
      .where((final entry) => entry.dateTime != null)
      .toList()
    ..sort((final a, final b) => a.dateTime!.compareTo(b.dateTime!));

  return entries;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';

/// 🔥 Elle (codegen'siz) tanımlanmış provider'lar — Discover ve Nearby
/// sayfalarının önceden hardcoded olan içeriğini gerçek Firestore verisiyle
/// besler. `myTickets`/`playerDetail` ile aynı desen: Show -> Event -> Stage
/// ilişkisini paralel çekip birleştiriyoruz.
class DiscoverEvent {
  final Event event;
  final Show show;
  final Stage? stage;

  const DiscoverEvent({required this.event, required this.show, this.stage});

  double get price => double.tryParse(event.price) ?? 0;
}

/// Tüm gösterilerin yaklaşan (bugünden sonraki) etkinliklerini, Show ve
/// Stage bilgisiyle birlikte, en yakın tarihten en uzağa sıralı getirir.
final upcomingEventsProvider =
    FutureProvider.autoDispose<List<DiscoverEvent>>((final ref) async {
  final shows = await ref.watch(showsProvider(isLimit: true).future);
  if (shows.isEmpty) return const [];

  final eventIds = shows
      .expand((final s) => s.eventsId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();
  if (eventIds.isEmpty) return const [];

  final events = await ref.watch(eventsByIdsProvider(eventIds).future);
  if (events.isEmpty) return const [];

  final stageIds = events
      .map((final e) => e.stageId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();
  final stages = await ref.watch(stagesByIdsProvider(stageIds).future);

  final showMap = {for (final s in shows) s.id: s};
  final stageMap = {for (final s in stages) s.id: s};
  final now = DateTime.now();

  final list = events
      .map((final e) {
        final show = showMap[e.showId];
        if (show == null) return null;
        return DiscoverEvent(event: e, show: show, stage: stageMap[e.stageId]);
      })
      .whereType<DiscoverEvent>()
      .where((final de) {
        final date = DateFormatter.parseDateString(de.event.date);
        // Tarih parse edilemiyorsa listeden düşürmek yerine göstermeyi tercih ediyoruz.
        return date == null || date.isAfter(now);
      })
      .toList();

  list.sort((final a, final b) {
    final da = DateFormatter.parseDateString(a.event.date) ?? DateTime(9999);
    final db = DateFormatter.parseDateString(b.event.date) ?? DateTime(9999);
    return da.compareTo(db);
  });

  return list;
});

/// En çok yaklaşan etkinliğe sahip sahneler önce gelecek şekilde
/// sıralanmış popüler sahneler listesi.
final popularStagesProvider =
    FutureProvider.autoDispose<List<Stage>>((final ref) async {
  final events = await ref.watch(upcomingEventsProvider.future);

  final counts = <String, int>{};
  final stageMap = <String, Stage>{};
  for (final de in events) {
    final stage = de.stage;
    if (stage == null) continue;
    counts[stage.id] = (counts[stage.id] ?? 0) + 1;
    stageMap[stage.id] = stage;
  }

  final stages = stageMap.values.toList()
    ..sort((final a, final b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
  return stages;
});

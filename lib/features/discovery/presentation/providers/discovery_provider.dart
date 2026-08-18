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
import '../../../users/presentation/providers/user_provider.dart';

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

  /// Koltuk haritasında en az bir 'available' (veya durumu hiç
  /// belirtilmemiş, ki bu da varsayılan olarak müsait sayılır) koltuk
  /// varsa true. Koltuk haritası boşsa (henüz oluşturulmamış) "belki
  /// müsaittir" diyip göstermeyi tercih ediyoruz — sadece KESİN dolu
  /// olduğunu bildiğimiz etkinlikleri eliyoruz.
  bool get hasAvailableSeats {
    if (event.seats.isEmpty) return true;
    return event.seats.values.any((final raw) {
      if (raw is! Map) return true;
      final status = raw['status'] as String?;
      return status == null || status == 'available';
    });
  }
}

/// Tüm gösterilerin yaklaşan (bugünden sonraki) VE bileti hâlâ satılabilir
/// olan etkinliklerini, Show ve Stage bilgisiyle birlikte, en yakın
/// tarihten en uzağa sıralı getirir. Etkinliği bitmiş, koltuk haritası
/// kesin dolu olan veya tarihi/etkinliği olmayan gösteriler bu listede
/// (dolayısıyla Home/Discover/Nearby'de) hiç görünmez.
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
        final isUpcoming = date == null || date.isAfter(now);
        return isUpcoming && de.hasAvailableSeats;
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

/// Cihazın anlık konumunu okur (izin akışı dahil). Konum kapalıysa/izin
/// yoksa/alınamıyorsa `null` döner — bu bir hata değil, "şehre göre öner"
/// moduna geçme sinyalidir.
final currentPositionProvider =
    FutureProvider.autoDispose<Position?>((final ref) async {
  return LocationService.getCurrentPosition();
});

/// Yaklaşan etkinlikleri KONUMA göre (varsa) sahneye olan mesafeye göre
/// yakından uzağa; konum yoksa/alınamıyorsa kullanıcının profilindeki
/// şehre göre (aynı şehirdekiler önce) sıralar. İkisi de yoksa tarihe
/// göre sıralı kalır (upcomingEventsProvider zaten öyle döner).
final nearbySortedEventsProvider =
    FutureProvider.autoDispose<List<DiscoverEvent>>((final ref) async {
  final events = await ref.watch(upcomingEventsProvider.future);
  if (events.isEmpty) return events;

  final position = await ref.watch(currentPositionProvider.future);

  if (position != null) {
    final withDistance = events.map((final de) {
      final stage = de.stage;
      final distance = (stage != null &&
              stage.locationLat != 0 &&
              stage.locationLng != 0)
          ? LocationService.distanceInMeters(
              position.latitude,
              position.longitude,
              stage.locationLat,
              stage.locationLng,
            )
          : double.infinity;
      return (de, distance);
    }).toList();

    withDistance.sort((final a, final b) => a.$2.compareTo(b.$2));
    return withDistance.map((final e) => e.$1).toList();
  }

  // Konum yoksa: kullanıcının kayıtlı şehrine göre öncelik ver.
  final user = await ref.watch(userProfileProvider.future);
  final city = user?.city.trim().toLowerCase();
  if (city == null || city.isEmpty) return events;

  final inCity = <DiscoverEvent>[];
  final rest = <DiscoverEvent>[];
  for (final de in events) {
    final address = de.stage?.address.toLowerCase() ?? '';
    if (address.contains(city)) {
      inCity.add(de);
    } else {
      rest.add(de);
    }
  }
  return [...inCity, ...rest];
});

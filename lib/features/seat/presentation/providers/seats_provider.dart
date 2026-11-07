import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/seat_repository_provider.dart';
import '../../domain/entities/seat_plan_meta.dart';
import '../../domain/usecases/get_seat_plan_meta_use_case_impl.dart';
import '../../domain/usecases/get_seats_by_stage_use_case_impl.dart';

part 'seats_provider.g.dart';

@riverpod
GetSeatsByStageUseCase getSeatsByStageUseCase(final Ref ref) =>
    GetSeatsByStageUseCaseImpl(ref.watch(seatRepositoryProvider));

/// 🎯 SAHNE DÜZENİ (Layout)
@riverpod
Future<Map<String, List<String>>> stageLayout(
    final Ref ref, final String stageId) async {
  if (stageId.isEmpty) return {};
  return ref.watch(getSeatsByStageUseCaseProvider).call(stageId).getOrThrow();
}

// `seats_provider.g.dart` zaten üretilmiş olduğundan (build_runner bu
// sandbox'ta çalışmıyor — bkz. CLAUDE.md) bu dosyaya yeni bir `@riverpod`
// provider EKLENEMEZ; `eventsByShowIdsProvider` (show_provider.dart) ile
// aynı şekilde klasik `Provider`/`FutureProvider.family` kullanılıyor.
final _getSeatPlanMetaUseCaseProvider = Provider<GetSeatPlanMetaUseCase>(
    (final ref) => GetSeatPlanMetaUseCaseImpl(ref.watch(seatRepositoryProvider)));

/// 🎯 SAHNE KOLTUK PLANI META VERİSİ — hangi sahneye ait, adresi, oluşturma/
/// güncelleme zamanı (bkz. `Seats/{stageId}` dökümanı). Koltuk durumunu
/// etkilemez; yalnızca admin/denetim ekranlarında gösterim içindir.
final seatPlanMetaProvider =
    FutureProvider.family<SeatPlanMeta, String>((final ref, final stageId) async {
  if (stageId.isEmpty) return SeatPlanMeta.empty;
  return ref.watch(_getSeatPlanMetaUseCaseProvider).call(stageId).getOrThrow();
});

/// 🎯 ETKİNLİK KOLTUK PAKETİ (Composite)
@riverpod
Future<EventSeatingState> eventSeating(
  final Ref ref, {
  required final String eventId,
  required final String showId,
}) async {
  // Paralel veri çekme
  final results = await Future.wait([
    ref.watch(showsByIdsProvider([showId]).future),
    ref.watch(eventsByIdsProvider([eventId]).future),
  ]);

  final shows = results[0] as List<Show>;
  final events = results[1] as List<Event>;

  if (events.isEmpty) throw Exception('Etkinlik bulunamadı');

  final event = events.first;
  // Stage Layout'u çek
  final layout = await ref.watch(stageLayoutProvider(event.stageId).future);

  return EventSeatingState(event: event, show: shows.first, layout: layout);
}

class EventSeatingState {
  final Event event;
  final Show show;
  final Map<String, List<String>> layout;

  const EventSeatingState(
      {required this.event, required this.show, required this.layout});
}

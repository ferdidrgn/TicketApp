import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart'; // getOrThrow extension
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/seat_repository_provider.dart';
import '../../domain/usecases/get_seats_by_stage_use_case_impl.dart';

part 'seats_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS
// ==============================================================================

@riverpod
GetSeatsByStageUseCase getSeatsByStageUseCase(final Ref ref) =>
    GetSeatsByStageUseCaseImpl(ref.watch(seatRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

/// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
/// Örn: Map<"A", ["A1", "A2"...]>
@riverpod
Future<Map<String, List<String>>> stageLayout(
    final Ref ref, final String stageId) async {
  if (stageId.isEmpty) return {};
  return ref.watch(getSeatsByStageUseCaseProvider).call(stageId).getOrThrow();
}

/// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
/// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.
@riverpod
Future<EventSeatingState> eventSeating(
  final Ref ref, {
  required final String eventId,
  required final String showId,
}) async {
  // 1. Show ve Event verilerini çek
  final showFuture = ref.watch(showsByIdsProvider([showId]).future);
  // Event verisini listelerden bulalım (veya eventsByIdsProvider varsa onu kullan)
  final events = await ref.watch(eventsByIdsProvider([eventId]).future);

  if (events.isEmpty) throw Exception('Etkinlik bulunamadı');
  final event = events.first;
  final shows = await showFuture;
  final show = shows.first;

  // 2. Stage Layout'u çek (Event içindeki stageId'yi kullanarak)
  final layout = await ref.watch(stageLayoutProvider(event.stageId).future);

  return EventSeatingState(
    event: event,
    show: show,
    layout: layout,
  );
}

/// UI Paketi
class EventSeatingState {
  final Event event;
  final Show show;
  final Map<String, List<String>> layout;

  const EventSeatingState({
    required this.event,
    required this.show,
    required this.layout,
  });
}

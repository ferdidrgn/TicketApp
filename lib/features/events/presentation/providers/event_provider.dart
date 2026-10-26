import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/get_events_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_seat_status_by_event_use_case_impl.dart';

part 'event_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS
// ==============================================================================

@riverpod
GetEventsByIdsUseCase getEventsByIdsUseCase(final Ref ref) =>
    GetEventsByIdsUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
GetEventSeatStatusStreamUseCase getEventSeatStatusStreamUseCase(
        final Ref ref) =>
    GetEventSeatStatusStreamUseCaseImpl(ref.watch(eventRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
/// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
/// MyTicketProvider'ın beklediği provider budur.
@riverpod
Future<List<Event>> eventsByIds(final Ref ref, final List<String> ids) async {
  if (ids.isEmpty) return [];
  final result = await ref.watch(getEventsByIdsUseCaseProvider).call(ids);
  return result.getOrThrow();
}

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.
@riverpod
Stream<Map<String, Map<String, dynamic>>> eventSeats(
        final Ref ref, final String eventId) =>
    ref.watch(getEventSeatStatusStreamUseCaseProvider).call(eventId).map(
        (final eventData) => eventData.cast<String, Map<String, dynamic>>());

/// 🎯 ETKİNLİK DETAYI
@riverpod
Future<Event> eventDetail(final Ref ref, final String eventId) async {
  final result = await ref.watch(getEventsByIdsUseCaseProvider).call([eventId]);
  final list = await result.getOrThrow();
  return list.first;
}

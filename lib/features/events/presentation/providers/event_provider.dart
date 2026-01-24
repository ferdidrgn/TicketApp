import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/attempt_reservation_use_case_impl.dart';
import '../../domain/usecases/confirm_purchase_case_impl.dart';
import '../../domain/usecases/get_events_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_seat_status_by_event_use_case_impl.dart';
import '../../domain/usecases/release_reservation_use_case_impl.dart';

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

@riverpod
AttemptReservationUseCase attemptReservationUseCase(final Ref ref) =>
    AttemptReservationUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
ReleaseReservationUseCase releaseReservationUseCase(final Ref ref) =>
    ReleaseReservationUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
ConfirmPurchaseUseCase confirmPurchaseUseCase(final Ref ref) =>
    ConfirmPurchaseUseCaseImpl(ref.watch(eventRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
@riverpod
Stream<Map<String, Map<String, dynamic>>> eventSeats(
        final Ref ref, final String eventId) =>
    ref.watch(getEventSeatStatusStreamUseCaseProvider).call(eventId).map(
        (final eventData) => eventData.cast<String, Map<String, dynamic>>());

/// 🎯 ETKİNLİK DETAYI
@riverpod
Future<Event> eventDetail(final Ref ref, final String eventId) async {
  final list = await ref
      .watch(getEventsByIdsUseCaseProvider)
      .call([eventId]).getOrThrow();
  return list.first;
}

/// 🎯 GERİ SAYIM (Timer)
@riverpod
Stream<int> reservationTimer(final Ref ref) =>
    Stream.periodic(const Duration(seconds: 1), (final i) => 600 - i).take(601);

// ==============================================================================
// 3. ACTION PROVIDERS (Side Effects)
// ==============================================================================

@riverpod
Future<bool> toggleSeatSelection(
  final Ref ref, {
  required final String eventId,
  required final String seatId,
  required final String customerId,
  required final bool isAdding,
}) async {
  if (isAdding)
    return ref
        .read(attemptReservationUseCaseProvider)
        .call(eventId, seatId, customerId)
        .getOrThrow();
  else
    return ref
        .read(releaseReservationUseCaseProvider)
        .call(eventId, seatId, customerId)
        .getOrThrow();
}

@riverpod
Future<void> purchaseAction(
  final Ref ref, {
  required final String eventId,
  required final String showId,
  required final String stageId,
  required final List<String> seatIds,
  required final String customerId,
  required final String paymentMethod,
  required final double totalPrice,
}) async {
  // 1. Koltukları onayla
  await ref
      .read(confirmPurchaseUseCaseProvider)
      .call(eventId, seatIds, customerId)
      .getOrThrow();

  // 2. Ticket nesnesi
  final ticket = Ticket(
    id: '',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    showId: showId,
    customerId: customerId,
    stageId: stageId,
    eventId: eventId,
    orderPrice: totalPrice.toStringAsFixed(2),
    orderMethod: paymentMethod,
    buySeats: seatIds,
    isPast: false,
  );

  // 3. Bileti kaydet
  await ref.read(createTicketUseCaseProvider).call(ticket).getOrThrow();
}

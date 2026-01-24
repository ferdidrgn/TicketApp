import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart'; // getOrThrow extension için
import '../../../tickets/domain/entities/ticket.dart'; // Ticket entity için
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/attempt_reservation_use_case_impl.dart';
import '../../domain/usecases/confirm_purchase_case_impl.dart';
import '../../domain/usecases/get_events_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_seat_status_by_event_use_case_impl.dart';
import '../../domain/usecases/release_reservation_use_case_impl.dart';

part 'event_providers.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS (Dependency Injection)
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
// 2. DATA PROVIDERS (Read Operations - AsyncValue)
// ==============================================================================

/// 🎯 KOLTUK DURUMU (Real-time Stream)
@riverpod
Stream<Map<String, Map<String, dynamic>>> eventSeats(
        final Ref ref, final String eventId) =>
    ref.watch(getEventSeatStatusStreamUseCaseProvider).call(eventId);

/// 🎯 ETKİNLİK DETAYI
@riverpod
Future<Event> eventDetail(final Ref ref, final String eventId) async {
  final result = await ref.watch(getEventsByIdsUseCaseProvider).call([eventId]);
  return result.getOrThrow().first;
}

/// 🎯 GERİ SAYIM (Timer) - 10 Dakika (600 Saniye)
@riverpod
Stream<int> reservationTimer(final Ref ref) =>
    Stream.periodic(const Duration(seconds: 1), (final i) => 600 - i).take(601);

// ==============================================================================
// 3. ACTION PROVIDERS (Side Effects / Mutations)
// ==============================================================================

/// ⚡ KOLTUK SEÇME / BIRAKMA (Rezervasyon İşlemi)
@riverpod
Future<bool> toggleSeatSelection(
  final Ref ref, {
  required final String eventId,
  required final String seatId,
  required final String customerId,
  required final bool isAdding,
}) async {
  if (isAdding) {
    final result = await ref
        .read(attemptReservationUseCaseProvider)
        .call(eventId, seatId, customerId);
    return result.getOrThrow();
  } else {
    final result = await ref
        .read(releaseReservationUseCaseProvider)
        .call(eventId, seatId, customerId);
    return result.getOrThrow();
  }
}

/// ⚡ SATIN ALMA VE BİLET OLUŞTURMA SÜRECİ
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
  // 1. Koltukları Firestore'da 'sold' (satıldı) yap
  final confirmResult = await ref
      .read(confirmPurchaseUseCaseProvider)
      .call(eventId, seatIds, customerId);
  confirmResult.getOrThrow();

  // 2. Bilet bilgilerini hazırla
  final now = DateTime.now();
  String finalPrice = totalPrice.toStringAsFixed(2);
  String finalMethod = paymentMethod;

  if (paymentMethod == 'free_ticket')
    finalPrice = "0.0";
  else if (paymentMethod.startsWith('coffee_')) {
    finalPrice =
        paymentMethod.split('_').last.replaceAll(RegExp(r'[^0-9.]'), '');
    if (finalPrice.isEmpty) finalPrice = "20.0";
    finalMethod = 'coffee_donation';
  }

  final ticket = Ticket(
    id: '',
    updatedAt: DateTime.now().toIso8601String(),
    showId: showId,
    customerId: customerId,
    stageId: stageId,
    eventId: eventId,
    orderPrice: totalPrice.toStringAsFixed(2),
    orderMethod: paymentMethod,
    buySeats: seatIds,
    createdAt: DateTime.now().toIso8601String(),
    isPast: false,
  );
  // 3. Bileti veritabanına kaydet
  await ref.read(createTicketUseCaseProvider).call(ticket).getOrThrow();
}

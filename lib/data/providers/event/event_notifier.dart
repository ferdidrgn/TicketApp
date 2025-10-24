import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'event_provider.dart';
import 'event_state.dart';

class EventNotifier extends BaseNotifierWithNetworkChecker<EventState> {
  @override
  EventState initialState() => EventState();

  @override
  void reloadData() {
    // Örn: bir eventId verilmediği için default reloadData boş bırakılıyor.
    // UI'de belirli eventId ile çağırmak daha mantıklı
  }

  // Event Price
  Future<void> loadEventPrice(final String eventId) => executeWithInternetCheck(
        () => ref.read(getEventPriceUseCaseProvider).call(eventId),
        onSuccess: (final price) => state = state.copyWith(price: price),
      );

  // Event Date
  Future<void> loadEventDate(final String eventId,
          {final bool formatWithMonthName = false}) =>
      executeWithInternetCheck(
        () => ref
            .read(getEventDateUseCaseProvider)
            .call(eventId, formatWithMonthName: formatWithMonthName),
        onSuccess: (final date) => state = state.copyWith(date: date),
      );

  // Stage ID
  Future<void> loadStageId(final String eventId) => executeWithInternetCheck(
        () => ref.read(getStageIdUseCaseProvider).call(eventId),
        onSuccess: (final stageId) => state = state.copyWith(stageId: stageId),
      );

  // Seat Status
  Future<void> loadSeatStatusByEvent(final String eventId) =>
      executeWithInternetCheck(
        () => ref.read(getSeatStatusByEventUseCaseProvider).call(eventId),
        onSuccess: (final seatStatus) =>
            state = state.copyWith(seatStatus: seatStatus ?? {}),
      );

  // Purchased Seats
  Future<void> loadPurchasedSeatsByCustomerId(
          final String eventId, final String customerId) =>
      executeWithInternetCheck(
        () => ref
            .read(getPurchasedSeatsByCustomerIdUseCaseProvider)
            .call(eventId, customerId),
        onSuccess: (final seats) => state =
            state.copyWith(purchasedSeats: List<String>.from(seats ?? [])),
      );

  // Initialize & Get Seats
  Future<void> initializeAndGetEventSeats(final String eventId) =>
      executeWithInternetCheck(
        () => ref.read(initializeAndGetEventSeatsUseCaseProvider).call(eventId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  // Update Seat Status
  Future<void> updateSeatStatus(
          final String eventId, final String seatId, final String status,
          {final String? customerId}) =>
      executeWithInternetCheck(
        () => ref
            .read(updateSeatStatusUseCaseProvider)
            .call(eventId, seatId, status, customerId: customerId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  // Reserve Seat
  Future<void> reserveSeat(
          final String eventId, final String seatId, final String customerId) =>
      executeWithInternetCheck(
        () => ref
            .read(reserveSeatUseCaseProvider)
            .call(eventId, seatId, customerId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  // Cancel Reservation
  Future<void> cancelReservation(final String eventId, final String seatId) =>
      executeWithInternetCheck(
        () => ref.read(cancelReservationUseCaseProvider).call(eventId, seatId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );
}

/// EventState için helper extension
extension EventStateX on EventState {
  bool get hasSeats => seatStatus != null && seatStatus!.isNotEmpty;

  bool get hasPurchasedSeats =>
      purchasedSeats != null && purchasedSeats!.isNotEmpty;

  bool hasPurchasedSeat(final String seatId) =>
      purchasedSeats?.contains(seatId) ?? false;

  int get seatCount => seatStatus?.length ?? 0;

  int get purchasedSeatCount => purchasedSeats?.length ?? 0;

  dynamic getSeatStatusById(final String seatId) => seatStatus?[seatId];
}

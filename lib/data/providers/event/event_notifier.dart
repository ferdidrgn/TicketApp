import 'package:ticketapp/core/common/base_notifier_with_base_state.dart';
import '../../../domain/useCase/event/cancel_reservation_use_case_impl.dart';
import '../../../domain/useCase/event/get_event_date_use_case_impl.dart';
import '../../../domain/useCase/event/get_event_price_use_case_impl.dart';
import '../../../domain/useCase/event/get_purchased_seats_by_customer_id_use_case_impl.dart';
import '../../../domain/useCase/event/get_seat_status_by_event_use_case_impl.dart';
import '../../../domain/useCase/event/get_stage_id_use_case_impl.dart';
import '../../../domain/useCase/event/initialize_and_get_event_seats_use_case_impl.dart';
import '../../../domain/useCase/event/reserve_seat_use_case_impl.dart';
import '../../../domain/useCase/event/update_seat_status_use_case_impl.dart';
import 'event_state.dart';

class EventNotifier extends BaseNotifierWithBaseState<EventState> {
  final GetEventPriceUseCase getEventPriceUseCase;
  final GetEventDateUseCase getEventDateUseCase;
  final GetStageIdUseCase getStageIdUseCase;
  final GetSeatStatusByEventUseCase getSeatStatusByEventUseCase;
  final GetPurchasedSeatsByCustomerIdUseCase
      getPurchasedSeatsByCustomerIdUseCase;
  final InitializeAndGetEventSeatsUseCase initializeAndGetEventSeatsUseCase;
  final UpdateSeatStatusUseCase updateSeatStatusUseCase;
  final ReserveSeatUseCase reserveSeatUseCase;
  final CancelReservationUseCase cancelReservationUseCase;

  EventNotifier(
    this.getEventPriceUseCase,
    this.getEventDateUseCase,
    this.getStageIdUseCase,
    this.getSeatStatusByEventUseCase,
    this.getPurchasedSeatsByCustomerIdUseCase,
    this.initializeAndGetEventSeatsUseCase,
    this.updateSeatStatusUseCase,
    this.reserveSeatUseCase,
    this.cancelReservationUseCase,
  ) : super(EventState());

  Future<void> loadEventPrice(final String eventId) async {
    await handleOperation(
      () => getEventPriceUseCase.call(eventId),
      onSuccess: (final price) => state = state.copyWith(price: price),
    );
  }

  Future<void> loadEventDate(final String eventId,
      {final bool formatWithMonthName = false}) async {
    await handleOperation(
      () => getEventDateUseCase.call(eventId,
          formatWithMonthName: formatWithMonthName),
      onSuccess: (final date) => state = state.copyWith(date: date),
    );
  }

  Future<void> loadStageId(final String eventId) async {
    await handleOperation(
      () => getStageIdUseCase.call(eventId),
      onSuccess: (final stageId) => state = state.copyWith(stageId: stageId),
    );
  }

  Future<void> loadSeatStatusByEvent(final String eventId) async {
    await handleOperation(
      () => getSeatStatusByEventUseCase.call(eventId),
      onSuccess: (final seatStatus) =>
          state = state.copyWith(seatStatus: seatStatus ?? {}),
    );
  }

  Future<void> loadPurchasedSeatsByCustomerId(
      final String eventId, final String customerId) async {
    await handleOperation(
        () => getPurchasedSeatsByCustomerIdUseCase.call(eventId, customerId),
        onSuccess: (final seats) => state =
            state.copyWith(purchasedSeats: List<String>.from(seats ?? [])));
  }

  Future<void> initializeAndGetEventSeats(final String eventId) async {
    await handleOperation(
      () => initializeAndGetEventSeatsUseCase.call(eventId),
      onSuccess: (final _) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> updateSeatStatus(
      final String eventId, final String seatId, final String status,
      {final String? customerId}) async {
    await handleOperation(
      () => updateSeatStatusUseCase.call(eventId, seatId, status,
          customerId: customerId),
      onSuccess: (final _) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> reserveSeat(final String eventId, final String seatId,
      final String customerId) async {
    await handleOperation(
      () => reserveSeatUseCase.call(eventId, seatId, customerId),
      onSuccess: (final _) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> cancelReservation(
      final String eventId, final String seatId) async {
    await handleOperation(
      () => cancelReservationUseCase.call(eventId, seatId),
      onSuccess: (final _) => state = state.copyWith(isLoading: false),
    );
  }
}

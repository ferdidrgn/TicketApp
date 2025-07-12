import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
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

class EventNotifier extends BaseNotifierWithNetworkChecker<EventState> {
  final GetEventPriceUseCase _getEventPriceUseCase;
  final GetEventDateUseCase _getEventDateUseCase;
  final GetStageIdUseCase _getStageIdUseCase;
  final GetSeatStatusByEventUseCase _getSeatStatusByEventUseCase;
  final GetPurchasedSeatsByCustomerIdUseCase
      _getPurchasedSeatsByCustomerIdUseCase;
  final InitializeAndGetEventSeatsUseCase _initializeAndGetEventSeatsUseCase;
  final UpdateSeatStatusUseCase _updateSeatStatusUseCase;
  final ReserveSeatUseCase _reserveSeatUseCase;
  final CancelReservationUseCase _cancelReservationUseCase;

  EventNotifier(
    final InternetService internetService,
    this._getEventPriceUseCase,
    this._getEventDateUseCase,
    this._getStageIdUseCase,
    this._getSeatStatusByEventUseCase,
    this._getPurchasedSeatsByCustomerIdUseCase,
    this._initializeAndGetEventSeatsUseCase,
    this._updateSeatStatusUseCase,
    this._reserveSeatUseCase,
    this._cancelReservationUseCase,
  ) : super(internetService, EventState());

  @override
  void reloadData() {}

  Future<void> loadEventPrice(final String eventId) => executeWithInternetCheck(
        () => _getEventPriceUseCase.call(eventId),
        onSuccess: (final price) => state = state.copyWith(price: price),
      );

  Future<void> loadEventDate(final String eventId,
          {final bool formatWithMonthName = false}) =>
      executeWithInternetCheck(
        () => _getEventDateUseCase.call(eventId,
            formatWithMonthName: formatWithMonthName),
        onSuccess: (final date) => state = state.copyWith(date: date),
      );

  Future<void> loadStageId(final String eventId) => executeWithInternetCheck(
        () => _getStageIdUseCase.call(eventId),
        onSuccess: (final stageId) => state = state.copyWith(stageId: stageId),
      );

  Future<void> loadSeatStatusByEvent(final String eventId) =>
      executeWithInternetCheck(
        () => _getSeatStatusByEventUseCase.call(eventId),
        onSuccess: (final seatStatus) =>
            state = state.copyWith(seatStatus: seatStatus ?? {}),
      );

  Future<void> loadPurchasedSeatsByCustomerId(
          final String eventId, final String customerId) =>
      executeWithInternetCheck(
        () => _getPurchasedSeatsByCustomerIdUseCase.call(eventId, customerId),
        onSuccess: (final seats) => state =
            state.copyWith(purchasedSeats: List<String>.from(seats ?? [])),
      );

  Future<void> initializeAndGetEventSeats(final String eventId) =>
      executeWithInternetCheck(
        () => _initializeAndGetEventSeatsUseCase.call(eventId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  Future<void> updateSeatStatus(
          final String eventId, final String seatId, final String status,
          {final String? customerId}) =>
      executeWithInternetCheck(
        () => _updateSeatStatusUseCase.call(eventId, seatId, status,
            customerId: customerId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  Future<void> reserveSeat(
          final String eventId, final String seatId, final String customerId) =>
      executeWithInternetCheck(
        () => _reserveSeatUseCase.call(eventId, seatId, customerId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );

  Future<void> cancelReservation(final String eventId, final String seatId) =>
      executeWithInternetCheck(
        () => _cancelReservationUseCase.call(eventId, seatId),
        onSuccess: (final _) => state = state.copyWith(isLoading: false),
      );
}

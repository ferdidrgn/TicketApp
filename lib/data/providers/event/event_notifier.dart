import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class EventNotifier extends StateNotifier<EventState> {
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

  Future<void> loadEventPrice(final String? eventId) async {
    _setLoadingState(true);
    final result = await getEventPriceUseCase.call(eventId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final price) => _setEventPrice(price),
    );
  }

  Future<void> loadEventDate(final String? eventId,
      {final bool formatWithMonthName = false}) async {
    _setLoadingState(true);
    final result = await getEventDateUseCase.call(eventId,
        formatWithMonthName: formatWithMonthName);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final date) => _setEventDate(date),
    );
  }

  Future<void> loadStageId(final String? eventId) async {
    _setLoadingState(true);
    final result = await getStageIdUseCase.call(eventId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final stageId) => _setStageId(stageId),
    );
  }

  Future<void> loadSeatStatusByEvent(final String? eventId) async {
    _setLoadingState(true);
    final result = await getSeatStatusByEventUseCase.call(eventId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final seatStatus) => _setSeatStatus(seatStatus),
    );
  }

  Future<void> loadPurchasedSeatsByCustomerId(
      final String? eventId, final String? customerId) async {
    _setLoadingState(true);
    final result =
        await getPurchasedSeatsByCustomerIdUseCase.call(eventId, customerId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final seats) => _setPurchasedSeats(seats),
    );
  }

  Future<void> initializeAndGetEventSeats(final String? eventId) async {
    _setLoadingState(true);
    final result = await initializeAndGetEventSeatsUseCase.call(eventId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> updateSeatStatus(
      final String? eventId, final String? seatId, final String? status,
      {final String? customerId}) async {
    _setLoadingState(true);
    final result = await updateSeatStatusUseCase.call(eventId, seatId, status,
        customerId: customerId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> reserveSeat(final String? eventId, final String? seatId,
      final String? customerId) async {
    _setLoadingState(true);
    final result = await reserveSeatUseCase.call(eventId, seatId, customerId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> cancelReservation(
      final String? eventId, final String? seatId) async {
    _setLoadingState(true);
    final result = await cancelReservationUseCase.call(eventId, seatId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setSuccessState() {
    state = state.copyWith(isLoading: false);
  }

  void _setEventPrice(final String? price) {
    state = state.copyWith(price: price, isLoading: false);
  }

  void _setEventDate(final Map<String, String>? date) {
    state = state.copyWith(date: date, isLoading: false);
  }

  void _setStageId(final String? stageId) {
    state = state.copyWith(stageId: stageId, isLoading: false);
  }

  void _setSeatStatus(final Map<String, Map<String, dynamic>> seatStatus) {
    state = state.copyWith(seatStatus: seatStatus, isLoading: false);
  }

  void _setPurchasedSeats(final List<String?> seats) {
    state = state.copyWith(purchasedSeats: seats, isLoading: false);
  }
}

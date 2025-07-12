import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/event/cancel_reservation_use_case_impl.dart';
import '../../../domain/useCase/event/get_event_date_use_case_impl.dart';
import '../../../domain/useCase/event/get_event_price_use_case_impl.dart';
import '../../../domain/useCase/event/get_purchased_seats_by_customer_id_use_case_impl.dart';
import '../../../domain/useCase/event/get_seat_status_by_event_use_case_impl.dart';
import '../../../domain/useCase/event/get_stage_id_use_case_impl.dart';
import '../../../domain/useCase/event/initialize_and_get_event_seats_use_case_impl.dart';
import '../../../domain/useCase/event/reserve_seat_use_case_impl.dart';
import '../../../domain/useCase/event/update_seat_status_use_case_impl.dart';
import '../../repository/event/event_repository_provider.dart';
import 'event_notifier.dart';
import 'event_state.dart';

final eventProvider =
    StateNotifierProvider<EventNotifier, EventState>((final ref) {
  return EventNotifier(
    ref.read(internetServiceProvider),
    ref.watch(getEventPriceUseCaseProvider),
    ref.watch(getEventDateUseCaseProvider),
    ref.watch(getStageIdUseCaseProvider),
    ref.watch(getSeatStatusByEventUseCaseProvider),
    ref.watch(getPurchasedSeatsByCustomerIdUseCaseProvider),
    ref.watch(initializeAndGetEventSeatsUseCaseProvider),
    ref.watch(updateSeatStatusUseCaseProvider),
    ref.watch(reserveSeatUseCaseProvider),
    ref.watch(cancelReservationUseCaseProvider),
  );
});

// Use case providers
final getEventPriceUseCaseProvider =
    Provider<GetEventPriceUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventPriceUseCaseImpl(repository);
});

final getEventDateUseCaseProvider = Provider<GetEventDateUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventDateUseCaseImpl(repository);
});

final getStageIdUseCaseProvider = Provider<GetStageIdUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetStageIdUseCaseImpl(repository);
});

final getSeatStatusByEventUseCaseProvider =
    Provider<GetSeatStatusByEventUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetSeatStatusByEventUseCaseImpl(repository);
});

final getPurchasedSeatsByCustomerIdUseCaseProvider =
    Provider<GetPurchasedSeatsByCustomerIdUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetPurchasedSeatsByCustomerIdUseCaseImpl(repository);
});

final initializeAndGetEventSeatsUseCaseProvider =
    Provider<InitializeAndGetEventSeatsUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return InitializeAndGetEventSeatsUseCaseImpl(repository);
});

final updateSeatStatusUseCaseProvider =
    Provider<UpdateSeatStatusUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return UpdateSeatStatusUseCaseImpl(repository);
});

final reserveSeatUseCaseProvider = Provider<ReserveSeatUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return ReserveSeatUseCaseImpl(repository);
});

final cancelReservationUseCaseProvider =
    Provider<CancelReservationUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return CancelReservationUseCaseImpl(repository);
});

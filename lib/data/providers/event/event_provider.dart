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
import '../../repository/event/event_repository_provider.dart';
import 'event_notifier.dart';
import 'event_state.dart';

final eventProvider = NotifierProvider<EventNotifier, EventState>(
  EventNotifier.new,
);

// Use case providers
final getEventPriceUseCaseProvider = Provider<GetEventPriceUseCase>(
  (final ref) => GetEventPriceUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getEventDateUseCaseProvider = Provider<GetEventDateUseCase>(
  (final ref) => GetEventDateUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getStageIdUseCaseProvider = Provider<GetStageIdUseCase>(
  (final ref) => GetStageIdUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getSeatStatusByEventUseCaseProvider =
    Provider<GetSeatStatusByEventUseCase>(
  (final ref) =>
      GetSeatStatusByEventUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getPurchasedSeatsByCustomerIdUseCaseProvider =
    Provider<GetPurchasedSeatsByCustomerIdUseCase>(
  (final ref) => GetPurchasedSeatsByCustomerIdUseCaseImpl(
      ref.watch(eventRepositoryProvider)),
);

final initializeAndGetEventSeatsUseCaseProvider =
    Provider<InitializeAndGetEventSeatsUseCase>(
  (final ref) =>
      InitializeAndGetEventSeatsUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final updateSeatStatusUseCaseProvider = Provider<UpdateSeatStatusUseCase>(
  (final ref) =>
      UpdateSeatStatusUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final reserveSeatUseCaseProvider = Provider<ReserveSeatUseCase>(
  (final ref) => ReserveSeatUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final cancelReservationUseCaseProvider = Provider<CancelReservationUseCase>(
  (final ref) =>
      CancelReservationUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

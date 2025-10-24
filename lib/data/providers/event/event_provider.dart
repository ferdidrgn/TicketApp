import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/event/attempt_reservation_use_case_impl.dart';
import '../../../domain/useCase/event/confirm_purchase_case_impl.dart';
import '../../../domain/useCase/event/get_event_date_use_case_impl.dart';
import '../../../domain/useCase/event/get_seat_status_by_event_use_case_impl.dart';
import '../../../domain/useCase/event/initialize_and_get_event_seats_use_case_impl.dart';
import '../../../domain/useCase/event/release_reservation_use_case_impl.dart';
import '../../repository/event/event_repository_provider.dart';
import 'event_notifier.dart';
import 'event_state.dart';

final eventNotifierProvider =
    NotifierProvider.autoDispose<EventNotifier, SeatSelectionState>(
  EventNotifier.new,
);

// Use case providers
final initializeAndGetEventSeatsUseCaseProvider =
    Provider<InitializeAndGetEventSeatsUseCase>(
  (final ref) =>
      InitializeAndGetEventSeatsUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getEventDateUseCaseProvider = Provider<GetEventDateUseCase>(
  (final ref) => GetEventDateUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getEventSeatStatusStreamUseCaseProvider =
    Provider<GetEventSeatStatusStreamUseCase>(
  (final ref) =>
      GetEventSeatStatusStreamUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final confirmPurchaseUseCaseUseCaseProvider = Provider<ConfirmPurchaseUseCase>(
  (final ref) => ConfirmPurchaseUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final releaseReservationUseCaseProvider = Provider<ReleaseReservationUseCase>(
  (final ref) =>
      ReleaseReservationUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final attemptReservationUseCaseProvider = Provider<AttemptReservationUseCase>(
  (final ref) =>
      AttemptReservationUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

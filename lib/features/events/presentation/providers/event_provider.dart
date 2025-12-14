import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/events/domain/usecases/get_events_by_ids_use_case_impl.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/usecases/attempt_reservation_use_case_impl.dart';
import '../../domain/usecases/confirm_purchase_case_impl.dart';
import '../../domain/usecases/get_seat_status_by_event_use_case_impl.dart';
import '../../domain/usecases/initialize_and_get_event_seats_use_case_impl.dart';
import '../../domain/usecases/release_reservation_use_case_impl.dart';
import 'event_notifier.dart';
import 'event_state.dart';

final eventProvider =
    NotifierProvider.autoDispose<EventNotifier, EventState>(EventNotifier.new);

// Use case providers
final initializeAndGetEventSeatsUseCaseProvider =
    Provider<InitializeAndGetEventSeatsUseCase>(
  (final ref) =>
      InitializeAndGetEventSeatsUseCaseImpl(ref.watch(eventRepositoryProvider)),
);

final getEventsByIdsUseCaseProvider = Provider<GetEventsByIdsUseCase>(
  (final ref) => GetEventsByIdsUseCaseImpl(ref.watch(eventRepositoryProvider)),
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

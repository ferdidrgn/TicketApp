import '../repositories/event_repository.dart';

abstract class GetEventSeatStatusStreamUseCase {
  Stream<Map<String, Map<String, dynamic>?>> call(final String eventId);
}

class GetEventSeatStatusStreamUseCaseImpl
    implements GetEventSeatStatusStreamUseCase {
  final EventRepository repository;

  GetEventSeatStatusStreamUseCaseImpl(this.repository);

  @override
  Stream<Map<String, Map<String, dynamic>?>> call(final String eventId) =>
      repository.getEventSeatStatusStream(eventId);
}

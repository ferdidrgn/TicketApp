import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class AttemptReservationUseCase {
  Future<Either<Failure, bool>> call(
      final String eventId, final String seatId, final String customerId);
}

class AttemptReservationUseCaseImpl implements AttemptReservationUseCase {
  final EventRepository repository;

  AttemptReservationUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final String eventId, final String seatId, final String customerId) =>
      repository.attemptReservation(eventId, seatId, customerId);
}

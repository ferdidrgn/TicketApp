import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class ReleaseReservationUseCase {
  Future<Either<Failure, bool>> call(
      final String eventId, final String seatId, final String customerId);
}

class ReleaseReservationUseCaseImpl implements ReleaseReservationUseCase {
  final EventRepository repository;

  ReleaseReservationUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String eventId, final String seatId,
      final String customerId) async {
    return repository.releaseReservation(eventId, seatId, customerId);
  }
}

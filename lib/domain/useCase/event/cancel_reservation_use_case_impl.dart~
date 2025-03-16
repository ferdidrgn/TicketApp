import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class CancelReservationUseCase {
  Future<Either<Failure, void>> call(final String? eventId, final String? seatId);
}

class CancelReservationUseCaseImpl implements CancelReservationUseCase {
  final EventRepository repository;

  CancelReservationUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String? eventId, final String? seatId) async {
    return repository.cancelReservation(eventId, seatId);
  }
}

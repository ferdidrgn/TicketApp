import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class ReserveSeatUseCase {
  Future<Either<Failure, void>> call(final String eventId, final String seatId, final String customerId);
}

class ReserveSeatUseCaseImpl implements ReserveSeatUseCase {
  final EventRepository repository;

  ReserveSeatUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String eventId, final String seatId, final String customerId) async {
    return repository.reserveSeat(eventId, seatId, customerId);
  }
}

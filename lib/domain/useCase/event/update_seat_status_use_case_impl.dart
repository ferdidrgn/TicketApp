import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class UpdateSeatStatusUseCase {
  Future<Either<Failure, void>> call(final String? eventId, final String? seatId, final String? status, {final String? customerId});
}

class UpdateSeatStatusUseCaseImpl implements UpdateSeatStatusUseCase {
  final EventRepository repository;

  UpdateSeatStatusUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String? eventId, final String? seatId, final String? status, {final String? customerId}) async {
    return repository.updateSeatStatus(eventId, seatId, status, customerId: customerId);
  }
}
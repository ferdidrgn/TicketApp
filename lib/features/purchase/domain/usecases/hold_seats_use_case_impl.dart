import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/purchase_entities.dart';
import '../repositories/purchase_repository.dart';

abstract class HoldSeatsUseCase {
  Future<Either<Failure, SeatHold>> call(final String eventId, final List<String> seatIds);
}

class HoldSeatsUseCaseImpl implements HoldSeatsUseCase {
  final PurchaseRepository repository;

  HoldSeatsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, SeatHold>> call(final String eventId, final List<String> seatIds) =>
      repository.holdSeats(eventId, seatIds);
}

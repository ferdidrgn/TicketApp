import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/seat_plan_meta.dart';
import '../repositories/seat_repository.dart';

abstract class GetSeatPlanMetaUseCase {
  Future<Either<Failure, SeatPlanMeta>> call(final String stageId);
}

class GetSeatPlanMetaUseCaseImpl implements GetSeatPlanMetaUseCase {
  final SeatRepository seatRepository;

  GetSeatPlanMetaUseCaseImpl(this.seatRepository);

  @override
  Future<Either<Failure, SeatPlanMeta>> call(final String stageId) async =>
      seatRepository.getSeatPlanMeta(stageId);
}

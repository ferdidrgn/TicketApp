import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/seat_repository.dart';

abstract class GetSeatsByStageUseCase {
  Future<Either<Failure, Map<String, List<String>>>> call(final String stageId);
}

class GetSeatsByStageUseCaseImpl implements GetSeatsByStageUseCase {
  final SeatRepository seatRepository;

  GetSeatsByStageUseCaseImpl(this.seatRepository);

  @override
  Future<Either<Failure, Map<String, List<String>>>> call(
          final String stageId) async =>
      seatRepository.getSeatsByStage(stageId);
}

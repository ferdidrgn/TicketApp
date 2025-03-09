import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetSeatsByStageUseCase {
  Future<Either<Failure, Map<String, List<String?>>>> call(final String stageId);
}

class GetSeatsByStageUseCaseImpl implements GetSeatsByStageUseCase {
  final EventRepository repository;

  GetSeatsByStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, Map<String, List<String?>>>> call(
      final String stageId) async {
    return repository.getSeatsByStage(stageId);
  }
}

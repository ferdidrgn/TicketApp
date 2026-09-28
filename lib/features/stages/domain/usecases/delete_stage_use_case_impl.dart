import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/stage_repository.dart';

abstract class DeleteStageUseCase {
  Future<Either<Failure, bool>> call(final String stageId);
}

class DeleteStageUseCaseImpl implements DeleteStageUseCase {
  final StageRepository repository;

  DeleteStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String stageId) async =>
      repository.deleteStage(stageId);
}

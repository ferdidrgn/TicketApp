import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/stage.dart';
import '../repositories/stage_repository.dart';

abstract class GetSearchStageUseCase {
  Future<Either<Failure, List<Stage>>> call(final String query);
}

class GetSearchStageUseCaseImpl implements GetSearchStageUseCase {
  final StageRepository repository;

  GetSearchStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Stage>>> call(final String query) async =>
      repository.getSearchStage(query);
}

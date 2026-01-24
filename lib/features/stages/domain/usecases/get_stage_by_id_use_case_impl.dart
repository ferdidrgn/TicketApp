import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/stage.dart';
import '../repositories/stage_repository.dart';

abstract class GetStagesByIdsUseCase {
  Future<Either<Failure, List<Stage>>> call(final List<String> stagesIds);
}

class GetStageByIdUseCaseImpl implements GetStagesByIdsUseCase {
  final StageRepository repository;

  GetStageByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Stage>>> call(
          final List<String> stagesIds) async =>
      repository.getStagesByIds(stagesIds);
}

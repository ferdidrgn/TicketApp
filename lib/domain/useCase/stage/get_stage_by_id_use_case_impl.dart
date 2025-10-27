import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/stage.dart';
import '../../repository/stage_repository.dart';

abstract class GetStagesByIdsUseCase {
  Future<Either<Failure, List<Stage>>> call(final List<String> stagesIds);
}

class GetStageByIdUseCaseImpl implements GetStagesByIdsUseCase {
  final StageRepository repository;

  GetStageByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Stage>>> call(
      final List<String> stagesIds) async {
    final result = await repository.getStagesByIds(stagesIds);
    return result.fold(
        (final failure) => Left(failure),
        (final stagesModels) => Right(stagesModels
                ?.map((final stageModel) => stageModel?.toEntity())
                .whereType<Stage>()
                .toList() ??
            []));
  }
}

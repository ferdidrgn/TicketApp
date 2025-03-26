import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/stage.dart';
import '../../repository/stage_repository.dart';

abstract class GetStagesUseCase {
  Future<Either<Failure, List<Stage>>> call(isLimit);
}

class GetStagesUseCaseImpl implements GetStagesUseCase {
  StageRepository repository;

  GetStagesUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Stage>>> call(isLimit) async {
    final result = await repository.getStages(isLimit);
    return result.fold(
          (final failure) => Left(failure),
          (final stagesModels) {
        final stages = stagesModels
            ?.map((final stageModel) => stageModel?.toEntity())
            .whereType<Stage>()
            .toList() ??
            [];
        return Right(stages);
      },
    );
  }
}

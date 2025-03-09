import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/stage_model.dart';
import '../../repository/stage_repository.dart';

abstract class GetStageByIdUseCase {
  Future<Either<Failure, StageModel?>> call(final String stageId);
}

class GetStageByIdUseCaseImpl implements GetStageByIdUseCase {
  final StageRepository repository;

  GetStageByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, StageModel?>> call(final String stageId) async {
    return repository.getStageById(stageId);
  }
}

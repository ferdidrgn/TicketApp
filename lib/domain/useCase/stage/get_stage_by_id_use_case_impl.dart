import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/stage_model.dart';
import '../../repository/stage_repository.dart';

abstract class GetStagesByIdsUseCase {
  Future<Either<Failure, List<StageModel?>?>> call(final List<String> stagesIds);
}

class GetStageByIdUseCaseImpl implements GetStagesByIdsUseCase {
  final StageRepository repository;

  GetStageByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<StageModel?>?>> call(final List<String> stagesIds) async {
    return repository.getStagesByIds(stagesIds);
  }
}

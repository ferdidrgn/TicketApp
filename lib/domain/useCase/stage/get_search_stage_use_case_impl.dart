import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/stage_model.dart';
import '../../repository/stage_repository.dart';

abstract class GetSearchStageUseCase {
  Future<Either<Failure, List<StageModel?>?>> call(final String query);
}

class GetSearchStageUseCaseImpl implements GetSearchStageUseCase {
  final StageRepository repository;

  GetSearchStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<StageModel?>?>> call(final String query) async {
    return repository.getSearchStage(query);
  }
}

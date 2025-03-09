import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/stage_model.dart';
import '../../repository/stage_repository.dart';

abstract class GetStagesUseCase {
  Future<Either<Failure, List<StageModel?>>> call(final isLimit);
}

class GetStagesUseCaseImpl implements GetStagesUseCase {
  final StageRepository repository;

  GetStagesUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<StageModel?>>> call(final isLimit) async {
    return repository.getStages(isLimit);
  }
}

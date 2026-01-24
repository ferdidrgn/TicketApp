import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/stage.dart';
import '../repositories/stage_repository.dart';

abstract class GetStagesUseCase {
  Future<Either<Failure, List<Stage>>> call(final bool isLimit);
}

class GetStagesUseCaseImpl implements GetStagesUseCase {
  final StageRepository repository;

  GetStagesUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Stage>>> call(final bool isLimit) async => repository.getStages(isLimit);

}

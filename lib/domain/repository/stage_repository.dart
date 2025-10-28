import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/stage_model.dart';

abstract class StageRepository {
  Future<Either<Failure, List<StageModel?>?>> getSearchStage(final String query);
  Future<Either<Failure, List<StageModel?>?>> getStages(final bool isLimit);
  Future<Either<Failure,  List<StageModel?>?>> getStagesByIds(final List<String> stagesIds);
}

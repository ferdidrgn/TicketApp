import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/stage_repository.dart';
import '../../datasources/stage/stage_remote_data_source_and_impl.dart';
import '../../model/stage_model.dart';

class StageRepositoryImpl extends BaseRepository implements StageRepository {
  final StageRemoteDataSource remoteDataSource;

  StageRepositoryImpl({
    required this.remoteDataSource,
    required super.internetService,
  });

  @override
  Future<Either<Failure, List<StageModel?>?>> getSearchStage(
      final String query) async {
    return execute(() async {
      if (query.isEmpty) throw Exception('Query cannot be empty.');
      return remoteDataSource.getSearchStage(query);
    });
  }

  @override
  Future<Either<Failure, List<StageModel?>?>> getStages(final bool isLimit) async {
    return execute(() async {
      if (isLimit == null) throw Exception('isLimit cannot be null.');
      return remoteDataSource.getStages(isLimit);
    });
  }

  @override
  Future<Either<Failure, List<StageModel?>?>> getStagesByIds(
      final List<String> stagesIds) async {
    return execute(() async {
      if (stagesIds.isEmpty) throw Exception('StageId cannot be empty.');
      return remoteDataSource.getStagesByIds(stagesIds);
    });
  }
}

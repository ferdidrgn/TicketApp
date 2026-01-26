import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/stage.dart';
import '../../domain/repositories/stage_repository.dart';
import '../datasources/stage_remote_data_source_and_impl.dart';
import '../mappers/stage_mapper.dart';

class StageRepositoryImpl extends BaseRepository implements StageRepository {
  final StageRemoteDataSource remoteDataSource;

  StageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Stage>>> getSearchStage(final String query) =>
      execute(() async {
        if (query.isEmpty) throw Exception('Query cannot be empty.');
        final models = await remoteDataSource.getSearchStage(query);
        return models.map((final m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Stage>>> getStages(final bool isLimit) =>
      execute(() async {
        final models = await remoteDataSource.getStages(isLimit);
        return models.map((final m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Stage>>> getStagesByIds(
          final List<String> stagesIds) =>
      execute(() async {
        if (stagesIds.isEmpty) return <Stage>[];
        final models = await remoteDataSource.getStagesByIds(stagesIds);
        return models.map((final m) => m.toEntity()).toList();
      });
}

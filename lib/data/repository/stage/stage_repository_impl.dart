import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/stage_repository.dart';
import '../../datasources/stage/stage_remote_data_source_and_impl.dart';
import '../../model/stage_model.dart';

class StageRepositoryImpl implements StageRepository {
  final StageRemoteDataSource remoteDataSource;
  final InternetService internetService;

  StageRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, List<StageModel?>>> getSearchStage(final String query) async {
    if (await internetService.isConnected) {
      try {
        final stages = await remoteDataSource.getSearchStage(query);
        return Right(stages);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<StageModel?>>> getStages(final isLimit) async {
    if (await internetService.isConnected) {
      try {
        final stages = await remoteDataSource.getStages(isLimit);
        return Right(stages);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, StageModel?>> getStageById(final String stageId) async {
    if (await internetService.isConnected) {
      try {
        final stage = await remoteDataSource.getStageById(stageId);
        return Right(stage);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

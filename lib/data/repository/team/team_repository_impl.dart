import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/team_repository.dart';
import '../../datasources/team/team_remote_data_source_and_impl.dart';
import '../../model/team_model.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource remoteDataSource;
  final InternetService internetService;

  TeamRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, List<TeamModel?>>> getTeams(final isLimit) async {
    if (await internetService.isConnected) {
      try {
        final teams = await remoteDataSource.getTeams(isLimit);
        return Right(teams);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamModel?>> getTeamById(final String teamId) async {
    if (await internetService.isConnected) {
      try {
        final team = await remoteDataSource.getTeamById(teamId);
        return Right(team);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

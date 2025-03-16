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

  Future<Either<Failure, T>> _execute<T>(final Future<T> Function() action) async {
    if (await internetService.isConnected)
      try {
        final result = await action();
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    else return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, List<TeamModel>>> getTeams(final isLimit) async {
    return _execute(() async {
      final teams = await remoteDataSource.getTeams(isLimit);
      return teams.whereType<TeamModel>().toList(); // Nullable değerleri filtrele
    });
  }

  @override
  Future<Either<Failure, TeamModel?>> getTeamById(final String teamId) async {
    return _execute(() async {
      if (teamId.isEmpty) throw Exception('Team ID cannot be empty.');
      return remoteDataSource.getTeamById(teamId);
    });
  }
}

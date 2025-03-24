import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/team_repository.dart';
import '../../datasources/team/team_remote_data_source_and_impl.dart';
import '../../model/team_model.dart';

class TeamRepositoryImpl extends BaseRepository implements TeamRepository {
  final TeamRemoteDataSource remoteDataSource;

  TeamRepositoryImpl({
    required this.remoteDataSource,
    required super.internetService,
  });

  @override
  Future<Either<Failure, List<TeamModel?>?>> getTeams(final isLimit) async {
    return execute(() async {
      final teams = await remoteDataSource.getTeams(isLimit);
      return teams?.whereType<TeamModel>().toList(); // Nullable değerleri filtrele
    });
  }

  @override
  Future<Either<Failure, List<TeamModel?>?>> getTeamsByIds(final List<String> teamIds) async {
    return execute(() async {
      if (teamIds.isEmpty) throw Exception('Team ID cannot be empty.');
      return remoteDataSource.getTeamsByIds(teamIds);
    });
  }
}

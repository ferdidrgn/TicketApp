import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_data_source_and_impl.dart';
import '../mappers/team_mapper.dart';

class TeamRepositoryImpl extends BaseRepository implements TeamRepository {
  final TeamRemoteDataSource remoteDataSource;

  TeamRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Team>>> getTeams(final bool isLimit) {
    return execute(() async {
      final models = await remoteDataSource.getTeams(isLimit);
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Team>>> getTeamsByIds(
      final List<String> teamIds) {
    if (teamIds.isEmpty) return Future.value(const Right([]));

    return execute(() async {
      final models = await remoteDataSource.getTeamsByIds(teamIds);
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, bool>> addTeam(
          final Team team, final File? imageFile) =>
      execute(() async {
        final model = team.toModel();
        return remoteDataSource.addTeam(model, imageFile);
      });

  @override
  Future<Either<Failure, bool>> updateTeam(final String teamId,
          final Map<String, dynamic> updatedData, final File? imageFile) =>
      execute(
          () => remoteDataSource.updateTeam(teamId, updatedData, imageFile));

  @override
  Future<Either<Failure, bool>> deleteTeam(final String teamId) {
    if (teamId.isEmpty)
      return Future.value(const Left(ServerFailure('Invalid ID')));
    return execute(() => remoteDataSource.deleteTeam(teamId));
  }
}

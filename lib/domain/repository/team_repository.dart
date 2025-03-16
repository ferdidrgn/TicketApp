import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/team_model.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<TeamModel>>> getTeams(final isLimit);
  Future<Either<Failure, TeamModel?>> getTeamById(final String teamId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/team_model.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<TeamModel?>?>> getTeams(isLimit);
  Future<Either<Failure, List<TeamModel?>?>> getTeamsByIds(final List<String> teamsIds);
}

import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

abstract class GetTeamByIdUseCase {
  Future<Either<Failure, List<Team>>> call(final List<String> teamsIds);
}

class GetTeamByIdUseCaseImpl implements GetTeamByIdUseCase {
  final TeamRepository repository;

  GetTeamByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Team>>> call(final List<String> teamsIds) async =>
      repository.getTeamsByIds(teamsIds);
}

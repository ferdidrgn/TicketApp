import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/team_repository.dart';

abstract class DeleteTeamUseCase {
  Future<Either<Failure, bool>> call(final String teamId);
}

class DeleteTeamUseCaseImpl implements DeleteTeamUseCase {
  final TeamRepository repository;

  DeleteTeamUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String teamId) async =>
      repository.deleteTeam(teamId);
}

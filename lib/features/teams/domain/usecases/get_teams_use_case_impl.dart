import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

abstract class GetTeamsUseCase {
  Future<Either<Failure, List<Team>>> call(final bool isLimit);
}

class GetTeamsUseCaseImpl implements GetTeamsUseCase {
  final TeamRepository repository;

  GetTeamsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Team>>> call(final bool isLimit) async =>
      repository.getTeams(isLimit);
}

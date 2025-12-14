import 'package:dartz/dartz.dart';
import 'package:ticketapp/features/teams/domain/entities/team.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/team_repository.dart';

abstract class GetTeamsUseCase {
  Future<Either<Failure, List<Team>>> call(final bool isLimit);
}

class GetTeamsUseCaseImpl implements GetTeamsUseCase {
  TeamRepository repository;

  GetTeamsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Team>>> call(final bool isLimit) async {
    final result = await repository.getTeams(isLimit);
    return result.fold(
        (final failure) => Left(failure),
        (final teamsModels) => Right(teamsModels
                ?.map((final teamModel) => teamModel?.toEntity())
                .whereType<Team>()
                .toList() ??
            []));
  }
}

import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/entities/team.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/team_repository.dart';

abstract class GetTeamsUseCase {
  Future<Either<Failure, List<Team>>> call(isLimit);
}

class GetTeamsUseCaseImpl implements GetTeamsUseCase {
  TeamRepository repository;

  GetTeamsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Team>>> call(isLimit) async {
    final result = await repository.getTeams(isLimit);
    return result.fold(
      (final failure) => Left(failure),
      (final teamsModels) {
        final teams = teamsModels
                ?.map((final teamModel) => teamModel?.toEntity())
                .whereType<Team>()
                .toList() ??
            [];
        return Right(teams);
      },
    );
  }
}

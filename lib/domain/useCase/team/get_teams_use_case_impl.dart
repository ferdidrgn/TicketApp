import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/team_model.dart';
import '../../repository/team_repository.dart';

abstract class GetTeamsUseCase {
  Future<Either<Failure, List<TeamModel?>?>> call(final isLimit);
}

class GetTeamsUseCaseImpl implements GetTeamsUseCase {
  final TeamRepository repository;

  GetTeamsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<TeamModel?>?>> call(final isLimit) async {
    return repository.getTeams(isLimit);
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/team_model.dart';
import '../../repository/team_repository.dart';

abstract class GetTeamByIdUseCase {
  Future<Either<Failure, List<TeamModel?>?>> call(final List<String> teamsIds);
}

class GetTeamByIdUseCaseImpl implements GetTeamByIdUseCase {
  final TeamRepository repository;

  GetTeamByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<TeamModel?>?>> call (final List<String> teamsIds){
    return repository.getTeamsByIds(teamsIds);
  }
}

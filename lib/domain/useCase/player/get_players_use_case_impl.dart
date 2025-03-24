import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/player_model.dart';
import '../../repository/player_repository.dart';

abstract class GetPlayersUseCase {
  Future<Either<Failure, List<PlayerModel?>?>> call(final isLimit);
}

class GetPlayersUseCaseImpl implements GetPlayersUseCase {
  final PlayerRepository repository;

  GetPlayersUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<PlayerModel?>?>> call(final isLimit) async {
    return repository.getPlayers(isLimit);
  }
}

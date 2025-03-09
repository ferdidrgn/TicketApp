import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/player_model.dart';
import '../../repository/player_repository.dart';

abstract class GetPlayerByIdUseCase {
  Future<Either<Failure, PlayerModel?>> call(final String playerId);
}

class GetPlayerByIdUseCaseImpl implements GetPlayerByIdUseCase {
  final PlayerRepository repository;

  GetPlayerByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, PlayerModel?>> call(final String playerId) async {
    return repository.getPlayerById(playerId);
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/player_repository.dart';

abstract class DeletePlayerUseCase {
  Future<Either<Failure, bool>> call(final String playerId);
}

class DeletePlayerUseCaseImpl implements DeletePlayerUseCase {
  final PlayerRepository repository;

  DeletePlayerUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String playerId) async =>
      repository.deletePlayer(playerId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

abstract class GetPlayersUseCase {
  Future<Either<Failure, List<Player>>> call(final bool isLimit);
}

class GetPlayersUseCaseImpl implements GetPlayersUseCase {
  final PlayerRepository repository;

  GetPlayersUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Player>>> call(final bool isLimit) async =>
      repository.getPlayers(isLimit);
}

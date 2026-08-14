import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

abstract class GetPlayerByIdUseCase {
  Future<Either<Failure, List<Player>>> call(final List<String> playersIds);
}

class GetPlayerByIdUseCaseImpl implements GetPlayerByIdUseCase {
  final PlayerRepository repository;

  GetPlayerByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Player>>> call(
          final List<String> playersIds) async =>
      repository.getPlayersByIds(playersIds);
}

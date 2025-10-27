import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/player.dart';
import '../../repository/player_repository.dart';

abstract class GetPlayersUseCase {
  Future<Either<Failure, List<Player>>> call(final isLimit);
}

class GetPlayersUseCaseImpl implements GetPlayersUseCase {
  PlayerRepository repository;

  GetPlayersUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Player>>> call(final isLimit) async {
    final result = await repository.getPlayers(isLimit);
    return result.fold(
        (final failure) => Left(failure),
        (final playersModel) => Right(playersModel
                ?.map((final playerModel) => playerModel?.toEntity())
                .whereType<Player>()
                .toList() ??
            []));
  }
}

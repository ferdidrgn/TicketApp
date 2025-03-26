import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/player.dart';
import '../../repository/player_repository.dart';

abstract class GetPlayerByIdUseCase {
  Future<Either<Failure, List<Player>>>  call(final List<String> playersIds);
}

class GetPlayerByIdUseCaseImpl implements GetPlayerByIdUseCase {
  final PlayerRepository repository;

  GetPlayerByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Player>>>  call(final List<String> playersIds) async {

    final result = await repository.getPlayersByIds(playersIds);
    return result.fold(
          (final failure) => Left(failure),
          (final playersModels) {
        final players = playersModels
            ?.map((final playerModel) => playerModel?.toEntity())
            .whereType<Player>()
            .toList() ??
            [];
        return Right(players);
      },
    );
  }
}

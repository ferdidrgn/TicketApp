import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/player_model.dart';
import '../../repository/player_repository.dart';

abstract class GetPlayerByIdUseCase {
  Future<Either<Failure, List<PlayerModel?>?>>  call(final List<String> playersIds);
}

class GetPlayerByIdUseCaseImpl implements GetPlayerByIdUseCase {
  final PlayerRepository repository;

  GetPlayerByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<PlayerModel?>?>>  call(final List<String> playersIds) async {
    return repository.getPlayersByIds(playersIds);
  }
}

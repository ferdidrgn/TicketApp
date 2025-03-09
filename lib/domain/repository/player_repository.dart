import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/player_model.dart';

abstract class PlayerRepository {
  Future<Either<Failure, List<PlayerModel?>>> getPlayers(final isLimit);
  Future<Either<Failure, PlayerModel?>> getPlayerById(final String playerId);
}

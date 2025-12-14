import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/player_model.dart';

abstract class PlayerRepository {
  Future<Either<Failure, List<PlayerModel?>?>> getPlayers(final bool isLimit);
  Future<Either<Failure, List<PlayerModel?>?>> getPlayersByIds(final List<String> playersIds);
}

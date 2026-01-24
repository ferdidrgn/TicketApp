import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/player.dart';

abstract class PlayerRepository {
  Future<Either<Failure, List<Player>>> getPlayers(final bool isLimit);
  Future<Either<Failure, List<Player>>> getPlayersByIds(final List<String> playersIds);
}

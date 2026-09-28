import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/player.dart';

abstract class PlayerRepository {
  Future<Either<Failure, List<Player>>> getPlayers(final bool isLimit);
  Future<Either<Failure, List<Player>>> getPlayersByIds(final List<String> playersIds);
  Future<Either<Failure, List<Player>>> searchPlayers(final String query);

  /// ➕ Admin panelinden yeni bir oyuncu oluşturur.
  Future<Either<Failure, bool>> addPlayer(final Player player, final File? imageFile);
}

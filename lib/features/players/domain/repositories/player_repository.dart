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

  /// 🔄 Admin panelinden bir oyuncuyu günceller (Phase 2). `imageFile`
  /// verilirse görsel `addPlayer` ile AYNI Storage yoluna yeniden yüklenir.
  Future<Either<Failure, bool>> updatePlayer(final String playerId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir oyuncuyu siler (Phase 2).
  Future<Either<Failure, bool>> deletePlayer(final String playerId);
}

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_data_source_and_impl.dart';
import '../mappers/player_mapper.dart';
import '../models/player_model.dart';

class PlayerRepositoryImpl extends BaseRepository implements PlayerRepository {
  final PlayerRemoteDataSource remoteDataSource;

  PlayerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Player>>> getPlayers(final bool isLimit) async =>
      execute(() async {
        // DataSource'dan gelen veriyi List<PlayerModel> olarak zorluyoruz
        final List<PlayerModel> models =
            await remoteDataSource.getPlayers(isLimit);

        // Mapper kullanarak Entity'ye çeviriyoruz
        return models.map((final model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Player>>> getPlayersByIds(
          final List<String> playersIds) async =>
      execute(() async {
        if (playersIds.isEmpty) return <Player>[];

        final List<PlayerModel> models =
            await remoteDataSource.getPlayersByIds(playersIds);
        return models.map((final model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Player>>> searchPlayers(
          final String query) async =>
      execute(() async {
        if (query.isEmpty) return <Player>[];
        final List<PlayerModel> models =
            await remoteDataSource.searchPlayers(query);
        return models.map((final model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, bool>> addPlayer(
          final Player player, final File? imageFile) async =>
      execute(() async {
        final model = player.toModel();
        return remoteDataSource.addPlayer(model, imageFile);
      });

  @override
  Future<Either<Failure, bool>> updatePlayer(final String playerId,
          final Map<String, dynamic> updatedData, final File? imageFile) async =>
      execute(() =>
          remoteDataSource.updatePlayer(playerId, updatedData, imageFile));

  @override
  Future<Either<Failure, bool>> deletePlayer(final String playerId) async {
    if (playerId.isEmpty)
      return Future.value(const Left(ServerFailure('Invalid ID')));
    return execute(() => remoteDataSource.deletePlayer(playerId));
  }
}

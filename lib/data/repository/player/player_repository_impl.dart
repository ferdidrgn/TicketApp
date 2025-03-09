import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/player_repository.dart';
import '../../datasources/player/player_remote_data_source_and_impl.dart';
import '../../model/player_model.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerRemoteDataSource remoteDataSource;
  final InternetService internetService;

  PlayerRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, List<PlayerModel?>>> getPlayers(final isLimit) async {
    if (await internetService.isConnected) {
      try {
        final players = await remoteDataSource.getPlayers(isLimit);
        return Right(players);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PlayerModel?>> getPlayerById(final String playerId) async {
    if (await internetService.isConnected) {
      try {
        final player = await remoteDataSource.getPlayerById(playerId);
        return Right(player);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}

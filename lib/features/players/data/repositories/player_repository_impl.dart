import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../core/common/base_repo.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_data_source_and_impl.dart';
import '../models/player_model.dart';

class PlayerRepositoryImpl extends BaseRepository implements PlayerRepository {
  final PlayerRemoteDataSource remoteDataSource;

  PlayerRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, List<PlayerModel?>?>> getPlayers(final bool isLimit) async {
   return execute(() => remoteDataSource.getPlayers(isLimit));
  }

  @override
  Future<Either<Failure, List<PlayerModel?>?>> getPlayersByIds(final List<String> playersIds) async {
    return execute(() async {
      if(playersIds.isEmpty) throw Exception('playersIds is null');
      return remoteDataSource.getPlayersByIds(playersIds);
    });
  }
}

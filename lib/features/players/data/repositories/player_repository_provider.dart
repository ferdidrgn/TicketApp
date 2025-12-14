import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/network/connectivity_provider.dart';
import 'package:ticketapp/features/players/data/datasources/player_remote_data_source_provider.dart';
import 'package:ticketapp/features/players/data/repositories/player_repository_impl.dart';
import 'package:ticketapp/features/players/domain/repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((final ref) {
  final remoteDataSource = ref.watch(playerRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return PlayerRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

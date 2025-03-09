import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/network/internet_service_provider.dart';
import 'package:ticketapp/data/datasources/player/player_remote_data_source_provider.dart';
import 'package:ticketapp/data/repository/player/player_repository_impl.dart';
import 'package:ticketapp/domain/repository/player_repository.dart';

final playerProvider = Provider<PlayerRepository>((final ref) {
  final remoteDataSource = ref.watch(playerRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return PlayerRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});

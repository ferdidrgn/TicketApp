import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/repository/team_repository.dart';
import '../../datasources/team/team_remote_data_source_provider.dart';
import 'team_repository_impl.dart';

final teamRepositoryProvider = Provider<TeamRepository>((final ref) {
  final remoteDataSource = ref.watch(teamRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return TeamRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});
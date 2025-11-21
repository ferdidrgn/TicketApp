import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../domain/repository/stage_repository.dart';
import '../../datasources/stage/stage_remote_data_source_provider.dart';
import 'stage_repository_impl.dart';

final stageRepositoryProvider = Provider<StageRepository>((final ref) {
  final remoteDataSource = ref.watch(stageRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return StageRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

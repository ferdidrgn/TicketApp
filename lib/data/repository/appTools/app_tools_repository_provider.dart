import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_provider.dart';
import '../../../domain/repository/app_tools_repository.dart';
import '../../datasources/appTools/app_tools_remote_data_source_provider.dart';
import 'app_tools_repository_impl.dart';

final appToolsRepositoryProvider = Provider<AppToolsRepository>((final ref) {
  final remoteDataSource = ref.watch(appToolsRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return AppToolsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

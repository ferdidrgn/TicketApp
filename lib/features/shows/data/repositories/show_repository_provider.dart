import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/shows/data/repositories/show_repository_impl.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../domain/repositories/show_repository.dart';
import '../datasources/show_remote_data_source_provider.dart';

final showRepositoryProvider = Provider<ShowRepository>((final ref) {
  final remoteDataSource = ref.watch(showRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return ShowRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/repository/show/show_repository_impl.dart';

import '../../../core/network/internet_service_provider.dart';
import '../../../domain/repository/show_repository.dart';
import '../../datasources/show/show_remote_data_source_provider.dart';

final showRepositoryProvider = Provider<ShowRepository>((ref) {
  final remoteDataSource = ref.watch(showRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return ShowRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});

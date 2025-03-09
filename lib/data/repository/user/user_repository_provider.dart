import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/repository/user_repository.dart';
import '../../datasources/user/user_remote_data_source_provider.dart';
import 'user_repository_impl.dart';

final userRepositoryProvider = Provider<UserRepository>((final ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return UserRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});

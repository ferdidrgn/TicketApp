import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source_provider.dart';
import 'auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((final ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

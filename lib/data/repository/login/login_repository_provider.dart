import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../domain/repository/login_repository.dart';
import '../../datasources/login/login_remote_data_source_provider.dart';
import 'login_repository_impl.dart';

final loginRepositoryProvider = Provider<LoginRepository>((final ref) {
  final remoteDataSource = ref.watch(loginRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return LoginRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});

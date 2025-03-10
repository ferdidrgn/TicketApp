import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_auth_provider.dart';
import 'login_remote_data_source_and_impl.dart';

final loginRemoteDataSourceProvider =
    Provider<LoginRemoteDataSource>((final ref) {
  final firebaseAuthAuth = ref.watch(firebaseAuthProvider);
  return LoginRemoteDataSourceImpl(firebaseAuth: firebaseAuthAuth);
});

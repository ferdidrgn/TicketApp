import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/firebase_auth_provider.dart';
import 'auth_remote_data_source_and_impl.dart';

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((final ref) {
  final firebaseAuthAuth = ref.watch(firebaseAuthProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth: firebaseAuthAuth);
});

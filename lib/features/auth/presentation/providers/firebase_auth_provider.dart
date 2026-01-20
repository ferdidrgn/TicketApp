import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/auth_remote_data_source_and_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

part 'firebase_auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(final Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseStorage firebaseStorage(final Ref ref) => FirebaseStorage.instance;

@riverpod
AuthRemoteDataSource authRemoteDataSource(final Ref ref) =>
    AuthRemoteDataSourceImpl(firebaseAuth: ref.watch(firebaseAuthProvider));

@riverpod
AuthRepository authRepository(final Ref ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider));

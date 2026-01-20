import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/auth_repository.dart'; // Kendi yoluna göre düzenle
import '../../data/repositories/auth_repository_impl.dart'; // Kendi yoluna göre düzenle

part 'firebase_auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(final Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseStorage firebaseStorage(final Ref ref) => FirebaseStorage.instance;

@riverpod
AuthRepository authRepository(final Ref ref) =>
    AuthRepositoryImpl(ref); // Repository implementasyonun

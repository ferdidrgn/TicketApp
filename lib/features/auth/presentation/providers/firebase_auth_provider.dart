import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(final Ref ref) => FirebaseAuth.instance;

@riverpod
Stream<User?> authStateChanges(final Ref ref) =>
    ref.watch(firebaseAuthProvider).authStateChanges();

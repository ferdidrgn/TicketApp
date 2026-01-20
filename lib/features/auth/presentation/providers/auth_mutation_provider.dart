import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import 'auth_provider.dart';

part 'auth_mutation_provider.g.dart';

@riverpod
class AuthMutation extends _$AuthMutation {
  @override
  FutureOr<void> build() {}

  /// Google ile Giriş
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signInWithGoogleUseCaseProvider).call().getOrThrow();
      ref.invalidate(currentUserProvider);
    });
  }

  /// Anonim Giriş
  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signInAnonymouslyUseCaseProvider).call().getOrThrow();
      ref.invalidate(currentUserProvider);
    });
  }

  /// Telefon Doğrulama (OTP İsteme)
  Future<void> verifyPhone(final String phoneNumber) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(verifyPhoneUseCaseProvider)
          .call(
            phoneNumber: phoneNumber,
            onVerificationCompleted: (final credential) =>
                ref.invalidate(currentUserProvider),
            onCodeSent: (final id, final token) => state = const AsyncData(null),
            onAutoRetrievalTimeout: (final id) {},
          )
          .getOrThrow();
    });
  }

  /// Çıkış Yap
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signOutUseCaseProvider).call().getOrThrow();
      await LocalStorageService.clearAllUserData();
      ref.invalidate(currentUserProvider);
    });
  }

  /// Hesabı Sil
  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteAccountUseCaseProvider).call().getOrThrow();
      await LocalStorageService.clearAllUserData();
      ref.invalidate(currentUserProvider);
    });
  }
}

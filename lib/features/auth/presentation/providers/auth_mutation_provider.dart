import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/errors/failures.dart';
import 'auth_provider.dart';

part 'auth_mutation_provider.g.dart';

@riverpod
class AuthMutation extends _$AuthMutation {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(signInWithGoogleUseCaseProvider).call();
      final user = result.getOrThrow(); // Either'ı burada açtık

      if (user != null) {
        ref.invalidate(currentUserProvider);
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(signOutUseCaseProvider).call();
      result.getOrThrow(); // Başarılıysa devam eder, başarısızsa hata fırlatır

      await LocalStorageService.clearAllUserData();
      ref.invalidate(currentUserProvider);
    });
  }
}

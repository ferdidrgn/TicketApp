import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart' as entity;
import 'user_provider.dart' hide currentUserProvider;

part 'user_mutation_provider.g.dart';

@riverpod
class UserMutation extends _$UserMutation {
  @override
  FutureOr<void> build() {}

  /// 💾 PROFİL GÜNCELLEME (İsim, Şehir, Fotoğraf vb.)
  Future<void> save(final entity.User user, final String photoUrl,
      {final bool isUpdate = false}) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref
          .read(saveUserUseCaseProvider)
          .call(UserModel.fromEntity(user), photoUrl, isUpdate: isUpdate);

      await LocalStorageService.saveEssentialUserData(
          uid: user.id,
          displayName: '${user.firstName} ${user.lastName}',
          photoUrl: photoUrl,
          role: user.role);
    });

    if (!ref.mounted) return;
    state = result;

    ref.invalidate(currentUserProvider);
  }

  /// 🗑️ HESABI VE TÜM VERİLERİ SİL (Atomik İmha)
  /// Bu metot biletleri, Firestore dökümanını ve Auth hesabını sırayla temizler.
  Future<void> deleteAccountCompletely() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      // 1. Firestore: UseCase üzerinden dökümanı ve biletleri sil
      await ref.read(deleteUserUseCaseProvider).call(userId);

      // 2. Auth: Firebase hesabını imha et
      await ref.read(authServiceProvider).deleteAccount();

      // 3. Lokal: Cihazdaki verileri temizle
      await LocalStorageService.clearAllUserData();
    });

    if (!ref.mounted) return;
    state = result;
    ref.invalidate(currentUserProvider);
  }
}

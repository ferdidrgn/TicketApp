import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../domain/entities/user.dart' as entity;
import 'user_provider.dart';

part 'user_mutation_provider.g.dart';

@riverpod
class UserMutation extends _$UserMutation {
  @override
  FutureOr<void> build() {}

  /// 💾 PROFİL GÜNCELLEME
  Future<void> save(final entity.User user, final String photoUrl,
      {final bool isUpdate = false}) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await ref
          .read(saveUserUseCaseProvider)
          .call(user, photoUrl, isUpdate: isUpdate);

      await LocalStorageService.saveEssentialUserData(
          uid: user.id,
          displayName: '${user.firstName} ${user.lastName}',
          photoUrl: photoUrl,
          role: user.role);
    });

    if (!ref.mounted) return;
    state = result;

    // GÜNCELLEME: Artık userProfileProvider'ı invalidate ediyoruz
    ref.invalidate(userProfileProvider);
  }

  /// 🗑️ HESABI VE TÜM VERİLERİ SİL
  Future<void> deleteAccountCompletely() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      // Auth'dan gelen UID'yi al
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      // 1. Firestore temizliği
      await ref.read(deleteUserUseCaseProvider).call(userId);

      // 2. Auth oturum kapatma
      await ref
          .read(authServiceProvider.notifier)
          .executeGlobalSignOutRoutine();

      // 3. Lokal temizlik
      await LocalStorageService.clearAllUserData();
    });

    if (!ref.mounted) return;
    state = result;

    // GÜNCELLEME: Profil verisini tamamen sıfırlıyoruz
    ref.invalidate(userProfileProvider);
  }
}

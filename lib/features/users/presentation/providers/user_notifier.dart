import '../../../../core/common/base_notifier.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'user_provider.dart';
import 'user_state.dart';

/// 👤 User Notifier
///
/// User CRUD işlemlerini yönetir
/// Auth işlemleri LoginNotifier'da yapılır
class UserNotifier extends BaseNotifier<UserState> {
  @override
  UserState initialState() => const UserState();

  // ========================================
  // USER OPERATIONS
  // ========================================

  Future<void> loadUserById(final String userId) async {
    return execute(
      () => ref.read(getUserByIdUseCaseProvider).call(userId),
      onSuccess: (user) {
        state = state.copyWith(dataSingle: user, errorMessage: null);
      },
      customErrorMessage: 'Kullanıcı bilgileri yüklenemedi',
    );
  }

  /// 💾 Save user
  Future<void> saveUser(
    final User user,
    final String downloadUrl, {
    final bool isUpdate = false,
  }) async =>
      execute(
        () => ref.read(saveUserUseCaseProvider).call(
              UserModel.fromEntity(user),
              downloadUrl,
              isUpdate: isUpdate,
            ),
        onSuccess: (final _) {
          state = state.copyWith(
            dataSingle: user,
            errorMessage: null,
          );
        },
        customErrorMessage:
            isUpdate ? 'Kullanıcı güncellenemedi' : 'Kullanıcı kaydedilemedi',
      );

  /// 🗑️ Delete user (Sadece Firestore)
  ///
  /// ⚠️ DİKKAT: Bu sadece Firestore'daki user document'ını siler
  /// Auth silme işlemi LoginNotifier.deleteAccount() ile yapılır
  Future<bool> deleteUser(final String userId) async {
    bool? result;

    await execute(
      () => ref.read(deleteUserUseCaseProvider).call(userId),
      onSuccess: (final success) {
        result = success;
        if (success) {
          state = state.copyWith(
            dataSingle: null,
            errorMessage: null,
          );
        }
      },
      customErrorMessage: 'Kullanıcı silinemedi',
    );

    return result ?? false;
  }

  // ========================================
  // STATE MANAGEMENT
  // ========================================

  /// Clear user state
  void clearUserState() => state = const UserState();

  /// Update user locally (without saving to Firestore)
  void updateUserLocally(final User user) =>
      state = state.copyWith(dataSingle: user);

  /// Clear error
  void clearError() => clearErrorState();
}

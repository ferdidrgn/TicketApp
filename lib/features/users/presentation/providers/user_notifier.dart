import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'user_state.dart';

class UserNotifier extends BaseNotifier<UserState> {
  @override
  UserState initialState() => const UserState();

  Future<void> loadUserById(final String userId) =>
      execute(() => ref.read(getUserByIdUseCaseProvider).call(userId),
          onSuccess: (final user) =>
              state = state.copyWith(dataSingle: user, errorMessage: null));

  Future<void> saveUser(final User user, final String downloadUrl,
          {final bool isUpdate = false}) =>
      execute(() => ref
          .read(saveUserUseCaseProvider)
          .call(UserModel.fromEntity(user), downloadUrl, isUpdate: isUpdate));

  Future<bool> deleteUser(final String userId) async {
    bool? result;

    await execute(() => ref.read(deleteUserUseCaseProvider).call(userId),
        onSuccess: (final success) => result = success);

    return result ?? false;
  }

  void clearUserState() => state = UserState();
}

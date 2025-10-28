import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../data/model/user_model.dart';
import '../../../domain/entities/user.dart';
import 'user_state.dart';

class UserNotifier extends BaseNotifierWithNetworkChecker<UserState> {
  @override
  UserState initialState() => const UserState();

  @override
  void reloadData() {
    // Örneğin, mevcut userId var ise loadUserById çağrılabilir
  }

  Future<void> loadUserById(final String userId) => executeWithInternetCheck(
      () => ref.read(getUserByIdUseCaseProvider).call(userId),
      onSuccess: (final user) =>
          state = state.copyWith(dataSingle: user, errorMessage: null));

  Future<void> saveUser(final User user, final String downloadUrl,
          {final bool isUpdate = false}) =>
      executeWithInternetCheck(() => ref
          .read(saveUserUseCaseProvider)
          .call(UserModel.fromEntity(user), downloadUrl, isUpdate: isUpdate));

  Future<void> deleteUser(final String userId) => executeWithInternetCheck(
      () => ref.read(deleteUserUseCaseProvider).call(userId),
      onSuccess: (final _) {});
}

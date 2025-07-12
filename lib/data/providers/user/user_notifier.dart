import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../data/model/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/useCase/user/delete_user_use_case_impl.dart';
import '../../../domain/useCase/user/get_user_by_id_use_case_impl.dart';
import '../../../domain/useCase/user/save_user_use_case_impl.dart';
import 'user_state.dart';

class UserNotifier extends BaseNotifierWithNetworkChecker<UserState> {
  final SaveUserUseCase _saveUserUseCase;
  final GetUserByIdUseCase _getUserByIdUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  UserNotifier(
    final InternetService internetService,
    this._saveUserUseCase,
    this._getUserByIdUseCase,
    this._deleteUserUseCase,
  ) : super(internetService, const UserState());


  @override
  void reloadData() {
    // Örneğin, mevcut userId var ise loadUserById çağrılabilir
  }

  Future<void> loadUserById(final String userId) => executeWithInternetCheck(
        () => _getUserByIdUseCase.call(userId),
        onSuccess: (final user) =>
            state = state.copyWith(dataSingle: user, errorMessage: null),
      );

  Future<void> saveUser(final User user, final String downloadUrl,
          {final bool isUpdate = false}) =>
      executeWithInternetCheck(
        () => _saveUserUseCase.call(UserModel.fromEntity(user), downloadUrl,
            isUpdate: isUpdate),
      );

  Future<void> deleteUser(final String userId) =>
      executeWithInternetCheck(() => _deleteUserUseCase.call(userId));

}

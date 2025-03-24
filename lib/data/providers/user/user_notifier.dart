import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../data/model/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/useCase/user/delete_user_use_case_impl.dart';
import '../../../domain/useCase/user/get_user_by_id_use_case_impl.dart';
import '../../../domain/useCase/user/save_user_use_case_impl.dart';
import 'user_state.dart';

class UserNotifier extends BaseNotifier<UserState> {
  final SaveUserUseCase saveUserUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final DeleteUserUseCase deleteUserUseCase;

  UserNotifier(
      this.saveUserUseCase, this.getUserByIdUseCase, this.deleteUserUseCase)
      : super(UserState());

  Future<void> loadUserById(final String userId) async {
    await handleOperation(() => getUserByIdUseCase.call(userId),
        onSuccess: (final user) => state = state.copyWith(user: user));
  }

  Future<void> saveUser(final User user, final String downloadUrl,
      {final bool isUpdate = false}) async {
    final userModel = UserModel.fromEntity(user);
    await handleOperation(
      () => saveUserUseCase.call(userModel, downloadUrl, isUpdate: isUpdate),
    );
  }

  Future<void> deleteUser(final String userId) async {
    await handleOperation(() => deleteUserUseCase.call(userId));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/model/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/useCase/user/delete_user_use_case_impl.dart';
import '../../../domain/useCase/user/get_user_by_id_use_case_impl.dart';
import '../../../domain/useCase/user/save_user_use_case_impl.dart';
import 'user_state.dart';

class UserNotifier extends StateNotifier<UserState> {
  final SaveUserUseCase saveUserUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final DeleteUserUseCase deleteUserUseCase;

  UserNotifier(this.saveUserUseCase, this.getUserByIdUseCase, this.deleteUserUseCase)
      : super(UserState());

  Future<void> loadUserById(final String userId) async {
    _setLoadingState(true);
    final result = await getUserByIdUseCase.call(userId);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final user) => _setUserState(user?.toEntity()),
    );
  }

  Future<void> saveUser(final User user, final String downloadUrl, {final bool isUpdate = false}) async {
    _setLoadingState(true);
    final userModel = UserModel.fromEntity(user);
    final result = await saveUserUseCase.call(userModel, downloadUrl, isUpdate: isUpdate);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final _) => _setSuccessState(),
    );
  }

  Future<void> deleteUser(final String userId) async {
    _setLoadingState(true);
    final result = await deleteUserUseCase.call(userId);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final _) => _setSuccessState(),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setUserState(final User? user) {
    state = state.copyWith(user: user, isLoading: false);
  }

  void _setSuccessState() {
    state = state.copyWith(isLoading: false);
  }
}

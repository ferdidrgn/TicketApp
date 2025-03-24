import 'package:ticketapp/core/common/base_state.dart';
import 'package:ticketapp/data/model/user_model.dart';

class UserState extends BaseState {
  final UserModel? user;

  UserState({
    this.user,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  UserState copyWith({
    final UserModel? user,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

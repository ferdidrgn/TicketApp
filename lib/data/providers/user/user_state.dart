import 'package:ticketapp/core/common/base_state.dart';
import '../../../domain/entities/user.dart';

class UserState extends BaseState {
  User? user;

  UserState({
    this.user,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  UserState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

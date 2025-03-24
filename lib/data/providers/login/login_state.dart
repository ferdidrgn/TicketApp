import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticketapp/core/common/base_state.dart';

class LoginState extends BaseState {
  final User? user;

  LoginState({
    this.user,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  LoginState copyWith({
    final User? user,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return LoginState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

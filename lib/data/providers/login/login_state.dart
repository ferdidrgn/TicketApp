import 'package:firebase_auth/firebase_auth.dart';

class LoginState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  LoginState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

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

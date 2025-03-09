import '../../../domain/entities/user.dart';

class UserState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  UserState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  UserState copyWith({
    final User? user,
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

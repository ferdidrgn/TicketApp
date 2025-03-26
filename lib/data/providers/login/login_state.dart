import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_state.dart';

class LoginState extends BaseState {
  User? user;
  GoogleSignInAccount? googleUser;

  LoginState({
    this.user,
    this.googleUser,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  LoginState copyWith({
    User? user,
    GoogleSignInAccount? googleUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      user: user ?? this.user,
      googleUser: googleUser ?? this.googleUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

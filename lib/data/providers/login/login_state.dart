import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_state.dart';

class LoginState extends BaseState {
  final User? user;
  final GoogleSignInAccount? googleUser;
  final String? verificationId;
  final String? phoneNumber;
  final bool isCodeSent;
  final bool isGuest;

  LoginState({
    this.user,
    this.googleUser,
    this.verificationId,
    this.phoneNumber,
    this.isCodeSent = false,
    this.isGuest = false,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  LoginState copyWith({
    final User? user,
    final GoogleSignInAccount? googleUser,
    final String? verificationId,
    final String? phoneNumber,
    final bool? isCodeSent,
    final bool? isGuest,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      LoginState(
        user: user ?? this.user,
        googleUser: googleUser ?? this.googleUser,
        verificationId: verificationId ?? this.verificationId,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isCodeSent: isCodeSent ?? this.isCodeSent,
        isGuest: isGuest ?? this.isGuest,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isLoggedIn => user != null;
  bool get isGoogleSignedIn => googleUser != null;
  bool get isPhoneVerified => phoneNumber != null;
}

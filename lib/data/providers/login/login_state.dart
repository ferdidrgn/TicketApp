import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_state.dart';

import '../../../core/common/enums.dart';

class LoginState extends BaseState {
  final User? user;
  final GoogleSignInAccount? googleUser;
  final String? verificationId;
  final String? phoneNumber;
  final bool isCodeSent;
  final bool isGuest;
  final bool isAccountDeleted;
  final LoginMethod? loginMethod;

  LoginState({
    this.user,
    this.googleUser,
    this.verificationId,
    this.phoneNumber,
    this.isCodeSent = false,
    this.isGuest = false,
    this.isAccountDeleted = false,
    this.loginMethod,
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
    final bool? isAccountDeleted,
    final LoginMethod? loginMethod,
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
        loginMethod: loginMethod ?? this.loginMethod,
        isAccountDeleted: isAccountDeleted ?? this.isAccountDeleted,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isLoggedIn => user != null;
  bool get isGoogleSignedIn => loginMethod == LoginMethod.google;
  bool get isPhoneVerified => loginMethod == LoginMethod.phone;
  bool get isAnonymous => loginMethod == LoginMethod.anonymous;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

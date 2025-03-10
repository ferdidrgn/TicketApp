import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/login/get_current_user_use_case_impl.dart';
import '../../../domain/useCase/login/sign_in_with_google_use_case_impl.dart';
import '../../../domain/useCase/login/sign_out_use_case_impl.dart';
import '../../../domain/useCase/login/verify_otp_use_case_impl.dart';
import '../../../domain/useCase/login/verify_phone_use_case_impl.dart';
import 'login_state.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final VerifyPhoneUseCase verifyPhoneUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  LoginNotifier(
    this.signInWithGoogleUseCase,
    this.signOutUseCase,
    this.getCurrentUserUseCase,
    this.verifyPhoneUseCase,
    this.verifyOtpUseCase,
  ) : super(LoginState());

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    final result = await signInWithGoogleUseCase.call();
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final userDisplayName) {
        state = state.copyWith(
            isLoading: false, user: getCurrentUserUseCase.call());
      },
    );
  }

  Future<void> signOut() async {
    await signOutUseCase.call();
    state = state.copyWith(user: null);
  }

  Future<void> verifyPhone(
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  ) async {
    state = state.copyWith(isLoading: true);
    final result = await verifyPhoneUseCase.call(
      phoneNumber,
      onVerificationCompleted,
      onCodeSent,
      onAutoRetrievalTimeout,
    );
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final _) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> verifyOtp(final String verificationId, final String otp) async {
    final result = await verifyOtpUseCase.call(verificationId, otp);
    result.fold(
      (final failure) => state = state.copyWith(errorMessage: failure.message),
      (final _) => state = state.copyWith(user: getCurrentUserUseCase.call()),
    );
  }
}

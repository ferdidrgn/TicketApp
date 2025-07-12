import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/login/get_current_user_use_case_impl.dart';
import '../../../domain/useCase/login/sign_in_with_google_use_case_impl.dart';
import '../../../domain/useCase/login/sign_out_use_case_impl.dart';
import '../../../domain/useCase/login/verify_otp_use_case_impl.dart';
import '../../../domain/useCase/login/verify_phone_use_case_impl.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifierWithNetworkChecker<LoginState> {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final VerifyPhoneUseCase _verifyPhoneUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;

  LoginNotifier(
    final InternetService internetService,
    this._signInWithGoogleUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
    this._verifyPhoneUseCase,
    this._verifyOtpUseCase,
  ) : super(internetService, LoginState());

  @override
  void reloadData() => getCurrentUser();

  Future<void> getCurrentUser() => executeWithInternetCheck(
        () => _getCurrentUserUseCase.call(),
        onSuccess: (final user) =>
            state = state.copyWith(user: user, errorMessage: null),
      );

  Future<void> signInWithGoogle() => executeWithInternetCheck(
        () => _signInWithGoogleUseCase.call(),
        onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser),
      );

  Future<void> _handleGoogleSignInSuccess(final googleUser) async {
    state = state.copyWith(googleUser: googleUser);
    final userResult = await _getCurrentUserUseCase.call();
    userResult.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final user) => state =
          state.copyWith(isLoading: false, user: user, errorMessage: null),
    );
  }

  Future<void> signOut() => executeWithInternetCheck(
        () => _signOutUseCase.call(),
        onSuccess: (_) =>
            state = state.copyWith(user: null, errorMessage: null),
      );

  Future<void> verifyPhone(
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _verifyPhoneUseCase.call(
      phoneNumber,
      onVerificationCompleted,
      onCodeSent,
      onAutoRetrievalTimeout,
    );
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => state = state.copyWith(isLoading: false, errorMessage: null),
    );
  }

  Future<void> verifyOtp(final String verificationId, final String otp) =>
      executeWithInternetCheck(
        () => _verifyOtpUseCase.call(verificationId, otp),
        onSuccess: (final success) => _handleOtpVerificationResult(success),
      );

  Future<void> _handleOtpVerificationResult(final bool success) async {
    if (!success) {
      state = state.copyWith(errorMessage: "Invalid OTP");
      return;
    }

    final userResult = await _getCurrentUserUseCase.call();
    userResult.fold(
      (final failure) => state = state.copyWith(errorMessage: failure.message),
      (final user) => state = state.copyWith(user: user, errorMessage: null),
    );
  }
}

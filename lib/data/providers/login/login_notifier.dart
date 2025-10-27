import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifierWithNetworkChecker<LoginState> {
  @override
  LoginState initialState() => LoginState();

  @override
  void reloadData() => getCurrentUser();

  Future<void> getCurrentUser() => executeWithInternetCheck(
        () => ref.read(getCurrentUserUseCaseProvider).call(),
        onSuccess: (final user) =>
            state = state.copyWith(user: user, errorMessage: null),
      );

  Future<void> signInWithGoogle() => executeWithInternetCheck(
        () => ref.read(signInWithGoogleUseCaseProvider).call(),
        onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser),
      );

  Future<void> _handleGoogleSignInSuccess(final googleUser) async {
    state = state.copyWith(googleUser: googleUser);
    final userResult = await ref.read(getCurrentUserUseCaseProvider).call();
    userResult.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final user) => state =
          state.copyWith(isLoading: false, user: user, errorMessage: null),
    );
  }

  Future<void> signOut() => executeWithInternetCheck(
        () => ref.read(signOutUseCaseProvider).call(),
        onSuccess: (final _) =>
            state = state.copyWith(user: null, errorMessage: null),
      );

  Future<void> verifyPhone({
    required final String phoneNumber,
    required final Function(String) onVerificationCompleted,
    required final Function(String) onCodeSent,
    required final Function(String) onAutoRetrievalTimeout,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref.read(verifyPhoneUseCaseProvider).call(
          phoneNumber,
          onVerificationCompleted: onVerificationCompleted,
          onCodeSent: onCodeSent,
          onAutoRetrievalTimeout: onAutoRetrievalTimeout,
          // onVerificationFailed: onVerificationFailed,
        );

    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final _) => state = state.copyWith(isLoading: false, errorMessage: null),
    );
  }

  Future<void> verifyOtp(final String verificationId, final String otp) =>
      executeWithInternetCheck(
        () => ref.read(verifyOtpUseCaseProvider).call(verificationId, otp),
        onSuccess: (final success) => _handleOtpVerificationResult(success),
      );

  Future<void> _handleOtpVerificationResult(final bool success) async {
    if (!success) {
      state = state.copyWith(errorMessage: "Invalid OTP");
      return;
    }

    final userResult = await ref.read(getCurrentUserUseCaseProvider).call();
    userResult.fold(
      (final failure) => state = state.copyWith(errorMessage: failure.message),
      (final user) => state = state.copyWith(user: user, errorMessage: null),
    );
  }
}

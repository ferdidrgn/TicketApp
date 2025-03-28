import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../domain/useCase/login/get_current_user_use_case_impl.dart';
import '../../../domain/useCase/login/sign_in_with_google_use_case_impl.dart';
import '../../../domain/useCase/login/sign_out_use_case_impl.dart';
import '../../../domain/useCase/login/verify_otp_use_case_impl.dart';
import '../../../domain/useCase/login/verify_phone_use_case_impl.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
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

  Future<void> getCurrentUser() async {
    await handleOperation(
      () => getCurrentUserUseCase.call(),
      onSuccess: (final user) => state = state.copyWith(user: user),
    );
  }

  Future<void> signInWithGoogle() async {
    await handleOperation(() => signInWithGoogleUseCase.call(),
        onSuccess: (final googleUser) async {
      state = state.copyWith(googleUser: googleUser);
      final userResult = await getCurrentUserUseCase.call();
      userResult.fold(
        (final failure) => state =
            state.copyWith(isLoading: false, errorMessage: failure.message),
        (final user) => state = state.copyWith(isLoading: false, user: user),
      );
    });
  }

  Future<void> signOut() async {
    await handleOperation(
      () => signOutUseCase.call(),
      onSuccess: (final _) => state = state.copyWith(user: null),
    );
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
    await handleOperation(
      () => verifyOtpUseCase.call(verificationId, otp),
      onSuccess: (final bool) async {
        if (bool) {
          final userResult = await getCurrentUserUseCase.call();
          userResult.fold(
            (final failure) =>
                state = state.copyWith(errorMessage: failure.message),
            (final user) => state = state.copyWith(user: user),
          );
        } else
          state = state.copyWith(errorMessage: "Invalid OTP");
      },
    );
  }
}

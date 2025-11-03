import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../user/user_provider.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifierWithNetworkChecker<LoginState> {
  @override
  LoginState initialState() => LoginState();

  @override
  void reloadData() => getCurrentUser();

  // Mevcut kullanıcıyı kontrol et
  Future<void> getCurrentUser() => executeWithInternetCheck(
      () => ref.read(getCurrentUserUseCaseProvider).call(),
      onSuccess: (final user) =>
          state = state.copyWith(user: user, errorMessage: null));

  // Google ile giriş
  Future<void> signInWithGoogle() => executeWithInternetCheck(
      () => ref.read(signInWithGoogleUseCaseProvider).call(),
      onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser));

  Future<void> _handleGoogleSignInSuccess(
      final GoogleSignInAccount? googleUser) async {
    state = state.copyWith(googleUser: googleUser, isGuest: false);

    final userResult = await ref.read(getCurrentUserUseCaseProvider).call();
    userResult.fold(
        (final failure) => state =
            state.copyWith(isLoading: false, errorMessage: failure.message),
        (final user) => state = state.copyWith(
            isLoading: false, user: user, errorMessage: null, isGuest: false));
  }

  // Misafir girişi
  Future<void> signInAnonymously() => executeWithInternetCheck(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
        onSuccess: (final user) => state =
            state.copyWith(user: user, isGuest: true, errorMessage: null),
      );

  Future<void> verifyPhone({
    required final String phoneNumber,
    required final Function(PhoneAuthCredential) onVerificationCompleted,
    required final Function(String, int?) onCodeSent,
    required final Function(String) onAutoRetrievalTimeout,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref.read(verifyPhoneUseCaseProvider).call(
          phoneNumber: phoneNumber,
          onVerificationCompleted: onVerificationCompleted,
          onCodeSent: onCodeSent,
          onAutoRetrievalTimeout: onAutoRetrievalTimeout,
          // onVerificationFailed: onVerificationFailed,
        );

    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final verificationId) => state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
        isCodeSent: true,
        errorMessage: null,
      ),
    );
  }

  // OTP doğrulama
  Future<void> verifyOtp(final String otp) => executeWithInternetCheck(
        () {
          if (state.verificationId == null)
            throw Exception('Verification ID not found');
          return ref
              .read(verifyOtpUseCaseProvider)
              .call(state.verificationId!, otp);
        },
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
      (final user) => state = state.copyWith(
        user: user,
        phoneNumber: user?.phoneNumber,
        isGuest: false,
        isCodeSent: false,
        verificationId: null,
        errorMessage: null,
      ),
    );
  }

  // Çıkış
  Future<void> signOut() =>
      executeWithInternetCheck(() => ref.read(signOutUseCaseProvider).call(),
          onSuccess: (final _) => state = LoginState());

  // Hesap Silme - ÖNCE Firestore'dan verileri sil, SONRA Auth'tan hesabı sil
  Future<void> deleteAccount() => executeWithInternetCheck(
        () async {
          final currentUserId = state.user?.uid;
          if (currentUserId == null) throw Exception('User ID not found');

          // 1. ÖNCE Firestore'dan kullanıcı verilerini sil
          final userDeleteResult =
              await ref.read(userProvider.notifier).deleteUser(currentUserId);

          if (!userDeleteResult)
            throw Exception('User data could not be deleted from Firestore');

          // 2. Firestore başarıyla silindiyse, şimdi Firebase Auth'tan hesabı sil
          final authDeleteResult =
              await ref.read(deleteAccountUseCaseProvider).call();

          return authDeleteResult;
        },
        onSuccess: (final success) {
          state =
              LoginState().copyWith(isAccountDeleted: true, errorMessage: null);
        },
      );
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifierWithNetworkChecker<LoginState> {
  @override
  LoginState initialState() {
    return LoginState.fromLocalStorage();
  }

  @override
  void reloadData() => getCurrentUser();

  Future<void> initialize() async {
    await LocalStorageService.init();
    if (state.isPersisted || LocalStorageService.isLoggedIn)
      await getCurrentUser();
  }

  Future<void> getCurrentUser() => executeWithInternetCheck(
        () => ref.read(getCurrentUserUseCaseProvider).call(),
        onSuccess: (final user) {
          if (user != null) {
            state = state.copyWith(
              user: user,
              errorMessage: null,
              isPersisted: false,
              userRole: LocalStorageService.userRole, // Rolü state'e aktar
            );
          } else if (LocalStorageService.isLoggedIn && !state.isPersisted)
            _handlePersistedUserNotFound();
        },
      );

  void _handlePersistedUserNotFound() {
    _clearPersistedData();
    state = LoginState();
  }

  Future<void> signInWithGoogle() => executeWithInternetCheck(
        () => ref.read(signInWithGoogleUseCaseProvider).call(),
        onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser),
      );

  Future<void> _handleGoogleSignInSuccess(
      final GoogleSignInAccount? googleUser) async {
    state = state.copyWith(googleUser: googleUser, isGuest: false);

    await executeWithInternetCheck(
      () => ref.read(getCurrentUserUseCaseProvider).call(),
      onSuccess: (final user) async {
        if (user != null) {
          final userRole = RoleManager.getDefaultRoleForLoginMethod('google');

          await LocalStorageService.saveCompleteUserData(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoURL: user.photoURL,
            userRole: userRole,
            isGuest: false,
            userPreferences: {},
          );

          state = state.copyWith(
            isLoading: false,
            user: user,
            errorMessage: null,
            isGuest: false,
            userRole: userRole,
            // Rolü state'e ekle
            isPersisted: false,
          );
        }
      },
    );
  }

  Future<void> signInAnonymously() => executeWithInternetCheck(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
        onSuccess: (final user) async {
          if (user != null) {
            final userRole =
                RoleManager.getDefaultRoleForLoginMethod('anonymous');

            await LocalStorageService.saveCompleteUserData(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              phoneNumber: user.phoneNumber,
              photoURL: user.photoURL,
              userRole: userRole,
              isGuest: true,
              userPreferences: {},
            );

            state = state.copyWith(
              user: user,
              isGuest: true,
              userRole: userRole,
              errorMessage: null,
              isPersisted: false,
            );
          }
        },
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

  Future<void> verifyOtp(final String otp) => executeWithInternetCheck(
        () {
          if (state.verificationId == null) {
            throw Exception('Verification ID not found');
          }
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
      (final user) async {
        if (user != null) {
          final userRole = RoleManager.getDefaultRoleForLoginMethod('phone');

          await LocalStorageService.saveCompleteUserData(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoURL: user.photoURL,
            userRole: userRole,
            isGuest: false,
            userPreferences: {},
          );

          state = state.copyWith(
            user: user,
            phoneNumber: user.phoneNumber,
            isGuest: false,
            isCodeSent: false,
            verificationId: null,
            errorMessage: null,
            userRole: userRole,
            isPersisted: false,
          );
        }
      },
    );
  }

  // ✅ ROL GÜNCELLEME METODU
  Future<void> updateUserRole(final String newRole) async {
    await LocalStorageService.updateUserRole(newRole);
    state = state.copyWith(userRole: newRole);
  }

  Future<void> signOut() => executeWithInternetCheck(
        () => ref.read(signOutUseCaseProvider).call(),
        onSuccess: (final _) async {
          await _clearPersistedData();
          state = LoginState();
        },
      );

  Future<void> deleteAccount() => executeWithInternetCheck(
        () async {
          final currentUserId = state.user?.uid;
          if (currentUserId == null) throw Exception('User ID not found');

          final authDeleteResult =
              await ref.read(deleteAccountUseCaseProvider).call();
          return authDeleteResult;
        },
        onSuccess: (final success) async {
          await _clearPersistedData();
          state =
              LoginState().copyWith(isAccountDeleted: true, errorMessage: null);
        },
      );

  Future<void> _clearPersistedData() async {
    await LocalStorageService.clearAllUserData();
  }
}

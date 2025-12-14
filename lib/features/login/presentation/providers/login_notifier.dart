import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
  @override
  LoginState initialState() {
    return LoginState.fromLocalStorage();
  }

  Future<void> initialize() async {
    await LocalStorageService.init();
    if (state.isPersisted || LocalStorageService.isLoggedIn)
      await getCurrentUser();
  }

  Future<void> getCurrentUser() => execute(
        () => ref.read(getCurrentUserUseCaseProvider).call(),
        onSuccess: (final user) {
          if (user != null)
            state = state.copyWith(
              user: user,
              errorMessage: null,
              isPersisted: false,
              userRole: LocalStorageService.userRole,
            );
          else if (LocalStorageService.isLoggedIn && !state.isPersisted)
            _handlePersistedUserNotFound();
        },
      );

  void _handlePersistedUserNotFound() {
    _clearPersistedData();
    state = LoginState();
  }

  Future<void> signInWithGoogle() => execute(
        () => ref.read(signInWithGoogleUseCaseProvider).call(),
        onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser),
      );

  Future<void> _handleGoogleSignInSuccess(
      final GoogleSignInAccount? googleUser) async {
    state = state.copyWith(googleUser: googleUser, isGuest: false);

    await execute(
      () => ref.read(getCurrentUserUseCaseProvider).call(),
      onSuccess: (final user) async {
        if (user != null) {
          final userRole = RoleManager.getDefaultRoleForLoginMethod('google');

          // ✅ SADECE GEREKLİ BİLGİLERİ KAYDET
          await LocalStorageService.saveEssentialUserData(
              uid: user.uid, displayName: user.displayName, role: userRole);

          state = state.copyWith(
            isLoading: false,
            user: user,
            errorMessage: null,
            isGuest: false,
            userRole: userRole,
            isPersisted: false,
          );
        }
      },
    );
  }

  Future<void> signInAnonymously() => execute(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
        onSuccess: (final user) async {
          if (user != null) {
            final userRole =
                RoleManager.getDefaultRoleForLoginMethod('anonymous');

            // ✅ SADECE GEREKLİ BİLGİLERİ KAYDET
            await LocalStorageService.saveEssentialUserData(
                uid: user.uid, displayName: user.displayName, role: userRole);

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

  Future<void> verifyOtp(final String otp) => execute(
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
      (final user) async {
        if (user != null) {
          final userRole = RoleManager.getDefaultRoleForLoginMethod('phone');

          // ✅ SADECE GEREKLİ BİLGİLERİ KAYDET
          await LocalStorageService.saveEssentialUserData(
            uid: user.uid,
            displayName: user.displayName,
            role: userRole,
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
    await LocalStorageService.saveEssentialUserData(
      uid: state.user!.uid,
      displayName: state.user!.displayName,
      role: newRole,
    );
    state = state.copyWith(userRole: newRole);
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, user: null);

      final result = await ref.read(signOutUseCaseProvider).call();
      result.fold((final failure) {}, (final success) {
        // ✅ STATE'I TAMAMEN SIFIRLA
        state = LoginState(
          user: null,
          googleUser: null,
          isLoading: false,
          errorMessage: null,
          isGuest: false,
          isCodeSent: false,
          verificationId: null,
          phoneNumber: null,
          isPersisted: false,
          userRole: null,
          isAccountDeleted: false,
        );
      });
    } catch (e) {
      // Hata durumunda da state'i sıfırla
      state = LoginState(
        user: null,
        googleUser: null,
        isLoading: false,
        errorMessage: 'Çıkış yapılamadı: $e',
        isGuest: false,
        isCodeSent: false,
        verificationId: null,
        phoneNumber: null,
        isPersisted: false,
        userRole: null,
        isAccountDeleted: false,
      );
    }
  }

  Future<void> deleteAccount() => execute(
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

  Future<void> _clearPersistedData() async => LocalStorageService.clearAllUserData();

  void clearLoginState() => state = LoginState();
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
  // 🚀 DÜZELTME 1: Riverpod 2.0 Notifier yapısında başlangıç noktası build() metodudur.
  // Burada initialize işlemini başlatmamız gerekiyor.
  @override
  LoginState build() {
    // 1. Başlangıç state'ini LocalStorage'dan al (isLoading: true olarak gelir)
    state = LoginState.fromLocalStorage();

    // 2. İşlemi asenkron olarak başlat (Build sırasında çakışmaması için Future.microtask)
    Future.microtask(() => initialize());

    return state;
  }

  // BaseNotifier'dan gelen zorunlu override (Eğer BaseNotifier kullanıyorsan)
  @override
  LoginState initialState() {
    return LoginState.fromLocalStorage();
  }

  Future<void> initialize() async {
    try {
      await LocalStorageService.init();

      if (state.isPersisted || LocalStorageService.isLoggedIn) {
        await getCurrentUser();
      } else {
        // Kullanıcı yok, yüklemeyi bitir.
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // Hata olsa bile sonsuz döngüde kalmamak için loading'i kapat
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> getCurrentUser() => execute(
        () => ref.read(getCurrentUserUseCaseProvider).call(),
        onSuccess: (final user) {
          if (user != null) {
            state = state.copyWith(
              user: user,
              isLoading: false,
              // Yükleme bitti
              errorMessage: null,
              isPersisted: false,
              userRole: LocalStorageService.userRole,
            );
          } else {
            // User null geldiyse (Token süresi dolmuş vs.)
            _handlePersistedUserNotFound();
          }
        },
      );

  void _handlePersistedUserNotFound() {
    _clearPersistedData();
    // Kullanıcı bulunamadıysa sıfırla ve Yüklemeyi Bitir (isLoading: false)
    state = LoginState(isLoading: false);
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

            await LocalStorageService.saveEssentialUserData(
                uid: user.uid, displayName: user.displayName, role: userRole);

            state = state.copyWith(
              user: user,
              isLoading: false,
              // Yükleme bitti
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
            isLoading: false,
          );
        }
      },
    );
  }

  Future<void> updateUserRole(final String newRole) async {
    if (state.user != null) {
      await LocalStorageService.saveEssentialUserData(
        uid: state.user!.uid,
        displayName: state.user!.displayName,
        role: newRole,
      );
      state = state.copyWith(userRole: newRole);
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, user: null);

      final result = await ref.read(signOutUseCaseProvider).call();
      result.fold((final failure) {
        // Hata olsa bile local'de çıkış yapılmış gibi davran
        _resetState();
      }, (final success) {
        _resetState();
      });
    } catch (e) {
      _resetState(errorMessage: 'Çıkış yapılamadı: $e');
    }
  }

  // State'i sıfırlayan yardımcı metod
  void _resetState({String? errorMessage}) {
    state = LoginState(
      user: null,
      googleUser: null,
      isLoading: false,
      // Yükleme bitti
      errorMessage: errorMessage,
      isGuest: false,
      isCodeSent: false,
      verificationId: null,
      phoneNumber: null,
      isPersisted: false,
      userRole: null,
      isAccountDeleted: false,
    );
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
          state = LoginState(isLoading: false)
              .copyWith(isAccountDeleted: true, errorMessage: null);
        },
      );

  Future<void> _clearPersistedData() async =>
      LocalStorageService.clearAllUserData();

  void clearLoginState() => state = LoginState(isLoading: false);
}

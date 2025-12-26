import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/common/base_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/util/app_debug.dart';
import '../../../../core/util/role_manager.dart';
import 'login_state.dart';

/// 🔐 Login Notifier - Complete Auth Management
///
/// ⚠️ ÖNEMLI: Bu notifier AutoDispose KULLANMAZ çünkü:
/// - Auth state her zaman aktif olmalı
/// - Uygulama boyunca erişilebilir olmalı
/// - Sayfa değişimlerinde kaybolmamalı
class LoginNotifier extends BaseNotifier<LoginState> {
  // Services
  late final AuthService _authService;
  late final UserDataService _userDataService;

  // Subscriptions
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _timer;

  // Flags
  bool _isManualSignOut = false;
  bool _isInitialized = false;

  @override
  LoginState initialState() {
    _initializeServices();
    _startAuthListener();
    return LoginState.loading();
  }

  @override
  void onDispose() {
    _authStateSubscription?.cancel();
    _timer?.cancel();
    AppDebug.log("LoginNotifier disposed", tag: "AUTH");
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  void _initializeServices() {
    _authService = AuthService();
    _userDataService = UserDataService();
  }

  Future<void> _startAuthListener() async {
    try {
      await LocalStorageService.init();

      // Safety timeout (10 seconds)
      Future.delayed(const Duration(seconds: 10), () {
        if (state.isLoading && _isInitialized) {
          state = LoginState.loggedOut();
          AppDebug.log("Auth initialization timeout", tag: "AUTH");
        }
      });

      // Listen to auth state changes
      _authStateSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (final error) {
          AppDebug.log("Auth state error: $error", tag: "AUTH");
          setErrorState(error.toString());
        },
      );

      _isInitialized = true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  // ========================================
  // AUTH STATE HANDLER
  // ========================================

  Future<void> _handleAuthStateChange(final User? firebaseUser) async {
    if (_isManualSignOut) {
      AppDebug.log("Manual sign out detected, skipping listener", tag: "AUTH");
      _isManualSignOut = false;
      return;
    }

    if (firebaseUser != null)
      await _handleUserLogin(firebaseUser);
    else
      await _handleUserLogout();
  }

  Future<void> _handleUserLogin(final User firebaseUser) async {
    try {
      // Reload user to get latest data
      await firebaseUser.reload();
      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        await _handleUserLogout();
        return;
      }

      // Get user role
      String userRole = LocalStorageService.userRole ?? 'user';
      if (refreshedUser.isAnonymous)
        userRole = RoleManager.getDefaultRoleForLoginMethod('anonymous');

      // Update state
      state = LoginState.fromUser(refreshedUser, userRole);

      // Save to local storage
      await LocalStorageService.saveUserData(
        userId: refreshedUser.uid,
        displayName: refreshedUser.displayName ?? 'User',
        email: refreshedUser.email ?? '',
        photoUrl: refreshedUser.photoURL ?? '',
        role: userRole,
        isGuest: refreshedUser.isAnonymous,
      );

      // Save FCM token
      await _authService.saveFcmToken(refreshedUser.uid);

      // Sync to Firestore (if not anonymous)
      if (!refreshedUser.isAnonymous)
        await _syncUserToFirestore(refreshedUser, userRole);

      AppDebug.log("Login successful: ${refreshedUser.uid}", tag: "AUTH");
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  Future<void> _handleUserLogout() async {
    state = LoginState.loggedOut();
    AppDebug.log("User logged out", tag: "AUTH");
  }

  // ========================================
  // SIGN IN METHODS
  // ========================================

  /// 🔐 Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      setLoadingState(true);
      clearErrorState();

      final user = await _authService.signInWithGoogle();

      if (user == null) {
        setErrorState('Google sign in cancelled');
        return false;
      }

      // Auth listener will handle the rest
      return true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Google sign in failed: ${e.toString()}');
      return false;
    }
  }

  /// 📱 Verify phone number
  Future<void> verifyPhone(final String phoneNumber) async {
    try {
      setLoadingState(true);
      clearErrorState();

      String phone = phoneNumber.trim();
      if (!phone.startsWith("+"))
        phone = "+90$phone";

      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationCompleted: (final credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        onCodeSent: (final verificationId, final resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            isCodeSent: true,
            isLoading: false,
            timerValue: 180,
            phoneNumber: phone,
            errorMessage: null,
          );
          _startTimer();
        },
        onVerificationFailed: (final error) {
          setErrorState(error);
        },
        onAutoRetrievalTimeout: (final verificationId) {
          state = state.copyWith(
            verificationId: verificationId,
            errorMessage: null,
          );
        },
      );
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Phone verification failed: ${e.toString()}');
    }
  }

  /// 📱 Verify OTP code
  Future<bool> verifyOtp(final String smsCode) async {
    try {
      if (state.verificationId == null) {
        setErrorState('No verification ID');
        return false;
      }

      setLoadingState(true);
      clearErrorState();

      final user = await _authService.signInWithPhoneCredential(
        state.verificationId!,
        smsCode,
      );

      if (user == null) {
        setErrorState('Invalid verification code');
        return false;
      }

      // Auth listener will handle the rest
      return true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Invalid code: ${e.toString()}');
      return false;
    }
  }

  /// 👤 Sign in anonymously
  Future<bool> signInAnonymously() async {
    try {
      setLoadingState(true);
      clearErrorState();

      final user = await _authService.signInAnonymously();

      if (user == null) {
        setErrorState('Anonymous sign in failed');
        return false;
      }

      // Auth listener will handle the rest
      return true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Anonymous sign in failed: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // SIGN OUT & DELETE
  // ========================================

  /// 🚪 Sign out
  Future<bool> signOut() async {
    try {
      setLoadingState(true);
      clearErrorState();
      _isManualSignOut = true;

      final userId = _authService.currentUser?.uid;

      // Clear FCM token
      if (userId != null)
        await _authService.clearFcmToken(userId);

      // Clear local storage
      await LocalStorageService.clearAllUserData();

      // Cancel timer
      _timer?.cancel();

      // Sign out
      await _authService.signOut();

      // Update state
      state = LoginState.loggedOut();

      AppDebug.log("Sign out successful", tag: "AUTH");
      return true;
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState('Sign out failed: ${e.toString()}');
      return false;
    }
  }

  /// 🗑️ Delete account completely
  Future<bool> deleteAccount() async {
    try {
      setLoadingState(true);
      clearErrorState();
      _isManualSignOut = true;

      final userId = _authService.currentUser?.uid;

      if (userId == null)
        throw Exception("No user to delete");

      AppDebug.log("Starting complete account deletion: $userId", tag: "AUTH");

      // 1. Clear FCM token
      await _authService.clearFcmToken(userId);

      // 2. Delete user data from Firestore (including tickets)
      await _userDataService.deleteUserCompletely(userId);

      // 3. Clear local storage
      await LocalStorageService.clearAllUserData();

      // 4. Cancel timer
      _timer?.cancel();

      // 5. Delete Firebase Auth account
      await _authService.deleteAccount();

      // 6. Update state
      state = LoginState.loggedOut().copyWith(isAccountDeleted: true);

      AppDebug.log("Account deleted completely: $userId", tag: "AUTH");
      return true;
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState('Delete account failed: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Sync user to Firestore
  Future<void> _syncUserToFirestore(final User user, final String role) async {
    try {
      // Check if user exists
      final exists = await _userDataService.userExists(user.uid);

      await _userDataService.syncUserFromAuth(
        userId: user.uid,
        displayName: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        phoneNumber: user.phoneNumber ?? '',
        role: role,
        isPhoneActive: user.phoneNumber != null,
      );

      AppDebug.log("User synced to Firestore: ${user.uid} (new: ${!exists})",
          tag: "AUTH");
    } catch (e, stack) {
      logError(e, stack);
      // Don't throw, just log
    }
  }

  /// Start resend timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (state.timerValue <= 0) {
        timer.cancel();
        state = state.copyWith(canResendCode: true, timerValue: 0);
      } else
        state = state.copyWith(timerValue: state.timerValue - 1);
    });
  }

  /// Clear error (override from BaseNotifier to return void)
  void clearError() {
    clearErrorState();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.reloadUser();
      await _handleUserLogin(user);
    }
  }
}

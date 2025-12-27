import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/common/base_notifier.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/util/role_manager.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_data_service.dart';
import 'login_state.dart';

/// 🔐 Login Notifier - Complete Auth Management
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

      // ⚡ 1. EMNİYET KİLİDİ: İnternet yoksa 5 saniye sonra siyah ekranı kırar.
      Future.delayed(const Duration(seconds: 5), () {
        if (ref.mounted && state.isLoading) {
          state = state.copyWith(
              isLoading: false,
              errorMessage:
                  "Bağlantı kurulamadı. Lütfen internetinizi kontrol edin.");
        }
      });

      // 2. Mevcut kullanıcıyı manuel kontrol et (Stream beklemeden)
      final User? initialUser = _authService.currentUser;
      if (initialUser != null)
        await _handleUserLogin(initialUser);
      else
        state = LoginState.loggedOut();

      // 3. Stream dinleyicisi
      _authStateSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (final error) => setErrorState("Bağlantı Hatası: $error"),
      );

      _isInitialized = true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // ========================================
  // AUTH STATE HANDLER
  // ========================================

  Future<void> _handleAuthStateChange(final User? firebaseUser) async {
    if (_isManualSignOut) {
      _isManualSignOut = false;
      return;
    }

    if (firebaseUser != null)
      await _handleUserLogin(firebaseUser);
    else
      await _handleUserLogout();
  }

  Future<void> _handleUserLogin(final User firebaseUser) async {
    // ⚡ KRİTİK KİLİT: Eğer kullanıcı telefonla bağlanıyorsa
    // ve biz henüz OTP (SMS) doğrulama aşamasındaysak (isCodeSent true ise),
    // otomatik login işlemini burada DURDUR.
    if (firebaseUser.phoneNumber != null && state.isCodeSent) {
      debugPrint("Otomatik login engellendi, SMS onayı bekleniyor...");
      return;
    }

    try {
      await firebaseUser.reload();
      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        await _handleUserLogout();
        return;
      }

      String userRole = LocalStorageService.userRole ?? 'user';

      // State'i sadece her şey tamamsa güncelle
      state = LoginState.fromUser(refreshedUser, userRole);

      await LocalStorageService.saveUserData(
        userId: refreshedUser.uid,
        displayName: refreshedUser.displayName ?? 'User',
        email: refreshedUser.email ?? '',
        photoUrl: refreshedUser.photoURL ?? '',
        role: userRole,
        isGuest: refreshedUser.isAnonymous,
      );

      await _authService.saveFcmToken(refreshedUser.uid);

      if (!refreshedUser.isAnonymous) {
        await _syncUserToFirestore(refreshedUser, userRole);
      }
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  Future<void> _handleUserLogout() async => state = LoginState.loggedOut();

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

  // login_notifier.dart
  Future<void> verifyPhone(final String phoneNumber) async {
    try {
      setLoadingState(true);
      clearErrorState();

      String phone = phoneNumber.trim();
      // ⚡ İyileştirme: Numara formatını daha esnek yapın
      if (!phone.startsWith("+")) {
        if (phone.startsWith("0")) phone = phone.substring(1);
        phone = "+90$phone";
      }

      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationCompleted: (final credential) async {
          // Otomatik doğrulama başarılı olursa burada login olur
          final user =
              await FirebaseAuth.instance.signInWithCredential(credential);
          if (user.user != null) {
            await _handleUserLogin(user.user!);
          }
        },
        onCodeSent: (final verificationId, final resendToken) {
          // ⚡ BURASI KRİTİK: isCodeSent true olduğunda redirect bizi atmamalı
          state = state.copyWith(
            verificationId: verificationId,
            isCodeSent: true,
            isLoading: false,
            // Loading biter, isCodeSent başlar
            timerValue: 60,
            // Genelde 60 saniye idealdir
            phoneNumber: phone,
          );
          _startTimer();
        },
        onVerificationFailed: (final error) {
          state = state.copyWith(isLoading: false, errorMessage: error);
        },
        onAutoRetrievalTimeout: (final verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Hata: ${e.toString()}');
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
      if (userId != null) await _authService.clearFcmToken(userId);

      // Clear local storage
      await LocalStorageService.clearAllUserData();

      // Cancel timer
      _timer?.cancel();

      // Sign out
      await _authService.signOut();

      // Update state
      state = LoginState.loggedOut();

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

      if (userId == null) throw Exception("No user to delete");

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

  // login_notifier.dart içinde
  void refreshUserState(final entity.User updatedUser) {
    state = state.copyWith(
      displayName: '${updatedUser.firstName} ${updatedUser.lastName}',
      photoUrl: updatedUser.imageUrl,
      email: updatedUser.eMail,
      phoneNumber: updatedUser.phoneNumber,
      city: updatedUser.city,
    );
  }

  /// Clear error (override from BaseNotifier to return void)
  void clearError() => clearErrorState();

  /// Refresh user data
  Future<void> refreshUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.reloadUser();
      await _handleUserLogin(user);
    }
  }
}

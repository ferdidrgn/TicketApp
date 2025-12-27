import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // EKLENDİ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/common/base_notifier.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_data_service.dart';
import 'login_state.dart';

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

  void _initializeServices() {
    _authService = AuthService();
    _userDataService = UserDataService();
  }

  Future<void> _startAuthListener() async {
    try {
      await LocalStorageService.init();

      Future.delayed(const Duration(seconds: 5), () {
        if (ref.mounted && state.isLoading) {
          state = state.copyWith(
              isLoading: false,
              errorMessage:
                  "Bağlantı kurulamadı. Lütfen internetinizi kontrol edin.");
        }
      });

      final User? initialUser = _authService.currentUser;
      if (initialUser != null) {
        await _handleUserLogin(initialUser);
      } else {
        state = LoginState.loggedOut();
      }

      _authStateSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (final error) => setErrorState("Bağlantı Hatası: $error"),
      );

      _isInitialized = true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _handleAuthStateChange(final User? firebaseUser) async {
    if (_isManualSignOut) {
      _isManualSignOut = false;
      return;
    }
    if (firebaseUser != null) {
      await _handleUserLogin(firebaseUser);
    } else {
      await _handleUserLogout();
    }
  }

  Future<void> _handleUserLogin(final User firebaseUser) async {
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

      if (!refreshedUser.isAnonymous)
        await _syncUserToFirestore(refreshedUser, userRole);
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  Future<void> _handleUserLogout() async => state = LoginState.loggedOut();

  // ========================================
  // SIGN IN & AUTH METHODS
  // ========================================

  Future<bool> signInWithGoogle() async {
    try {
      setLoadingState(true);
      clearErrorState();
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        setErrorState('Google sign in cancelled');
        return false;
      }
      return true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Google sign in failed: ${e.toString()}');
      return false;
    }
  }

  Future<void> verifyPhone(final String phoneNumber) async {
    try {
      setLoadingState(true);
      clearErrorState();
      String phone = phoneNumber.trim();
      if (!phone.startsWith("+")) {
        if (phone.startsWith("0")) phone = phone.substring(1);
        phone = "+90$phone";
      }

      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationCompleted: (final credential) async {
          final user =
              await FirebaseAuth.instance.signInWithCredential(credential);
          if (user.user != null) await _handleUserLogin(user.user!);
        },
        onCodeSent: (final verificationId, final resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            isCodeSent: true,
            isLoading: false,
            timerValue: 60,
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

  Future<bool> verifyOtp(final String smsCode) async {
    try {
      if (state.verificationId == null) {
        setErrorState('No verification ID');
        return false;
      }
      setLoadingState(true);
      clearErrorState();
      final user = await _authService.signInWithPhoneCredential(
          state.verificationId!, smsCode);
      if (user == null) {
        setErrorState('Invalid verification code');
        return false;
      }
      return true;
    } catch (e, stack) {
      logError(e, stack);
      setErrorState('Invalid code: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // SIGN OUT & DELETE (GÜNCELLENDİ)
  // ========================================

  Future<bool> signOut() async {
    try {
      setLoadingState(true);
      clearErrorState();
      _isManualSignOut = true;
      final userId = _authService.currentUser?.uid;
      if (userId != null) await _authService.clearFcmToken(userId);
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      await _authService.signOut();
      state = LoginState.loggedOut();
      return true;
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState('Sign out failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      setLoadingState(true);
      clearErrorState();
      _isManualSignOut = true;

      final user = _authService.currentUser;
      if (user == null) throw Exception("No user to delete");
      final String userId = user.uid;

      // 1. FCM temizle
      await _authService.clearFcmToken(userId);

      // 2. Firestore ve Tüm Verileri sil (UserDataService üzerinden)
      await _userDataService.deleteUserCompletely(userId);

      // 3. Yerel hafızayı temizle
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();

      // 4. Auth hesabını sil
      await _authService.deleteAccount();

      state = LoginState.loggedOut().copyWith(isAccountDeleted: true);
      return true;
    } on FirebaseAuthException catch (e) {
      _isManualSignOut = false;
      if (e.code == 'requires-recent-login')
        setErrorState('Güvenlik için yeniden giriş yapmalısınız.');
      else
        setErrorState(e.message ?? 'Hesap silinemedi.');
      return false;
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState('Delete account failed: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // HELPERS
  // ========================================

  Future<void> _syncUserToFirestore(final User user, final String role) async {
    try {
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
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (state.timerValue <= 0) {
        timer.cancel();
        state = state.copyWith(canResendCode: true, timerValue: 0);
      } else {
        state = state.copyWith(timerValue: state.timerValue - 1);
      }
    });
  }

  void refreshUserState(final entity.User updatedUser) {
    state = state.copyWith(
      displayName: '${updatedUser.firstName} ${updatedUser.lastName}',
      photoUrl: updatedUser.imageUrl,
      email: updatedUser.eMail,
      phoneNumber: updatedUser.phoneNumber,
      city: updatedUser.city,
    );
  }

  void clearError() => clearErrorState();

  Future<void> refreshUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      await user.reload();
      await _handleUserLogin(user);
    }
  }
}

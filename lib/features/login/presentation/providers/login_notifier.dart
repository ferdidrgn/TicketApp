import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/common/base_notifier.dart';
import '../../../../core/common/enum/enums.dart';
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
      _authStateSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (final error) => setErrorState("Bağlantı Hatası: $error"),
      );

      final User? initialUser = _authService.currentUser;
      if (initialUser != null)
        await _handleUserLogin(initialUser);
      else
        state = LoginState.loggedOut();

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
    if (firebaseUser != null)
      await _handleUserLogin(firebaseUser);
    else
      await _handleUserLogout();
  }

  Future<void> _handleUserLogin(final User firebaseUser) async {
    try {
      await firebaseUser.reload();
      final refreshedUser = _authService.currentUser;
      if (refreshedUser == null) return;

      // Anonim giriş engeli: Eğer gelen kullanıcı anonimse direkt çıkış yap
      if (refreshedUser.isAnonymous) {
        await _authService.signOut();
        state = LoginState.loggedOut();
        return;
      }

      final UserRole userRole = await LocalStorageService.userRole;

      // state.copyWith veya LoginState.fromUser metodunuzun UserRole kabul ettiğinden emin olun
      state = LoginState.fromUser(refreshedUser, userRole.name);

      await LocalStorageService.saveUserData(
        userId: refreshedUser.uid,
        displayName: refreshedUser.displayName ?? 'Kullanıcı',
        email: refreshedUser.email ?? '',
        photoUrl: refreshedUser.photoURL ?? '',
        role: userRole,
      );
    } catch (e) {
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

  /// 👤 Anonim Giriş ve Veri Kaydı
  Future<bool> signInAnonymously() async {
    try {
      setLoadingState(true);
      clearErrorState();

      final user = await _authService.signInAnonymously();
      if (user == null) {
        setErrorState('Anonim giriş başarısız.');
        return false;
      }

      const UserRole role = UserRole.guest;

      // 1. FCM Token kaydet
      await _authService.saveFcmToken(user.uid);

      // 2. Firestore üzerinde "Ziyaretçi" dökümanı oluştur
      await _userDataService.syncUserFromAuth(
        userId: user.uid,
        displayName: 'Ziyaretçi',
        email: '',
        photoUrl: '',
        phoneNumber: '',
        role: role.name,
        isPhoneActive: false,
      );

      await LocalStorageService.saveUserData(
        userId: user.uid,
        displayName: 'Ziyaretçi',
        email: '',
        photoUrl: '',
        role: role,
      );

      return true;
    } catch (e) {
      setErrorState(e.toString());
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

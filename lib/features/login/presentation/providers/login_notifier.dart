import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/common/base_notifier.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/util/app_debug.dart';
import '../../../../core/util/role_manager.dart';
import '../../../users/data/models/user_model.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_provider.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _timer;
  bool _isManualSignOut = false;

  @override
  LoginState initialState() {
    // Başlatmayı güvenli bir şekilde tetikle
    Future.microtask(() => initialize());
    return LoginState(isLoading: true);
  }

  @override
  void onDispose() {
    _authStateSubscription?.cancel();
    _timer?.cancel();
    AppDebug.log("LoginNotifier temizlendi.", tag: "AUTH");
  }

  // --- BAŞLATMA ---
  Future<void> initialize() async {
    try {
      // 10 Saniyelik Güvenlik Kilidi (Splash'te asılı kalmayı önler)
      Future.delayed(const Duration(seconds: 10), () {
        if (state.isLoading) {
          state = state.copyWith(isLoading: false);
          AppDebug.log("Zaman aşımı: Yükleme ekranı zorla kapatıldı.",
              tag: "AUTH");
        }
      });

      await LocalStorageService.init();
      await _setupAuthListener();
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  Future<void> _setupAuthListener() async {
    await _authStateSubscription?.cancel();

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (final firebaseUser) async {
        if (_isManualSignOut) {
          AppDebug.log("Manuel çıkış algılandı, listener atlanıyor.",
              tag: "AUTH");
          _isManualSignOut = false;
          return;
        }
        await _handleAuthStateChange(firebaseUser);
      },
      onError: (final error) {
        logError(error);
        setErrorState(error.toString());
      },
    );
  }

  // --- KULLANICI DURUM YÖNETİMİ ---
  Future<void> _handleAuthStateChange(final User? firebaseUser) async {
    if (firebaseUser != null)
      await _handleUserLogin(firebaseUser);
    else
      await _handleUserLogout();
  }

  Future<void> _handleUserLogin(final User firebaseUser) async {
    try {
      await firebaseUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        await _handleUserLogout();
        return;
      }

      String userRole = LocalStorageService.userRole ?? 'user';
      if (refreshedUser.isAnonymous)
        userRole = RoleManager.getDefaultRoleForLoginMethod('anonymous');

      state = state.copyWith(
        user: refreshedUser,
        isLoading: false,
        isGuest: refreshedUser.isAnonymous,
        userRole: userRole,
        errorMessage: null,
      );

      await LocalStorageService.saveEssentialUserData(
        uid: refreshedUser.uid,
        displayName: refreshedUser.displayName,
        role: userRole,
      );

      await _saveFcmToken(refreshedUser.uid);

      if (!refreshedUser.isAnonymous)
        await _syncUserWithFirestore(refreshedUser, userRole);

      AppDebug.log("Giriş başarılı: ${refreshedUser.uid}", tag: "AUTH");
    } catch (e, stack) {
      logError(e, stack);
      setErrorState(e.toString());
    }
  }

  Future<void> _handleUserLogout() async {
    state = LoginState(isLoading: false);
    AppDebug.log("Oturum kapatıldı.", tag: "AUTH");
  }

  // --- TÜM AUTH METODLARI (UI Hatalarını Çözer) ---

  Future<void> verifyPhone(final String phoneNumber) async {
    setLoadingState(true);
    String phone = phoneNumber.trim();
    if (!phone.startsWith("+")) phone = "+90$phone";

    try {
      await ref.read(verifyPhoneUseCaseProvider).call(
            phoneNumber: phone,
            onVerificationCompleted: (final credential) async {
              await FirebaseAuth.instance.signInWithCredential(credential);
            },
            onCodeSent: (final String vId, final int? resendToken) {
              state = state.copyWith(
                verificationId: vId,
                isCodeSent: true,
                isLoading: false,
                timerValue: 180,
                phoneNumber: phone,
              );
              _startTimer();
            },
            onAutoRetrievalTimeout: (final String vId) {
              state = state.copyWith(verificationId: vId);
            },
          );
    } catch (e, stack) {
      logError(e, stack);
      setErrorState("SMS gönderilemedi.");
    }
  }

  Future<void> verifyOtp(final String otp) async {
    if (state.verificationId == null) return;
    await execute<bool>(
      () => ref.read(verifyOtpUseCaseProvider).call(state.verificationId!, otp),
      onSuccess: (final isVerified) {
        if (!isVerified) setErrorState("Hatalı kod.");
      },
    );
  }

  Future<void> signInWithGoogle() async {
    setLoadingState(true);
    final result = await ref.read(signInWithGoogleUseCaseProvider).call();
    result.fold(
      (final failure) => setErrorState(failure.message),
      (final user) => AppDebug.log("Google Login Başarılı", tag: "AUTH"),
    );
  }

  Future<void> signInAnonymously() async {
    await execute(
      () => ref.read(signInAnonymouslyUseCaseProvider).call(),
      onSuccess: (final _) =>
          AppDebug.log("Anonim giriş başarılı", tag: "AUTH"),
    );
  }

  Future<void> signOut() async {
    try {
      setLoadingState(true);
      _isManualSignOut = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) await _clearFcmToken(userId);
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      await FirebaseAuth.instance.signOut();

      _handleUserLogout();
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState("Çıkış hatası.");
    }
  }

  Future<void> deleteAccount() async {
    try {
      setLoadingState(true);
      _isManualSignOut = true;
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      if (userId != null) {
        await _clearFcmToken(userId);
        await FirebaseFirestore.instance
            .collection('User')
            .doc(userId)
            .delete();
      }

      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      await user?.delete();

      state = LoginState(isLoading: false, isAccountDeleted: true);
      AppDebug.log("Hesap silindi.", tag: "AUTH");
    } catch (e, stack) {
      _isManualSignOut = false;
      logError(e, stack);
      setErrorState("Hesap silinemedi.");
    }
  }

  // --- YARDIMCI METODLAR ---

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

  Future<void> _saveFcmToken(final String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('User').doc(userId).set({
          'fcmToken': token,
          '_updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      logError(e);
    }
  }

  Future<void> _clearFcmToken(final String userId) async {
    try {
      await FirebaseFirestore.instance.collection('User').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      logError(e);
    }
  }

  Future<void> _syncUserWithFirestore(
      final User firebaseUser, final String role) async {
    try {
      final nameParts = _splitName(firebaseUser.displayName ?? '');
      final userEntity = entity.User(
        id: firebaseUser.uid,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: nameParts['firstName'] ?? '',
        lastName: nameParts['lastName'] ?? '',
        imageUrl: firebaseUser.photoURL ?? '',
        eMail: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        role: role,
        age: 0,
        city: '',
        isPhoneActive: firebaseUser.phoneNumber != null,
        fcmToken: '',
        favoriteShows: const [],
        favoriteStages: const [],
        favoritePlayers: const [],
        ticketsId: const [],
      );

      await ref.read(saveUserUseCaseProvider).call(
            UserModel.fromEntity(userEntity),
            firebaseUser.photoURL ?? '',
            isUpdate: false,
          );
    } catch (e) {
      logError(e);
    }
  }

  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};
    return {
      'firstName': parts.sublist(0, parts.length - 1).join(' '),
      'lastName': parts.last,
    };
  }
}

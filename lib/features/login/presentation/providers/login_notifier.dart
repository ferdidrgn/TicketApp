import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import '../../../users/data/models/user_model.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_provider.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _timer;

  @override
  LoginState build() {
    // Başlangıçta local storage kontrolü yaparak state'i yükle
    state = LoginState.fromLocalStorage();
    Future.microtask(() => initialize());
    return state;
  }

  @override
  LoginState initialState() => LoginState(isLoading: true);

  // --- BAŞLATMA VE AUTH TAKİBİ ---
  Future<void> initialize() async {
    await LocalStorageService.init();
    await _authStateSubscription?.cancel();

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (final User? firebaseUser) async {
        await _updateStateWithUser(firebaseUser);
      },
      onError: (final error) {
        state =
            state.copyWith(isLoading: false, errorMessage: error.toString());
      },
    );
  }

  // --- KULLANICI DURUM GÜNCELLEME ---
  Future<void> _updateStateWithUser(final User? firebaseUser) async {
    if (firebaseUser != null) {
      await firebaseUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      String userRole = LocalStorageService.userRole ?? 'user';
      if (refreshedUser!.isAnonymous) {
        userRole = RoleManager.getDefaultRoleForLoginMethod('anonymous');
      }

      state = state.copyWith(
        user: refreshedUser,
        isLoading: false,
        isGuest: refreshedUser.isAnonymous,
        userRole: userRole,
        errorMessage: null,
      );

      // Local storage verilerini kaydet
      await LocalStorageService.saveEssentialUserData(
        uid: refreshedUser.uid,
        displayName: refreshedUser.displayName,
        role: userRole,
      );

      // FCM Token'ı veritabanına kaydet (Önemli!)
      await _saveFcmToken(refreshedUser.uid);

      if (!refreshedUser.isAnonymous)
        await _syncUserWithFirestore(refreshedUser, userRole);
    } else
      state = state.copyWith(
          user: null, isLoading: false, isGuest: false, isCodeSent: false);
  }

  // --- TELEFON GİRİŞ SÜRECİ (OTP) ---

  // 1. SMS Gönderimi
  Future<void> verifyPhone(final String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Telefon numarasını düzenle (+90 ekle)
    String phone = phoneNumber.trim();
    if (!phone.startsWith("+")) phone = "+90$phone";

    await ref.read(verifyPhoneUseCaseProvider).call(
          phoneNumber: phone,
          onVerificationCompleted: (final credential) async {
            // Android bazen SMS'i otomatik okur ve direkt giriş yapar
            await FirebaseAuth.instance.signInWithCredential(credential);
          },
          onCodeSent: (final verificationId, final resendToken) {
            state = state.copyWith(
              verificationId: verificationId,
              isCodeSent: true,
              isLoading: false,
              timerValue: 180,
              canResendCode: false,
            );
            _startTimer();
          },
          onAutoRetrievalTimeout: (final verificationId) {
            state = state.copyWith(verificationId: verificationId);
          },
        );
  }

  // 2. OTP Doğrulama (Kullanıcının girdiği kodla giriş)
  Future<void> verifyOtp(final String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(errorMessage: "Doğrulama kimliği bulunamadı.");
      return;
    }

    await execute<bool>(
      () => ref.read(verifyOtpUseCaseProvider).call(state.verificationId!, otp),
      onSuccess: (final isVerified) async {
        if (isVerified) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.reload();
            await _updateStateWithUser(FirebaseAuth.instance.currentUser);
          }
        } else
          state =
              state.copyWith(errorMessage: "Hatalı veya süresi dolmuş kod.");
      },
    );
  }

  // 3. Sayaç Yönetimi
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

  // --- GOOGLE VE ANONİM GİRİŞ ---
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await ref.read(signInWithGoogleUseCaseProvider).call();
      result.fold(
        (final failure) => state =
            state.copyWith(isLoading: false, errorMessage: failure.message),
        (final googleUser) async {
          if (googleUser != null)
            await _updateStateWithUser(FirebaseAuth.instance.currentUser);
          state = state.copyWith(isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signInAnonymously() =>
      execute(() => ref.read(signInAnonymouslyUseCaseProvider).call());

  // FCM Token'ı veritabanından silen yardımcı metot
  Future<void> _clearFcmToken(final String userId) async {
    try {
      await FirebaseFirestore.instance.collection('User').doc(userId).update({
        'fcmToken': FieldValue.delete(), // Token alanını siler
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ("Token silinirken hata oluştu: $e");
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _clearFcmToken(userId); // 🎯 Çıkıştan önce token'ı temizle
      }

      await ref.read(signOutUseCaseProvider).call();
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      state = LoginState(
          user: null, isLoading: false, isGuest: false, isCodeSent: false);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Çıkış hatası: $e');
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Auth'tan silmeden önce her şeyi temizle
      if (userId != null) {
        await _clearFcmToken(userId); // 🎯 Token'ı temizle
      }

      await ref.read(deleteAccountUseCaseProvider).call();
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      state = LoginState(user: null, isLoading: false, isGuest: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Hesap silme hatası: $e');
    }
  }

  // --- YARDIMCI METODLAR (TOKEN & SYNC) ---

  Future<void> _saveFcmToken(final String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('User').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw ("FCM Token kaydedilemedi: $e");
    }
  }

  Future<void> _syncUserWithFirestore(
      final User firebaseUser, final String role) async {
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
    final userModel = UserModel.fromEntity(userEntity);
    await ref
        .read(saveUserUseCaseProvider)
        .call(userModel, firebaseUser.photoURL ?? '', isUpdate: false);
  }

  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};
    final List<String> parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};
    return {
      'firstName': parts.sublist(0, parts.length - 1).join(' '),
      'lastName': parts.last
    };
  }
}

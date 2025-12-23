import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  @override
  LoginState build() {
    state = LoginState(isLoading: true);
    Future.microtask(() => initialize());
    return state;
  }

  @override
  LoginState initialState() => LoginState(isLoading: true);

  /// Uygulama başladığında Auth durumunu dinler ve kullanıcıyı senkronize eder.
  Future<void> initialize() async {
    await LocalStorageService.init();

    await _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (final User? firebaseUser) async {
        if (firebaseUser != null) {
          String userRole = LocalStorageService.userRole ?? 'user';
          if (firebaseUser.isAnonymous) {
            userRole = RoleManager.getDefaultRoleForLoginMethod('anonymous');
          }

          state = state.copyWith(
            user: firebaseUser,
            isLoading: false,
            isGuest: firebaseUser.isAnonymous,
            userRole: userRole,
            errorMessage: null,
          );

          await LocalStorageService.saveEssentialUserData(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            role: userRole,
          );

          // Misafir değilse Firestore ile senkronize et
          if (!firebaseUser.isAnonymous) {
            await _syncUserWithFirestore(firebaseUser, userRole);
          }
        } else {
          state = state.copyWith(user: null, isLoading: false, isGuest: false);
        }
      },
      onError: (final error) {
        state =
            state.copyWith(isLoading: false, errorMessage: error.toString());
      },
    );

    // Bağlantı gecikmesi durumunda sonsuz yüklemeyi önler
    Future.delayed(const Duration(seconds: 4), () {
      if (state.isLoading) state = state.copyWith(isLoading: false);
    });
  }

  /// Firebase kullanıcısını Domain Entity'e çevirip veritabanına kaydeder (Mevcutsa güncellemez).
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
      isPhoneActive: false,
      fcmToken: '',
      favoriteShows: const [],
      favoriteStages: const [],
      favoritePlayers: const [],
      ticketsId: const [],
    );

    final userModel = UserModel.fromEntity(userEntity);

    await ref.read(saveUserUseCaseProvider).call(
        userModel, firebaseUser.photoURL ?? '',
        isUpdate: false // Kullanıcı varsa üzerine yazma
        );
  }

  /// Google ile giriş işlemini başlatır.
  Future<void> signInWithGoogle() => execute<GoogleSignInAccount?>(
        () => ref.read(signInWithGoogleUseCaseProvider).call(),
        onSuccess: (final googleUser) {
          if (googleUser == null) {
            // Kullanıcı pencereyi kapattı (Vazgeçti).
            // BaseNotifier otomatik olarak isLoading = false yapacak.
            // Ekstra bir şey yapmamıza gerek yok.
            print("Google girişi kullanıcı tarafından iptal edildi.");
            return;
          }

          // Giriş başarılı olduysa 'initialize' metodundaki
          // Auth Listener (authStateChanges) otomatik devreye girecek
          // ve Firestore kaydını yapacaktır.
        },
      );

  /// Misafir girişi işlemini başlatır.
  Future<void> signInAnonymously() => execute(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
        onSuccess: (final user) {
          // Başarılı olursa initialize'daki listener yakalar.
        },
      );

  /// Telefon numarasına doğrulama kodu gönderir.
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

  /// Kullanıcının girdiği OTP kodunu doğrular.
  Future<void> verifyOtp(final String otp) => execute(
        () {
          if (state.verificationId == null)
            throw Exception('Verification ID not found');
          return ref
              .read(verifyOtpUseCaseProvider)
              .call(state.verificationId!, otp);
        },
        onSuccess: (final success) {
          if (!success) state = state.copyWith(errorMessage: "Invalid OTP");
        },
      );

  /// Kullanıcı rolünü günceller (Örn: Premium üyeliğe geçiş).
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

  /// Oturumdan çıkış yapar.
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await ref.read(signOutUseCaseProvider).call();
    } catch (e) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Çıkış hatası: $e');
    }
  }

  /// Hesabı tamamen siler.
  Future<void> deleteAccount() => execute(
        () async {
          if (state.user == null) throw Exception('User ID not found');
          return await ref.read(deleteAccountUseCaseProvider).call();
        },
        onSuccess: (final success) async {
          await LocalStorageService.clearAllUserData();
        },
      );

  /// Login state'ini sıfırlar.
  void clearLoginState() {
    state = LoginState(
      user: null,
      isLoading: false,
      isGuest: false,
      errorMessage: null,
    );
  }

  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};
    final List<String> parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};
    final String lastName = parts.last;
    final String firstName = parts.sublist(0, parts.length - 1).join(' ');
    return {'firstName': firstName, 'lastName': lastName};
  }
}

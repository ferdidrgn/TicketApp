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

  Future<void> initialize() async {
    await LocalStorageService.init();
    await _authStateSubscription?.cancel();

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (final User? firebaseUser) async {
        _updateStateWithUser(firebaseUser);
      },
      onError: (final error) {
        state =
            state.copyWith(isLoading: false, errorMessage: error.toString());
      },
    );
  }

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

      await LocalStorageService.saveEssentialUserData(
        uid: refreshedUser.uid,
        displayName: refreshedUser.displayName,
        role: userRole,
      );

      if (!refreshedUser.isAnonymous) {
        await _syncUserWithFirestore(refreshedUser, userRole);
      }
    } else {
      state = state.copyWith(user: null, isLoading: false, isGuest: false);
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
      isPhoneActive: false,
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

  // --- GOOGLE GİRİŞ ---
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await ref.read(signInWithGoogleUseCaseProvider).call();
      result.fold(
        (final failure) {
          state =
              state.copyWith(isLoading: false, errorMessage: failure.message);
          throw Exception(failure.message);
        },
        (final googleUser) {
          if (googleUser != null) {
            _updateStateWithUser(FirebaseAuth.instance.currentUser);
          }
          state = state.copyWith(isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signInAnonymously() => execute(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
      );

  // --- TELEFON DOĞRULAMA (SADELEŞTİRİLDİ) ---
  Future<void> verifyPhone({
    required final String phoneNumber,
    required final Function(PhoneAuthCredential) onVerificationCompleted,
    required final Function(String, int?) onCodeSent,
    required final Function(String) onAutoRetrievalTimeout,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Sadece UseCase'i çağır, mantığı UI tarafındaki callback'lere bırak
    await ref.read(verifyPhoneUseCaseProvider).call(
          phoneNumber: phoneNumber,
          onVerificationCompleted: onVerificationCompleted,
          onCodeSent: onCodeSent,
          onAutoRetrievalTimeout: onAutoRetrievalTimeout,
        );
  }

  // --- OTP DOĞRULAMA ---
  Future<void> verifyOtp(final String otp) => execute<bool>(
        () {
          if (state.verificationId == null)
            throw Exception('Verification ID not found');
          // Kutuyu (Either) açmadan direkt döndür
          return ref
              .read(verifyOtpUseCaseProvider)
              .call(state.verificationId!, otp);
        },
        onSuccess: (final isVerified) async {
          if (isVerified) {
            await FirebaseAuth.instance.currentUser?.reload();
            await _updateStateWithUser(FirebaseAuth.instance.currentUser);
          } else {
            state = state.copyWith(errorMessage: "Hatalı kod girdiniz.");
          }
        },
      );

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await ref.read(signOutUseCaseProvider).call();
      await LocalStorageService.clearAllUserData();
      clearLoginState();
    } catch (e) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Çıkış hatası: $e');
    }
  }

  Future<void> deleteAccount() => execute<bool>(
        () {
          if (state.user == null) throw Exception('User ID not found');
          return ref.read(deleteAccountUseCaseProvider).call();
        },
        onSuccess: (final success) async {
          // İşlem başarılıysa temizliği burada yapıyoruz
          await LocalStorageService.clearAllUserData();

          // State'i tamamen sıfırla
          state = LoginState(
              user: null, isLoading: false, isGuest: false, errorMessage: null);
        },
      );

  void clearLoginState() => state = LoginState(
      user: null, isLoading: false, isGuest: false, errorMessage: null);

  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};
    final List<String> parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};
    final String lastName = parts.last;
    final String firstName = parts.sublist(0, parts.length - 1).join(' ');
    return {'firstName': firstName, 'lastName': lastName};
  }
}

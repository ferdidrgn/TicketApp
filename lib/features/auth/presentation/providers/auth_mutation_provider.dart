import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_provider.dart';
import 'auth_provider.dart' hide currentUserProvider;

part 'auth_mutation_provider.g.dart';

@riverpod
class OtpTimer extends _$OtpTimer {
  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  Timer? _timer;

  void set(final int seconds) {
    state = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (state <= 0) {
        timer.cancel();
      } else {
        state = state - 1;
      }
    });
  }
}

@riverpod
class AuthMutation extends _$AuthMutation {
  String? _verificationId;

  @override
  FutureOr<void> build() {}

  /// 🔑 Google ile Giriş
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user =
          await ref.read(signInWithGoogleUseCaseProvider).call().getOrThrow();
      if (user != null) await _handlePostLogin(user.id, UserRole.user);
    });
  }

  /// 🚪 Oturumu Kapat
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signOutUseCaseProvider).call();
      await LocalStorageService.clearAllUserData();
      ref.invalidate(authFirebaseUserProvider);
    });
  }

  /// 📱 Telefon Doğrulama
  Future<void> verifyPhone(final String phoneNumber) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => ref
        .read(verifyPhoneUseCaseProvider)
        .call(
          phoneNumber: phoneNumber,
          onVerificationCompleted: (final credential) {
            ref.invalidate(authFirebaseUserProvider);
          },
          onCodeSent: (final id, final token) {
            _verificationId = id;
            ref.read(otpTimerProvider.notifier).set(60);
          },
          onAutoRetrievalTimeout: (final id) => _verificationId = id,
        )
        .getOrThrow());
  }

  /// 📱 SMS Kodunu Doğrula
  Future<void> verifyOtp(final String otp) async {
    if (_verificationId == null) {
      state =
          AsyncError(Exception("Doğrulama kimliği eksik."), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(verifyOtpUseCaseProvider)
          .call(_verificationId!, otp)
          .getOrThrow();
      final userId = ref.read(currentUserIdProvider) ?? '';
      await _handlePostLogin(userId, UserRole.user);
    });
  }

  Future<void> _handlePostLogin(final String uid, final UserRole role) async {
    // DOĞRULAMA: Null safety hatasını aşmak için ham Firebase Auth örneği güvenle okunuyor
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    final existingUser =
        await ref.read(getUserByIdUseCaseProvider).call(uid).getOrThrow();

    if (existingUser == null) {
      final newUser = entity.User.empty(uid).copyWith(
        eMail: firebaseUser?.email ?? '',
        firstName: firebaseUser?.displayName?.split(' ').first ?? 'Yeni',
        lastName: firebaseUser?.displayName?.split(' ').last ?? 'Kullanıcı',
        imageUrl: firebaseUser?.photoURL ?? '',
        role: role,
      );
      await ref.read(saveUserUseCaseProvider).call(newUser, newUser.imageUrl);
    } else {
      final updatedUser =
          existingUser.copyWith(updatedAt: DateTime.now().toIso8601String());
      await ref
          .read(saveUserUseCaseProvider)
          .call(updatedUser, updatedUser.imageUrl, isUpdate: true);
    }

    await LocalStorageService.saveUserData(
      userId: uid,
      displayName: firebaseUser?.displayName ?? 'Kullanıcı',
      email: firebaseUser?.email ?? '',
      photoUrl: firebaseUser?.photoURL ?? '',
      role: role,
    );

    // 🔥 KRİTİK DÜZELTME:
    // authStateChanges() Firestore yazma işlemi TAMAMLANMADAN ÖNCE tetiklenebiliyor.
    // Bu durumda userProfileProvider, Firestore'da henüz oluşturulmamış bir
    // dökümanı sorguluyor ve `null` dönüyor. Sonuç: Profil sayfası kullanıcı
    // giriş yapmış olsa bile "giriş yapılmamış" gibi görünüyordu.
    // authFirebaseUserProvider'ı invalidate etmek yetersizdi çünkü profil
    // sayfası aslında userProfileProvider'ı dinliyor (o da currentUserIdProvider'ı
    // dinliyor, authFirebaseUserProvider'ı değil). Firestore yazma işlemi
    // tamamlandıktan SONRA, doğru provider'ı invalidate ediyoruz ki sayfa
    // güncel kullanıcı verisiyle anında yeniden çekilsin.
    ref.invalidate(authFirebaseUserProvider);
    ref.invalidate(userProfileProvider);
  }
}

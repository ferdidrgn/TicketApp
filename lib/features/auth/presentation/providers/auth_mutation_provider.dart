import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_service.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import 'auth_provider.dart';

part 'auth_mutation_provider.g.dart';

@riverpod
class OtpTimer extends _$OtpTimer {
  @override
  int build() => 0;

  void set(final int seconds) => state = seconds;

  void decrement() => state = state > 0 ? state - 1 : 0;
}

@riverpod
class AuthMutation extends _$AuthMutation {
  String? _verificationId;
  Timer? _timer;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _timer?.cancel());
  }

  /// 🔑 Google ile Giriş
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user =
          await ref.read(signInWithGoogleUseCaseProvider).call().getOrThrow();
      if (user != null) await _handlePostLogin(user.id, UserRole.user);
    });
  }

  /// 👤 Anonim Giriş (Ziyaretçi)
  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user =
          await ref.read(signInAnonymouslyUseCaseProvider).call().getOrThrow();
      if (user != null) {
        // LoginNotifier'daki FCM ve Firestore senkronizasyon mantığı burada çalışır
        await _handlePostLogin(user.uid, UserRole.guest);
      }
    });
  }

  /// 📱 Telefon Doğrulama (OTP Gönder)
  Future<void> verifyPhone(final String phoneNumber) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(verifyPhoneUseCaseProvider)
          .call(
            phoneNumber: phoneNumber,
            onVerificationCompleted: (final credential) =>
                ref.invalidate(currentUserProvider),
            onCodeSent: (final id, final token) {
              _verificationId = id;
              _startCountdown(60);
              state = const AsyncData(null);
            },
            onAutoRetrievalTimeout: (final id) => _verificationId = id,
          )
          .getOrThrow();
    });
  }

  void _startCountdown(final int seconds) {
    ref.read(otpTimerProvider.notifier).set(seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (ref.read(otpTimerProvider) <= 0) {
        timer.cancel();
      } else {
        ref.read(otpTimerProvider.notifier).decrement();
      }
    });
  }

  Future<void> verifyOtp(final String otp) async {
    if (_verificationId == null) {
      state =
          AsyncError(Exception("Doğrulama ID bulunamadı"), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(verifyOtpUseCaseProvider)
          .call(_verificationId!, otp)
          .getOrThrow();

      // Başarılıysa kullanıcı verilerini işle
      final userId = ref.read(currentUserIdProvider) ?? '';
      await _handlePostLogin(userId, UserRole.user);
    });
  }

  /// 🚪 Çıkış Yap
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider).value;

      // 1. FCM Token'ı temizle (LoginNotifier mantığı)
      if (user != null)
        await ref.read(authServiceProvider).clearFcmToken(user.uid);

      // 2. Auth oturumunu kapat
      await ref.read(signOutUseCaseProvider).call();

      // 3. Yerel verileri temizle
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      ref.invalidate(currentUserProvider);
    });
  }

  /// 🗑️ Hesabı Tamamen Sil
  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // LoginNotifier'daki kapsamlı silme sırası:
      // 1. Veritabanı ve Firestore verilerini sil (UseCase içinde halledilmeli)
      // 2. Auth sil
      await ref.read(deleteAccountUseCaseProvider).call();

      // 3. Yerel temizlik
      await LocalStorageService.clearAllUserData();
      _timer?.cancel();
      ref.invalidate(currentUserProvider);
    });
  }

  Future<void> _handlePostLogin(final String uid, final UserRole role) async {
    final user =
        await ref.read(getCurrentUserUseCaseProvider).call().getOrThrow();

    if (user != null) {
      // 2. Yerel hafızayı (LocalStorage) tüm bilgilerle doldur
      await LocalStorageService.saveUserData(
        userId: user.uid,
        displayName: user.displayName ?? 'Kullanıcı',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        role: role,
      );

      await ref.read(authServiceProvider).saveFcmToken(user.uid);
    }

    ref.invalidate(currentUserProvider);

    ref.invalidate(currentUserRoleProvider);
  }
}

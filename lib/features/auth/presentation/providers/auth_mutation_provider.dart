import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_service.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../users/data/models/user_model.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../../../users/presentation/providers/user_provider.dart';
import 'auth_provider.dart' hide currentUserProvider;

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

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signOutUseCaseProvider).call();
      await LocalStorageService.clearAllUserData();
      ref.invalidate(currentUserProvider);
    });
  }

  /// 📱 Telefon Doğrulama (Kodu Gönder)
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
              _startCountdown(60); // 60 saniyelik geri sayımı başlat
              state = const AsyncData(null);
            },
            onAutoRetrievalTimeout: (final id) => _verificationId = id,
          )
          .getOrThrow();
    });
  }

  /// 📱 SMS Kodunu Doğrula ve Giriş Yap
  Future<void> verifyOtp(final String otp) async {
    if (_verificationId == null) {
      state = AsyncError(
          Exception("Doğrulama kimliği bulunamadı. Lütfen tekrar kod isteyin."),
          StackTrace.current);
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

  void _startCountdown(final int seconds) {
    ref.read(otpTimerProvider.notifier).set(seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (ref.read(otpTimerProvider) <= 0)
        timer.cancel();
      else
        ref.read(otpTimerProvider.notifier).decrement();
    });
  }

  Future<void> _handlePostLogin(final String uid, final UserRole role) async {
    final firebaseUser = ref.read(authServiceProvider).currentUser;

    // 1. Döküman var mı kontrol et
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
      await ref.read(saveUserUseCaseProvider).call(
            UserModel.fromEntity(newUser),
            newUser.imageUrl,
          );
    } else {
      // 🔄 MEVCUT KULLANICI: Tarihi güncelle
      await ref.read(saveUserUseCaseProvider).call(
            UserModel.fromEntity(existingUser.copyWith(
                updatedAt: DateTime.now().toIso8601String())),
            existingUser.imageUrl,
            isUpdate: true,
          );
    }

    // 2. LOKAL HAFIZA SENKRONİZASYONU (Senin metodun)
    await LocalStorageService.saveUserData(
        userId: uid,
        displayName: firebaseUser?.displayName ?? 'Kullanıcı',
        email: firebaseUser?.email ?? '',
        photoUrl: firebaseUser?.photoURL ?? '',
        role: role);

    ref.invalidate(currentUserProvider);
  }
}

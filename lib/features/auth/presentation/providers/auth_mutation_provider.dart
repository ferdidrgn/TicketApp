import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_service.dart';
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
    // Widget veya provider yok edildiğinde timer'ı kesin olarak durdur
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  Timer? _timer;

  void set(final int seconds) {
    state = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      // State'i her saniye bir azalt
      if (state <= 0)
        timer.cancel();
       else state = state - 1;

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

  /// 🚪 Oturumu Kapat (Eksik olan metod eklendi)
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Firebase ve servis çıkışlarını yap
      await ref.read(signOutUseCaseProvider).call();
      // 2. Yerel verileri temizle
      await LocalStorageService.clearAllUserData();
      // 3. Kullanıcı bilgilerini sıfırla
      ref.invalidate(currentUserProvider);
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
            ref.invalidate(currentUserProvider);
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
    final firebaseUser = ref.read(authServiceProvider).currentUser;

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

    ref.invalidate(currentUserProvider);
  }
}

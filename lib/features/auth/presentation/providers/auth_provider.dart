import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/repositories/auth_repository_provider.dart';
import '../../domain/usecases/delete_account_use_case.dart';
import '../../domain/usecases/get_current_user_use_case_impl.dart';
import '../../domain/usecases/sign_in_anonymously_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case_impl.dart';
import '../../domain/usecases/sign_out_use_case_impl.dart';
import '../../domain/usecases/verify_otp_use_case_impl.dart';
import '../../domain/usecases/verify_phone_use_case_impl.dart';

part 'auth_provider.g.dart';

@riverpod
SignInWithGoogleUseCase signInWithGoogleUseCase(final Ref ref) =>
    SignInWithGoogleUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
SignInAnonymouslyUseCase signInAnonymouslyUseCase(final Ref ref) =>
    SignInAnonymouslyUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
VerifyPhoneUseCase verifyPhoneUseCase(final Ref ref) =>
    VerifyPhoneUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
VerifyOtpUseCase verifyOtpUseCase(final Ref ref) =>
    VerifyOtpUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
SignOutUseCase signOutUseCase(final Ref ref) =>
    SignOutUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
DeleteAccountUseCase deleteAccountUseCase(final Ref ref) =>
    DeleteAccountUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(final Ref ref) =>
    GetCurrentUserUseCaseImpl(ref.watch(authRepositoryProvider));

// --- Ana Veri Kaynakları ---

@riverpod
Future<User?> currentUser(final Ref ref) async {
  final user =
      await ref.watch(getCurrentUserUseCaseProvider).call().getOrThrow();

  // Proje kuralı: Anonim kullanıcılar 'null' kabul edilir.
  return (user != null && user.isAnonymous) ? null : user;
}

/// 🛡️ Kullanıcı Rolü (Admin, User, Guest vb.)
@riverpod
Future<UserRole> currentUserRole(final Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return UserRole.guest;

  // Yerel hafızadaki güncel rolü getirir.
  return await LocalStorageService.userRole;
}

/// 🔐 Giriş Durumu Kontrolü
// currentUser verisinin yüklenip yüklenmediğini ve null olup olmadığını kontrol eder.
@riverpod
bool isLoggedIn(final Ref ref) => ref.watch(currentUserProvider).value != null;

/// 🆔 Kullanıcı ID (Kısa erişim için)
@riverpod
String? currentUserId(final Ref ref) =>
    ref.watch(currentUserProvider).value?.uid;

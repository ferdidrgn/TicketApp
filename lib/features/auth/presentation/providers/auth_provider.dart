import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../data/repositories/auth_repository_provider.dart';
import '../../domain/usecases/delete_account_use_case.dart';
import '../../domain/usecases/get_current_user_use_case_impl.dart';
import '../../domain/usecases/sign_in_anonymously_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case_impl.dart';
import '../../domain/usecases/sign_out_use_case_impl.dart';
import '../../domain/usecases/verify_otp_use_case_impl.dart';
import '../../domain/usecases/verify_phone_use_case_impl.dart';

part 'auth_provider.g.dart';

// ─── Firebase Auth State Stream ─────────────────────────────────────────────
final authStateProvider = StreamProvider<firebase_auth.User?>((final ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges();
});

// ─── Use Case Providers ──────────────────────────────────────────────────────

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

// ─── Ana Veri Kaynakları ─────────────────────────────────────────────────────

/// Firebase Auth kullanıcısını döner. (Bunu ref.watch(authFirebaseUserProvider) olarak kullan)
@riverpod
Future<firebase_auth.User?> authFirebaseUser(final Ref ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null || authUser.isAnonymous) return null;
  return authUser;
}

/// 🔐 Giriş Durumu
@riverpod
bool isLoggedIn(final Ref ref) {
  final authUser = ref.watch(authStateProvider).value;
  return authUser != null && !authUser.isAnonymous;
}

@riverpod
bool isUserPrivileged(final Ref ref) {
  // Artık güncel profil verisini (entity.User) takip ediyoruz
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return false;
  return user.role == UserRole.admin || user.role == UserRole.curator;
}

/// 🆔 Kullanıcı UID'si (Bunu ref.watch(currentUserIdProvider) olarak kullan)
@riverpod
String? currentUserId(final Ref ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null || authUser.isAnonymous) return null;
  return authUser.uid;
}

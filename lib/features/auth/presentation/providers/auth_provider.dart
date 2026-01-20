import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../domain/usecases/delete_account_use_case.dart';
import '../../domain/usecases/get_current_user_use_case_impl.dart';
import '../../domain/usecases/sign_in_anonymously_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case_impl.dart';
import '../../domain/usecases/sign_out_use_case_impl.dart';
import '../../domain/usecases/verify_otp_use_case_impl.dart';
import '../../domain/usecases/verify_phone_use_case_impl.dart';

part 'auth_provider.g.dart';

// --- UseCase Provider'ları ---
@riverpod
SignInWithGoogleUseCase signInWithGoogleUseCase(final Ref ref) =>
    SignInWithGoogleUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
SignOutUseCase signOutUseCase(final Ref ref) =>
    SignOutUseCaseImpl(ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(final Ref ref) =>
    GetCurrentUserUseCaseImpl(ref.watch(authRepositoryProvider));

// Diğer UseCase'leri de aynı şekilde buraya ekleyebilirsin...

// --- Ana Veri Kaynakları ---

@riverpod
Future<User?> currentUser(final Ref ref) async {
  // getOrThrow() kullanarak Either'ı doğrudan açıyoruz
  final user = await ref
      .watch(getCurrentUserUseCaseProvider)
      .call()
      .then((value) => value.getOrThrow());

  if (user != null && user.isAnonymous) return null;
  return user;
}

@riverpod
Future<UserRole> currentUserRole(final Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return UserRole.guest;
  return await LocalStorageService.userRole;
}

@riverpod
bool isLoggedIn(final Ref ref) => ref.watch(currentUserProvider).value != null;

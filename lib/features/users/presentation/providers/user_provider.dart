import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/enum/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/user_repository_provider.dart';
import '../../domain/entities/user.dart' as entity;
import '../../domain/usecases/delete_user_use_case_impl.dart';
import '../../domain/usecases/get_user_by_id_use_case_impl.dart';
import '../../domain/usecases/save_user_use_case_impl.dart';

part 'user_provider.g.dart';

// ═══════════════════════════════════════════════════════════
// 1. USE CASE PROVIDERS
// ═══════════════════════════════════════════════════════════

@riverpod
SaveUserUseCase saveUserUseCase(final Ref ref) =>
    SaveUserUseCaseImpl(ref.watch(userRepositoryProvider));

@riverpod
GetUserByIdUseCase getUserByIdUseCase(final Ref ref) =>
    GetUserByIdUseCaseImpl(ref.watch(userRepositoryProvider));

@riverpod
DeleteUserUseCase deleteUserUseCase(final Ref ref) =>
    DeleteUserUseCaseImpl(ref.watch(userRepositoryProvider));

// ═══════════════════════════════════════════════════════════
// 2. READ OPERATIONS (Sürekli Güncel Veri)
// ═══════════════════════════════════════════════════════════

/// 🔥 Uygulamanın en kritik provider'ı. Auth UID'sini izler ve
/// Firestore dökümanını (entity.User) asenkron döndürür.
@riverpod
Future<entity.User?> currentUser(final Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  // Firestore dökümanını UseCase üzerinden çekiyoruz
  return await ref.watch(getUserByIdUseCaseProvider).call(userId).getOrThrow();
}

// ═══════════════════════════════════════════════════════════
// 3. SELECTORS (Durum ve Yetki Kontrolleri)
// ═══════════════════════════════════════════════════════════

/// Kullanıcının Admin veya Küratör olup olmadığını kontrol eder.
@riverpod
bool isUserPrivileged(final Ref ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;
  return user.role == UserRole.admin || user.role == UserRole.curator;
}

/// Kullanıcının toplam bilet sayısını döner.
@riverpod
int userTicketCount(final Ref ref) =>
    ref.watch(currentUserProvider).value?.ticketsId.length ?? 0;

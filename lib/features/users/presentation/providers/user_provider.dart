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

@riverpod
SaveUserUseCase saveUserUseCase(final Ref ref) =>
    SaveUserUseCaseImpl(ref.watch(userRepositoryProvider));

@riverpod
GetUserByIdUseCase getUserByIdUseCase(final Ref ref) =>
    GetUserByIdUseCaseImpl(ref.watch(userRepositoryProvider));

@riverpod
DeleteUserUseCase deleteUserUseCase(final Ref ref) =>
    DeleteUserUseCaseImpl(ref.watch(userRepositoryProvider));

/// 🔥 Profil sayfası için kullanılan ana provider.
/// Auth ID'sini izler ve Firestore'dan kullanıcı verisini getirir.
@riverpod
Future<entity.User?> userProfile(final Ref ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return await ref.read(getUserByIdUseCaseProvider).call(userId).getOrThrow();
}

/// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
/// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.
@riverpod
Future<entity.User?> userById(final Ref ref, final String uid) async {
  if (uid.isEmpty) return null;
  return await ref.watch(getUserByIdUseCaseProvider).call(uid).getOrThrow();
}

/// Admin/Küratör kontrolü
@riverpod
bool isUserPrivileged(final Ref ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return false;
  return user.role == UserRole.admin || user.role == UserRole.curator;
}

/// Kullanıcının toplam bilet sayısını döner.
@riverpod
int userTicketCount(final Ref ref) =>
    ref.watch(userProfileProvider).value?.ticketsId.length ?? 0;

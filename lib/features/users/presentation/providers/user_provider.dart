import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_notifier.dart';
import 'user_state.dart';
import '../../data/repositories/user_repository_provider.dart';
import '../../domain/usecases/delete_user_use_case_impl.dart';
import '../../domain/usecases/get_user_by_id_use_case_impl.dart';
import '../../domain/usecases/save_user_use_case_impl.dart';

/// 👤 User Provider
///
/// User bilgilerini yönetir (profile edit, user details vb.)
/// Auth işlemleri için LoginProvider kullanılır
final userProvider =
    NotifierProvider<UserNotifier, UserState>(UserNotifier.new);

// ========================================
// USE CASE PROVIDERS
// ========================================

/// Save user use case
final saveUserUseCaseProvider = Provider<SaveUserUseCase>(
    (final ref) => SaveUserUseCaseImpl(ref.watch(userRepositoryProvider)));

/// Get user by ID use case
final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>(
    (final ref) => GetUserByIdUseCaseImpl(ref.watch(userRepositoryProvider)));

/// Delete user use case
final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>(
    (final ref) => DeleteUserUseCaseImpl(ref.watch(userRepositoryProvider)));

// ========================================
// DERIVED PROVIDERS (Convenience)
// ========================================

/// Current user
final currentUserProvider = Provider((final ref) =>
    ref.watch(userProvider.select((final state) => state.dataSingle)));

/// User full name
final userFullNameProvider = Provider<String>((final ref) => ref.watch(userProvider.select((final state) => state.userFullName)));

/// Is loading
final isUserLoadingProvider = Provider<bool>((final ref) => ref.watch(userProvider.select((final state) => state.isLoading)));

/// Has error
final hasUserErrorProvider = Provider<bool>((final ref) {
  final errorMessage =
      ref.watch(userProvider.select((final state) => state.errorMessage));
  return errorMessage != null && errorMessage.isNotEmpty;
});

/// Error message
final userErrorMessageProvider = Provider<String?>((final ref) => ref.watch(userProvider.select((final state) => state.errorMessage)));

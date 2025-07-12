import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/user/delete_user_use_case_impl.dart';
import '../../../domain/useCase/user/get_user_by_id_use_case_impl.dart';
import '../../../domain/useCase/user/save_user_use_case_impl.dart';
import '../../repository/user/user_repository_provider.dart';
import 'user_notifier.dart';
import 'user_state.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, UserState>((final ref) {
  return UserNotifier(
    ref.read(internetServiceProvider),
    ref.watch(saveUserUseCaseProvider),
    ref.watch(getUserByIdUseCaseProvider),
    ref.watch(deleteUserUseCaseProvider),
  );
});

// Use case providers
final saveUserUseCaseProvider = Provider<SaveUserUseCase>((final ref) {
  final repository = ref.watch(userRepositoryProvider);
  return SaveUserUseCaseImpl(repository);
});

final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>((final ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserByIdUseCaseImpl(repository);
});

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((final ref) {
  final repository = ref.watch(userRepositoryProvider);
  return DeleteUserUseCaseImpl(repository);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/user/delete_user_use_case_impl.dart';
import '../../../domain/useCase/user/get_user_by_id_use_case_impl.dart';
import '../../../domain/useCase/user/save_user_use_case_impl.dart';
import '../../repository/user/user_repository_provider.dart';
import 'user_notifier.dart';
import 'user_state.dart';

final userProvider =
    NotifierProvider.autoDispose<UserNotifier, UserState>(UserNotifier.new);

// Use case providers
final saveUserUseCaseProvider = Provider<SaveUserUseCase>(
  (final ref) => SaveUserUseCaseImpl(ref.watch(userRepositoryProvider)),
);

final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>(
  (final ref) => GetUserByIdUseCaseImpl(ref.watch(userRepositoryProvider)),
);

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>(
  (final ref) => DeleteUserUseCaseImpl(ref.watch(userRepositoryProvider)),
);

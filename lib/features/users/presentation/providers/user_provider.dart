import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/users/presentation/providers/user_notifier.dart';
import 'package:ticketapp/features/users/presentation/providers/user_state.dart';
import '../../data/repositories/user_repository_provider.dart';
import '../../domain/usecases/delete_user_use_case_impl.dart';
import '../../domain/usecases/get_user_by_id_use_case_impl.dart';
import '../../domain/usecases/save_user_use_case_impl.dart';

final userProvider =
    NotifierProvider<UserNotifier, UserState>(UserNotifier.new);

// Use case providers
final saveUserUseCaseProvider = Provider<SaveUserUseCase>(
    (final ref) => SaveUserUseCaseImpl(ref.watch(userRepositoryProvider)));

final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>(
    (final ref) => GetUserByIdUseCaseImpl(ref.watch(userRepositoryProvider)));

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>(
    (final ref) => DeleteUserUseCaseImpl(ref.watch(userRepositoryProvider)));

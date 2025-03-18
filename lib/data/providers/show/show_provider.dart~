import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/show/add_show_use_case_impl.dart';
import '../../../domain/useCase/show/delete_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_search_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_show_by_id_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_use_case_impl.dart';
import '../../../domain/useCase/show/update_show_use_case_impl.dart';
import '../../repository/show/show_repository_provider.dart';
import 'show_notifier.dart';
import 'show_state.dart';

final showProvider = StateNotifierProvider<ShowNotifier, ShowState>((final ref) {
  return ShowNotifier(
    ref.watch(addShowUseCaseProvider),
    ref.watch(deleteShowUseCaseProvider),
    ref.watch(updateShowUseCaseProvider),
    ref.watch(getShowByIdUseCaseProvider),
    ref.watch(getShowsUseCaseProvider),
    ref.watch(getSearchShowUseCaseProvider),
  );
});

// Use case providers
final addShowUseCaseProvider = Provider<AddShowUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return AddShowUseCaseImpl(repository);
});

final deleteShowUseCaseProvider = Provider<DeleteShowUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return DeleteShowUseCaseImpl(repository);
});

final updateShowUseCaseProvider = Provider<UpdateShowUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return UpdateShowUseCaseImpl(repository);
});

final getShowByIdUseCaseProvider = Provider<GetShowByIdUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return GetShowByIdUseCaseImpl(repository);
});

final getShowsUseCaseProvider = Provider<GetShowsUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return GetShowsUseCaseImpl(repository);
});

final getSearchShowUseCaseProvider = Provider<GetSearchShowUseCase>((final ref) {
  final repository = ref.watch(showRepositoryProvider);
  return GetSearchShowUseCaseImpl(repository);
});

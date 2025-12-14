import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_notifier.dart';
import '../../data/repositories/show_repository_provider.dart';
import '../../domain/usecases/add_show_use_case_impl.dart';
import '../../domain/usecases/delete_show_use_case_impl.dart';
import '../../domain/usecases/get_search_show_use_case_impl.dart';
import '../../domain/usecases/get_shows_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_shows_use_case_impl.dart';
import '../../domain/usecases/update_show_use_case_impl.dart';
import 'show_state.dart';

/// Ana Show Notifier provider
final showProvider =
    NotifierProvider.autoDispose<ShowNotifier, ShowState>(ShowNotifier.new);

/// Use case provider'ları
final addShowUseCaseProvider = Provider<AddShowUseCase>(
    (final ref) => AddShowUseCaseImpl(ref.watch(showRepositoryProvider)));

final deleteShowUseCaseProvider = Provider<DeleteShowUseCase>(
    (final ref) => DeleteShowUseCaseImpl(ref.watch(showRepositoryProvider)));

final updateShowUseCaseProvider = Provider<UpdateShowUseCase>(
    (final ref) => UpdateShowUseCaseImpl(ref.watch(showRepositoryProvider)));

final getShowsByIdsUseCaseProvider = Provider<GetShowsByIdsUseCase>(
    (final ref) => GetShowsByIdsUseCaseImpl(ref.watch(showRepositoryProvider)));

final getShowsUseCaseProvider = Provider<GetShowsUseCase>(
    (final ref) => GetShowsUseCaseImpl(ref.watch(showRepositoryProvider)));

final getSearchShowUseCaseProvider = Provider<GetSearchShowUseCase>(
    (final ref) => GetSearchShowUseCaseImpl(ref.watch(showRepositoryProvider)));

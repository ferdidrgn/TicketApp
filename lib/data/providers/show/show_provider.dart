import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/show/add_show_use_case_impl.dart';
import '../../../domain/useCase/show/delete_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_search_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_by_ids_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_use_case_impl.dart';
import '../../../domain/useCase/show/update_show_use_case_impl.dart';
import '../../repository/show/show_repository_provider.dart';
import 'show_notifier.dart';
import 'show_state.dart';

/// Ana Show Notifier provider
final showProvider =
    NotifierProvider<ShowNotifier, ShowState>(ShowNotifier.new);

/// Use case provider'ları
final addShowUseCaseProvider = Provider<AddShowUseCase>(
  (final ref) => AddShowUseCaseImpl(ref.watch(showRepositoryProvider)),
);

final deleteShowUseCaseProvider = Provider<DeleteShowUseCase>(
  (final ref) => DeleteShowUseCaseImpl(ref.watch(showRepositoryProvider)),
);

final updateShowUseCaseProvider = Provider<UpdateShowUseCase>(
  (final ref) => UpdateShowUseCaseImpl(ref.watch(showRepositoryProvider)),
);

final getShowsByIdsUseCaseProvider = Provider<GetShowsByIdsUseCase>(
  (final ref) => GetShowsByIdsUseCaseImpl(ref.watch(showRepositoryProvider)),
);

final getShowsUseCaseProvider = Provider<GetShowsUseCase>(
  (final ref) => GetShowsUseCaseImpl(ref.watch(showRepositoryProvider)),
);

final getSearchShowUseCaseProvider = Provider<GetSearchShowUseCase>(
  (final ref) => GetSearchShowUseCaseImpl(ref.watch(showRepositoryProvider)),
);

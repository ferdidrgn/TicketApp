import 'package:flutter/material.dart';
import '../../../core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/show/add_show_use_case_impl.dart';
import '../../../domain/useCase/show/delete_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_search_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_by_ids_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_use_case_impl.dart';
import '../../../domain/useCase/show/update_show_use_case_impl.dart';
import '../../model/show_model.dart';
import 'show_state.dart';

class ShowNotifier extends BaseNotifierWithNetworkChecker<ShowState> {
  final InternetService internetService;
  final AddShowUseCase addShowUseCase;
  final DeleteShowUseCase deleteShowUseCase;
  final UpdateShowUseCase updateShowUseCase;
  final GetShowsByIdsUseCase getShowsByIdsUseCase;
  final GetShowsUseCase getShowsUseCase;
  final GetSearchShowUseCase getSearchShowUseCase;

  ShowNotifier(
      this.internetService,
      this.addShowUseCase,
      this.deleteShowUseCase,
      this.updateShowUseCase,
      this.getShowsByIdsUseCase,
      this.getShowsUseCase,
      this.getSearchShowUseCase)
      : super(internetService, ShowState());

  @override // Internet restore olduğunda yapılacak işlemler
  void reloadData() => loadShows(true);

  Future<void> addShow(final ShowModel show, final Uri? imageUrl) async =>
      executeWithInternetCheck(
        () => addShowUseCase.call(show, imageUrl),
      );

  Future<void> deleteShow(final String? showId) async {
    await executeWithInternetCheck(
      () => deleteShowUseCase.call(showId),
    );
  }

  Future<void> updateShow(
          final String showId, final Map<String, dynamic> updatedData) async =>
      executeWithInternetCheck(
        () => updateShowUseCase.call(showId, updatedData),
      );

  Future<void> loadShowsByIds(final List<String> showsIds) async =>
      executeWithInternetCheck(
        () => getShowsByIdsUseCase.call(showsIds),
        onSuccess: (final shows) => state = state.copyWith(dataList: shows),
      );

  Future<void> loadShows(final isLimit) async => executeWithInternetCheck(
        () => getShowsUseCase.call(isLimit),
        onSuccess: (final shows) => state = state.copyWith(dataList: shows),
      );

  Future<void> searchShows(
          final List<String> categories, final String? type) async =>
      executeWithInternetCheck(
          () => getSearchShowUseCase.call(categories, type));
}

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
  final AddShowUseCase _addShowUseCase;
  final DeleteShowUseCase _deleteShowUseCase;
  final UpdateShowUseCase _updateShowUseCase;
  final GetShowsByIdsUseCase _getShowsByIdsUseCase;
  final GetShowsUseCase _getShowsUseCase;
  final GetSearchShowUseCase _getSearchShowUseCase;

  ShowNotifier(
      final InternetService internetService,
      this._addShowUseCase,
      this._deleteShowUseCase,
      this._updateShowUseCase,
      this._getShowsByIdsUseCase,
      this._getShowsUseCase,
      this._getSearchShowUseCase)
      : super(internetService, const ShowState());

  @override // Internet restore olduğunda yapılacak işlemler
  void reloadData() => loadShows(true);

  Future<void> addShow(final ShowModel show, final Uri? imageUrl) =>
      executeWithInternetCheck(() => _addShowUseCase.call(show, imageUrl));

  Future<void> deleteShow(final String? showId) =>
      executeWithInternetCheck(() => _deleteShowUseCase.call(showId));

  Future<void> updateShow(
          final String showId, final Map<String, dynamic> updatedData) =>
      executeWithInternetCheck(
          () => _updateShowUseCase.call(showId, updatedData));

  Future<void> loadShowsByIds(final List<String> showsIds) =>
      executeWithInternetCheck(
        () => _getShowsByIdsUseCase.call(showsIds),
        onSuccess: (final shows) => state = state.copyWith(dataList: shows),
      );

  Future<void> loadShows(final isLimit) => executeWithInternetCheck(
        () => _getShowsUseCase.call(isLimit),
        onSuccess: (final shows) => state = state.copyWith(dataList: shows),
      );

  Future<void> searchShows(final List<String> categories, final String? type) =>
      executeWithInternetCheck(
        () => _getSearchShowUseCase.call(categories, type),
      );
}

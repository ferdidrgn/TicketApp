import '../../../core/common/base_notifier.dart';
import '../../../domain/useCase/show/add_show_use_case_impl.dart';
import '../../../domain/useCase/show/delete_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_search_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_by_ids_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_use_case_impl.dart';
import '../../../domain/useCase/show/update_show_use_case_impl.dart';
import '../../model/show_model.dart';
import 'show_state.dart';

class ShowNotifier extends BaseNotifier<ShowState> {
  final AddShowUseCase addShowUseCase;
  final DeleteShowUseCase deleteShowUseCase;
  final UpdateShowUseCase updateShowUseCase;
  final GetShowsByIdsUseCase getShowsByIdsUseCase;
  final GetShowsUseCase getShowsUseCase;
  final GetSearchShowUseCase getSearchShowUseCase;

  ShowNotifier(
    this.addShowUseCase,
    this.deleteShowUseCase,
    this.updateShowUseCase,
    this.getShowsByIdsUseCase,
    this.getShowsUseCase,
    this.getSearchShowUseCase,
  ) : super(ShowState());

  Future<void> addShow(final ShowModel show, final Uri? imageUrl) async =>
      handleOperation(() => addShowUseCase.call(show, imageUrl));

  Future<void> deleteShow(final String? showId) async =>
      handleOperation(() => deleteShowUseCase.call(showId));

  Future<void> updateShow(
          final String showId, final Map<String, dynamic> updatedData) async =>
      handleOperation(() => updateShowUseCase.call(showId, updatedData));

  Future<void> loadShowsByIds(final List<String> showsIds) async {
    await handleOperation(
      () => getShowsByIdsUseCase.call(showsIds),
      onSuccess: (final shows) => state = state.copyWith(dataList: shows),
    );
  }

  Future<void> loadShows(final isLimit) async {
    await handleOperation(
      () => getShowsUseCase.call(isLimit),
      onSuccess: (final shows) => state = state.copyWith(dataList: shows),
    );
  }

  Future<void> searchShows(
      final List<String> categories, final String? type) async =>
      handleOperation(() => getSearchShowUseCase.call(categories, type));
}

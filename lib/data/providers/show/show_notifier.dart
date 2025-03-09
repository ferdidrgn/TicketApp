import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/show/add_show_use_case_impl.dart';
import '../../../domain/useCase/show/delete_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_search_show_use_case_impl.dart';
import '../../../domain/useCase/show/get_show_by_id_use_case_impl.dart';
import '../../../domain/useCase/show/get_shows_use_case_impl.dart';
import '../../../domain/useCase/show/update_show_use_case_impl.dart';
import '../../model/show_model.dart';
import 'show_state.dart';

class ShowNotifier extends StateNotifier<ShowState> {
  final AddShowUseCase addShowUseCase;
  final DeleteShowUseCase deleteShowUseCase;
  final UpdateShowUseCase updateShowUseCase;
  final GetShowByIdUseCase getShowByIdUseCase;
  final GetShowsUseCase getShowsUseCase;
  final GetSearchShowUseCase getSearchShowUseCase;

  ShowNotifier(
    this.addShowUseCase,
    this.deleteShowUseCase,
    this.updateShowUseCase,
    this.getShowByIdUseCase,
    this.getShowsUseCase,
    this.getSearchShowUseCase,
  ) : super(ShowState());

  Future<void> addShow(final ShowModel show, final Uri? imageUrl) async {
    _setLoadingState(true);
    final result = await addShowUseCase.call(show, imageUrl);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> deleteShow(final String? showId) async {
    _setLoadingState(true);
    final result = await deleteShowUseCase.call(showId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    _setLoadingState(true);
    final result = await updateShowUseCase.call(showId, updatedData);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  Future<void> loadShowById(final String showId) async {
    _setLoadingState(true);
    final result = await getShowByIdUseCase.call(showId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final show) => _setShowState(show),
    );
  }

  Future<void> loadShows(final isLimit) async {
    _setLoadingState(true);
    final result = await getShowsUseCase.call(isLimit);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final shows) => _setShowsState(shows),
    );
  }

  Future<void> searchShows(
      final List<String?> categories, final String? type) async {
    _setLoadingState(true);
    final result = await getSearchShowUseCase.call(categories, type);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final shows) => _setShowsState(shows),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setSuccessState() {
    state = state.copyWith(isLoading: false);
  }

  void _setShowState(final ShowModel? show) {
    state = state.copyWith(show: show, isLoading: false);
  }

  void _setShowsState(final List<ShowModel?> shows) {
    state = state.copyWith(shows: shows, isLoading: false);
  }
}

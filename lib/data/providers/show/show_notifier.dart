import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
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
    await _handleShowOperation(() async => addShowUseCase.call(show, imageUrl));
  }

  Future<void> deleteShow(final String? showId) async {
    await _handleShowOperation(() async => deleteShowUseCase.call(showId));
  }

  Future<void> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    await _handleShowOperation(
        () async => updateShowUseCase.call(showId, updatedData));
  }

  Future<void> loadShowById(final String showId) async {
    await _handleShowOperation(() async => getShowByIdUseCase.call(showId),
        onSuccess: (final show) {
      state = state.copyWith(show: show);
    });
  }

  Future<void> loadShows(final isLimit) async {
    await _handleShowOperation(() async => getShowsUseCase.call(isLimit),
        onSuccess: (final shows) {
      state = state.copyWith(shows: shows);
    });
  }

  Future<void> searchShows(
      final List<String> categories, final String? type) async {
    await _handleShowOperation(
        () async => getSearchShowUseCase.call(categories, type));
  }

  Future<void> _handleShowOperation<T>(
    final Future<Either<Failure, T>> Function() operation, {
    final Function(T)? onSuccess,
  }) async {
    _setLoadingState(true);
    final result = await operation();

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final success) {
        onSuccess?.call(success);
        _setSuccessState();
      },
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
}

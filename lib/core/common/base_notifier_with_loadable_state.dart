import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';
import 'base_loadable_state.dart';

// Enhanced BaseNotifier for LoadableState with silent loading option
abstract class BaseNotifierWithLoadableState<T extends LoadableState>
    extends StateNotifier<T> {
  BaseNotifierWithLoadableState(final T state) : super(state);

  // Perform operation with optional silent loading
  Future<void> handleOperation<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
    final bool silentLoading = false,
  }) async {
    try {
      if (!silentLoading) _setLoadingState(true);

      final result = await operation();

      result.fold(
        (final failure) => _setErrorState(failure.message),
        (final success) {
          onSuccess?.call(success);
          _setLoadingState(false);
        },
      );
    } catch (e) {
      _setErrorState('Unexpected error occurred: ${e.toString()}');
    }
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading, errorMessage: null) as T;
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
    ) as T;
  }
}

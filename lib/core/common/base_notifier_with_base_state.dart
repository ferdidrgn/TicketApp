import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_state.dart';

// Enhanced Base Notifier with more robust error handling
abstract class BaseNotifierWithBaseState<T extends BaseState> extends StateNotifier<T> {
  BaseNotifierWithBaseState(final T state) : super(state);

  Future<void> handleOperation<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    try {
      _setLoadingState(true);

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

  // Private method to set error state
  void _setErrorState(final String errorMessage) {
    state = state.copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    ) as T;
  }
}

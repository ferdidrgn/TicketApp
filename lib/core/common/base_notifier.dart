import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_state.dart';

// Enhanced Base Notifier with more robust error handling
abstract class BaseNotifier<T extends BaseState> extends StateNotifier<T> {
  BaseNotifier(final T state) : super(state);

  Future<void> handleOperation<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    try {
      isSetLoading(true);

      final result = await operation();

      result.fold(
        (final failure) => setErrorState(failure.message),
        (final success) {
          onSuccess?.call(success);
          isSetLoading(false);
        },
      );
    } catch (e) {
      setErrorState('Unexpected error occurred: ${e.toString()}');
    }
  }

  // Convenience methods for state updates
  void isSetLoading(final isLoading) =>
      state = state.copyWith(isLoading: isLoading, errorMessage: null) as T;

  void setErrorState(final String errorMessage) {
    state = state.copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    ) as T;
  }
}

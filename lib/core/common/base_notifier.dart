import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_state.dart';

// Base notifier class with common state management logic
abstract class BaseNotifier<T extends BaseState> extends StateNotifier<T> {
  BaseNotifier(final T state) : super(state);

  Future<void> handleOperation<R>(
      final Future<Either<Failure, R>> Function() operation, {
        final Function(R)? onSuccess,
      }) async {
    setLoadingState(true);
    final result = await operation();

    result.fold(
          (final failure) => setErrorState(failure.message),
          (final success) {
        onSuccess?.call(success);
        setSuccessState();
      },
    );
  }

  void setLoadingState(final isLoading) {
    state = state.copyWith(isLoading: isLoading) as T;
  }

  void setErrorState(final String errorMessage) {
    state = state.copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    ) as T;
  }

  void setSuccessState() {
    state = state.copyWith(isLoading: false) as T;
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_loadable_state.dart';
import 'base_state.dart';

// Enhanced Base Notifier with more robust error handling
abstract class BaseNotifier<T extends BaseState> extends StateNotifier<T> {
  BaseNotifier(T state) : super(state);

  Future<void> handleOperation<R>(
    Future<Either<Failure, R>> Function() operation, {
    Function(R)? onSuccess,
  }) async {
    try {
      isSetLoading(true);

      Either<Failure, R> result = await operation();

      result.fold(
        (failure) => setErrorState(failure.message),
        (success) {
          onSuccess?.call(success);
          isSetLoading(false);
        },
      );
    } catch (e) {
      setErrorState('Unexpected error occurred: ${e.toString()}');
    }
  }

  // Convenience methods for state updates
  void isSetLoading(isLoading) =>
      state = state.copyWith(isLoading: isLoading, errorMessage: null) as T;

  void setErrorState(String errorMessage) {
    state = state.copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    ) as T;
  }
}

abstract class BaseNotifierTwo<T extends LoadableState> extends StateNotifier<T> {
  BaseNotifierTwo(T state) : super(state);

  Future<void> handleOperation<R>(
      Future<Either<Failure, R>> Function() operation, {
        Function(R)? onSuccess,
        bool silentLoading = false,
      }) async {
    try {
      // Only show loading if not silent loading
      if (!silentLoading) {
        state = state.copyWith(isLoading: true, errorMessage: null) as T;
      }

      Either<Failure, R> result = await operation();

      result.fold(
            (failure) {
          state = state.copyWith(
              isLoading: false,
              errorMessage: failure.message
          ) as T;
        },
            (success) {
          onSuccess?.call(success);
          state = state.copyWith(
              isLoading: false,
              errorMessage: null
          ) as T;
        },
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Beklenmeyen bir hata oluştu: ${e.toString()}'
      ) as T;
    }
  }
}

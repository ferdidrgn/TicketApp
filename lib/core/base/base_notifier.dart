import 'dart:developer' as dev;
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import 'base_state.dart';

/// Tüm Riverpod 3 Notifier tipleriyle uyumlu (Notifier, AsyncNotifier, AutoDispose).
mixin BaseNotifierActionHandler<T extends BaseState> {
  // Notifier'ın state'ine erişmek için gereken soyut imzalar.
  T get state;

  set state(final T value);

  Future<R?> execute<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final String? operationTag,
    final String? customErrorMessage,
    final bool showLoading = true,
  }) async {
    final tag = operationTag ?? 'Operation';

    try {
      if (showLoading)
        state = state.copyWith(isLoading: true, errorMessage: null) as T;

      dev.log('Executing $tag...', name: 'BaseActionHandler');
      final result = await operation();

      return result.fold(
        (final failure) {
          final error = _mapFailureToMessage(failure, customErrorMessage);
          dev.log('Error in $tag: $error',
              name: 'BaseActionHandler', error: failure);
          state = state.copyWith(isLoading: false, errorMessage: error) as T;
          return null;
        },
        (final success) {
          dev.log('$tag completed successfully.', name: 'BaseActionHandler');
          state = state.copyWith(isLoading: false, errorMessage: null) as T;
          return success;
        },
      );
    } catch (e, stackTrace) {
      dev.log('Critical Error in $tag',
          name: 'BaseActionHandler', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Beklenmedik bir hata oluştu... / An unexpected error has occurred...',
      ) as T;
      return null;
    }
  }

  String _mapFailureToMessage(final Failure failure, final String? custom) {
    if (custom != null) return custom;
    return switch (failure.runtimeType.toString()) {
      'NetworkFailure' =>
        'İnternet bağlantınızı kontrol edin / Network Checking',
      'ServerFailure' =>
        'Sunucu şu an yanıt vermiyor / Server is not answer now',
      _ => failure.message,
    };
  }
}

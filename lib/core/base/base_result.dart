import 'dart:developer' as dev;
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// State'e dokunmayan, sadece iş akışını yöneten handler.
mixin BaseResultHandler {
  /// Operasyonu fold eder ve sonucu döndürür.
  Future<R?> handleResult<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final String? operationTag,
    final void Function(String errorMessage)? onError,
  }) async {
    final tag = operationTag ?? 'Operation';

    try {
      dev.log('Executing $tag...', name: 'BaseResultHandler');
      final result = await operation();

      return result.fold(
        (final failure) {
          final error = _mapFailureToMessage(failure);
          dev.log('Error in $tag: $error',
              name: 'BaseResultHandler', error: failure);

          // Hatayı dışarı fırlatmak yerine callback ile haber veriyoruz
          onError?.call(error);
          return null;
        },
        (final success) {
          dev.log('$tag completed successfully.', name: 'BaseResultHandler');
          return success;
        },
      );
    } catch (e, stackTrace) {
      dev.log('Critical Error in $tag',
          name: 'BaseResultHandler', error: e, stackTrace: stackTrace);
      onError?.call('Beklenmeyen bir hata oluştu / An unexpected error has occurred');
      return null;
    }
  }

  String _mapFailureToMessage(final Failure failure) {
    return switch (failure.runtimeType.toString()) {
      'NetworkFailure' =>
        'İnternet bağlantınızı kontrol edin / Network Checking',
      'ServerFailure' =>
        'Sunucu şu an yanıt vermiyor / Server is not answer now',
      _ => failure.message,
    };
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';
import 'base_state.dart';

/// Basitleştirilmiş Base Notifier
/// İnternet kontrolü YOK - sunucu hatası zaten yakalanacak
abstract class BaseNotifier<T extends BaseState> extends Notifier<T> {
  @override
  T build() => initialState();

  T initialState();

  /// API çağrılarını wrap eden ana metod
  Future<void> execute<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
    final String? customErrorMessage,
  }) async {
    if (!ref.mounted) return;

    setLoadingState(true);

    try {
      final result = await operation();

      if (!ref.mounted) return;
      result.fold(
        (final failure) {
          // Network hatası gelirse özel mesaj göster
          final message = _mapFailureToMessage(failure, customErrorMessage);
          setErrorState(message);
        },
        (final success) {
          onSuccess?.call(success);
          setLoadingState(false);
        },
      );
    } catch (e) {
      if (!ref.mounted) return;
      setErrorState(customErrorMessage ?? 'Beklenmeyen bir hata oluştu');
    }
  }

  String _mapFailureToMessage(final Failure failure, final String? custom) {
    if (custom != null) return custom;

    // Failure tipine göre mesaj döndür
    return switch (failure.runtimeType.toString()) {
      'NetworkFailure' => 'Bağlantı hatası. Lütfen internetinizi kontrol edin.',
      'ServerFailure' => 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.',
      'CacheFailure' => 'Önbellek hatası.',
      _ => failure.message ?? 'Bir hata oluştu',
    };
  }

  void setLoadingState(final bool loading) =>
      state = state.copyWith(isLoading: loading) as T;

  void setErrorState(final String message) =>
      state = state.copyWith(errorMessage: message, isLoading: false) as T;

  void clearErrorState() {
    if (state.errorMessage != null)
      state = state.copyWith(errorMessage: null) as T;
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';
import 'base_state.dart';

abstract class BaseNotifier<T extends BaseState> extends Notifier<T> {
  @override
  T build() => initialState();

  T initialState();

  /// API çağrılarını wrap eden ana metod
  Future<void> execute<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    if (!ref.mounted) return;
    try {
      state = state.copyWith(isLoading: true, errorMessage: null) as T;

      final result = await operation(); // İnternet varsa işlemi gerçekleştir
      if (!ref.mounted) return;
      result.fold(
        (final failure) => setErrorState(
            "Sistemimizi kitledik. Meraklılarımıza kodlarımız: ${failure.message}"),
        (final success) {
          try {
            onSuccess?.call(success);
            state = state.copyWith(isLoading: false, errorMessage: null) as T;
          } catch (e, s) {
            if (!ref.mounted) return;
            setErrorState("Veri işlenirken hata oluştu: $e");
          }
        },
      );
    } catch (e, s) {
      setErrorState('Beklenmeyen bir hata oluştu: ${e.toString()}');
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

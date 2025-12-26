import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';
import 'base_state.dart';

/// Sayfa kapansa bile state tutulur (cache gibi)
/// Riverpod 3+ Notifier sınıfını kullanır
abstract class BaseNotifier<T extends BaseState> extends Notifier<T> {
  @override
  T build() {
    ref.onDispose(onDispose);
    return initialState();
  }

  T initialState();

  // Alt sınıfların temizlik yapması için opsiyonel metod
  void onDispose() {}

  /// API çağrılarını wrap eden ana metod
  Future<void> execute<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
    final String? customErrorMessage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null) as T;

      final result = await operation();
      result.fold(
        (final failure) {
          final message = _mapFailureToMessage(failure, customErrorMessage);
          setErrorState(message);
        },
        (final success) {
          try {
            onSuccess?.call(success);
            state = state.copyWith(isLoading: false, errorMessage: null) as T;
          } catch (e, s) {
            setErrorState("Veri işlenirken hata oluştu: $e");
          }
        },
      );
    } catch (e, s) {
      logError(e, s);
      setErrorState('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  String _mapFailureToMessage(final Failure failure, final String? custom) {
    if (custom != null) return custom;

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

  void logError(final Object e, [final StackTrace? stack]) {
    assert(() {
      print('❌ [ERROR]: $e');
      if (stack != null) print(stack);
      return true;
    }());

    FirebaseCrashlytics.instance.recordError(
      e,
      stack,
      reason: 'BaseNotifier Log',
      fatal: false,
    );
  }
}

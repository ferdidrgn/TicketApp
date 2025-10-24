import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/errors/failures.dart';
import '../network/internet_service.dart';
import 'base_state.dart';

/// Tüm ViewModel'ler için merkezi internet kontrolü ve state yönetimi sağlayan base sınıf
/// Internet bağlantısı kesilip geri geldiğinde otomatik retry mekanizması sunar
abstract class BaseNotifierWithNetworkChecker<T extends BaseState>
    extends Notifier<T> {
  StreamSubscription<InternetConnectionStatus>? _subscription;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  @override
  T build() {
    _initializeNetworkListener();
    _registerCleanup();
    return initialState();
  }

  T initialState();

  void reloadData();

  void _initializeNetworkListener() => _subscription =
      InternetService.instance.connectionStream.listen(_handleConnectionChange);

  void _registerCleanup() => ref.onDispose(() {
        _subscription?.cancel();
        _debounceTimer?.cancel();
      });

  void _handleConnectionChange(final InternetConnectionStatus status) {
    final isOnline = status == InternetConnectionStatus.connected;

    if (isOnline && _wasOffline) {
      _scheduleReload();
      _wasOffline = false;
    } else if (!isOnline && !_wasOffline) {
      _wasOffline = true;
      _handleOffline();
    }
  }

  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 2),
      () => reloadData(),
    );
  }

  void _handleOffline() => state = state.copyWith(
      isLoading: false, errorMessage: 'İnternet Bağlantısı Yok!') as T;

  Future<bool> _hasInternetConnection() async {
    try {
      return await InternetService.instance.isConnected;
    } catch (_) {
      return false;
    }
  }

  void _setLoadingState() =>
      state = state.copyWith(isLoading: true, errorMessage: null) as T;

  void _setSuccessState() =>
      state = state.copyWith(isLoading: false, errorMessage: null) as T;

  void _setErrorState(final String errorMessage) =>
      state = state.copyWith(errorMessage: errorMessage, isLoading: false) as T;

  /// Network operasyonları için wrapper
  Future<void> executeWithInternetCheck<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    try {
      _setLoadingState();

      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        _handleOffline();
        return;
      }

      final result = await operation();

      result.fold(
        (final failure) => _setErrorState(failure.message),
        (final success) {
          onSuccess?.call(success);
          _setSuccessState();
        },
      );
    } catch (e) {
      _setErrorState(
        'Beklenmeyen bir hata oluştu: ${e.toString()}',
      );
    }
  }
}

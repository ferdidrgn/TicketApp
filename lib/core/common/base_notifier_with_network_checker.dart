import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/errors/failures.dart';
import '../network/internet_service.dart';
import 'base_state.dart';

abstract class BaseNotifierWithNetworkChecker<T extends BaseState>
    extends StateNotifier<T> {
  final InternetService _internetService;

  BaseNotifierWithNetworkChecker(
    this._internetService,
    final T initialState,
  ) : super(initialState) {
    _startListening();
  }

  StreamSubscription<InternetConnectionStatus>? _subscription;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  void _startListening() {
    _subscription = _internetService.connectionStream.listen((final status) {
      final isOnline = status == InternetConnectionStatus.connected;
      if (isOnline && _wasOffline) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), onInternetRestored);
        _wasOffline = false;
      } else if (!isOnline && !_wasOffline) {
        _wasOffline = true;
        onInternetLost();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onInternetRestored() => reloadData();

  void onInternetLost() => _setOfflineState();

  void reloadData();

  void _setLoadingState(final bool isLoading) =>
      state = state.copyWith(isLoading: isLoading, errorMessage: null) as T;

  void _setSuccessState() =>
      state = state.copyWith(isLoading: false, errorMessage: null) as T;

  // Private method to set error state
  void _setErrorState(final String errorMessage) =>
      state = state.copyWith(errorMessage: errorMessage, isLoading: false) as T;

  void _setOfflineState() => state = state.copyWith(
      isLoading: false, errorMessage: 'İnternet Bağlantısı Yok!') as T;

  // Manual internet check method
  Future<bool> checkInternet() async {
    try {
      return await _internetService.isConnected;
    } catch (e) {
      return false;
    }
  }

  /// Network operasyonları için wrapper
  Future<void> executeWithInternetCheck<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    try {
      _setLoadingState(true);
      final hasInternet = await checkInternet();

      if (!hasInternet) {
        _setOfflineState();
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
          'Beklenmeyen bir hata oluştu (Unexpected error occurred): ${e.toString()}');
    }
  }
}

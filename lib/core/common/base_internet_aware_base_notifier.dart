import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_state.dart';

// Enhanced Base Notifier with more robust error handling
abstract class InternetAwareBaseNotifier<T extends BaseState>
    extends StateNotifier<T> {
  InternetAwareBaseNotifier(final T state) : super(state) {
    _startInternetCheck();
  }

  Timer? _internetCheckTimer;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  void _startInternetCheck() {
    // Her 5 saniyede bir internet kontrolü yap
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 5), (final _) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (isOnline && _wasOffline) {// Internet restore oldu
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () {
          onInternetRestored();
        });
        _wasOffline = false;
      } else if (!isOnline && !_wasOffline) {// Internet kesildi
        _wasOffline = true;
        onInternetLost();
      }
    } catch (e) {
      if (!_wasOffline) {
        _wasOffline = true;
        onInternetLost();
      }
    }
  }

  // Alt sınıflar bu methodları override edebilir
  // Default implementation - reload data
  void onInternetRestored() => reloadData();

  // Default implementation - show offline state
  void onInternetLost() => _setOfflineState();

  // Alt sınıflar bu methodları implement etmeli
  void reloadData();

  void _setLoadingState(final bool isLoading) =>
      state = state.copyWith(isLoading: isLoading, errorMessage: null) as T;

  void _setSuccessState() =>
      state = state.copyWith(isLoading: false, errorMessage: null) as T;

  // Private method to set error state
  void _setErrorState(final String errorMessage) =>
      state = state.copyWith(errorMessage: errorMessage, isLoading: false) as T;

  void _setOfflineState() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'İnternet Bağlantısı Yok!',
    ) as T;
  }

  // Manual internet check method
  Future<bool> checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _internetCheckTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Network operasyonları için wrapper
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
      _setErrorState('Unexpected error occurred: ${e.toString()}');
    }
  }
}

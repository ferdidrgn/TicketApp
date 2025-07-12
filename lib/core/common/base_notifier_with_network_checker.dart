import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import 'base_state.dart';

abstract class BaseNotifierWithNetworkChecker<T extends BaseState>
    extends StateNotifier<T> {
  BaseNotifierWithNetworkChecker(final T initialState) : super(initialState) {
    _startPeriodicInternetCheck();
  }

  Timer? _internetCheckTimer;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  void _startPeriodicInternetCheck() {
    _internetCheckTimer?.cancel();
    _internetCheckTimer = Timer.periodic(
        const Duration(seconds: 5), (final _) => _checkInternet());
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (isOnline && _wasOffline) {// Internet restore oldu
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), onInternetRestored);
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

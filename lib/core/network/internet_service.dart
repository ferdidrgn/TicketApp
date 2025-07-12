import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetService {
  InternetService._();

  static final InternetService instance = InternetService._();

  final InternetConnectionChecker _checker = InternetConnectionChecker.instance;
  StreamSubscription? _subscription;

  // Global callback'ler
  final List<void Function(bool)> _listeners = [];

  void startListening() {
    _subscription = _checker.onStatusChange.listen((final status) {
      final isConnected = status == InternetConnectionStatus.connected;
      for (final listener in _listeners) listener(isConnected);
    });
  }


  void stopListening() {
    _subscription?.cancel();
    _listeners.clear();
  }

  // Listener ekle
  void addListener(final void Function(bool) listener) =>
      _listeners.add(listener);

  // Listener kaldır
  void removeListener(final void Function(bool) listener) =>
      _listeners.remove(listener);

  Future<bool> get isConnected async => _checker.hasConnection;
  Stream<InternetConnectionStatus> get connectionStream => _checker.onStatusChange;
}

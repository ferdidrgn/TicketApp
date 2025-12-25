import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    ref.onDispose(() => _subscription?.cancel());
    _startListening();
    return true; // Başlangıçta online varsay
  }

  void _startListening() {
    // İlk değeri hemen al
    Connectivity().checkConnectivity().then((final results) {
      final isConnected = _isConnected(results);
      print('📶 İlk bağlantı durumu: $isConnected ($results)');
      if (state != isConnected) state = isConnected;
    });

    // Stream'i dinle
    _subscription =
        Connectivity().onConnectivityChanged.listen((final results) {
      final isConnected = _isConnected(results);
      print('📶 Bağlantı değişti: $isConnected ($results)');
      if (state != isConnected) state = isConnected;
    });
  }

  // none dışında herhangi bir bağlantı varsa online
  bool _isConnected(final List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.contains(ConnectivityResult.none);
}

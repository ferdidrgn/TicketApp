import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_provider.dart';

mixin AutoRefreshOnReconnect<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _wasOffline = false;
  ProviderSubscription<bool>? _subscription; // bool oldu

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((final _) => _setupConnectivityListener());
  }

  void _setupConnectivityListener() {
    _subscription = ref.listenManual<bool>(
      // AsyncValue<bool> değil, bool
      connectivityProvider,
      (final previous, final next) {
        // next artık bool, whenData yok
        if (next && _wasOffline) {
          _wasOffline = false;
          onReconnected();
        } else if (!next) {
          _wasOffline = true;
          onDisconnected();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  void onReconnected() {}
  void onDisconnected() {}
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_provider.dart';

/// İnternet geldiğinde otomatik refresh yapmak isteyen sayfalar için mixin
///
/// Kullanım:
/// ```dart
/// class _MyPageState extends ConsumerState<MyPage> with AutoRefreshOnReconnect {
///   @override
///   void onReconnected() {
///     ref.read(myProvider.notifier).loadData();
///   }
/// }
/// ```
mixin AutoRefreshOnReconnect<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _wasOffline = false;
  ProviderSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    _subscription = ref.listenManual<AsyncValue<bool>>(
      connectivityProvider,
      (final previous, final next) {
        next.whenData((final isOnline) {
          if (isOnline && _wasOffline) {
            _wasOffline = false;
            onReconnected();
          } else if (!isOnline) {
            _wasOffline = true;
            onDisconnected();
          }
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  /// İnternet geri geldiğinde çağrılır - override et
  void onReconnected() {}

  /// İnternet kesildiğinde çağrılır - override et (opsiyonel)
  void onDisconnected() {}
}

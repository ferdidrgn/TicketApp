import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Global internet durumu provider'ı
/// Kullanım: ref.watch(connectivityProvider)
final connectivityProvider = StreamProvider<bool>((final ref) {
  return InternetConnectionChecker.instance.onStatusChange.map(
    (final status) => status == InternetConnectionStatus.connected,
  );
});

/// Anlık kontrol için (nadiren lazım olur)
/// Kullanım: await ref.read(isOnlineProvider.future)
final isOnlineProvider = FutureProvider<bool>((final ref) async {
  return InternetConnectionChecker.instance.hasConnection;
});

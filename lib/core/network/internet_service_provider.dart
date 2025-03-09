import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'internet_service.dart';

// Singleton for Internet Connection Checker
final internetServiceProvider = Provider<InternetService>((final ref) {
  return InternetService.instance;
});

// StreamProvider for real-time connection updates
final networkInfoStreamProvider =
    StreamProvider<InternetConnectionStatus>((final ref) {
  final internetService = ref.watch(internetServiceProvider);
  return internetService.connectionStream;
});

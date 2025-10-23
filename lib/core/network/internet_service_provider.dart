import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'internet_service.dart';

// Singleton for Internet Connection Checker
final internetServiceProvider = Provider<InternetService>((final ref) {
  return InternetService.instance;
});

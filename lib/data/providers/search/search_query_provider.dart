import 'package:flutter_riverpod/flutter_riverpod.dart';

// Arama değişimlerini debounce eden bir provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

/// Arama sorgusunu debounce eden provider
final searchQueryProvider =
StateNotifierProvider.autoDispose<SearchQueryNotifier, String>(
      (final ref) => SearchQueryNotifier(),
);

class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  Timer? _debounceTimer;

  /// Yeni sorgu geldiğinde 500ms bekler, sonra state'i günceller
  void setQuery(final String query) {
    _debounceTimer?.cancel(); // önceki timer iptal
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      state = query;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

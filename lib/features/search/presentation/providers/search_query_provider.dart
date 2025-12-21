import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arama sorgusunu debounce eden provider
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() => '';

  /// Yeni sorgu geldiğinde 500ms bekler, sonra state'i günceller
  void setQuery(final String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => state = query);
  }
}

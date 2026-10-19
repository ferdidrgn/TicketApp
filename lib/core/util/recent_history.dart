import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda tutulan, kullanıcıya özel küçük geçmiş: son bakılan oyunlar ve son
/// aramalar. Sunucuya gitmez; `SharedPreferences` yoksa/bozuksa sessizce boş
/// liste döner (özellik ek konfordur, asla ekranı kırmaz).
class RecentList extends Notifier<List<String>> {
  final String _key;
  final int _max;

  RecentList(this._key, this._max);

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String> saved = p.getStringList(_key) ?? const [];
      if (saved.isNotEmpty) state = saved;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList(_key, state);
    } catch (_) {}
  }

  /// En başa ekler; tekrar eden varsa öne taşır.
  void add(final String value) {
    final String v = value.trim();
    if (v.isEmpty) return;
    final List<String> next = [
      v,
      for (final String x in state)
        if (x != v) x,
    ];
    state = next.length > _max ? next.sublist(0, _max) : next;
    _save();
  }

  void remove(final String value) {
    state = [
      for (final String x in state)
        if (x != value) x,
    ];
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}

/// Son bakılan oyun kimlikleri (en yeni önce, en çok 12).
final recentShowIdsProvider = NotifierProvider<RecentList, List<String>>(
    () => RecentList('recent_show_ids', 12));

/// Son aramalar (en yeni önce, en çok 8).
final recentSearchesProvider = NotifierProvider<RecentList, List<String>>(
    () => RecentList('recent_searches', 8));

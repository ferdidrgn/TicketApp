import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda kalan keşif izi — son bakılan oyun ve son aramalar.
class BrowseMemory {
  BrowseMemory._();

  static const _showId = 'browse.last_show_id';
  static const _showName = 'browse.last_show_name';
  static const _recent = 'browse.recent_queries';

  static Future<void> rememberShow({
    required final String id,
    required final String name,
  }) async {
    if (id.isEmpty) return;
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(_showId, id);
    await p.setString(_showName, name);
  }

  static Future<(String id, String name)?> lastShow() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? id = p.getString(_showId);
    if (id == null || id.isEmpty) return null;
    return (id, p.getString(_showName) ?? '');
  }

  static Future<List<String>> recentQueries() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return p.getStringList(_recent) ?? const [];
  }

  static Future<List<String>> pushQuery(final String raw) async {
    final String q = raw.trim();
    if (q.length < 2) return recentQueries();
    final SharedPreferences p = await SharedPreferences.getInstance();
    final List<String> next = [
      q,
      ...?p.getStringList(_recent)?.where((final s) => s != q),
    ].take(8).toList();
    await p.setStringList(_recent, next);
    return next;
  }

  static Future<List<String>> removeQuery(final String q) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final List<String> next = [
      ...?p.getStringList(_recent)?.where((final s) => s != q),
    ];
    await p.setStringList(_recent, next);
    return next;
  }
}

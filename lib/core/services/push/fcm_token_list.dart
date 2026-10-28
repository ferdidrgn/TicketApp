/// Çoklu cihaz FCM token listesi (User.fcmTokens) için saf yardımcılar.
/// Firestore'a bağımlı değildir; birim testlenir.
class FcmTokenList {
  FcmTokenList._();

  /// Kullanıcı başına en çok tutulan cihaz sayısı (firestore.rules ile aynı).
  static const int maxTokens = 5;

  static List<String> _clean(final Object? raw) => raw is List
      ? raw.whereType<String>().where((final t) => t.isNotEmpty).toList()
      : <String>[];

  /// Bu cihazın [token]'ını listeye ekler: yinelenen düşer, yeni token sona
  /// gelir, [maxTokens] aşılırsa EN ESKİ (baştaki) düşer. Eski tekil alandaki
  /// ([legacy]) token listede yoksa geçişte başa alınır.
  static List<String> add(
      final Object? existing, final String? legacy, final String token) {
    final List<String> list = _clean(existing);
    if (legacy != null && legacy.isNotEmpty && !list.contains(legacy)) {
      list.insert(0, legacy);
    }
    list.remove(token);
    list.add(token);
    return list.length > maxTokens
        ? list.sublist(list.length - maxTokens)
        : list;
  }

  /// Yalnız bu cihazın token'ını çıkarır (diğer cihazlar etkilenmez).
  static List<String> remove(final Object? existing, final String token) =>
      _clean(existing).where((final t) => t != token).toList();
}

/// `Show.duration` serbest metin — "150", "150 dk", "2 saat 30 dk", bazen
/// yanlışlıkla seans saati ("21:45"). Ham rakam birleştirme ("21:45" → 2145)
/// yasak; makul dakika aralığı dışında sonuç yok sayılır.
abstract final class ShowDurationFormat {
  static const int _minMinutes = 15;
  static const int _maxMinutes = 480; // 8 saat — tiyatro için üst sınır

  /// Dakika cinsinden süre; anlaşılamaz / saat gibi durursa null.
  static int? minutes(final String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return null;

    // "21:45" / "9:30" — süre değil, saat dilimi.
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)) return null;

    // "2 saat 30 dk" / "2 sa 30"
    final Match? hm = RegExp(
      r'(\d+)\s*(?:saat|sa\.?)\s*(\d+)\s*(?:dk|dakika|min)?',
      caseSensitive: false,
    ).firstMatch(t);
    if (hm != null) {
      final int h = int.tryParse(hm.group(1)!) ?? 0;
      final int m = int.tryParse(hm.group(2)!) ?? 0;
      return _clampOrNull(h * 60 + m);
    }

    // "2 saat" / "2 sa"
    final Match? hOnly = RegExp(
      r'(\d+)\s*(?:saat|sa\.?)\b',
      caseSensitive: false,
    ).firstMatch(t);
    if (hOnly != null) {
      final int h = int.tryParse(hOnly.group(1)!) ?? 0;
      return _clampOrNull(h * 60);
    }

    // "150 dk" / "90 dakika"
    final Match? mOnly = RegExp(
      r'(\d+)\s*(?:dk|dakika|min)\b',
      caseSensitive: false,
    ).firstMatch(t);
    if (mOnly != null) {
      return _clampOrNull(int.tryParse(mOnly.group(1)!));
    }

    // Salt rakam — "150". Çok büyük değerler (2145) muhtemel bozulma.
    if (RegExp(r'^\d+$').hasMatch(t)) {
      return _clampOrNull(int.tryParse(t));
    }

    return null;
  }

  /// Metrik orb: `('150', 'dk')` veya anlaşılamazsa null.
  static ({String value, String unit})? metric(final String raw) {
    final int? m = minutes(raw);
    if (m == null) return null;
    return (value: '$m', unit: 'dk');
  }

  /// Okunur etiket: "2 saat 30 dk" / "90 dk".
  static String? label(final String raw) {
    final int? m = minutes(raw);
    if (m == null) {
      final String t = raw.trim();
      if (t.isEmpty) return null;
      // Saat gibi görüneni kullanıcıya süre diye verme.
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)) return null;
      return t;
    }
    if (m < 60) return '$m dk';
    final int h = m ~/ 60;
    final int r = m % 60;
    if (r == 0) return '$h saat';
    return '$h saat $r dk';
  }

  static int? _clampOrNull(final int? m) {
    if (m == null) return null;
    if (m < _minMinutes || m > _maxMinutes) return null;
    return m;
  }
}

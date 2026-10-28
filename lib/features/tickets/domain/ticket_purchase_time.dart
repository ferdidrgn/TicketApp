/// Biletin alış (satın alma / rezervasyon) zamanı gösterimi.
///
/// Kaynak: `Ticket._createdAt` — sunucu `toISOString()` (UTC, `Z` ekli)
/// yazar; Timestamp ya da sayı (ms) gelirse `TicketModel` UTC ISO'ya çevirir.
/// Gösterim Europe/Istanbul (2016'dan beri sabit UTC+3, yaz saati yok):
/// "28.10.2026 14:32".
DateTime? parsePurchaseInstant(final String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final DateTime? d = DateTime.tryParse(s);
  if (d != null) return d;
  final int? ms = int.tryParse(s);
  if (ms != null && ms > 0) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  return null;
}

String _two(final int n) => n.toString().padLeft(2, '0');

/// "28.10.2026 14:32" ya da çözülemezse boş metin.
String formatPurchaseStamp(final String raw) {
  final DateTime? d = parsePurchaseInstant(raw);
  if (d == null) return '';
  // Saat dilimi bilgisi olan (UTC) an: İstanbul'a çevir. Dilimsiz metin zaten
  // yerel kabul edilir ve olduğu gibi gösterilir.
  final DateTime t = d.isUtc ? d.add(const Duration(hours: 3)) : d;
  return '${_two(t.day)}.${_two(t.month)}.${t.year} ${_two(t.hour)}:${_two(t.minute)}';
}

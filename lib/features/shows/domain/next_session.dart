import '../../../core/util/date_formatter.dart';
import '../../events/domain/entities/event.dart';

/// Bir oyunun en yakın gelecek seansı. Tarih uydurulmaz: ayrıştırılamayan
/// veya geçmiş seanslar yok sayılır.
class NextSessionHint {
  final DateTime when;
  final double? price;

  const NextSessionHint({required this.when, this.price});
}

NextSessionHint? nextSessionHint(
  final List<Event>? events, {
  final DateTime? now,
}) {
  if (events == null || events.isEmpty) return null;
  final DateTime reference = now ?? DateTime.now();
  Event? best;
  DateTime? bestWhen;
  for (final Event event in events) {
    final DateTime? date = DateFormatter.parseDateString(event.date);
    if (date == null || !date.isAfter(reference)) continue;
    if (bestWhen == null || date.isBefore(bestWhen)) {
      bestWhen = date;
      best = event;
    }
  }
  if (bestWhen == null || best == null) return null;
  final double? price =
      double.tryParse(best.price.trim().replaceAll(',', '.'));
  return NextSessionHint(
    when: bestWhen,
    price: price != null && price > 0 ? price : null,
  );
}

/// Firestore'daki yer tutucu kural metinleri ("yok", "-") ekranda not olmaz.
String displayEventRule(final String raw) {
  final String text = raw.trim();
  if (text.isEmpty) return '';
  if (const {'yok', '-', '—', 'none', 'null'}.contains(text.toLowerCase())) {
    return '';
  }
  return text;
}

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

mixin DateFormatter {
  /// Uygulama başında bir kez çağırılmalıdır (main.dart)
  static Future<void> initializeLocale() async => initializeDateFormatting();

  /// "dd.MM.yyyy, HH:mm" formatında şu anki tarihi döndürür.
  static String nowFormatDateTime() =>
      DateFormat('dd.MM.yyyy, HH:mm').format(DateTime.now());

  /// Uygulamanın kendi "dd.MM.yyyy, HH:mm" string formatını VE Firestore'dan
  /// gelen ISO8601 string'lerini (bkz. `EventModel.fromFirestore` — bir
  /// `Event.date` alanı Firebase Console'dan elle bir Timestamp olarak
  /// girildiyse, model onu ISO8601'e çeviriyor, uygulamanın kendi
  /// dd.MM.yyyy formatına değil) birlikte anlayan ortak ayrıştırıcı.
  /// Önce asıl formatı dener, o başarısız olursa ISO8601'e düşer — bir
  /// etkinliğin sadece Firebase Console'dan elle eklenmiş olması yüzünden
  /// "aktif" hesaplamalarından sessizce düşmesini engeller.
  static DateTime? _parseAny(final String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateFormat('dd.MM.yyyy, HH:mm').parse(raw);
    } catch (_) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      print("DateFormatter: tarih ayrıştırılamadı: $raw");
      return null;
    }
  }

  /// "dd.MM.yyyy, HH:mm" stringini (ya da ISO8601 düşüşünü) DateTime
  /// nesnesine çevirir.
  static DateTime? parseDateString(final String? dateString) =>
      _parseAny(dateString);

  /// Formatlanmış veriyi tarih ve saat olarak böler.
  /// formatWithMonthName true ise dile göre "10 Ekim" veya "October 10" döndürür.
  static Map<String, String> parseFormattedDateTime(
    final String formattedDateTime, {
    final bool formatWithMonthName = false,
  }) {
    final DateTime? dateTime = _parseAny(formattedDateTime);
    if (dateTime == null) return {"date": "Hatalı Tarih", "time": "--:--"};

    final String timePart = DateFormat('HH:mm').format(dateTime);

    String datePart;
    if (formatWithMonthName) {
      final String locale = Intl.getCurrentLocale();
      // TR için: 19 Ocak | EN için: January 19
      datePart = locale.startsWith('tr')
          ? DateFormat('d MMMM', 'tr').format(dateTime)
          : DateFormat('MMMM d', 'en').format(dateTime);
    } else
      datePart = DateFormat('dd.MM.yyyy').format(dateTime);

    return {"date": datePart, "time": timePart};
  }

  /// ESKİ İSİM & YENİ İŞLEV: Kartlar için parçalara ayırır.
  /// Day: "25", monthName: "Ekim"/"October", time: "12:19"
  static Map<String, String> formatForEventCard(
      final String formattedDateTime) {
    final DateTime? dateTime = _parseAny(formattedDateTime);
    if (dateTime == null) return {"day": "?", "monthName": "Hata", "time": "--:--"};

    final String locale = Intl.getCurrentLocale();
    return {
      "day": DateFormat('d').format(dateTime),
      "monthName": DateFormat('MMMM', locale).format(dateTime),
      "time": DateFormat('HH:mm').format(dateTime)
    };
  }

  /// Ay numarasından ay adını dile göre döndürür.
  // 2024 yılının ilgili ayını temsil eden geçici bir tarih oluşturup ismini alıyoruz
  static String getMonthName(final int month) =>
      DateFormat('MMMM', Intl.getCurrentLocale()).format(DateTime(2024, month));
}

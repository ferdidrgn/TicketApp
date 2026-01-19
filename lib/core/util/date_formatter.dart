import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

mixin DateFormatter {
  /// Uygulama başında bir kez çağırılmalıdır (main.dart)
  static Future<void> initializeLocale() async => initializeDateFormatting();

  /// "dd.MM.yyyy, HH:mm" formatında şu anki tarihi döndürür.
  static String nowFormatDateTime() =>
      DateFormat('dd.MM.yyyy, HH:mm').format(DateTime.now());

  /// "dd.MM.yyyy, HH:mm" stringini DateTime nesnesine çevirir.
  static DateTime? parseDateString(final String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat('dd.MM.yyyy, HH:mm').parse(dateString);
    } catch (e) {
      print("DateFormatter.parseDateString Hata: $e");
      return null;
    }
  }

  /// Formatlanmış veriyi tarih ve saat olarak böler.
  /// formatWithMonthName true ise dile göre "10 Ekim" veya "October 10" döndürür.
  static Map<String, String> parseFormattedDateTime(
    final String formattedDateTime, {
    final bool formatWithMonthName = false,
  }) {
    try {
      final DateTime dateTime =
          DateFormat('dd.MM.yyyy, HH:mm').parse(formattedDateTime);
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
    } catch (e) {
      return {"date": "Hatalı Tarih", "time": "--:--"};
    }
  }

  /// ESKİ İSİM & YENİ İŞLEV: Kartlar için parçalara ayırır.
  /// Day: "25", monthName: "Ekim"/"October", time: "12:19"
  static Map<String, String> formatForEventCard(
      final String formattedDateTime) {
    try {
      final DateTime dateTime =
          DateFormat('dd.MM.yyyy, HH:mm').parse(formattedDateTime);
      final String locale = Intl.getCurrentLocale();

      return {
        "day": DateFormat('d').format(dateTime),
        "monthName": DateFormat('MMMM', locale).format(dateTime),
        "time": DateFormat('HH:mm').format(dateTime)
      };
    } catch (e) {
      return {"day": "?", "monthName": "Hata", "time": "--:--"};
    }
  }

  /// Ay numarasından ay adını dile göre döndürür.
  // 2024 yılının ilgili ayını temsil eden geçici bir tarih oluşturup ismini alıyoruz
  static String getMonthName(final int month) =>
      DateFormat('MMMM', Intl.getCurrentLocale()).format(DateTime(2024, month));
}

mixin DateFormatter {
  // "dd.MM.yyyy, HH:mm" formatında şu anki tarih ve saati döndüren metod
  static String nowFormatDateTime() {
    final dateTime = DateTime.now();
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day.$month.$year, $hour:$minute";
  }

  static DateTime? parseDateString(final String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final List<String> parts = dateString.split(',');
      if (parts.length != 2) return null; // Beklenen format değil

      final String datePart = parts[0].trim();
      final String timePart = parts[1].trim();

      final List<String> dateParts = datePart.split('.');
      final List<String> timeParts = timePart.split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return null;

      final int year = int.parse(dateParts[2]);
      final int month = int.parse(dateParts[1]);
      final int day = int.parse(dateParts[0]);
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      // DateTime.parse() veya intl paketine göre daha az güvenli
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print("DateFormatter.parseEventDateString Hata ($dateString): $e");
      return null;
    }
  }

  // Formatlanmış veriyi tarih ve saat olarak bölen metod
  static Map<String, String> parseFormattedDateTime(
      final String formattedDateTime,
      {final bool formatWithMonthName = false}) {
    try {
      final List<String> parts = formattedDateTime.split(',');
      if (parts.length < 2) throw FormatException("Comma separator missing.");
      final String datePart = parts[0];
      final String timePart = parts[1].trim();

      final List<String> dateParts = datePart.split('.');
      if (dateParts.length < 3) throw FormatException("Date parts missing.");

      final int day = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int year = int.parse(dateParts[2]);

      final String formattedDate = formatWithMonthName
          ? "${getMonthName(month)} $day" //Like "10 Ekim"
          : "$day.${month.toString().padLeft(2, '0')}.$year"; //Like "18.09.2024"

      return {"date": formattedDate, "time": timePart};
    } catch (e) {
      print(
          "Error in parseFormattedDateTime for input '$formattedDateTime': $e");
      return {"date": "Hatalı Tarih", "time": "--:--"};
    }
  }

  /// YENİ/GÜNCEL METOD: Gelen "dd.MM.yyyy, HH:mm" formatındaki string'i
  /// etkinlik kartının ihtiyacı olan parçalara ayırır.
  static Map<String, String> formatForEventCard(
      final String formattedDateTime) {
    try {
      // 1. Tarih ve Saati ayır ("dd.MM.yyyy" ve " HH:mm")
      final List<String> parts = formattedDateTime.split(',');
      if (parts.length < 2) {
      // Eğer format bozuksa (virgül yoksa) hata ver
        throw FormatException(
            "Invalid date time format: Comma separator missing.");
      }
      final String datePart = parts[0];
      final String timePart = parts[1].trim(); // Başındaki boşluğu temizle

      // 2. Tarih parçalarını ayır ("dd", "MM", "yyyy")
      final List<String> dateParts = datePart.split('.');
      if (dateParts.length < 3) {
      // Eğer format bozuksa (noktalar eksikse) hata ver
        throw FormatException("Invalid date format: Date parts missing.");
      }
      final String day = dateParts[0];
      final int monthInt = int.parse(dateParts[1]);

      // 3. Ay numarasından ay adını al (Public metodu kullan)
      final String monthName = getMonthName(monthInt);

      return {
        "day": day, // Örn: "25"
        "monthName": monthName, // Örn: "Ekim"
        "time": timePart // Örn: "12:19"
      };
    } catch (e) {
    // Hata oluşursa (örn: format bozuksa, parse hatası)
      print("Error in formatForEventCard for input '$formattedDateTime': $e");
      return {"day": "?", "monthName": "Hata", "time": "--:--"};
    }
  }

  // Ay adını getiren public yardımcı metod (Baştaki '_' kaldırıldı)
  static String getMonthName(final int month) {
    const Map<int, String> monthNames = {
      1: "Ocak",
      2: "Şubat",
      3: "Mart",
      4: "Nisan",
      5: "Mayıs",
      6: "Haziran",
      7: "Temmuz",
      8: "Ağustos",
      9: "Eylül",
      10: "Ekim",
      11: "Kasım",
      12: "Aralık"
    };
    return monthNames[month] ?? '';
  }
}

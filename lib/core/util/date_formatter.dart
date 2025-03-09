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

  // Formatlanmış veriyi tarih ve saat olarak bölen metod
  static Map<String, String> parseFormattedDateTime(
      final String formattedDateTime,
      {final bool formatWithMonthName = false}) {
    final List<String> parts = formattedDateTime.split(',');
    final List<String> dateParts = parts[0].split('.');

    final int day = int.parse(dateParts[0]);
    final int month = int.parse(dateParts[1]);
    final int year = int.parse(dateParts[2]);
    final String timePart = parts[1];

    final String formattedDate = formatWithMonthName
        ? "${_getMonthName(month)} $day" //Like "10 Ekim"
        : "$day.${month.toString().padLeft(2, '0')}.$year"; //Like "18.09.2024"

    return {"date": formattedDate, "time": timePart};
  }

  static String _getMonthName(final int month) {
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

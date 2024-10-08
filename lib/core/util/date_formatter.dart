class DateFormatter {
  // "dd.MM.yyyy, HH:mm" formatında şu anki tarih ve saati döndüren metod
  static String nowFormatDateTime() {
    final dateTime = DateTime.now();
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day.$month.$year, $hour:$minute";
  }

  // Formatlanmış veriyi tarih ve saat olarak bölen metod
  static Map<String, String> parseFormattedDateTime(String formattedDateTime,
      {bool formatWithMonthName = false}) {
    List<String> parts = formattedDateTime.split(',');
    List<String> dateParts = parts[0].split('.');

    int day = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int year = int.parse(dateParts[2]);
    String timePart = parts[1];

    String formattedDate = formatWithMonthName
        ? "${_getMonthName(month)} $day" //Like "10 Ekim"
        : "$day.${month.toString().padLeft(2, '0')}.$year"; //Like "18.09.2024"

    return {"date": formattedDate, "time": timePart};
  }

  static String _getMonthName(int month) {
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

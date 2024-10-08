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
  static Map<String, String> parseFormattedDateTime(String formattedDateTime) {
    List<String> parts = formattedDateTime.split(', ');
    if (parts.length != 2) throw FormatException("Geçersiz format: '$formattedDateTime'");

    return {'date': parts[0], 'time': parts[1]};
  }
}

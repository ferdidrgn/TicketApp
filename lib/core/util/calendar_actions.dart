import 'package:add_2_calendar/add_2_calendar.dart' as cal;

/// Gerçek, cihaz takvimine ekleme aksiyonu — `TiyatrolCommunicationActions`
/// (bkz. `comminucation_actions.dart`) ile aynı ruhta: sahte/boş bir onTap
/// yerine gerçek bir platform eylemi. `add_2_calendar` paketinin kendi
/// `Event` sınıfı uygulamanın domain `Event` entity'siyle isim çakışması
/// yaptığı için `cal` önekiyle import edilir.
final class TiyatrolCalendarActions {
  TiyatrolCalendarActions._();

  /// Varsayılan gösteri süresi — `Show.duration` serbest metin bir alan
  /// olduğundan (ör. "120 dakika", "2 saat") güvenilir şekilde
  /// ayrıştırılamazsa bu kullanılır. Takvim etkinliğinin bitiş saati için
  /// pratik bir tahmindir; asla "gösterinin resmi süresi budur" diye
  /// kullanıcıya sunulmaz.
  static const Duration _fallbackDuration = Duration(hours: 2);

  /// Gösteri adı, GERÇEK etkinlik tarihi (`Event.date`'ten ayrıştırılmış)
  /// ve GERÇEK sahne adresinden cihazın takvim uygulamasına (Android/iOS/
  /// web'de indirilebilir .ics) bir etkinlik ekler.
  static Future<void> addShowEventToCalendar({
    required final String showName,
    required final DateTime eventStart,
    final String location = '',
    final String showDuration = '',
    final String description = '',
  }) async {
    final event = cal.Event(
      title: showName,
      description: description.isNotEmpty
          ? description
          : 'TiyatRol üzerinden alınan bilet.',
      location: location,
      startDate: eventStart,
      endDate: eventStart.add(_parseDuration(showDuration)),
      allDay: false,
    );
    await cal.Add2Calendar.addEvent2Cal(event);
  }

  static Duration _parseDuration(final String rawDuration) {
    final match = RegExp(r'(\d+)').firstMatch(rawDuration);
    if (match == null) return _fallbackDuration;
    final minutes = int.tryParse(match.group(1)!);
    if (minutes == null || minutes < 15 || minutes > 480) {
      return _fallbackDuration;
    }
    return Duration(minutes: minutes);
  }
}

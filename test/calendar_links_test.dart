import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/util/calendar_picker.dart';

void main() {
  final CalendarEventData e = CalendarEventData(
    title: 'Oyun; Adı, Test',
    start: DateTime.utc(2026, 11, 15, 19, 0),
    end: DateTime.utc(2026, 11, 15, 21, 0),
    location: 'Salon A',
    description: 'Not',
  );

  test('Google bağlantısı tarihleri UTC biçiminde taşır', () {
    final Uri u = CalendarLinks.google(e);
    expect(u.host, 'calendar.google.com');
    expect(u.queryParameters['dates'], '20261115T190000Z/20261115T210000Z');
    expect(u.queryParameters['text'], 'Oyun; Adı, Test');
  });

  test('.ics geçerli bir VEVENT üretir ve özel karakterleri kaçırır', () {
    final String ics = CalendarLinks.ics(e);
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('DTSTART:20261115T190000Z'));
    expect(ics, contains(r'SUMMARY:Oyun\; Adı\, Test'));
    expect(ics, contains('END:VCALENDAR'));
  });

  test('Outlook ve Yahoo bağlantıları doğru ana makineye gider', () {
    expect(CalendarLinks.outlook(e).host, 'outlook.live.com');
    expect(CalendarLinks.yahoo(e).host, 'calendar.yahoo.com');
  });
}

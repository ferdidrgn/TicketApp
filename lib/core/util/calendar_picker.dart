import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calendar_actions.dart';
import 'ics_download_stub.dart'
    if (dart.library.js_interop) 'ics_download_web.dart';
import 'show_duration.dart';

/// Takvime eklenecek tek bir seans.
class CalendarEventData {
  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String description;

  const CalendarEventData({
    required this.title,
    required this.start,
    required this.end,
    this.location = '',
    this.description = '',
  });

  /// Süre metninden ("2 perde / 145dk") bitişi türetir; okunamazsa 2 saat.
  factory CalendarEventData.forShow({
    required final String showName,
    required final DateTime start,
    final String duration = '',
    final String location = '',
    final String description = '',
  }) {
    final int? minutes = ShowDurationFormat.minutes(duration);
    return CalendarEventData(
      title: showName,
      start: start,
      end: start.add(Duration(minutes: minutes ?? 120)),
      location: location,
      description:
          description.isNotEmpty ? description : 'TiyatRol üzerinden alınan bilet.',
    );
  }
}

/// Takvim bağlantıları ve .ics içeriği (hepsi gerçek, herkese açık biçimler).
abstract final class CalendarLinks {
  static String _utc(final DateTime d) {
    final DateTime u = d.toUtc();
    String p(final int n, [final int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(u.year, 4)}${p(u.month)}${p(u.day)}T${p(u.hour)}${p(u.minute)}${p(u.second)}Z';
  }

  static Uri google(final CalendarEventData e) => Uri.https(
          'calendar.google.com', '/calendar/render', {
        'action': 'TEMPLATE',
        'text': e.title,
        'dates': '${_utc(e.start)}/${_utc(e.end)}',
        'details': e.description,
        'location': e.location,
      });

  static Uri outlook(final CalendarEventData e, {final bool office = false}) =>
      Uri.https(office ? 'outlook.office.com' : 'outlook.live.com',
          '/calendar/0/deeplink/compose', {
        'path': '/calendar/action/compose',
        'rru': 'addevent',
        'subject': e.title,
        'startdt': e.start.toUtc().toIso8601String(),
        'enddt': e.end.toUtc().toIso8601String(),
        'body': e.description,
        'location': e.location,
      });

  static Uri yahoo(final CalendarEventData e) =>
      Uri.https('calendar.yahoo.com', '/', {
        'v': '60',
        'title': e.title,
        'st': _utc(e.start),
        'et': _utc(e.end),
        'desc': e.description,
        'in_loc': e.location,
      });

  static String _esc(final String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  static String ics(final CalendarEventData e) => [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//TiyatRol//Takvim//TR',
        'CALSCALE:GREGORIAN',
        'METHOD:PUBLISH',
        'BEGIN:VEVENT',
        'UID:${e.start.millisecondsSinceEpoch}-${e.title.hashCode}@tiyatrol.com',
        'DTSTAMP:${_utc(DateTime.now())}',
        'DTSTART:${_utc(e.start)}',
        'DTEND:${_utc(e.end)}',
        'SUMMARY:${_esc(e.title)}',
        if (e.location.isNotEmpty) 'LOCATION:${_esc(e.location)}',
        if (e.description.isNotEmpty) 'DESCRIPTION:${_esc(e.description)}',
        'BEGIN:VALARM',
        'TRIGGER:-PT2H',
        'ACTION:DISPLAY',
        'DESCRIPTION:${_esc(e.title)} 2 saat sonra başlıyor',
        'END:VALARM',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\r\n');
}

enum _Target { device, google, apple, outlook, yahoo, ics }

/// Düğmenin yanında küçük bir açılır menü: Google, Apple/iCloud, Outlook,
/// Yahoo, Diğer (.ics). Seçilen uygulama açılıp seans oradaki takvime eklenir.
/// Mobil uygulamada ayrıca "Cihaz takvimi" (yerel ekleme) en üstte çıkar.
Future<void> showAddToCalendarMenu(
  final BuildContext context,
  final CalendarEventData data, {
  final bool native = false,
}) async {
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  final Offset topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromLTWH(topLeft.dx, topLeft.dy + box.size.height, box.size.width, 0),
    Offset.zero & overlay.size,
  );
  final ColorScheme cs = Theme.of(context).colorScheme;
  HapticFeedback.selectionClick();

  PopupMenuItem<_Target> item(final _Target t, final Widget leading,
          final String label, final String sub) =>
      PopupMenuItem<_Target>(
        value: t,
        height: 52,
        child: Row(children: [
          SizedBox(width: 30, height: 30, child: Center(child: leading)),
          const SizedBox(width: 12),
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11.5, color: cs.onSurfaceVariant)),
              ]),
        ]),
      );

  Widget letter(final String l, final Color c) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        child: Text(l,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      );

  final _Target? choice = await showMenu<_Target>(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [
      if (native)
        item(_Target.device, Icon(Icons.phone_iphone_rounded, color: cs.primary),
            'Cihaz takvimi', 'Telefonunun takvim uygulaması'),
      item(_Target.google, letter('G', const Color(0xFF4285F4)),
          'Google Takvim', 'Tarayıcıda ya da uygulamada aç'),
      item(_Target.apple, const Icon(Icons.apple, size: 26),
          'Apple Takvim · iCloud', '.ics dosyası olarak indir'),
      item(_Target.outlook, letter('O', const Color(0xFF0A64AD)),
          'Outlook', 'Outlook.com / Microsoft 365'),
      item(_Target.yahoo, letter('Y', const Color(0xFF6001D2)),
          'Yahoo Takvim', 'Tarayıcıda aç'),
      item(_Target.ics, Icon(Icons.download_rounded, color: cs.primary),
          'Diğer (.ics)', 'Herhangi bir takvim uygulaması'),
    ],
  );
  if (choice == null || !context.mounted) return;

  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  void say(final String m) => messenger?.showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  Future<void> open(final Uri u) async {
    final bool ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok) say('Takvim uygulaması açılamadı.');
  }

  try {
    switch (choice) {
      case _Target.device:
        await TiyatrolCalendarActions.addShowEventToCalendar(
          showName: data.title,
          eventStart: data.start,
          location: data.location,
          description: data.description,
        );
      case _Target.google:
        await open(CalendarLinks.google(data));
      case _Target.outlook:
        await open(CalendarLinks.outlook(data));
      case _Target.yahoo:
        await open(CalendarLinks.yahoo(data));
      case _Target.apple:
      case _Target.ics:
        final bool saved =
            await downloadIcs('tiyatrol-seans.ics', CalendarLinks.ics(data));
        if (saved) {
          say('Takvim dosyası indirildi. Açınca seans takvimine eklenir.');
        } else {
          // Web dışı: yerel takvim eklemesine düş.
          await TiyatrolCalendarActions.addShowEventToCalendar(
            showName: data.title,
            eventStart: data.start,
            location: data.location,
            description: data.description,
          );
        }
    }
  } catch (_) {
    say('Takvime eklenemedi. Tekrar dene.');
  }
}

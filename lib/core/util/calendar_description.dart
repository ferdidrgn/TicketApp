import '../services/deeplink/deeplink_service.dart';

/// Takvim kaydının açıklaması: oyunun bağlantısı + etkinlik (seans) numarası;
/// kullanıcının bu seans için bileti varsa koltuklar, bilet numarası ve
/// biletini açan bağlantı da eklenir. Böylece takvimdeki kayıttan doğrudan
/// bilete/oyuna dönülebilir.
String calendarDescription({
  required final String showId,
  required final String showName,
  final String eventId = '',
  final String venue = '',
  final List<String> seats = const [],
  final String ticketId = '',
}) {
  final String showUrl = TiyatrolDeeplinkService.showUrl(showId, showName);
  final List<String> lines = [
    'TiyatRol — $showName',
    if (venue.trim().isNotEmpty) 'Mekân: ${venue.trim()}',
    if (eventId.trim().isNotEmpty) 'Etkinlik no: ${eventId.trim()}',
    '',
    if (seats.isNotEmpty || ticketId.isNotEmpty) ...[
      'BİLETİN',
      if (seats.isNotEmpty) 'Koltuk: ${seats.join(', ')}',
      if (ticketId.isNotEmpty) 'Bilet no: $ticketId',
      if (ticketId.isNotEmpty)
        'Biletini aç: ${TiyatrolDeeplinkService.ticketUrl(ticketId)}',
      '',
    ] else
      'Bilet al: $showUrl',
    'Oyun sayfası: $showUrl',
  ];
  return lines.join('\n');
}

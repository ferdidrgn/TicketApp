import 'package:cloud_functions/cloud_functions.dart';

/// Ücretsiz etkinlikler için bilet talep akışının Flutter tarafındaki tek
/// giriş noktası. Gerçek doğrulama (etkinlik gerçekten ücretsiz mi, koltuklar
/// gerçekten bu kullanıcı tarafından rezerve mi) ve SMS tetiklemesi SUNUCU
/// tarafında (functions/freeTickets/index.js) yapılır — client sadece
/// sonucu bekler.
abstract final class FreeTicketService {
  static Future<String> claim({
    required final String eventId,
    required final List<String> seatIds,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('claimFreeTicket');
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': eventId,
        'seatIds': seatIds,
      });
      return result.data['ticketId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}

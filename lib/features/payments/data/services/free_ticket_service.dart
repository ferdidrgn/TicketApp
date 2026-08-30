import 'package:cloud_functions/cloud_functions.dart';

class FreeTicketClaimResult {
  final String ticketId;
  final bool smsSent;

  const FreeTicketClaimResult({required this.ticketId, required this.smsSent});
}

/// Ücretsiz etkinlikler için bilet talep akışının Flutter tarafındaki tek
/// giriş noktası. Gerçek doğrulama (etkinlik gerçekten ücretsiz mi, koltuklar
/// gerçekten bu kullanıcı tarafından rezerve mi, hesap telefon/e-posta ile
/// doğrulanmış mı) ve SMS tetiklemesi SUNUCU tarafında
/// (functions/freeTickets/index.js) yapılır — client sadece sonucu bekler.
abstract final class FreeTicketService {
  static Future<FreeTicketClaimResult> claim({
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
      return FreeTicketClaimResult(
        ticketId: result.data['ticketId'] as String,
        smsSent: result.data['smsSent'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }
}

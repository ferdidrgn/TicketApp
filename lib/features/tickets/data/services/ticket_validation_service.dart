import 'package:cloud_functions/cloud_functions.dart';

enum TicketValidationStatus { valid, alreadyUsed, notFound, error }

class TicketValidationResult {
  final TicketValidationStatus status;
  final String message;
  final String? showName;
  final int? seatCount;

  const TicketValidationResult({
    required this.status,
    required this.message,
    this.showName,
    this.seatCount,
  });
}

/// Kapıda bilet QR kodu doğrulama — sunucu tarafında (functions/tickets/
/// index.js) admin/curator yetkisi ve "bir bilet en fazla bir kez"
/// kontrolü yapılır. Client sadece sonucu gösterir.
abstract final class TicketValidationService {
  static Future<TicketValidationResult> validate(final String ticketId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('validateTicket');
      final result = await callable.call<Map<String, dynamic>>({
        'ticketId': ticketId,
      });
      final data = result.data;
      return TicketValidationResult(
        status: TicketValidationStatus.valid,
        message: '${data['showName']} — ${data['seatCount']} koltuk. Giriş onaylandı.',
        showName: data['showName'] as String?,
        seatCount: data['seatCount'] as int?,
      );
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'already-exists':
          return TicketValidationResult(
              status: TicketValidationStatus.alreadyUsed,
              message: e.message ?? 'Bu bilet daha önce kullanılmış.');
        case 'not-found':
          return const TicketValidationResult(
              status: TicketValidationStatus.notFound,
              message: 'Bu bilet sistemde bulunamadı.');
        case 'permission-denied':
          return const TicketValidationResult(
              status: TicketValidationStatus.error,
              message: 'Bu işlem için yetkin yok.');
        default:
          return TicketValidationResult(
              status: TicketValidationStatus.error,
              message: e.message ?? 'Bilinmeyen bir hata oluştu.');
      }
    }
  }
}

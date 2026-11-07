import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  // NOT (13.11.2026): `createNotification` BİLEREK yok — Notification
  // yazımı yalnız sunucuda (Cloud Functions, orders.js/notify.js/
  // accountDeletion.js). `firestore.rules` istemciden `Notification`
  // create'i zaten `if false` ile kapatıyor; istemci tarafı yazma yolu
  // (use case/datasource/model.toFirestore) ölü kod olduğu için kaldırıldı
  // (bkz. git geçmişi — aynı gerekçeyle kaldırılan `getClosedSeatsByStage`).

  /// Canlı akış olduğu için Either'a sarılmaz (bkz. EventRepository.getEventSeatStatusStream
  /// ile aynı gerekçe: anlık veri akışları try/catch + Stream.error ile yönetilir).
  Stream<List<AppNotification>> watchNotificationsForUser(
      final String userId);

  Future<Either<Failure, bool>> markNotificationRead(
      final String notificationId);
}

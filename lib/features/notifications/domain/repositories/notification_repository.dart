import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, bool>> createNotification(
      final AppNotification notification);

  /// Canlı akış olduğu için Either'a sarılmaz (bkz. EventRepository.getEventSeatStatusStream
  /// ile aynı gerekçe: anlık veri akışları try/catch + Stream.error ile yönetilir).
  Stream<List<AppNotification>> watchNotificationsForUser(
      final String userId);

  Future<Either<Failure, bool>> markNotificationRead(
      final String notificationId);
}

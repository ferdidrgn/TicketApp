import 'package:dartz/dartz.dart';
import '../../../../core/base/base_repo.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source_and_impl.dart';
import '../mappers/notification_mapper.dart';

class NotificationRepositoryImpl extends BaseRepository
    implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> createNotification(
          final AppNotification notification) =>
      execute(() async =>
          remoteDataSource.createNotification(notification.toModel()));

  @override
  Stream<List<AppNotification>> watchNotificationsForUser(
      final String userId) {
    // Stream'ler 'execute' bloğuna sarılmaz çünkü anlık veri akışıdırlar
    // (bkz. EventRepositoryImpl.getEventSeatStatusStream ile aynı desen).
    try {
      return remoteDataSource
          .watchNotificationsForUser(userId)
          .map((final models) => models.map((final m) => m.toEntity()).toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  @override
  Future<Either<Failure, bool>> markNotificationRead(
          final String notificationId) =>
      execute(() async => remoteDataSource.markNotificationRead(notificationId));
}
